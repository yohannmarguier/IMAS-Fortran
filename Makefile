# -*- makefile -*- #
include ../Makefile.common

ifeq ("no","$(strip $(IMAS_FORTRAN))")
all sources sources_install install clean clean-src:
	$(warning "Ignoring fortraninterface (IMAS_FORTRAN=no).")
else

F90_g95         = g95
MODDIR_g95      = g95
COPTS_g95       = -D__USE_XOPEN2K8 -r8 -ftrace=full -fPIC -fno-second-underscore -ffree-line-length-huge -g -fmod=$(MODDIR_g95)
INCDIR_g95      = -I$(MODDIR_g95)

F90_gfortran    = gfortran
MODDIR_gfortran = gfortran
COPTS_gfortran  = -D__USE_XOPEN2K8 -fdefault-real-8 -fdefault-double-8 -fPIC -fno-second-underscore -ffree-line-length-none -g -J$(MODDIR_gfortran)
INCDIR_gfortran = -I$(MODDIR_gfortran)

F90_pgi         = pgf90
MODDIR_pgi      = pgi
COPTS_pgi       = -D__USE_XOPEN2K8 -r8 -Mnosecond_underscore -fPIC -module=./$(MODDIR_pgi) -g
INCDIR_pgi      = -I$(MODDIR_pgi)

F90_ifort       = ifort
MODDIR_ifort    = ifort
COPTS_ifort     = -r8 -O0 -assume no2underscore -fPIC -module $(MODDIR_ifort) -g -shared-intel
INCDIR_ifort    = -I$(MODDIR_ifort)

IDSDEF          = ../xml/IDSDef.xml
IDSDEFXSD       = ../xml/dd_physics_data_dictionary.xsd

LIBS            =  -L../lowlevel -limas -lm

# Get a list of IDS from IDSDEF file
IDSNAMES := $(shell sed '/<IDS name=/!d;s/.*name="\([^"]*\)".*/\1/' $(IDSDEF))

IDSNAMES_FUNC=$(addsuffix _put,$(IDSNAMES))
IDSNAMES_FUNC+=$(addsuffix _put_slice,$(IDSNAMES))
IDSNAMES_FUNC+=$(addsuffix _put_non_timed,$(IDSNAMES))
IDSNAMES_FUNC+=$(addsuffix _get,$(IDSNAMES))
IDSNAMES_FUNC+=$(addsuffix _get_slice,$(IDSNAMES))
IDSNAMES_FUNC+=$(addsuffix _copy,$(IDSNAMES))
IDSNAMES_FUNC+=$(addsuffix _copy_struct,$(IDSNAMES))
IDSNAMES_FUNC+=$(addsuffix _deallocate_struct,$(IDSNAMES))

# IDS routines
IDSROUTINES=$(addsuffix .f90,$(IDSNAMES_FUNC))
SOURCES=ids_routines.f90 utilities_copy_struct.f90 utilities_deallocate_struct.f90 $(IDSROUTINES)

ifneq ("no","$(strip $(IMAS_G95))")
TARGETS += libimas-g95.so libimas-g95.a
INSTALL_TARGETS += g95
IDSOBJECTS_g95=$(addsuffix _g95.o,$(IDSNAMES_FUNC))
endif

ifneq ("no","$(strip $(IMAS_GFORTRAN))")
TARGETS += libimas-gfortran.so libimas-gfortran.a
INSTALL_TARGETS += gfortran
IDSOBJECTS_gfortran=$(addsuffix _gfortran.o,$(IDSNAMES_FUNC))
endif

ifneq ("no","$(strip $(IMAS_PGI))")
TARGETS += libimas-pgi.so libimas-pgi.a
INSTALL_TARGETS += pgi
IDSOBJECTS_pgi=$(addsuffix _pgi.o,$(IDSNAMES_FUNC))
endif

ifneq ("no","$(strip $(IMAS_IFORT))")
TARGETS += libimas-ifort.so libimas-ifort.a
INSTALL_TARGETS += ifort
IDSOBJECTS_ifort=$(addsuffix _ifort.o,$(IDSNAMES_FUNC))
endif

# Concatenated list
IDSOBJECTS=$(IDSOBJECTS_g95) $(IDSOBJECTS_gfortran) $(IDSOBJECTS_pgi) $(IDSOBJECTS_ifort)

all: $(SOURCES) $(TARGETS)

