{
  config,
  lib,
  ...
}:

let
  cfg = config.services.webzfs;
in
{
  options.services.webzfs = {
    enable = lib.mkEnableOption "WebZFS - Web-based ZFS management interface";

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
      home = "/opt/webzfs";
      createHome = false;
    };

    users.groups.${cfg.group} = { };

    systemd.services.webzfs = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "zfs-mount.service" ];

      serviceConfig = {
        Type = "notify";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "/opt/webzfs";
        Environment = [
          "PATH=/opt/webzfs/.venv/bin:/run/wrappers/bin:/usr/local/bin:/usr/bin:/bin"
          "HOST=${cfg.host}"
          "PORT=${toString cfg.port}"
        ];
        ExecStart = "/opt/webzfs/.venv/bin/gunicorn -c /opt/webzfs/config/gunicorn.conf.py";
        Restart = "always";
        RestartSec = "5";
        RuntimeDirectory = "webzfs";
        RuntimeDirectoryMode = "0755";
      };

      environment = cfg.settings;
    };

    environment.etc."webzfs/env".text = let
      baseSettings = {
        CAPTION = "webzfs";
        SECRET_KEY = "changeme-in-production";
        HOST = cfg.host;
        PORT = toString cfg.port;
        SETTINGS_MODULE = "config.settings.base";
      };
    in lib.generators.toKeyValue { } (baseSettings // cfg.settings);

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
