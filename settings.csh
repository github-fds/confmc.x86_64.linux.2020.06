#!/bin/csh -f
#------------------------------------------------------------------------------
# Copyright (c) 2018-2019-2020 Future Design Systems, Inc. All rights reserved. 
#------------------------------------------------------------------------------
# FILE: setting.csh
#------------------------------------------------------------------------------
set KERN=`uname -s | tr '[:upper:]' '[:lower:]'`
set MACH=`uname -m`

set PYTHON_VERSION=3
if (`which python` == "python") then
    set PYTHON_VERSION=`python --version 2>&1 | cut -d" " -f 2 | cut -d"." -f 1`
endif

@ i = 1

while ( $#argv >= $i )
    switch ( $argv[$i] )
        case '-python': 
        case '--python': 
               @ i++
               set PYTHON_VERSION=$argv[$i]
               breaksw
        case '-help':
        case '--help':
               goto HELP
               breaksw
        default:
               goto HELP
    endsw
    @ i++
end

setenv CONFMC_HOME CONFMC_CONFMC
if $?PATH then
  setenv PATH $CONFMC_HOME/bin:$PATH
else
  setenv PATH $CONFMC_HOME/bin
endif
if $?LD_LIBRARY_PATH then
  setenv LD_LIBRARY_PATH $CONFMC_HOME/lib/${KERN}_${MACH}:$LD_LIBRARY_PATH
else
  setenv LD_LIBRARY_PATH $CONFMC_HOME/lib/${KERN}_${MACH}
endif
if $?C_INCLUDE_PATH then
  setenv C_INCLUDE_PATH $CONFMC_HOME/include:$C_INCLUDE_PATH
else
  setenv C_INCLUDE_PATH $CONFMC_HOME/include
endif
if $?CPLUS_INCLUDE_PATH then
  setenv CPLUS_INCLUDE_PATH $CONFMC_HOME/include:$CPLUS_INCLUDE_PATH
else
  setenv CPLUS_INCLUDE_PATH $CONFMC_HOME/include
endif
if $?PYTHONPATH then
  setenv PYTHONPATH=${CONFMC_HOME}/python${PYTHON_VERSION}/${KERN}_${MACH}:${PYTHONPATH}
else
  setenv PYTHONPATH=${CONFMC_HOME}/python${PYTHON_VERSION}/${KERN}_${MACH}
endif

exit 0 # normal exit

HELP:
    echo "Usage: $0 [options]"
    echo "       -python 2|3    : Python version"
    echo "       -help          : print help"

