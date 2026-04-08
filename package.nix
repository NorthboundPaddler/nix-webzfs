{ lib
, fetchFromGitHub
, python3
, makeWrapper
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

  buildInputs = [ makeWrapper python3 ];

  installPhase = ''
    mkdir -p $out/opt/webzfs
    cp -r $src/* $out/opt/webzfs/

    # Create virtual environment with system python
    cd $out/opt/webzfs
    python3 -m venv .venv
    . .venv/bin/activate
    pip install -r requirements.txt || true

    # Install Node deps and build CSS
    npm install || true
    npm run build:css || true

    # Create .env from example
    cp .env.example .env 2>/dev/null || true

    # Go back and set up gunicorn wrapper
    cd $out
    mkdir -p $out/bin
    cat > $out/bin/gunicorn << 'WRAPPER'
    #!/bin/sh
    cd /opt/webzfs
    exec .venv/bin/gunicorn "$@"
    WRAPPER
    chmod +x $out/bin/gunicorn

    mkdir -p $out/etc
    cp -r $out/opt/webzfs/config $out/etc/gunicorn.conf.py
  '';

  meta = with lib; {
    description = "WebZFS - Web-based ZFS management interface";
    homepage = "https://github.com/webzfs/webzfs";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
