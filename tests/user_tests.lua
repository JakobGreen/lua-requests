local requests = require('src/requests')
local inspect = require('inspect')

describe("All requests test", function()
  describe("GET request", function()
    it("can make basic get requests", function()
      local url = 'http://httpbin.org/get'

      local response = requests.get(url)
      local json_data, err = response.json()

      assert.are.same(200, response.status_code)
      assert.falsy(err)
      assert.are.same(url, json_data.url)
    end)
  end)

  describe("GET request (secure)", function()
    it("can make basic get requests with https", function()
      local url = 'https://httpbin.org/get'

      local response = requests.get(url)
      local json_data, err = response.json()

      assert.are.same(200, response.status_code)
      assert.falsy(err)
      assert.are.same(url, json_data.url)
    end)
  end)

  describe("POST request", function()
    it("can do basic post commands", function ()
      local url = 'http://httpbin.org/post'

      local response = requests.post(url, {data = 'blah'})
      local json_data, err = response.json()

      assert.are.same(200, response.status_code)
      assert.falsy(err)
      assert.are.same('blah', json_data.data)
      assert.are.same('4', json_data.headers['Content-Length'])

      response = requests.post(url, {data = ''})
      json_data, err = response.json()

      assert.are.same(200, response.status_code)
      assert.falsy(err)
      assert.are.same('', json_data.data)
      assert.are.same('0', json_data.headers['Content-Length'])
    end)

    it("can send a json encoded table", function ()
      local url = 'http://httpbin.org/post'
      local data = { stuff = true, otherstuff = false }
      local response = requests.post(url, {data = data})
      local json_data = response.json()

      local json = require('cjson')
      local output_data = json.encode(data)
      assert.are.same(output_data, json_data.data)
    end)
  end)

  describe("DELETE request", function()
    it("can make basic delete requests", function()
      local url = 'http://httpbin.org/delete'

      local response = requests.delete(url, {data = 'delete!'})
      local json_data, err = response.json()

      assert.are.same(200, response.status_code)
      assert.falsy(err)
      assert.are.same('delete!', json_data.data)
    end)
  end)

  describe("PUT request", function()
    it("can make basic put requests", function()
      local url = 'http://httpbin.org/put'

      local response = requests.put(url, {data = 'put'})
      local json_data, err = response.json()

      assert.are.same(200, response.status_code)
      assert.falsy(err)
      assert.are.same('put', json_data.data)
    end)
  end)

  describe("OPTIONS request", function()
    it("can make options requests", function()
      local url = 'http://httpbin.org/get'

      local response = requests.options(url)

      assert.are.same(200, response.status_code)
      assert.are.same('HEAD, OPTIONS, GET', response.headers.allow)
    end)
  end)

  describe("HEAD request", function()
    it("can make head requests", function()
      local url = 'http://httpbin.org/get'

      local response = requests.head(url)

      assert.are.same(200, response.status_code)
      assert.is_true(tonumber(response.headers['content-length']) > 0)
      assert.are.same('', response.text)
    end)
  end)

end)

describe("Authentication", function()

  describe("Digest", function()

    it("should work with GET", function()
      local url = 'http://httpbin.org/digest-auth/auth/user/passwd'
      local response = requests.get(url, {auth=requests.HTTPDigestAuth('user', 'passwd')})

      assert.are.same(200, response.status_code)
      assert.are.same(1, response.auth.nc_count)

      local response_text = response.text
      local nonce = response.auth.nonce

      -- Should be able to reuse the previous authentication
      response = requests.get(url, {auth = response.auth, cookies = response.cookies })

      assert.are.same(200, response.status_code)
      assert.are.same(2, response.auth.nc_count)
      assert.are.same(response.auth.nonce, nonce)
      assert.are.same(response_text, response.text)

      -- Should be able to reuse the previous authentication
      response = requests.get(url, {auth = response.auth, cookies = response.cookies })

      assert.are.same(200, response.status_code)
      assert.are.same(3, response.auth.nc_count)
      assert.are.same(response.auth.nonce, nonce)
      assert.are.same(response_text, response.text)

      -- Without the cookies this should have to reauthenticate
      response = requests.get(url, {auth = response.auth})

      assert.are.same(1, response.auth.nc_count)
      assert.are.same(200, response.status_code)
    end)

  end)

  describe("Basic", function()

    it("should work with GET", function()
      local url = 'http://httpbin.org/basic-auth/user/passwd'
      local response = requests.get(url, {auth=requests.HTTPBasicAuth('user', 'passwd')})
      local json_data, err = response.json()

      assert.are.same(200, response.status_code)
      assert.are.same(true, json_data.authenticated)

      response = requests.get{url=url, auth=requests.HTTPBasicAuth('user', 'passwd')}
      json_data, err = response.json()

      assert.are.same(200, response.status_code)
      assert.are.same(true, json_data.authenticated)
    end)
  end)
end)

describe("XML", function ()

  it("should work with a basic xml", function ()
    local url = 'http://httpbin.org/xml'
    local response = requests.get(url)
    local xml_body = response.xml()

    assert.are.same(200, response.status_code)
    assert.are.same("title", xml_body[1][1].xml)
  end)

  it("should fail with a non-xml response", function ()
    local url = 'http://httpbin.org/get'
    local response = requests.get(url)
    assert.has_errors(function () return response.xml() end)
  end)
end)

describe("Redirects", function()
  it("should work", function()
    local url = 'http://httpbin.org/redirect-to?url=google.com'
    local response = requests.get(url, {allow_redirects = true})
    assert.are.same(200, response.status_code)

    response = requests.get(url, {allow_redirects = false})
    assert.are.same(302, response.status_code)
  end)
end)

describe("Timeout", function()
  it("should work", function()
    local url = 'http://httpbin.org/delay/2'
    assert.has.errors(function () return requests.get(url, {timeout = 1}) end)

    local response = requests.get(url, {timeout = 3})
    assert.are.same(200, response.status_code)
  end)
end)
