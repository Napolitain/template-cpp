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
                in
                {
                    default = (pkgs.mkShell.override { stdenv = pkgs.llvmPackages.stdenv; }) {
                        packages = [
                            pkgs.git
                            pkgs.prek
                            pkgs.cmake
                            pkgs.ninja
                            pkgs.llvmPackages.clang-tools
                            pkgs.llvmPackages.llvm
                            pkgs.llvmPackages.lld
                            pkgs.cppcheck
                            pkgs.pkg-config
                        ];
                    };
                }
            );
        };
}
