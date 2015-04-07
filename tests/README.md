Tests
====

All tests are written using [busted](http://olivinelabs.com/busted/ "Busted home page").

Install `busted`:

	$ luarocks install busted

Run All Tests:

	$ busted -p _tests tests


Files
====

Tests are broken down into three files. `user_tests.lua` use [httpbin](http://httpbin.org/) to verify correct functionality. Tests within `user_tests.lua` will fail if they don't have internet access.


Code Coverage
====

Code coverage is done using [luacov](http://luacov.luaforge.net/).

Install `luacov`:

	$ luarocks install luacov

Run All Tests and check code coverage:

	$ busted -c -p _test tests
	$ luacov luacov.stats.out
	$ cat luacov.report.out
