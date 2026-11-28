#!/usr/bin/env -S deno run --allow-all --quiet
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
 *   deno run -A scripts/run-pi4.ts [img] [opts]   (`nix run .#run-pi4` pins Deno + the tools)
 *     opts: --keep-going (default: stop at the first FAIL)  --ssh [user@]host[:port]  --password PW (default "testing": SSH + sudo)  --static-only
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
 * Runs on Deno (node: built-in modules, all I/O async). Only erasable TypeScript syntax is used,
 * so it would also run under Node >= 23.6 with native type stripping.
 */
import { execFile, spawn, type ChildProcess } from "node:child_process";
import * as fs from "node:fs";
import * as fsp from "node:fs/promises";
import { pipeline } from "node:stream/promises";
import { promisify } from "node:util";
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

// Fail fast by default: the first FAIL throws, VMs are killed in main's finally, exit 1.
// --keep-going runs every check instead (full report).
let FAIL_FAST = true;
class FailFast extends Error {}

/** ok: true=PASS, false=FAIL, null=WARN. Returns ok === true. */
function report(ok: boolean | null, name: string, detail = ""): boolean {
  const s: Status = ok === true ? "PASS" : ok === false ? "FAIL" : "WARN";
  rows.push([s, name, detail]);
  const color = { PASS: 32, FAIL: 31, WARN: 33 }[s];
  const tag = process.stdout.isTTY ? `\x1b[${color}m${s}\x1b[0m` : s;
  console.log(`  [${tag}] ${name}${detail ? `  (${detail})` : ""}`);
  if (s === "FAIL" && FAIL_FAST) throw new FailFast(name);
  return ok === true;
}
const failed = () => rows.filter((r) => r[0] === "FAIL");
const step = (msg: string) => console.log(`\n==> ${msg}`);

const execFileP = promisify(execFile);
const run = async (cmd: string, ...args: string[]): Promise<string> =>
  (await execFileP(cmd, args, { encoding: "utf8", maxBuffer: 1 << 28 })).stdout;
const runBuf = async (cmd: string, ...args: string[]): Promise<Buffer> =>
  (await execFileP(cmd, args, { encoding: "buffer", maxBuffer: 1 << 28 })).stdout;
const ok0 = (cmd: string, ...args: string[]): Promise<boolean> => execFileP(cmd, args).then(() => true, () => false);
const exists = (p: string): Promise<boolean> => fsp.access(p).then(() => true, () => false);

// ------------------------------------------------------------------ image / FAT helpers
interface Part { start: number; size: number; type: string; bootable?: boolean }
const partitions = async (img: string): Promise<Part[]> => JSON.parse(await run("sfdisk", "-J", img)).partitiontable.partitions;
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

async function staticChecks(img: string, fat: string): Promise<{ ext: Extlinux; dtb?: string }> {
  step("Static checks of the image (what the real Pi's firmware + U-Boot will see)");
  // Independent reads run concurrently; reports below stay in a fixed order.
  const fwFiles = ["/start4.elf", "/fixup4.dat", "/bcm2711-rpi-4-b.dtb", "/u-boot.bin"];
  const [[p1, p2], cfgBuf, ubootBuf, extBuf, fwPresent] = await Promise.all([
    partitions(img), fatRead(fat, "/config.txt"), fatRead(fat, "/u-boot.bin"), fatRead(fat, "/extlinux/extlinux.conf"),
    Promise.all(fwFiles.map((f) => fatExists(fat, f))),
  ]);
  report(p1.bootable === true && ["b", "c"].includes(p1.type), "partition 1 (FAT) is the bootable partition",
         `type=${p1.type} bootable=${!!p1.bootable}`);
  report(!p2.bootable, "partition 2 (btrfs root) is NOT flagged bootable",
         "U-Boot here has no btrfs driver and only scans flagged partitions");

  const cfg = cfgBuf.toString();
  report(cfg.includes("kernel=u-boot.bin") && cfg.includes("arm_64bit=1"), "config.txt chainloads 64-bit U-Boot");
  report(cfg.includes("vc4-kms-v3d") ? null : true, "config.txt has no vendor-kernel vc4-kms-v3d overlay");
  const missing = fwFiles.filter((_, i) => !fwPresent[i]);
  report(missing.length === 0, "Pi 4 firmware files present (start4.elf fixup4.dat vendor DTB u-boot.bin)", missing.join(" "));

  const bootcmd = /bootcmd=([^\x00]*)/.exec(ubootBuf.toString("latin1"))?.[1] ?? "";
  report(/bootflow scan -\w*b/.test(bootcmd) || bootcmd.includes("distro_bootcmd"),
         "U-Boot bootcmd actually boots", JSON.stringify(bootcmd));

  const ext = parseExtlinux(extBuf.toString());
  const dtb = ext.fdtdir ? `${ext.fdtdir}/broadcom/bcm2711-rpi-4-b.dtb` : ext.fdt;
  const [hasLinux, hasInitrd, hasDtb] = await Promise.all(
    [ext.linux, ext.initrd, dtb].map((p) => (p ? fatExists(fat, p) : Promise.resolve(false))));
  report(hasLinux, "extlinux LINUX exists on FAT", path.basename(ext.linux ?? ""));
  report(hasInitrd, "extlinux INITRD exists on FAT", path.basename(ext.initrd ?? ""));
  report(hasDtb, "extlinux points U-Boot at the kernel's own (mainline) DTB", dtb && "FDTDIR");
  const consoles = [...ext.append.matchAll(/console=(\w+)/g)].map((m) => m[1]);
  report(/^tty\d+$/.test(consoles.at(-1) ?? "") ? true : null,
         "last console= is the HDMI VT (systemd status goes to /dev/console)", consoles.join(" "));
  return { ext, dtb };
}

