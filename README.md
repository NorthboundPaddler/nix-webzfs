# nix-webzfs

An unofficial NixOS module for [WebZFS](https://github.com/webzfs/webzfs) - a modern web-based management interface for ZFS pools, datasets, snapshots, and SMART disk monitoring.

## Features

- NixOS module for easy integration: `services.webzfs.enable = true;`
- Systemd service management
- Configurable port, host, and settings
- Optional firewall configuration
- Customizable user/group

## Usage

### With Flakes

```nix
{
  inputs.webzfs = {
    url = "github:aaron/webzfs/nix-webzfs";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, webzfs }: {
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      modules = [
        webzfs.nixosModules.webzfs
        # ... other modules
      ];
      specialArgs = { inherit inputs; };
    };
  };
}
```

Then in your NixOS config:

```nix
services.webzfs = {
  enable = true;
  settings.SECRET_KEY = "your-production-secret-key";
  openFirewall = true;
};
```

### Without Flakes

Download or reference the module directly:

```nix
{ config, pkgs, ... }:

{
  imports = [ /path/to/module.nix ];

  services.webzfs = {
    enable = true;
    settings.SECRET_KEY = "your-production-secret-key";
  };
}
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable WebZFS service |
| `package` | package | - | Override the webzfs package |
| `port` | port | `26619` | Listen port |
| `host` | string | `"127.0.0.1"` | Bind address |
| `settings` | attrs | `{}` | Extra environment variables |
| `openFirewall` | bool | `false` | Open firewall port |
| `user` | string | `"webzfs"` | Service user |
| `group` | string | `"webzfs"` | Service group |

## Access

After enabling, access WebZFS at: http://localhost:26619

For remote access, use SSH port forwarding:
```bash
ssh -L 127.0.0.1:26619:127.0.0.1:26619 user@server
```
