#! /bin/bash
# This only seems to work with CygwinX, VcXsrv doesn't seem to work.
# https://gist.github.com/LAK132/fcc946f848f9ed87dbef289f2d30096d
if [ -z "$1" ]
then
  echo "Please specify path to Vivado installer"
else
  export DISPLAY="`cat /etc/resolv.conf | grep nameserver | awk '{ print $2 }'`:0.0" && echo $DISPLAY && sudo apt install libncurses5 && sudo $1
fi
