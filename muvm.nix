# Based on https://github.com/NixOS/nixpkgs/pull/347792/commits/3998e8369521ffc6e89acc9518925504eac0e4e9
{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  libkrun,
  makeBinaryWrapper,
  passt,
  dhcpcd,
  systemd,
  udev,
  pkg-config,
  procps,
  socat,
  coreutils,
  fex,
  withFex ? stdenv.isAarch64,
  fex-x86_64-rootfs,
  fexRootFS ? if withFex then fex-x86_64-rootfs else null,
  findutils,
  util-linux,
  writeShellApplication,
  fuse,
  mesa-x86_64-linux,
  hardcodedMesa ? withFex,
}:
let
  binPath = lib.makeBinPath (
    [
      dhcpcd
      passt
      (placeholder "out")
      socat
    ]
    ++ lib.optionals withFex [ fex ]
  );

  mesaDir = if hardcodedMesa then mesa-x86_64-linux else "/run/muvm-host/run/opengl-driver";
  initScript = writeShellApplication {
    name = "muvm-init";
    runtimeInputs = [
      coreutils
      util-linux
      findutils
    ];
    text = ''
      ln -s /run/muvm-host/run/current-system /run/current-system
      ln -s ${mesaDir} /run/opengl-driver

      # Set up fusermount suid wrapper. Needed for FEX
      mkdir -p /run/wrappers
      mount -t tmpfs -o exec,suid tmpfs /run/wrappers
      mkdir -p /run/wrappers/bin
      cp "${lib.getExe' fuse "fusermount"}" /run/wrappers/bin/fusermount
      chown root:root /run/wrappers/bin/fusermount
      chmod u=srx,g=x,o=x /run/wrappers/bin/fusermount
    '';
  };

  wrapperArgs = lib.escapeShellArgs (
    [
      "--prefix"
      "PATH"
      ":"
      binPath
      "--add-flags"
      "--execute-pre=${lib.getExe initScript}"
    ]
    ++ lib.optionals (withFex && fexRootFS != null) [
      # TODO: Doesn't actually currently work
      "--add-flags"
      "--fex-image=${fexRootFS}"
    ]
  );
in
assert lib.assertMsg (withFex -> stdenv.isAarch64) "FEX only support aarch64 hosts";
rustPlatform.buildRustPackage rec {
  pname = "muvm";
  version = "0.3.1-unstable-16-03-2025";

  src = fetchFromGitHub {
    owner = "AsahiLinux";
    repo = pname;
    rev = "refs/pull/158/merge";
    hash = "sha256-egZT9w+tj97d8uVuEPhj5y+2EhH04q1Rgfw3s7njysw=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-aF7R8YpygU4zevKrV8hZBTO6vah4ZtqU9hUI+8OBk4E=";

  postPatch = ''
    substituteInPlace crates/muvm/src/guest/bin/muvm-guest.rs \
      --replace-fail "/usr/lib/systemd/systemd-udevd" "${systemd}/lib/systemd/systemd-udevd"
      
    substituteInPlace crates/muvm/src/monitor.rs \
      --replace-fail "/sbin/sysctl" "${procps}/bin/sysctl"

    substituteInPlace crates/muvm/src/guest/mount.rs \
      --replace-fail "/usr/share/fex-emu" "${fex}/share/fex-emu"
  '';

  nativeBuildInputs = [
    rustPlatform.bindgenHook
    makeBinaryWrapper
    pkg-config
  ];

  buildInputs = [
    (libkrun.override {
      withBlk = true;
      withGpu = true;
      withNet = true;
    })
    udev
  ];

  postFixup = ''
    wrapProgram $out/bin/muvm ${wrapperArgs}
  '';

  meta = {
    description = "Run programs from your system in a microVM";
    homepage = "https://github.com/AsahiLinux/muvm";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ nrabulinski ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    mainProgram = "muvm";
  };
}