// ------------------------------------------------------------------ unit test: bt-autopair
// Runs the image's real bt-autopair script on the host against a mock `bluetoothctl` (a small
// state machine standing in for the keyboard). Deterministic, seconds, no VM or radio needed.
// "@{" stands for bash's "${" (a JS template literal can't hold "${" without interpolating).
const bash = (src: string) => src.replaceAll("@{", "${");
const MOCK_BTCTL = bash(String.raw`#!/usr/bin/env bash
# state: $STATE/{discoverable,paired,trusted,connected}; every call is logged to $STATE/calls
echo "$*" >> "$STATE/calls"
args=("$@"); while [[ "@{args[0]}" == --* ]]; do args=("@{args[@]:2}"); done
yn() { [ -e "$STATE/$1" ] && echo yes || echo no; }
case "@{args[0]}" in
  info) [ -e "$STATE/known" ] || { echo "Device @{args[1]} not available"; exit 1; }
        echo "Device @{args[1]}"; echo "Paired: $(yn paired)"; echo "Trusted: $(yn trusted)"; echo "Connected: $(yn connected)";;
  scan) [ -e "$STATE/discoverable" ] && touch "$STATE/known";;
  pair) if [ -e "$STATE/known" ] && [ -e "$STATE/discoverable" ]; then touch "$STATE/paired"; echo "Pairing successful"; else echo "Device not available"; exit 1; fi;;
  trust) [ -e "$STATE/known" ] && touch "$STATE/trusted";;
  connect) [ -e "$STATE/paired" ] && [ -e "$STATE/discoverable" ] && touch "$STATE/connected" && echo "Connection successful";;
esac`);
// \`sleep\` ends the loop after N iterations (the real script loops forever)
const MOCK_SLEEP = bash(String.raw`#!/usr/bin/env bash
n=$(( $(cat "$STATE/loops" 2>/dev/null || echo 0) + 1 )); echo $n > "$STATE/loops"
[ $n -ge @{LOOPS:-2} ] && kill -TERM $PPID; exit 0`);

async function btAutopairUnitTest(top: string) {
  const unit = path.join(top, "etc/systemd/system/bt-autopair.service");
  if (!(await exists(unit))) { report(null, "bt-autopair unit test", "no bt-autopair in this image"); return; }
  const exec = /^ExecStart=(\S+)/m.exec(await fsp.readFile(unit, "utf8"))?.[1];
  const script = (await fsp.readFile(exec!, "utf8")).replace(/\/nix\/store\/[a-z0-9]{32}-bluez-[^/]+\/bin\/bluetoothctl/g, "bluetoothctl");
  const mac = /devices="([^"]+)"/.exec(script)?.[1] ?? "?";
  /** One scenario in its own temp dir: initial mock state -> the calls made + the final state. */
  const scenario = async (state: string[], loops: number) => {
    const d = await fsp.mkdtemp(path.join(os.tmpdir(), "btmock-")), bin = path.join(d, "bin"), st = path.join(d, "state");
    await Promise.all([fsp.mkdir(bin), fsp.mkdir(st)]);
    await Promise.all([
      fsp.writeFile(path.join(bin, "bluetoothctl"), MOCK_BTCTL, { mode: 0o755 }),
      fsp.writeFile(path.join(bin, "sleep"), MOCK_SLEEP, { mode: 0o755 }),
      fsp.writeFile(path.join(d, "script.sh"), script),
      ...state.map((f) => fsp.writeFile(path.join(st, f), "")),
    ]);
    // The loop ends when the mock `sleep` kills it, so a non-zero exit is expected.
    await execFileP("bash", [path.join(d, "script.sh")], {
      env: { ...process.env, PATH: `${bin}:${process.env.PATH}`, STATE: st, LOOPS: String(loops) }, timeout: 20000,
    }).catch(() => {});
    const calls = (await fsp.readFile(path.join(st, "calls"), "utf8").catch(() => "")).trim().split("\n").filter(Boolean);
    const final = new Set(await fsp.readdir(st));
    await fsp.rm(d, { recursive: true, force: true });
    return { calls: calls.map((c) => c.replace(/^(--\S+ \S+ )+/, "").split(" ")[0]), has: (f: string) => final.has(f) };
  };
  const [pairing, off, reconnect] = await Promise.all([
    scenario(["discoverable"], 2),                                   // keyboard in pairing mode
    scenario([], 2),                                                 // keyboard off
    scenario(["known", "paired", "trusted", "discoverable"], 1),     // paired keyboard turned on
  ]);
  // 1. keyboard in pairing mode -> scan, pair (NoInputNoOutput), trust, connect
  let r = pairing;
  const seq = r.calls.filter((c) => c !== "info").join(">");
  report(/scan>pair>trust>connect/.test(seq) && r.has("connected"),
         `bt-autopair unit: keyboard ${mac} in pairing mode gets paired, trusted, connected`, seq);
  // 2. keyboard off -> no trust/connect, no crash
  r = off;
  report(!r.calls.includes("trust") && !r.calls.includes("connect") && r.calls.includes("pair"),
         "bt-autopair unit: keyboard off -> keeps scanning, no trust/connect", r.calls.filter((c) => c !== "info").join(">"));
  // 3. already paired + trusted but disconnected -> reconnect, no re-pair
  r = reconnect;
  report(r.has("connected") && !r.calls.includes("pair"),
         "bt-autopair unit: paired keyboard turned on -> reconnects without re-pairing", r.calls.filter((c) => c !== "info").join(">"));
}

