{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.webzfs;
  webzfsDir = "${cfg.package}/opt/webzfs";
in
{
  options.services.webzfs = {
    enable = lib.mkEnableOption "WebZFS - Web-based ZFS management interface";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.webzfs;
      defaultText = lib.literalExpression "pkgs.webzfs";
      description = ''
        The webzfs package to use.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 26619;
      description = "Port to listen on.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address to bind to.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        SECRET_KEY = "your-secret-key-here";
        AUTH_SESSION_EXPIRES_SECONDS = "3600";
      };
      description = "Additional environment variables for webzfs.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for the webzfs port.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "webzfs";
      description = "User account to run webzfs as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "webzfs";
      description = "Group for webzfs user.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      description = "WebZFS service user";
    };

    users.groups.${cfg.group} = { };

    systemd.services.webzfs = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "zfs-mount.service" ];

      serviceConfig = {
        Type = "notify";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = webzfsDir;
        Environment = [
          "PATH=${webzfsDir}/.venv/bin:/run/wrappers/bin:/usr/local/bin:/usr/bin:/bin"
          "HOST=${cfg.host}"
          "PORT=${toString cfg.port}"
        ];
        ExecStart = "${webzfsDir}/.venv/bin/gunicorn -c ${webzfsDir}/config/gunicorn.conf.py";
        Restart = "always";
        RestartSec = "5";
      };

      environment = cfg.settings;

      script = ''
        # Create .env file from /etc if it doesn't exist
        if [ ! -f "${webzfsDir}/.env" ]; then
          cp /etc/webzfs/env "${webzfsDir}/.env" 2>/dev/null || true
        fi

        # Ensure the venv python is executable
        exec ${webzfsDir}/.venv/bin/gunicorn -c ${webzfsDir}/config/gunicorn.conf.py
      '';

      preStart = ''
        if [ ! -f "${webzfsDir}/.env" ]; then
          cp /etc/webzfs/env "${webzfsDir}/.env"
          chmod 644 "${webzfsDir}/.env"
        fi
      '';
    };

    environment.etc."webzfs/env".text = let
      baseSettings = {
        CAPTION = "webzfs ${cfg.package.version or "git"}";
        SECRET_KEY = "changeme-in-production";
        HOST = cfg.host;
        PORT = toString cfg.port;
        SETTINGS_MODULE = "config.settings.base";
      };
    in lib.generators.toKeyValue { } (baseSettings // cfg.settings);

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
