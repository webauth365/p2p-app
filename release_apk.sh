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


make prepare_build_location
make clone_engine_sources

rm -rfv ./bin/BitDustAndroid_*.apk


# x86_64
if [[ "1" == "" ]]; then
	rm -rf buildozer.spec.building
	cp -v buildozer.spec buildozer.spec.building
	echo "__version__ = \"$1\"" > ./src/version.py
	make refresh_android_environment_full
	rm -rfv ./bin/BitDustAndroid.apk
	rm -rfv ./bin/BitDustAndroid_unsigned.apk
	rm -rfv ./bin/bitdust1-*-release-unsigned.apk
	(PYTHONIOENCODING=utf-8 VIRTUAL_ENV=1 ./venv/bin/buildozer -v --profile x86_64 android release 1>x86_64.out.log 2>x86_64.err.log || PYTHONIOENCODING=utf-8 VIRTUAL_ENV=1 ./venv/bin/buildozer -v --profile x86_64 android release 1>x86_64.out.log 2>x86_64.err.log)
	cp -v -f ./bin/bitdust*.apk ./bin/BitDustAndroid_unsigned.apk
	mv -v -f buildozer.spec.building buildozer.spec
	pw=$(cat ".keystore_password")
	zipalign -v 4 ./bin/BitDustAndroid_unsigned.apk  ./bin/BitDustAndroid.apk
	apksigner sign --ks ~/keystores/bitdust.keystore --ks-pass file:.keystore_password --v1-signing-enabled true --v2-signing-enabled true bin/BitDustAndroid.apk
	mv -v ./bin/BitDustAndroid.apk ./bin/BitDustAndroid_x86_64.apk
fi


# armeabi_v7a
if [[ "1" == "" ]]; then
	rm -rf buildozer.spec.building
	cp -v buildozer.spec buildozer.spec.building
	echo "__version__ = \"$1\"" > ./src/version.py
	make refresh_android_environment_full
	rm -rfv ./bin/BitDustAndroid.apk
	rm -rfv ./bin/BitDustAndroid_unsigned.apk
	rm -rfv ./bin/bitdust1-*-release-unsigned.apk
	(PYTHONIOENCODING=utf-8 VIRTUAL_ENV=1 ./venv/bin/buildozer -v --profile armeabi_v7a android release 1>armeabi_v7a.out.log 2>armeabi_v7a.err.log || PYTHONIOENCODING=utf-8 VIRTUAL_ENV=1 ./venv/bin/buildozer -v --profile armeabi_v7a android release 1>armeabi_v7a.out.log 2>armeabi_v7a.err.log)
	cp -v -f ./bin/bitdust*.apk ./bin/BitDustAndroid_unsigned.apk
	mv -v -f buildozer.spec.building buildozer.spec
	pw=$(cat ".keystore_password")
	zipalign -v 4 ./bin/BitDustAndroid_unsigned.apk  ./bin/BitDustAndroid.apk
	apksigner sign --ks ~/keystores/bitdust.keystore --ks-pass file:.keystore_password --v1-signing-enabled true --v2-signing-enabled true bin/BitDustAndroid.apk
	mv -v ./bin/BitDustAndroid.apk ./bin/BitDustAndroid_armeabi_v7a.apk
fi


# arm64_v8a
rm -rf buildozer.spec.building
cp -v buildozer.spec buildozer.spec.building
echo "__version__ = \"$1\"" > ./src/version.py
make refresh_android_environment_full
rm -rfv ./bin/BitDustAndroid.apk
rm -rfv ./bin/BitDustAndroid_unsigned.apk
rm -rfv ./bin/bitdust1-*-release-unsigned.apk
# (PYTHONIOENCODING=utf-8 VIRTUAL_ENV=1 ./venv/bin/buildozer -v --profile arm64_v8a android release 1>arm64_v8a.out.log 2>arm64_v8a.err.log || PYTHONIOENCODING=utf-8 VIRTUAL_ENV=1 ./venv/bin/buildozer -v --profile arm64_v8a android release 1>arm64_v8a.out.log 2>arm64_v8a.err.log)
(PYTHONIOENCODING=utf-8 VIRTUAL_ENV=1 ./venv/bin/buildozer -v --profile arm64_v8a android release || PYTHONIOENCODING=utf-8 VIRTUAL_ENV=1 ./venv/bin/buildozer -v --profile arm64_v8a android release)
cp -v -f ./bin/bitdust*.apk ./bin/BitDustAndroid_unsigned.apk
mv -v -f buildozer.spec.building buildozer.spec
pw=$(cat ".keystore_password")
zipalign -v 4 ./bin/BitDustAndroid_unsigned.apk  ./bin/BitDustAndroid.apk
apksigner sign --ks ~/keystores/bitdust.keystore --ks-pass file:.keystore_password --v1-signing-enabled true --v2-signing-enabled true bin/BitDustAndroid.apk
mv -v ./bin/BitDustAndroid.apk ./bin/BitDustAndroid_arm64_v8a.apk


# extract .APK file for development purposes
apktool d -o ./bin/apk/ -f ./bin/BitDustAndroid_arm64_v8a.apk
rm -rf ./bin/apk/private_mp3/
mkdir -p ./bin/apk/private_mp3/
cp ./bin/apk/assets/private.tar ./bin/apk/private_mp3/private_mp3.tar.gz
cd ./bin/apk/private_mp3/
tar -p -xf private_mp3.tar.gz
find . -type d -exec chmod +x {} \;
cd ../../..


# cleanup
rm -rfv ./bin/BitDustAndroid.apk
rm -rfv ./bin/BitDustAndroid_unsigned.apk
rm -rfv ./bin/bitdust1-*-release-unsigned.apk


echo "SUCCESS !!!"