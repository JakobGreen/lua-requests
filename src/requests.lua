-- Lua Requests library for http ease

local http_socket = require('socket.http')
local url_parser = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')

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
function digest_create_header_string(auth)
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

  local url = url_parser.parse(request.url)
  request.auth.uri = url_parser.build{path = url.path, query = url.query}
  request.auth.method = request.method
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

  if request.cookies then
    if request.headers.cookie then
      request.headers.cookie = request.headers.cookie..'; '..request.cookies
    else
      request.headers.cookie = request.cookies
    end
  end
  
  if request.auth then
    requests.add_auth_headers(request)
  end
end

-- TODO: Rename this
function use_digest(response, request)
  if response.status_code == 401 then
    parse_digest_response_header(response,request)
    requests.create_header(request)
    response = make_request(request)
    response.auth = request.auth
    response.cookies = request.headers.cookie
    return response
  else
    response.auth = request.auth
    response.cookies = request.headers.cookie
    return response 
  end
end

function parse_digest_response_header(response, request)

  for key, value in response.headers['www-authenticate']:gmatch('(%w+)="(%S+)"') do
    request.auth[key] = value
  end

  if request.headers.cookie then
    request.headers.cookie = request.headers.cookie..'; '..response.headers['set-cookie']
  else
    request.headers.cookie = response.headers['set-cookie']
  end

  request.auth.nc_count = 0
end

function requests.post(url, ...)
  return requests.request("POST", url, ...)
end

function requests.get(url, ...)
  return requests.request("GET", url, ...)
end

function requests.delete(url, ...)
  return requests.request("DELETE", url, ...)
end

function requests.patch(url, ...)
  return requests.request("PATCH", url, ...)
end

function requests.put(url, ...)
  return requests.request("PUT", url, ...)
end

function requests.options(url, ...)
  return requests.request("OPTIONS", url, ...)
end

function requests.head(url, ...)
  return requests.request("HEAD", url, ...)
end

function requests.trace(url, ...)
  return requests.request("TRACE", url, ...)
end

function requests.path(url, ...)
  return requests.request("PATCH", url, ...)
end

function requests.request(method, url, ...)
  local request = ... or {}
  request.url = url
  assert(request.url, 'URL not specified')
  request.method = method
  requests.check_url(request)
  request.data = request.data or '' -- TODO: Add functionality
  requests.create_header(request)

  -- TODO: Find a better way to do this
  if request.auth and request.auth._type == 'digest' then
    local response = make_request(request)
    return use_digest(response, request)
  else
    return make_request(request)
  end
end

function make_request(request)
  local response_body = {}
  local full_request = {
    method = request.method,
    url = request.url,
    headers = request.headers,
    source = ltn12.source.string(request.data),
    sink = ltn12.sink.table(response_body)
  }

  local response = {}
  local ok

  ok, response.status_code, response.headers, response.status = requests.http_socket.request(full_request)

  assert(ok, 'error in '..request.method..' request: '..response.status_code)
  response.text = table.concat(response_body)
  response.json = function () return json.decode(response.text) end
  
  return response
end

return requests
