{
  description = "WebZFS - Web-based ZFS management interface and NixOS module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      overlay = final: prev: {
        webzfs = final.callPackage ./package.nix { };
      };
    in
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        webzfs = pkgs.webzfs;
        default = pkgs.webzfs;
      }
    )) // {
      nixosModules = {
        webzfs = import ./module.nix;
      };

      overlays.default = overlay;
    };
}
