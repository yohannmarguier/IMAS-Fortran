# -*- makefile -*- #
include ../Makefile.common

ifeq ("no","$(strip $(IMAS_FORTRAN))")
all sources sources_install install clean clean-src:
	$(warning "Ignoring fortraninterface (IMAS_FORTRAN=no).")
else

ifneq ("no","$(strip $(SYS_WIN))")
ifneq ("no","$(strip $(IMAS_G95))")
	$(error "Ignoring fortraninterface for Windows (IMAS_G95=yes).")
endif
ifneq ("no","$(strip $(IMAS_PGI))")
	$(error "Ignoring fortraninterface for Windows (IMAS_PGI=yes).")
endif
ifneq ("no","$(strip $(IMAS_IFORT))")
	$(error "Ignoring fortraninterface for Windows (IMAS_IFORT=yes).")
endif
endif

export IMAS_PREFIX=$(UAL)

ifeq (,$(wildcard $(IMAS_PREFIX)))
$(error $$IMAS_PREFIX is unset)
endif


FC_g95			= g95
MODDIR_g95		= g95
COPTS_g95		= -D__USE_XOPEN2K8 -r8 -ftrace=full -fPIC -fno-second-underscore -ffree-line-length-huge -g -fmod=$(MODDIR_g95)
INCDIR_g95		= -I$(MODDIR_g95)

FC_gfortran		= gfortran
MODDIR_gfortran = gfortran
COPTS_gfortran	= -O0 -D__USE_XOPEN2K8 -fdefault-real-8 -fdefault-double-8 -fPIC -fno-second-underscore -ffree-line-length-none -g -J$(MODDIR_gfortran)
INCDIR_gfortran	= -I$(MODDIR_gfortran)

FC_pgi			= pgf90
MODDIR_pgi		= pgi
COPTS_pgi		= -D__USE_XOPEN2K8 -r8 -Mnosecond_underscore -fPIC -module=./$(MODDIR_pgi) -g
INCDIR_pgi		= -I$(MODDIR_pgi)

FC_ifort		= ifort
MODDIR_ifort	= ifort
COPTS_ifort		= -r8 -O0 -assume no2underscore -fPIC -module $(MODDIR_ifort) -g -shared-intel
INCDIR_ifort	= -I$(MODDIR_ifort)

IDSDEF		  = ../xml/IDSDef.xml

# Windows
ifneq ("no","$(strip $(SYS_WIN))")
	LIBS		= $(IMAS_PREFIX)/lib/libimas.lib
	LIBS		+= -lm -lstdc++
	JAVA		= $(JAVA_HOME)/bin/java
	IDSDEFXSD   = dd_data_dictionary.xml.xsd
else
	LIBS		= -L../lowlevel -limas -lm
	JAVA		= java
	IDSDEFXSD   = dd_physics_data_dictionary.xsd
endif

ifneq ("no","$(strip $(IMAS_MDSPLUS))")
	ifneq ("no","$(strip $(SYS_WIN))")
		LIBS	+= -L$(MDSPLUS_DIR)/lib
		LIBS	+= $(MDSPLUS_DIR)/lib/XTreeShr.a
		LIBS	+= $(MDSPLUS_DIR)/lib/MdsObjectsCppShr.a
		LIBS	+= $(MDSPLUS_DIR)/lib/MdsIpShr.a
		LIBS	+= $(MDSPLUS_DIR)/lib/MdsLib.a
		LIBS	+= $(MDSPLUS_DIR)/lib/TdiShr.a
		LIBS	+= $(MDSPLUS_DIR)/lib/TreeShr.a
		LIBS	+= $(MDSPLUS_DIR)/lib/MdsShr.a
		LIBS	+= -lxml2 -lws2_32 -ldl -liphlpapi -lstdc++
	else
		LIBS	+= -L$(MDSPLUS_DIR)/lib64 -L$(MDSPLUS_DIR)/lib
		LIBS	+= -lMdsShr -lTreeShr -lTdiShr -lMdsLib -lMdsIpShr -lMdsObjectsCppShr -lXTreeShr
	endif
endif

