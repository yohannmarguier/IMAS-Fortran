# -*- makefile -*- #
include ../Makefile.common

# Library interface number (used as soname suffix)
# If any interfaces have been added, removed, or changed since the last update,
# increment this number. Do not increment if it is certain the changes retain
# ABI compatibility. This may be possible if the changes are only in the
# implementation and do not change any function signatures or data structures.
# N.B. this number is not tied to the AL major version number whatsoever.
SO_NUM=4


ifeq ("no","$(strip $(IMAS_FORTRAN))")
all sources sources_install install clean clean-src check test:
	$(warning "Ignoring fortraninterface (IMAS_FORTRAN=no).")
else

ifneq ("no","$(strip $(SYS_WIN))")
ifneq ("no","$(strip $(IMAS_G95))")
$(error "Ignoring fortraninterface for Windows (IMAS_G95=yes).")
endif
ifneq ("no","$(strip $(IMAS_NAGFOR))")
$(error "Ignoring fortraninterface for Windows (IMAS_NAGFOR=yes).")
endif
ifneq ("no","$(strip $(IMAS_PGI))")
$(error "Ignoring fortraninterface for Windows (IMAS_PGI=yes).")
endif
ifneq ("no","$(strip $(IMAS_IFORT))")
$(error "Ignoring fortraninterface for Windows (IMAS_IFORT=yes).")
endif
export IMAS_PREFIX=$(UAL)
ifeq (,$(wildcard $(IMAS_PREFIX)))
$(error $$IMAS_PREFIX is unset)
endif
endif

FC_g95         = g95
MODDIR_g95      = g95
FCFLAGS_g95       = -D__USE_XOPEN2K8 -r8 -ftrace=full -fPIC -fno-second-underscore -ffree-line-length-huge -g -fmod=$(MODDIR_g95)
INCDIR_g95      = -I$(MODDIR_g95)

FC_gfortran    = gfortran
MODDIR_gfortran = gfortran
FCFLAGS_gfortran  = -O0 -D__USE_XOPEN2K8 -fdefault-real-8 -fdefault-double-8 -fPIC -fno-second-underscore -ffree-line-length-none -g -J$(MODDIR_gfortran)
INCDIR_gfortran = -I$(MODDIR_gfortran)

FC_nagfor      = nagfor
MODDIR_nagfor   = nagfor
FCFLAGS_nagfor    = -O0 -D__USE_XOPEN2K8 -free -maxcontin=4000 -w=unused -w=x95 -kind=byte -r8 -PIC -mdir ./$(MODDIR_nagfor) -g 
INCDIR_nagfor   = -I$(MODDIR_nagfor)

FC_pgi         = pgf90
MODDIR_pgi      = pgi
FCFLAGS_pgi       = -D__USE_XOPEN2K8 -r8 -Mnosecond_underscore -fPIC -module=./$(MODDIR_pgi) -g
INCDIR_pgi      = -I$(MODDIR_pgi)

FC_ifort       = ifort
MODDIR_ifort    = ifort
FCFLAGS_ifort     = -r8 -O0 -assume no2underscore -fPIC -module $(MODDIR_ifort) -g -shared-intel
INCDIR_ifort    = -I$(MODDIR_ifort)

# Windows
ifneq ("no","$(strip $(SYS_WIN))")
LIBS		= $(IMAS_PREFIX)/lib/libimas.lib
LIBS		+= -lm -lstdc++
JAVA		= $(JAVA_HOME)/bin/java
else
LIBS		= -L../lowlevel -limas -lm
JAVA		= java
endif
IDSDEFXSD   = dd_data_dictionary.xml.xsd
IDSDEF      = ../xml/IDSDef.xml

ifneq ("no","$(strip $(IMAS_MDSPLUS))")
ifneq ("no","$(strip $(SYS_WIN))")
LIBS	+= -L$(MDSPLUS_DIR)/lib
LIBS	+= $(MDSPLUS_DIR)/lib/XTreeShr.a
LIBS	+= $(MDSPLUS_DIR)/lib/MdsObjectsCppShr.a
LIBS	+= $(MDSPLUS_DIR)/lib/TdiShr.a
LIBS	+= $(MDSPLUS_DIR)/lib/TreeShr.a
LIBS	+= $(MDSPLUS_DIR)/lib/MdsIpShr.a
LIBS	+= $(MDSPLUS_DIR)/lib/MdsShr.a
LIBS	+= -lxml2 -lws2_32 -ldl -liphlpapi -lstdc++
else
#LIBS	+= -L$(MDSPLUS_DIR)/lib64 -L$(MDSPLUS_DIR)/lib
#LIBS	+= -lMdsShr -lTreeShr -lTdiShr -lMdsLib -lMdsIpShr -lMdsObjectsCppShr -lXTreeShr
endif
endif

