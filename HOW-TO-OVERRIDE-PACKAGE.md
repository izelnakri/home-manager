# How to override a package in nixpkgs?

There are two ways:

## 1. Directly on the config:

```
nixpkgs.config.packageOverrides = prev: {
  ffmpeg_6 = prev.ffmpeg_6.overrideAttrs (old: rec {
    withVpl = true;
    configureFlags =
      # Remove deprecated Intel Media SDK support
      (builtins.filter (e: e != "--enable-libmfx") old.configureFlags)
      # Add Intel VPL support
      ++ [ "--enable-libvpl" ];
    buildInputs = old.buildInputs ++ [
      # VPL dispatcher
      pkgs-unstable.libvpl
    ];
  });
};
```

## 2. Overlay on the pgks:

```

{ config, pkgs, ... }:
let
  jellyfin-ffmpeg-overlay = (final: prev: {
    jellyfin-ffmpeg = prev.jellyfin-ffmpeg.override {
      ffmpeg_6-full = prev.ffmpeg_6-full.override {
        withMfx = false;
        withVpl = true;
      };
    };
  });
  unstable = (import <unstable> {
    config.allowUnfree = true;
    overlays = [ jellyfin-ffmpeg-overlay ];
  });
in
{
  services.jellyfin = {
    enable = true;
    package = unstable.jellyfin;
  };
```


