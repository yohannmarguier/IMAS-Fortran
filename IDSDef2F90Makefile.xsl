<?xml version="1.0" encoding="UTF-8"?>
<?modxslt-stylesheet type="text/xsl" media="fuffa, screen and $GET[stylesheet]" href="./%24GET%5Bstylesheet%5D" alternate="no" title="Translation using provided stylesheet" charset="ISO-8859-1" ?>
<?modxslt-stylesheet type="text/xsl" media="screen" alternate="no" title="Show raw source of the XML file" charset="ISO-8859-1" ?>
<xsl:stylesheet xmlns:yaslt="http://www.mod-xslt2.com/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" version="1.0"
  extension-element-prefixes="yaslt exsl" xmlns:fn="http://www.w3.org/2005/02/xpath-functions">
<!--<xsl:stylesheet xmlns:yaslt="http://www.mod-xslt2.com/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="1.0" extension-element-prefixes="yaslt" xmlns:fn="http://www.w3.org/2005/02/xpath-functions">-->

<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>
<!-- This XSL translates IDSDef.xml to Makefile building the modular Fortran 90 interface for IDSs -->


<xsl:template match="/IDSs">
  <exsl:document href="makefile-gen" method="text">
# -*- makefile -*- #
include ../Makefile.common

F90_g95         = x86_64-unknown-linux-gnu-g95
MODDIR_g95      = amd64_g95
COPTS_g95       = -r8 -ftrace=full -fPIC -fno-second-underscore -ffree-line-length-huge -g -fmod=$(MODDIR_g95)/
INCDIR_g95      = -Iamd64_g95

F90_gfortran    = gfortran
MODDIR_gfortran = amd64_gfortran
COPTS_gfortran  = -fdefault-real-8 -fPIC -fno-second-underscore -ffree-line-length-none -g -J$(MODDIR_gfortran)/
INCDIR_gfortran = -I$(MODDIR_gfortran)

F90_pgi         = pgf90
MODDIR_pgi      = amd64_pgi
COPTS_pgi       = -r8  -Mnosecond_underscore -fPIC -module=./$(MODDIR_pgi) -g
INCDIR_pgi      = -I$(MODDIR_pgi)

F90_ifort       = ifort
MODDIR_ifort    = amd64_ifort
COPTS_ifort     = -r8 -O0 -assume no2underscore  -fPIC -module $(MODDIR_ifort) -shared-intel
INCDIR_ifort    = -I$(MODDIR_ifort)

IDSDEF          = ../xml/IDSDef.xml
<!--XSDDIR          = ../xml
DDTOP           = DD_TOP.xsd -->
LIBS            =  -L../lowlevel -lUALLowLevel -lm

ifeq "$(strip $(G95))" "yes"
TARGETS += libUALFORTRANInterface_g95.so libUALFORTRANInterface_g95.a
INSTALL_TARGETS += amd64_g95
endif

ifeq "$(strip $(GFORTRAN))" "yes"
TARGETS += libUALFORTRANInterface_gfortran.so libUALFORTRANInterface_gfortran.a
INSTALL_TARGETS += amd64_gfortran
endif

ifeq "$(strip $(PGI))" "yes"
TARGETS += libUALFORTRANInterface_pgi.so libUALFORTRANInterface_pgi.a
INSTALL_TARGETS += amd64_pgi
endif

ifeq "$(strip $(IFORT))" "yes"
TARGETS += libUALFORTRANInterface_ifort.so libUALFORTRANInterface_ifort.a
INSTALL_TARGETS += amd64_ifort
endif

all: ids_routines.f90 $(TARGETS)

install: all $(addprefix install_,$(INSTALL_TARGETS))
&#009;cp *.so $(INSTALL)/lib

