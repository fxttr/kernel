{ pkgs
, lib ? pkgs.lib
,
}: {
  buildInitramfs = pkgs.callPackage ./initramfs.nix { };

  buildKernelConfig = pkgs.callPackage ./kernel-config.nix { };
  buildKernel = pkgs.callPackage ./kernel.nix { };

  buildQemuCmd = pkgs.callPackage ./run-qemu.nix { };
  buildGdbCmd = pkgs.callPackage ./run-gdb.nix { };
}
