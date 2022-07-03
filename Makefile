# -*- makefile -*- #
include ../Makefile.common

# Library interface number (used as soname suffix)
# If any interfaces have been added, removed, or changed since the last update,
# increment this number. Do not increment if it is certain the changes retain
# ABI compatibility. This may be possible if the changes are only in the
# implementation and do not change any function signatures or data structures.
# N.B. this number is not tied to the AL major version number whatsoever.
SO_NUM=6


ifneq ("yes","$(strip $(IMAS_FORTRAN))")
all sources sources_install install uninstall clean clean-src check test:
	$(warning "Ignoring fortraninterface (IMAS_FORTRAN=no).")
else

MODDIR = include
MODINC = -I$(MODDIR)

# The builder should specify FC, this is a fail safe if it wasn't.
# The builder should specify FCFLAGS, these are some suggestions that are known to work.
ifeq ("yes","$(strip $(IMAS_GFORTRAN))")
FC      ?= gfortran
FCFLAGS ?= -g -O3 -D__USE_XOPEN2K8 -fdefault-real-8 -fdefault-double-8 -fPIC -fno-second-underscore -ffree-line-length-none -J$(MODDIR)
else ifeq ("yes","$(strip $(IMAS_IFORT))")
FC      ?= ifort
FCFLAGS ?= -g -O3 -r8 -assume no2underscore -fPIC -module $(MODDIR) -g -shared-intel
else ifeq ("yes","$(strip $(IMAS_NVFORTRAN))")
FC      ?= nvfortran
FCFLAGS ?= -g -O3 -D__USE_XOPEN2K8 -r8 -Mnosecond_underscore -fPIC -module=./$(MODDIR)
else ifeq ("yes","$(strip $(IMAS_NAGFOR))")
FC      ?= nagfor
FCFLAGS ?= -g -O3 -D__USE_XOPEN2K8 -free -maxcontin=4000 -w=unused -w=x95 -kind=byte -r8 -PIC -mdir ./$(MODDIR)
else ifeq ("yes","$(strip $(IMAS_G95))")
FC      ?= g95
FCFLAGS ?= -g -O3 -D__USE_XOPEN2K8 -r8 -ftrace=full -fPIC -fno-second-underscore -ffree-line-length-huge -fmod=$(MODDIR)
else 
SOURCES_ONLY=yes
endif


# Get a list of IDS from IDSDEF file, allow override by DD in environment
IDSDEF   ?= ../xml/IDSDef.xml
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
PC_FILES=al-fortran.pc
PC_FILES_VAR=al-fortran-$(DD_GIT_DESCRIBE).pc
PC_FILES_ALT=$(ID_fortran_PC_FILES_2)

# Concatenated list
IDSOBJECTS=$(addsuffix .o,$(IDSNAMES_FUNC))

# Include OS-specific Makefile, if exists.
ifneq (,$(wildcard Makefile.$(SYSTEM)))
include Makefile.$(SYSTEM)
else
$(error No Makefile.$(SYSTEM) found for this system: $(UNAME_S))
endif


BUILD_TARGETS = sources
ifneq ("yes","$(strip $(SOURCES_ONLY))")
	BUILD_TARGETS += $(TARGETS) pkgconfig
endif

all: $(BUILD_TARGETS) 

install: all $(INSTALL_TARGETS) pkgconfig_install

uninstall: $(INSTALL_TARGETS:%_install=%_uninstall) pkgconfig_uninstall

$(libdir) $(includedir)/fortran $(datadir)/src/fortraninterface $(MODDIR):
	$(mkdir_p) $@

sources: $(SOURCES) ids_schemas.f90 id_f90_sources

clean: pkgconfig_clean id_fortran_clean check-clean
	$(RM) -r *.o *.mod *.so* *~ $(MODDIR) *.a *.lib *.dll

clean-src: clean id_f90_clean-src check-clean-src
	$(RM) $(SOURCES)
	$(RM) ids_schemas.f90

check test:
	$(MAKE) -C tests/generator test

