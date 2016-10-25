# kvms.nix
NixOS KVM guests with a similar interface to containers.

Clone this repo into your /etc/nixos and import it in your configuration.nix like so:
```
  imports = [ ./kvms.nix ];
```

Then you can enable the module and configure as many VM's as you would like, here we create a single vm running postgres:

```
  kvms.enable = true;
  kvms.vms.database = {
    autostart = true;
    config = {config, ...}:
    {
      services.postgresql.enable = true;
    }
  }
```
