{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        {
          packages.default = pkgs.rustPlatform.buildRustPackage rec {
            pname = "keyroost";
            version = "0.7.8";

            src = pkgs.fetchFromGitHub {
              owner = "framefilter";
              repo = "keyroost";
              rev = "refs/tags/v${version}";
              hash = "sha256-oaEzTq7/ETRVXBv9lsoqXvSBdXuGPzdcJW/nrJ7w/7I=";
            };

            cargoHash = "sha256-Rv2wxvFtH6QWOL8aTKlJHvQdkSg0yxK4zfaEvySvv6Y=";

            cargoBuildFlags = [
              "-p"
              "keyroost"
              "-p"
              "keyroostctl"
            ];

            buildNoDefaultFeatures = true;

            nativeBuildInputs = with pkgs; [
              pkg-config
            ];

            buildInputs =
              with pkgs;
              [
                pcsclite
              ]
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                libxkbcommon
                libGL
                wayland
                libx11
                libxcursor
                libxi
                libxrandr
              ];

            postFixup = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
              patchelf --set-rpath "${
                pkgs.lib.makeLibraryPath [
                  pkgs.pcsclite
                  pkgs.wayland
                  pkgs.libx11
                  pkgs.libxcursor
                  pkgs.libxi
                  pkgs.libxrandr
                  pkgs.libGL
                  pkgs.libxkbcommon
                ]
              }" $out/bin/keyroost
              patchelf --set-rpath "${pkgs.lib.makeLibraryPath [ pkgs.pcsclite ]}" $out/bin/keyroostctl
            '';

            meta = {
              description = "Vendor Neutral, Rust-Based Management UI and CLI for U2F/FIDO2 and other hardware security keys";
              homepage = "https://github.com/framefilter/keyroost";
              license = with pkgs.lib.licenses; [
                mit
                asl20
              ];
              platforms = pkgs.lib.platforms.unix;
            };
          };

          devShells.default = pkgs.mkShell {
            inputsFrom = [ config.packages.default ];
            packages = with pkgs; [
              nixfmt
              nixd
            ];
          };
        };
    };
}
