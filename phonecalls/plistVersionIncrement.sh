#!/bin/bash
#
# @(#)  Increment the version number in the project plist.
#               Note:   The project plist could be in directory
#                               "Resources" or the project root.
#                               Personally, I avoid clutter in the project root.
#               Enjoy! xaos@xm5design.com
# Based on
# http://davedelong.com/blog/2009/04/15/incrementing-build-numbers-xcode
# Now available at:
# https://github.com/othercat/MyUtilities/blob/master/OSXShellCommands/plistVersionIncrement.sh
#

PLIST=/usr/libexec/PlistBuddy

PROJECTMAIN=$(pwd)
PROJECT_NAME=$(basename "${PROJECTMAIN}")
#
buildPlist="${INFOPLIST_FILE}"
echo -e "Looking for ${INFOPLIST_FILE}"
if [[ -f "${INFOPLIST_FILE}" ]]
then
    echo "Found ${buildPlist}"
else
    echo -e "plistVersionIncrement.sh: Can't find the plist: ${INFOPLIST_FILE}"
exit 1
fi
shortVersion=$($PLIST -c "Print CFBundleShortVersionString" "${buildPlist}" 2>/dev/null)
if [[ "${shortVersion}" = "" ]]
then
    echo -e "\"${buildPlist}\" does not contain key: \"CFBundleShortVersionString\""
exit 1
fi
IFS='.'
set $shortVersion
MAJOR_VERSION="${1}.${2}.${3}"
#
buildVersion=$($PLIST -c "Print CFBundleVersion" "${buildPlist}" 2>/dev/null)
if [[ "${buildVersion}" = "" ]]
then
    echo -e "\"${buildPlist}\" does not contain key: \"CFBundleVersion\""
exit 1
fi
IFS='.'
set $buildVersion
MINOR_VERSION="${4}"
buildNumber=$(($MINOR_VERSION + 1))
buildNewVersion="${MAJOR_VERSION}.${buildNumber}"
echo -e "${PROJECT_NAME}: Old version number: ${buildVersion} New Version Number: ${buildNewVersion}"
$PLIST -c "Set :CFBundleVersion ${buildNewVersion}" "${buildPlist}"
