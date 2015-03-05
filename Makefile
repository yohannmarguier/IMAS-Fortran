IDSDEF	= ../xml/IDSDef.xml

all: makefile-gen
	$(MAKE) -f makefile-gen ids_schemas.f90
	$(MAKE) -f makefile-gen ids_routines.f90
	$(MAKE) -f makefile-gen

makefile-gen: IDSDef2F90Makefile.xsl
	xsltproc IDSDef2F90Makefile.xsl $(IDSDEF)

install:
	$(MAKE) -f makefile-gen install

clean: 
	$(MAKE) -f makefile-gen clean

clean-src:
	$(MAKE) -f makefile-gen clean-src
	rm -f makefile-gen
	
	
test: 
	$(MAKE) -C tests/generator test

test-clean: 
	$(MAKE) -C tests/generator clean

test-clean-src:
	$(MAKE) -C tests/generator clean-src


