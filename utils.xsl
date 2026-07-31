<?xml version="1.0" encoding="UTF-8"?>
<?modxslt-stylesheet type="text/xsl" media="fuffa, screen and $GET[stylesheet]" href="./%24GET%5Bstylesheet%5D" alternate="no" title="Translation using provided stylesheet" charset="ISO-8859-1" ?>
<?modxslt-stylesheet type="text/xsl" media="screen" alternate="no" title="Show raw source of the XML file" charset="ISO-8859-1" ?>
<xsl:stylesheet xmlns:yaslt="http://www.mod-xslt2.com/ns/2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" extension-element-prefixes="yaslt" xmlns:fn="http://www.w3.org/2005/02/xpath-functions" xmlns:local="http://www.example.com/functions/local" exclude-result-prefixes="local xs">
  <!-- -->
  <xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>

  <!--
    SUFFIX - appended to every module name and every derived type name whose
    spelling depends on the Data Dictionary version, so that two DD versions can
    be compiled into one build (e.g. SUFFIX='_v4_1_1' yields ids_utilities_v4_1_1,
    ids_schemas_equilibrium_v4_1_1, ids_equilibrium_v4_1_1,
    equilibrium_put_struct_v4_1_1).

    Defaults to the empty string, which reproduces the historical, unsuffixed
    spellings byte for byte.

    Declared here rather than in either generator because both must spell the
    shared names (ids_utilities, ids_schemas_<ids>) identically: one declaration,
    one place to pass it.

    Deliberately NOT suffixed: the ids_types module and everything it declares
    (the kinds, the invalid values, the abstract IDS_base type) and the
    al_defs/al_low_level_wrap wrapper layer - those are DD-version-independent
    and shared by every version; the ids_routines front door, which keeps its
    bare name while its use statements reach the suffixed modules underneath;
    generic interface names and specific procedure names, so that a generic can
    merge specifics from two versions and dispatch on type; and anything inside
    a string literal, since those carry Data Dictionary paths.

    One thing this parameter does not do on its own: the .f90 file names are
    unsuffixed, so each version must be generated into its own directory.
  -->
  <xsl:param name="SUFFIX" as="xs:string" select="''"/>

  <!--
    Keep the version suffix intact even when appending it would exceed Fortran's
    63-character identifier limit. Unsuffixed output takes the first branch and
    is therefore unchanged byte for byte.
  -->
  <xsl:function name="local:versioned-name" as="xs:string">
    <xsl:param name="base" as="xs:string"/>
    <xsl:variable name="available" as="xs:integer" select="63 - string-length($SUFFIX)"/>
    <xsl:sequence select="if ($SUFFIX = '' or string-length($base) le $available)
                          then concat($base, $SUFFIX)
                          else if ($available lt 8)
                          then concat(substring($base, 1, $available), $SUFFIX)
                          else concat(substring($base, 1, $available - 7), '_',
                                      substring($base, string-length($base) - 5), $SUFFIX)"/>
  </xsl:function>

  <!-- The two module names the generators exchange: IDSDef2F90TypeDef.xsl declares
       them, IDSDef2F90Routines.xsl writes use statements for them. Spelled once
       here so the declaration and the reference cannot drift apart. -->
  <xsl:function name="local:utilities-module" as="xs:string">
    <xsl:sequence select="local:versioned-name('ids_utilities')"/>
  </xsl:function>

  <xsl:function name="local:schemas-module" as="xs:string">
    <xsl:param name="ids" as="xs:string"/>
    <xsl:sequence select="local:versioned-name(concat('ids_schemas_', $ids))"/>
  </xsl:function>

  <!-- The Fortran derived type a Data Dictionary type name maps to. Same reason as
       the two module names above: IDSDef2F90TypeDef.xsl declares these types and
       IDSDef2F90Routines.xsl declares variables of them, so the 'ids_' prefix and
       the version suffix are spelled once, here.

       Takes the Data Dictionary type name - what local:structtypename returns for a
       structure or struct_array field, or an IDS's own @name - not an already
       prefixed one. -->
  <xsl:function name="local:ids-type" as="xs:string">
    <xsl:param name="dd-type" as="xs:string"/>
    <xsl:sequence select="local:versioned-name(concat('ids_', $dd-type))"/>
  </xsl:function>

  <!--
    A Fortran identifier is limited to 63 characters (F2003 and later, enforced by
    gfortran). Retain the entire version suffix and shorten only an overlong base
    name. Reject a suffix that leaves no room for a base name, or a dictionary
    whose shortened names collide.

    Skipped entirely when SUFFIX is empty: the unsuffixed names are what the DD
    has always produced, and they already fit.

    Called by both generators, and covering the names of both, because either one
    can be the first to run: whichever it is must fail before it writes a source
    file full of truncated or colliding identifiers.
  -->
  <xsl:template name="check_versioned_names">
    <xsl:variable name="max-length" as="xs:integer" select="63"/>
    <!-- Every name either generator puts through local:versioned-name, as base names:
         this template appends the suffix itself, below, so it cannot call
         local:ids-type - hence the one further copy of the 'ids_' prefix here.
         local:structtypename is the same function the generators call, so the type
         half of this list cannot drift from what it is guarding; the module half is
         spelled out, since the routine module names are built inline at their use
         sites. -->
    <xsl:variable name="routine-module-kinds" as="xs:string*"
      select="('_put_struct', '_put_slice_struct', '_get_struct', '_get_slice_struct',
               '_delete', '_copy_struct', '_deallocate_struct', '_validate_struct')"/>
    <xsl:variable name="base-names" as="xs:string*"
      select="(for $f in //field[@data_type='structure' or @data_type='struct_array']
                 return concat('ids_', local:structtypename($f)),
               for $i in /IDSs/IDS return concat('ids_', string($i/@name)),
               for $i in /IDSs/IDS return concat('ids_schemas_', string($i/@name)),
               'ids_utilities',
               'ids_schemas',
               for $k in $routine-module-kinds return concat('utilities', $k),
               for $i in /IDSs/IDS return
                 for $k in $routine-module-kinds return concat(string($i/@name), $k))"/>
    <xsl:if test="string-length($SUFFIX) ge $max-length">
      <xsl:message terminate="yes">
