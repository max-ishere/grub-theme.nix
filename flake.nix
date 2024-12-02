{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    unfreePkgs = import nixpkgs {
      config.allowUnfree = true;
      inherit system;
    };
  in {
    formatter.${system} = pkgs.alejandra;

    lib = import ./lib {
      inherit (pkgs) callPackage;
      inherit (nixpkgs) lib;
    };

    devShells.${system} = {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          (unfreePkgs.vscode-with-extensions.override {
            vscodeExtensions = with vscode-extensions; [
              vscodevim.vim
              jnoortheen.nix-ide
            ];
          })
          nixd
        ];
      };
    };
  };
}
