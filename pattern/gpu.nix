{ ... }:

{
  imports = [
    ./nvidia-gpu.nix
  ];

  specialisation = {
    intel-gpu.configuration = {
      # A mobile setup that relies *only* upon the igpu. It cannot connect to any
      # external displays, but is probably more power efficient.
      services.xserver.videoDrivers = [ "modesetting" ];
    };
  };
}