// ------------------------------------------------------------------ VM-only DTB ([uboot] --full)
/** All node paths of a DTB (children listed concurrently). */
async function fdtNodes(dtb: string, p = "/"): Promise<string[]> {
  const children = (await run("fdtget", "-l", dtb, p)).split(/\s+/).filter(Boolean);
  const sub = await Promise.all(children.map((c) => fdtNodes(dtb, `${p.replace(/\/$/, "")}/${c}`)));
  return [p, ...sub.flat()];
}

async function makeVmDtb(dtb: string): Promise<string[]> {
  const nodes = await fdtNodes(dtb);
  // Reads concurrently; writes below stay sequential (they all modify the same file).
  const compats = await Promise.all(nodes.map((n) =>
    run("fdtget", "-t", "s", dtb, n, "compatible").then((o) => o.split(/\s+/).filter(Boolean), () => [] as string[])));
  const changes: string[] = [];
  for (const [i, node] of nodes.entries()) {
    const compat = compats[i];
    const hit = compat.find((c) => c in UNEMULATED);
    if (hit) {
      await run("fdtput", "-t", "s", dtb, node, "status", "disabled");
      changes.push(`disabled ${node} (${UNEMULATED[hit]})`);
    }
    if (compat.includes("brcm,bcm2835-sdhci")) { // the SDHCI QEMU wires the SD card to
      await ok0("fdtput", "-d", dtb, node, "mmc-pwrseq");
      for (const child of (await run("fdtget", "-l", dtb, node)).split(/\s+/).filter(Boolean)) {
        await run("fdtput", "-r", dtb, `${node}/${child}`);
      }
      changes.push(`${node}: plain SD slot (dropped mmc-pwrseq + wifi child)`);
    }
  }
  return changes;
}

