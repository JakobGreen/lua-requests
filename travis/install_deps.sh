#!/bin/sh

# For travis-ci
# dev.rockspec needs to be turned into an actual 
# rockspec file so we can install the dependencies

set -ex

version=$(grep "version" rocks/dev.rockspec | grep -Po "\d+.\d+-\d+")
rockspec="lua-requests-$version.rockspec"
mv rocks/dev.rockspec $rockspec

luarocks build --only-deps $rockspec
