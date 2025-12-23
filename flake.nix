{
  description = "GTA San Andreas Savegame Editor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          gtasa-savegame-editor = pkgs.maven.buildMavenPackage rec {
            pname = "gtasa-savegame-editor";
            version = "3.3-rc.26";

            src = pkgs.fetchFromGitHub {
              owner = "gtasa-savegame-editor";
              repo = "gtasa-savegame-editor";
              rev = "v${version}";
              hash = "sha256-aIpNLuFCEUZkjQzle3wz+RhDKynWfR2OFGkI7Eus418=";
            };

            mvnHash = "sha256-bEt4EG8C2aopigTklNy6/yhy48+J7Fp6oly+14feYgg=";

            # Skip tests and git-commit-id plugin during build
            mvnParameters = "-DskipTests=true -Dmaven.gitcommitid.skip=true";

            nativeBuildInputs = with pkgs; [
              makeWrapper
              copyDesktopItems
            ];

            desktopItems = [
              (pkgs.makeDesktopItem {
                name = pname;
                exec = pname;
                icon = pname;
                desktopName = "GTA:SA Savegame Editor";
                comment = "Edit Grand Theft Auto: San Andreas save files";
                categories = [ "Game" "Utility" ];
                mimeTypes = [ "application/x-gtasa-save" ];
              })
            ];

            installPhase = ''
              runHook preInstall

              # Install the main JAR with dependencies
              mkdir -p $out/share/java
              cp savegame-editor/target/savegame-editor-3.3.0-SNAPSHOT-jar-with-dependencies.jar \
                $out/share/java/${pname}.jar

              # Install icon
              mkdir -p $out/share/pixmaps
              cp savegame-editor/src/main/resources/icon-256.png \
                $out/share/pixmaps/${pname}.png

              # Create a wrapper script to run the application
              mkdir -p $out/bin
              makeWrapper ${pkgs.jre}/bin/java $out/bin/${pname} \
                --add-flags "-jar $out/share/java/${pname}.jar"

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Savegame editor for Grand Theft Auto: San Andreas";
              homepage = "https://github.com/gtasa-savegame-editor/gtasa-savegame-editor";
              license = licenses.mit;
              maintainers = [ ];
              platforms = platforms.all;
              mainProgram = pname;
            };
          };

          default = self.packages.${system}.gtasa-savegame-editor;
        };

        apps = {
          gtasa-savegame-editor = {
            type = "app";
            program = "${self.packages.${system}.gtasa-savegame-editor}/bin/gtasa-savegame-editor";
          };

          default = self.apps.${system}.gtasa-savegame-editor;
        };
      }
    );
}