SUFFIX '<xsl:value-of select="$SUFFIX"/>' is <xsl:value-of select="string-length($SUFFIX)"/> characters; it must leave room for at least one base-name character within the <xsl:value-of select="$max-length"/>-character Fortran identifier limit.
</xsl:message>
    </xsl:if>
    <xsl:variable name="versioned-names" as="xs:string*"
      select="for $name in distinct-values($base-names) return local:versioned-name($name)"/>
    <xsl:variable name="collisions" as="xs:string*"
      select="distinct-values($versioned-names[count(index-of($versioned-names, .)) gt 1])"/>
    <xsl:if test="exists($collisions)">
      <xsl:message terminate="yes">
SUFFIX '<xsl:value-of select="$SUFFIX"/>' would make generated Fortran identifiers collide:
<xsl:for-each select="$collisions">  <xsl:value-of select="."/>
</xsl:for-each></xsl:message>
    </xsl:if>
  </xsl:template>

  <!-- function that truncate strings to 132 chars and adding '...' to mark the truncation -->
  <xsl:function name="local:truncatestring" as="xs:string">
    <xsl:param name="longstring" as="xs:string"/>
    <xsl:variable name="size" as="xs:integer" select="string-length($longstring)"/>
    <xsl:variable name="truncsize" as="xs:integer" select="132"/>
    <xsl:choose>
      <xsl:when test="$size &gt; $truncsize">
	<xsl:value-of select="concat(substring($longstring,1,($truncsize)-3),'...')"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$longstring"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- function that breaks long strings into smaller ones over several lines (adding specified character at the end and begin of each new lines) -->
  <xsl:function name="local:breakstring" as="xs:string">
    <xsl:param name="longstring" as="xs:string"/>
    <xsl:param name="breakchar" as="xs:string"/> 
    <xsl:variable name="cursize" as="xs:integer" select="string-length($longstring)"/>
    <xsl:variable name="breaksize" as="xs:integer" select="130"/>
    <xsl:variable name="breakseq" as="xs:string" select="concat($breakchar,'&#10; ',$breakchar)"/> 
    <xsl:choose>
      <xsl:when test="$cursize &gt; $breaksize">
	<xsl:value-of select="concat(substring($longstring,1,$breaksize),$breakseq,local:breakstring(substring($longstring,$breaksize+1,$cursize),$breakchar))"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$longstring"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- function that breaks long strings into smaller continuation lines to respect the 132 chars limit of the Fortran standard -->
  <xsl:function name="local:continuedstring" as="xs:string">
    <xsl:param name="longstring" as="xs:string"/>
    <xsl:variable name="breakchar" as="xs:string" select="'&amp;'"/> 
    <xsl:variable name="cursize" as="xs:integer" select="string-length($longstring)"/>
    <xsl:variable name="breaksize" as="xs:integer" select="130"/>
    <xsl:variable name="breakseq" as="xs:string" select="concat($breakchar,'&#10; ',$breakchar)"/> 
    <xsl:choose>
      <xsl:when test="$cursize &gt; $breaksize">
	<xsl:value-of select="concat(substring($longstring,1,$breaksize),$breakseq,local:breakstring(substring($longstring,$breaksize+1,$cursize),$breakchar))"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$longstring"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- function that gives the Data Dictionary type name a structure or struct_array field
       declares: its structure_reference, except for the 'self' sentinel, which means the
       field defines its own type and so is named after the field. Prepend 'ids_' for the
       Fortran spelling. -->
  <xsl:function name="local:structtypename" as="xs:string">
    <xsl:param name="field" as="element()"/>
    <xsl:sequence select="if ($field/@structure_reference = 'self')
                          then string($field/@name)
                          else string($field/@structure_reference)"/>
  </xsl:function>

  <!-- function that breaks long strings for comments that respects the 132 chars limit of the Fortran standard -->
  <xsl:function name="local:commentstring" as="xs:string">
    <xsl:param name="longstring" as="xs:string"/>
    <xsl:variable name="breakchar" as="xs:string" select="'!'"/> 
    <xsl:variable name="cursize" as="xs:integer" select="string-length($longstring)"/>
    <xsl:variable name="breaksize" as="xs:integer" select="130"/>
    <xsl:variable name="breakseq" as="xs:string" select="concat($breakchar,'&#10; ',$breakchar)"/> 
    <xsl:choose>
      <xsl:when test="$cursize &gt; $breaksize">
	<xsl:value-of select="concat(substring($longstring,1,$breaksize),$breakseq,local:breakstring(substring($longstring,$breaksize+1,$cursize),$breakchar))"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$longstring"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
</xsl:stylesheet>
