#!/bin/bash

# Create keystore directory if it doesn't exist
mkdir -p android/app/keystore

# Generate keystore
keytool -genkey -v \
  -keystore android/app/keystore/release.keystore \
  -alias vocable \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass vocable123 \
  -keypass vocable123 \
  -dname "CN=Vocable, OU=Vocable, O=Vocable, L=Paris, ST=France, C=FR"

echo "Keystore generated successfully!"
echo "Please add these environment variables to your system:"
echo "export KEYSTORE_PASSWORD=vocable123"
echo "export KEY_ALIAS=vocable"
echo "export KEY_PASSWORD=vocable123" 