ifneq ("no","$(strip $(IMAS_UDA))")
ifneq ("no","$(strip $(SYS_WIN))")
LIBS	+= -L$(UDA_HOME)/lib
LIBS	+= $(UDA_HOME)/lib/libuda_cpp.a
LIBS	+= $(UDA_HOME)/lib/libportablexdr.a
LIBS	+= -lws2_32 -lssl -lcrypto -lstdc++
else
#LIBS	+= `pkg-config --libs uda-cpp`
#LIBS	+= -lssl -lcrypto
endif
endif

ifneq ("no","$(strip $(IMAS_HDF5))")
ifneq ("no","$(strip $(SYS_WIN))")
LIBS	+= -L$(HDF5_HOME)/lib
LIBS	+= $(HDF5_HOME)/lib/libhdf5.a -ldl -lz -lstdc++
else
#LIBS	+= -L$(HDF5_HOME)/lib
#LIBS	+= -lhdf5 -ldl -lz
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
PC_FILES_VAR=
PC_FILES_ALT=

ifneq ("no","$(strip $(IMAS_G95))")
TARGETS += libimas-g95.so libimas-g95.a id_g95_all
PC_FILES += imas-g95.pc
PC_FILES_VAR += imas-g95-$(DD_GIT_DESCRIBE).pc
PC_FILES_ALT += $(ID_g95_PC_FILES_2)
INSTALL_TARGETS += g95_install id_g95_install
IDSOBJECTS_g95=$(addsuffix _g95.o,$(IDSNAMES_FUNC))
endif

ifneq ("no","$(strip $(IMAS_GFORTRAN))")
ifneq ("no","$(strip $(SYS_WIN))")
TARGETS += libimas-gfortran.dll libimas-gfortran.lib
else
TARGETS += libimas-gfortran.so libimas-gfortran.a
endif
TARGETS += id_gfortran_all
PC_FILES += imas-gfortran.pc
PC_FILES_VAR += imas-gfortran-$(DD_GIT_DESCRIBE).pc
PC_FILES_ALT += $(ID_gfortran_PC_FILES_2)
INSTALL_TARGETS += gfortran_install id_gfortran_install
IDSOBJECTS_gfortran=$(addsuffix _gfortran.o,$(IDSNAMES_FUNC))
endif

ifneq ("no","$(strip $(IMAS_NAGFOR))")
TARGETS += libimas-nagfor.so libimas-nagfor.a id_nagfor_all
PC_FILES += imas-nagfor.pc
PC_FILES_VAR += imas-nagfor-$(DD_GIT_DESCRIBE).pc
PC_FILES_ALT += $(ID_nagfor_PC_FILES_2)
INSTALL_TARGETS += nagfor_install id_nagfor_install
IDSOBJECTS_nagfor=$(addsuffix _nagfor.o,$(IDSNAMES_FUNC))
endif

ifneq ("no","$(strip $(IMAS_PGI))")
TARGETS += libimas-pgi.so libimas-pgi.a id_pgi_all
PC_FILES += imas-pgi.pc
PC_FILES_VAR += imas-pgi-$(DD_GIT_DESCRIBE).pc
PC_FILES_ALT += $(ID_pgi_PC_FILES_2)
INSTALL_TARGETS += pgi_install id_pgi_install
IDSOBJECTS_pgi=$(addsuffix _pgi.o,$(IDSNAMES_FUNC))
endif

ifneq ("no","$(strip $(IMAS_IFORT))")
TARGETS += libimas-ifort.so libimas-ifort.a id_ifort_all
PC_FILES += imas-ifort.pc
PC_FILES_VAR += imas-ifort-$(DD_GIT_DESCRIBE).pc
PC_FILES_ALT += $(ID_ifort_PC_FILES_2)
INSTALL_TARGETS += ifort_install id_ifort_install
IDSOBJECTS_ifort=$(addsuffix _ifort.o,$(IDSNAMES_FUNC))
endif

# Concatenated list
IDSOBJECTS=$(IDSOBJECTS_g95) $(IDSOBJECTS_gfortran) $(IDSOBJECTS_nagfor) $(IDSOBJECTS_pgi) $(IDSOBJECTS_ifort)

all: $(SOURCES) $(TARGETS) pkgconfig

install: all $(INSTALL_TARGETS) pkgconfig_install

