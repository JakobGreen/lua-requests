-- Lua Requests library for http ease

local http_socket  = require("socket.http")
local https_socket = require("ssl.https")
local url_parser   = require("socket.url")
local ltn12        = require("ltn12")
local json         = require("cjson.safe")
local xml          = require("xml")
local md5sum       = require("md5") -- TODO: Make modular?
local base64       = require("base64")

local requests = {
	_DESCRIPTION = "Http requests made simpler",
	http_socket  = http_socket,
	https_socket = https_socket
}

local _requests = {}

--User facing function the make a request use Digest Authentication
--TODO: Determine what else should live in authentication
function requests.HTTPDigestAuth(user, password)
	return {_type = "digest", user = user, password = password}
end

--User facing function the make a request use Basic Authentication
--TODO: Determine what else should live in authentication
function requests.HTTPBasicAuth(user, password)
	return {_type = "basic", user = user, password = password}
end

--User facing function the make a request use Token Authentication
function requests.HTTPTokenAuth(token)
	return {_type = "token", token = token}
end

--User facing function the make a request use Bearer Authentication
function requests.HTTPBearerAuth(user, password)
	return {_type = "bearer", token = token}
end

function requests.post(url, args)
	return requests.request("POST", url, args)
end

function requests.get(url, args)
	return requests.request("GET", url, args)
end

function requests.delete(url, args)
	return requests.request("DELETE", url, args)
end

function requests.patch(url, args)
	return requests.request("PATCH", url, args)
end

function requests.put(url, args)
	return requests.request("PUT", url, args)
end

function requests.options(url, args)
	return requests.request("OPTIONS", url, args)
end

function requests.head(url, args)
	return requests.request("HEAD", url, args)
end

function requests.trace(url, args)
	return requests.request("TRACE", url, args)
end

--Sets up all the data for a request and makes the request
function requests.request(method, url, args)
	local request

	if type(url) == "table" then
		request = url
		if not request.url and request[1] then
			request.url = table.remove(request, 1)
		end
	else
		request = args or {}
		request.url = url
	end

	request.method = method
	_requests.parse_args(request)

	-- TODO: Find a better way to do this
	if request.auth and request.auth._type == "digest" then
		local response = _requests.make_request(request)
		return _requests.use_digest(response, request)
	else
		return _requests.make_request(request)
	end
end

--Makes a request
function _requests.make_request(request)
	local response_body = {}

	local source = ""
	if request.data ~= "" then
		source = request.data
	elseif request.json ~= "" then
		source = request.json
	elseif request.form ~= "" then
		source = request.form
	end

	local full_request = {
		method   = request.method,
		url      = request.url,
		headers  = request.headers,
		source   = ltn12.source.string(source),
		sink     = ltn12.sink.table(response_body),
		redirect = request.allow_redirects,
		proxy    = request.proxy
	}

	local response = {}
	local ok
	local socket = string.find(full_request.url, "^https:") and not request.proxy and https_socket or http_socket

	ok, response.status_code, response.headers, response.status = socket.request(full_request)

	assert(ok, "error in " .. request.method .. " request: " .. response.status_code)
	response.text = table.concat(response_body)
	response.json = function()
		return json.decode(response.text)
	end
	response.xml = function()
		return xml.load(response.text)
	end

	return response
end

--Parses through all the possible arguments for a request
function _requests.parse_args(request)
	_requests.check_url(request)
	_requests.check_data(request)
	_requests.check_json(request)
	_requests.check_form(request)
	_requests.create_header(request)
	_requests.check_timeout(request.timeout)
	_requests.check_redirect(request.allow_redirects)
end

--Format the the url based on the params argument
function _requests.format_params(url, params) -- TODO: Clean
	if not params or next(params) == nil then
		return url
	end

	url = url .. "?"
	for key, value in pairs(params) do
		if tostring(value) then
			url = url .. tostring(key) .. "="

			if type(value) == "table" then
				local val_string = ""

				for _, val in ipairs(value) do
					val_string = val_string .. tostring(val) .. ","
				end

				url = url .. val_string:sub(0, -2)
			else
				url = url .. tostring(value)
			end

			url = url .. "&"
		end
	end

	return url:sub(0, -2)
