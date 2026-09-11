{
  description = "ytkew — YouTube Music on the terminal";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };
      runtimePackages = pkgs:
        [ pkgs.mpv pkgs.yt-dlp ]
        ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.pipewire ];
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          manifest = builtins.fromTOML (builtins.readFile ./Cargo.toml);
        in
        {
          default = pkgs.rustPlatform.buildRustPackage {
            pname = manifest.package.name;
            version = manifest.package.version;
            src = pkgs.lib.cleanSource ./.;
            cargoLock.lockFile = ./Cargo.lock;
            nativeBuildInputs = [ pkgs.makeWrapper ];

            postInstall = ''
              wrapProgram "$out/bin/ytkew" \
                --prefix PATH : ${pkgs.lib.makeBinPath (runtimePackages pkgs)}
              install -Dm644 ytkew.desktop "$out/share/applications/ytkew.desktop"
              install -Dm644 assets/ytkew.svg "$out/share/icons/hicolor/scalable/apps/ytkew.svg"
            '';

            meta = {
              inherit (manifest.package) description;
              homepage = manifest.package.repository;
              license = pkgs.lib.licenses.gpl3Plus;
              mainProgram = "ytkew";
              platforms = systems;
            };
          };
        });

      devShells = forAllSystems (system:
        let pkgs = pkgsFor system;
        in {
          default = pkgs.mkShell {
            packages = [ pkgs.cargo pkgs.rustc pkgs.rustfmt pkgs.clippy ]
              ++ runtimePackages pkgs;
          };
        });
    };
}
