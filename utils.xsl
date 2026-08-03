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
    and shared by every version; generic interface names and specific procedure
    names, so that a generic can merge specifics from two versions and dispatch
    on type; and anything inside a string literal, since those carry Data
    Dictionary paths.

    The ids_routines front door IS suffixed, which is what gives a user a module
    naming the default version explicitly. Its bare spelling comes from the alias
    layer (see below), so `use ids_routines` still reaches the default version and
    sees every name bare.

    One thing this parameter does not do on its own: the .f90 file names are
    unsuffixed, so each version must be generated into its own directory.
  -->
  <xsl:param name="SUFFIX" as="xs:string" select="''"/>

  <!--
    IS_DEFAULT_VERSION - 'yes' (the default) or 'no'. Says which of two roles this
    generator run plays when a build compiles more than one Data Dictionary version
    into one library.

    'yes': this run owns everything there is exactly one of. The
    DD-version-independent ids_types module, and the alias layer that makes the bare,
    unsuffixed spellings mean *this* version. Its front door carries the shared
    procedures, including the serialization pair, which is why serialization is
    limited to this version - and limited loudly: ids_serialize prints
    "SERIALIZE: ERROR selecting IDS type" for any other version's IDS and then crashes
    reading back a buffer nothing wrote.

    'no': this run adds a version alongside it. It emits its own suffixed modules and
    nothing else: no ids_types (there is one, and it is shared), no alias layer (the
    bare names are already taken), and a front door that is re-exports only - no
    procedures, so it cannot make a procedure name ambiguous for a program that uses
    two front doors at once.

    A run with IS_DEFAULT_VERSION='no' must have a non-empty SUFFIX, or every module
    it emits collides with the default version's.
  -->
  <xsl:param name="IS_DEFAULT_VERSION" as="xs:string" select="'yes'"/>

  <xsl:variable name="is-default-version" as="xs:boolean"
    select="$IS_DEFAULT_VERSION = 'yes'"/>

  <!--
    Reject a parameter combination that would otherwise be discovered as a duplicate
    module thousands of lines into the Fortran compilation, or - worse, for a
    misspelled IS_DEFAULT_VERSION - as a silently missing ids_types module. Called by
    both generators, unconditionally: unlike check_versioned_names below, this has to
    run for an unsuffixed run too.
  -->
  <xsl:template name="check_generator_parameters">
    <xsl:if test="not($IS_DEFAULT_VERSION = ('yes', 'no'))">
      <xsl:message terminate="yes">
IS_DEFAULT_VERSION is '<xsl:value-of select="$IS_DEFAULT_VERSION"/>'; it must be 'yes' or 'no'.
</xsl:message>
    </xsl:if>
    <xsl:if test="not($is-default-version) and $SUFFIX = ''">
      <xsl:message terminate="yes">
