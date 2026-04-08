{ lib
, fetchFromGitHub
, python3
, nodejs
, stdenvNoCC
}:

let
  pname = "webzfs";
  version = "git";

  src = fetchFromGitHub {
    owner = "webzfs";
    repo = "webzfs";
    rev = "main";
    hash = "sha256-TRgryuKkf4YP7Fwrfkg4nu+Mp+aLyZ1Iky0Y/gcnnw0=";
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version src;

  buildInputs = [ python3 nodejs ];

  installPhase = ''
    mkdir -p $out/opt/webzfs
    cp -r $src/* $out/opt/webzfs/
    
    # Create .env from example (will be replaced at runtime)
    cp $out/opt/webzfs/.env.example $out/opt/webzfs/.env 2>/dev/null || true
  '';

  meta = with lib; {
    description = "WebZFS - Web-based ZFS management interface";
    homepage = "https://github.com/webzfs/webzfs";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
