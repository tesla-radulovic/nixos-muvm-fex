{ nixos-apple-silicon-overlay }:
final: prev:
let
  overlayed = nixos-apple-silicon-overlay final prev;
in
overlayed
// {
  virglrenderer = prev.virglrenderer.overrideAttrs (old: {
    src = final.fetchurl {
      url = "https://gitlab.freedesktop.org/asahi/virglrenderer/-/archive/asahi-20241205.2/virglrenderer-asahi-20241205.2.tar.bz2";
      hash = "sha256-mESFaB//RThS5Uts8dCRExfxT5DQ+QQgTDWBoQppU7U=";
    };
    mesonFlags = old.mesonFlags ++ [ (final.lib.mesonOption "drm-renderers" "asahi-experimental") ];
  });
  libkrun = final.callPackage ./libkrun.nix { };
  mesa-asahi-edge = final.callPackage ./mesa.nix { inherit (overlayed) mesa-asahi-edge; };
  muvm = final.callPackage ./muvm.nix { mesa-x86_64-linux = final.pkgsCross.gnu64.mesa-asahi-edge; };
  fex = final.callPackage ./fex.nix { };
  fex-x86_64-rootfs = final.runCommand "fex-rootfs" { nativeBuildInputs = [ final.erofs-utils ]; } ''
    mkdir -p rootfs/run/opengl-driver
    cp -R "${final.pkgsCross.gnu64.mesa-asahi-edge}"/* rootfs/run/opengl-driver/
    mkfs.erofs $out rootfs/
  '';
}
