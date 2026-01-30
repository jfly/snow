{ lib, ... }:
let
  sensorByName = {
    "Bedroom" = "sensor.south_bedroom_weather_temperature";
    "Nursery" = "sensor.northeast_bedroom_weather_temperature";
  };
  # HA doesn't have the ability to define human-readable labels and
  # machine-readable values for an input_select:
  # <https://community.home-assistant.io/t/input-select-enhancement-support-mapping/94391/22>
  sensorMapping = /* jinja */ ''
    {% set mapping = ${builtins.toJSON sensorByName} %}
  '';
in
{
  services.home-assistant.config = {
    climate = [
      {
        unique_id = "snow_therm";
        platform = "generic_thermostat";
        name = "Snow Therm";
        heater = "switch.furnace";
        target_sensor = "sensor.snow_therm_target";
      }
      {
        unique_id = "bed_therm";
        platform = "generic_thermostat";
        name = "Bedroom Therm";
        heater = "switch.south_bedroom_outlet";
        target_sensor = "sensor.south_bedroom_weather_temperature";
      }
    ];
    template = [
      {
        sensor = [
          {
            name = "Snow Therm Target";
            unique_id = "snow_therm_target";
            device_class = "temperature";
            unit_of_measurement = /* jinja */ ''
              ${sensorMapping}
              {{ state_attr(mapping[states('input_select.snow_therm_target_select')], 'unit_of_measurement') }}
            '';
            state = /* jinja */ ''
              ${sensorMapping}
              {{ states(mapping[states('input_select.snow_therm_target_select')]) }}
            '';
          }
        ];
      }
    ];
    input_select = {
      snow_therm_target_select = {
        name = "Snow Therm Target";
        options = lib.attrNames sensorByName;
      };
    };
  };
}
