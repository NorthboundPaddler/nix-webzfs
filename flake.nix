{
  description = "WebZFS - Web-based ZFS management interface and NixOS module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      overlay = final: prev: {
        webzfs = final.callPackage ./package.nix { };
      };
    in
    {
      packages.x86_64-linux = let
        pkgs = import nixpkgs { system = "x86_64-linux"; overlays = [ overlay ]; };
      in {
        webzfs = pkgs.webzfs;
        default = pkgs.webzfs;
      };

      nixosModules = {
        webzfs = import ./module.nix;
      };

      overlays.default = overlay;
    };
}
