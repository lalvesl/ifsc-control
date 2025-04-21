{
  description = "abnTeX2 environment with TeX Live";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      for_each_system = nixpkgs.lib.genAttrs supportedSystems;

      pkgs = for_each_system (system: import nixpkgs { inherit system; });
      tex_pkgs = for_each_system (
        system:
        pkgs.${system}.texlive.combine {
          inherit (pkgs.${system}.texlive) scheme-full abntex2;
        }
      );
    in
    {
      devShells = for_each_system (system: {
        default = pkgs.${system}.mkShell {
          name = "tex_in_live shell";
          buildInputs = [
            tex_pkgs.${system}
          ];
        };
      });

      apps = for_each_system (system: {
        default = {
          type = "app";
          program = "${pkgs.${system}.writeShellScript "watch" ''
            echo "Watching for changes..."
            mkdir -p result
            exec latexmk -pvc -pdf -outdir=result main.tex
          ''}";
        };
      });

      packages = for_each_system (system: {
        default = pkgs.${system}.stdenv.mkDerivation {
          pname = "abntex2_some_document";
          version = "1.0";

          src = ./.;

          buildInputs = [ tex_pkgs.${system} ];

          buildPhase = ''
            echo "📦 Building your document..."
            # mkdir -p result
            latexmk -outdir=result -pdf main.tex
            echo "✅ Build complete: main.pdf"
          '';

          installPhase = ''
            mkdir -p $out
            cp result/main.pdf $out/
          '';

          dontFixup = true;
          # unpackPhase = "true";
        };
      });
    };
}
