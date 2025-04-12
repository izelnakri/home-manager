if [[ "$(tty)" = "/dev/tty1" ]]; then
  timedatectl set-ntp true
fi
