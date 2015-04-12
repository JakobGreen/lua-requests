local requests = require('src/requests')

describe("Digest authentication", function()
  local _requests = requests._private
  
  -- TODO: Add all functionality to this? 
  it("Should initialize table with data", function()
    local auth = requests.HTTPDigestAuth('jake', 'green')
    local test_auth = {
      _type = 'digest',
      user = 'jake',
      password = 'green',
    }

    assert.are.same(test_auth, auth)

    auth = requests.HTTPDigestAuth('blah')
    test_auth.user = 'blah'
    test_auth.password = nil

    assert.are.same(test_auth, auth)

    auth = requests.HTTPDigestAuth()
    test_auth.user = nil
    test_auth.password = nil

    assert.are.same(test_auth, auth)
  end)

  it("Can make the correct header", function()
    local auth_table = {
      user = 'user',
      password = 'pass',
      realm = 'user@domain.com',
      nonce = '123412341234',
      uri = '/blah/blah/',
      qop = 'auth',
      nc = '00000001',
      cnonce = '654321',
      response = '1234567890',
      opaque = '0987654321',
    }

    local auth = _requests.digest_create_header_string(auth_table)

    local test_auth = 'Digest username="user", realm="user@domain.com", ' ..
      'nonce="123412341234", uri="/blah/blah/", qop=auth, nc=00000001, cnonce="654321", '..
      'response="1234567890", opaque="0987654321"'

    assert.are.same(test_auth, auth)

    auth_table = {
      user = 'user',
      password = 'pass',
      realm = 'user@domain.com',
      nonce = '123412341234',
      uri = '/blah/blah/',
      qop = 'auth',
      nc = '00000001',
      cnonce = '654321',
      response = '1234567890'
    }

    auth = _requests.digest_create_header_string(auth_table)

    test_auth = 'Digest username="user", realm="user@domain.com", ' ..
      'nonce="123412341234", uri="/blah/blah/", qop=auth, nc=00000001, cnonce="654321", '..
      'response="1234567890"'

    assert.are.same(test_auth, auth)
  end)
end)

