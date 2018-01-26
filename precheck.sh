#!/bin/bash

echo "Running pre-checks..."

for command in wget unzip; do
	which $command 2>/dev/null >/dev/null
	if [ $? == 0 ]; then
		echo " * $command found."
	else
		echo "  * $command not found, exiting."
		exit 1
	fi
done

echo ""
echo "Pre-checks passed."

exit 0
