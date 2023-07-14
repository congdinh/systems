local typedefs = require "kong.db.schema.typedefs"


local PLUGIN_NAME = "neo_auth"


local schema = {
  name = PLUGIN_NAME,
  fields = {
    -- the 'fields' array is the top-level entry with fields defined by Kong
    { consumer = typedefs.no_consumer }, -- this plugin cannot be configured on a consumer (typical for auth plugins)
    { protocols = typedefs.protocols_http },
    {
      config = {
        -- The 'config' record is the custom part of the plugin schema
        type = "record",
        fields = {
          {
            redis = {
              type = "record",
              fields = {
                {
                  host = typedefs.host {
                    default = "redis",
                    required = true,
                  },
                },
                {
                  port = {
                    type = "number",
                    default = 6379,
                    required = true,
                    between = { 0, 65534 },
                  },
                },
                { db = { type = "number", default = 0 } },
                { timeout = { type = "number", required = true, default = 1000 } },
                { password = { type = "string", required = false } }
              },
            },
          },
          { session_secret = { type = "string", required = true, default = 'session_secret' } },
          { app_fingerprint = { type = "string", required = true, default = 'app_fingerprint' } },
          { proxy_secret = { type = "string", required = true, default = 'proxy_secret' } },
        }
      },
    },
  },
}

return schema
