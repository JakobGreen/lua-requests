package = "lua-requests"
version = "0.1-0"
source = {
  url = "git://github.com/JakobGreen/lua-requests.git"
}
description = {
  summary = "HTTP requests for Lua!",
  detailed = [[Similar to Requests for python.
    The goal of lua-requests is to make HTTP simple and easy.
    Checkout the wiki on the github page for more details.
  ]],
  homepage = "http://github.com/JakobGreen/lua-requests",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1",
  "lbase64",
  "luasocket >= 3.0rc1-2",
  "md5",
  "inspect"
}
build = {
  type = "builtin",
  modules = {
    requests = "src/requests.lua"
  }
}
