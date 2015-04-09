lua-requests
====

The same friendly python Requests interface for Lua!

API documentation is on the [wiki](http://github.com/JakobGreen/lua-requests/wiki) page.


Dependencies
====

- [luasocket](http://w3.impa.br/~diego/software/luasocket/ "LuaSocket homepage")
- [md5](https://github.com/kikito/md5.lua "md5 github")
- [lbase64](https://github.com/LuaDist/lbase64 "lbase64 github")
- [lua-cjson](http://www.kyne.com.au/~mark/software/lua-cjson.php)
- [xml](http://doc.lubyk.org/xml.html)

Tests
====

Tests are located in the tests directory and are written using [busted](http://olivinelabs.com/busted/ "Busted home page").

Install `busted`:

	$ luarocks install busted

Run Tests:

	$ busted -p _tests tests

Licensing
====

`lua-requests` is licensed under the MIT license. See LICENSE.md for details on the MIT license.
