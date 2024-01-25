# This Makefile expects you've got AL already built (e.g. using the installer), but not yet installed, so we're testing the current build.

include ../../Makefile.common

ifneq ("yes","$(strip $(IMAS_FORTRAN))")
all sources sources_install sources_uninstall install uninstall clean clean-src check test:
	$(warning "Ignoring examples/dd-v3/fortran (IMAS_FORTRAN=no).")
else

ifeq (,$(AL_BUILD))
AL_BUILD=../..
$(warning AL_BUILD variable unset, probably not running 'make al_examples' from the Installer. Assuming AL_BUILD=$(AL_BUILD).)
endif

LIBS    = -L$(AL_BUILD)/fortraninterface -lal-fortran -L$(AL_BUILD)/lowlevel -lal

# Include OS-specific Makefile, if exists.
ifneq (,$(wildcard Makefile.$(SYSTEM)))
include Makefile.$(SYSTEM)
endif


ifeq ("yes","$(strip $(IMAS_GFORTRAN))")
FCFLAGS ?= -g -cpp -fdefault-real-8 -fPIC -fno-second-underscore -ffree-line-length-none -I$(AL_BUILD)/fortraninterface/include
else ifeq ("yes","$(strip $(IMAS_IFORT))")
FCFLAGS ?= -g -r8 -fpp -assume no2underscore  -fPIC -module $(AL_BUILD)/fortraninterface/include -shared-intel
else ifeq ("yes","$(strip $(IMAS_NVFORTRAN))")
FCFLAGS ?= -g -r8 -Mpreprocess -Mnosecond_underscore -fPIC -module=$(AL_BUILD)/fortraninterface/include
else ifeq ("yes","$(strip $(IMAS_NAGFOR))")
FCFLAGS ?= -g -free -fpp -kind=byte -r8 -PIC -I$(AL_BUILD)/fortraninterface/include
else ifeq ("yes","$(strip $(IMAS_G95))")
FCFLAGS ?= -g -r8 -ftrace=full -fPIC -fno-second-underscore -ffree-line-length-huge -I$(AL_BUILD)/fortraninterface/include
else
SOURCES_ONLY=yes
endif


IDSDEF = $(AL_BUILD)/xml/IDSDef.xml
ids_path = $(realpath $(AL_BUILD)/models/mdsplus)

# Test environment (mimics loaded imas environment), write ids to tmp dir
TMPDIR = tmp
test_with_plugins_ENV = IMAS_AL_ENABLE_PLUGINS=TRUE IMAS_AL_PLUGINS=${IMAS_AL_PLUGINS}  LD_LIBRARY_PATH=$(AL_BUILD)/fortraninterface:$(AL_BUILD)/lowlevel:$$LD_LIBRARY_PATH ids_path="$(abspath $(TMPDIR));$(ids_path)"
test_without_plugins_ENV = IMAS_AL_ENABLE_PLUGINS=FALSE IMAS_AL_PLUGINS=${IMAS_AL_PLUGINS}  LD_LIBRARY_PATH=$(AL_BUILD)/fortraninterface:$(AL_BUILD)/lowlevel:$$LD_LIBRARY_PATH ids_path="$(abspath $(TMPDIR));$(ids_path)"

checkenv:
	echo $(IMAS_GFORTRAN) $(FC) $(FCFLAGS)

include Makefile.tests
endif # IMAS_FORTRAN
