{
  description = "Linux development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    linux = {
      url = "git+file:./linux?shallow=1";
      flake = false;
    };
  };

  outputs =
    { self
    , nixpkgs
    , linux
    , ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Flake options
      enableGdb = true;

      buildLib = pkgs.callPackage ./build { };

      linuxConfigs = pkgs.callPackage ./configs/kernel.nix { inherit enableGdb linux; };
      inherit (linuxConfigs) kernelArgs kernelConfig;

      # Config file derivation
      configfile = buildLib.buildKernelConfig {
        inherit
          (kernelConfig)
          generateConfigFlags
          structuredExtraConfig
          ;
        inherit kernel nixpkgs;
      };

      # Kernel derivation
      kernelDrv = buildLib.buildKernel {
        inherit
          (kernelArgs)
          src
          modDirVersion
          version
          enableGdb
          ;

        inherit configfile nixpkgs;
      };

      linuxDev = pkgs.linuxPackagesFor kernelDrv;
      kernel = linuxDev.kernel;

      initramfs = buildLib.buildInitramfs {
        inherit kernel;

        extraBin =
          {
            strace = "${pkgs.strace}/bin/strace";
          };
        storePaths = [ pkgs.foot.terminfo ];
      };

      runQemu = buildLib.buildQemuCmd { inherit kernel initramfs enableGdb; };
      runGdb = buildLib.buildGdbCmd { inherit kernel; };

      devShell =
        let
          nativeBuildInputs = with pkgs;
            [
              bear # for compile_commands.json, use bear -- make
              runQemu
              git
              gdb
              qemu
              pahole
              flex
              bison
              bc
              pkg-config
              elfutils
              openssl.dev
              llvmPackages.clang
              (python3.withPackages (ps: with ps; [
                GitPython
                ply
              ]))
              codespell

              # static analysis
              flawfinder
              cppcheck
              sparse
            ]
            ++ lib.optional enableGdb runGdb;
          buildInputs = [ pkgs.nukeReferences kernel.dev ];
        in
        pkgs.mkShell {
          inherit buildInputs nativeBuildInputs;
          KERNEL = kernel.dev;
          KERNEL_VERSION = kernel.modDirVersion;
        };
    in
    {
      lib = {
        builders = import ./build/default.nix;
      };

      packages.${system} = {
        inherit initramfs kernel;
        kernelConfig = configfile;
      };

      devShells.${system}.default = devShell;
    };
}
