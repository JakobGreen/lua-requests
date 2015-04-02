local requests = require('src/requests')

describe("User level testing", function()
  describe("GET request", function()
    
  end)

  describe("POST request", function()

  end)

  describe("Digest authentication", function()
    
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
