# Kernel Flake

A nix flake dedicated to making the developer tooling around kernel development easier.

## Features

* Compile a local copy of the linux kernel located unter ./linux
* QEMU VM support using Nix's built in functions for generating an initramfs
* Remote GDB debugging through the VM

## Cloning the flake

Get started by cloning this repository.

```bash
git clone git@github.com:fxttr/kernel
cd kernel
git clone --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git linux

# nix develop .# or direnv allow to get into the dev environment

runvm   # Calls QEMU with the necessary commands, uses sudo for enabling kvm

#### Inside QEMU
# insmod module/helloworld.ko   # Load the kernel module
# rmmod module/helloworld.ko    # Unload the module
#### C^A+X to exit
#### In another terminal while the VM is running
# rungdb                        # Connect to the VM with remote GDB debugging
### (GDB)
## lx-symbols-nix               # Runs lx-symbols with the nix store paths of the modules
####

cd linux
bear -- make            # generate the compile_commands.json

# exit and then nix develop .# or just direnv reload
# to rebuild and update the runvm command
```

## How it works

### Remote GDB

Remote GDB debugging is activated through the `rungdb` command (`build/run-gdb.nix`). It wraps GDB to provide the kernel source in the search path, loads `vmlinux`, sources the kernel gdb scripts, and then connects to the VM. An alias is provided `lx-symbols-nix` that runs the `lx-symbols` command with all the provided modules' nix store paths as search directories.

### initramfs

The initial ram disk is built using the new [make-initrd-ng](https://github.com/NixOS/nixpkgs/tree/master/pkgs/build-support/kernel/make-initrd-ng). It is called through its [nix wrapper](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/kernel/make-initrd-ng.nix) which safely copies the nix store packages needed over. To see how to include modules and other options see the builder, `build/initramfs.nix`.

#### C

Clang-format was copied over from the linux source tree. To get CCLS working correctly call `bear -- make` to get a `compile_commands.json`. Then open up C files.

### Direnv

If you have nix-direnv enabled a shell with everything you need should open when you `cd` into the directory after calling `direnv allow`
