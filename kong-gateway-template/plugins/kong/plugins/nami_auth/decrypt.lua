local cipher = require "resty.openssl.cipher"
local hmac = require "resty.openssl.hmac"
local digest = require "resty.openssl.digest"
local to_hex = require("resty.string").to_hex
local cjson = require "cjson.safe"

function string.fromhex(str)
  return (str:gsub('..', function (cc)
      return string.char(tonumber(cc, 16))
  end))
end


local function decrypt(cipherText, secret, verifyHmac, debug)
  if not cipherText then
    return nil
  end
  local function logError(message)
    if debug then
      ngx.log(ngx.ERR, message)
    end
  end

  local cryptoKey = digest.new('sha256'):final(secret)
  local expectedHmac, iv, encrypted

  if verifyHmac then
    -- Extract the HMAC from the start of the message:
    expectedHmac = string.sub(cipherText, 1, 64)
    -- The remaining message is the IV + encrypted message:
    cipherText = string.sub(cipherText, 65)
    -- Calculate the actual HMAC of the message:
    local actualHmac = to_hex(hmac.new(cryptoKey, 'sha256'):final(cipherText))
    if expectedHmac ~= actualHmac then
      return nil
    end
  end

  
  -- Extract the IV from the beginning of the message:
  iv = string.sub(cipherText, 1, 32):fromhex()
  -- The remaining text is the encrypted JSON:
  encrypted = string.sub(cipherText, 33)

  local cip, err = cipher.new('aes-256-cbc')
  if err then
    return nil
  end

  local decrypted, err = cip:decrypt(cryptoKey, iv, ngx.decode_base64(encrypted), false)
  
  if not decrypted then
    logError("Failed to decrypt : " .. err)
    return nil
  end

  local value = cjson.decode(decrypted)

  return value or decrypted
end

return decrypt
