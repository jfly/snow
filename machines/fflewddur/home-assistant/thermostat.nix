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
        heater = "switch.thermostat_house_furnace";
        target_sensor = "sensor.snow_therm_target";
      }
      {
        unique_id = "laundry_therm";
        platform = "generic_thermostat";
        name = "Laundry Therm";
        heater = "switch.laundry_room_outlet";
        target_sensor = "sensor.laundry_room_weather_temperature";
      }
    ];
    template = [
      {
        sensor = [
          {
            name = "Snow Therm Target";
            unique_id = "snow_therm_target";
            device_class = "temperature";
            # All the targets *should* be Fahrenheit. But I sure which this could just be
            # a template like this:
            # ${sensorMapping}
            # {{ state_attr(mapping[states('input_select.snow_therm_target_select')], 'unit_of_measurement') }}
            # Oh well.
            unit_of_measurement = "°F";
            state = /* jinja */ ''
              ${sensorMapping}
              {{ states(mapping[states('input_select.snow_therm_target_select')]) }}
            '';
          }
        ];
      }
      {
        switch = {
          name = "Garage Door Switch";
          unique_id = "garage_door";
          turn_on = {
            service = "button.press";
            target.entity_id = "button.garage_door_garage_remote";
          };
          turn_off = {
            service = "button.press";
            target.entity_id = "button.garage_door_garage_remote";
          };
          state = "{{ is_state('binary_sensor.garage_door_garage_door', 'on') }}";
          icon = "{{ is_state('binary_sensor.garage_door_garage_door', 'on') | iif(' mdi:garage-open', 'mdi:garage') }}";
        };
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
