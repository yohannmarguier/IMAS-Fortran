include ../Makefile.common

ifeq ("no","$(FORTRAN)")
$(warning "Ignoring fortraninterface (FORTRAN=no).")
all:
clean:
clean-src:
install:
else

IDSDEF	= ../xml/IDSDef.xml

all: makefile-gen ids_routines.f90 ids_schemas.f90
	$(MAKE) -f makefile-gen

ids_routines.f90: makefile-gen
	$(MAKE) -f makefile-gen ids_routines.f90
ids_schemas.f90: makefile-gen
	$(MAKE) -f makefile-gen ids_schemas.f90

makefile-gen: IDSDef2F90Makefile.xsl
	xsltproc IDSDef2F90Makefile.xsl $(IDSDEF)

install: makefile-gen pkgconfig_install
	$(MAKE) -f makefile-gen install

clean: makefile-gen
	$(MAKE) -f makefile-gen clean

clean-src: makefile-gen
	$(MAKE) -f makefile-gen clean-src
	rm -f makefile-gen

test:
	$(MAKE) -C tests/generator test

test-clean:
	$(MAKE) -C tests/generator clean

test-clean-src:
	$(MAKE) -C tests/generator clean-src

PC_FILES = imas-ifort.pc imas-gfortran.pc imas-pgi.pc imas-g95.pc

include ../Makefile.pkgconfig
endif # FORTRAN=no?
