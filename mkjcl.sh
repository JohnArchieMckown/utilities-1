#!/bin/sh
function usage {
   cat <<EOF
Usage: mkjcl jcl-template-file [parameters]

This shell script requires at least one parameter.
The first parameter is a file containing template JCL.
The subsequent parameters are of the form "name=value".
This script does not attempt any validation.
If you break it, you own both parts.
EOF
   exit 1
}
test $# -eq 0 && usage
jcl=$1
shift
i=$(basename ${jcl})
test "${jcl}" = "-" && jcl="/dev/fd/0"
test "${jcl}" = "$i" && jcl="./${jcl}"
while [ $# -gt 0 ];do
  stmt="$1";
  shift
  eval "${stmt}"
done
JOBNAME=${JOBNAME:-${LOGNAME}}
MSGCLASS=${MSGCLASS:-H}
CLASS=${CLASS:-A}
eval ". ${jcl}"

