{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
    };
    nixos-apple-silicon = {
      url = "github:yuyuyureka/nixos-apple-silicon/minimize-patches";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixos-apple-silicon,
      self,
    }:
    let
      pkgs = nixpkgs.legacyPackages.aarch64-linux;
      overlay = import ./overlay.nix {
        nixos-apple-silicon-overlay = nixos-apple-silicon.overlays.apple-silicon-overlay;
      };
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
