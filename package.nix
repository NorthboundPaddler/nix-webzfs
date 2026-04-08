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

    cd $out/opt/webzfs

    # Create .env from example
    cp .env.example .env 2>/dev/null || true

    # Create wrapper script for gunicorn that uses system Python
    mkdir -p $out/bin
    cat > $out/bin/gunicorn << EOF
    #!/bin/sh
    cd "$out/opt/webzfs"
    export PYTHONPATH="$out/opt/webzfs"
    exec gunicorn -c "$out/opt/webzfs/config/gunicorn.conf.py" app.main:app
    EOF
    chmod +x $out/bin/gunicorn
  '';

  meta = with lib; {
    description = "WebZFS - Web-based ZFS management interface";
    homepage = "https://github.com/webzfs/webzfs";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
