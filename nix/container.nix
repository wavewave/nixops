{ config, lib, ... }:


with lib;

let

  machine = mkOptionType {
    name = "a machine";
    check = x: x._type or "" == "machine";
    merge = mergeOneOption;
  };

  bindMountOpt = {name, config, ...}: {
    options = {
      mountPoint = mkOption {
        example = "/mnt/usb";
        type = types.str;
        description = "Mount point on the container file system.";
      };
      hostPath = mkOption {
        default = null;
        example = "/home/alice";
        type = types.nullOr types.str;
        description = "Location of the host path to be mounted.";
      };
      isReadOnly = mkOption {
        default = true;
        example = true;
        type = types.bool;
        description = "Determine whether the mounted path will be accessed in read-only mode.";
      };
    };
    config = {
      mountPoint = mkDefault name;
    };
    
  };


in

{

  imports = [ ./container-base.nix ];

  options = {

    deployment.container.host = mkOption {
      type = types.either types.str machine;
      apply = x: if builtins.isString x then x else "__machine-" + x._name;
      default = "localhost";
      description = ''
        The NixOS machine on which this container is to be instantiated.
      '';
    };

    deployment.container.hostBridge = mkOption {
      type = types.str;
      default = "";
      description = ''
        The host network interface for bridged network.
      '';
    };

    deployment.container.forwardPorts = mkOption {
      type = types.listOf (types.submodule {
        options = {
          protocol = mkOption {
            type = types.str;
            default = "tcp";
            description = "The protocol specifier for port forwarding between host and container";
          };
          hostPort = mkOption {
            type = types.int;
            description = "Source port of the external interface on host";
          };
          containerPort = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Target port of container";
          };
        };
      });
      default = [];
      example = [ { protocol = "tcp"; hostPort = 8080; containerPort = 80; } ];
      description = ''
        List of forwarded ports from host to container. Each forwarded port is specified by protocol, hostPort and containerPort. By default, protocol is tcp and hostPort and containerPort are assumed to be the same if containerPort is not explicitly given. 
      '';
    };

    deployment.container.bindMounts = mkOption {
      
      type = types.attrsOf (types.submodule bindMountOpt);

      default = {};
      example = { "/home" = { hostPath = "/home/alice";
                              isReadOnly = false; };
                };
      description =
        ''
          An extra list of directories that is bound to the container.
        '';
    };

  };

  config = mkIf (config.deployment.targetEnv == "container") {

    boot.isContainer = true;

  };

}
