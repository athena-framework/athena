#!/bin/bash

# Shell script to run specs.
crystal spec spec/athena_spec.cr --warnings all --error-on-warnings
crystal spec spec/cli --warnings all --error-on-warnings
crystal spec spec/config --warnings all --error-on-warnings
crystal spec spec/dependency_injection --warnings all --error-on-warnings
crystal spec spec/routing --warnings all --error-on-warnings