IS_DEFAULT_VERSION='no' needs a non-empty SUFFIX: without one, every module this run emits has the same name as the default version's.
</xsl:message>
    </xsl:if>
  </xsl:template>

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
    <xsl:sequence select="local:versioned-name(local:schemas-module-base($ids))"/>
  </xsl:function>

  <!-- The same module name without the version suffix: the bare spelling the alias
       layer declares for it. Same reason as local:ids-type-base below - one place
       spells 'ids_schemas_', for both spellings. -->
  <xsl:function name="local:schemas-module-base" as="xs:string">
    <xsl:param name="ids" as="xs:string"/>
    <xsl:sequence select="concat('ids_schemas_', $ids)"/>
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
    <xsl:sequence select="local:versioned-name(local:ids-type-base($dd-type))"/>
  </xsl:function>

  <!-- The same derived type name without the version suffix: the base name
       local:versioned-name is handed, and therefore the bare spelling the alias
       layer declares for it. Split out of local:ids-type so that the 'ids_' prefix
       is written once for both spellings. -->
  <xsl:function name="local:ids-type-base" as="xs:string">
    <xsl:param name="dd-type" as="xs:string"/>
    <xsl:sequence select="concat('ids_', $dd-type)"/>
  </xsl:function>

  <!-- The per-IDS routine modules IDSDef2F90Routines.xsl emits, as name suffixes to
       an IDS name. The utilities half of that generator emits six of the eight; the
       two missing ones are checked anyway (see check_versioned_names) because a
       guard over a superset of the emitted names cannot let a bad name through. -->
  <xsl:variable name="ids-routine-module-kinds" as="xs:string*"
    select="('_put_struct', '_put_slice_struct', '_get_struct', '_get_slice_struct',
             '_delete', '_copy_struct', '_deallocate_struct', '_validate_struct')"/>

  <!-- The same list for the utilities half, which is the per-IDS list less the two
       kinds that half does not emit: slicing a get and deleting are per-IDS
       operations, so there is no utilities_get_slice_struct or utilities_delete.
       Expressed as a filter rather than a second list so that the relationship
       between the two is visible and a new routine kind cannot be added to one and
       forgotten in the other.

       The alias layer needs this exact set, not a superset: a bare module that
       re-exports a module nobody emitted does not compile. -->
  <xsl:variable name="utilities-routine-module-kinds" as="xs:string*"
    select="$ids-routine-module-kinds[. != '_get_slice_struct' and . != '_delete']"/>

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
         this template appends the suffix itself, below, so it goes through
         local:ids-type-base rather than local:ids-type. local:structtypename and
         local:ids-type-base are the same functions the generators call, so the type
         half of this list cannot drift from what it is guarding; the module half is
         spelled out, since the routine module names are built inline at their use
         sites. -->
    <xsl:variable name="base-names" as="xs:string*"
      select="(for $f in //field[@data_type='structure' or @data_type='struct_array']
                 return local:ids-type-base(local:structtypename($f)),
               for $i in /IDSs/IDS return local:ids-type-base(string($i/@name)),
               for $i in /IDSs/IDS return local:schemas-module-base(string($i/@name)),
               'ids_utilities',
               'ids_schemas',
               'ids_routines',
               for $k in $ids-routine-module-kinds return concat('utilities', $k),
               for $i in /IDSs/IDS return
                 for $k in $ids-routine-module-kinds return concat(string($i/@name), $k))"/>
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

  <!--
    THE ALIAS LAYER

    With a non-empty SUFFIX every module and every derived type whose spelling
    depends on the Data Dictionary version is named for that version. The alias
    layer gives each of them its bare, unsuffixed spelling back, as the *default*
    version: `ids_equilibrium` is not a second type, it is a second spelling of
    `ids_equilibrium_v4_1_1`. That is what lets existing programs, the generated
    test suite and the identifiers library compile with no source change.

    Two shapes, one per kind of module.

    A module that exports only procedures (the routine modules) needs nothing but a
    plain re-export: procedure and generic interface names are never suffixed, so
    they already arrive bare. That is local:alias_module.

    A module that declares derived types (the utilities module, the per-IDS schema
    modules) needs one `only:` rename per type, and a plain `use` of the same module
    on top so that everything else it exports - the generic interfaces, the kind
    parameters it re-exports from ids_types - still comes through. Emitting the plain
    `use` is what makes coverage of the non-type half automatic rather than a list
    that can fall behind. That is alias_type_use, called once per type inside a
    module the caller opens itself.

    Nothing suffixed depends on anything in this layer, so the whole bare surface can
    be re-pointed at a different version by regenerating it alone.
  -->

  <!-- A bare module that re-exports its suffixed counterpart wholesale. $base is the
       bare spelling by construction: it is the name local:versioned-name is handed. -->
  <xsl:template name="alias_module">
    <xsl:param name="base" as="xs:string"/>
    <xsl:text>module </xsl:text><xsl:value-of select="$base"/><xsl:text>
  use </xsl:text><xsl:value-of select="local:versioned-name($base)"/><xsl:text>
end module
</xsl:text>
  </xsl:template>

  <!-- One `use <module>, only: <bare type> => <suffixed type>` statement.

       Split over two lines on purpose: the longest Data Dictionary type name is 57
       characters and its suffixed form can reach the full 63, which together with
       the module name would run past Fortran's 132-column limit. Two lines fit any
       name the 63-character identifier limit allows. -->
  <xsl:template name="alias_type_use">
    <xsl:param name="module-base" as="xs:string"/>
    <xsl:param name="dd-type" as="xs:string"/>
    <xsl:text>  use </xsl:text>
    <xsl:value-of select="local:versioned-name($module-base)"/>
    <xsl:text>, only: </xsl:text>
    <xsl:value-of select="local:ids-type-base($dd-type)"/>
    <xsl:text> &amp;
       =&gt; </xsl:text>
    <xsl:value-of select="local:ids-type($dd-type)"/>
    <xsl:text>
</xsl:text>
  </xsl:template>

  <!-- Emit a declaration and its Data Dictionary documentation without letting the
       version suffix push generated Fortran past 132 columns.  The historical
       unsuffixed spelling deliberately keeps using local:commentstring so SUFFIX=''
       remains byte-for-byte identical.  Versioned declarations put an overlong
       comment on following Fortran comment lines, where the complete prefix is known
       and each line can be bounded independently. -->
  <xsl:function name="local:declaration-with-comment" as="xs:string">
    <xsl:param name="declaration" as="xs:string"/>
    <xsl:param name="documentation" as="xs:string"/>
    <xsl:variable name="inline" as="xs:string"
      select="concat($declaration, ' !', $documentation)"/>
    <xsl:sequence select="if ($SUFFIX = '')
                          then concat($declaration, ' !', local:commentstring($documentation))
                          else if (string-length($inline) le 132)
                          then $inline
                          else concat($declaration, '&#10;',
                                      local:wrapped-comment($documentation, '      ! '))"/>
  </xsl:function>

  <!-- Wrap one Fortran comment to the space left after its prefix. -->
  <xsl:function name="local:wrapped-comment" as="xs:string">
    <xsl:param name="comment" as="xs:string"/>
    <xsl:param name="prefix" as="xs:string"/>
    <xsl:variable name="width" as="xs:integer" select="132 - string-length($prefix)"/>
    <xsl:sequence select="if (string-length($comment) le $width)
                          then concat($prefix, $comment)
                          else concat($prefix, substring($comment, 1, $width), '&#10;',
                                      local:wrapped-comment(
                                        substring($comment, $width + 1), $prefix))"/>
  </xsl:function>

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
