{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
  variant ? import ../../utils/default/variant.nix,
  flavor ? import ../../utils/default/flavor.nix,
}:

let
  name = "ffmpeg";
  packageLock = (import ../../../packages.lock.nix).${name};
  inherit (packageLock) version;

  flavors = import ../../utils/constants/flavors.nix;
  variants = import ../../utils/constants/variants.nix;
  callPackage = pkgs.lib.callPackageWith {
    inherit
      pkgs
      os
      arch
      variant
      flavor
      ;
  };
  nativeFile = callPackage ../../utils/native-file/default.nix { };
  crossFile = callPackage ../../utils/cross-file/default.nix { };
  mbedtls = callPackage ../mk-pkg-mbedtls/default.nix { };
  dav1d = callPackage ../mk-pkg-dav1d/default.nix { };
  libxml2 = callPackage ../mk-pkg-libxml2/default.nix { };
  libvorbis = callPackage ../mk-pkg-libvorbis/default.nix { };
  libvpx = callPackage ../mk-pkg-libvpx/default.nix { };
  libx264 = callPackage ../mk-pkg-libx264/default.nix { };

  pname = import ../../utils/name/package.nix name;
  src = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-source-${version}";
    inherit (packageLock) url sha256;
  };
  patchedSource = pkgs.runCommand "${pname}-patched-source-${version}" { } ''
    cp -r ${src} src
    export src=$PWD/src
    chmod -R 777 $src

    cd $src
    patch -p1 <${../../../patches/ffmpeg-fix-vp9-hwaccel.patch}
    patch -p1 <${../../../patches/ffmpeg-fix-ios-hdr-texture.patch}
    patch -p1 <${../../../patches/ffmpeg-fix-dash-base-url-escape.patch}
    patch -p1 <${../../../patches/ffmpeg-mbedtls-psa-init.patch}
    cd -

    cp ${./meson.build} $src/meson.build
    cp ${./meson.options} $src/meson.options

    cp -r $src $out
  '';

  # FFmpeg 6.1.6's VideoToolbox scaler (iOS 16) and encoders (iOS 11,
  # macOS 10.13) don't build for the iOS 9 and macOS 10.9 these target
  # (-Werror=partial-availability), so the video encodersgpl flavor, the only
  # one to enable all filters and encoders, goes without them. Done here, on a
  # copy of the source with the same name, rather than in meson.build, so the
  # other flavors' builds stay exactly as they were.
  withoutVideoToolboxEncoders =
    pkgs.lib.optionalString (variant == variants.video && flavor == flavors.encodersgpl)
      ''
        mkdir encodersgpl
        cp -r $src encodersgpl/
        src=$PWD/encodersgpl/$(basename $src)
        chmod -R u+w $src
        sed -i.orig "s|'--enable-libx264',|'--enable-libx264', '--disable-filter=scale_vt', '--disable-encoder=h264_videotoolbox', '--disable-encoder=hevc_videotoolbox', '--disable-encoder=prores_videotoolbox',|" $src/meson.build
        grep -q "disable-filter=scale_vt" $src/meson.build
      '';
in

pkgs.stdenvNoCC.mkDerivation {
  name = "${pname}-${os}-${arch}-${variant}-${flavor}-${version}";
  pname = pname;
  inherit version;
  src = patchedSource;
  dontUnpack = true;
  enableParallelBuilding = true;
  nativeBuildInputs = [
    pkgs.meson
    pkgs.ninja
    pkgs.pkg-config
  ];
  buildInputs =
    [ mbedtls ]
    ++ pkgs.lib.optionals (flavor == flavors.encodersgpl) [
      libvorbis
    ]
    ++ pkgs.lib.optionals (variant == variants.video) [
      dav1d
      libxml2
    ]
    ++ pkgs.lib.optionals (variant == variants.video && flavor == flavors.encodersgpl) [
      libvpx
      libx264
    ];
  configurePhase = withoutVideoToolboxEncoders + ''
    meson setup build $src \
      --native-file ${nativeFile} \
      --cross-file ${crossFile} \
      --prefix=$out \
      -Dvariant=${variant} \
      -Dflavor=${flavor} |
      tee configure.log
  '';
  buildPhase = ''
    meson compile -vC build $(basename $src)
  '';
  installPhase = ''
    # manual install to preserve symlinks (meson install -C build)
    cp -r build/dist$out $out

    # copy configure.log
    cp configure.log $out/share/ffmpeg/
  '';
}
