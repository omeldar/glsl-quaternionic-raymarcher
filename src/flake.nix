{
  description = "A self-contained WebGPU development environment with a configured VS Code";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        unfreeConfig = {
          allowUnfreePredicate = pkg:
            let
              drvName = if pkg ? "pname" then pkg.pname else pkg.name;
            in
              builtins.elem (builtins.parseDrvName drvName).name [
                "vscode"
                "vscode-with-extensions"
              ];
        };

        pkgs = import nixpkgs {
          inherit system;
          config = unfreeConfig;
        };

        unstablePkgs = import nixpkgs-unstable {
          inherit system;
          config = unfreeConfig;
        };

        all-vscode-extensions = pkgs.vscode-extensions // unstablePkgs.vscode-extensions;

        # We now build our custom VS Code using the 'unstable' package set.
        # This ensures we get a recent version of Code compatible with the latest extensions.
        vscode-with-extensions = unstablePkgs.vscode-with-extensions.override {
          vscode = unstablePkgs.vscode; # Use the unstable version of VS Code
          vscodeExtensions = with all-vscode-extensions; [
            wgsl-analyzer.wgsl-analyzer
            esbenp.prettier-vscode
            eamodio.gitlens
            sdras.night-owl
          ];
        };

      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.nodePackages.http-server
            unstablePkgs.wgsl-analyzer
            vscode-with-extensions
          ];

          shellHook = ''
            echo " "
            echo "✅ WebGPU development environment is ready."
            echo " "
            echo "A project-specific .vscode/settings.json file has been created."
            echo "Run 'code .' to open the configured VS Code."
            echo "Then run 'http-server -p <port>' to start the local webserver."
            echo " "

            mkdir -p .vscode

            cat > .vscode/settings.json <<EOF
{
    "editor.fontSize": 12,
    "editor.fontFamily": "Fira Code, JetBrains Mono, Consolas, 'Courier New', monospace",
    "editor.tabSize": 4,
    "editor.wordWrap": "on",
    "workbench.colorTheme": "Night Owl",
    "editor.formatOnSave": true,
    "files.autoSave": "afterDelay",
    "editor.minimap.enabled": true,
    "terminal.integrated.fontSize": 14,
    "git.autofetch": true,
    "prettier.printWidth": 100,
    "[wgsl]": {
        "editor.defaultFormatter": "wgsl-analyzer.wgsl-analyzer"
    }
}
EOF
          '';
        };
      });
}