ifneq ("no","$(strip $(IMAS_UDA))")
	ifneq ("no","$(strip $(SYS_WIN))")
		LIBS	+= -L$(UDA_HOME)/lib
		LIBS	+= $(UDA_HOME)/lib/libuda_cpp.a
		LIBS	+= $(UDA_HOME)/lib/libportablexdr.a
		LIBS	+= -lws2_32 -lssl -lcrypto -lstdc++
	else
		LIBS	+= `pkg-config --libs uda-cpp`
		LIBS	+= -lssl -lcrypto
	endif
endif

ifneq ("no","$(strip $(IMAS_HDF5))")
	ifneq ("no","$(strip $(SYS_WIN))")
		LIBS	+= -L$(HDF5_HOME)/lib
		LIBS	+= $(HDF5_HOME)/lib/libhdf5.a -ldl -lz -lstdc++
	else
		LIBS	+= -L$(HDF5_HOME)/lib
		LIBS	+= -lhdf5 -ldl -lz
	endif
endif


# Get a list of IDS from IDSDEF file
IDSNAMES := $(shell sed '/<IDS name=/!d;s/.*name="\([^"]*\)".*/\1/' $(IDSDEF))

IDSNAMES_FUNC=$(addsuffix _copy_struct,$(IDSNAMES))
IDSNAMES_FUNC+=$(addsuffix _deallocate_struct,$(IDSNAMES))
IDSNAMES_FUNC+=$(addsuffix _delete,$(IDSNAMES))
IDSNAMES_FUNC+=$(addsuffix _put,$(IDSNAMES))
IDSNAMES_FUNC+=$(addsuffix _put_slice,$(IDSNAMES))
IDSNAMES_FUNC+=$(addsuffix _get,$(IDSNAMES))
IDSNAMES_FUNC+=$(addsuffix _get_slice,$(IDSNAMES))

# IDS routines
IDSROUTINES=$(addsuffix .f90,$(IDSNAMES_FUNC))
SOURCES=ids_routines.f90 utilities_copy_struct.f90 utilities_deallocate_struct.f90 utilities_put_struct.f90 utilities_put_slice_struct.f90 utilities_get_struct.f90 $(IDSROUTINES)

# pkg-config files
PC_FILES=

# SONAME extension
SOEXT3=.so.$(IMAS_MAJOR).$(IMAS_MINOR).$(IMAS_MICRO)
SOEXT2=.so.$(IMAS_MAJOR).$(IMAS_MINOR)
SOEXT1=.so.$(IMAS_MAJOR)

ifneq ("no","$(strip $(IMAS_G95))")
TARGETS += libimas-g95.so libimas-g95.a
PC_FILES += imas-g95.pc
INSTALL_TARGETS += g95
IDSOBJECTS_g95=$(addsuffix _g95.o,$(IDSNAMES_FUNC))
endif

ifneq ("no","$(strip $(IMAS_GFORTRAN))")
ifneq ("no","$(strip $(SYS_WIN))")
	TARGETS += libimas-gfortran.dll libimas-gfortran.lib
else
	TARGETS += libimas-gfortran.so libimas-gfortran.a
endif
INSTALL_TARGETS += gfortran
IDSOBJECTS_gfortran=$(addsuffix _gfortran.o,$(IDSNAMES_FUNC))
endif

ifneq ("no","$(strip $(IMAS_PGI))")
TARGETS += libimas-pgi.so libimas-pgi.a
PC_FILES += imas-pgi.pc
INSTALL_TARGETS += pgi
IDSOBJECTS_pgi=$(addsuffix _pgi.o,$(IDSNAMES_FUNC))
endif

ifneq ("no","$(strip $(IMAS_IFORT))")
TARGETS += libimas-ifort.so libimas-ifort.a
PC_FILES += imas-ifort.pc
INSTALL_TARGETS += ifort
IDSOBJECTS_ifort=$(addsuffix _ifort.o,$(IDSNAMES_FUNC))
endif

# Concatenated list
IDSOBJECTS=$(IDSOBJECTS_g95) $(IDSOBJECTS_gfortran) $(IDSOBJECTS_pgi) $(IDSOBJECTS_ifort)

