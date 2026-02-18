{ flake, ... }:
{
  imports = [
    flake.nixosModules.ntfy-alertmanager
  ];

  services.ntfy-alertmanager = {
    enable = true;
    port = 8567;
    ntfy.topic = "jfly";
  };
}
