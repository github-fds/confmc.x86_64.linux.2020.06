#!/bin/bash

/bin/rm -rf .Xil
/bin/rm -f  *.html
/bin/rm -f  *.xml
/bin/rm -f  *.jou
/bin/rm -f  *.backup*
/bin/rm -f  planAhead.*
/bin/rm -f  vivado.log
/bin/rm -f  vivado_pid*.str  vivado_pid*.debug
/bin/rm -f  fsm_encoding.os

/bin/rm -f  ./*.log
/bin/rm -f  *.xpr
/bin/rm -f  $(MODULE).ucf
/bin/rm -f  $(MODULE).ut
/bin/rm -f  $(MODULE).tcf
/bin/rm -rf work
/bin/rm -rf sim
/bin/rm -rf src
/bin/rm -rf xgui
/bin/rm -rf bfm_axi_if.cache
/bin/rm -rf bfm_axi_if.hw
/bin/rm -rf bfm_axi_if.ip_user_files
/bin/rm -rf bfm_axi_if.sim
