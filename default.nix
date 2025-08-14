{ pkgs ? import <nixpkgs> {} }:
let
  inherit (pkgs) stdenvNoCC fetchurl lib autoPatchelfHook makeWrapper;
in
stdenvNoCC.mkDerivation (finalAttrs: rec {
  pname = "codex";
  version = "0.21.0";

  # Remote tarball (preferred for reproducibility)
  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v0.21.0/codex-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = "0p9c8dn7wqyfi4jsbb4jx9r0flavli9k7r4xsi1bvqil1b2fy001";
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
		install -m755 codex-x86_64-unknown-linux-gnu $out/bin/${pname}

    runHook postInstall
  '';

	postInstall = ''
		libPath=${pkgs.lib.makeLibraryPath [
			pkgs.openssl
		]}

		wrapProgram $out/bin/codex \
			--prefix LD_LIBRARY_PATH : "$libPath" \
	'';

  meta = with lib; {
    description = "OpenAI Codex Cli";
    homepage    = "https://github.com/openai/codex";
    license     = licenses.asl20;
    platforms   = [ "x86_64-linux" ];
    mainProgram = pname;
  };
})
