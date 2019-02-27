#!/bin/bash

REQUIRED_SPACE="50 Mb"
MY_PATH=`dirname "$0"`
XCODE_PATH="/Applications/Xcode.app"
PLATFORM_PATH="${XCODE_PATH}/Contents/Developer/Platforms/iPhoneOS.platform"
SDK_PATH="${PLATFORM_PATH}/Developer/SDKs"
XCTCHAIN_PATH="${XCODE_PATH}/Contents/Developer/Toolchains/XcodeDefault.xctoolchain"
OUTFILE="${MY_PATH}/SDK.zip"
OUTFILE_KEYCHAIN="${MY_PATH}/Keychain.zip"
LOCKFILE="${MY_PATH}/migration-assistant.lock"

if [ "_${MY_PATH}_" = "_._" ]; then
	echo ""
	echo "-------------------------------------------------------------------------------"
	echo "Looks like you're trying to run this script from a Terminal session."
	echo "This does not work as expected. Just double-click the file from Finder instead."
	echo "-------------------------------------------------------------------------------"
	echo ""
	exit
fi

if [ -f "${LOCKFILE}" ]; then
	echo ""
	echo "-------------------------------------------------------------------------------"
	echo "Looks like the migration assistant is already running. Why not let it finish?"
	echo "If it's not, please delete ${LOCKFILE}"
	echo "and run this script again."
	echo "-------------------------------------------------------------------------------"
	echo ""
	exit
fi

echo ""
echo "-------------------------------------------------------------------------------"
echo "Welcome! This automated script will copy a few files from the iOS SDK that are "
echo "necessary for the iOS Build Environment to work."
#echo "These files will be copied on the USB key at ${OUTFILE}"
echo "-------------------------------------------------------------------------------"

touch "${LOCKFILE}"

echo ""
echo -n "Step 1. Let's see if Xcode is installed and if we have the iOS SDK... "
THE_SDK=`ls -t ${SDK_PATH}|awk '{print $0}'|head -n 1`
if [ ! -f "${XCODE_PATH}/Contents/Info.plist" -o "_${THE_SDK}_" = "__" ]; then
	echo "no."
	echo ""
	echo "iOS SDK not found."
	echo "Please download and install Xcode (it's free) from the Mac App Store"
	echo "before running this script."
	rm -f "${LOCKFILE}"
	exit
fi
echo "yes."

echo ""
echo -n "Step 2. Getting Xcode's version.plist and the needed libraries... "
RT_LIB=`find ${XCODE_PATH} -name libclang_rt.ios.a`
CPPELEVENDIR=`find ${XCTCHAIN_PATH} -name v1`
if [ ! -f "${XCODE_PATH}/Contents/version.plist" -o ! -f "${RT_LIB}" -o ! -d "${CPPELEVENDIR}" ]; then
	echo "fail."
	echo ""
	if [ ! -f "${XCODE_PATH}/Contents/version.plist" ]; then
		echo "Xcode's version.plist not found."
	elif [ ! -f "${RT_LIB}" ]; then
		echo "No Clang runtime library found."
	else
		echo "C++11 libraries not found."
	fi
	echo "Your Xcode version must be ages old !?"
	echo "Please download and install a RECENT version of Xcode that has an iOS"
	echo "SDK in it."
	rm -f "${LOCKFILE}"
	exit
fi
rm -f "${OUTFILE}"
zip -jq "${OUTFILE}" "${RT_LIB}"
cd "${CPPELEVENDIR}/.."
mkdir -p "/tmp/__iosbuildenv_temp/lib/c++"
cp -R v1 "/tmp/__iosbuildenv_temp/lib/c++"
cp "${XCODE_PATH}/Contents/version.plist" "/tmp/__iosbuildenv_temp/xcode-version.plist"
cd "/tmp/__iosbuildenv_temp"
sw_vers|grep BuildVersion|awk '{print $2}' > osx-build
# with symlinks: zip -uryq
zip -urq "${OUTFILE}" "." || ( echo ""; echo "Looks like there's not enough space on your USB key."; echo "Please try again with a key with at least ${REQUIRED_SPACE} free."; rm -f "${LOCKFILE}"; exit; )
rm -rf "/tmp/__iosbuildenv_temp"
echo "done."

echo ""
echo -n "Step 3. Zipping 'System' and 'usr' directories from ${THE_SDK}..."
cd "${SDK_PATH}/${THE_SDK}"
# with symlinks: zip -uryq
zip -urq "${OUTFILE}" "System" "usr" || ( echo ""; echo "Looks like there's not enough space on your USB key."; echo "Please try again with a key with at least ${REQUIRED_SPACE} free."; rm -f "${LOCKFILE}"; exit; )
echo "done."

echo ""
echo -n "Step 4. Saving the platform's Info.plist and version.plist... "
cd "${PLATFORM_PATH}"
if [ ! -f "Info.plist" -o ! -f "version.plist" ]; then
	echo "Platform's Info.plist and/or version.plist not found."
	echo "Your Xcode version must be ages old !?"
	echo "Please download and install a RECENT version of Xcode that has an iOS"
	echo "SDK in it."
	rm -f "${LOCKFILE}"
	exit