check-clean test-clean:
	$(MAKE) -C tests/generator clean

check-clean-src test-clean-src:
	$(MAKE) -C tests/generator clean-src


LIBFILES_fortran = ids_schemas.o ual_defs.o ual_low_level_wrap.o utilities_copy_struct.o utilities_deallocate_struct.o utilities_put_struct.o utilities_put_slice_struct.o utilities_get_struct.o $(IDSOBJECTS) ids_routines.o $(DEP)

ids_routines.o: ids_routines.f90 ual_defs.o ual_low_level_wrap.o utilities_copy_struct.o utilities_deallocate_struct.o utilities_put_struct.o utilities_put_slice_struct.o utilities_get_struct.o $(IDSOBJECTS)
	$(FC) -c $(FCFLAGS) $(MODINC) ids_routines.f90 -o $@

ual_defs.o: %.o:wrapper/%.f90 | $(MODDIR)
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@
ual_low_level_wrap.o: %.o:wrapper/%.f90 ual_defs.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@
ids_schemas.o: %.o:%.f90 ual_defs.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@
utilities_copy_struct.o: utilities_copy_struct.f90 ids_schemas.o ual_defs.o ual_low_level_wrap.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@
utilities_deallocate_struct.o: utilities_deallocate_struct.f90 ids_schemas.o ual_defs.o ual_low_level_wrap.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@
utilities_put_struct.o: utilities_put_struct.f90 ids_schemas.o ual_defs.o ual_low_level_wrap.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@
utilities_put_slice_struct.o: utilities_put_slice_struct.f90 ids_schemas.o ual_defs.o ual_low_level_wrap.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@
utilities_get_struct.o: utilities_get_struct.f90 ids_schemas.o ual_defs.o ual_low_level_wrap.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@

$(filter %_put.o,$(IDSOBJECTS)): %_put.o : %_put.f90 %_delete.o ids_schemas.o utilities_put_struct.o ual_defs.o ual_low_level_wrap.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@
$(filter %_put_slice.o,$(IDSOBJECTS)): %_put_slice.o : %_put_slice.f90 ids_schemas.o %_put.o utilities_put_slice_struct.o ual_defs.o ual_low_level_wrap.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@
$(filter %_get.o,$(IDSOBJECTS)): %_get.o:%_get.f90 ids_schemas.o utilities_get_struct.o ual_defs.o ual_low_level_wrap.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@
$(filter %_get_slice.o,$(IDSOBJECTS)): %_get_slice.o:%_get_slice.f90 ids_schemas.o utilities_get_struct.o %_get.o ual_defs.o ual_low_level_wrap.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@
$(filter %_delete.o,$(IDSOBJECTS)): %.o:%.f90 ids_schemas.o ual_defs.o ual_low_level_wrap.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@
$(filter %_copy_struct.o,$(IDSOBJECTS)): %.o:%.f90 ids_schemas.o utilities_copy_struct.o ual_defs.o ual_low_level_wrap.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@
$(filter %_deallocate_struct.o,$(IDSOBJECTS)): %.o:%.f90 ids_schemas.o utilities_deallocate_struct.o ual_defs.o ual_low_level_wrap.o
	$(FC) -c $(FCFLAGS) $(MODINC) $< -o $@


#----------------------- xslt ---------------------
# Test if all idsroutines are found to exist as files.
$(SOURCES): idsroutines
idsroutines: IDSDef2F90Routines.xsl | saxonicajar
	$(if $(call allnewerthan,$(IDSROUTINES),$^),, $(SAXON) -t -s:$(IDSDEF) -xsl:IDSDef2F90Routines.xsl DD_GIT_DESCRIBE=$(DD_GIT_DESCRIBE) UAL_GIT_DESCRIBE=$(UAL_GIT_DESCRIBE))

ids_schemas.f90: IDSDef2F90TypeDef.xsl | saxonicajar
	$(SAXON) -t -s:$(IDSDEF) -xsl:IDSDef2F90TypeDef.xsl


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