install_amd64_pgi:
&#009;mkdir -p $(INSTALL)/include/amd64_pgi
&#009;cp amd64_pgi/*.mod $(INSTALL)/include/amd64_pgi
install_amd64_g95:
&#009;mkdir -p $(INSTALL)/include/amd64_g95
&#009;cp amd64_g95/*.mod $(INSTALL)/include/amd64_g95
install_amd64_ifort:
&#009;mkdir -p $(INSTALL)/include/amd64_ifort
&#009;cp amd64_ifort/*.mod $(INSTALL)/include/amd64_ifort
install_amd64_gfortran:
&#009;mkdir -p $(INSTALL)/include/amd64_gfortran
&#009;cp amd64_gfortran/*.mod $(INSTALL)/include/amd64_gfortran

clean:
&#009;rm -rf *.o *.mod  *.so *~ amd64_g95 amd64_gfortran amd64_pgi amd64_ifort *.a

clean-src: clean
&#009;rm -f ids_schemas.f90 ids_routines.f90 <xsl:for-each select="IDS"> <xsl:value-of select="@name"/>.f90 </xsl:for-each>


#--------------------- g95 ------------------------
libUALFORTRANInterface_g95.so: ids_schemas_g95.o <xsl:for-each select="IDS"> ids_<xsl:value-of select="@name"/>_g95.o </xsl:for-each> ids_routines_g95.o
&#009;$(F90_g95) $(COPTS_g95) -o $@ -shared $^ $(LIBS)

libUALFORTRANInterface_g95.a: ids_schemas_g95.o  <xsl:for-each select="IDS"> ids_<xsl:value-of select="@name"/>_g95.o </xsl:for-each> ids_routines_g95.o
&#009;ar rvs $@ $^

ids_routines_g95.o: ids_routines.f90 <xsl:for-each select="IDS">ids_<xsl:value-of select="@name"/>_g95.o </xsl:for-each>
&#009;$(F90_g95) -c $(COPTS_g95) $(INCDIR_g95) ids_routines.f90 -o $@

ids_schemas_g95.o: ids_schemas.f90
&#009;mkdir -p $(MODDIR_g95)
&#009;$(F90_g95) -c $(COPTS_g95) $(INCDIR_g95) $&lt; -o $@

<xsl:for-each select="IDS">
ids_<xsl:value-of select="@name"/>_g95.o: <xsl:value-of select="@name"/>.f90 ids_schemas_g95.o
&#009;$(F90_g95) -c $(COPTS_g95) $(INCDIR_g95) $&lt; -o $@
</xsl:for-each>


#--------------------- gfortran --------------
libUALFORTRANInterface_gfortran.so: ids_schemas_gfortran.o <xsl:for-each select="IDS"> ids_<xsl:value-of select="@name"/>_gfortran.o </xsl:for-each> ids_routines_gfortran.o
&#009;$(F90_gfortran) $(COPTS_gfortran) -o $@ -shared $^ $(LIBS)

libUALFORTRANInterface_gfortran.a: ids_schemas_gfortran.o <xsl:for-each select="IDS"> ids_<xsl:value-of select="@name"/>_gfortran.o </xsl:for-each> ids_routines_gfortran.o
&#009;ar rvs $@ $^

ids_routines_gfortran.o: ids_routines.f90 <xsl:for-each select="IDS">ids_<xsl:value-of select="@name"/>_gfortran.o </xsl:for-each>
&#009;$(F90_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) ids_routines.f90 -o $@

ids_schemas_gfortran.o: ids_schemas.f90
&#009;mkdir -p $(MODDIR_gfortran)
&#009;$(F90_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $&lt; -o $@

<xsl:for-each select="IDS">
ids_<xsl:value-of select="@name"/>_gfortran.o: <xsl:value-of select="@name"/>.f90 ids_schemas_gfortran.o
&#009;$(F90_gfortran) -c $(COPTS_gfortran) $(INCDIR_gfortran) $&lt; -o $@
</xsl:for-each>


