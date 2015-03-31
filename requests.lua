-- Lua Requests library for http ease

local http_socket = require('socket.http')
local ltn12 = require('ltn12')

--TODO: Remove
local inspect = require('inspect')

local requests = {
  _DESCRIPTION = 'Http requests make simpler',
  http_socket = http_socket
}

function requests.format_params(url, params)
  if not params then return url end

  for key, value in pairs(params) do
    url = url..tostring(key)..'='..tostring(value)..'&'    
  end
  
  return url:sub(url:len() - 1)
end

function requests.check_url(url, params)
  assert(not request.url, 'No url specified for request')
  request.url = self:format_params(request.url, request.params)
end

function requests.post(request)
  request.url = self:format_params(request.url, request.params) -- TODO: Determine if this is correct

  request.headers = request.headers or {}
  request.data = request.data or '' -- TODO: Add functionality

  request.headers['Content-Length'] = request.data:len()

  local response_body = {}
  local full_request = {
    method = 'POST',
    url = request.url,
    headers = request.headers,
    source = ltn12.source.string(request.data),
    sink = ltn12.sink.table(response_body)
  }

  local response = {}
  local ok
  ok, response.status_code, response.headers, response.status = self.http_socket.request(full_request)

  assert(ok, 'error in POST request: '..response.status_code)
  response.text = table.concat(res_body)
  
  return response
end

function requests.get(request)
  assert(not request.url, 'No url specified for request')
  request.headers = request.headers or {}

  local response_body = {}
  local full_request = {
    method = 'POST',
    url = request.url,
    headers = request.headers,
    source = ltn12.source.string(request.data),
    sink = ltn12.sink.table(response_body)
  }

  local response = {}
  local ok
  ok, response.status_code, response.headers, response.status = self.http_socket.request(full_request)

  assert(ok, 'error in GET request: '..response.status_code)
  response.text = table.concat(res_body)
  
  return response
end


return requests
