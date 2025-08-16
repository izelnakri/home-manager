# every session has to run export $(tmux show-env) -> make a command to automate these 3 steps

HOSTNAME = $(shell hostname)
USERNAME = $(shell whoami)
# FOO ?= "bar" # this represents ||= in ruby

NIX_FILES = $(shell find . -name '*.nix' -type f)

ifndef HOSTNAME
 $(error Hostname unknown)
endif

# sudo make -C ~/.config/home-manager switch:
switch:
	nixos-rebuild switch --flake .#${HOSTNAME} -L --impure

module-dev:
	nixos-rebuild switch --override-input nixpkgs ~/Github/nixpkgs --flake .#${HOSTNAME} -L --impure


boot:
	nixos-rebuild boot --use-remote-sudo --flake .#${HOSTNAME} -L --impure

test:
	nixos-rebuild test --use-remote-sudo --flake .#${HOSTNAME} -L --impure

update:
	nix flake update

upgrade:
	make update && make home-switch

# nixGL.auto requires --impure due to builtins.currentTime
home-switch:
	home-manager --impure switch --flake .

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
