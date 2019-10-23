# -*- makefile -*- #
include ../Makefile.common

# Library interface number (used as soname suffix)
# If any interfaces have been added, removed, or changed since the last update,
# increment this number. Do not increment if it is certain the changes retain
# ABI compatibility. This may be possible if the changes are only in the
# implementation and do not change any function signatures or data structures.
# N.B. this number is not tied to the AL major version number whatsoever.
SO_NUM=5


ifeq ("no","$(strip $(IMAS_FORTRAN))")
all sources sources_install install uninstall clean clean-src check test:
	$(warning "Ignoring fortraninterface (IMAS_FORTRAN=no).")
else

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

# Get a list of IDS from IDSDEF file
IDSDEFXSD   = dd_data_dictionary.xml.xsd
IDSDEF= ../xml/IDSDef.xml
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

# Concatenated list
IDSOBJECTS=$(IDSOBJECTS_g95) $(IDSOBJECTS_gfortran) $(IDSOBJECTS_nagfor) $(IDSOBJECTS_pgi) $(IDSOBJECTS_ifort)

# Include OS-specific Makefile, if exists.
ifneq (,$(wildcard Makefile.$(SYSTEM)))
include Makefile.$(SYSTEM)
else
$(error No Makefile.$(SYSTEM) found for this system: $(UNAME_S))
endif

all: sources $(TARGETS) pkgconfig

install: all $(INSTALL_TARGETS) pkgconfig_install

uninstall: $(INSTALL_TARGETS:%_install=%_uninstall) pkgconfig_uninstall

$(libdir) $(addprefix $(includedir)/,nagfor pgi g95 gfortran ifort) $(datadir)/src/fortraninterface \
$(MODDIR_nagfor) $(MODDIR_pgi) $(MODDIR_g95) $(MODDIR_gfortran) $(MODDIR_ifort):
	$(mkdir_p) $@

sources: $(SOURCES) ids_schemas.f90 id_f90_sources

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
	$(if $(call allnewerthan,$(IDSROUTINES),$^),, $(JAVA) net.sf.saxon.Transform -t -s:$(IDSDEF) -xsl:IDSDef2F90Routines.xsl DD_GIT_DESCRIBE=$(DD_GIT_DESCRIBE) UAL_GIT_DESCRIBE=$(UAL_GIT_DESCRIBE))

ids_schemas.f90: xsd2F90TypeDef.xsl
	(cp xsd2F90TypeDef.xsl ../xml/ ; cd ../xml/ ; \
	xsltproc xsd2F90TypeDef.xsl $(IDSDEFXSD) > ids_schemas.f90 ) ; \
	$(RM) ../xml/xsd2F90TypeDef.xsl ; \
	mv ../xml/ids_schemas.f90 .

# Include OS-specific Makefile.targets, if exists.
ifneq (,$(wildcard Makefile.targets.$(SYSTEM)))
include Makefile.targets.$(SYSTEM)
else
$(error No Makefile.targets.$(SYSTEM) found for this system: $(UNAME_S))
endif

#----------------------- identifiers ---------------------
include ../Makefile.identifiers

#----------------------- pkgconfig ---------------------
include ../Makefile.pkgconfig

#----------------------- classpath deps ---------------------
include ../Makefile.classpath
endif # IMAS_FORTRAN=no?
