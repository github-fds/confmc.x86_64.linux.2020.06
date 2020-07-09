#------------------------------------------------------------------
# VIVADO Batch Mode 
#------------------------------------------------------------------
# Copyright (c) 2020 by Future Design Systems
# All right reserved.
#------------------------------------------------------------------
SHELL		= /bin/sh
MAKEFILE	= Makefile
#------------------------------------------------------------------
export VIVADO    = $(XILINX_VIVADO)/bin/vivado
export SOURCE    = ../vivado.script/vivado_gen_ip.tcl
export WORK      = work
export PART      = xc7z020clg484-1
export FPGA_TYPE = z7
export MODULE    = bfm_axi
export RIGOR     = 1
export GUI      ?= 0

#------------------------------------------------------------------
all: vivado

vivado:
	if [ "$(GUI)" = "1" ]; then\
		$(VIVADO) -mode gui -source $(SOURCE);\
	else\
		$(VIVADO) -mode batch -source $(SOURCE);\
	fi

#------------------------------------------------------------------
DIRS    = $(subst /,, $(dir $(wildcard */Makefile)))

clean:
	-@/bin/rm -rf .Xil
	-@/bin/rm -f  *.html
	-@/bin/rm -f  *.xml
	-@/bin/rm -f  *.jou
	-@/bin/rm -f  *.backup*
	-@/bin/rm -f  planAhead.*
	-@/bin/rm -f  vivado.log
	-@/bin/rm -f  vivado_pid*.str  vivado_pid*.debug
	-@/bin/rm -f  fsm_encoding.os

cleanup: clean
	-@/bin/rm -f  ./*.log
	-@/bin/rm -f  *.xpr
	-@/bin/rm -f  $(MODULE).ucf
	-@/bin/rm -f  $(MODULE).ut
	-@/bin/rm -f  $(MODULE).tcf
	-@/bin/rm -rf work
	-@/bin/rm -rf sim
	-@/bin/rm -rf src
	-@/bin/rm -rf xgui
	-@/bin/rm -rf bfm_axi_if.cache
	-@/bin/rm -rf bfm_axi_if.hw
	-@/bin/rm -rf bfm_axi_if.ip_user_files
	-@/bin/rm -rf bfm_axi_if.sim

cleanupall: cleanup

