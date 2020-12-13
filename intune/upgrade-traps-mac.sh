#!/bin/sh

#turn debug on/off
set -x

cortexpkg="com.paloaltonetworks.pkg.traps"

#check for existing installation
found=`pkgutil --pkgs="${cortexpkg}"`
if [ -z "$found" ]; then
	echo "PaloAlto Traps or CortexXDR is not installed"
else
	echo "PaloAlto Traps is already Installed, checking version"
	#versionfile=`pkgutil --files com.paloaltonetworks.pkg.traps | grep -e "version"`
	#if [ -e "/${versionfile}" ]; then
	#	echo `cat "/$versionfile"`
	#fi
	#appfile=`pkgutil --files com.paloaltonetworks.pkg.traps | grep -e "app$" | head -n 1`
	#echo "`mdls -name kMDItemVersion "/${appfile}"`"
	version="`pkgutil --pkg-info ${cortexpkg} | grep "version" | cut -d " " -f 2`"
	if [ "${version}" -ge "10701022016" ]; then
		echo "The current agent version is same or later than 7.1.2.2016, not upgrading the agent"
		exit 0
	fi
	echo "Agent version is older than 7.1.2.2016, downloading v7.1.2.2016"
fi

#download the package
url="https://<your tenant>/public_api/v1/distributions/get_dist_url/"
apikey="<your api key>"
keyid=<your api key id>
# distribution id of v6.1.4 package
#dist_id="443d60fa18194244b14815e295ab6255"
# distribution id of v7.1.2.2016 package
dist_id="e137b9ef27794c2a8e9e527882836dca"
req_data="{
   \"request_data\":{
      \"distribution_id\":\"${dist_id}\",
      \"package_type\":\"pkg\"
   }
}"

#checking if pkg still exists in Cortex tenanat
echo "Checking pkg for distribution id ${dist_id}"
response=`curl -s -X POST ${url} -H "x-xdr-auth-id:${keyid}" -H "Authorization:${apikey}" -H "Content-Type:application/json" -d "${req_data}"`
echo "Received Response \"${response}\""
dist_url=`echo $response | python -c 'import sys, json; print json.load(sys.stdin)["reply"]["distribution_url"]'`
if [ -z "${dist_url}" ]; then
	echo "No distribution url returned from the server, the package do not exist for the requested distribution id"
	echo "PaloAlto CortexXDR not installed"
	exit 0
fi

#downloading the package
#dist_url="https://<your tenant>/download/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJsY2Fhc19pZCI6Ijc1ODMwNjQ1MyIsImV4cCI6MTYwNjAzMjE2MCwiZGF0YSI6eyJmaWxlX3BhdGgiOiI0NDNkNjBmYTE4MTk0MjQ0YjE0ODE1ZTI5NWFiNjI1NS9wa2ciLCJmaWxlX25hbWUiOiJUcmFwczYxNE1hYy56aXAiLCJidWNrZXRfbmFtZSI6ImotbDR3LWRpc3RyaWJ1dGlvbnMifX0.TYgu43d4xVs3XsX1DaOrCtjvCzB42jxw2d_NNVZXobc"

#create temporary directory
##tempd=$(mktemp -d)
echo "Download package in temporary directory ${tempd}"

##curl -s -X GET ${dist_url} -H "x-xdr-auth-id:${keyid}" -H "Authorization:${apikey}" -H "Content-Type:application/json" -o $tempd/cortexxdr.zip
##if [ -e "${tempd}/cortexxdr.zip" ]; then
##	unzip $tempd/cortexxdr.zip -d "${tempd}/cortex-installer/"
##	pkgfile=`ls -1 "${tempd}/cortex-installer/" | grep -e ".pkg$"`
##	sudo installer -pkg "${tempd}/cortex-installer/${pkgfile}" -target /
##fi
#rm -rf $tempd
set +x
