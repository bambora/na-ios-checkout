#!/bin/bash
#setup script
set -e
scriptDir="$(dirname "$0")"
scriptName="$(basename "$0")"

pushd $scriptDir

#log
now=$(date +"%y%m%d-%H%M%S")
logDir="$scriptDir/logs"
logName="$scriptName.log"
mkdir -p "$logDir"
exec > >(tee "$logDir/$logName")

echo "-----------------------------"
echo "Script: $scriptName"
echo "Time: $now"
echo "-----------------------------"
echo

echo "-----------------------------"
echo "Getting podspec version..."
echo "-----------------------------"
version=$(grep 'spec.version[ ]*=' PayForm.podspec | sed -e "s/.*\'\(.*\)\'.*/\1/")
echo "Version: $version"
echo

echo "-----------------------------"
echo "Packaging..."
echo "-----------------------------"
package="PayForm-$version.tar.gz"

echo "Package: $package"
export COPYFILE_DISABLE=true
tar -cvzf $package PayForm/ PayForm.podspec LICENSE
echo

echo "-----------------------------"
echo "Publishing..."
echo "-----------------------------"

file="artifactory.properties"
if [ -f "$file" ]
then
  	. $file
	curl -u$jfrog_user:$jfrog_pass -X PUT https://beanstream.jfrog.io/beanstream/beanstream-public/$package -T $package
else
  	echo "ERROR: $file not found."
fi
echo

echo "-----------------------------"
echo

popd

