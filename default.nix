{ pkgs ? import <nixpkgs> {} }:
let
  inherit (pkgs) stdenvNoCC fetchurl lib autoPatchelfHook makeWrapper;
in
stdenvNoCC.mkDerivation (finalAttrs: rec {
  pname = "codex";
  version = "0.21.0";

  # Remote tarball (preferred for reproducibility)
  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v0.21.0/codex-x86_64-unknown-linux-musl.tar.gz";
    sha256 = "167kk71agil905z0g5maz57iz3p0d4pv0s3dhd1246i1h4la0145";
  };

  # If the tarball unpacks straight into files with no top-level directory:
  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook   # automatically fixes ELF interpreter + RPATH
    makeWrapper        # provides wrapProgram for convenience
  ];

  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
		openssl
  ];

  # No build – just install the unpacked files into $out
  installPhase = ''
    runHook preInstall

		# Install supporting files
    mkdir -p $out/bin
		install -m755 codex-x86_64-unknown-linux-musl $out/bin/${pname}

    runHook postInstall
  '';

	postInstall = ''
		libPath=${pkgs.lib.makeLibraryPath [
			pkgs.openssl
		]}

		wrapProgram $out/bin/codex \
			--prefix LD_LIBRARY_PATH : "$libPath" \
	'';

	postFixup = ''
			wrapProgram "$out/bin/${pname}" \
				--prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.python3 ]}
	'';

  meta = with lib; {
    description = "OpenAI Codex Cli";
    homepage    = "https://github.com/openai/codex";
    license     = licenses.asl20;
    platforms   = [ "x86_64-linux" ];
    mainProgram = pname;
  };
})
