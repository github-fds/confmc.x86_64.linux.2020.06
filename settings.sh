#------------------------------------------------------------------------------
# Copyright (c) 2018-2019-2020 Future Design Systems, Inc. All rights reserved. 
#------------------------------------------------------------------------------
# FILE: setting.sh
#------------------------------------------------------------------------------
KERN=`uname -s | tr '[:upper:]' '[:lower:]'`
MACH=`uname -m`

function usage() {
    echo "Usage: $0 [options]"
    echo "       -python 2|3    : Python version"
    echo "       -help          : print help"
}

PYTHON_VERSION=3
if command -v python &> /dev/null; then
    PYTHON_VERSION=`python --version 2>&1 | cut -d" " -f 2 | cut -d"." -f 1`
fi

while [ "$1" != "" ]; do
    case $1 in
        -python | --python ) shift
                             PYTHON_VERSION=$1
                             ;;
        -h | -help | --help ) usage
                              exit
                              ;;
        * ) usage
            exit 1
    esac
    shift
done

export CONFMC_HOME=CONFMC_CONFMC
if [ -n "${PATH}" ]; then
  export PATH=$CONFMC_HOME/bin:$PATH
else
  export PATH=$CONFMC_HOME/bin
fi
if [ -n "${LD_LIBRARY_PATH}" ]; then
  export LD_LIBRARY_PATH=$CONFMC_HOME/lib/${KERN}_${MACH}:$LD_LIBRARY_PATH
else
  export LD_LIBRARY_PATH=$CONFMC_HOME/lib/${KERN}_${MACH}
fi
if [ -n "${C_INCLUDE_PATH}" ]; then
  export C_INCLUDE_PATH=$CONFMC_HOME/include:$C_INCLUDE_PATH
else
  export C_INCLUDE_PATH=$CONFMC_HOME/include
fi
if [ -n "${CPLUS_INCLUDE_PATH}" ]; then
  export CPLUS_INCLUDE_PATH=$CONFMC_HOME/include:$CPLUS_INCLUDE_PATH
else
  export CPLUS_INCLUDE_PATH=$CONFMC_HOME/include
fi

if [ -n "${PYTHONPATH}" ]; then
  export PYTHONPATH=$CONFMC_HOME/python${PYTHON_VERSION}/${KERN}_${MACH}:$PYTHONPATH
else
  export PYTHONPATH=$CONFMC_HOME/python${PYTHON_VERSION}/${KERN}_${MACH}
fi
