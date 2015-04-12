local requests = require('src/requests')

describe("Params", function()
  local _requests = requests._private
  it("has basic functionality", function ()
    local url_output = _requests.format_params("blah.com/dumb.cgi", {action = 'stuff', run = 'true'})
    assert.are.same("blah.com/dumb.cgi?action=stuff&run=true", url_output)

    url_output = _requests.format_params("git.com/git", {great = true, hero = 1, blah = 'no'})
    assert.are.same("git.com/git?great=true&hero=1&blah=no", url_output)

    url_output = _requests.format_params("google.com/help", {action = {1, 2, 3}, No = false})
    assert.are.same("google.com/help?action=1,2,3&No=false", url_output)

    url_output = _requests.format_params("jake.com/work", {action = {'do','some','stuff'}, good = 42, bad = '666'})
    assert.are.same("jake.com/work?good=42&action=do,some,stuff&bad=666", url_output)
  end)

  it("works with edge cases", function()
    local url_output = _requests.format_params("blah.com/dumb.cgi", {})
    assert.are.same("blah.com/dumb.cgi", url_output)

    url_output = _requests.format_params("github.com/bad" , nil)
    assert.are.same("github.com/bad", url_output)
  end)

end)

describe("Headers", function()
  local _requests = requests._private
  it("add's the content length to headers", function()
    local request = {
      data = 'try'
    }

    _requests.create_header(request)

    assert.are.same(3, request.headers['Content-Length'])

    request = {
      data = ''
    }

    _requests.create_header(request)

    assert.are.same(0, request.headers['Content-Length'])
  end)
end)
