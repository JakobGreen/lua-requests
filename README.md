# lua-requests

[![License](http://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE.md)
[![Coverage Status](https://coveralls.io/repos/github/JakobGreen/lua-requests/badge.svg?branch=master)](https://coveralls.io/github/JakobGreen/lua-requests?branch=master)
[![Build Status](https://travis-ci.org/JakobGreen/lua-requests.svg?branch=master)](https://travis-ci.org/JakobGreen/lua-requests)

The same friendly Python Requests interface for Lua!

## Basic Usage

	> requests = require('requests')
	> response = requests.get('http://httpbin.org/get')
	> print(response.status_code)
	200
	>
	> response = requests.post{'http://httpbin.org/post', data='random data'}
	> json_data = response.json()
	> print(json_data.data)
	random data

## Contents

[API](#api)
+ [Simple requests](#simple-requests)
+ [HTTPS](#https)
+ [Basic Response](#basic-response)
+ [URL parameters](#url-parameters)
+ [Sending Data](#sending-data)
+ [Custom headers](#custom-headers)
+ [Timeout](#timeout)
+ [Basic Authentication](#basic-authentication)
+ [Digest Authentication](#digest-authentication)
+ [Cookies](#cookies)
+ [JSON Response](#json-response)
+ [XML Response](#xml-response)
+ [Proxy](#proxy)
+ [Redirects](#redirects)

[Dependencies](#dependencies)

[Tests](#tests)

[License](#licensing)

## Dependencies

- [LuaSocket](http://w3.impa.br/~diego/software/luasocket/ "LuaSocket homepage")
- [LuaSec](https://github.com/brunoos/luasec "LuaSec github")
- [md5](https://github.com/kikito/md5.lua "md5 github")
- [lbase64](https://github.com/LuaDist/lbase64 "lbase64 github")
- [lua-cjson](http://www.kyne.com.au/~mark/software/lua-cjson.php)
- [xml](https://lubyk.github.io/lubyk/xml.html)

The HTTP backend can be swapped out for anything that has the same API as LuaSocket's `socket.http`. This is done by setting the value of `requests.http_socket`. Swapping the HTTPS backend can be done by swapping out `requests.https_socket`.

## Tests

Tests are located in the tests directory and are written using [busted](http://olivinelabs.com/busted/ "Busted home page").

Install `busted`:

	$ luarocks install busted

Run Tests:

	$ busted -p _tests tests

## Licensing

`lua-requests` is licensed under the MIT license. See LICENSE.md for details on the MIT license.


## API

### Simple requests

Importing the lua-requests is quite simple.

    > requests = require('requests')

Making a GET request is not much more difficult.

    > response = requests.get('http://httpbin.org/get')

Other methods like POST, HEAD, OPTIONS, TRACE, PATCH, PUT, and DELETE are just as simple.

    > response = requests.post('http://httpbin.org/post')
    > response = requests.put('http://httpbin.org/put')
    etc...

The second argument of a request is a table that can be used to make more advanced requests.
Any request can be made with either a second argument or as a table.

    > response = requests.post{url = 'http://httpbin.org/post', data = 'random data'}

or

    > response = requests.post{'http://httpbin.org/post', data = 'random data'}

or

    > response = requests.post('http://httpbin.org/post', {data = 'random data'})


NOTE: This documentation mostly uses two parameters instead of just one table because the single table feature was added later.

There is also a general request call. The first parameter is the method.

    > response = requests.request("GET", 'http://httpbin.org/get')
    
### HTTPS

Using HTTPS is as simple as changing the URL to be 'https' instead of 'http'

    > response = requests.get('https://httpbing.org/get')

### Basic Response

The http response contains all of the response data in different fields.

The response body is contained in `response.text`

    > response = response.get('http://httpbin.org/robots.txt')
    > print(response.text)
    User-agent: *
    Disallow: /deny

The response headers are contained in `response.headers`

    > response = requests.get('http://httpbin.org/robots.txt')
    > print(inspect(response.headers))
    {
      ["access-control-allow-credentials"] = "true",
      ["access-control-allow-origin"] = "*",
      connection = "close",
      ["content-length"] = "30",
      ["content-type"] = "text/plain",
      date = "Tue, 07 Apr 2015 01:43:26 GMT",
      server = "nginx"
    }

The response status code is contained in `response.status_code`

    > response = requests.get('http://httpbin.org/robot.txt')
    > print(response.status_code)
    200

### URL Parameters

It is common for URL's that need to have some sort of query string. 
For example, `http://httpbin.org/response-headers?key1=val1&key2=val2`. 
Adding parameters to a URL query is as simple as passing a table into the params field of the second argument.

	> query_parameters = { key1 = 'val1', key2 = 'val2' }
	> response = requests.get{'http://httpbin.org/response-headers', params = query_parameters}
	> print(response.url)
	http://httpbin.org/response-headers?key1=val1&key2=val2

For keys that contain a list of values just make the value into a table.

	> query_parameters = { key1 = 'val2', key2 = {'val2', 'val3'}}
	> response = requests.get{'http://httpbin.org/response-headers', params = query_parameters}
	> print(response.url)
	http://httpbin.org/response-headers?key1=val1&key2=val2,val3

### Sending Data

Sending data is possible with any command. Just pass the data you want to send into the data field of the second argument.

	> data = "Example data"
	> response = requests.post{'http://httpbin.org/post', data = data}

If a table is passed in to data it is automatically encoded as JSON.

	> data = {Data = "JSON"}
	> response = requests.post{'http://httpbin.org/post', data = data}

### Custom headers

Custom headers can be added to any request method. Just pass a table into the headers field of the second argument.

	> headers = {['Content-Type'] = 'application/json'}
	> response = requests.get{'http://httpbin.org/headers', headers = headers}

### Timeout

Timeout in seconds can be passed as a parameter. If the host has not responded in timeout seconds then through an error.

	> url = 'http://httpbin.org/delay/2'
	> response = requests.get{url, timeout = 1}
	requests.lua:261: error in GET request: timeout

### Basic Authentication

Basic authentication can be added to any request.

	> auth = requests.HTTPBasicAuth('user', 'passwd')
	> response = requests.get{'http://httpbin.org/basic-auth/user/passwd', auth = auth}
	> print(response.status_code)
	200 

### Digest Authentication

Digest authentication can be added to any request.

	> auth = requests.HTTPDigestAuth('user', 'passwd')
	> response = requests.get{'http://httpbin.org/digest-auth/auth/user/passwd', auth = auth}
	> print(response.status_code)
	200 

To continue using the same digest authentication just pass `response.auth` into the next request.

	> response = requests.get{'http://httpbin.org/digest-auth/auth/user/passwd', auth = response.auth}
	> print(response.status_code)
	200

By reusing the `response.auth` you can save time by not needing to reauthenticate again.
`response.cookies` contains cookies that the server requested to be set for authentication.

### Cookies

Cookies can be added to any request by setting the `cookies` field.

	> response = requests.get{'http://httpbin.org/get', cookies = 'cookie!'}

### JSON Response

JSON response's can be parsed into a Lua table using `response.json()`. 
JSON encoding and decoding is done with `lua-cjson`. 

	> response = requests.get{'http://httpbin.org/get', params =  {stuff=true}}
	> json_body, error = response.json()
	> print(json_body.args.stuff)
	true	

### XML Response

XML response's can be parsed into a Lua table using `response.xml()`.
XML encoding and decoding is done with `xml` which is based on RapidXML.

	> response = requests.get('http://httpbin.org/xml')
	> xml_body, error = response.xml()
	> print(xml_body[1][1][1])
	Wake up to WonderWidgets!

The returned xml table can be tricky to parse. 
I recommend using `inspect` to help the first time to help see the table structure.

### Proxy

A proxy server can be added as an argument to a request.

	> response = requests.get{'http://httpbin.org/get', proxy = '8.8.8.8:9001'}

### Redirects

301 and 302 redirects are enabled by default for most requests. To disable redirects set `allow_redirects = false`.

	> response = requests.get('http://httpbin.org/redirect-to?url=google.com', {allow_redirects = false})

