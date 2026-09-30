{
  stdenvNoCC,
  fetchurl,
  zstd,
  makeWrapper,
}:

let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  system = stdenvNoCC.hostPlatform.system;
  entry = sources.systems.${system} or (throw "codex-cli: unsupported system ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "codex-cli";
  version = sources.version;

  # официальный package (статический musl): bin/codex + codex-code-mode-host,
  # codex-resources/{bwrap,zsh}, codex-path/rg, манифест codex-package.json
  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${sources.version}/codex-package-${entry.target}.tar.zst";
    hash = entry.hash;
  };

  nativeBuildInputs = [ zstd makeWrapper ];

  sourceRoot = ".";
  unpackCmd = "zstd -d --stdout $curSrc | tar -x";

  dontBuild = true;
  dontStrip = true;

  # Daemon сравнивает bin/codex с текущим ELF: обёртка должна быть вне package.
  installPhase = ''
    mkdir -p $out/bin $out/libexec/codex
    cp -r bin codex-resources codex-path codex-package.json $out/libexec/codex/
    makeWrapper $out/libexec/codex/bin/codex $out/bin/codex \
      --set DISABLE_AUTOUPDATER 1 \
      --prefix PATH : $out/libexec/codex/codex-resources:$out/libexec/codex/codex-path
    ln -s $out/libexec/codex/bin/codex-code-mode-host $out/bin/codex-code-mode-host
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    cmp bin/codex $out/libexec/codex/bin/codex
    cmp codex-package.json $out/libexec/codex/codex-package.json
    $out/bin/codex --version
  '';

  meta.mainProgram = "codex";
  meta.platforms = builtins.attrNames sources.systems;
}
