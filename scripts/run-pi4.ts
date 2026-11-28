#!/usr/bin/env -S node
/**
 * Test the pi4-nas system: in QEMU (before flashing) or on the real Pi over SSH.
 *
 *   make run-pi4                         # static image checks + both VM tiers in parallel (exit 0/1)
 *   make run-pi4 ARGS="--ssh pi4-nas.local"   # same system checks + real-hardware ones, on the Pi (seconds)
 *   make run-pi4 ARGS="--tier uboot"     # only the U-Boot VM (~1 min)   --tier system: only the virt VM
 *   make run-pi4 ARGS="--reboot"         # + reboot, check persistence and 2nd-boot behaviour (VM or --ssh)
 *   make run-pi4 ARGS="--full"           # raspi4b tier boots all the way too (slow: emulated PIO SD)
 *   make run-pi4 ARGS="--run 'journalctl -b -p err'"   # extra commands, VM or --ssh (repeatable)
 *   make pi4-check                       # static image checks only (~5s)
 *   make pi4-vm                          # interactive serial console (virt; ARGS=--full for raspi4b)
 *   node scripts/run-pi4.ts [img] [opts]   /   deno run -A scripts/run-pi4.ts [img] [opts]
 *     opts: --ssh [user@]host[:port]  --password PW (default "testing": SSH + sudo)  --static-only
 *           --tier uboot|system  --full --reboot --interactive --keep --workdir DIR --run CMD
 *   Tools on PATH: VM mode: qemu-system-aarch64 qemu-img qemu-io sfdisk mtype mdir mcopy fdtget fdtput;
 *   --ssh: ssh (+ sshpass for password auth). `nix run .#run-pi4` provides pinned ones.
 *
 *  --ssh: key auth if it works, else password via sshpass. One multiplexed connection
 *     (ControlMaster) for every check, so a run takes seconds. Adds what only real
 *     hardware can show: HDMI connector + vc4 driver, Wi-Fi connected, 8 GB RAM,
 *     getty on tty1. No VM allowances: any failed unit fails the run.
 *
 * Two VMs run in parallel, each covering what it emulates faithfully:
 *
 *  [uboot] QEMU raspi4b (BCM2711, 4x Cortex-A72, rev 1.5). The Pi-specific boot path,
 *     byte for byte from the image: u-boot.bin + vendor DTB from FAT (QEMU stands in for
 *     start4.elf's kernel=u-boot.bin), U-Boot's own bootcmd, partition-flag scan,
 *     extlinux.conf, loading kernel/initrd/mainline DTB, kernel banner. Then it stops,
 *     because the rest is slow here (PIO-only SD, ~10 min) and covered by [system].
 *     --full continues to login using a VM-only DTB (see UNEMULATED) in the overlay.
 *     Caveats: 2 GiB fixed RAM; the card sits on the 0x7e300000 SDHCI, not emmc2;
 *     no HDMI, PCIe/USB or ethernet.
 *
 *  [system] QEMU virt, -cpu cortex-a72 -smp 4 -m 8G (the 8GB board's RAM), virtio disk
 *     + NIC. Boots the *exact* kernel, initrd and APPEND line from the image's
 *     extlinux.conf, directly (no U-Boot; that's [uboot]'s job) on the image's own
 *     partitions, to a login. Then it checks mounts, first-boot root expansion, failed
 *     units, services, sudo, and sshd reachable from the host over a forwarded port.
 *     VM-only additions to the cmdline: console=ttyAMA0 (so this UART is
 *     /dev/console) and a longer systemd device timeout, because coldplug under TCG
 *     takes ~1 min (xz module loading) vs seconds on the Pi, and the stock 90s
 *     timeout would drop to emergency mode.
 *
 * The store image is never modified: each VM gets a throwaway qcow2 overlay.
 * Only erasable TypeScript syntax and node: built-ins, so Node and Deno run it as-is.
 */
import { execFileSync, spawn, spawnSync, type ChildProcess } from "node:child_process";
import * as fs from "node:fs";
import * as net from "node:net";
import * as os from "node:os";
import * as path from "node:path";
import process from "node:process";

process.env.MTOOLS_SKIP_CHECK = "1";

// compatible -> why QEMU raspi4b can't run it (mainline kernel takes a synchronous
// external abort probing these). Only used for [uboot] --full.
const UNEMULATED: Record<string, string> = {
  "brcm,l2-intc": "AON/HDMI L2 interrupt controller",
  "brcm,bcm7271-l2-intc": "L2 interrupt controller",
  "brcm,bcm2711-pcie": "PCIe (VL805 USB)",
  "brcm,bcm2711-genet-v5": "GENET ethernet",
  "brcm,bcm2711-rng200": "RNG200",
  "brcm,bcm2711-thermal": "AVS thermal",
  "brcm,brcm2711-dvp": "HDMI DVP clock gates (sic: brcm2711)",
  "brcm,bcm2711-hdmi0": "HDMI0",
  "brcm,bcm2711-hdmi1": "HDMI1",
  "brcm,bcm2711-hdmi-i2c": "HDMI DDC I2C",
  "brcm,bcm2711-hvs": "HVS",
  "brcm,bcm2711-vc5": "vc4 DRM master",
  "brcm,bcm2711-pixelvalve0": "pixelvalve",
  "brcm,bcm2711-pixelvalve1": "pixelvalve",
  "brcm,bcm2711-pixelvalve2": "pixelvalve",
  "brcm,bcm2711-pixelvalve3": "pixelvalve",
  "brcm,bcm2711-pixelvalve4": "pixelvalve",
  "brcm,2711-v3d": "V3D GPU",
  "brcm,bcm2711-vec": "composite video",
  "brcm,bcm2711-dsi1": "DSI1",
};

