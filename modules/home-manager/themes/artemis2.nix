{ pkgs, lib }: {
  image = pkgs.fetchurl {
    url = "https://images-assets.nasa.gov/image/art002e009567/art002e009567~large.jpg";
    hash = "sha256-luXBmnZB1RbNAyfakAKxPOj57GWD4vwuRag8m/OLcYA=";
  };
  polarity = "dark";
  fonts = {
    serif = {
      package = pkgs.nerd-fonts.caskaydia-cove;
      name = "Caskaydia Cove Nerd Font";
    };

    sansSerif = {
      package = pkgs.nerd-fonts.caskaydia-cove;
      name = "Caskaydia Cove Nerd Font Sans";
    };

    monospace = {
      package = pkgs.nerd-fonts.caskaydia-cove;
      name = "Caskaydia Cove Nerd Font Mono";
    };

    emoji = {
      package = pkgs.noto-fonts-color-emoji;
      name = "Noto Color Emoji";
    };
  };
}