// ------------------------------------------------------------------ serial console driver
// CSI (colors, cursor) + OSC (e.g. systemd 260's "\e]3008;start=..." shell-context markers) + CR
const ANSI = /\x1b\[[0-9;:?!<=>]*[A-Za-z]|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b[78=>]|\r/g;
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

  private queue: Promise<unknown> = Promise.resolve();

  /** Run cmd in the shell; returns [exitCode|null, output]. Calls are queued (one at a time),
   *  so concurrent check groups can share a console: their *waits* overlap, commands don't. */
  sh(cmd: string, timeoutS = 120): Promise<[number | null, string]> {
    const run = () => this.shNow(cmd, timeoutS);
    const p = this.queue.then(run, run);
    this.queue = p.catch(() => {});
    return p;
  }

  private async shNow(cmd: string, timeoutS: number): Promise<[number | null, string]> {
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
/** QEMU human monitor (HMP): virtual-keyboard input and screenshots. */
class Monitor {
  sock!: net.Socket;
  static async connect(sockPath: string): Promise<Monitor> {
    const m = new Monitor();
    for (let i = 0; ; i++) {
      try {
        m.sock = await new Promise<net.Socket>((res, rej) => {
          const s = net.createConnection({ path: sockPath }, () => res(s));
          s.once("error", rej);
        });
        m.sock.on("data", () => {});
        m.sock.on("error", () => {});
        return m;
      } catch (e) {
        if (i > 100) throw e;
        await sleep(100);
      }
    }
  }
  async cmd(c: string) { this.sock.write(c + "\n"); await sleep(300); }
  /** Type text on the VM's USB keyboard (letters, digits and a few symbols). */
  async type(text: string) {
    const keys: Record<string, string> = { " ": "spc", "\n": "ret", ".": "dot", "-": "minus", "/": "slash", "_": "shift-minus" };
    for (const ch of text) await this.cmd(`sendkey ${keys[ch] ?? ch}`);
  }
}

interface Vm { proc: ChildProcess; con: Console; tag: string; sockDir: string; root?: Console; mon?: Monitor }

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
  const sockDir = await fsp.mkdtemp("/tmp/pi4s"); // unix socket paths max out at ~107 bytes
  const sock = path.join(sockDir, "ttyAMA0"), hvc = path.join(sockDir, "hvc0");
  const hvcArgs = rootShell ? ["-device", "virtio-serial-pci", "-chardev", `socket,id=hvc0,path=${hvc},server=on,wait=off`,
                               "-device", "virtconsole,chardev=hvc0"] : [];
  const mon = path.join(sockDir, "monitor");
  const proc = spawn("qemu-system-aarch64",
    [...args, ...hvcArgs, "-display", "none", "-monitor", `unix:${mon},server=on,wait=off`,
     "-serial", `unix:${sock},server=on,wait=on`, ...after],
    { stdio: ["ignore", "ignore", (await fsp.open(path.join(wd, `${tag}.qemu.stderr`), "w")).fd] });
  children.add(proc);
  const con = await Console.connect(sock, path.join(wd, `${tag}.serial.log`));
  const root = rootShell ? await Console.connect(hvc, path.join(wd, `${tag}.rootshell.log`)) : undefined;
  return { proc, con, tag, sockDir, root, mon: await Monitor.connect(mon) };
}

/** Make the debug shell scriptable; resolves false if it never shows up. */
async function rootShellReady(vm: Vm): Promise<boolean> {
  const r = vm.root!;
  for (let i = 0; i < 120; i++) { // the shell only prints its prompt after input
    await r.send("\n");
    if (await r.expect(/#\s*$/, 5)) break;
  }
  await r.send("export PATH=/run/current-system/sw/bin:$PATH SYSTEMD_COLORS=0 SYSTEMD_PAGER= PAGER=cat TERM=dumb; " +
               "stty -echo cols 400 2>/dev/null; set +o emacs +o vi; PS1='ROOT# '\n");
  const ok = !!(await r.expect("ROOT# ", 60));
  report(ok, `[${vm.tag}] root debug shell on hvc0 (VM-only diagnostics channel)`);
  return ok;
}

function stopVm(vm?: Vm) {
  if (!vm) return;
  vm.con.sock.destroy();
  vm.proc.kill("SIGKILL");
  void fsp.rm(vm.sockDir, { recursive: true, force: true }); // best effort
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

async function sshTarget(dest: string): Promise<Target> {
  const port = /:(\d+)$/.exec(dest)?.[1]; // [user@]host[:port]
  const bare = port ? dest.slice(0, -port.length - 1) : dest;
  const host = bare.includes("@") ? bare : `izelnakri@${bare}`;
  const ctl = path.join(await fsp.mkdtemp("/tmp/pi4ssh"), "c");
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
  if (t.real) {
    await check("system finished booting", "systemctl is-system-running --wait",
                (_, o) => ["running", "degraded"].includes(o.trim()), 900);
  } else { // VM: first boot under emulation is slow; wait only for what the checks need
    const st = await waitActive(t, ["sshd", "NetworkManager"], 900);
    report(st === "active active", `[${t.tag}] sshd + NetworkManager active`, `${st} t+${secs(tStart)}`);
  }
  await check("image files root-owned (/, /var, NetworkManager Wi-Fi plugin)",
              "stat -c %U / /var /nix/store/*-networkmanager-*/lib/NetworkManager/*/libnm-device-plugin-wifi.so | sort -u",
              (_, o) => o.trim() === "root");
  const kver = /linux-\S*?-(\d+\.\d+\.\d+)/.exec(ext?.linux ?? "")?.[1];
  await check(ext ? "running the kernel from extlinux.conf" : "kernel", "uname -r",
              (c, o) => c === 0 && (!kver || o.trim() === kver));
  await check("cmdline is a NixOS extlinux boot", "cat /proc/cmdline",
              (_, o) => o.includes("root=fstab") && (ext ? o.includes(ext.append.split(" ")[0]) : /init=\/nix\/store\//.test(o)));
  await check("DT is the Pi 4 Model B", "tr -d '\\0' </proc/device-tree/model 2>/dev/null || echo none",
              (_, o) => t.tag === "system" || o.includes("Raspberry Pi 4 Model B")); // virt has its own DT
  // pi4.rootFs: ext4 (default) or btrfs (modules/raspberry-pi/rootfs.nix)
  await check("/ is ext4 or btrfs on partition 2", "findmnt -no SOURCE,FSTYPE /",
              (_, o) => new RegExp(`${p(2)}(\\[/\\])?\\s+(ext4|btrfs)`).test(o));
  await check("/boot is the FAT firmware partition", "findmnt -no SOURCE,FSTYPE /boot", (_, o) => new RegExp(`${p(1)}\\s+vfat`).test(o));
  // /boot is mounted umask=0077 (root only), so a real user needs sudo to look.
  await check("bootloader files visible under /boot",
              `${t.real ? sudo() + " " : ""}ls /boot/extlinux/extlinux.conf /boot/u-boot.bin /boot/config.txt`,
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
  if (t.real) await check("izelnakri can manage NetworkManager without sudo (networkmanager group)",
                         "nmcli general permissions | grep -E 'network-control' | grep -c yes", (_, o) => o.trim() === "1");
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
    // Pi 4: card0 = v3d (render only), card1 = vc4-drm with the HDMI connectors.
    await check("vc4 HDMI driver bound to a DRM card", "for c in /sys/class/drm/card[0-9]; do readlink -f $c/device/driver; done | grep -c vc4",
                (_, o) => Number(o.trim()) > 0);
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

/** Poll until all units are active (or timeout); returns the last `is-active` line. */
async function waitActive(t: Target, units: string[], timeoutS: number): Promise<string> {
  const end = Date.now() + timeoutS * 1000;
  let st = "";
  while (Date.now() < end) {
    st = (await t.sh(`systemctl is-active ${units.join(" ")} | paste -sd' '`, 60))[1].trim();
    if (st.split(" ").every((x) => x === "active")) break;
    await sleep(5000);
  }
  return st;
}

// ---- VM-only check groups. They run concurrently (each waits only for its own services);
// root-shell commands are queued by Console.sh, so their waits overlap.

/** Wi-Fi: NetworkManager's wpa_supplicant backend + virtual mac80211_hwsim radios. */
async function vmWifiChecks(t: Target) {
  const tag = `[${t.tag}]`;
  await waitActive(t, ["NetworkManager"], 900);
  const [, act] = await t.sh("busctl --system list --activatable --no-pager 2>/dev/null | grep -c fi.w1.wpa_supplicant1");
  report(Number(act) > 0, `${tag} wpa_supplicant D-Bus service activatable (NetworkManager's Wi-Fi backend)`, act);
  await t.sh("modprobe mac80211_hwsim radios=2", 60);
  const usable = /:wifi:(disconnected|connected|connecting)/;
  let wifi = "";
  for (let i = 0; i < 24 && !usable.test(wifi); i++) { // bounded: ~2 min
    wifi = (await t.sh("nmcli -t -f DEVICE,TYPE,STATE dev | grep ':wifi:' | paste -sd' '", 30))[1];
    if (i === 6 && !usable.test(wifi)) { // NM may skip hwsim radios by policy: force management
      await t.sh(`for d in $(nmcli -t -f DEVICE,TYPE dev | awk -F: '$2=="wifi"{print $1}'); do nmcli dev set $d managed yes; done`, 30);
    }
    if (!usable.test(wifi)) await sleep(5000);
  }
  // Hard: NetworkManager sees the Wi-Fi devices. Soft: NM's "managed" state for *virtual*
  // hwsim radios is flaky; real Wi-Fi (connected) is asserted by the --ssh tier on the Pi.
  report(/:wifi:/.test(wifi), `${tag} NetworkManager sees Wi-Fi devices (virtual hwsim radios)`, wifi || "none");
  report(usable.test(wifi) ? true : null, `${tag} NetworkManager manages the virtual radios`, wifi);
  const [c] = await t.sh("nmcli dev wifi rescan 2>/dev/null; sleep 3; nmcli -t dev wifi list >/dev/null", 90);
  report(c === 0, `${tag} Wi-Fi scan runs`);
}

/** Bluetooth daemon. (A real controller only exists on hardware: see --ssh.) */
async function vmBluetoothChecks(t: Target) {
  // bluetooth.service needs /sys/class/bluetooth (ConditionPathIsDirectory); the VM has no
  // adapter, so create a virtual one (held open in the background) and start the daemon.
  await waitActive(t, ["NetworkManager"], 900);
  await t.sh("modprobe hci_vhci; (exec 3<>/dev/vhci; sleep 600) >/dev/null 2>&1 & sleep 3; systemctl restart bluetooth", 90);
  const st = await waitActive(t, ["bluetooth"], 120);
  const [, ctl] = await t.sh("timeout 10 bluetoothctl list", 30);
  report(st === "active", `[${t.tag}] bluetoothd running`, `${st}; ${ctl.split("\n")[0] || "no virtual controller"}`);
  const [, ap] = await t.sh("systemctl is-active bt-autopair", 30);
  report(ap.trim() === "active", `[${t.tag}] bt-autopair service running (pairs/reconnects the keyboard)`, ap.trim());
}

/** The boot-diagnostics unit must succeed and write its report to the FAT partition. */
async function vmDiagnosticsChecks(t: Target) {
  await waitActive(t, ["NetworkManager"], 900);
  await t.sh("systemctl start --no-block pi4-diagnostics", 30);
  let o = "";
  for (let i = 0; i < 24 && !o.includes("written"); i++) { // bounded: ~4 min
    await sleep(10000);
    o = (await t.sh("systemctl is-active pi4-diagnostics; test -s /boot/pi4-diagnostics.txt && echo written", 30))[1];
  }
  const [, state] = await t.sh("systemctl is-failed pi4-diagnostics", 30);
  report(o.includes("written") && state.trim() !== "failed", `[${t.tag}] pi4-diagnostics writes /boot/pi4-diagnostics.txt`,
         `${o.replace(/\n/g, " ")} unit=${state.trim()}`);
}

/** DisplayLink: evdi module + its virtual DRM card, and DisplayLinkManager running. */
async function vmDisplayLinkChecks(t: Target) {
  const tag = `[${t.tag}]`;
  await waitActive(t, ["NetworkManager"], 900);
  const [, ev] = await t.sh("lsmod | grep -c '^evdi'; for c in /sys/class/drm/card[0-9]; do " +
                            "[ \"$(basename $(readlink -f $c/device/driver) 2>/dev/null)\" = evdi ] && ls -d $c/card*-*; done | xargs -rn1 basename | paste -sd' '", 60);
  const [loaded, conns = ""] = ev.split("\n");
  report(Number(loaded) > 0 && conns.length > 0, `${tag} DisplayLink: evdi loaded with a DRM card + connector`, `evdi=${loaded} ${conns}`);
  report((await waitActive(t, ["dlm"], 300)) === "active", `${tag} DisplayLink: DisplayLinkManager (dlm.service) running`);
}

/** Desktop: log in on tty1 with the virtual keyboard; the zsh login autostarts Hyprland. */
async function vmDesktopChecks(vm: Vm, t: Target, wd: string) {
  const tag = `[${vm.tag}]`;
  report((await waitActive(t, ["getty@tty1"], 900)) === "active", `${tag} getty on tty1`);
  // agetty flushes input when it (re)opens the tty, so keys typed too early are lost: wait for
  // the rest of the boot (sshd/NM), then type; retry the login if Hyprland doesn't appear.
  await waitActive(t, ["sshd", "NetworkManager"], 900);
  const [, cfg] = await t.sh("runuser -u izelnakri -- Hyprland --verify-config --config /etc/hypr/hyprland.lua 2>&1 | tail -1", 120);
  report(cfg.includes("config ok"), `${tag} Hyprland accepts /etc/hypr/hyprland.lua (--verify-config)`, cfg.trim());
  // Log in on tty1 once (retry only if no tty1 session exists yet: agetty may flush early keys).
  const log = "/home/izelnakri/.hyprland.log";
  let started = "";
  for (let attempt = 1; attempt <= 3 && !started; attempt++) {
    const [, sess] = await t.sh("loginctl list-sessions --no-legend | grep -c tty1", 30);
    if (sess.trim() === "0") {
      await sleep(10000);
      await vm.mon!.type("izelnakri\n");
      await sleep(6000);
      await vm.mon!.type(`${PASSWORD}\n`);
    }
    for (let i = 0; i < 9 && !started; i++) {
      await sleep(10000);
      started = (await t.sh(`grep -m1 -o 'Creating the ConfigManager' ${log} 2>/dev/null`, 30))[1].trim();
    }
  }
  const shot = path.join(wd, "hyprland.ppm");
  await vm.mon!.cmd(`screendump ${shot}`);
  const [, card] = await t.sh(`grep -o 'AQ_DRM_DEVICES[^ ]*\\|Starting Hyprland on [^ ]*' ${log} 2>/dev/null | head -1; ` +
                              `grep -c 'CBackend::create() failed' ${log} 2>/dev/null`, 30);
  report(!!started, `${tag} tty1 login autostarts Hyprland with the system config`, `screenshot: ${shot}`);
  // virtio-gpu has no 3D: Hyprland's renderer can't start in this VM. Real rendering = the Pi.
  report(card.trim().endsWith("0") ? true : null, `${tag} Hyprland renderer (virtio-gpu has no 3D; verified on the Pi)`,
         card.replace(/\n/g, " "));
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
    else if (x === "--keep-going") FAIL_FAST = false;
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

/** Copy bytes [offset, offset+length) of src to dst (streams; no full read into memory). */
async function copyRange(src: string, dst: string, offset: number, length: number) {
  await pipeline(fs.createReadStream(src, { start: offset, end: offset + length - 1 }), fs.createWriteStream(dst));
}


const TOOLS = ["qemu-system-aarch64", "qemu-img", "qemu-io", "sfdisk", "mtype", "mdir", "mcopy", "fdtget", "fdtput"];

async function main() {
  const a = parseArgs(process.argv.slice(2));
  if (a.ssh) { // real hardware: no image, no VMs
    step(`System checks on the real Pi: ${a.ssh}`);
    const t = await sshTarget(a.ssh);
    try {
      await systemChecks(t, { disk: "mmcblk0", sshPort: null, extra: a.run });
      if (a.reboot) await sshRebootChecks(t);
    } catch (e) { if (!(e instanceof FailFast)) console.log(`  error: ${e}`); }
    const bad = failed();
    step(`Summary: ${rows.length - bad.length}/${rows.length} passed in ${secs(tStart)}`);
    for (const [, n, d] of bad) console.log(`  FAIL ${n}  ${d}`);
    process.exit(bad.length ? 1 : 0);
  }
  const found = await Promise.all(TOOLS.map((t) => ok0("sh", "-c", `command -v ${t}`)));
  const missing = TOOLS.filter((_, i) => !found[i]);
  if (missing.length) {
    console.error(`missing on PATH: ${missing.join(" ")}\nuse \`nix run .#run-pi4\` (pinned tools) or ` +
                  "`nix shell nixpkgs#{qemu,dtc,mtools,util-linux}`");
    process.exit(2);
  }
  let img = a.image;
  if (!img) {
    const dir = "result-pi4-nas/sd-image";
    const f = (await fsp.readdir(dir).catch(() => [] as string[])).filter((x) => x.endsWith(".img")).sort()[0];
    img = f ? path.join(dir, f) : "";
  }
  if (!img || !(await exists(img))) { console.error("no image; run `make pi4-image` or pass the .img path"); process.exit(2); }
  img = await fsp.realpath(img);
  const wd = a.workdir || await fsp.mkdtemp(path.join(os.tmpdir(), "pi4-vm-"));
  await fsp.mkdir(wd, { recursive: true });
  console.log(`image:   ${img}\nworkdir: ${wd}`);

  const [p1, p2] = await partitions(img);
  const fat = path.join(wd, "firmware.img");
  await copyRange(img, fat, p1.start * 512, p1.size * 512);
  const { ext, dtb } = await staticChecks(img, fat);
  const top = /init=(\S+)\/init/.exec(ext.append)?.[1];
  // Feature checks follow what the image actually contains (pi4.displaylink.enable etc.).
  const hasDisplayLink = !!top && await exists(path.join(top, "etc/systemd/system/dlm.service"));
  if (top && await exists(top)) { // the image's system closure is in the local store after a build
    await btAutopairUnitTest(top);
    const dlm = path.join(top, "sw/bin/.DisplayLinkManager-wrapped");
    const bin = (await exists(dlm)) ? dlm : path.join(top, "sw/bin/DisplayLinkManager");
    const elf = (await exists(bin)) ? (await fsp.readFile(await fsp.realpath(bin))).subarray(0, 20) : null;
    if (hasDisplayLink) {
      report(elf ? elf.readUInt16LE(18) === 183 : false, "DisplayLinkManager is an aarch64 binary in the image",
             elf ? `e_machine=${elf.readUInt16LE(18)}` : "missing");
    }
  }
  /** Extract a FAT file into the workdir; returns its path. */
  const extract = async (name: string, fatPath: string) => {
    const f = path.join(wd, name);
    await fsp.writeFile(f, await fatRead(fat, fatPath));
    return f;
  };
  const [uboot, fwDtb, kernel, initrd] = await Promise.all([
    extract("u-boot.bin", "/u-boot.bin"), extract("fw.dtb", "/bcm2711-rpi-4-b.dtb"),
    ext.linux ? extract("Image", ext.linux) : undefined, ext.initrd ? extract("initrd", ext.initrd) : undefined,
  ]);

  const finish = async () => {
    const bad = failed();
    step(`Summary: ${rows.length - bad.length}/${rows.length} passed in ${secs(tStart)}`);
    for (const [, n, d] of bad) console.log(`  FAIL ${n}  ${d}`);
    if (bad.length || a.keep) console.log(`  kept ${wd} (*.serial.log, *.qemu.stderr, overlays)`);
    else await fsp.rm(wd, { recursive: true, force: true });
    process.exit(bad.length ? 1 : 0);
  };
  if (a.staticOnly || failed().length) { await fsp.unlink(fat); await finish(); }

  // overlays: the store image is the read-only backing file
  const overlay = async (name: string, size?: number) => {
    const f = path.join(wd, name);
    await run("qemu-img", "create", "-q", "-f", "qcow2", "-F", "raw", "-b", img, f, ...(size ? [String(size)] : []));
    return f;
  };
  const [piDisk, virtDisk] = await Promise.all([
    overlay("raspi4b.qcow2", 2 ** Math.ceil(Math.log2((await fsp.stat(img)).size + 1))), // SD: power of 2
    overlay("virt.qcow2", 16 * 2 ** 30), // room for the first-boot root expansion
  ]);
  if (a.full && dtb) { // VM-only DTB, written only into the raspi4b overlay
    const vmDtb = path.join(wd, "vm.dtb");
    await fsp.writeFile(vmDtb, await fatRead(fat, dtb), { mode: 0o644 });
    await makeVmDtb(vmDtb);
    await run("mcopy", "-o", "-i", fat, vmDtb, "::" + dtb);
    await run("qemu-io", "-f", "qcow2", "-c", `write -s ${fat} ${p1.start * 512} ${p1.size * 512}`, piDisk);
  }
  await fsp.unlink(fat);

  const piArgs = ["-M", "raspi4b", "-kernel", uboot, "-dtb", fwDtb, "-drive", `file=${piDisk},if=sd,format=qcow2`];
  const piSerial1 = ["-serial", "null"]; // mini-UART (ttyS1), after serial0
  const sshPort = await freePort();
  const virtArgs = ["-M", "virt", "-cpu", "cortex-a72", "-smp", "4", "-m", "8G",
    "-accel", "tcg,thread=multi,tb-size=1024", "-kernel", kernel!, "-initrd", initrd!,
    "-append", `${ext.append} console=ttyAMA0 ${VM_DEVICE_TIMEOUT}${a.interactive ? "" : " systemd.debug_shell=hvc0"}`,
    "-drive", `file=${virtDisk},if=virtio,format=qcow2,cache=unsafe`,
    "-nic", `user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:${sshPort}-:22`,
    // display + input for the Hyprland check (tty1 login via the USB keyboard, then screendump)
    "-device", "virtio-gpu-pci", "-device", "qemu-xhci", "-device", "usb-kbd", "-device", "usb-tablet"];

  if (a.interactive) {
    const args = a.full ? piArgs : virtArgs;
    step(`Interactive ${a.full ? "raspi4b" : "virt"} VM. Login izelnakri/testing, quit with Ctrl-A X` +
         (a.full ? "" : `, ssh -p ${sshPort} izelnakri@127.0.0.1`));
    const q = spawn("qemu-system-aarch64", [...args, "-display", "none", "-serial", "mon:stdio",
                    ...(a.full ? piSerial1 : [])], { stdio: "inherit" });
    const code = await new Promise<number>((res) => q.on("close", (c) => res(c ?? 1)));
    console.log(`workdir kept: ${wd}`);
    process.exit(code);
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
      // Every command carries its own env: the debug shell can respawn (fresh env) mid-run.
      const env = "PATH=/run/current-system/sw/bin:$PATH SYSTEMD_COLORS=0 SYSTEMD_PAGER= PAGER=cat TERM=dumb";
      const rootT: Target = { tag: "system", real: false, sh: (c, tm) => vm.root!.sh(`${env}; ${c}`, tm) };
      // System checks as root over hvc0, while the serial console independently proves the
      // real user login (getty + PAM + password + sudo) once getty is up.
      await Promise.all([
        systemChecks(rootT, { ext, disk: "vda", sshPort, extra: a.run }),
        vmWifiChecks(rootT),
        vmBluetoothChecks(rootT),
        vmDiagnosticsChecks(rootT),
        hasDisplayLink ? vmDisplayLinkChecks(rootT) : Promise.resolve(report(null, "[system] DisplayLink", "not enabled in this image")),
        vmDesktopChecks(vm, rootT, wd),
        (async () => { if (await milestones(vm, t0.t, getty)) await login(vm); })(),
      ]);
      if (a.reboot) await rebootChecks(vm, t0, ms);
    }
    stopVm(vm);
  };
  try {
    await Promise.all([a.tier !== "system" && ubootTier(), a.tier !== "uboot" && systemTier()]);
  } catch (e) {
    if (!(e instanceof FailFast)) throw e;
    console.log(`\n  fail-fast: stopping after "${e.message}" (use --keep-going for a full report)`);
  } finally {
    vms.forEach(stopVm);
  }
  await finish();
}

try {
  await main();
} catch (e) {
  if (!(e instanceof FailFast)) throw e;
  // FAIL outside the VM tiers (e.g. static checks): VMs are killed by the exit hook.
  console.log(`\n==> fail-fast: stopped after "${e.message}" (${secs(tStart)}); --keep-going for a full report`);
  process.exit(1);
}