// Units allowed to fail *only because* of the VM. Anything else fails the test.
const FAILED_UNITS_EXPECTED_IN_VM: Record<string, string> = {
  "wpa_supplicant-wlan0.service": "no Wi-Fi chip in QEMU",
};

const VM_DEVICE_TIMEOUT = "systemd.default_device_timeout_sec=600";

// ------------------------------------------------------------------ reporting
type Status = "PASS" | "FAIL" | "WARN";
const rows: [Status, string, string][] = [];
const tStart = Date.now();
const secs = (t0: number) => `${Math.round((Date.now() - t0) / 1000)}s`;

/** ok: true=PASS, false=FAIL, null=WARN. Returns ok === true. */
function report(ok: boolean | null, name: string, detail = ""): boolean {
  const s: Status = ok === true ? "PASS" : ok === false ? "FAIL" : "WARN";
  rows.push([s, name, detail]);
  const color = { PASS: 32, FAIL: 31, WARN: 33 }[s];
  const tag = process.stdout.isTTY ? `\x1b[${color}m${s}\x1b[0m` : s;
  console.log(`  [${tag}] ${name}${detail ? `  (${detail})` : ""}`);
  return ok === true;
}
const failed = () => rows.filter((r) => r[0] === "FAIL");
const step = (msg: string) => console.log(`\n==> ${msg}`);

const run = (cmd: string, ...args: string[]) => execFileSync(cmd, args, { encoding: "utf8", maxBuffer: 1 << 28 });
const runBuf = (cmd: string, ...args: string[]) => execFileSync(cmd, args, { maxBuffer: 1 << 28 });
const ok0 = (cmd: string, ...args: string[]) => spawnSync(cmd, args, { stdio: "ignore" }).status === 0;

// ------------------------------------------------------------------ image / FAT helpers
interface Part { start: number; size: number; type: string; bootable?: boolean }
const partitions = (img: string): Part[] => JSON.parse(run("sfdisk", "-J", img)).partitiontable.partitions;
const fatRead = (fat: string, p: string) => runBuf("mtype", "-i", fat, "::" + p);
const fatExists = (fat: string, p: string) => ok0("mdir", "-i", fat, "::" + p);

interface Extlinux { label: string; linux?: string; initrd?: string; fdtdir?: string; fdt?: string; append: string }
function parseExtlinux(text: string): Extlinux {
  const label = /^DEFAULT\s+(\S+)/m.exec(text)![1];
  const entry = text.split(/^LABEL\s+/m).find((b) => b.startsWith(label)) ?? "";
  const get = (k: string) => new RegExp(`^\\s*${k}\\s+(.*)$`, "m").exec(entry)?.[1];
  const rel = (p?: string) => (p ? path.posix.normalize("/extlinux/" + p) : undefined);
  return { label, linux: rel(get("LINUX")), initrd: rel(get("INITRD")), fdtdir: rel(get("FDTDIR")),
           fdt: rel(get("FDT")), append: get("APPEND") ?? "" };
}

function staticChecks(img: string, fat: string): { ext: Extlinux; dtb?: string } {
  step("Static checks of the image (what the real Pi's firmware + U-Boot will see)");
  const [p1, p2] = partitions(img);
  report(p1.bootable === true && ["b", "c"].includes(p1.type), "partition 1 (FAT) is the bootable partition",
         `type=${p1.type} bootable=${!!p1.bootable}`);
  report(!p2.bootable, "partition 2 (btrfs root) is NOT flagged bootable",
         "U-Boot here has no btrfs driver and only scans flagged partitions");

  const cfg = fatRead(fat, "/config.txt").toString();
  report(cfg.includes("kernel=u-boot.bin") && cfg.includes("arm_64bit=1"), "config.txt chainloads 64-bit U-Boot");
  report(cfg.includes("vc4-kms-v3d") ? null : true, "config.txt has no vendor-kernel vc4-kms-v3d overlay");
  const missing = ["/start4.elf", "/fixup4.dat", "/bcm2711-rpi-4-b.dtb", "/u-boot.bin"].filter((f) => !fatExists(fat, f));
  report(missing.length === 0, "Pi 4 firmware files present (start4.elf fixup4.dat vendor DTB u-boot.bin)", missing.join(" "));

  const bootcmd = /bootcmd=([^\x00]*)/.exec(fatRead(fat, "/u-boot.bin").toString("latin1"))?.[1] ?? "";
  report(/bootflow scan -\w*b/.test(bootcmd) || bootcmd.includes("distro_bootcmd"),
         "U-Boot bootcmd actually boots", JSON.stringify(bootcmd));

  const ext = parseExtlinux(fatRead(fat, "/extlinux/extlinux.conf").toString());
  for (const k of ["linux", "initrd"] as const) {
    report(!!ext[k] && fatExists(fat, ext[k]!), `extlinux ${k.toUpperCase()} exists on FAT`, path.basename(ext[k] ?? ""));
  }
  const dtb = ext.fdtdir ? `${ext.fdtdir}/broadcom/bcm2711-rpi-4-b.dtb` : ext.fdt;
  report(!!dtb && fatExists(fat, dtb), "extlinux points U-Boot at the kernel's own (mainline) DTB", dtb && "FDTDIR");
  const consoles = [...ext.append.matchAll(/console=(\w+)/g)].map((m) => m[1]);
  report(/^tty\d+$/.test(consoles.at(-1) ?? "") ? true : null,
         "last console= is the HDMI VT (systemd status goes to /dev/console)", consoles.join(" "));
  return { ext, dtb };
}