fi
zip -urq "${OUTFILE}" "Info.plist" "version.plist" || ( echo ""; echo "Looks like there's not enough space on your USB key."; echo "Please try again with a key with at least ${REQUIRED_SPACE} free."; rm -f "${LOCKFILE}"; exit; )
echo "done."

echo ""
echo -n "Step 5. Exporting the existing iOS code signing identites... "
mkdir -p "/tmp/__iosbuildenv_temp"
cd "/tmp/__iosbuildenv_temp"
# look for iOS developer identities in the keychain and have a list of their names
CERT_IDS=`security find-identity -v -p codesigning|grep iPhone|awk '{print $2}'`
CERT_NAMES=`security find-identity -v -p codesigning|grep iPhone|awk -F\" '{print $2}'`
if [ "_${CERT_NAMES}_" != "__" ]; then
	# iterate through each of them and export the corresponding certificates
	IDENTITY_COUNT=0
	while read -r CERT_NAME; do
		CERT_FILENAME="`echo ${CERT_NAME}|sed 's/[:\\/]//g'`.cer"
		security find-certificate -c 'iPhone Developer: Pierre-Marie Baty (8AKT2R84W5)' -p | /usr/bin/openssl x509 -inform pem -out "${CERT_FILENAME}" -outform der
		IDENTITY_COUNT=$(expr ${IDENTITY_COUNT} + 1)
	done <<< "${CERT_NAMES}"
	# now export all private keys and secure them with a passphrase
	security export -k /Library/Keychains/System.keychain -t identities -f pkcs12 -P w0bbit | /usr/bin/openssl pkcs12 -nodes -nocerts -passin pass:w0bbit 2> /dev/null|csplit -f private_key - '/^Bag Attributes/' > /dev/null 2>&1
	KEYPASS=`osascript -e 'Tell application "System Events" to display dialog "Enter a passphrase in the following dialog to protect during their transfer the private key(s) that were found on your Mac.\n\n4 characters minimum, a mix of the ranges [A-Z][a-z][0-9] is safe (DO NOT USE SPECIAL CHARACTERS!)\n\nRemember that passphrase, you will need it in Windows to sign your iOS apps." with hidden answer default answer ""' -e 'text returned of result' 2>/dev/null`
	for KEYFILE in private_key*; do
		# remove duplicates before encryption
		for OTHERFILE in private_key*; do
			test "_${KEYFILE}_" == "_${OTHERFILE}_" && continue
			test ! -e "${KEYFILE}" && continue
			test ! -e "${OTHERFILE}" && continue
			cmp "${KEYFILE}" "${OTHERFILE}" > /dev/null && rm -f "${OTHERFILE}"
		done
		test ! -e "${KEYFILE}" && continue
		# preserve key name
		KEYNAME=`cat "${KEYFILE}"|grep friendlyName|awk -F': ' '{print $2}'`
		echo "Bag Attributes" > "${KEYFILE}.key"
		echo "    friendlyName: ${KEYNAME}" >> "${KEYFILE}.key"
		openssl rsa -des3 -in "${KEYFILE}" -passout pass:"${KEYPASS}" >> "${KEYFILE}.key" 2> /dev/null
		rm -f "${KEYFILE}"
	done
	KEYPASS=""
	echo "${IDENTITY_COUNT} found."
else
	echo "none found."
fi
# gather all the provisioning profiles in our temporary directory alongside the certificates and private keys
# preserve mtime during copy (-p), this will make older profiles be overwritten (mv) by newer copies
cp -p ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision . 2>/dev/null
if [ "_`ls -t *.mobileprovision 2> /dev/null`_" != "__" ]; then
	for PROFILE in `ls -t *.mobileprovision`; do
		NAME=`cat "${PROFILE}" | grep -a "<string>" | sed -e 's/<string>//g' -e 's/<\/string>//g' | awk '{$1=$1};1' | head -n 2 | head -n 1`
		TEAMID=`cat "${PROFILE}" | grep -a "<string>" | sed -e 's/<string>//g' -e 's/<\/string>//g' | awk '{$1=$1};1' | head -n 2 | tail -n 1`
		mv "${PROFILE}" "${NAME} (${TEAMID}).mobileprovision"
	done
fi
rm -f "${OUTFILE_KEYCHAIN}"
if [ "_`ls -t * 2> /dev/null`_" != "__" ]; then
	zip -jq "${OUTFILE_KEYCHAIN}" * || ( echo ""; echo "Looks like there's not enough space on your USB key."; echo "Please try again with a key with at least ${REQUIRED_SPACE} free."; rm -f "${LOCKFILE}"; exit; )
fi
rm -rf "/tmp/__iosbuildenv_temp"

rm -f "${LOCKFILE}"

echo ""
echo "-------------------------------------------------------------------------------"
echo "Finished."
echo "I have all the files I need. Now please reboot into Windows, open your USB key"
echo "there and run the second part of the migration assistant."
echo "-------------------------------------------------------------------------------"
