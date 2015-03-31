require('busted')

local requests = require('requests')

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
    end)

  end)

end)
