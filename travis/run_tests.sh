#!/bin/sh

# Script for running tests in travis

# Start httpbin
gunicorn -b 0.0.0.0:8080 httpbin:app &
pid=$!

# Wait for httpbin to get running
sleep 2

# Run tests
busted --verbose --coverage --exclude-tags=secure -p _tests tests

# Kill httpbin
kill $pid

# Wait for httpbin to die
while kill -0 $pid 2>/dev/null; do sleep 1; done;
