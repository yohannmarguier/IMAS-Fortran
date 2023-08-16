# This Makefile expects you've got AL already built (using the installer), but not yet installed, so we're testing the current build.
# Until the testSuite is made modular (one test program per IDS), it is recommended to avoid running the IFORT case (huge source file, takes ages to compile)
# To detect if an error has been reported, search for "ERROR:" strings in the result file (fortraninterface/tests/generator/gfortran_testSuite.results)

include ../../../Makefile.common

ifeq (,$(AL_BUILD))
AL_BUILD=../../..
$(warning AL_BUILD variable unset, probably not running 'make al_test' from the Installer. Assuming AL_BUILD=$(AL_BUILD).)
endif

ifneq ("yes","$(strip $(IMAS_FORTRAN))")
all sources sources_install sources_uninstall install uninstall clean clean-src check test:
	$(warning "Ignoring fortraninterface (IMAS_FORTRAN=no).")
else

# Include OS-specific Makefile, if exists.
ifneq (,$(wildcard Makefile.$(SYSTEM)))
include Makefile.$(SYSTEM)
endif

IDSDEF = $(AL_BUILD)/xml/IDSDef.xml
ids_path = $(realpath $(AL_BUILD)/models/mdsplus)

# Test environment (mimics loaded imas environment), write ids to tmp dir
test_ENV = IMAS_AL_PLUGINS=$(AL_BUILD)/plugins LD_LIBRARY_PATH=$(AL_BUILD)/fortraninterface:$(AL_BUILD)/lowlevel:$$LD_LIBRARY_PATH ids_path="$$PWD/tmp;$(ids_path)" IMAS_DISABLE_VALIDATE=1

include Makefile.tests
endif # IMAS_FORTRAN
