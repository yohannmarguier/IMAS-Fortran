# This Makefile expects you've got UAL already built (using the installer), but not yet installed, so we're testing the current build.
# Until the testSuite is made modular (one test program per IDS), it is recommended to avoid running the IFORT case (huge source file, takes ages to compile)
# To detect if an error has been reported, search for "ERROR:" strings in the result file (fortraninterface/tests/generator/gfortran_testSuite.results)

include ../../../Makefile.common

ifeq (,$(UAL_BUILD))
UAL_BUILD=../../..
$(warning UAL_BUILD variable unset, probably not running 'make ual_test' from the Installer. Assuming UAL_BUILD=$(UAL_BUILD).)
endif

ifeq ("no","$(strip $(IMAS_FORTRAN))")
all sources sources_install install clean clean-src check test:
	$(warning "Ignoring fortraninterface (IMAS_FORTRAN=no).")
else

#------------------------- gfortran ----------------------------
FC_gfortran = gfortran
COPTS_gfortran = -g -fdefault-real-8 -fPIC -fno-second-underscore -ffree-line-length-none -I$(UAL_BUILD)/fortraninterface/gfortran
ifneq ("no","$(strip $(SYS_WIN))")
	LIBS_gfortran = -L$(UAL_BUILD)/lowlevel -L$(UAL_BUILD)/fortraninterface $(UAL_BUILD)/fortraninterface/libimas-gfortran.lib $(UAL_BUILD)/lowlevel/libimas.lib -lm -lstdc++
else
	LIBS_gfortran = -L$(UAL_BUILD)/lowlevel -L$(UAL_BUILD)/fortraninterface -limas-gfortran -limas -lm
endif

ifneq ("no","$(strip $(IMAS_MDSPLUS))")
	ifneq ("no","$(strip $(SYS_WIN))")
		LIBS_gfortran+= -L$(MDSPLUS_DIR)/lib
		LIBS_gfortran+= $(MDSPLUS_DIR)/lib/XTreeShr.a
		LIBS_gfortran+= $(MDSPLUS_DIR)/lib/MdsObjectsCppShr.a
		LIBS_gfortran+= $(MDSPLUS_DIR)/lib/TdiShr.a
		LIBS_gfortran+= $(MDSPLUS_DIR)/lib/TreeShr.a
		LIBS_gfortran+= $(MDSPLUS_DIR)/lib/MdsIpShr.a
		LIBS_gfortran+= $(MDSPLUS_DIR)/lib/MdsShr.a
		LIBS_gfortran+= -lxml2 -lws2_32 -ldl -liphlpapi -lstdc++
	else
		LIBS_gfortran+= -L$(MDSPLUS_DIR)/lib64 -L$(MDSPLUS_DIR)/lib
		LIBS_gfortran+= -lMdsShr -lTreeShr -lTdiShr -lMdsLib -lMdsIpShr -lMdsObjectsCppShr -lXTreeShr
	endif
endif

ifneq ("no","$(strip $(IMAS_UDA))")
	ifneq ("no","$(strip $(SYS_WIN))")
		LIBS_gfortran+= -L$(UDA_HOME)/lib
		LIBS_gfortran+= $(UDA_HOME)/lib/libuda_cpp.a
		LIBS_gfortran+= $(UDA_HOME)/lib/libportablexdr.a
		LIBS_gfortran+= -lws2_32 -lssl -lcrypto -lstdc++
	else
		LIBS_gfortran+= `pkg-config --libs uda-cpp`
		LIBS_gfortran+= -lssl -lcrypto
	endif
endif

ifneq ("no","$(strip $(IMAS_HDF5))")
	ifneq ("no","$(strip $(SYS_WIN))")
		LIBS_gfortran+= -L$(HDF5_HOME)/lib
		LIBS_gfortran+= $(HDF5_HOME)/lib/libhdf5.a -ldl -lz
	else
		LIBS_gfortran+= -L$(HDF5_HOME)/lib
		LIBS_gfortran+= -lhdf5 -ldl -lz -lstdc++
	endif
endif


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
