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

  # раскладка сохраняется как есть: codex ищет манифест и ресурсы относительно бинаря
  installPhase = ''
    mkdir -p $out
    cp -r bin codex-resources codex-path codex-package.json $out/
    wrapProgram $out/bin/codex \
      --set DISABLE_AUTOUPDATER 1 \
      --prefix PATH : $out/codex-resources:$out/codex-path
  '';

  meta.mainProgram = "codex";
}
