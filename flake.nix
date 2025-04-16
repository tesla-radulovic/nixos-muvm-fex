{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
    };
    nixos-apple-silicon = {
      url = "github:yuyuyureka/nixos-apple-silicon/minimize-patches";
      flake = false;
    };
    __flake-compat = {
      url = "git+https://git.lix.systems/lix-project/flake-compat.git";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      pkgs = nixpkgs.legacyPackages.aarch64-linux;
      overlay = import ./overlay.nix;
      pkgs' = pkgs.extend overlay;
    in
    {
      overlays.default = overlay;

      packages.aarch64-linux = {
        inherit (pkgs')
          mesa-asahi-edge
          muvm
          fex
          fex-x86_64-rootfs
          ;
        mesa-x86_64-linux = pkgs'.pkgsCross.gnu64.mesa-asahi-edge;
      };
    };
}
