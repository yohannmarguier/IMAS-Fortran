#!/bin/bash
# You should have already installed imas and loaded it (IMAS_PREFIX variable) before running "make test".
# Until the testSuite is made modular (one test program per IDS), it is recommended to avoid running the IFORT case (huge source file, takes ages to compile)
# To detect if an error has been reported, search for "ERROR:" strings in the result file (fortraninterface/tests/generator/gfortran_testSuite.results)

include ../../../Makefile.common

ifeq (,$(IMAS_PREFIX))
$(error Please supply a variable IMAS_PREFIX that is the prefix of your IMAS installation.)
endif

# Check that "saxon9he.jar" utility is set in CLASSPATH
SAXONICAJAR=$(wildcard $(filter %saxon9he.jar,$(subst :, ,$(CLASSPATH))))

#------------------------- gfortran ----------------------------
F90_gfortran = gfortran
COPTS_gfortran = -g -fdefault-real-8 -fPIC -fno-second-underscore -ffree-line-length-none -I$(IMAS_PREFIX)/include/gfortran
LIBS_gfortran = -L$(IMAS_PREFIX)/lib -limas-gfortran -limas -lm

#------------------------- ifort ----------------------------
F90_ifort = ifort
COPTS_ifort = -r8 -assume no2underscore  -fPIC -module $(IMAS_PREFIX)/include/ifort -shared-intel
LIBS_ifort = -L$(IMAS_PREFIX)/lib -limas-ifort -limas -lm


IDSDEF = $(IMAS_PREFIX)/include/IDSDef.xml
ids_path = $(IMAS_PREFIX)/models/mdsplus


ifeq "$(strip $(GFORTRAN))" "yes"
    TARGETS += gfortran_testSuite
    TESTS += gfortran_test
endif

ifeq "$(strip $(IFORT))" "yes"
    TARGETS += ifort_testSuite
    TESTS += ifort_test
endif


IFORT_BIN_DIR:=./bin/ifort
GFORTRAN_BIN_DIR:=./bin/gfortran
TEST_SRC_DIR=./src


# Get a list of IDS from IDSDEF file
IDSNAMES := $(shell sed '/<IDS name=/!d;s/.*name="\([^"]*\)".*/\1/' $(IDSDEF))
TEST_IDS_FILES = $(patsubst %,$(TEST_SRC_DIR)/%_test.f90,$(IDSNAMES))

TEST_FILES= helper.f90 comparator.f90 $(TEST_IDS_FILES)

IFORT_BIN_FILES=$(patsubst %.f90,$(IFORT_BIN_DIR)/%.exe,$(notdir $(TEST_IDS_FILES)))
GFORTRAN_BIN_FILES=$(patsubst %.f90,$(GFORTRAN_BIN_DIR)/%.exe,$(notdir $(TEST_IDS_FILES)))

# Sets a path where make will search for files
VPATH = ./src $(TEST_SRC_DIR) 




all :   $(TARGETS)

# Test if all generated sources are found to exist as files to
# gracefully skip generation if not needed.
ifeq ($(words $(TEST_IDS_FILES)), $(words $(wildcard $(TEST_IDS_FILES))))
$(TEST_IDS_FILES):
else
$(TEST_IDS_FILES): sources
endif


.PHONY: clean clean-src
clean: ifort_clean gfortran_clean
	rm -rf build *~ *.o *.mod
	rm -rf idspath-*
	rm -rf *.results

clean-src: clean
	rm -rf $(TEST_IDS_FILES) 


#################################################
#                 INIT: SOURCE GENERATION
#################################################
sources: IDSDef2TestSuite.xsl $(IDSDEF)
	mkdir -p $(IFORT_BIN_DIR)
	mkdir -p $(GFORTRAN_BIN_DIR)

ifeq (,$(SAXONICAJAR))
	$(error Invalid /path/to/saxon9he.jar in CLASSPATH. Forgot to load module?)
endif
	java net.sf.saxon.Transform newLowLevel=$(NEW_LOW_LEVEL) -t -s:$(IDSDEF) -xsl:IDSDef2TestSuite.xsl   


#################################################
#              BUILD
#################################################

#------------------------- gfortran ----------------------------
.PHONY: gfortran_clean
gfortran_clean:
	rm -rf ${GFORTRAN_BIN_DIR}

gfortran_helper.o: helper.f90
	$(F90_gfortran) $(COPTS_gfortran) -c $< -o $@

gfortran_comparator.o: comparator.f90
	$(F90_gfortran) $(COPTS_gfortran) -c $< -o $@

gfortran_testSuite:  $(GFORTRAN_BIN_FILES)

$(GFORTRAN_BIN_FILES): $(GFORTRAN_BIN_DIR)/%.exe : $(TEST_SRC_DIR)/%.f90 gfortran_helper.o gfortran_comparator.o
	$(F90_gfortran) $(COPTS_gfortran) -o $@ $< gfortran_helper.o gfortran_comparator.o $(LIBS_gfortran)


#------------------------- ifort ----------------------------
.PHONY: ifort_clean
ifort_clean:
	rm -rf ${IFORT_BIN_DIR}

ifort_helper.o: helper.f90
	$(F90_ifort) $(COPTS_ifort) -c $< -o $@

ifort_comparator.o: comparator.f90
	$(F90_ifort) $(COPTS_ifort) -c $< -o $@

ifort_testSuite: $(IFORT_BIN_FILES)


$(IFORT_BIN_FILES): $(IFORT_BIN_DIR)/%.exe: $(TEST_SRC_DIR)/%.f90 ifort_helper.o ifort_comparator.o
	$(F90_ifort) $(COPTS_ifort) -o $@ $< ifort_helper.o ifort_comparator.o $(LIBS_ifort)

#################################################
#              TEST
#################################################
:.PHONY: test ifort_test gfortran_test

%_test: %_testSuite
	./test.sh -c $* | tee test_$*.results 

test : $(TESTS)



