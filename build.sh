#!/bin/bash

_usage_and_exit()
{
	echo "Usage:"
	echo "  $0 <source directory> <target directory> [project name] [project version]"
	echo ""
	echo "Project name and version is optional, default values are \"unnamed\" and \"0.1.0\"."
	echo ""
	echo "Examples:"
	echo "  $0 src dist"
	echo "  $0 src dist test-project 0.9.3"
	exit 1
}

section_start()
{
	local section="$1"
	local message="$2"
	
	if [ "$TRAVIS" == "true" ]; then
		echo -en "travis_fold:start:${section}\\r"
	fi
	
	echo -e "\\e[1;93m${message}\\e[0;39m"
}

section_end()
{
	local section="$1"
	
	if [ "$TRAVIS" == "true" ]; then
		echo -en "travis_fold:end:${section}\\r"
	fi
}

if [ $# -lt 2 ] || [ $# -gt 4 ]; then
	_usage_and_exit
fi

PROG=`readlink -f "$0"`
ROOT_DIR=`dirname "$PROG"`

# override HOME to avoid trashing user's home
export HOME="$ROOT_DIR"

# set up environment variabes
export ANDROID_HOME="$ROOT_DIR/build/android"
export ANDROID_SDK="$ANDROID_HOME"
export JAVA_HOME="$ANDROID_HOME/jre"
export PATH="$JAVA_HOME/bin:$PATH"

# change the tmp path
export _JAVA_OPTIONS="-Djava.io.tmpdir=$ROOT_DIR/build/tmp"

SOURCE_DIR=`readlink -f "$1" 2>/dev/null`
TARGET_DIR=`readlink -f "$2" 2>/dev/null`
PROJECT_NAME="$3"
PROJECT_VERSION="$4"

if [ "$SOURCE_DIR" == "" ]; then
	echo "ERROR: invalid source directory, exiting."
	exit 1
fi

if [ "$TARGET_DIR" == "" ]; then
	echo "ERROR: invalid target directory, exiting."
	exit 1
fi

if [ "$PROJECT_NAME" == "" ]; then
	PROJECT_NAME="unnamed"
fi

if [ "$PROJECT_VERSION" == "" ]; then
	PROJECT_VERSION="0.1.0"
fi


### preparing
section_start "android_prepare" "Preparing..."

cd "$ROOT_DIR"

# create directories
mkdir -p build

cd build

mkdir -p android
mkdir -p tmp
mkdir -p cache
mkdir -p src

cd cache

# download Android SDK if not downloaded already
if [ ! -e "sdk-tools-linux-3859397.zip" ]; then
	wget https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
fi

# download JRE if not downloaded already
if [ ! -e "android-studio_3_jre.zip" ]; then
	wget https://github.com/gheja/zips/raw/master/android-studio_3_jre.zip
fi

cd ..

# install Android SDK if not installed
cd android

if [ ! -e "tools" ]; then
	unzip -q ../cache/sdk-tools-linux-3859397.zip
fi

# install JRE if not installed
if [ ! -e "jre" ]; then
	unzip -q ../cache/android-studio_3_jre.zip
fi

# accept the licenses
mkdir -p "licenses"

if [ ! -e "licenses/android-sdk-license" ]; then
	echo -e "\n8933bad161af4178b1185d1a37fbf41ea5269c55" > "licenses/android-sdk-license"
	echo -e "\nd56f5187479451eabf01fb78af6dfcb131a6481e" >> "licenses/android-sdk-license"
fi

if [ ! -e "licenses/android-sdk-preview-license" ]; then
	echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > "licenses/android-sdk-preview-license"
fi

./tools/bin/sdkmanager --update
./tools/bin/sdkmanager "platforms;android-26" "build-tools;26.0.2" 2>&1 | grep -vE '^\[[ =]+\] '

cd ..

section_end "android_prepare"

### building
section_start "android_build" "Building..."

cd src

# copy files
cp -r ../../apk_src/* ./
cp -r "$SOURCE_DIR/"* ./app/src/main/assets/www/

# set up sdk path
echo "sdk.dir=$ANDROID_SDK" > ./local.properties

./gradlew --no-daemon --stacktrace --console plain build
result=$?

cd ..

if [ $result != 0 ]; then
	echo "gradlew failed, exiting." >&2
	exit 1
fi

cp src/app/build/outputs/apk/debug/*.apk ./

cp *.apk "$TARGET_DIR/"

section_end "android_build"

cd "$TARGET_DIR"

ls -alh

exit 0
