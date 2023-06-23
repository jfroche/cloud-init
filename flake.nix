{
  description = "Server-optimized NixOS configuration";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = inputs@{ self, nixpkgs, devshell }:
    let
      supportedSystems = [
        "x86_64-linux"
        "i686-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          cloud-init = pkgs.callPackage ./. { inherit (pkgs) buildPythonApplication busybox; };
          default = self.packages.${system}.cloud-init;
        });
      devShell =
        forAllSystems (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ devshell.overlays.default ];
            };
          in
          pkgs.devshell.mkShell {
            packages = with pkgs; [
              (python3.withPackages (p: [
                p.setuptools
                p.tox
                p.responses
                p.pyyaml
                p.pytest
                p.configobj
                p.jsonpatch
                p.netifaces
                p.pyserial
                p.jsonschema
                p.jinja2
                p.pytest-mock
                p.python-lsp-server
                p.pyls-flake8
                (p.pylsp-mypy.overrideAttrs (old: { pytestCheckPhase = "true"; }))
              ]))
              isort
              black
              dmidecode
            ];
            commands = [
              {
                name = "run-tests";
                help = "Run tests";
                command = "${pkgs.python3Packages.tox}/bin/tox -v -e integration-tests -- tests/unittests/net/test_dhcp.py";
              }
            ];
          });
    };
}
