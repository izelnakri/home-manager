{ pkgs, config, ... }:
{
  home.file."./config/system-colors.xml".text = ''
    <color1>${config.colorScheme.colors.base00}</color1>
    <color2>${config.colorScheme.colors.base05}</color2>
  '';
}
