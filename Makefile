# every session has to run export $(tmux show-env) -> make a command to automate these 3 steps

HOSTNAME = $(shell hostname)
USERNAME = $(shell whoami)
# FOO ?= "bar" # this represents ||= in ruby

NIX_FILES = $(shell find . -name '*.nix' -type f)

ifndef HOSTNAME
 $(error Hostname unknown)
endif

# The config now evaluates PURELY (no --impure). Impure bits removed: nixGL.auto's
# builtins.currentTime (modules/functions/wrap-nix-gl.nix) and xremap's absolute-path
# readFile (users/izelnakri). Two payoffs:
#   1. nixGL.auto's currentTime changed the nixGL wrapper derivations on EVERY invocation,
#      so all ~13 wrapNixGL'd packages rebuilt on every `switch`. Gone now -> real per-switch
#      time saved on the build side.
#   2. Pure eval = reproducible, and a prerequisite for remote/distributed builds & CI.
# Note: pure eval does NOT shortcut the ~28s toplevel evaluation itself — Nix's flake eval
# cache doesn't cache the NixOS module fixpoint (measured). That 28s is inherent to the size
# of this config (~30M values). Re-add --impure below if you reintroduce impurity.

# sudo make -C ~/.config/home-manager switch:
switch:
	nixos-rebuild switch --flake .#${HOSTNAME} -L
	# nixos-rebuild switch --flake .#${HOSTNAME} -L --impure

module-dev:
	nixos-rebuild switch --override-input nixpkgs ~/Github/nixpkgs --flake .#${HOSTNAME} -L
	# nixos-rebuild switch --override-input nixpkgs ~/Github/nixpkgs --flake .#${HOSTNAME} -L --impure


boot:
	nixos-rebuild boot --use-remote-sudo --flake .#${HOSTNAME} -L
	# nixos-rebuild boot --use-remote-sudo --flake .#${HOSTNAME} -L --impure

test:
	nixos-rebuild test --use-remote-sudo --flake .#${HOSTNAME} -L
	# nixos-rebuild test --use-remote-sudo --flake .#${HOSTNAME} -L --impure

update:
	nix flake update

upgrade:
	make update && make home-switch

# Was --impure for nixGL.auto's builtins.currentTime; now pure (nixGL neutralized on NixOS).
home-switch:
	home-manager switch --flake .
	# home-manager --impure switch --flake .

new-rage-identity:
	@echo "Generating new SSH key for Nix secrets..."
	ssh-keygen -t ed25519 -f ~/.ssh/nix-secrets -C "Nix secrets" -N ""

# Only check-in the secrets.nix.age on git where I have the public key of ~/.ssh/nix-secrets
encrypt:
	@echo "Encrypting secrets.nix..."
	rage -e -i ~/.ssh/nix-secrets secrets.nix -o secrets.nix.age

# Only check-in the secrets.nix.age on git where I have the public key of ~/.ssh/nix-secrets
decrypt:
	@echo "Decrypting secrets.nix.age..."
	rage -d -i ~/.ssh/nix-secrets secrets.nix.age -o output.nix

# First we need to add "secrets/sample-secret".publicKeys = [ nixSecretsSSHPublicKey ] then run this:
create-sample-secret:
	rm secrets/sample-secret.age
	ragenix --identity ~/.ssh/nix-secrets -e secrets/sample-secret.age # saved cyphertext to secrets/sample-secret.age
	make encrypt
	# Then add it to: age.secrets.example-secret.file = ../secrets/secret1.age; then reference is config.age.secrets.example-secret.path

decrypt-sample-secret-file: decrypt
	rage -d -i ~/.ssh/nix-secrets secrets/sample-secret.age -o


# TODO: Read more in depth
# disko:
# 	nix run github:nix-community/disko -- --mode disko /tmp/disk-config.nix # NOTE: mode is mount/format/disko(both)

# TODO: read more nixos-anywhere then, build a simple nginx server with it as an example on scaleway

# foo:
# 	echo ${BAR}

# deploy
#   make update && nix run .nix run .#apps.nixinate.$1

