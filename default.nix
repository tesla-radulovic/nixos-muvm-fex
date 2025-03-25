let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  inherit (lock.nodes.__flake-compat.locked) narHash rev url;
  flake-compat = builtins.fetchTarball {
    url = "${url}/archive/${rev}.tar.gz";
    sha256 = narHash;
  };
  flake = import flake-compat { src = ./.; };
in
{
  pkgs ? flake.inputs.legacyPackages.aarch64-linux,
}:
pkgs.extend flake.inputs.self.overlays.default
