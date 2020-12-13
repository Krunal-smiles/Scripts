#!/bin/sh
outp=`mdls -name kMDItemVersion /Applications/Microsoft\ Edge.app`
#outp=`mdls -name kMDItemVersion /Applications/zoom.us.app`
echo $outp | cut -d " " -f 3-
