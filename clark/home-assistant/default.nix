{ ... }:

{
  image = "homeassistant/home-assistant:stable";
  volumes = [
    "/root/ha-config:/config"
  ];
  environment = {
    TZ = "America/Los_Angeles";
  };
  extraOptions = [
    "--network=host"
    "--privileged=true"
    "--device=/dev/ttyACM0:/dev/ttyACM0"
  ];
}
