#!/bin/bash

_usage_and_exit()
{
	echo "$0 <class name> <title>"
	echo ""
	echo "Parameters:"
	echo "  class name: java class name, must match ^[a-z0-9\.]+\$"
	echo "  title: custom text, multiple words must be enclosed by \""
	echo ""
	echo "Example:"
	echo "  $0 hu.kakaopor.gheja.sitametgame \"Sit Amet Game\""
	exit 1
}

if [ $# != 2 ]; then
	_usage_and_exit
fi

echo "$1" | grep -Eq '^[a-z0-9\.]+$'
if [ $? != 0 ]; then
	_usage_and_exit
fi

echo "$2" | grep -Eq '^[^"]+$'
if [ $? != 0 ]; then
	_usage_and_exit
fi

name_from="hu.kakaopor.gheja.browsertest"
name_to="$1"
title="$2"

name_from_2=`echo "$name_from" | sed -r 's,\.,\\\\.,g'`

dir_from=`echo "$name_from" | sed -r 's,\.,/,g'`
dir_to=`echo "$name_to" | sed -r 's,\.,/,g'`

mkdir -p "app/src/main/java/${dir_to}/"

mv "app/src/main/java/${dir_from}/"* "app/src/main/java/${dir_to}/"

find -type f | grep -vE '^\./rename.sh' | xargs -d '\n' sed -i -r "s/${name_from_2}/${name_to}/g"

sed -i -r "s/browsertest/${title}/g" app/src/main/res/values/strings.xml
