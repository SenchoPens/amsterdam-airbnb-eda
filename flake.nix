{
  description = "Description for the project";

  nixConfig.extra-substituters = [
    "https://tweag-jupyter.cachix.org"
  ];
  nixConfig.extra-trusted-public-keys = [
    "tweag-jupyter.cachix.org-1:UtNH4Zs6hVUFpFBTLaA4ejYavPo5EFFqgd7G7FxGW9g="
  ];

  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "nixpkgs-unstable";
    poetry2nix = {
      # url = "github:nix-community/poetry2nix";
      url = "/home/sencho/n/git/github.com/SenchoPens/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # inputs.jupyenv.url = "github:tweag/jupyenv";
    jupyenv.url = "/home/sencho/n/git/github.com/SenchoPens/jupyterWith";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      perSystem = {
        config,
        lib,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        inherit (inputs'.poetry2nix.legacyPackages) mkPoetryEnv;
        poetryOverrides = inputs'.poetry2nix.legacyPackages.overrides;
        # Provides an environment with Python 3.10 with dependencies from pyproject.toml
        poetryEnv = mkPoetryEnv {
          projectDir = ./.;
          python = pkgs.python311;
          overrides = poetryOverrides;
          # editablePackageSources = {
          #   mygeneration = ./lib/mygeneration;
          # };
          # groups = [];
          groups = ["dev"];
          # otherwise compiles dependencies from source, which takes an enormous amount
          # of time and resources when changing poetry.lock (e.g. mypy is very heavy to compile)
          preferWheels = true;
        };
        inherit (inputs.jupyenv.lib.${system}) mkJupyterlabNew;
        jupyterlab = mkJupyterlabNew ({...}: {
          nixpkgs = inputs.nixpkgs;
          imports = [
            {
              kernel.python.da = {
                enable = true;
                inherit poetryEnv;
                inherit (inputs) poetry2nix;
              };
            }
          ];
        });
      in {
        devShells = {
          # Source code development shell:
          # formatters, checkers / linters, poetry CLI, etc.
          default = pkgs.mkShell {
            nativeBuildInputs = [
              poetryEnv
              jupyterlab
            ];
          };
          # # Shell to generate music: test and run python code, play audio, edit soundfonts.
          # mygeneration = pkgs.mkShell {
          #   buildInputs = [
          #   ];
          # };
        };

        apps = {
          jupyterlab = {
            type = "app";
            program = "${jupyterlab}/bin/jupyter-lab";
          };
          poetry = {
            type = "app";
            program = "${inputs'.poetry2nix.packages.poetry}/bin/poetry";
          };
        };

        packages = {
          soundfonts = pkgs.soundfont-fluid;
        };
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}
