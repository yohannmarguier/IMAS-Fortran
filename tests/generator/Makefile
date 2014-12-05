#!/bin/bash
UAL_BUILD_DIR=$(shell cd ../../..; pwd )

include $(UAL_BUILD_DIR)/Makefile.common

#------------------------------- gfortran ----------------------------------
F90_gfortran      = gfortran
COPTS_gfortran    = -g -fdefault-real-8 -fPIC -fno-second-underscore -ffree-line-length-none -Jamd64_gfortran
INCDIR_gfortran   = -I$(UAL_BUILD_DIR)/fortraninterface/amd64_gfortran  -Iamd64_gfortran
LIBS_gfortran     = -Wl,-rpath,$(UAL_BUILD_DIR)/lib -L$(UAL_BUILD_DIR)/fortraninterface -lUALFORTRANInterface_gfortran 

F90_ifort       = ifort
COPTS_ifort     = -r8 -O0 -assume no2underscore  -fPIC -module amd64_ifort -shared-intel
INCDIR_ifort    = -I$(UAL_BUILD_DIR)/fortraninterface/amd64_ifort
LIBS_ifort      = -Wl,-rpath,$(UAL_BUILD_DIR)/lib -L$(UAL_BUILD_DIR)/fortraninterface -lUALFORTRANInterface_ifort 

IDSDEF= $(UAL_BUILD_DIR)/xml/IDSDef.xml
ids_path := $(UAL_BUILD_DIR)/models/mdsplus
LD_LIBRARY_PATH :=  $(UAL_BUILD_DIR)/lowlevel:$(UAL_BUILD_DIR)/fortraninterface:$(LD_LIBRARY_PATH)


ifeq "$(strip $(GFORTRAN))" "yes"
    TARGETS += gfortran_testSuite
endif

ifeq "$(strip $(IFORT))" "yes"
    TARGETS += ifort_testSuite
endif

all : testSuite.f90 comp 
	
clean: ifort_clean gfortran_clean
	rm -rf build *~ *.o *.mod
	
clean-src: clean
	rm -f testSuite.f90
	
testSuite.f90: IDSDef2TestSuite.xsl  
	xsltproc IDSDef2TestSuite.xsl $(IDSDEF)  > testSuite.f90

comp: $(TARGETS)

.PHONY: ifort_clean ifort_prep test comp clean
	
#test: export ids_path = $(UAL_BUILD_DIR)/models/mdsplus
test: testSuite.f90 comp 
	ids_path=$(ids_path) ./gfortran_testSuite
	ids_path=$(ids_path) ./ifort_testSuite

#------------------------- gfortran ----------------------------
gfortran_clean: 
	rm -rf gfortran_testSuite amd64_gfortran

gfortran_helper.o: helper.f90
	mkdir -p amd64_gfortran
	$(F90_gfortran) $(COPTS_gfortran) $(INCDIR_gfortran) -c $< -o $@ 

gfortran_comparator.o: comparator.f90
	mkdir -p amd64_gfortran
	$(F90_gfortran) $(COPTS_gfortran) $(INCDIR_gfortran) -c $< -o $@ 

gfortran_testSuite: testSuite.f90 gfortran_helper.o gfortran_comparator.o
	mkdir -p amd64_gfortran
	$(F90_gfortran) $(COPTS_gfortran)  $(INCDIR_gfortran) -o $@ $^ $(LIBS_gfortran)

#------------------------- ifort ----------------------------
ifort_clean: 
	rm -rf ifort_testSuite amd64_ifort

ifort_helper.o: helper.f90
	mkdir -p amd64_ifort
	$(F90_ifort) $(COPTS_ifort) $(INCDIR_ifort) -c $< -o $@ 

ifort_comparator.o: comparator.f90
	mkdir -p amd64_ifort
	$(F90_ifort) $(COPTS_ifort) $(INCDIR_ifort) -c $< -o $@ 

ifort_testSuite: testSuite.f90 ifort_helper.o ifort_comparator.o
	mkdir -p amd64_ifort
	$(F90_ifort) $(COPTS_ifort)  $(INCDIR_ifort) -o $@ $^ $(LIBS_ifort)

