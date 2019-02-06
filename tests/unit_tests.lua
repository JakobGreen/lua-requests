local requests = require('src/requests')
local say = require("say")

local function is_any(state, arguments)
  if not type(arguments[1]) == "table" or #arguments ~= 2 then
    return false
  end

  for _, value in pairs(arguments[1]) do
    if value == arguments[2] then
      return true
    end
  end

  return false
end

say:set("assertion.is_any.positive", "Expected table %s \n to have: %s")
say:set("assertion.is_any.negative", "Expected table %s \n not to have: %s")
assert:register("assertion", "is_any", is_any, "assertion.is_any.positive", "assertion.is_any.negative")

describe("Params", function()
  local _requests = requests._private
  it("has basic functionality", function ()
    -- These tests can be screwy depending on the version of lua. LuaJit2.1 likes to order tables differently.
    local url_output = _requests.format_params("blah.com/dumb.cgi", {action = 'stuff', run = 'true'})
    local possible = {"blah.com/dumb.cgi?action=stuff&run=true", "blah.com/dumb.cgi?run=true&action=stuff"}
    assert.is_any(possible, url_output)

    url_output = _requests.format_params("git.com/git", {great = true, hero = 1, blah = 'no'})
    possible = {"git.com/git?great=true&hero=1&blah=no","git.com/git?blah=no&hero=1&great=true"}
    assert.is_any(possible, url_output)

    url_output = _requests.format_params("google.com/help", {action = {1, 2, 3}, No = false})
    possible = {"google.com/help?action=1,2,3&No=false", "google.com/help?No=false&action=1,2,3"}
    assert.is_any(possible, url_output)

    url_output = _requests.format_params("jake.com/work", {action = {'do','some','stuff'}, good = 42, bad = '666'})
    possible = {"jake.com/work?good=42&action=do,some,stuff&bad=666", "jake.com/work?bad=666&good=42&action=do,some,stuff"}
    assert.is_any(possible, url_output)
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