install: all $(addprefix install_,$(INSTALL_TARGETS)) pkgconfig_install
	$(mkdir_p) $(libdir)
	for OBJECT in *.so ;do \
		$(INSTALL_DATA) -T $$OBJECT $(libdir)/$$OBJECT.$(IMAS_MAJOR).$(IMAS_MINOR).$(IMAS_MICRO); \
		ln -svfT $$OBJECT.$(IMAS_MAJOR).$(IMAS_MINOR).$(IMAS_MICRO) $(libdir)/$$OBJECT.$(IMAS_MAJOR).$(IMAS_MINOR); \
		ln -svfT $$OBJECT.$(IMAS_MAJOR).$(IMAS_MINOR).$(IMAS_MICRO) $(libdir)/$$OBJECT.$(IMAS_MAJOR); \
		ln -svfT $$OBJECT.$(IMAS_MAJOR).$(IMAS_MINOR).$(IMAS_MICRO) $(libdir)/$$OBJECT; \
	done

sources: $(SOURCES) ids_schemas.f90
sources_install: $(SOURCES) ids_schemas.f90
	$(mkdir_p) $(datadir)/src/fortraninterface
	$(INSTALL_DATA) $^ $(datadir)/src/fortraninterface

install_pgi:
	$(mkdir_p) $(includedir)/pgi
	$(INSTALL_DATA) pgi/*.mod $(includedir)/pgi
install_g95:
	$(mkdir_p) $(includedir)/g95
	$(INSTALL_DATA) g95/*.mod $(includedir)/g95
install_ifort:
	$(mkdir_p) $(includedir)/ifort
	$(INSTALL_DATA) ifort/*.mod $(includedir)/ifort
install_gfortran:
	$(mkdir_p) $(includedir)/gfortran
	$(INSTALL_DATA) gfortran/*.mod $(includedir)/gfortran

clean:
	rm -rf *.o *.mod  *.so *~ g95/ gfortran/ pgi/ ifort/ *.a

clean-src: clean
	rm -f $(SOURCES)

test:
	$(MAKE) -C tests/generator test

test-clean:
	$(MAKE) -C tests/generator clean

test-clean-src:
	$(MAKE) -C tests/generator clean-src

#--------------------- g95 --------------
libimas-g95.so: ids_schemas_g95.o utilities_copy_struct_g95.o utilities_deallocate_struct_g95.o $(IDSOBJECTS_g95) ids_routines_g95.o $(DEP_g95)
	$(F90_g95) $(COPTS_g95) -o $@ -shared -Wl,-soname,$@.$(IMAS_MAJOR).$(IMAS_MINOR) $^ $(LIBS)

libimas-g95.a: ids_schemas_g95.o utilities_copy_struct_g95.o utilities_deallocate_struct_g95.o $(IDSOBJECTS_g95) ids_routines_g95.o $(DEP_g95)
	ar rvs $@ $^

ids_routines_g95.o: ids_routines.f90 utilities_copy_struct_g95.o utilities_deallocate_struct_g95.o $(IDSOBJECTS_g95)
	$(F90_g95) -c $(COPTS_g95) $(INCDIR_g95) ids_routines.f90 -o $@

ids_schemas_g95.o: %_g95.o:%.f90
	mkdir -p $(MODDIR_g95)
	$(F90_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
utilities_copy_struct_g95.o utilities_deallocate_struct_g95.o: %_g95.o:%.f90 ids_schemas_g95.o
	$(F90_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
$(filter %_put_g95.o,$(IDSOBJECTS)): %_put_g95.o : %_put.f90 %_copy_g95.o ids_schemas_g95.o 
	$(F90_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
$(filter %_put_non_timed_g95.o,$(IDSOBJECTS)): %_put_non_timed_g95.o : %_put_non_timed.f90 %_copy_g95.o ids_schemas_g95.o
	$(F90_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
$(filter %_get_g95.o %_put_slice_g95.o %_get_slice_g95.o %_copy_g95.o,$(IDSOBJECTS)): %_g95.o:%.f90 ids_schemas_g95.o
	$(F90_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
$(filter %_copy_struct_g95.o,$(IDSOBJECTS)): %_g95.o:%.f90 ids_schemas_g95.o utilities_copy_struct_g95.o
	$(F90_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@
$(filter %_deallocate_struct_g95.o,$(IDSOBJECTS)): %_g95.o:%.f90 ids_schemas_g95.o utilities_deallocate_struct_g95.o
	$(F90_g95) -c $(COPTS_g95) $(INCDIR_g95) $< -o $@

#--------------------- gfortran --------------
libimas-gfortran.so: ids_schemas_gfortran.o utilities_copy_struct_gfortran.o utilities_deallocate_struct_gfortran.o $(IDSOBJECTS_gfortran) ids_routines_gfortran.o $(DEP_gfortran)
	$(F90_gfortran) $(COPTS_gfortran) -o $@ -shared -Wl,-soname,$@.$(IMAS_MAJOR).$(IMAS_MINOR) $^ $(LIBS)

libimas-gfortran.a: ids_schemas_gfortran.o utilities_copy_struct_gfortran.o utilities_deallocate_struct_gfortran.o $(IDSOBJECTS_gfortran) ids_routines_gfortran.o $(DEP_gfortran)
	ar rvs $@ $^

ids_routines_gfortran.o: ids_routines.f90 utilities_copy_struct_gfortran.o utilities_deallocate_struct_gfortran.o $(IDSOBJECTS_gfortran)
	$(F90_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) ids_routines.f90 -o $@

ids_schemas_gfortran.o: %_gfortran.o:%.f90
	mkdir -p $(MODDIR_gfortran)
	$(F90_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
utilities_copy_struct_gfortran.o utilities_deallocate_struct_gfortran.o: %_gfortran.o:%.f90 ids_schemas_gfortran.o
	$(F90_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_put_gfortran.o,$(IDSOBJECTS)): %_put_gfortran.o : %_put.f90 %_copy_gfortran.o ids_schemas_gfortran.o 
	$(F90_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_put_non_timed_gfortran.o,$(IDSOBJECTS)): %_put_non_timed_gfortran.o : %_put_non_timed.f90 %_copy_gfortran.o ids_schemas_gfortran.o
	$(F90_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_get_gfortran.o %_put_slice_gfortran.o %_get_slice_gfortran.o %_copy_gfortran.o,$(IDSOBJECTS)): %_gfortran.o:%.f90 ids_schemas_gfortran.o
	$(F90_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_copy_struct_gfortran.o,$(IDSOBJECTS)): %_gfortran.o:%.f90 ids_schemas_gfortran.o utilities_copy_struct_gfortran.o
	$(F90_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@
$(filter %_deallocate_struct_gfortran.o,$(IDSOBJECTS)): %_gfortran.o:%.f90 ids_schemas_gfortran.o utilities_deallocate_struct_gfortran.o
	$(F90_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $< -o $@

#--------------------- pgi --------------
libimas-pgi.so: ids_schemas_pgi.o utilities_copy_struct_pgi.o utilities_deallocate_struct_pgi.o $(IDSOBJECTS_pgi) ids_routines_pgi.o $(DEP_pgi)
	$(F90_pgi) $(COPTS_pgi) -o $@ -shared -Wl,-soname,$@.$(IMAS_MAJOR).$(IMAS_MINOR) $^ $(LIBS)

libimas-pgi.a: ids_schemas_pgi.o utilities_copy_struct_pgi.o utilities_deallocate_struct_pgi.o $(IDSOBJECTS_pgi) ids_routines_pgi.o $(DEP_pgi)
	ar rvs $@ $^

ids_routines_pgi.o: ids_routines.f90 utilities_copy_struct_pgi.o utilities_deallocate_struct_pgi.o $(IDSOBJECTS_pgi)
	$(F90_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) ids_routines.f90 -o $@

ids_schemas_pgi.o: %_pgi.o:%.f90
	mkdir -p $(MODDIR_pgi)
	$(F90_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
utilities_copy_struct_pgi.o utilities_deallocate_struct_pgi.o: %_pgi.o:%.f90 ids_schemas_pgi.o
	$(F90_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_put_pgi.o,$(IDSOBJECTS)): %_put_pgi.o : %_put.f90 %_copy_pgi.o ids_schemas_pgi.o 
	$(F90_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_put_non_timed_pgi.o,$(IDSOBJECTS)): %_put_non_timed_pgi.o : %_put_non_timed.f90 %_copy_pgi.o ids_schemas_pgi.o
	$(F90_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_get_pgi.o %_put_slice_pgi.o %_get_slice_pgi.o %_copy_pgi.o,$(IDSOBJECTS)): %_pgi.o:%.f90 ids_schemas_pgi.o
	$(F90_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_copy_struct_pgi.o,$(IDSOBJECTS)): %_pgi.o:%.f90 ids_schemas_pgi.o utilities_copy_struct_pgi.o
	$(F90_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@
$(filter %_deallocate_struct_pgi.o,$(IDSOBJECTS)): %_pgi.o:%.f90 ids_schemas_pgi.o utilities_deallocate_struct_pgi.o
	$(F90_pgi) -c $(COPTS_pgi) $(INCDIR_pgi) $< -o $@

#--------------------- ifort --------------
libimas-ifort.so: ids_schemas_ifort.o utilities_copy_struct_ifort.o utilities_deallocate_struct_ifort.o $(IDSOBJECTS_ifort) ids_routines_ifort.o $(DEP_ifort)
	$(F90_ifort) $(COPTS_ifort) -o $@ -shared -Wl,-soname,$@.$(IMAS_MAJOR).$(IMAS_MINOR) $^ $(LIBS)

libimas-ifort.a: ids_schemas_ifort.o utilities_copy_struct_ifort.o utilities_deallocate_struct_ifort.o $(IDSOBJECTS_ifort) ids_routines_ifort.o $(DEP_ifort)
	ar rvs $@ $^

ids_routines_ifort.o: ids_routines.f90 utilities_copy_struct_ifort.o utilities_deallocate_struct_ifort.o $(IDSOBJECTS_ifort)
	$(F90_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) ids_routines.f90 -o $@

ids_schemas_ifort.o: %_ifort.o:%.f90
	mkdir -p $(MODDIR_ifort)
	$(F90_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
utilities_copy_struct_ifort.o utilities_deallocate_struct_ifort.o: %_ifort.o:%.f90 ids_schemas_ifort.o
	$(F90_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_put_ifort.o,$(IDSOBJECTS)): %_put_ifort.o : %_put.f90 %_copy_ifort.o ids_schemas_ifort.o 
	$(F90_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_put_non_timed_ifort.o,$(IDSOBJECTS)): %_put_non_timed_ifort.o : %_put_non_timed.f90 %_copy_ifort.o ids_schemas_ifort.o
	$(F90_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_get_ifort.o %_put_slice_ifort.o %_get_slice_ifort.o %_copy_ifort.o,$(IDSOBJECTS)): %_ifort.o:%.f90 ids_schemas_ifort.o
	$(F90_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_copy_struct_ifort.o,$(IDSOBJECTS)): %_ifort.o:%.f90 ids_schemas_ifort.o utilities_copy_struct_ifort.o
	$(F90_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@
$(filter %_deallocate_struct_ifort.o,$(IDSOBJECTS)): %_ifort.o:%.f90 ids_schemas_ifort.o utilities_deallocate_struct_ifort.o
	$(F90_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $< -o $@

#----------------------- xslt ---------------------
# Test if all idsroutines are found to exist as files.
ifeq ($(words $(IDSROUTINES)), $(words $(wildcard $(IDSROUTINES))))
$(SOURCES): IDSDef2F90Routines.xsl xsd2copy_structures.xsl
	java net.sf.saxon.Transform -t -s:$(IDSDEF) -xsl:IDSDef2F90Routines.xsl
	java net.sf.saxon.Transform -t -s:$(IDSDEFXSD) -xsl:xsd2copy_structures.xsl
	java net.sf.saxon.Transform -t -s:$(IDSDEFXSD) -xsl:xsd2deallocate_structures.xsl
idsroutines:
else
# Need to generate, use an intermediate target idsroutines to force non-parallel execution.
$(SOURCES): idsroutines
idsroutines: IDSDef2F90Routines.xsl xsd2copy_structures.xsl
	java net.sf.saxon.Transform -t -s:$(IDSDEF) -xsl:IDSDef2F90Routines.xsl
	java net.sf.saxon.Transform -t -s:$(IDSDEFXSD) -xsl:xsd2copy_structures.xsl
	java net.sf.saxon.Transform -t -s:$(IDSDEFXSD) -xsl:xsd2deallocate_structures.xsl
endif

ids_schemas.f90: xsd2F90TypeDef.xsl
	(cp xsd2F90TypeDef.xsl ../xml/ ; cd ../xml/ ; \
	xsltproc xsd2F90TypeDef.xsl dd_physics_data_dictionary.xsd > ids_schemas.f90 ) ; \
	rm ../xml/xsd2F90TypeDef.xsl ; \
	mv ../xml/ids_schemas.f90 .

#----------------------- pkgconfig ---------------------
PC_FILES = imas-ifort.pc imas-gfortran.pc imas-pgi.pc imas-g95.pc

include ../Makefile.pkgconfig
endif # IMAS_FORTRAN=no?
