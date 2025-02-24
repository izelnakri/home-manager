# every session has to run export $(tmux show-env) -> make a command to automate these 3 steps

HOSTNAME = $(shell hostname)
USERNAME = $(shell whoami)
# FOO ?= "bar" # this represents ||= in ruby

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

# TODO: Read more in depth
# disko:
# 	nix run github:nix-community/disko -- --mode disko /tmp/disk-config.nix # NOTE: mode is mount/format/disko(both)

# TODO: read more nixos-anywhere then, build a simple nginx server with it as an example on scaleway

# foo:
# 	echo ${BAR}

# deploy
#   make update && nix run .nix run .#apps.nixinate.$1