#--------------------- PGI ------------------------
libUALFORTRANInterface_pgi.so: ids_schemas_pgi.o <xsl:for-each select="IDS"> ids_<xsl:value-of select="@name"/>_pgi.o </xsl:for-each> ids_routines_pgi.o $(DEP_PGI)
&#009;$(F90_pgi) $(COPTS_pgi) -o $@ -shared $^ $(LIBS)

libUALFORTRANInterface_pgi.a: ids_schemas_pgi.o <xsl:for-each select="IDS"> ids_<xsl:value-of select="@name"/>_pgi.o </xsl:for-each> ids_routines_pgi.o $(DEP_PGI)
&#009;ar rvs $@ $^

ids_routines_pgi.o: ids_routines.f90 <xsl:for-each select="IDS">ids_<xsl:value-of select="@name"/>_pgi.o </xsl:for-each>
&#009;$(F90_pgi) -c $(COPTS_pgi) ids_routines.f90 -o $@

ids_schemas_pgi.o: ids_schemas.f90
&#009;mkdir -p $(MODDIR_pgi)
&#009;$(F90_pgi) -c $(COPTS_pgi) $&lt; -o $@

<xsl:for-each select="IDS">
ids_<xsl:value-of select="@name"/>_pgi.o: <xsl:value-of select="@name"/>.f90 ids_schemas_pgi.o
&#009;$(F90_pgi) -c $(COPTS_pgi) $&lt; -o $@
</xsl:for-each>


#--------------------- ifort --------------
libUALFORTRANInterface_ifort.so: ids_schemas_ifort.o <xsl:for-each select="IDS"> ids_<xsl:value-of select="@name"/>_ifort.o </xsl:for-each> ids_routines_ifort.o $(DEP_IFORT)
&#009;$(F90_ifort) $(COPTS_ifort) -o $@ -shared $^ $(LIBS)

libUALFORTRANInterface_ifort.a: ids_schemas_ifort.o <xsl:for-each select="IDS"> ids_<xsl:value-of select="@name"/>_ifort.o </xsl:for-each> ids_routines_ifort.o $(DEP_IFORT)
&#009;ar rvs $@ $^

ids_routines_ifort.o: ids_routines.f90 <xsl:for-each select="IDS">ids_<xsl:value-of select="@name"/>_ifort.o </xsl:for-each>
&#009;$(F90_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) ids_routines.f90 -o $@

ids_schemas_ifort.o: ids_schemas.f90
&#009;mkdir -p $(MODDIR_ifort)
&#009;$(F90_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $&lt; -o $@

<xsl:for-each select="IDS">
ids_<xsl:value-of select="@name"/>_ifort.o: <xsl:value-of select="@name"/>.f90 ids_schemas_ifort.o
&#009;$(F90_ifort) -c $(COPTS_ifort) $(INCDIR_ifort) $&lt; -o $@
</xsl:for-each>


#----------------------- xslt ---------------------
ids_routines.f90: IDSDef2F90Routines.xsl
&#009;java net.sf.saxon.Transform -t -s:$(IDSDEF) -xsl:IDSDef2F90Routines.xsl

ids_schemas.f90: xsd2F90TypeDef.xsl
&#009;(cp xsd2F90TypeDef.xsl ../xml/ ; cd ../xml/ ; \
&#009;xsltproc xsd2F90TypeDef.xsl dd_physics_data_dictionary.xsd > ids_schemas.f90 ) ; \
&#009;rm ../xml/xsd2F90TypeDef.xsl ; \
&#009;mv ../xml/ids_schemas.f90 .

<!-- The old method does not work because the XSDs are now distributed in sub-folders. The XSL transform must be in the same folder as DDTOP to handle the Includes
&#009;ln -s $(XSDDIR)/*.xsd
&#009;xsltproc xsd2F90TypeDef.xsl $(DDTOP) > ids_schemas.f90
&#009;rm *.xsd -->


</exsl:document>
</xsl:template>
</xsl:stylesheet>
