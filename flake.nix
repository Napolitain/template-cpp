{
  description = "Optional development shell for template-cpp";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    in
    {
      devShells = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          common = [
            pkgs.git
            pkgs.prek
            pkgs.cmake
            pkgs.ninja
            pkgs.llvmPackages.clang-tools
            pkgs.llvmPackages.llvm
            # Wrapped LLD retains Nix runtime library search paths.
            pkgs.llvmPackages.bintools
            pkgs.cppcheck
            pkgs.pkg-config
          ];
          shell =
            extra:
            (pkgs.mkShell.override { stdenv = pkgs.llvmPackages.stdenv; }) {
              packages = common ++ extra;
            };
        in
        {
          default = shell [ ];
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          propeller = shell [
            pkgs.python3
            pkgs.elfutils
            pkgs.openssl
            pkgs.zlib
            pkgs.zstd
          ];
        }
      );
    };
}
