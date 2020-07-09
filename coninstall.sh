#!/bin/bash -f
#-------------------------------------------------------------------------------
# Copyright (c) 2018 by Future Design Systems
#-------------------------------------------------------------------------------
# coninstall.sh -- CON-FMC package installation script
#-------------------------------------------------------------------------------
# VERSION: 2018.08.22.
#-------------------------------------------------------------------------------
# If an error occurs during installation then a message will be sent to
# stdout and the script will exit with a non-zero code indicating its
# error status.
# 0 = no error
# 1 = interrupted
# 2 = not proper permission
# 3 = '-dist' does not have directory path
# 9 = fail to install the package
#-------------------------------------------------------------------------------
SHELL=/bin/bash

#-------------------------------------------------------------------------------
trap func_catch 1 2 15 # prepare to catch interrupts (EXIT, INT, TERM)

#-------------------------------------------------------------------------------
# default installation directory
CONFMC_VER=2020.06
DIR_INS=/opt/confmc/${CONFMC_VER}

#-------------------------------------------------------------------------------
function func_help() {
   echo "Usage : $0 [options]"
   echo "           -dst  install_dir    installation directory: ${DIR_INS}"
   echo "           -h/-?                printf help"
   echo ""
   echo "Exampel: $ sudo $0 -dst ${DIR_INS}"
   return 0
}

#-------------------------------------------------------------------------------
# which yum : redhat, centos, fedora
# which apt-get : debian, ubuntu
OS_DIST= # CentOS Ubuntu
OS_RELE= # 6.6, 14.04
OS_KERN=
MACH_TYPE= # bits
PROCESSOR= # bits
GCC_VER=
#-------------------------------------------------------------------------------
# return 1 on success, otherwize 0.
function func_os_info {
  local os=`uname -s | tr [:upper:] [:lower:]`
  if [ ${os} != "linux" ]; then
     return 0
  fi
  if which xlsb_release &> /dev/null; then
     OS_DIST=`lsb_release -si | tr [:upper:] [:lower:]`
     OS_RELE=`lsb_release -sr`
  elif [ -f x/etc/os-release ]; then
       OS_DIST=`cat /etc/os-release | grep -h ^ID= | cut -d'=' -f2 | tr [:upper:] [:lower:]`
       OS_RELE=`cat /etc/os-release | grep -h ^VERSION_ID= | cut -d'=' -f2 | tr -d '"'`
  elif [ -f x/etc/lsb-release ]; then
       OS_DIST=`cat /etc/lsb-release | grep -h ^DISTRIB_ID= | cut -d'=' -f2 | tr [:upper:] [:lower:]`
       OS_RELE=`cat /etc/lsb-release | grep -h ^DISTRIB_RELEASE= | cut -d'=' -f2`
  else
       echo "could not figure out OS info."
       return 0
  fi
  OS_KERN=`uname -r | cut -d'-' -f1`
  MACH_TYPE=`uname -m`
  PROCESSOR=`uname -p`
  GCC_VER=`gcc -dumpversion`
  return 1
}

#-------------------------------------------------------------------------------
function func_catch() {
   echo Interrupted.
   exit 1
}

#-------------------------------------------------------------------------------
# return 1 on success, otherwize 0.
function am_i_root() {
   if [ `id -u` = "0" ]; then
      return 1
   else
      return 0
   fi
}

#-------------------------------------------------------------------------------
# return 1 on success, otherwize 0.
function is_readable() {
   local dir=$1 
   if [ -d $dir ]; then
      if [ -x $dir ]; then
         echo "$dir accessible"
         return 1
      else
         echo "$dir not accessible"
         return 0
      fi
   else
      echo "$dir not exist"
      return 0
   fi
}

#-------------------------------------------------------------------------------
# return 1 on success, otherwize 0.
function is_writable() {
   local dir=$1 
      while [ $dir ]; do
         if [ -d $dir ]; then
            if [ -w $dir ]; then
               echo "$dir writable"
               return 1
            else
               echo "$dir not writable"
               return 0
            fi
         else
            dir=`dirname $dir`
         fi
      done
}

#-------------------------------------------------------------------------------
# return 1 on success, otherwize 0.
function func_license() {
   local answer
   #----------------------------------------------------------------------------
   while true; do
      echo ""
      echo "Do you want to see full \"End-User-License-Agreement for CON-FMC\""
      echo -n "Yes (Y) or no (n): "
      read answer
      if [ "${answer}" == "Y" ] || [ "${answer}" == "y" ]; then
         if [ ! -f "EULA.txt" ]; then
            echo -n "${FUNCNAME}\(\):Error: \"End-User-License-Agreement for CON-FMC\" not found"
            echo " please contact to contact@future-ds.com"
         else
            /bin/more EULA.txt
            echo ""
            break
         fi
      elif [ "${answer}" == "N" ] || [ "${answer}" == "n" ]; then
         break;
      fi
   done
   #----------------------------------------------------------------------------
   while true; do
      echo ""
      echo "Do you agree \"End-User-License-Agreement for CON-FMC\""
      echo -n "Yes (Y) or no (n): "
      read answer
      if [ "${answer}" == "N" ] || [ "${answer}" == "n" ]; then
            echo "Thank you for your interest in Future Deisng Systems CON-FMC product. Bye."
            exit 0
      elif [ "${answer}" == "Y" ] || [ "${answer}" == "y" ]; then
           echo "Thank you and proceed to install CON-FMC software"
           break
      fi
   done
   #----------------------------------------------------------------------------
   return 0
}

