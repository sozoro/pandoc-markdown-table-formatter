{
  description = "pandoc-markdown-table-formatter";

  inputs = {
    nixpkgs.url     = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url    = "github:numtide/devshell";
  };

  outputs = { self, ... }@inputs: (inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [
      inputs.devshell.flakeModule
    ];
    systems   = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
    perSystem = { pkgs, system, ... }: rec {
      packages.default  = pkgs.vimUtils.buildVimPlugin rec {
        pname        = "${self.name}";
        name         = pname;
        src          = ./.;
        dependencies = [];
      };
    };
  }) // {
    name         = "pandoc-markdown-table-formatter";
    nixosModules = rec {
      addpkg = { pkgs, ... }: {
        nixpkgs.config = {
          packageOverrides = oldpkgs: let newpkgs = oldpkgs.pkgs; in {
            "myVimPlugins_${self.name}" = self.packages."${pkgs.system}".default;
          };
        };
      };

      install = { pkgs, ... }: (addpkg { inherit pkgs; }) // {
        programs.vim.plugins.start = [ pkgs."myVimPlugins_${self.name}" ];
      };
    };
  };
}
