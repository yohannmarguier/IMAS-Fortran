# This Makefile expects you've got UAL already built (using the installer), but not yet installed, so we're testing the current build.
# Until the testSuite is made modular (one test program per IDS), it is recommended to avoid running the IFORT case (huge source file, takes ages to compile)
# To detect if an error has been reported, search for "ERROR:" strings in the result file (fortraninterface/tests/generator/gfortran_testSuite.results)

include ../../../Makefile.common

ifeq (,$(UAL_BUILD))
UAL_BUILD=../../..
$(warning UAL_BUILD variable unset, probably not running 'make ual_test' from the Installer. Assuming UAL_BUILD=$(UAL_BUILD).)
endif

ifeq ("no","$(strip $(IMAS_FORTRAN))")
all sources sources_install install clean clean-src:
	$(warning "Ignoring fortraninterface (IMAS_FORTRAN=no).")
else

#------------------------- gfortran ----------------------------
FC_gfortran = gfortran
COPTS_gfortran = -g -fdefault-real-8 -fPIC -fno-second-underscore -ffree-line-length-none -I$(UAL_BUILD)/fortraninterface/gfortran
LIBS_gfortran = -L$(UAL_BUILD)/lowlevel -L$(UAL_BUILD)/fortraninterface -limas-gfortran -limas -lm

#------------------------- ifort ----------------------------
FC_ifort = ifort
COPTS_ifort = -g -r8 -assume no2underscore  -fPIC -I$(UAL_BUILD)/fortraninterface/ifort -shared-intel
LIBS_ifort = -L$(UAL_BUILD)/lowlevel -L$(UAL_BUILD)/fortraninterface -limas-ifort -limas -lm


IDSDEF = $(UAL_BUILD)/xml/IDSDef.xml
ids_path = $(realpath $(UAL_BUILD)/models/mdsplus)

# Test environment (mimics loaded imas environment), write ids to tmp dir
test_ENV = LD_LIBRARY_PATH=$(UAL_BUILD)/fortraninterface:$(UAL_BUILD)/lowlevel:$$LD_LIBRARY_PATH ids_path="$$PWD/tmp;$(ids_path)"

include Makefile.tests
endif # IMAS_FORTRAN
