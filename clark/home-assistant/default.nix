{ ... }:

{
  image = "homeassistant/home-assistant:stable";
  volumes = [
    "/mnt/media/home-assistant/config:/config"
  ];
  environment = {
    TZ = "America/Los_Angeles";
  };
  extraOptions = [
    "--network=clark"
  ];
}
