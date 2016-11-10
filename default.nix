{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.kvms;
  makeVMService = target: {
    name = "kvms-"+target.name;
    enable = target.autostart;
    value = {
      description = target.name+" VM";
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 2;
      };
      wantedBy = [ "multi-user.target" ];
      script = ''
        mkdir -p /var/lib/kvms/
        ${target.qemubuild}/bin/run-${target.name}-vm
      '';
    };
  };
in {
  ######### NixOS Options Interface
  options = {
    kvms = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable KVM NixOS VM's.
        '';
      };
      vms = mkOption {
        type = types.attrsOf (types.submodule (
          { config, options, name, ... }:
          {
            options = {
              name = mkOption {
                type = types.string;
                default = name;
                description = "VM name.";
              };
              autostart = mkOption {
                type = types.bool;
                default = false;
                description = "Start this VM on boot.";
              };
              qemubuild = mkOption {
                type = types.path;
                description = "qemu-nix build";
              };

              config = mkOption {
                description = "Configrations of NixOS VM's.";
                type = lib.mkOptionType {
                  name = "Toplevel NixOS config for a KVM VM";
                  merge = loc: defs: (import <nixos/nixos/lib/eval-config.nix> {
                    modules = let extraConfig = {
                        networking.hostName = mkDefault name;
                        virtualisation.graphics = false;
                        virtualisation.diskImage = "/var/lib/kvms/${name}.qcow2";
                        imports = [ ./qemu-vm.nix ];
                      };
                      in [ extraConfig ] ++ (map (x: x.value) defs);
                    prefix = [ "kvms" name ];
                  }).config;
                };
              };
            };
            config = mkMerge [
              (mkIf options.config.isDefined {
                qemubuild = config.config.system.build.vm;
              })
            ];
          }
        ));
        default = {};
        example = literalExample ''
          { database = {
              autostart = true;
              config = { config, ... }:
              {
                services.postgresql.enable = true;
              };
            };
          }
        '';
        description = ''
          A set of NixOS system configurations to be run as KVM virtual machines.
        '';
      };
    };
  };
  ######### Implementation of the interface's options
  config = let
    VMServices = builtins.listToAttrs (map makeVMService (attrValues config.kvms.vms));
  in mkIf cfg.enable {
    systemd.services = VMServices;
  };
}