# --- Raspberry Pi 4 (pi4-nas) ------------------------------------------------
# make pi4-image                  -> ./result-pi4-nas/sd-image/*.img (cross-built, uncompressed)
# sudo make pi4-flash DEV=/dev/sdX -> write the built image to a *removable, unmounted* disk
#                                    (no build here: don't run nix build as root)
# make pi4-inspect                -> print partition table, extlinux.conf, config.txt of the image
# make pi4-deploy                 -> nixinate: push the config to the running Pi over SSH
# make run-pi4 [ARGS=...]         -> test the image: static checks + 2 parallel QEMU VMs (raspi4b runs the real
#                                    U-Boot -> extlinux -> kernel; virt A72x4/8G boots it to login + system checks)
# make run-pi4 ARGS="--ssh pi4-nas.local" -> the same system checks + HDMI/Wi-Fi/RAM on the real Pi (seconds)
#   more ARGS: --tier uboot|system  --reboot  --full  --keep  --run 'CMD'  --password PW   (scripts/run-pi4.ts)
# make pi4-check                  -> static image checks only (partition flag, bootcmd, extlinux, DTB): seconds
# make pi4-vm [ARGS=--full]       -> interactive serial console (virt, or raspi4b with --full); Ctrl-A X quits
#   (also: `deno run -A scripts/run-pi4.ts ...` with the tools on PATH)
# ROOTFS=btrfs selects the btrfs-root image (images.pi4-nas-btrfs); default ext4. If you flash
# btrfs, also set `pi4.rootFs = "btrfs";` in hosts/izels-pi4 before `make pi4-deploy`.
ROOTFS ?= ext4
PI4_RESULT = $(if $(filter btrfs,$(ROOTFS)),result-pi4-nas-btrfs,result-pi4-nas)
PI4_IMG = $(wildcard $(PI4_RESULT)/sd-image/*.img)

pi4-image:
	nix build .#images.pi4-nas -o result-pi4-nas -L

pi4-image-btrfs:
	nix build .#images.pi4-nas-btrfs -o result-pi4-nas-btrfs -L

pi4-flash:
	@test -n "$(PI4_IMG)" || { echo "no $(ROOTFS) image, run: make pi4-image$(if $(filter btrfs,$(ROOTFS)),-btrfs,)"; exit 1; }
	@echo "flashing $(ROOTFS) image: $(PI4_IMG)"
	@test -n "$(DEV)" || { echo "usage: sudo make pi4-flash DEV=/dev/sdX"; exit 1; }
	@test "$$(lsblk -dno RM $(DEV))" = 1 || { echo "$(DEV) is not removable, refusing"; exit 1; }
	@! lsblk -no MOUNTPOINTS $(DEV) | grep -q . || { echo "$(DEV) has mounted partitions, refusing"; exit 1; }
	lsblk -o NAME,SIZE,MODEL,TRAN $(DEV)
	dd if=$(PI4_IMG) of=$(DEV) bs=4M conv=fsync oflag=direct status=progress
	sync
	partprobe $(DEV) || true
	lsblk -o NAME,SIZE,LABEL,FSTYPE $(DEV)

pi4-inspect:
	sfdisk -d $(PI4_IMG)
	dd if=$(PI4_IMG) bs=512 skip=16384 count=1048576 status=none > /tmp/pi4-fw.img
	MTOOLS_SKIP_CHECK=1 mtype -i /tmp/pi4-fw.img ::/extlinux/extlinux.conf | grep -v '^#'
	MTOOLS_SKIP_CHECK=1 mtype -i /tmp/pi4-fw.img ::/config.txt
	rm -f /tmp/pi4-fw.img

pi4-deploy:
	nix run .#apps.nixinate.pi4-nas

pi4-check: pi4-image
	nix run .#run-pi4 -- --static-only

# --ssh needs no image, so skip the build then.
run-pi4:
	$(if $(findstring --ssh,$(ARGS)),,nix build .#images.pi4-nas -o result-pi4-nas -L)
	nix run .#run-pi4 -- $(ARGS)

pi4-vm: pi4-image
	nix run .#run-pi4 -- --interactive $(ARGS)

.PHONY: pi4-image pi4-image-btrfs pi4-flash pi4-inspect pi4-deploy pi4-check run-pi4 pi4-vm
