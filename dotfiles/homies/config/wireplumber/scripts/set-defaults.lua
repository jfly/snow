-- Created by copying /usr/share/wireplumber/scripts/policy-endpoint-device.lua
-- and iterating.

default_nodes = Plugin.find("default-nodes-api")
endpoints_om = ObjectManager { Interest { type = "SiEndpoint" }}
linkables_om = ObjectManager {
  Interest {
    type = "SiLinkable",
    -- only handle device si-audio-adapter items
    Constraint { "item.factory.name", "=", "si-audio-adapter", type = "pw-global" },
    Constraint { "item.node.type", "=", "device", type = "pw-global" },
    Constraint { "active-features", "!", 0, type = "gobject" },
  }
}

function setDefaults ()
  description_priority = { "wireless headphones", "desk speakers", "desk mic", "laptop speakers", "laptop mic" }

  linkable_by_description = {}
  for si in linkables_om:iterate() do
    local si_props = si.properties
    if si_props then
        local description = si_props["node.description"]
        linkable_by_description[description] = si
    end
  end

  local si
  for i, description in pairs(description_priority) do
      si = linkable_by_description[description]
      if si then
          break
      end
  end

  if not si then
      Log.warning("Could not find any of the preferred devices")
  else
      local si_props = si.properties

      default_nodes:call("set-default-configured-node-name", si_props["media.class"], si_props["node.name"])
  end
end

linkables_om:connect("objects-changed", function (om)
    setDefaults ()
end)

endpoints_om:connect("object-added", function (om)
    setDefaults ()
end)

linkables_om:connect("object-removed", function (om, si)
    setDefaults ()
end)

endpoints_om:activate()
linkables_om:activate()