end

--Check that there is a URL given and append to it if params are passed in.
function _requests.check_url(request)
	assert(request.url, "No url specified for request")
	request.url = _requests.format_params(request.url, request.params)
end

-- Add to the HTTP header
function _requests.create_header(request)
	request.headers = request.headers or {}

	if request.data ~= "" then
		request.headers["Content-Length"] = request.data:len()
		request.headers["Content-Type"]   = "application/x-www-form-urlencoded"
	elseif request.json ~= "" then
		request.headers["Content-Length"] = request.json:len()
		request.headers["Content-Type"]   = "application/json"
	elseif request.form ~= "" then
		request.headers["Content-Length"] = request.form:len()
		request.headers["Content-Type"]   = _requests.format("multipart/form-data; boundary=%s", request.boundary)
	end

	if request.cookies then
		if request.headers.cookie then
			request.headers.cookie = request.headers.cookie .. "; " .. request.cookies
		else
			request.headers.cookie = request.cookies
		end
	end

	if request.auth then
		_requests.add_auth_headers(request)
	end
end

function _requests.check_json(request)
	request.json = request.json or ""
	if (
		type(request.json) == "table"
		and (not request.data or request.data == "")
		and (not request.form or request.form == "")
	) then
		request.json = json.encode(request.json)
	end
end

function _requests.check_form(request)
	request.form = request.form or ""
	if (
		type(request.form) == "table"
		and (not request.data or request.data == "")
		and (not request.json or request.json == "")
	) then
		request.form, request.boundary = _requests.encode_form_data(request.form)
	end
end

--Makes sure that the data is in a format that can be sent
function _requests.check_data(request)
	local data = ""
	request.data = request.data or ""

	if (
		type(request.data) == "table"
		and (not request.json or request.json == "")
		and (not request.form or request.form == "")
	) then
		for key, value in pairs(request.data) do
			if data ~= "" then
				data = data .. "&"
			end
			data = data .. string.format("%s=%s", key, value)
		end
		if data ~= "" then
			request.data = data
		end
	end
end

--Set the timeout
function _requests.check_timeout(timeout)
	http_socket.TIMEOUT  = timeout or 5
	https_socket.TIMEOUT = timeout or 5
end

--Checks is allow_redirects parameter is set correctly
function _requests.check_redirect(allow_redirects)
	if allow_redirects and type(allow_redirects) ~= "boolean" then
		error("allow_redirects expects a boolean value. received type = " .. type(allow_redirects))
	end
end

--Create the Authorization header for Basic Auth
function _requests.basic_auth_header(request)
	local encoded = base64.encode(request.auth.user .. ":" .. request.auth.password)
	request.headers.Authorization = "Basic " .. encoded
end

--Create the Authorization header for Bearer Auth
function _requests.bearer_auth_header(request)
	request.headers.Authorization = "Bearer " .. request.auth.token
end

--Create the Authorization header for Token Auth
function _requests.token_auth_header(request)
	request.headers.Authorization = "Token " .. request.auth.token
end

-- Create digest authorization string for request header TODO: Could be better, but it should work
function _requests.digest_create_header_string(auth)
	local authorization = ""
	authorization = 'Digest username="' .. auth.user .. '", realm="' .. auth.realm .. '", nonce="' .. auth.nonce
	 			.. '", uri="' .. auth.uri .. '", qop=' .. auth.qop .. ", nc=" .. auth.nc
				.. ', cnonce="' .. auth.cnonce .. '", response="' .. auth.response .. '"'

	if auth.opaque then
		authorization = authorization .. ', opaque="' .. auth.opaque .. '"'
	end

	return authorization
end

--MD5 hash all parameters
local function md5_hash(...)
	return md5sum.sumhexa(table.concat({...}, ":"))
end

