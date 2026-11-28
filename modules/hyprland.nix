{ config, ... }:

{
  xdg.configFile."hypr" = {
    source = ../static/.config/hypr;
    recursive = true;
  };
}

