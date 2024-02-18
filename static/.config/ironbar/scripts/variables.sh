#!/bin/bash

export green_background_color="#0d372d";
export green_color="#7DAF9C";
export blue_color="#6C99BB";
export red_color="#EF5D32";
export orange_color="#EFAC32";
export yellow_color="#D9D762";

export get_load_color() {
  if [ $1 -gt 90 ]; then
      echo $red_color
  elif [ $1 -gt 75 ]; then
      echo $orange_color
  else
      echo $green_color
  fi
}
