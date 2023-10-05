HOSTNAME = $(shell hostname)
USERNAME = $(shell whoami)

NIX_FILES = $(shell find . -name '*.nix' -type f)

ifndef HOSTNAME
 $(error Hostname unknown)
endif

switch:
	nixos-rebuild switch --use-remote-sudo --flake .#${HOSTNAME} -L

boot:
	nixos-rebuild boot --use-remote-sudo --flake .#${HOSTNAME} -L

test:
	nixos-rebuild test --use-remote-sudo --flake .#${HOSTNAME} -L

update:
	nix flake update

upgrade:
	make update && make home-switch

# nixGL.auto requires --impure due to builtins.currentTime
home-switch:
	home-manager --impure switch --flake .

# deploy
#   make update && nix run .nix run .#apps.nixinate.$1