all: $(SOURCES) $(TARGETS)

install: all $(addprefix install_,$(INSTALL_TARGETS)) pkgconfig_install

sources: $(SOURCES) ids_schemas.f90
sources_install: $(SOURCES) ids_schemas.f90
ifeq ("no","$(strip $(SYS_WIN))")
	$(mkdir_p) $(datadir)/src/fortraninterface
	$(INSTALL_DATA) $^ $(datadir)/src/fortraninterface
endif

install_pgi: $(IDSOBJECTS_pgi) libimas-pgi.a libimas-pgi.so
	$(mkdir_p) $(includedir)/pgi
	$(INSTALL_DATA) pgi/*.mod $(includedir)/pgi
	$(mkdir_p) $(libdir)
	$(INSTALL_DATA) $(addprefix libimas-pgi,.a $(SOEXT3)) $(libdir)
	ln -svfT libimas-pgi$(SOEXT3) $(libdir)/libimas-pgi$(SOEXT2)
	ln -svfT libimas-pgi$(SOEXT3) $(libdir)/libimas-pgi$(SOEXT1)
	ln -svfT libimas-pgi$(SOEXT3) $(libdir)/libimas-pgi.so
install_g95: $(IDSOBJECTS_g95) libimas-g95.a libimas-g95.so
	$(mkdir_p) $(includedir)/g95
	$(INSTALL_DATA) g95/*.mod $(includedir)/g95
	$(mkdir_p) $(libdir)
	$(INSTALL_DATA) $(addprefix libimas-g95,.a $(SOEXT3)) $(libdir)
	ln -svfT libimas-g95$(SOEXT3) $(libdir)/libimas-g95$(SOEXT2)
	ln -svfT libimas-g95$(SOEXT3) $(libdir)/libimas-g95$(SOEXT1)
	ln -svfT libimas-g95$(SOEXT3) $(libdir)/libimas-g95.so
install_ifort: $(IDSOBJECTS_ifort) libimas-ifort.a libimas-ifort.so
	$(mkdir_p) $(includedir)/ifort
	$(INSTALL_DATA) ifort/*.mod $(includedir)/ifort
	$(mkdir_p) $(libdir)
	$(INSTALL_DATA) $(addprefix libimas-ifort,.a $(SOEXT3)) $(libdir)
	ln -svfT libimas-ifort$(SOEXT3) $(libdir)/libimas-ifort$(SOEXT2)
	ln -svfT libimas-ifort$(SOEXT3) $(libdir)/libimas-ifort$(SOEXT1)
	ln -svfT libimas-ifort$(SOEXT3) $(libdir)/libimas-ifort.so
install_gfortran: $(IDSOBJECTS_gfortran) libimas-gfortran.a libimas-gfortran.so
ifeq ("no","$(strip $(SYS_WIN))")
	$(mkdir_p) $(includedir)/gfortran
	$(INSTALL_DATA) gfortran/*.mod $(includedir)/gfortran
	$(mkdir_p) $(libdir)
	$(INSTALL_DATA) $(addprefix libimas-gfortran,.a $(SOEXT3)) $(libdir)
	ln -svfT libimas-gfortran$(SOEXT3) $(libdir)/libimas-gfortran$(SOEXT2)
	ln -svfT libimas-gfortran$(SOEXT3) $(libdir)/libimas-gfortran$(SOEXT1)
	ln -svfT libimas-gfortran$(SOEXT3) $(libdir)/libimas-gfortran.so
else
	$(mkdir_p) $(packagedir)/fortraninterface/include
	cp gfortran/*.mod $(packagedir)/fortraninterface/include
	$(mkdir_p) $(packagedir)/fortraninterface/lib
	for OBJECT in `find . -type f \( -name "*.lib" -or -name "*.dll" \)`; do \
		cp $$OBJECT $(packagedir)/fortraninterface/lib; \
	done
endif


clean:
	$(RM) -r *.o *.mod *.so *~ g95/ gfortran/ pgi/ ifort/ *.a *.lib *.dll

clean-src: clean
	$(RM) $(SOURCES)
	$(RM) ids_schemas.f90  

test:
	$(MAKE) -C tests/generator test

test-clean:
	$(MAKE) -C tests/generator clean

test-clean-src:
	$(MAKE) -C tests/generator clean-src

libimas-g95.so libimas-gfortran.so libimas-pgi.so libimas-ifort.so: %.so:%$(SOEXT3)
	ln -svfT $*$(SOEXT3) $@

#--------------------- g95 --------------
libimas-g95$(SOEXT3): %$(SOEXT3): ids_schemas_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o utilities_copy_struct_g95.o utilities_deallocate_struct_g95.o utilities_put_struct_g95.o utilities_put_slice_struct_g95.o utilities_get_struct_g95.o $(IDSOBJECTS_g95) ids_routines_g95.o $(DEP_g95)
	$(FC_g95) $(COPTS_g95) -o $@ -shared -Wl,-soname,$*$(SOEXT2) $^ $(LIBS)
	ln -svfT $@ $*$(SOEXT2)

libimas-g95.a: ids_schemas_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o utilities_copy_struct_g95.o utilities_deallocate_struct_g95.o utilities_put_struct_g95.o utilities_put_slice_struct_g95.o utilities_get_struct_g95.o $(IDSOBJECTS_g95) ids_routines_g95.o $(DEP_g95)
	$(AR) rvs $@ $^

ids_routines_g95.o: ids_routines.f90 ual_defs_g95.o ual_low_level_wrap_g95.o utilities_copy_struct_g95.o utilities_deallocate_struct_g95.o utilities_put_struct_g95.o utilities_put_slice_struct_g95.o utilities_get_struct_g95.o $(IDSOBJECTS_g95)
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) ids_routines.f90 -o $@

ual_defs_g95.o: %_g95.o:wrapper/%.f90
	$(mkdir_p) $(MODDIR_g95)
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
ual_low_level_wrap_g95.o: %_g95.o:wrapper/%.f90 ual_defs_g95.o
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
ids_schemas_g95.o: %_g95.o:%.f90 ual_defs_g95.o
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
utilities_copy_struct_g95.o: utilities_copy_struct.f90 ids_schemas_g95.o 
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
utilities_deallocate_struct_g95.o: utilities_deallocate_struct.f90 ids_schemas_g95.o 
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
utilities_put_struct_g95.o : utilities_put_struct.f90 ids_schemas_g95.o 
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
utilities_put_slice_struct_g95.o : utilities_put_slice_struct.f90 ids_schemas_g95.o 
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
utilities_get_struct_g95.o : utilities_get_struct.f90 ids_schemas_g95.o 
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@

$(filter %_put_g95.o,$(IDSOBJECTS)): %_put_g95.o : %_put.f90 %_delete_g95.o ids_schemas_g95.o utilities_put_struct_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
$(filter %_put_slice_g95.o,$(IDSOBJECTS)): %_put_slice_g95.o : %_put_slice.f90 ids_schemas_g95.o utilities_put_slice_struct_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
$(filter %_get_g95.o,$(IDSOBJECTS)): %_get_g95.o:%_get.f90 ids_schemas_g95.o utilities_get_struct_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
$(filter %_get_slice_g95.o,$(IDSOBJECTS)): %_get_slice_g95.o:%_get_slice.f90 ids_schemas_g95.o utilities_get_struct_g95.o %_get_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
$(filter %_delete_g95.o,$(IDSOBJECTS)): %_g95.o:%.f90 ids_schemas_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
$(filter %_copy_struct_g95.o,$(IDSOBJECTS)): %_g95.o:%.f90 ids_schemas_g95.o utilities_copy_struct_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
$(filter %_deallocate_struct_g95.o,$(IDSOBJECTS)): %_g95.o:%.f90 ids_schemas_g95.o utilities_deallocate_struct_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@

#--------------------- gfortran --------------
libimas-gfortran$(SOEXT3): %$(SOEXT3): ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o utilities_copy_struct_gfortran.o utilities_deallocate_struct_gfortran.o utilities_put_struct_gfortran.o utilities_put_slice_struct_gfortran.o utilities_get_struct_gfortran.o $(IDSOBJECTS_gfortran) ids_routines_gfortran.o $(DEP_gfortran)
	$(FC_gfortran) $(COPTS_gfortran) -o $@ -shared -Wl,-soname,$*$(SOEXT2) $^ $(LIBS)
	ln -svfT $@ $*$(SOEXT2)

libimas-gfortran.a: ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o utilities_copy_struct_gfortran.o utilities_deallocate_struct_gfortran.o utilities_put_struct_gfortran.o utilities_put_slice_struct_gfortran.o utilities_get_struct_gfortran.o $(IDSOBJECTS_gfortran) ids_routines_gfortran.o $(DEP_gfortran)
	$(AR) rvs $@ $^

libimas-gfortran.dll: ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o utilities_copy_struct_gfortran.o utilities_deallocate_struct_gfortran.o utilities_put_struct_gfortran.o utilities_put_slice_struct_gfortran.o utilities_get_struct_gfortran.o $(IDSOBJECTS_gfortran) ids_routines_gfortran.o $(DEP_gfortran)
	$(FC_gfortran) $(COPTS_gfortran) -o $@ -shared -Wl,-soname,$@.$(IMAS_MAJOR).$(IMAS_MINOR) -Wl,--out-implib,$@.lib $^ $(LIBS)

libimas-gfortran.lib: ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o utilities_copy_struct_gfortran.o utilities_deallocate_struct_gfortran.o utilities_put_struct_gfortran.o utilities_put_slice_struct_gfortran.o utilities_get_struct_gfortran.o $(IDSOBJECTS_gfortran) ids_routines_gfortran.o $(DEP_gfortran)
	$(AR) rcvsu $@ $^
	ranlib $@

ids_routines_gfortran.o: ids_routines.f90 ual_defs_gfortran.o ual_low_level_wrap_gfortran.o utilities_copy_struct_gfortran.o utilities_deallocate_struct_gfortran.o utilities_put_struct_gfortran.o utilities_put_slice_struct_gfortran.o utilities_get_struct_gfortran.o $(IDSOBJECTS_gfortran)
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) ids_routines.f90 -o $@

ual_defs_gfortran.o: %_gfortran.o:wrapper/%.f90
	$(mkdir_p) $(MODDIR_gfortran)
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
ual_low_level_wrap_gfortran.o: %_gfortran.o:wrapper/%.f90 ual_defs_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
ids_schemas_gfortran.o: %_gfortran.o:%.f90 ual_defs_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
utilities_copy_struct_gfortran.o: utilities_copy_struct.f90 ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
utilities_deallocate_struct_gfortran.o: utilities_deallocate_struct.f90 ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
utilities_put_struct_gfortran.o: utilities_put_struct.f90 ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
utilities_put_slice_struct_gfortran.o: utilities_put_slice_struct.f90 ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
utilities_get_struct_gfortran.o: utilities_get_struct.f90 ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@

$(filter %_put_gfortran.o,$(IDSOBJECTS)): %_put_gfortran.o : %_put.f90 %_delete_gfortran.o ids_schemas_gfortran.o utilities_put_struct_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_put_slice_gfortran.o,$(IDSOBJECTS)): %_put_slice_gfortran.o : %_put_slice.f90 ids_schemas_gfortran.o utilities_put_slice_struct_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_get_gfortran.o,$(IDSOBJECTS)): %_get_gfortran.o:%_get.f90 ids_schemas_gfortran.o utilities_get_struct_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_get_slice_gfortran.o,$(IDSOBJECTS)): %_get_slice_gfortran.o:%_get_slice.f90 ids_schemas_gfortran.o utilities_get_struct_gfortran.o %_get_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_delete_gfortran.o,$(IDSOBJECTS)): %_gfortran.o:%.f90 ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_copy_struct_gfortran.o,$(IDSOBJECTS)): %_gfortran.o:%.f90 ids_schemas_gfortran.o utilities_copy_struct_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_deallocate_struct_gfortran.o,$(IDSOBJECTS)): %_gfortran.o:%.f90 ids_schemas_gfortran.o utilities_deallocate_struct_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@

#--------------------- pgi --------------
libimas-pgi$(SOEXT3): %$(SOEXT3): ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o utilities_copy_struct_pgi.o utilities_deallocate_struct_pgi.o utilities_put_struct_pgi.o utilities_put_slice_struct_pgi.o utilities_get_struct_pgi.o $(IDSOBJECTS_pgi) ids_routines_pgi.o $(DEP_pgi)
	$(FC_pgi) $(COPTS_pgi) -o $@ -shared -Wl,-soname,$*$(SOEXT2) $^ $(LIBS)
	ln -svfT $@ $*$(SOEXT2)

libimas-pgi.a: ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o utilities_copy_struct_pgi.o utilities_deallocate_struct_pgi.o utilities_put_struct_pgi.o utilities_put_slice_struct_pgi.o utilities_get_struct_pgi.o $(IDSOBJECTS_pgi) ids_routines_pgi.o $(DEP_pgi)
	$(AR) rvs $@ $^

ids_routines_pgi.o: ids_routines.f90 ual_defs_pgi.o ual_low_level_wrap_pgi.o utilities_copy_struct_pgi.o utilities_deallocate_struct_pgi.o utilities_put_struct_pgi.o utilities_put_slice_struct_pgi.o utilities_get_struct_pgi.o $(IDSOBJECTS_pgi)
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) ids_routines.f90 -o $@

ual_defs_pgi.o: %_pgi.o:wrapper/%.f90
	$(mkdir_p) $(MODDIR_pgi)
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
ual_low_level_wrap_pgi.o: %_pgi.o:wrapper/%.f90 ual_defs_pgi.o
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
ids_schemas_pgi.o: %_pgi.o:%.f90 ual_defs_pgi.o 
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
utilities_copy_struct_pgi.o: utilities_copy_struct.f90 ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o 
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
utilities_deallocate_struct_pgi.o: utilities_deallocate_struct.f90 ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o 
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
utilities_put_struct_pgi.o: utilities_put_struct.f90 ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o 
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
utilities_put_slice_struct_pgi.o: utilities_put_slice_struct.f90 ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o 
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
utilities_get_struct_pgi.o: utilities_get_struct.f90 ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o 
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@

$(filter %_put_pgi.o,$(IDSOBJECTS)): %_put_pgi.o : %_put.f90 %_delete_pgi.o ids_schemas_pgi.o utilities_put_struct_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o 
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_put_slice_pgi.o,$(IDSOBJECTS)): %_put_slice_pgi.o : %_put_slice.f90 ids_schemas_pgi.o utilities_put_slice_struct_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o 
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_get_pgi.o,$(IDSOBJECTS)): %_get_pgi.o:%_get.f90 ids_schemas_pgi.o utilities_get_struct_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o 
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_get_slice_pgi.o,$(IDSOBJECTS)): %_get_slice_pgi.o:%_get_slice.f90 ids_schemas_pgi.o utilities_get_struct_pgi.o %_get_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o 
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_delete_pgi.o,$(IDSOBJECTS)): %_pgi.o:%.f90 ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o 
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_copy_struct_pgi.o,$(IDSOBJECTS)): %_pgi.o:%.f90 ids_schemas_pgi.o utilities_copy_struct_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o 
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_deallocate_struct_pgi.o,$(IDSOBJECTS)): %_pgi.o:%.f90 ids_schemas_pgi.o utilities_deallocate_struct_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o 
	$(FC_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@

#--------------------- ifort --------------
libimas-ifort$(SOEXT3): %$(SOEXT3): ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o utilities_copy_struct_ifort.o utilities_deallocate_struct_ifort.o utilities_put_struct_ifort.o utilities_put_slice_struct_ifort.o utilities_get_struct_ifort.o $(IDSOBJECTS_ifort) ids_routines_ifort.o $(DEP_ifort)
	$(FC_ifort) $(COPTS_ifort) -o $@ -shared -Wl,-soname,$*$(SOEXT2) $^ $(LIBS)
	ln -svfT $@ $*$(SOEXT2)

libimas-ifort.a: ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o utilities_copy_struct_ifort.o utilities_deallocate_struct_ifort.o utilities_put_struct_ifort.o utilities_put_slice_struct_ifort.o utilities_get_struct_ifort.o $(IDSOBJECTS_ifort) ids_routines_ifort.o $(DEP_ifort)
	$(AR) rvs $@ $^

ids_routines_ifort.o: ids_routines.f90 ual_defs_ifort.o ual_low_level_wrap_ifort.o utilities_copy_struct_ifort.o utilities_deallocate_struct_ifort.o utilities_put_struct_ifort.o utilities_put_slice_struct_ifort.o utilities_get_struct_ifort.o $(IDSOBJECTS_ifort)
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) ids_routines.f90 -o $@

ual_defs_ifort.o: %_ifort.o:wrapper/%.f90
	$(mkdir_p) $(MODDIR_ifort)
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
ual_low_level_wrap_ifort.o: %_ifort.o:wrapper/%.f90 ual_defs_ifort.o
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
ids_schemas_ifort.o: %_ifort.o:%.f90 ual_defs_ifort.o 
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
utilities_copy_struct_ifort.o: utilities_copy_struct.f90 ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
utilities_deallocate_struct_ifort.o: utilities_deallocate_struct.f90 ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
utilities_put_struct_ifort.o: utilities_put_struct.f90 ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
utilities_put_slice_struct_ifort.o: utilities_put_slice_struct.f90 ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
utilities_get_struct_ifort.o: utilities_get_struct.f90 ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@

$(filter %_put_ifort.o,$(IDSOBJECTS)): %_put_ifort.o : %_put.f90 %_delete_ifort.o ids_schemas_ifort.o utilities_put_struct_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_put_slice_ifort.o,$(IDSOBJECTS)): %_put_slice_ifort.o : %_put_slice.f90 ids_schemas_ifort.o utilities_put_slice_struct_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_get_ifort.o,$(IDSOBJECTS)): %_get_ifort.o:%_get.f90 ids_schemas_ifort.o utilities_get_struct_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_get_slice_ifort.o,$(IDSOBJECTS)): %_get_slice_ifort.o:%_get_slice.f90 ids_schemas_ifort.o utilities_get_struct_ifort.o %_get_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_delete_ifort.o,$(IDSOBJECTS)): %_ifort.o:%.f90 ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_copy_struct_ifort.o,$(IDSOBJECTS)): %_ifort.o:%.f90 ids_schemas_ifort.o utilities_copy_struct_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_deallocate_struct_ifort.o,$(IDSOBJECTS)): %_ifort.o:%.f90 ids_schemas_ifort.o utilities_deallocate_struct_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@

#----------------------- xslt ---------------------
# Test if all idsroutines are found to exist as files.
ifeq ($(words $(IDSROUTINES)), $(words $(wildcard $(IDSROUTINES))))
$(SOURCES): IDSDef2F90Routines.xsl xsd2copy_structures.xsl
	$(JAVA) net.sf.saxon.Transform -t -s:$(IDSDEF) -xsl:IDSDef2F90Routines.xsl
idsroutines:
else
# Need to generate, use an intermediate target idsroutines to force non-parallel execution.
$(SOURCES): idsroutines
idsroutines: IDSDef2F90Routines.xsl xsd2copy_structures.xsl
	$(JAVA) net.sf.saxon.Transform -t -s:$(IDSDEF) -xsl:IDSDef2F90Routines.xsl
endif

ids_schemas.f90: xsd2F90TypeDef.xsl
	(cp xsd2F90TypeDef.xsl ../xml/ ; cd ../xml/ ; \
	xsltproc xsd2F90TypeDef.xsl $(IDSDEFXSD) > ids_schemas.f90 ) ; \
	$(RM) ../xml/xsd2F90TypeDef.xsl ; \
	mv ../xml/ids_schemas.f90 .

#----------------------- pkgconfig ---------------------
include ../Makefile.pkgconfig

#----------------------- classpath deps ---------------------
include ../Makefile.classpath
endif # IMAS_FORTRAN=no?
