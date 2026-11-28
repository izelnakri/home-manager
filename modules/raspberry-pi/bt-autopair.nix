# Declarative Bluetooth auto-pairing: list device addresses, and the Pi pairs, trusts and
# (re)connects them whenever they're in range. Classic keyboards pair "Just Works" with the
# NoInputNoOutput agent (no passkey). Trusted devices then reconnect on every boot.
#
#   pi4.bluetooth.autoPair = [ "E6:7A:00:00:2C:8E" ]; # "Bluetooth 5.1 Keyboard"
#
# A Bluetooth bond is a secret link key negotiated between the device and ONE host, so the very
# first time the device must be in pairing mode (its pairing button / Fn+channel). After that it
# just works. Log: `journalctl -u bt-autopair -f`.
{ config, lib, pkgs, ... }:
let
  cfg = config.pi4.bluetooth;
  btctl = "${pkgs.bluez}/bin/bluetoothctl";
in
{
  options.pi4.bluetooth.autoPair = lib.mkOption {
    type = lib.types.listOf (lib.types.strMatching "([0-9A-F]{2}:){5}[0-9A-F]{2}");
    default = [ ];
    description = "Bluetooth addresses (upper case) to pair, trust and keep connected.";
  };

  config = lib.mkIf (cfg.autoPair != [ ]) {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.settings.Policy.AutoEnable = true;
    boot.kernelModules = [ "uhid" ]; # BlueZ HID devices (keyboards) go through /dev/uhid

    systemd.services.bt-autopair = {
      description = "Pair, trust and connect configured Bluetooth devices";
      after = [ "bluetooth.service" ];
      requires = [ "bluetooth.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.bluez pkgs.gnugrep pkgs.coreutils ];
      serviceConfig = {
        Restart = "always";
        RestartSec = 10;
      };
      script = ''
        set +e
        devices="${lib.concatStringsSep " " cfg.autoPair}"
        while true; do
          for mac in $devices; do
            info=$(${btctl} info "$mac" 2>&1)
            if ! grep -q "Paired: yes" <<<"$info"; then
              # Discover it (must be in pairing mode), then pair without a passkey and trust it.
              ${btctl} --timeout 15 scan on >/dev/null 2>&1
              if ${btctl} --agent NoInputNoOutput --timeout 30 pair "$mac" 2>&1 | grep -q "Pairing successful"; then
                echo "paired $mac"
                ${btctl} trust "$mac"
                ${btctl} --timeout 15 connect "$mac"
              fi
            elif ! grep -q "Trusted: yes" <<<"$info"; then
              ${btctl} trust "$mac"
            elif ! grep -q "Connected: yes" <<<"$info"; then
              ${btctl} --timeout 10 connect "$mac" >/dev/null 2>&1 && echo "connected $mac"
            fi
          done
          sleep 10
        done
      '';
    };
  };
}
