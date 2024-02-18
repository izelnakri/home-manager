#!/bin/bash

source ~/.config/ironbar/scripts/variables.sh

# Function to get memory percentage
get_memory_percent() {
    memory_percent=$(free | awk '/Mem:/ {print ($3/$2)*100}')
    printf "%.1f" "$memory_percent"
}

# Function to get memory used in GB
get_memory_used() {
    memory_used=$(free -h | awk '/Mem:/ {print $3}' | cut -d 'G' -f 1)
    printf "%.2f" "$memory_used"
}

# Function to get total memory in GB
get_memory_total() {
    memory_total=$(free -h | awk '/Mem:/ {print $2}' | cut -d 'G' -f 1)
    printf "%.2f" "$memory_total"
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
    memory_percent=$(get_memory_percent)
    memory_used=$(get_memory_used)
    memory_total=$(get_memory_total)
    load_color=$(get_load_color $memory_percent)

    echo "<span color='$load_color'>📟 $memory_percent% [$memory_used GB / $memory_total GB]</span>"
}

# Call the main function
main