$(libdir) $(addprefix $(includedir)/,nagfor pgi g95 gfortran ifort) $(datadir)/src/fortraninterface \
$(MODDIR_nagfor) $(MODDIR_pgi) $(MODDIR_g95) $(MODDIR_gfortran) $(MODDIR_ifort):
	$(mkdir_p) $@

sources: $(SOURCES) ids_schemas.f90 id_f90_sources
sources_install: $(SOURCES) ids_schemas.f90 id_f90_sources_install
ifeq ("no","$(strip $(SYS_WIN))")
	$(INSTALL_DATA) $(SOURCES) ids_schemas.f90 $(datadir)/src/fortraninterface
endif

nagfor_install: $(IDSOBJECTS_nagfor) libimas-nagfor.a_install libimas-nagfor.so_install | $(includedir)/nagfor
	$(INSTALL_DATA) $(MODDIR_nagfor)/*.mod $(includedir)/nagfor
pgi_install: $(IDSOBJECTS_pgi) libimas-pgi.a_install libimas-pgi.so_install | $(includedir)/pgi
	$(INSTALL_DATA) $(MODDIR_pgi)/*.mod $(includedir)/pgi
g95_install: $(IDSOBJECTS_g95) libimas-g95.a_install libimas-g95.so_install | $(includedir)/g95
	$(INSTALL_DATA) $(MODDIR_g95)/*.mod $(includedir)/g95
ifort_install: $(IDSOBJECTS_ifort) libimas-ifort.a_install libimas-ifort.so_install | $(includedir)/ifort
	$(INSTALL_DATA) $(MODDIR_ifort)/*.mod $(includedir)/ifort
ifeq ("no","$(strip $(SYS_WIN))")
gfortran_install: $(IDSOBJECTS_gfortran) libimas-gfortran.a_install libimas-gfortran.so_install | $(includedir)/gfortran
	$(INSTALL_DATA) $(MODDIR_gfortran)/*.mod $(includedir)/gfortran
else
gfortran_install: $(IDSOBJECTS_gfortran) libimas-gfortran.dll libimas-gfortran.lib
	$(mkdir_p) $(packagedir)/fortraninterface/include
	cp gfortran/*.mod $(packagedir)/fortraninterface/include
	$(mkdir_p) $(packagedir)/fortraninterface/lib
	for OBJECT in `find . -type f \( -name "*.lib" -or -name "*.dll" \)`; do \
		cp $$OBJECT $(packagedir)/fortraninterface/lib; \
	done
endif

clean: pkgconfig_clean id_g95_clean id_gfortran_clean id_ifort_clean id_nagfor_clean id_pgi_clean check-clean
	$(RM) -r *.o *.mod *.so* *~ g95/ gfortran/ nagfor/ pgi/ ifort/ *.a *.lib *.dll

clean-src: clean id_f90_clean-src check-clean-src
	$(RM) $(SOURCES)
	$(RM) ids_schemas.f90

check test:
	$(MAKE) -C tests/generator test

check-clean test-clean:
	$(MAKE) -C tests/generator clean

check-clean-src test-clean-src:
	$(MAKE) -C tests/generator clean-src


#--------------------- g95 --------------
LIBFILES_g95 = ids_schemas_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o utilities_copy_struct_g95.o utilities_deallocate_struct_g95.o utilities_put_struct_g95.o utilities_put_slice_struct_g95.o utilities_get_struct_g95.o $(IDSOBJECTS_g95) ids_routines_g95.o $(DEP_g95)

libimas-g95-$(DD_GIT_DESCRIBE).so.$(SO_NUM): $(LIBFILES_g95)
	$(FC_g95) $(FCFLAGS_g95) -o $@ -shared -Wl,-soname,$@ $^ $(LIBS)
libimas-g95-$(DD_GIT_DESCRIBE).so: %:%.$(SO_NUM)
	$(LN_S) $< $@
libimas-g95.so:libimas-g95-$(DD_GIT_DESCRIBE).so
	$(LN_S) $< $@
libimas-g95.so_install: %.so_install:%-$(DD_GIT_DESCRIBE).so.$(SO_NUM) | $(libdir)
	$(INSTALL_DATA) $< $(libdir)
	$(LN_S) $< $(libdir)/$*-$(DD_GIT_DESCRIBE).so
	$(LN_S) $< $(libdir)/$*.so

# Static library
libimas-g95-$(DD_GIT_DESCRIBE).a: $(LIBFILES_g95)
	$(AR) rvs $@ $^
libimas-g95.a:libimas-g95-$(DD_GIT_DESCRIBE).a
	$(LN_S) $< $@
libimas-g95.a_install: %.a_install:%-$(DD_GIT_DESCRIBE).a | $(libdir)
	$(INSTALL_DATA) $< $(libdir)
	$(LN_S) $< $(libdir)/$*.a

ids_routines_g95.o: ids_routines.f90 ual_defs_g95.o ual_low_level_wrap_g95.o utilities_copy_struct_g95.o utilities_deallocate_struct_g95.o utilities_put_struct_g95.o utilities_put_slice_struct_g95.o utilities_get_struct_g95.o $(IDSOBJECTS_g95)
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) ids_routines.f90 -o $@

ual_defs_g95.o: %_g95.o:wrapper/%.f90 | $(MODDIR_g95)
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@
ual_low_level_wrap_g95.o: %_g95.o:wrapper/%.f90 ual_defs_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@
ids_schemas_g95.o: %_g95.o:%.f90 ual_defs_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@
utilities_copy_struct_g95.o: utilities_copy_struct.f90 ids_schemas_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@
utilities_deallocate_struct_g95.o: utilities_deallocate_struct.f90 ids_schemas_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@
utilities_put_struct_g95.o : utilities_put_struct.f90 ids_schemas_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@
utilities_put_slice_struct_g95.o : utilities_put_slice_struct.f90 ids_schemas_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@
utilities_get_struct_g95.o : utilities_get_struct.f90 ids_schemas_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@

$(filter %_put_g95.o,$(IDSOBJECTS)): %_put_g95.o : %_put.f90 %_delete_g95.o ids_schemas_g95.o utilities_put_struct_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@
$(filter %_put_slice_g95.o,$(IDSOBJECTS)): %_put_slice_g95.o : %_put_slice.f90 ids_schemas_g95.o utilities_put_slice_struct_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@
$(filter %_get_g95.o,$(IDSOBJECTS)): %_get_g95.o:%_get.f90 ids_schemas_g95.o utilities_get_struct_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@
$(filter %_get_slice_g95.o,$(IDSOBJECTS)): %_get_slice_g95.o:%_get_slice.f90 ids_schemas_g95.o utilities_get_struct_g95.o %_get_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@
$(filter %_delete_g95.o,$(IDSOBJECTS)): %_g95.o:%.f90 ids_schemas_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@
$(filter %_copy_struct_g95.o,$(IDSOBJECTS)): %_g95.o:%.f90 ids_schemas_g95.o utilities_copy_struct_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@
$(filter %_deallocate_struct_g95.o,$(IDSOBJECTS)): %_g95.o:%.f90 ids_schemas_g95.o utilities_deallocate_struct_g95.o ual_defs_g95.o ual_low_level_wrap_g95.o
	$(FC_g95) -c $(FCFLAGS_g95) $(INCDIR_g95) $< -o $@

#--------------------- gfortran --------------
LIBFILES_gfortran = ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o utilities_copy_struct_gfortran.o utilities_deallocate_struct_gfortran.o utilities_put_struct_gfortran.o utilities_put_slice_struct_gfortran.o utilities_get_struct_gfortran.o $(IDSOBJECTS_gfortran) ids_routines_gfortran.o $(DEP_gfortran)

libimas-gfortran-$(DD_GIT_DESCRIBE).so.$(SO_NUM): $(LIBFILES_gfortran)
	$(FC_gfortran) $(FCFLAGS_gfortran) -o $@ -shared -Wl,-soname,$@ $^ $(LIBS)
libimas-gfortran-$(DD_GIT_DESCRIBE).so: %:%.$(SO_NUM)
	$(LN_S) $< $@
libimas-gfortran.so:libimas-gfortran-$(DD_GIT_DESCRIBE).so
	$(LN_S) $< $@
libimas-gfortran.so_install: %.so_install:%-$(DD_GIT_DESCRIBE).so.$(SO_NUM) | $(libdir)
	$(INSTALL_DATA) $< $(libdir)
	$(LN_S) $< $(libdir)/$*-$(DD_GIT_DESCRIBE).so
	$(LN_S) $< $(libdir)/$*.so

# Static library
libimas-gfortran-$(DD_GIT_DESCRIBE).a: $(LIBFILES_gfortran)
	$(AR) rvs $@ $^
libimas-gfortran.a:libimas-gfortran-$(DD_GIT_DESCRIBE).a
	$(LN_S) $< $@
libimas-gfortran.a_install: %.a_install:%-$(DD_GIT_DESCRIBE).a | $(libdir)
	$(INSTALL_DATA) $< $(libdir)
	$(LN_S) $< $(libdir)/$*.a

# Windows libraries
libimas-gfortran.dll: $(LIBFILES_gfortran)
	$(FC_gfortran) $(COPTS_gfortran) -o $@ -shared -Wl,-soname,$@.$(SO_NUM) -Wl,--out-implib,$@.lib $^ $(LIBS)

libimas-gfortran.lib: $(LIBFILES_gfortran)
	$(AR) rcvsu $@ $^
	ranlib $@

ids_routines_gfortran.o: ids_routines.f90 ual_defs_gfortran.o ual_low_level_wrap_gfortran.o utilities_copy_struct_gfortran.o utilities_deallocate_struct_gfortran.o utilities_put_struct_gfortran.o utilities_put_slice_struct_gfortran.o utilities_get_struct_gfortran.o $(IDSOBJECTS_gfortran)
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) ids_routines.f90 -o $@

ual_defs_gfortran.o: %_gfortran.o:wrapper/%.f90 | $(MODDIR_gfortran)
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@
ual_low_level_wrap_gfortran.o: %_gfortran.o:wrapper/%.f90 ual_defs_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@
ids_schemas_gfortran.o: %_gfortran.o:%.f90 ual_defs_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@
utilities_copy_struct_gfortran.o: utilities_copy_struct.f90 ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@
utilities_deallocate_struct_gfortran.o: utilities_deallocate_struct.f90 ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@
utilities_put_struct_gfortran.o: utilities_put_struct.f90 ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@
utilities_put_slice_struct_gfortran.o: utilities_put_slice_struct.f90 ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@
utilities_get_struct_gfortran.o: utilities_get_struct.f90 ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@

$(filter %_put_gfortran.o,$(IDSOBJECTS)): %_put_gfortran.o : %_put.f90 %_delete_gfortran.o ids_schemas_gfortran.o utilities_put_struct_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_put_slice_gfortran.o,$(IDSOBJECTS)): %_put_slice_gfortran.o : %_put_slice.f90 ids_schemas_gfortran.o utilities_put_slice_struct_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_get_gfortran.o,$(IDSOBJECTS)): %_get_gfortran.o:%_get.f90 ids_schemas_gfortran.o utilities_get_struct_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_get_slice_gfortran.o,$(IDSOBJECTS)): %_get_slice_gfortran.o:%_get_slice.f90 ids_schemas_gfortran.o utilities_get_struct_gfortran.o %_get_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_delete_gfortran.o,$(IDSOBJECTS)): %_gfortran.o:%.f90 ids_schemas_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_copy_struct_gfortran.o,$(IDSOBJECTS)): %_gfortran.o:%.f90 ids_schemas_gfortran.o utilities_copy_struct_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_deallocate_struct_gfortran.o,$(IDSOBJECTS)): %_gfortran.o:%.f90 ids_schemas_gfortran.o utilities_deallocate_struct_gfortran.o ual_defs_gfortran.o ual_low_level_wrap_gfortran.o
	$(FC_gfortran) -c $(FCFLAGS_gfortran) $(INCDIR_gfortran) $< -o $@

#--------------------- nagfor --------------
LIBFILES_nagfor = ids_schemas_nagfor.o ual_defs_nagfor.o ual_low_level_wrap_nagfor.o utilities_copy_struct_nagfor.o utilities_deallocate_struct_nagfor.o utilities_put_struct_nagfor.o utilities_put_slice_struct_nagfor.o utilities_get_struct_nagfor.o $(IDSOBJECTS_nagfor) ids_routines_nagfor.o $(DEP_nagfor)

libimas-nagfor-$(DD_GIT_DESCRIBE).so.$(SO_NUM): $(LIBFILES_nagfor)
	$(FC_nagfor) $(FCFLAGS_nagfor) -o $@ -Wl,-shared $^ $(LIBS)
#	$(FC_nagfor) $(FCFLAGS_nagfor) -o $@ -Wl,-Wl,,-shared -Wl,-Wl,,-soname,,$@ $^ $(LIBS)
libimas-nagfor-$(DD_GIT_DESCRIBE).so: %:%.$(SO_NUM)
	$(LN_S) $< $@
libimas-nagfor.so:libimas-nagfor-$(DD_GIT_DESCRIBE).so
	$(LN_S) $< $@
libimas-nagfor.so_install: %.so_install:%-$(DD_GIT_DESCRIBE).so.$(SO_NUM) | $(libdir)
	$(INSTALL_DATA) $< $(libdir)
	$(LN_S) $< $(libdir)/$*-$(DD_GIT_DESCRIBE).so
	$(LN_S) $< $(libdir)/$*.so

# Static library
libimas-nagfor-$(DD_GIT_DESCRIBE).a: $(LIBFILES_nagfor)
	$(AR) rvs $@ $^
libimas-nagfor.a:libimas-nagfor-$(DD_GIT_DESCRIBE).a
	$(LN_S) $< $@
libimas-nagfor.a_install: %.a_install:%-$(DD_GIT_DESCRIBE).a | $(libdir)
	$(INSTALL_DATA) $< $(libdir)
	$(LN_S) $< $(libdir)/$*.a

ids_routines_nagfor.o: ids_routines.f90 ual_defs_nagfor.o ual_low_level_wrap_nagfor.o utilities_copy_struct_nagfor.o utilities_deallocate_struct_nagfor.o utilities_put_struct_nagfor.o utilities_put_slice_struct_nagfor.o utilities_get_struct_nagfor.o $(IDSOBJECTS_nagfor)
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) ids_routines.f90 -o $@

ual_defs_nagfor.o: %_nagfor.o:wrapper/%.f90 | $(MODDIR_nagfor)
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@
ual_low_level_wrap_nagfor.o: %_nagfor.o:wrapper/%.f90 ual_defs_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@
ids_schemas_nagfor.o: %_nagfor.o:%.f90 ual_defs_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@
utilities_copy_struct_nagfor.o: utilities_copy_struct.f90 ids_schemas_nagfor.o ual_defs_nagfor.o ual_low_level_wrap_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@
utilities_deallocate_struct_nagfor.o: utilities_deallocate_struct.f90 ids_schemas_nagfor.o ual_defs_nagfor.o ual_low_level_wrap_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@
utilities_put_struct_nagfor.o: utilities_put_struct.f90 ids_schemas_nagfor.o ual_defs_nagfor.o ual_low_level_wrap_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@
utilities_put_slice_struct_nagfor.o: utilities_put_slice_struct.f90 ids_schemas_nagfor.o ual_defs_nagfor.o ual_low_level_wrap_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@
utilities_get_struct_nagfor.o: utilities_get_struct.f90 ids_schemas_nagfor.o ual_defs_nagfor.o ual_low_level_wrap_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@

$(filter %_put_nagfor.o,$(IDSOBJECTS)): %_put_nagfor.o : %_put.f90 %_delete_nagfor.o ids_schemas_nagfor.o utilities_put_struct_nagfor.o ual_defs_nagfor.o ual_low_level_wrap_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@
$(filter %_put_slice_nagfor.o,$(IDSOBJECTS)): %_put_slice_nagfor.o : %_put_slice.f90 ids_schemas_nagfor.o utilities_put_slice_struct_nagfor.o ual_defs_nagfor.o ual_low_level_wrap_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@
$(filter %_get_nagfor.o,$(IDSOBJECTS)): %_get_nagfor.o:%_get.f90 ids_schemas_nagfor.o utilities_get_struct_nagfor.o ual_defs_nagfor.o ual_low_level_wrap_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@
$(filter %_get_slice_nagfor.o,$(IDSOBJECTS)): %_get_slice_nagfor.o:%_get_slice.f90 ids_schemas_nagfor.o utilities_get_struct_nagfor.o %_get_nagfor.o ual_defs_nagfor.o ual_low_level_wrap_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@
$(filter %_delete_nagfor.o,$(IDSOBJECTS)): %_nagfor.o:%.f90 ids_schemas_nagfor.o ual_defs_nagfor.o ual_low_level_wrap_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@
$(filter %_copy_struct_nagfor.o,$(IDSOBJECTS)): %_nagfor.o:%.f90 ids_schemas_nagfor.o utilities_copy_struct_nagfor.o ual_defs_nagfor.o ual_low_level_wrap_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@
$(filter %_deallocate_struct_nagfor.o,$(IDSOBJECTS)): %_nagfor.o:%.f90 ids_schemas_nagfor.o utilities_deallocate_struct_nagfor.o ual_defs_nagfor.o ual_low_level_wrap_nagfor.o
	$(FC_nagfor) -c $(FCFLAGS_nagfor) $(INCDIR_nagfor) $< -o $@

#--------------------- pgi --------------
LIBFILES_pgi = ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o utilities_copy_struct_pgi.o utilities_deallocate_struct_pgi.o utilities_put_struct_pgi.o utilities_put_slice_struct_pgi.o utilities_get_struct_pgi.o $(IDSOBJECTS_pgi) ids_routines_pgi.o $(DEP_pgi)

libimas-pgi-$(DD_GIT_DESCRIBE).so.$(SO_NUM): $(LIBFILES_pgi)
	$(FC_pgi) $(FCFLAGS_pgi) -o $@ -shared -Wl,-soname,$@ $^ $(LIBS)
libimas-pgi-$(DD_GIT_DESCRIBE).so: %:%.$(SO_NUM)
	$(LN_S) $< $@
libimas-pgi.so:libimas-pgi-$(DD_GIT_DESCRIBE).so
	$(LN_S) $< $@
libimas-pgi.so_install: %.so_install:%-$(DD_GIT_DESCRIBE).so.$(SO_NUM) | $(libdir)
	$(INSTALL_DATA) $< $(libdir)
	$(LN_S) $< $(libdir)/$*-$(DD_GIT_DESCRIBE).so
	$(LN_S) $< $(libdir)/$*.so

# Static library
libimas-pgi-$(DD_GIT_DESCRIBE).a: $(LIBFILES_pgi)
	$(AR) rvs $@ $^
libimas-pgi.a:libimas-pgi-$(DD_GIT_DESCRIBE).a
	$(LN_S) $< $@
libimas-pgi.a_install: %.a_install:%-$(DD_GIT_DESCRIBE).a | $(libdir)
	$(INSTALL_DATA) $< $(libdir)
	$(LN_S) $< $(libdir)/$*.a

ids_routines_pgi.o: ids_routines.f90 ual_defs_pgi.o ual_low_level_wrap_pgi.o utilities_copy_struct_pgi.o utilities_deallocate_struct_pgi.o utilities_put_struct_pgi.o utilities_put_slice_struct_pgi.o utilities_get_struct_pgi.o $(IDSOBJECTS_pgi)
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) ids_routines.f90 -o $@

ual_defs_pgi.o: %_pgi.o:wrapper/%.f90 | $(MODDIR_pgi)
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@
ual_low_level_wrap_pgi.o: %_pgi.o:wrapper/%.f90 ual_defs_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@
ids_schemas_pgi.o: %_pgi.o:%.f90 ual_defs_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@
utilities_copy_struct_pgi.o: utilities_copy_struct.f90 ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@
utilities_deallocate_struct_pgi.o: utilities_deallocate_struct.f90 ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@
utilities_put_struct_pgi.o: utilities_put_struct.f90 ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@
utilities_put_slice_struct_pgi.o: utilities_put_slice_struct.f90 ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@
utilities_get_struct_pgi.o: utilities_get_struct.f90 ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@

$(filter %_put_pgi.o,$(IDSOBJECTS)): %_put_pgi.o : %_put.f90 %_delete_pgi.o ids_schemas_pgi.o utilities_put_struct_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_put_slice_pgi.o,$(IDSOBJECTS)): %_put_slice_pgi.o : %_put_slice.f90 ids_schemas_pgi.o utilities_put_slice_struct_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_get_pgi.o,$(IDSOBJECTS)): %_get_pgi.o:%_get.f90 ids_schemas_pgi.o utilities_get_struct_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_get_slice_pgi.o,$(IDSOBJECTS)): %_get_slice_pgi.o:%_get_slice.f90 ids_schemas_pgi.o utilities_get_struct_pgi.o %_get_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_delete_pgi.o,$(IDSOBJECTS)): %_pgi.o:%.f90 ids_schemas_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_copy_struct_pgi.o,$(IDSOBJECTS)): %_pgi.o:%.f90 ids_schemas_pgi.o utilities_copy_struct_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_deallocate_struct_pgi.o,$(IDSOBJECTS)): %_pgi.o:%.f90 ids_schemas_pgi.o utilities_deallocate_struct_pgi.o ual_defs_pgi.o ual_low_level_wrap_pgi.o
	$(FC_pgi) -c $(FCFLAGS_pgi) $(INCDIR_pgi) $< -o $@

#--------------------- ifort --------------
LIBFILES_ifort = ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o utilities_copy_struct_ifort.o utilities_deallocate_struct_ifort.o utilities_put_struct_ifort.o utilities_put_slice_struct_ifort.o utilities_get_struct_ifort.o $(IDSOBJECTS_ifort) ids_routines_ifort.o $(DEP_ifort)

libimas-ifort-$(DD_GIT_DESCRIBE).so.$(SO_NUM): $(LIBFILES_ifort)
	$(FC_ifort) $(FCFLAGS_ifort) -o $@ -shared -Wl,-soname,$@ $^ $(LIBS)
libimas-ifort-$(DD_GIT_DESCRIBE).so: %:%.$(SO_NUM)
	$(LN_S) $< $@
libimas-ifort.so:libimas-ifort-$(DD_GIT_DESCRIBE).so
	$(LN_S) $< $@
libimas-ifort.so_install: %.so_install:%-$(DD_GIT_DESCRIBE).so.$(SO_NUM) | $(libdir)
	$(INSTALL_DATA) $< $(libdir)
	$(LN_S) $< $(libdir)/$*-$(DD_GIT_DESCRIBE).so
	$(LN_S) $< $(libdir)/$*.so

# Static library
libimas-ifort-$(DD_GIT_DESCRIBE).a: $(LIBFILES_ifort)
	$(AR) rvs $@ $^
libimas-ifort.a:libimas-ifort-$(DD_GIT_DESCRIBE).a
	$(LN_S) $< $@
libimas-ifort.a_install: %.a_install:%-$(DD_GIT_DESCRIBE).a | $(libdir)
	$(INSTALL_DATA) $< $(libdir)
	$(LN_S) $< $(libdir)/$*.a

ids_routines_ifort.o: ids_routines.f90 ual_defs_ifort.o ual_low_level_wrap_ifort.o utilities_copy_struct_ifort.o utilities_deallocate_struct_ifort.o utilities_put_struct_ifort.o utilities_put_slice_struct_ifort.o utilities_get_struct_ifort.o $(IDSOBJECTS_ifort)
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) ids_routines.f90 -o $@

ual_defs_ifort.o: %_ifort.o:wrapper/%.f90 | $(MODDIR_ifort)
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@
ual_low_level_wrap_ifort.o: %_ifort.o:wrapper/%.f90 ual_defs_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@
ids_schemas_ifort.o: %_ifort.o:%.f90 ual_defs_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@
utilities_copy_struct_ifort.o: utilities_copy_struct.f90 ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@
utilities_deallocate_struct_ifort.o: utilities_deallocate_struct.f90 ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@
utilities_put_struct_ifort.o: utilities_put_struct.f90 ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@
utilities_put_slice_struct_ifort.o: utilities_put_slice_struct.f90 ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@
utilities_get_struct_ifort.o: utilities_get_struct.f90 ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@

$(filter %_put_ifort.o,$(IDSOBJECTS)): %_put_ifort.o : %_put.f90 %_delete_ifort.o ids_schemas_ifort.o utilities_put_struct_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_put_slice_ifort.o,$(IDSOBJECTS)): %_put_slice_ifort.o : %_put_slice.f90 ids_schemas_ifort.o utilities_put_slice_struct_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_get_ifort.o,$(IDSOBJECTS)): %_get_ifort.o:%_get.f90 ids_schemas_ifort.o utilities_get_struct_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_get_slice_ifort.o,$(IDSOBJECTS)): %_get_slice_ifort.o:%_get_slice.f90 ids_schemas_ifort.o utilities_get_struct_ifort.o %_get_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_delete_ifort.o,$(IDSOBJECTS)): %_ifort.o:%.f90 ids_schemas_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_copy_struct_ifort.o,$(IDSOBJECTS)): %_ifort.o:%.f90 ids_schemas_ifort.o utilities_copy_struct_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_deallocate_struct_ifort.o,$(IDSOBJECTS)): %_ifort.o:%.f90 ids_schemas_ifort.o utilities_deallocate_struct_ifort.o ual_defs_ifort.o ual_low_level_wrap_ifort.o
	$(FC_ifort) -c $(FCFLAGS_ifort) $(INCDIR_ifort) $< -o $@

#----------------------- xslt ---------------------
# Test if all idsroutines are found to exist as files.
$(SOURCES): idsroutines
idsroutines: IDSDef2F90Routines.xsl xsd2copy_structures.xsl | saxonicajar
	$(if $(call allnewerthan,$(IDSROUTINES),$^),, $(JAVA) net.sf.saxon.Transform -t -s:$(IDSDEF) -xsl:IDSDef2F90Routines.xsl )

ids_schemas.f90: xsd2F90TypeDef.xsl
	(cp xsd2F90TypeDef.xsl ../xml/ ; cd ../xml/ ; \
	xsltproc xsd2F90TypeDef.xsl $(IDSDEFXSD) > ids_schemas.f90 ) ; \
	$(RM) ../xml/xsd2F90TypeDef.xsl ; \
	mv ../xml/ids_schemas.f90 .

#----------------------- identifiers ---------------------
include ../Makefile.identifiers

#----------------------- pkgconfig ---------------------
include ../Makefile.pkgconfig

#----------------------- classpath deps ---------------------
include ../Makefile.classpath
endif # IMAS_FORTRAN=no?
