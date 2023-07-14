-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")

---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
---------------------------------------------------------------------------------------------

local Redis = require "kong.plugins.neo_auth.redis"
local decrypt = require "kong.plugins.neo_auth.decrypt"
local jwt_decoder = require "kong.plugins.neo_auth.jwt"
local socket = require "socket"

local plugin = {
  PRIORITY = 1000, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1", -- version in X.Y.Z format. Check hybrid-mode compatibility requirements.
}

local REDIS_PREFIX_SESSION_KEY = 'auth:session:user:'
-- do initialization here, any module level code runs in the 'init_by_lua_block',
-- before worker processes are forked. So anything you add here will run once,
-- but be available in all workers.

-- handles more initialization, but AFTER the worker process has been forked/created.
-- It runs in the 'init_worker_by_lua_block'



function plugin:init_worker()
  -- your custom code here
  kong.log.debug("saying hi from the 'init_worker' handler")
end --]]

local function get_access_token(user_id, secret_key)
  local payload = {
    user = {
      id = user_id
    }
  }

  -- encode
  local alg = "HS256" -- (default)
  local token, err = jwt_decoder.encode(payload, secret_key, alg)
  return token, err
end

-- Lưu tạm cache trong 30s của accesstoken
local function get_access_token_cached(user_id, secret_key)
  local _key = "jwt:user:" .. user_id .. ":" .. secret_key
  local res, err = kong.cache:get(_key, { ttl = 30000 }, get_access_token, user_id, secret_key)
  return res, err
end


local function check_session_key(user_id, auth_token)
  local redis_key = REDIS_PREFIX_SESSION_KEY .. ":" .. user_id .. ":" .. auth_token
end


local function get_secret_from_client_id(conf, user_id, client_id)
  local redis_secret_key = "session:auth:session_v2_secret:" .. user_id .. ":" .. client_id

  local data = Redis:fetch(conf.redis, redis_secret_key);
  if not data then
    return nil
  end

  return data['secret']
end

local function verify_access_token(conf, user_id, client_id, access_token)
  local claims_to_verify = {
    iss = "backend",
    aud = conf.app_fingerprint
  }
  local secret = get_secret_from_client_id(conf, user_id, client_id)

  if not secret then
    return false
  end
  local jwt, err = jwt_decoder:new(access_token)

  if err then
    return false
  end

  for claim_name, claim_value in pairs(claims_to_verify) do
    if claim_value ~= jwt.claims[claim_name] then
      return false
    end
  end
  return jwt:verify_signature(secret)
end

-- runs in the 'access_by_lua_block'
function plugin:access(conf)
  local start_time = socket.gettime()

  
  local token = kong.request.get_header("Authorization")
  local client_id = kong.request.get_header("Clientid")
  if not token then
    kong.response.exit(401, { message = "Missing Token;" })
  end

  local jwt, err = jwt_decoder:new(token)
  if jwt then
    local user_id = decrypt(jwt.claims.userId, conf.session_secret, true, true)
    kong.service.request.set_header('user_id', user_id)
    if user_id then
      local valid = verify_access_token(conf, user_id, client_id, token)
      kong.service.request.set_header('valid', valid)
      if valid then
        local new_token = get_access_token_cached(user_id, conf.proxy_secret)
        kong.service.request.set_header('accessToken', new_token)
      end
    end
  end

  local duration = socket.gettime() - start_time
  kong.service.request.set_header('duration', duration)
end --]]

return plugin
