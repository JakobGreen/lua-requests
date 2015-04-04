local requests = require('src/requests')
local inspect = require('inspect')

describe("All requests test", function()
  describe("GET request", function()
    it("can make basic get requests", function()
      local url = 'http://httpbin.org/get'

      local response = requests.get(url)
      local json_data, _, err = response.json()
      
      assert.are.same(200, response.status_code)
      assert.falsy(err)
      assert.are.same(url, json_data.url)
    end)
  end)

  describe("POST request", function()
      local url = 'http://httpbin.org/post'

      local response = requests.post(url, {data = 'blah'})
      local json_data, _, err = response.json()

      assert.are.same(200, response.status_code)
      assert.falsy(err)
      assert.are.same('blah', json_data.data)
      assert.are.same('4', json_data.headers['Content-Length'])

      response = requests.post(url, {data = ''})
      json_data, _, err = response.json()

      assert.are.same(200, response.status_code)
      assert.falsy(err)
      assert.are.same('', json_data.data)
      assert.are.same('0', json_data.headers['Content-Length'])
  end)

  describe("DELETE request", function()
    it("can make basic delete requests", function()
      local url = 'http://httpbin.org/delete'

      local response = requests.delete(url, {data = 'delete!'})
      local json_data, _, err = response.json()

      assert.are.same(200, response.status_code)
      assert.falsy(err)
      assert.are.same('delete!', json_data.data)
    end)
  end)

  describe("PUT request", function()
    it("can make basic put requests", function()
      local url = 'http://httpbin.org/put'

      local response = requests.put(url, {data = 'put'})
      local json_data, _, err = response.json()

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

  describe("TRACE request", function()
    it("can make trace requests", function()
      local url = 'http://httpbin.org/get'

      local response = requests.trace(url)

      print(inspect(response.headers))
      print(response.text)

      assert.are.same(200, response.status_code)
    end)
  end)

end)

describe("Authentication", function()

  describe("Digest", function()

    it("should work with POST", function()

    end)

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
end)
