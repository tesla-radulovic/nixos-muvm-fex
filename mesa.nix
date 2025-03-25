{
  lib,
  stdenv,
  mesa-asahi-edge,
  llvm,
  buildPackages,
}:
let
  isCross = stdenv.hostPlatform != stdenv.buildPlatform;
in
mesa-asahi-edge.overrideAttrs (old: {
  postInstall =
    old.postInstall or ""
    + ''
      moveToOutput bin/vtn_bindgen2 $cross_tools
      moveToOutput bin/asahi_clc $cross_tools
    '';

  LLVM_CONFIG_PATH = lib.optionalDrvAttr isCross "${llvm.dev}/bin/llvm-config-native";

  nativeBuildInputs =
    old.nativeBuildInputs or [ ]
    ++ lib.optionals isCross [
      buildPackages.mesa-asahi-edge.cross_tools or null
    ];
})
