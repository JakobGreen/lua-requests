-- Lua Requests library for http ease

local http_socket = require('socket.http')
local ltn12 = require('ltn12')

--TODO: Remove
local inspect = require('inspect')
local md5sum = require('md5') -- TODO: Make modular?

local requests = {
  _DESCRIPTION = 'Http requests made simpler',
  http_socket = http_socket
}

function requests.format_params(url, params) -- TODO: Clean
  if not params or next(params) == nil then return url end

  for key, value in pairs(params) do
    if tostring(value) then
      url = url..tostring(key)..'='

      if type(value) == 'table' then
        local val_string = ''

        for _, val in ipairs(value) do
          val_string = val_string..tostring(val)..','
        end

        url = url..val_string:sub(0, -2)
      else
        url = url..tostring(value)
      end

      url = url..'&'
    end
  end
  
  return url:sub(0, -2)
end

function requests.check_url(request)
  assert(request.url, 'No url specified for request')
  request.url = requests.format_params(request.url, request.params)
end

function requests.HTTPDigestAuth(user, password)
  return { _type = 'digest', user = user, password = password}
end

function requests.HTTPBasicAuth(user, password)
  return { _type = 'basic', user = user, password = password}
end

local function basic_auth_header(request)
  request.header.Authorization = 'Basic '..request.auth.user..request.auth.password -- TODO: Encode this
end

-- Create digest authorization string for request header TODO: Could be better, but it should work
local function digest_create_header_string(auth)
  local authorization = ''
  authorization = 'Digest username="'..auth.user..'", realm="'..auth.realm..'", nonce="'..auth.nonce
  authorization = authorization..'", uri="'..auth.uri..'", qop='..auth.qop..', nc='..auth.nc
  authorization = authorization..', cnonce="'..auth.cnonce..'", response="'..auth.response..'"'

  if auth.opaque then
    authorization = authorization..', opaque="'..auth.opaque..'"'
  end

  return authorization
end

local function md5_hash(...)
  return md5sum.sumhexa(table.concat({...}, ":"))
end

-- Creates response hash TODO: Add functionality
local function digest_hash_response(auth_table)
  return md5_hash( 
    md5_hash(auth_table.user, auth_table.realm, auth_table.password),
    auth_table.nonce,
    auth_table.nc,
    auth_table.cnonce,
    auth_table.qop,
    md5_hash(auth_table.method, auth_table.uri)
  )
end

-- Add digest authentication to the request header
local function digest_auth_header(request)
  if not request.auth.nonce then return end

  request.auth.cnonce = request.auth.cnonce or string.format("%08x", os.time())

  request.auth.nc_count = request.auth.nc_count or 0
  request.auth.nc_count = request.auth.nc_count + 1

  request.auth.nc = string.format("%08x", request.auth.nc_count)
  request.auth.uri = '/digest-auth/auth/user/passwd'
  request.auth.method = 'GET'
  request.auth.qop = 'auth'

  request.auth.response = digest_hash_response(request.auth)

  request.headers.Authorization = digest_create_header_string(request.auth)
end

-- Call the correct authentication header function
function requests.add_auth_headers(request)
  local auth_func = {
    basic = basic_auth_header,
    digest = digest_auth_header
  }
  
  auth_func[request.auth._type](request)
end

-- Add to the HTTP header
function requests.create_header(request)
  request.headers = request.headers or {}
  request.headers['Content-Length'] = request.data:len()
  
  if request.auth then
    requests.add_auth_headers(request)
  end
end

function requests.parse_digest_response_header(header, method, request)

  for key, value in header['www-authenticate']:gmatch('(%w+)="(%S+)"') do
    request.auth[key] = value
  end

  request.headers.cookie = "fake=fake_value"

  requests.request(method, request)
end

function requests.post(url, ...)
  return requests.request("POST",{url = url, ...})
end

function requests.get(url, ...)
  local thing = ...
  thing.url = url
  return requests.request("GET", thing)
end

g_val = 0

function requests.request(method, request)
  assert(request.url, 'URL not specified')
  requests.check_url(request)
  request.data = request.data or '' -- TODO: Add functionality
  requests.create_header(request)

  local response_body = {}
  local full_request = {
    method = method,
    url = request.url,
    headers = request.headers,
    source = ltn12.source.string(request.data),
    sink = ltn12.sink.table(response_body)
  }

  local response = {}
  local ok

  ok, response.status_code, response.headers, response.status = requests.http_socket.request(full_request)

  if response.status_code == 401 then
    g_val = g_val + 1
    assert(g_val < 2, inspect(response)..inspect(request))
    requests.parse_digest_response_header(response.headers, method, request)
  end

  assert(ok, 'error in POST request: '..response.status_code)
  response.text = table.concat(response_body)
  
  return response
end

return requests
