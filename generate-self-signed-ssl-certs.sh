#!/bin/bash
# This script generates SSL certs (.crt and .key) to be used with nginx.
# The files are generated in .PEM format (by default).

echo "Generating certificate (valid for 10 years! :)"
openssl req \
  -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout server.key -out server.crt -subj '/CN=localhost'

echo

echo "Generated files:"
ls server.*


