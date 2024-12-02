{
  callPackage,
  lib,
}: let
  fmtPosition = self: let
    pc =
      lib.optionalString (self.percent != 0)
      "${builtins.toString (builtins.floor self.percent)}%";
    sign = lib.optionalString (self.percent != 0) (
      if self.pixels > 0
      then "+"
      else "" # minus is handeled by toString
    );
    px = lib.optionalString (self.pixels != 0) "${builtins.toString (builtins.floor self.pixels)}";
  in "${pc}${sign}${px}";

  rel = percent: pixels: {
    __toString = fmtPosition;
    inherit percent pixels;
  };
in {
  # Derivation that outputs a preview ISO and a script to preview the theme
  mkGrubThemePreview = callPackage ./mkGrubThemePreview.nix {};

  # Returns a string value of the `theme.txt` file that can be used with GRUB.
  mkGrubThemeTxt = callPackage ./mkGrubThemeTxt.nix {};

  # Helper for `mkGrubThemeTxt` component declation.
  # ```nix
  # mkComponent "image" {
  #   file = "image.png";
  # }
  # ```
  mkComponent = type: config: {${type} = config;};

  # Create a position relative to a percentage:
  # ```nix
  # "${ rel 50 7 }"
  # "50%+7"
  # ```
  # The resulting value can either be converted to a string via `builtins.toString` or each component of the
  # position can be accessed for changes / calculations in other positions
  # ```nix
  # (rel 50 3).pixels
  # 3
  # ```
  inherit rel;

  # Same as `rel`, but the pixel value is negated (`- pixels`). "I" is for inverse.
  irel = percent: pixels: {
    __toString = fmtPosition;
    inherit percent;
    pixels = - pixels;
  };

  # Create a percentage value. Equivalent to calling `rel value 0`.
  percent = lib.flip rel 0;
}
