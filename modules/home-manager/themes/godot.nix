{ pkgs, lib }: {
  base16Scheme = {
    system = "base16";
    variant = "dark";
    name = "Godot Theme";
    palette = {
      foreground = "#CDCFD2";
      background = "#1D2229";
      selection_foreground = "#CDCFD2";
      selection_background = "#403D3D";

      base00 = "#000000"; # : black
      base08 = "#1D2229";
      base01 = "#FF7085"; # : red
      base09 = "#FF0000";
      base02 = "#A1FFE0"; # : green
      base0A = "#A6E22E";
      base03 = "#FFEDA1"; # : yellow
      base0B = "#FFB373";
      base04 = "#66D9EF"; # : blue
      base0C = "#57B3FF";
      base05 = "#FF8CCC"; # : magenta
      base0D = "#F92672";
      base06 = "#BCE0FF"; # : cyan
      base0E = "#70F0F0";
      base07 = "#F8F8F0"; # : white
      base0F = "#FFFFFF";
    };
  };
}
