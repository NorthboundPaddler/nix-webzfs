{ lib
, fetchFromGitHub
, makeWrapper
, stdenvNoCC
}:

let
  src = fetchFromGitHub {
    owner = "webzfs";
    repo = "webzfs";
    rev = "main";
    hash = "sha256-TRgryuKkf4YP7Fwrfkg4nu+Mp+aLyZ1Iky0Y/gcnnw0=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "webzfs";
  version = "git";
  inherit src;

  buildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/opt/webzfs
    cp -r $src/* $out/opt/webzfs/

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