// ------------------------------------------------------------------ VM-only DTB ([uboot] --full)
function* fdtNodes(dtb: string, p = "/"): Generator<string> {
  yield p;
  for (const child of run("fdtget", "-l", dtb, p).split(/\s+/).filter(Boolean)) {
    yield* fdtNodes(dtb, `${p.replace(/\/$/, "")}/${child}`);
  }
}

function makeVmDtb(dtb: string): string[] {
  const changes: string[] = [];
  for (const node of [...fdtNodes(dtb)]) {
    const r = spawnSync("fdtget", ["-t", "s", dtb, node, "compatible"], { encoding: "utf8" });
    const compat = r.status === 0 ? r.stdout.split(/\s+/).filter(Boolean) : [];
    const hit = compat.find((c) => c in UNEMULATED);
    if (hit) {
      run("fdtput", "-t", "s", dtb, node, "status", "disabled");
      changes.push(`disabled ${node} (${UNEMULATED[hit]})`);
    }
    if (compat.includes("brcm,bcm2835-sdhci")) { // the SDHCI QEMU wires the SD card to
      spawnSync("fdtput", ["-d", dtb, node, "mmc-pwrseq"], { stdio: "ignore" });
      for (const child of run("fdtget", "-l", dtb, node).split(/\s+/).filter(Boolean)) {
        run("fdtput", "-r", dtb, `${node}/${child}`);
      }
      changes.push(`${node}: plain SD slot (dropped mmc-pwrseq + wifi child)`);
    }
  }
  return changes;
}

