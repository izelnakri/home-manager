#!/bin/bash

source ~/.config/ironbar/scripts/variables.sh

# Function to get CPU percentage
get_cpu_percent() {
    cpu_percent=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    printf "$cpu_percent"
}

# Function to get load average in GHz
get_load_average() {
    load_average=$(uptime | awk -F'[a-z]:' '{ print $2 }' | awk -F, '{print $1}' | awk '{$1=$1};1')
    printf "%.2f" "$load_average"
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
    cpu_percent=$(get_cpu_percent)
    load_average=$(get_load_average)
    load_color=$(get_load_color $cpu_percent)

    echo "<span color='$load_color'>💻 $cpu_percent% [$load_average GHz]</span>"
}

# Call the main function
main