-- Creates response hash TODO: Add functionality
function _requests.digest_hash_response(auth_table)
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
function _requests.digest_auth_header(request)
	if not request.auth.nonce then
		return
	end

	request.auth.cnonce = request.auth.cnonce or string.format("%08x", os.time())

	request.auth.nc_count = request.auth.nc_count or 0
	request.auth.nc_count = request.auth.nc_count + 1

	request.auth.nc = string.format("%08x", request.auth.nc_count)

	local url           = url_parser.parse(request.url)
	request.auth.uri    = url_parser.build {path = url.path, query = url.query}
	request.auth.method = request.method
	request.auth.qop    = "auth"

	request.auth.response = _requests.digest_hash_response(request.auth)

	request.headers.Authorization = _requests.digest_create_header_string(request.auth)
end

--Checks the resonse code and adds additional headers for Digest Auth
-- TODO: Rename this
function _requests.use_digest(response, request)
	if response.status_code == 401 then
		_requests.parse_digest_response_header(response, request)
		_requests.create_header(request)

		response         = _requests.make_request(request)
		response.auth    = request.auth
		response.cookies = request.headers.cookie
		return response
	else
		response.auth    = request.auth
		response.cookies = request.headers.cookie
		return response
	end
end

--Parse the first response from the host to make the Authorization header
function _requests.parse_digest_response_header(response, request)
	for key, value in response.headers["www-authenticate"]:gmatch('(%w+)="(%S+)"') do
		request.auth[key] = value
	end

	if request.headers.cookie then
		request.headers.cookie = request.headers.cookie .. "; " .. response.headers["set-cookie"]
	else
		request.headers.cookie = response.headers["set-cookie"]
	end

	request.auth.nc_count = 0
end

-- Call the correct authentication header function
function _requests.add_auth_headers(request)
	local auth_func = {
		basic  = _requests.basic_auth_header,
		digest = _requests.digest_auth_header,
		token  = _requests.token_auth_header,
		bearer = _requests.bearer_auth_header,
	}

	auth_func[request.auth._type](request)
end

function _requests.format(p, ...)
    if select('#', ...) == 0 then
        return p
	else
		return string.format(p, ...)
	end
end

function _requests.tprintf(t, p, ...)
    t[#t+1] = _requests.format(p, ...)
end

function _requests.append_data(r, k, data, extra)
	_requests.tprintf(r, "content-disposition: form-data; name=\"%s\"", k)

    if extra.filename then
        _requests.tprintf(r, "; filename=\"%s\"", extra.filename)
	end

    if extra.content_type then
        _requests.tprintf(r, "\r\ncontent-type: %s", extra.content_type)
	end

    if extra.content_transfer_encoding then
        _requests.tprintf(
            r, "\r\ncontent-transfer-encoding: %s",
            extra.content_transfer_encoding
        )
	end

    _requests.tprintf(r, "\r\n\r\n")
    _requests.tprintf(r, data)
    _requests.tprintf(r, "\r\n")
end

function _requests.gen_boundary()
	local t = {"BOUNDARY-"}
	for i = 2, 17 do
		t[i] = string.char(math.random(65, 90))
	end
	t[18] = "-BOUNDARY"
	return table.concat(t)
end

function _requests.encode_form_data(t, boundary)
    boundary = boundary or _requests.gen_boundary()
    local r  = {}
    local _t
    for k,v in pairs(t) do
        _requests.tprintf(r, "--%s\r\n", boundary)
        _t = type(v)
        if _t == "string" then
            _requests.append_data(r, k, v, {})
        elseif _t == "table" then
            assert(v.data, "invalid input, expected data field")
            local extra = {
                filename                  = v.filename or v.name,
                content_type              = v.content_type or v.mimetype or "application/octet-stream",
                content_transfer_encoding = v.content_transfer_encoding or "binary",
            }
			_requests.append_data(r, k, v.data, extra)

        else error(string.format("unexpected type %s", _t)) end
    end
    _requests.tprintf(r, "--%s--\r\n", boundary)
    return table.concat(r), boundary
end

--Return public functions
requests._private = _requests
return requests
