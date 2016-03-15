#!/bin/bash

include ../../../Makefile.common

ifeq (,$(INSTALL))
$(error Please supply a variable INSTALL that is the prefix of your IMAS installation.)
endif

#------------------------- gfortran ----------------------------
F90_gfortran = gfortran
COPTS_gfortran = -g -fdefault-real-8 -fPIC -fno-second-underscore -ffree-line-length-none -I$(INSTALL)/fortraninterface/gfortran
LIBS_gfortran = -L$(INSTALL)/lib -limas-gfortran -limas -lm

#------------------------- ifort ----------------------------
F90_ifort = ifort
COPTS_ifort = -r8 -assume no2underscore  -fPIC -module $(INSTALL)/fortraninterface/ifort -shared-intel
LIBS_ifort = -L$(INSTALL)/lib -limas-ifort -limas -lm


IDSDEF = $(UAL)/xml/IDSDef.xml
ids_path = $(UAL)/models/mdsplus


ifeq "$(strip $(GFORTRAN))" "yes"
    TARGETS += gfortran_testSuite
endif

ifeq "$(strip $(IFORT))" "yes"
    TARGETS += ifort_testSuite
endif

all : testSuite.f90 comp

.PHONY: clean clean-src
clean: ifort_clean gfortran_clean
	rm -rf build *~ *.o *.mod

clean-src: clean
	rm -f testSuite.f90

testSuite.f90: IDSDef2TestSuite.xsl
	xsltproc IDSDef2TestSuite.xsl $(IDSDEF)  > testSuite.f90

comp: $(TARGETS)

.PHONY: test ifort_test gfortran_test
cmd_test = ( cp -av $(ids_path) idspath-$@ ; \
	export LD_LIBRARY_PATH=$(INSTALL)/lib:$$LD_LIBRARY_PATH \
		ids_path=$$PWD/idspath-$@ \
		ual_debug=yes; \
	./$@Suite | tee $@Suite.results )

gfortran_test: testSuite.f90 comp
	$(call cmd_test)

ifort_test: testSuite.f90 comp
	$(call cmd_test)

test : gfortran_test ifort_test

#------------------------- gfortran ----------------------------
.PHONY: gfortran_clean
gfortran_clean:
	rm -rf gfortran_testSuite

gfortran_helper.o: helper.f90
	$(F90_gfortran) $(COPTS_gfortran) -c $< -o $@

gfortran_comparator.o: comparator.f90
	$(F90_gfortran) $(COPTS_gfortran) -c $< -o $@

gfortran_testSuite: testSuite.f90 gfortran_helper.o gfortran_comparator.o
	$(F90_gfortran) $(COPTS_gfortran) -o $@ $^ $(LIBS_gfortran)

#------------------------- ifort ----------------------------
.PHONY: ifort_clean
ifort_clean:
	rm -rf ifort_testSuite

ifort_helper.o: helper.f90
	$(F90_ifort) $(COPTS_ifort) -c $< -o $@

ifort_comparator.o: comparator.f90
	$(F90_ifort) $(COPTS_ifort) -c $< -o $@

ifort_testSuite: testSuite.f90 ifort_helper.o ifort_comparator.o
	$(F90_ifort) $(COPTS_ifort) -o $@ $^ $(LIBS_ifort)

