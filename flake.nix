{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    formatter.${system} = pkgs.alejandra;

    lib = {
      mkGrubThemePreview = pkgs.callPackage ./lib/mkGrubThemePreview.nix {};
      mkGrubThemeTxt = pkgs.callPackage ./lib/mkGrubThemeTxt.nix {};
    };
  };
}