// ------------------------------------------------------------------ serial console driver
const ANSI = /\x1b\[[0-9;:?]*[A-Za-z]|\r/g;
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

class Console {
  buf = "";
  pos = 0;
  alive = true;
  n = 0;
  sock!: net.Socket;
  waiters: (() => void)[] = [];
  log!: fs.WriteStream;

  static async connect(sockPath: string, logPath: string): Promise<Console> {
    const c = new Console();
    c.log = fs.createWriteStream(logPath);
    for (let i = 0; ; i++) {
      try {
        c.sock = await new Promise<net.Socket>((res, rej) => {
          const s = net.createConnection({ path: sockPath }, () => res(s));
          s.once("error", rej);
        });
        break;
      } catch (e) {
        if (i > 100) throw e;
        await sleep(100);
      }
    }
    c.sock.on("data", (d: Buffer) => {
      c.log.write(d);
      c.buf += d.toString("latin1").replace(ANSI, "");
      c.wake();
    });
    c.sock.on("close", () => { c.alive = false; c.wake(); });
    c.sock.on("error", () => {});
    return c;
  }

  wake() { this.waiters.splice(0).forEach((w) => w()); }

  /** Wait for pattern after the cursor; advances the cursor past the match. */
  async expect(pattern: string | RegExp, timeoutS: number): Promise<RegExpExecArray | null> {
    const rx = new RegExp(typeof pattern === "string" ? pattern : pattern.source, "g");
    const end = Date.now() + timeoutS * 1000;
    while (true) {
      rx.lastIndex = this.pos;
      const m = rx.exec(this.buf);
      if (m) { this.pos = m.index + m[0].length; return m; }
      const left = end - Date.now();
      if (left <= 0 || !this.alive) return null;
      await new Promise<void>((r) => { this.waiters.push(r); setTimeout(r, Math.min(left, 1000)); });
    }
  }

  /** Emulated UART FIFOs drop bursts, so trickle bytes. */
  async send(text: string) {
    for (const ch of text) { this.sock.write(ch); await sleep(3); }
  }

  /** Run cmd in the logged-in shell; returns [exitCode|null, output]. */
  async sh(cmd: string, timeoutS = 120): Promise<[number | null, string]> {
    const n = ++this.n; // markers built by printf so the echoed command line never matches
    await this.send(`printf '\\n__B%s__\\n' ${n}; ${cmd}; printf '\\n__E%s__ %s\\n' ${n} $?\n`);
    if (!(await this.expect(`\\n__B${n}__\\n`, timeoutS))) return [null, ""];
    const start = this.pos;
    const m = await this.expect(`\\n__E${n}__ (\\d+)\\n`, timeoutS);
    if (!m) return [null, this.buf.slice(start)];
    return [Number(m[1]), this.buf.slice(start, m.index).trim()];
  }
}

// ------------------------------------------------------------------ VM plumbing
interface Vm { proc: ChildProcess; con: Console; tag: string; sockDir: string; root?: Console }

// QEMU assigns -serial options in order: the first is serial0 = PL011 = ttyAMA0, which
// carries U-Boot's and Linux's console on raspi4b and virt. `after` comes after it.
// Never leave an orphaned QEMU eating CPU (one did, and slowed the next run 2x).
const children = new Set<ChildProcess>();
const killAll = () => children.forEach((c) => c.kill("SIGKILL"));
process.on("exit", killAll);
for (const sig of ["SIGINT", "SIGTERM", "SIGHUP"] as const) process.on(sig, () => { killAll(); process.exit(130); });

/** rootShell: also a virtio console (hvc0) for `systemd.debug_shell=hvc0`, i.e. a root
 *  shell from early boot that needs no getty, password or working PAM. VM-only. */
async function startVm(tag: string, wd: string, args: string[], after: string[] = [], rootShell = false): Promise<Vm> {
  const sockDir = fs.mkdtempSync("/tmp/pi4s"); // unix socket paths max out at ~107 bytes
  const sock = path.join(sockDir, "ttyAMA0"), hvc = path.join(sockDir, "hvc0");
  const hvcArgs = rootShell ? ["-device", "virtio-serial-pci", "-chardev", `socket,id=hvc0,path=${hvc},server=on,wait=off`,
                               "-device", "virtconsole,chardev=hvc0"] : [];
  const proc = spawn("qemu-system-aarch64",
    [...args, ...hvcArgs, "-display", "none", "-monitor", "none", "-serial", `unix:${sock},server=on,wait=on`, ...after],
    { stdio: ["ignore", "ignore", fs.openSync(path.join(wd, `${tag}.qemu.stderr`), "w")] });
  children.add(proc);
  const con = await Console.connect(sock, path.join(wd, `${tag}.serial.log`));
  const root = rootShell ? await Console.connect(hvc, path.join(wd, `${tag}.rootshell.log`)) : undefined;
  return { proc, con, tag, sockDir, root };
}

/** Make the debug shell scriptable; resolves false if it never shows up. */
async function rootShellReady(vm: Vm): Promise<boolean> {
  const r = vm.root!;
  for (let i = 0; i < 120; i++) { // the shell only prints its prompt after input
    await r.send("\n");
    if (await r.expect(/#\s*$/, 5)) break;
  }
  await r.send("export PATH=/run/current-system/sw/bin:$PATH SYSTEMD_COLORS=0 SYSTEMD_PAGER= PAGER=cat TERM=dumb; " +
               "stty -echo cols 400 2>/dev/null; PS1='ROOT# '\n");
  const ok = !!(await r.expect("ROOT# ", 60));
  report(ok, `[${vm.tag}] root debug shell on hvc0 (VM-only diagnostics channel)`);
  return ok;
}

function stopVm(vm?: Vm) {
  if (!vm) return;
  vm.con.sock.destroy();
  vm.proc.kill("SIGKILL");
  fs.rmSync(vm.sockDir, { recursive: true, force: true });
}

async function milestones(vm: Vm, t0: number, ms: [string, number, string][]): Promise<boolean> {
  for (const [rx, tmo, name] of ms) {
    const m = await vm.con.expect(rx, tmo);
    const extra = m && /version|U-Boot 20/.test(rx) ? `, ${m[0]}` : "";
    if (!report(!!m, `[${vm.tag}] ${name}`, `t+${secs(t0)}${extra}`)) {
      const tail = vm.con.buf.slice(-1500);
      console.log(`\n--- [${vm.tag}] last console output ---\n${tail}\n---------------------------`);
      if (tail.slice(-200).includes("U-Boot>")) console.log("U-Boot dropped to its prompt: bootcmd didn't boot anything.");
      return false;
    }
  }
  return true;
}

const UBOOT_MS: [string, number, string][] = [
  [String.raw`U-Boot 20\d\d\.\d\d`, 60, "U-Boot started from u-boot.bin"],
  [String.raw`Booting bootflow '[^']*part_1' with extlinux`, 120, "U-Boot picked partition 1 + extlinux.conf"],
  [String.raw`Starting kernel \.\.\.`, 240, "U-Boot loaded kernel + initrd + mainline DTB, jumped to it"],
];
// Only with --full (VM DTB): with the real DTB the kernel aborts on unemulated hardware
// before its UART driver registers, so it can't print. [system] proves the same Image.
const UBOOT_KERNEL_MS: [string, number, string][] = [[String.raw`Linux version \S+`, 120, "kernel started"]];
// kmsg lines reach every console=, whichever one is /dev/console
const LINUX_MS = (disk: string): [string, number, string][] => [
  [String.raw`BTRFS info \(device ${disk}\): first mount`, 600, "stage 1 found NIXOS_SD, mounted btrfs root"],
  [String.raw`systemd\[1\]: (Switching root|Detected architecture arm64)|Welcome to NixOS`, 300, "stage 2 systemd started"],
  [String.raw`pi4-nas login:`, 900, "getty on the serial console"],
];

async function login(vm: Vm): Promise<boolean> {
  const con = vm.con;
  await con.send("izelnakri\n");
  let ok = !!(await con.expect("Password:", 60));
  await con.send("testing\n");
  ok &&= !!(await con.expect(/[$%#>] ?$|\n.*[$%#] /, 120));
  await con.send("PROMPT='VMTEST> '; PS1='VMTEST> '; stty -echo cols 400; " +
                 "export SYSTEMD_PAGER= SYSTEMD_COLORS=0 PAGER=cat TERM=dumb\n");
  ok &&= !!(await con.expect("VMTEST> ", 60));
  report(ok, `[${vm.tag}] logged in as izelnakri / ${PASSWORD} on the serial console`);
  if (!ok) return false;
  const [, out] = await con.sh(`${sudo()} sh -c 'dmesg -n 1; id -u'`); // also keeps kmsg out of output
  report(out.trim().endsWith("0"), `[${vm.tag}] izelnakri has root via sudo`, out.trim().split("\n").at(-1));
  return true;
}

async function unexpectedFailedUnits(t: Target): Promise<string[]> {
  const [, out] = await t.sh("systemctl --failed --plain --no-legend | awk '{print $1}'");
  const units = out.split(/\s+/).filter(Boolean);
  const allowed = t.real ? {} : FAILED_UNITS_EXPECTED_IN_VM; // real hardware gets no allowances
  for (const u of units.filter((u) => u in allowed)) {
    report(null, `[${t.tag}] ${u} failed`, `expected in VM: ${allowed[u]}`);
  }
  const bad = units.filter((u) => !(u in allowed));
  for (const u of bad) {
    const [, why] = await t.sh(`journalctl -b -u ${u} --no-pager -n 12 -o cat`);
    console.log(`      --- ${u} ---\n      ${why.replace(/\n/g, "\n      ")}`);
  }
  return bad;
}

function sshBanner(port: number, timeoutS: number): Promise<string> {
  return new Promise((res) => {
    const s = net.createConnection({ host: "127.0.0.1", port });
    const done = (v: string) => { s.destroy(); res(v); };
    s.setTimeout(timeoutS * 1000, () => done(""));
    s.on("data", (d: Buffer) => done(d.toString().trim()));
    s.on("error", () => done(""));
  });
}

/** Something checks can run shell commands on: a VM's serial console or an SSH session. */
interface Target { tag: string; real: boolean; sh(cmd: string, timeoutS?: number): Promise<[number | null, string]> }
const vmTarget = (vm: Vm): Target => ({ tag: vm.tag, real: false, sh: (c, t) => vm.con.sh(c, t) });

let PASSWORD = "testing"; // izelnakri's initialPassword: login, SSH fallback, sudo
const sudo = () => `echo '${PASSWORD.replace(/'/g, "'\\''")}' | sudo -S -p ''`;

function sshTarget(dest: string): Target {
  const port = /:(\d+)$/.exec(dest)?.[1]; // [user@]host[:port]
  const bare = port ? dest.slice(0, -port.length - 1) : dest;
  const host = bare.includes("@") ? bare : `izelnakri@${bare}`;
  const ctl = path.join(fs.mkdtempSync("/tmp/pi4ssh"), "c");
  const common = ["-o", "ControlMaster=auto", "-o", `ControlPath=${ctl}`, "-o", "ControlPersist=120",
                  "-o", "ConnectTimeout=10", "-o", "ServerAliveInterval=5", "-o", "StrictHostKeyChecking=accept-new",
                  "-o", "LogLevel=ERROR", ...(port ? ["-p", port] : [])];
  let usePassword = false;
  const exec = (cmd: string, timeoutS: number): Promise<[number | null, string]> => new Promise((res) => {
    const args = usePassword
      ? ["-e", "ssh", ...common, "-o", "PubkeyAuthentication=no", "-o", "PreferredAuthentications=password", host, cmd]
      : [...common, "-o", "BatchMode=yes", host, cmd];
    const p = spawn(usePassword ? "sshpass" : "ssh", args,
                    { env: { ...process.env, SSHPASS: PASSWORD }, stdio: ["ignore", "pipe", "pipe"] });
    let out = "";
    p.stdout!.on("data", (d) => (out += d));
    p.stderr!.on("data", (d) => (out += d));
    const timer = setTimeout(() => p.kill("SIGKILL"), timeoutS * 1000);
    p.on("error", () => {});
    p.on("close", (code) => { clearTimeout(timer); res([code === null ? null : code, out.trim()]); });
  });
  let ready: Promise<void> | null = null;
  const connect = async (): Promise<void> => {
    const [kc] = await exec("true", 20);
    if (kc === 0) { report(true, "[ssh] connected (key auth)", host); return; }
    usePassword = true;
    const [pc, po] = await exec("true", 30);
    report(pc === 0, "[ssh] connected (password auth)", pc === 0 ? host : `${host}: ${po || "unreachable"}`);
    if (pc !== 0) throw new Error("ssh failed");
  };
  return { tag: "ssh", real: true, sh: async (cmd, t = 120) => { await (ready ??= connect()); return exec(cmd, t); } };
}

interface CheckOpts { ext?: Extlinux; disk: string; sshPort: number | null; extra: string[] }

async function systemChecks(t: Target, o: CheckOpts) {
  const { ext, disk, sshPort, extra } = o;
  const p = (n: number) => (/\d$/.test(disk) ? `${disk}p${n}` : `${disk}${n}`);
  const check = async (name: string, cmd: string, pred: (c: number, o: string) => boolean,
                       timeoutS = 120, warn = false) => {
    const [code, out] = await t.sh(cmd, timeoutS);
    const ok = code !== null && pred(code, out);
    report(ok || !warn ? ok : null, `[${t.tag}] ${name}`, out.replace(/\n/g, " | ").slice(0, 140));
    return out;
  };

  // First: everything below needs a finished boot (/boot mounted, first-boot expansion done).
  // The VM root shell exists from early stage 2, long before that.
  await check("system finished booting", "systemctl is-system-running --wait",
              (_, o) => ["running", "degraded"].includes(o.trim()), 900);
  const kver = /linux-\S*?-(\d+\.\d+\.\d+)/.exec(ext?.linux ?? "")?.[1];
  await check(ext ? "running the kernel from extlinux.conf" : "kernel", "uname -r",
              (c, o) => c === 0 && (!kver || o.trim() === kver));
  await check("cmdline is a NixOS extlinux boot", "cat /proc/cmdline",
              (_, o) => o.includes("root=fstab") && (ext ? o.includes(ext.append.split(" ")[0]) : /init=\/nix\/store\//.test(o)));
  await check("DT is the Pi 4 Model B", "tr -d '\\0' </proc/device-tree/model 2>/dev/null || echo none",
              (_, o) => t.tag === "system" || o.includes("Raspberry Pi 4 Model B")); // virt has its own DT
  await check("/ is btrfs on partition 2", "findmnt -no SOURCE,FSTYPE /", (_, o) => new RegExp(`${p(2)}(\\[/\\])?\\s+btrfs`).test(o));
  await check("/boot is the FAT firmware partition", "findmnt -no SOURCE,FSTYPE /boot", (_, o) => new RegExp(`${p(1)}\\s+vfat`).test(o));
  await check("bootloader files visible under /boot", "ls /boot/extlinux/extlinux.conf /boot/u-boot.bin /boot/config.txt",
              (c) => c === 0);
  // Works on 1st and later boots: the root partition + btrfs fill the card (VM: the 16 GiB overlay).
  await check("root partition + btrfs expanded to the whole disk",
              `lsblk -bndo SIZE /dev/${disk}; lsblk -bndo SIZE /dev/${p(2)}; df -B1 --output=size / | tail -1`,
              (c, o) => { const [d, part, fsz] = o.split(/\s+/).map(Number); return c === 0 && part > d * 0.9 && fsz > d * 0.85; });
  const bad = await unexpectedFailedUnits(t);
  report(bad.length === 0, `[${t.tag}] no unexpected failed units`, bad.join(" "));
  const [, act] = await t.sh("systemctl is-active sshd NetworkManager systemd-timesyncd avahi-daemon | paste -sd' '");
  report(act.trim() === "active active active active", `[${t.tag}] sshd NetworkManager timesyncd avahi active`, act.trim());
  await check("console shows a login prompt (no autologin)", "systemctl cat getty@tty1 | grep -c -- '--autologin' || true",
              (_, o) => o.trim() === "0");
  if (t.real) await check("izelnakri has root via sudo", `${sudo()} id -u`, (_, o) => o.trim().endsWith("0"));
  await check("no kernel oops/BUG", "journalctl -k -b --no-pager -o cat | grep -cE 'Oops|BUG:|Call trace' || true",
              (_, o) => o.trim() === "0", 120, true);
  await check("RAM is the 8 GB board's", "awk '/MemTotal/{print $2}' /proc/meminfo",
              (_, o) => Number(o) > 7 * 1024 * 1024, 30, true);
  if (sshPort || t.real) {
    await check("NetworkManager has a default route", "ip -4 route show default", (_, o) => o.includes("default via"), 60);
  }
  if (sshPort) {
    const banner = await sshBanner(sshPort, 30);
    report(banner.startsWith("SSH-2.0-"), `[${t.tag}] sshd reachable from the host over the network`, banner);
  }
  if (t.real) { // only real hardware can show these
    await check("vc4 HDMI driver bound", "ls -d /sys/bus/platform/drivers/vc4-drm/*.gpu 2>/dev/null", (c) => c === 0);
    await check("HDMI monitor detected", "cat /sys/class/drm/card*-HDMI-A-*/status | paste -sd' '",
                (_, o) => o.includes("connected") && !/^(disconnected ?)+$/.test(o.trim()), 30, true);
    await check("getty on tty1 (HDMI) running", "systemctl is-active getty@tty1", (_, o) => o.trim() === "active");
    await check("Wi-Fi connected", "nmcli -t -f DEVICE,TYPE,STATE dev | grep ':wifi:'",
                (_, o) => o.includes(":wifi:connected"), 30, true);
    await check("not undervolted/throttled", "journalctl -k -b --no-pager -o cat | grep -ci 'under-voltage' || true",
                (_, o) => o.trim() === "0", 30, true);
  }
  for (const cmd of extra) {
    const [code, out] = await t.sh(cmd, 300);
    console.log(`\n[${t.tag}] $ ${cmd}   [exit ${code}]\n${out}`);
  }
}

async function rebootChecks(vm: Vm, t0Ref: { t: number }, ms: [string, number, string][]) {
  await vm.con.sh("echo persisted >~/.vmtest && sync");
  await vm.con.send(`${sudo()} systemctl reboot\n`);
  t0Ref.t = Date.now();
  if (!(await milestones(vm, t0Ref.t, ms)) || !(await login(vm))) return;
  report((await vm.con.sh("cat ~/.vmtest"))[1].trim() === "persisted", `[${vm.tag}] file written before reboot survived`);
  const [, cond] = await vm.con.sh("systemctl show -p ConditionResult --value expand-root-partition");
  report(cond.trim() === "no", `[${vm.tag}] root expansion skipped on 2nd boot`, `ConditionResult=${cond.trim()}`);
  const bad = await unexpectedFailedUnits(vmTarget(vm));
  report(bad.length === 0, `[${vm.tag}] no unexpected failed units on 2nd boot`, bad.join(" "));
}

/** Reboot the real Pi over SSH and wait for it to come back (bounded, polls every 3s). */
async function sshRebootChecks(t: Target) {
  step("Rebooting the Pi");
  const [, boot1] = await t.sh("cat /proc/sys/kernel/random/boot_id; echo persisted >~/.vmtest; sync");
  await t.sh(`${sudo()} systemd-run --on-active=2 systemctl reboot`, 20);
  const t0 = Date.now();
  let boot2 = "";
  while (Date.now() - t0 < 300_000) {
    await sleep(3000);
    const [c, o] = await t.sh("cat /proc/sys/kernel/random/boot_id", 8);
    if (c === 0 && o.split("\n")[0] !== boot1.split("\n")[0]) { boot2 = o; break; }
  }
  if (!report(!!boot2, "[ssh] Pi rebooted and is reachable again", `t+${secs(t0)}`)) return;
  report((await t.sh("cat ~/.vmtest"))[1].trim() === "persisted", "[ssh] file written before reboot survived");
  const bad = await unexpectedFailedUnits(t);
  report(bad.length === 0, "[ssh] no failed units after reboot", bad.join(" "));
}

const freePort = () => new Promise<number>((res) => {
  const s = net.createServer().listen(0, "127.0.0.1", () => { const p = (s.address() as net.AddressInfo).port; s.close(() => res(p)); });
});

// ------------------------------------------------------------------ main
function parseArgs(argv: string[]) {
  const a = { image: "", interactive: false, reboot: false, keep: false, full: false, staticOnly: false,
              workdir: "", tier: "", ssh: "", run: [] as string[] };
  for (let i = 0; i < argv.length; i++) {
    const x = argv[i];
    if (x === "--interactive") a.interactive = true;
    else if (x === "--reboot") a.reboot = true;
    else if (x === "--keep") a.keep = true;
    else if (x === "--full") a.full = true;
    else if (x === "--static-only") a.staticOnly = true;
    else if (x === "--workdir") a.workdir = argv[++i];
    else if (x === "--tier") a.tier = argv[++i]; // uboot | system (default: both)
    else if (x === "--ssh") a.ssh = argv[++i];
    else if (x === "--password") PASSWORD = argv[++i];
    else if (x === "--run") a.run.push(argv[++i]);
    else if (x === "-h" || x === "--help") { console.log("see the header of scripts/run-pi4.ts"); process.exit(0); }
    else if (x.startsWith("-")) { console.error(`unknown option ${x}`); process.exit(2); }
    else a.image = x;
  }
  return a;
}

function copyRange(src: string, dst: string, offset: number, length: number) {
  const fi = fs.openSync(src, "r"), fo = fs.openSync(dst, "w");
  const chunk = Buffer.alloc(1 << 24);
  for (let done = 0; done < length;) {
    const n = fs.readSync(fi, chunk, 0, Math.min(chunk.length, length - done), offset + done);
    fs.writeSync(fo, chunk, 0, n);
    done += n;
  }
  fs.closeSync(fi); fs.closeSync(fo);
}

const TOOLS = ["qemu-system-aarch64", "qemu-img", "qemu-io", "sfdisk", "mtype", "mdir", "mcopy", "fdtget", "fdtput"];

async function main() {
  const a = parseArgs(process.argv.slice(2));
  if (a.ssh) { // real hardware: no image, no VMs
    step(`System checks on the real Pi: ${a.ssh}`);
    const t = sshTarget(a.ssh);
    try {
      await systemChecks(t, { disk: "mmcblk0", sshPort: null, extra: a.run });
      if (a.reboot) await sshRebootChecks(t);
    } catch { /* connection failure already reported */ }
    const bad = failed();
    step(`Summary: ${rows.length - bad.length}/${rows.length} passed in ${secs(tStart)}`);
    for (const [, n, d] of bad) console.log(`  FAIL ${n}  ${d}`);
    process.exit(bad.length ? 1 : 0);
  }
  const missing = TOOLS.filter((t) => spawnSync("sh", ["-c", `command -v ${t}`], { stdio: "ignore" }).status !== 0);
  if (missing.length) {
    console.error(`missing on PATH: ${missing.join(" ")}\nuse \`nix run .#run-pi4\` (pinned tools) or ` +
                  "`nix shell nixpkgs#{qemu,dtc,mtools,util-linux}`");
    process.exit(2);
  }
  let img = a.image;
  if (!img) {
    const dir = "result-pi4-nas/sd-image";
    const f = fs.existsSync(dir) ? fs.readdirSync(dir).filter((x) => x.endsWith(".img")).sort()[0] : undefined;
    img = f ? path.join(dir, f) : "";
  }
  if (!img || !fs.existsSync(img)) { console.error("no image; run `make pi4-image` or pass the .img path"); process.exit(2); }
  img = fs.realpathSync(img);
  const wd = a.workdir || fs.mkdtempSync(path.join(os.tmpdir(), "pi4-vm-"));
  fs.mkdirSync(wd, { recursive: true });
  console.log(`image:   ${img}\nworkdir: ${wd}`);

  const [p1, p2] = partitions(img);
  const fat = path.join(wd, "firmware.img");
  copyRange(img, fat, p1.start * 512, p1.size * 512);
  const { ext, dtb } = staticChecks(img, fat);
  const out = (name: string, data: Buffer) => { const f = path.join(wd, name); fs.writeFileSync(f, data); return f; };
  const uboot = out("u-boot.bin", fatRead(fat, "/u-boot.bin"));
  const fwDtb = out("fw.dtb", fatRead(fat, "/bcm2711-rpi-4-b.dtb"));
  const kernel = ext.linux && out("Image", fatRead(fat, ext.linux));
  const initrd = ext.initrd && out("initrd", fatRead(fat, ext.initrd));

  const finish = () => {
    const bad = failed();
    step(`Summary: ${rows.length - bad.length}/${rows.length} passed in ${secs(tStart)}`);
    for (const [, n, d] of bad) console.log(`  FAIL ${n}  ${d}`);
    if (bad.length || a.keep) console.log(`  kept ${wd} (*.serial.log, *.qemu.stderr, overlays)`);
    else fs.rmSync(wd, { recursive: true, force: true });
    process.exit(bad.length ? 1 : 0);
  };
  if (a.staticOnly || failed().length) { fs.unlinkSync(fat); finish(); }

  // overlays: the store image is the read-only backing file
  const overlay = (name: string, size?: number) => {
    const f = path.join(wd, name);
    run("qemu-img", "create", "-q", "-f", "qcow2", "-F", "raw", "-b", img, f, ...(size ? [String(size)] : []));
    return f;
  };
  const piDisk = overlay("raspi4b.qcow2", 2 ** Math.ceil(Math.log2(fs.statSync(img).size + 1))); // SD: power of 2
  if (a.full && dtb) { // VM-only DTB, written only into the raspi4b overlay
    const vmDtb = path.join(wd, "vm.dtb");
    fs.writeFileSync(vmDtb, fatRead(fat, dtb), { mode: 0o644 });
    makeVmDtb(vmDtb);
    run("mcopy", "-o", "-i", fat, vmDtb, "::" + dtb);
    run("qemu-io", "-f", "qcow2", "-c", `write -s ${fat} ${p1.start * 512} ${p1.size * 512}`, piDisk);
  }
  fs.unlinkSync(fat);
  const virtDisk = overlay("virt.qcow2", 16 * 2 ** 30); // room for expand-root-partition

  const piArgs = ["-M", "raspi4b", "-kernel", uboot, "-dtb", fwDtb, "-drive", `file=${piDisk},if=sd,format=qcow2`];
  const piSerial1 = ["-serial", "null"]; // mini-UART (ttyS1), after serial0
  const sshPort = await freePort();
  const virtArgs = ["-M", "virt", "-cpu", "cortex-a72", "-smp", "4", "-m", "8G",
    "-accel", "tcg,thread=multi,tb-size=1024", "-kernel", kernel!, "-initrd", initrd!,
    "-append", `${ext.append} console=ttyAMA0 ${VM_DEVICE_TIMEOUT}${a.interactive ? "" : " systemd.debug_shell=hvc0"}`,
    "-drive", `file=${virtDisk},if=virtio,format=qcow2,cache=unsafe`,
    "-nic", `user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:${sshPort}-:22`];

  if (a.interactive) {
    const args = a.full ? piArgs : virtArgs;
    step(`Interactive ${a.full ? "raspi4b" : "virt"} VM. Login izelnakri/testing, quit with Ctrl-A X` +
         (a.full ? "" : `, ssh -p ${sshPort} izelnakri@127.0.0.1`));
    const r = spawnSync("qemu-system-aarch64", [...args, "-display", "none", "-serial", "mon:stdio",
                        ...(a.full ? piSerial1 : [])], { stdio: "inherit" });
    console.log(`workdir kept: ${wd}`);
    process.exit(r.status ?? 1);
  }

  step(`Booting both VMs in parallel (logs: ${wd}/{uboot,system}.serial.log)`);
  const vms: Vm[] = [];
  const ubootTier = async () => {
    const vm = await startVm("uboot", wd, piArgs, piSerial1);
    vms.push(vm);
    const t0 = Date.now();
    const ok = await milestones(vm, t0, a.full ? [...UBOOT_MS, ...UBOOT_KERNEL_MS, ...LINUX_MS("mmcblk0p2")] : UBOOT_MS);
    if (ok && a.full && await login(vm)) await systemChecks(vmTarget(vm), { ext, disk: "mmcblk0", sshPort: null, extra: [] });
    stopVm(vm);
  };
  const systemTier = async () => {
    const vm = await startVm("system", wd, virtArgs, [], true);
    vms.push(vm);
    const t0 = { t: Date.now() };
    const ms: [string, number, string][] = [[String.raw`Linux version \S+`, 60, "kernel started"], ...LINUX_MS("vda2")];
    const boot = ms.slice(0, -1), getty = ms.slice(-1);
    if (await milestones(vm, t0.t, boot) && await rootShellReady(vm)) {
      const rootT: Target = { tag: "system", real: false, sh: (c, tm) => vm.root!.sh(c, tm) };
      // System checks as root over hvc0, while the serial console independently proves the
      // real user login (getty + PAM + password + sudo) once getty is up.
      await Promise.all([
        systemChecks(rootT, { ext, disk: "vda", sshPort, extra: a.run }),
        (async () => { if (await milestones(vm, t0.t, getty)) await login(vm); })(),
      ]);
      if (a.reboot) await rebootChecks(vm, t0, ms);
    }
    stopVm(vm);
  };
  try {
    await Promise.all([a.tier !== "system" && ubootTier(), a.tier !== "uboot" && systemTier()]);
  } finally {
    vms.forEach(stopVm);
  }
  finish();
}

await main();
