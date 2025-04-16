let
  inputs = import ./inputs.nix;
in
{
  pkgs ? inputs.nixpkgs.legacyPackages.aarch64-linux,
}:
pkgs.extend (import ./overlay.nix)
