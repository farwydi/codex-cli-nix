# codex-nix

Nix package for [OpenAI Codex CLI](https://github.com/openai/codex) from the official
prebuilt musl bundle (`codex` + `codex-code-mode-host` + `bwrap`) — no building.

Updated daily by GitHub Actions (`update.sh` regenerates `sources.json`).

## Usage (home-manager)

```nix
let
  codexNixSrc = builtins.fetchTarball {
    url = "https://github.com/farwydi/codex-nix/archive/refs/heads/main.tar.gz";
  };
  codexCli = pkgs.callPackage "${codexNixSrc}/package.nix" { };
in
{
  home.packages = [ codexCli ];
}
```
