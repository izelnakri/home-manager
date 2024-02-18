#!/bin/bash

source ~/.config/ironbar/scripts/variables.sh

# Function to get disk usage percentage
get_disk_percent() {
    df -h --output=pcent "$1" | sed '1d;s/%//'
}

# Function to get disk usage in GB with decimal
get_disk_used() {
    df -B 1G --output=used "$1" | awk 'NR==2 {printf "%.2f", $1}'
}

get_load_color() {
  if [ $1 -gt 90 ]; then
      echo $red_color
  elif [ $1 -gt 75 ]; then
      echo $orange_color
  else
      echo $green_color
  fi
}

# Main function
main() {
    # Path to the disk you want to monitor, e.g., "/"
    disk_path="/"
    disk_percent=$(get_disk_percent "$disk_path")
    disk_used=$(get_disk_used "$disk_path")
    load_color=$(get_load_color $disk_percent)

    echo "<span color='$load_color'>🗄️$disk_percent% [$disk_used GB]</span>"
}

# Call the main function
main
