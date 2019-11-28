#!/bin/bash

# Shell script to run specs.
crystal spec spec/athena_spec.cr --order random --error-on-warnings
crystal spec spec/cli --order random --error-on-warnings
crystal spec spec/config --order random --error-on-warnings
crystal spec spec/dependency_injection --order random --error-on-warnings
crystal spec spec/routing --order random --error-on-warnings
