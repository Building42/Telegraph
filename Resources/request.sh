#!/bin/bash

# Make sure that we are in the script's folder
cd "${0%/*}"

echo
echo TELEGRAPH
echo

curl -v --cacert ca.der https://localhost:9000"$@"

echo
echo
