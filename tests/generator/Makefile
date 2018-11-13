# This Makefile expects you've got UAL already built (using the installer), but not yet installed, so we're testing the current build.
# Until the testSuite is made modular (one test program per IDS), it is recommended to avoid running the IFORT case (huge source file, takes ages to compile)
# To detect if an error has been reported, search for "ERROR:" strings in the result file (fortraninterface/tests/generator/gfortran_testSuite.results)

include ../../../Makefile.common

ifeq (,$(UAL_BUILD))
$(error UAL_BUILD variable unset, are you sure you are running 'make ual_test' from the Installer? use Makefile-local to test a previously installed IMAS.)
endif

ifeq ("no","$(strip $(IMAS_FORTRAN))")
all sources sources_install install clean clean-src:
	$(warning "Ignoring fortraninterface (IMAS_FORTRAN=no).")
else
# Check that "saxon9he.jar" utility is set in CLASSPATH
SAXONICAJAR=$(wildcard $(filter %saxon9he.jar,$(subst :, ,$(CLASSPATH))))

#------------------------- gfortran ----------------------------
FC_gfortran = gfortran
COPTS_gfortran = -g -fdefault-real-8 -fPIC -fno-second-underscore -ffree-line-length-none -I$(UAL_BUILD)/include/gfortran
LIBS_gfortran = -L$(UAL_BUILD)/lib -limas-gfortran -limas -lm

#------------------------- ifort ----------------------------
FC_ifort = ifort
COPTS_ifort = -g -r8 -assume no2underscore  -fPIC -module $(UAL_BUILD)/include/ifort -shared-intel
LIBS_ifort = -L$(UAL_BUILD)/lib -limas-ifort -limas -lm


IDSDEF = $(UAL_BUILD)/xml/IDSDef.xml
ids_path = $(UAL_BUILD)/models/mdsplus


include Makefile.tests
endif # IMAS_FORTRAN
