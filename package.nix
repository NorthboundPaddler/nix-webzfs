{ lib
, fetchFromGitHub
, python3
, nodejs
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

  buildInputs = [ makeWrapper python3 nodejs ];

  installPhase = ''
    mkdir -p $out/opt/webzfs
    cp -r $src/* $out/opt/webzfs/

    cd $out/opt/webzfs

    # Create virtual environment
    python3 -m venv .venv
    . .venv/bin/activate
    pip install -r requirements.txt

    # Install Node deps and build CSS (npm is included with nodejs)
    npm install
    npm run build:css

    # Create .env from example
    cp .env.example .env 2>/dev/null || true
    deactivate

    # Create wrapper script for gunicorn
    mkdir -p $out/bin

    cat > $out/bin/gunicorn << EOF
    #!${python3}/bin/python
    import sys
    import os
    os.chdir("$out/opt/webzfs")
    sys.path.insert(0, "$out/opt/webzfs")
    os.environ["PYTHONPATH"] = "$out/opt/webzfs"
    import gunicorn.app.wsgiapp
    sys.exit(gunicorn.app.wsgiapp.run())
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