#-------------------------------------------------------------------------------
SET_FILES="settings.csh settings.sh"
UDEV_FILE="51-fds-rule.rules"
#-------------------------------------------------------------------------------
function func_install() { # install_dir
   #----------------------------------------------------------------------------
   # check argument
   if [ -z "$1" ]; then
      echo ${FUNCNAME}\(\):Error: installation directory not specified.
      return 1
   fi
   local DIR_TAR=$1
   #----------------------------------------------------------------------------
   # check if source and destination are the same
   local DIR_DST=`readlink -f "$1"`
   local DIR_SRC=`pwd`
   if [ "${DIR_SRC}" == "${DIR_DST}" ]; then
      echo ${FUNCNAME}\(\):Error: source-dest ${DIR_DST}.
      return 1
   fi
   #----------------------------------------------------------------------------
   # ask if remove destination directory if exists
   if [ -d ${DIR_TAR} ]; then
      local key_in=X
      echo -n "Warning: ${DIR_TAR} exists, remove (R) or overwrite (W): "
      read key_in
      if [ "${key_in}" == "R" ] || [ "${key_in}" == "r" ]; then
           local answer=n
           echo -n "Warning: ${DIR_TAR} will be erased, ARE YOU SURE (Y|n)"
           read answer
           if [ "${answer}" == "Y" ] || [ "${answer}" == "y" ]; then
                /bin/rm -rf ${DIR_TAR}
           else
                return 1
           fi
      elif [ "${key_in}" == "W" ] || [ "${key_in}" == "w" ]; then
           echo "Warning: ${DIR_TAR} will be updated"
      else
           echo "${key_in} not known"
           return 1
      fi
   fi
   #----------------------------------------------------------------------------
   if [ ! -d ${DIR_TAR} ]; then
      /bin/mkdir -p ${DIR_TAR}
      if test $? -ne 0; then
            echo ${FUNCNAME}\(\):Error: could not create ${DIR_TAR}.
            return $?
      fi
   fi
   #----------------------------------------------------------------------------
   # move package
   /bin/tar --exclude=coninstall.sh\
            --exclude=${UDEV_FILE}\
            --exclude=.git\
            -cf - .\
            | (cd ${DIR_TAR}; /bin/tar --group=`id -g` --owner=`id -g` -xf -)
   if test $? -ne 0; then
         echo ${FUNCNAME}\(\):Error: could not copy ${DIR_TAR}.
         return $?
   fi
   #----------------------------------------------------------------------------
   # update setting files
   for S in ${SET_FILES}; do
       local DIR_TARGET=`readlink -f "${DIR_TAR}"`
       if [ -f ${S} ]; then
            if [ -f ${DIR_TAR}/${S} ]; then /bin/rm -f ${DIR_TAR}/${S}; fi
            /bin/cat ${S} | /bin/sed 's|CONFMC_CONFMC|'"${DIR_TARGET}"'|g' > ${DIR_TAR}/${S}
            /bin/chmod 755 ${DIR_TAR}/${S}
       else
            echo ${FUNCNAME[0]}\(\):Warning: ${S} not found.
       fi
   done
   #----------------------------------------------------------------------------
   # update udev files
   if [ -f ${UDEV_FILE} ]; then
      if [ -d /etc/udev/rules.d ]; then
         if [ -f /etc/udev/rules.d/${UDEV_FILE} ]; then
            while true; do
               echo ""
               echo "Override \"/etc/udev/rules.d/${UDEV_FILE}\""
               echo -n "Yes (Y) or no (n): "
               read answer
               if [ "${answer}" == "N" ] || [ "${answer}" == "n" ]; then
                    echo "Keep \"/etc/udev/rules.d/${UDEV_FILE}\""
                    break
               elif [ "${answer}" == "Y" ] || [ "${answer}" == "y" ]; then
                    /bin/cp ${UDEV_FILE} /etc/udev/rules.d/${UDEV_FILE}
                    /bin/chmod 644 /etc/udev/rules.d/${UDEV_FILE}
                    break
               fi
            done
         else
            /bin/cp ${UDEV_FILE} /etc/udev/rules.d/${UDEV_FILE}
            /bin/chmod 644 /etc/udev/rules.d/${UDEV_FILE}
         fi
            echo ""
            echo "You may need to run followings or re-boot the system."
            echo "$ sudo udevadm control --reload-rules"
            echo "$ sudo service udev restart"
            echo "$ sudo udevadm trigger"
      fi
   fi
}

#-------------------------------------------------------------------------------
while [ "$1" != "" ]; do
   case $1 in
   -dst|--install) if [ -z "$2" ]; then
                      echo "$1 needs option"
                      func_help
                      exit 3
                   fi
                   shift
                   DIR_INS=$1
                   ;;
   -h|-\?|--help ) func_help
                   exit 0
                   ;;
   *) func_help
      exit 0
      ;;
   esac
   shift
done

#-------------------------------------------------------------------------------
is_writable ${DIR_INS}
if [ $? == "0" ]; then
   echo "You need a proper permission for ${DIR_INS}."
   echo "Why don't you use 'sudo ./coninstall.sh'."
   exit 2
fi

#-------------------------------------------------------------------------------
func_license
func_install ${DIR_INS}

#-------------------------------------------------------------------------------
if test $? -ne 0; then
   echo Error: could not install.
   return $?
else
   echo ""
   echo CON-FMC software package has been installed at `readlink -f ${DIR_INS}`
   echo Do not forget to run "`readlink -f ${DIR_INS}`/settings.sh" before using CON-FMC software.
   echo ""
fi

#-------------------------------------------------------------------------------
# Revision history:
#
# 2018.08.22: '--exclude=.git' added by Ando Ki.
# 2018.08.15: 'grep' with '-h', which suppress the prefixing of file names on output
# 2018.08.15: '--exclude=${UDEV_FILE}' added by Ando Ki.
# 2018.05.10: Started by Ando Ki (adki@future-ds.com)
#-------------------------------------------------------------------------------
