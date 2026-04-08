{ lib
, fetchFromGitHub
, python3
, python3Packages
, nodejs
, git
, makeWrapper
, smartmontools
, sudo
, libkrb5
, libsodium
, writeText
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

  python = python3;

  postInstall = writeText "postInstall.sh" ''
    # This script runs after installation to set up the venv
    cd $out/opt/webzfs
    
    # Create virtual environment
    python3 -m venv .venv
    
    # Install Python dependencies
    . .venv/bin/activate
    pip install -r requirements.txt
    
    # Install Node dependencies and build CSS
    npm install
    npm run build:css
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
      cp .env.example .env 2>/dev/null || true
    fi
  '';
in
python3Packages.buildPythonApplication {
  inherit pname version src;

  format = "other";

  nativeBuildInputs = [
    makeWrapper
    nodejs
    git
  ];

  buildInputs = [
    python3
    libkrb5
    libsodium
    smartmontools
    sudo
  ];

  buildPhase = ''
    runPreBuildHooks

    mkdir -p /tmp/webzfs-build
    cp -r $src/* /tmp/webzfs-build/
    cd /tmp/webzfs-build

    # Create virtual environment
    python3 -m venv .venv
    . .venv/bin/activate

    # Install Python dependencies (allow network)
    pip install -r requirements.txt

    # Install Node dependencies and build CSS
    npm install
    npm run build:css

    # Create .env from example
    cp .env.example .env 2>/dev/null || true
  '';

  installPhase = ''
    mkdir -p $out/opt/webzfs
    cp -r /tmp/webzfs-build/* $out/opt/webzfs/

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
