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

  # официальный bundle: codex + codex-code-mode-host + codex-resources/bwrap (статический musl)
  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${sources.version}/codex-${entry.target}-bundle.tar.zst";
    hash = entry.hash;
  };

  nativeBuildInputs = [ zstd makeWrapper ];

  sourceRoot = ".";
  unpackCmd = "zstd -d --stdout $curSrc | tar -x";

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    mkdir -p $out/bin
    cp codex codex-code-mode-host $out/bin/
    cp -r codex-resources $out/bin/codex-resources
    wrapProgram $out/bin/codex \
      --set DISABLE_AUTOUPDATER 1 \
      --set CODEX_CODE_MODE_HOST_PATH $out/bin/codex-code-mode-host \
      --prefix PATH : $out/bin/codex-resources
  '';

  meta.mainProgram = "codex";
}
