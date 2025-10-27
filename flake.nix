{

  description = "typst2book";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ...}:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
#system = "x86_64-linux";
          base_font_url = "https://cdn.jsdelivr.net/fontsource/fonts/";
          font_suffix_url = "@latest/latin-400-normal.ttf";
          search_url = "https://api.fontsource.org/fontlist?family";
          template_dir = "template";
          font_dir = "font";
          text_dir = "text";
          image_dir = "image";
      in {
        devShells.${system} = {
          default = pkgs.mkShell {
            packages = with pkgs; [ typst jaq ];
            shellHook = ''
            '';
          };
        };

        packages = {
          init = pkgs.writeShellApplication {
            name = "init";
            runtimeInputs = [pkgs.typst];
            text = ''
              echo init
              mkdir -p ${font_dir} ${text_dir} ${image_dir}
              rsync -a --ignore-existing ${template_dir}/ .
            '';
          };

          font-list = pkgs.writeShellApplication {
            name = "font-list";
            runtimeInputs = [pkgs.typst];
            text = ''
              ${self.packages.${system}.init}/bin/init
              typst fonts --font-path .
            '';
          };
          font-search = pkgs.writeShellApplication {
            name = "font-search";
            runtimeInputs = [pkgs.typst pkgs.curl pkgs.jaq];
            text = ''
              ${self.packages.${system}.init}/bin/init
              search_term="$1"
              echo "$search_term"
              # shellcheck disable=SC2016
              curl -s ${search_url} |
                jaq --arg q "$search_term" '
                  to_entries
                  | map(select(
                    .key
                    | gsub("-"; "")
                    | contains($q | gsub("-"; "") | ascii_downcase)
                  ))
                '
            '';
          };
          font-add= pkgs.writeShellApplication {
            name = "font-add";
            runtimeInputs = [pkgs.typst];
            text = ''
              ${self.packages.${system}.init}/bin/init
              font_name="$1"
              # shellcheck disable=SC2016
              font_path="${font_dir}/$font_name.ttf"
              font_url="${base_font_url}$font_name${font_suffix_url}"
              echo "Downloaded $font_url to $font_path"
              curl -Ls "$font_url" -o "$font_path"
            '';
          };

          compile = pkgs.writeShellApplication {
            name = "compile";
            runtimeInputs = [pkgs.typst];
            text = ''
              typst compile --root . --font-path . text/main.typ
            '';
          };
      };
  });
}
