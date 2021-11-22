#!/bin/bash

# Usage:
#
#   ./release.sh <version number>
#
#
# to be able to publish on Android Play Market need to first prepare the keystore file and send it Google:
# java -jar pepk.jar --keystore=~/keystores/bitdust.keystore --alias=bitdust --output=output.zip --encryptionkey=xxx --include-cert
# create a file ".keystore_password" in the same folder and store the keystore password there

set -e

rm -rf buildozer.spec.building

cp -v buildozer.spec buildozer.spec.building

echo "__version__ = \"$1\"" > src/version.py

make release_android

mv -v -f buildozer.spec.building buildozer.spec

pw=$(cat ".keystore_password")

zipalign -v 4 ./bin/BitDustAndroid_unsigned.apk  ./bin/BitDustAndroid.apk

apksigner sign --ks ~/keystores/bitdust.keystore --ks-pass file:.keystore_password --v1-signing-enabled true --v2-signing-enabled true bin/BitDustAndroid.apk

apktool d -o ./bin/apk/ -f ./bin/BitDustAndroid.apk

rm -rf ./bin/apk/private_mp3/
mkdir -p ./bin/apk/private_mp3/
cp ./bin/apk/assets/private.mp3 ./bin/apk/private_mp3/private_mp3.tar.gz
cd ./bin/apk/private_mp3/
tar -p -xf private_mp3.tar.gz
find . -type d -exec chmod +x {} \;
cd ../../..

echo "SUCCESS !!!"