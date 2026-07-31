<?xml version="1.0" encoding="UTF-8"?>
<?modxslt-stylesheet type="text/xsl" media="fuffa, screen and $GET[stylesheet]" href="./%24GET%5Bstylesheet%5D" alternate="no" title="Translation using provided stylesheet" charset="ISO-8859-1" ?>
<?modxslt-stylesheet type="text/xsl" media="screen" alternate="no" title="Show raw source of the XML file" charset="ISO-8859-1" ?>
<xsl:stylesheet xmlns:yaslt="http://www.mod-xslt2.com/ns/2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" extension-element-prefixes="yaslt" xmlns:fn="http://www.w3.org/2005/02/xpath-functions" xmlns:local="http://www.example.com/functions/local" exclude-result-prefixes="local xs">
<!-- -->
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>
<!-- -->
<xsl:param name="DD_GIT_DESCRIBE" as="xs:string" required="yes"/>
<xsl:param name="AL_GIT_DESCRIBE" as="xs:string" required="yes"/>

<!-- SUFFIX and local:versioned-name are declared in utils.xsl, included below and
     shared with IDSDef2F90Routines.xsl: the two generators must spell the names they
     exchange identically. The modules go through local:utilities-module and
     local:schemas-module, the derived types declared here through local:ids-type -
     which is also what the other generator's type(...) declarations and its
     `only:` rename clauses call. -->

<xsl:variable name="version_regex" select="'^([0-9]+)\.([0-9]+)\.([0-9]+)([+-].*)?$'"/>
<xsl:variable name="DD_MAJOR" as="xs:integer" select="xs:integer(replace($DD_GIT_DESCRIBE, $version_regex, '$1'))"/>
<xsl:variable name="DD_MINOR" as="xs:integer" select="xs:integer(replace($DD_GIT_DESCRIBE, $version_regex, '$2'))"/>
<xsl:variable name="DD_PATCH" as="xs:integer" select="xs:integer(replace($DD_GIT_DESCRIBE, $version_regex, '$3'))"/>

<xsl:variable name="HLI_MAJOR" as="xs:integer" select="xs:integer(replace($AL_GIT_DESCRIBE, $version_regex, '$1'))"/>
<xsl:variable name="HLI_MINOR" as="xs:integer" select="xs:integer(replace($AL_GIT_DESCRIBE, $version_regex, '$2'))"/>
<xsl:variable name="HLI_PATCH" as="xs:integer" select="xs:integer(replace($AL_GIT_DESCRIBE, $version_regex, '$3'))"/>
<!-- TOP -->

<xsl:include href="utils.xsl"/>


<!-- check_versioned_names lives in utils.xsl, next to local:versioned-name, so that
     it guards the names both generators emit rather than only this one's. -->

<xsl:template match="/IDSs">
  <xsl:call-template name="check_generator_parameters"/>
  <xsl:if test="$SUFFIX != ''">
    <xsl:call-template name="check_versioned_names"/>
  </xsl:if>
  <!-- ids_types is Data Dictionary-version-independent and shared by every version, so
       only the default version's run emits it. A second version's run would emit a
       duplicate module - and one whose compile-time DD version constants disagree with
       the first, which is why those constants report the default version (see #45). -->
  <xsl:if test="$is-default-version">
  <xsl:result-document href="ids_types.f90">
! IDS FORTRAN 90 type definitions
! Contains the type definition of all IDSs
<!-- -->
<!-- ======================= ====   Begin : Common Types definition ==== =====================-->
module ids_types    ! declare the size of real and integer variables to be used in all sub-trees, along with the invalid numbers.

  use iso_c_binding, only: ids_real => c_double, &amp;
                           ids_int  => c_int32_t, &amp;
                           ids_complex => c_double_complex
<!--
Possible way to extend the types to single precision floats, c_int, etc 
  !!use iso_c_binding, only:  &amp;
  !!                        ids_c_double => c_double, &amp;
  !!                        ids_c_float  => c_float, &amp;
  !!                        ids_c_int    => c_int
  !! real(ids_c_float), parameter :: ids_c_float_invalid = -9.0E30_ids_c_float
 -->
  implicit none

  integer(ids_int),  parameter :: ids_string_length   = 132_ids_int

  integer(ids_int),  parameter :: ids_int_invalid     = -999999999_ids_int
  real(ids_real),    parameter :: ids_real_invalid    = -9.0E40_ids_real
  complex(ids_real), parameter :: ids_complex_invalid = CMPLX(-9.0E40_ids_real,-9.0E40_ids_real,8)

  integer(ids_int), parameter :: ids_data_dictionary_version(3) = (/ ids_int_invalid , ids_int_invalid , ids_int_invalid /)  !! NOTE: to be filled with e.g. (/3,7,4/).

  ! ids_is_valid - Function for testing the validity of scalar and arrays of integers and real numbers
  interface ids_is_valid
     module procedure &amp;
          ids_is_valid_int, &amp;
          ids_is_valid_ids_real, &amp;
          ids_is_valid_array_of_int, &amp;
          ids_is_valid_array_of_real
  end interface

  ! Version info
  ! HLI version, currently this is the same as the lowlevel version (see al_get_version)
  character(*), parameter :: al_fortran_version = '<xsl:value-of select="$AL_GIT_DESCRIBE"/>'
  integer(ids_int), parameter :: al_fortran_major_version = <xsl:value-of select="$HLI_MAJOR"/>
  integer(ids_int), parameter :: al_fortran_minor_version = <xsl:value-of select="$HLI_MINOR"/>
  integer(ids_int), parameter :: al_fortran_patch_version = <xsl:value-of select="$HLI_PATCH"/>
  ! DD version
  character(*), parameter :: al_dd_version = '<xsl:value-of select="$DD_GIT_DESCRIBE"/>'
  integer(ids_int), parameter :: al_dd_major_version = <xsl:value-of select="$DD_MAJOR"/>
  integer(ids_int), parameter :: al_dd_minor_version = <xsl:value-of select="$DD_MINOR"/>
  integer(ids_int), parameter :: al_dd_patch_version = <xsl:value-of select="$DD_PATCH"/>

  ! Base IDS type. Declared here, in the DD-version-independent module, so that
  ! every IDS type extends the same base type and shared polymorphic code (e.g.
  ! ids_serialize, declared as class(IDS_base)) accepts any IDS.
  type, abstract :: IDS_base
  end type

contains

  logical function ids_is_valid_int(in)
    implicit none
    integer(ids_int) :: in
    ids_is_valid_int = in .ne. ids_int_invalid
    return
  end function ids_is_valid_int

  logical function ids_is_valid_ids_real(in)
    real(ids_real) :: in
    ids_is_valid_ids_real = abs(in - ids_real_invalid) .gt. tiny(ids_real_invalid)
    return
  end function ids_is_valid_ids_real

  logical function ids_is_valid_array_of_int(in)
    integer(ids_int) :: in(:)
    ids_is_valid_array_of_int = .not. any( in(:) .eq. ids_int_invalid )
    return
  end function ids_is_valid_array_of_int

  logical function ids_is_valid_array_of_real(in)
    real(ids_real) :: in(:)
    ids_is_valid_array_of_real = .not. any( abs(in(:) - ids_real_invalid) .le. tiny(ids_real_invalid) )
    return
  end function ids_is_valid_array_of_real

  !!! to be defined if needed !!!
  !logical function ids_is_valid_array_of_complex(in)

end module ids_types
<!-- ======================= ====   End :Common Types definition ==== =====================-->
<!-- -->

<!-- -->
<!-- ======================= ====   Begin : Common Utility definition ==== =====================-->
</xsl:result-document>
  </xsl:if><!-- end of the default version's ids_types.f90 -->
<xsl:result-document href="ids_utilities.f90">
module <xsl:value-of select="local:utilities-module()"/>    ! declare the set of types common to all sub-trees

use ids_types  ! re-exports IDS_base to consumers of this module

<!-- Declare utilities types -->
<xsl:apply-templates select="/IDSs/utilities" mode="module"/> <!-- Original IDS structure -->

end module ! end of the utilities module
</xsl:result-document>
<!-- ======================= ====   End :Common Utility definition ==== =====================-->

<!-- ======================= ====   Begin : declare schema  ==== =====================-->

  <xsl:apply-templates select="IDS" mode="declare_in_file"/>

<!-- ======================= ====   Begin : alias layer  ==== =====================-->
<!-- Only worth emitting when there is a suffix to hide: with an empty SUFFIX the
     modules above already carry the bare names, and an alias module of the same
     name would be a duplicate. Skipping it is also what keeps an unsuffixed
     build's output directory free of files nothing compiles.

     And only from the default version's run: the bare spellings are what makes one
     version the default, so a second version emitting them would be a duplicate
     module rather than a second opinion. -->
  <xsl:if test="$SUFFIX != '' and $is-default-version">
    <xsl:result-document href="alias_ids_utilities.f90">
! Alias layer: the bare, unsuffixed spelling of every utilities type of the default
! Data Dictionary version (<xsl:value-of select="$DD_GIT_DESCRIBE"/>).
module ids_utilities
  use ids_types  ! the kind parameters and IDS_base, which the `only:` renames below would otherwise hide
  use <xsl:value-of select="local:utilities-module()"/>  ! everything, under its suffixed spelling
<xsl:for-each select="distinct-values(
        for $f in /IDSs/utilities/field[@data_type='structure' or @data_type='struct_array']
          return local:structtypename($f))"><xsl:call-template name="alias_type_use">
        <xsl:with-param name="module-base" select="'ids_utilities'"/>
        <xsl:with-param name="dd-type" select="."/>
      </xsl:call-template></xsl:for-each>end module
</xsl:result-document>
    <xsl:apply-templates select="IDS" mode="alias_in_file"/>
  </xsl:if>
<!-- ======================= ====   End : alias layer  ==== =====================-->

</xsl:template>
<!-- ============================  End : declare schema ========================= -->

<!--                                                                                                                                                -->
<!-- *********************************** TEMPLATES ********************************************* -->

<xsl:template match="IDS" mode="declare_set_c_data">
  module procedure set_c_data_<xsl:value-of select="@name"/>
</xsl:template>

<xsl:template match="IDS" mode="declare_is_c_data">
  module procedure is_c_data_<xsl:value-of select="@name"/>  
</xsl:template>

<xsl:template match="IDS" mode="declare_get_max_occurrences">
  module procedure get_max_occurrences_<xsl:value-of select="@name"/>
</xsl:template>

<xsl:template match="utilities" mode="module">
  <xsl:for-each select="./field[@data_type='structure' or @data_type='struct_array']">
    <xsl:variable name="this-type" select="local:structtypename(.)"/>
    type <xsl:value-of select="local:ids-type($this-type)"/> !<xsl:value-of select="local:commentstring(@documentation)"/>
    <xsl:apply-templates select="./field" mode="declare_field"/>
    end type
  </xsl:for-each>
</xsl:template>



<xsl:template match="IDS" mode="declare">
  use <xsl:value-of select="@name"/>
</xsl:template>

<xsl:template match="IDS" mode="declare_in_file">
  <xsl:result-document href="{@name}_schema.f90">
    module <xsl:value-of select="local:schemas-module(string(@name))"/>
    use ids_types
    use <xsl:value-of select="local:utilities-module()"/>
    
    implicit none

    interface set_c_data
      module procedure set_c_data_<xsl:value-of select="@name"/>
    end interface

    interface is_c_data
      module procedure is_c_data_<xsl:value-of select="@name"/> 
    end interface

    interface get_max_occurrences
      module procedure get_max_occurrences_<xsl:value-of select="@name"/>
    end interface

    interface ids_is_defined
      module procedure ids_is_defined_<xsl:value-of select="@name"/>
    end interface


  ! ***********  <xsl:value-of select="@name"/> IDS internal structures declaration
  <xsl:variable name="this-ids" select="@name"/>
  <xsl:for-each select="./field[@data_type='structure' or @data_type='struct_array']">
    <xsl:variable name="this-name" select="@name"/>
    <xsl:variable name="this-type" select="local:structtypename(.)"/>
    <xsl:apply-templates select="." mode="declare_struct_recurse">
      <xsl:with-param name="this-type" select="$this-type"/>
      <xsl:with-param name="this-ids" select="$this-ids"/>
      <xsl:with-param name="this-name" select="$this-name"/>
    </xsl:apply-templates>
  </xsl:for-each>

  ! ***********  <xsl:value-of select="@name"/> IDS 
  type, extends(IDS_base) :: <xsl:value-of select="local:ids-type(string(@name))"/> !<xsl:value-of select="local:commentstring(@documentation)"/>
    logical, private :: c_data = .FALSE. ! Fortran specific metadata telling whether the IDS has been populated from C allocated data (LL) or not
    integer, private :: max_occurrence = <xsl:value-of select="@maxoccur"/>! Maximum occurrence allowed as defined in the DD
    character(len = 50), private :: ids_name = '<xsl:value-of select="@name"/>'
    <xsl:apply-templates select="./field" mode="declare_field"/>
    contains
      procedure check_name_<xsl:value-of select="@name"/>
  end type

  contains 

    subroutine set_c_data_<xsl:value-of select="@name"/>(ids, bool)
    type(<xsl:value-of select="local:ids-type(string(@name))"/>), intent(inout) :: ids
    logical, intent(in) :: bool
    ids%c_data = bool
  end subroutine
  subroutine is_c_data_<xsl:value-of select="@name"/>(ids, bool)
    type(<xsl:value-of select="local:ids-type(string(@name))"/>), intent(in) :: ids
    logical, intent(out) :: bool
    bool = ids%c_data
  end subroutine

  subroutine check_name_<xsl:value-of select="@name"/>(ids, name, retstatus)
  class(<xsl:value-of select="local:ids-type(string(@name))"/>), intent(in) :: ids
  character*(*), intent(in) :: name
  integer, intent(out) :: retstatus
  integer :: slash_index
  
  slash_index = INDEX(name, '/')
  if ( (slash_index == 0 .AND. ids%ids_name /= name) .OR. (slash_index /= 0 .AND. ids%ids_name /= name(1:slash_index - 1)) ) then
     retstatus = -3
  else
    retstatus = 0
  end if
  end subroutine


function get_max_occurrences_<xsl:value-of select="@name"/>(ids)
    type(<xsl:value-of select="local:ids-type(string(@name))"/>), intent(in) :: ids
    integer :: get_max_occurrences_<xsl:value-of select="@name"/>
    get_max_occurrences_<xsl:value-of select="@name"/> = ids%max_occurrence
  end function

function ids_is_defined_<xsl:value-of select="@name"/>(ids) result(is_defined)

    use al_defs
    type(<xsl:value-of select="local:ids-type(string(@name))"/>), intent(in) :: ids
    logical :: is_defined
    integer :: time_mode

    time_mode = ids%ids_properties%homogeneous_time

    if (time_mode == IDS_TIME_MODE_HETEROGENEOUS) then
        is_defined = .TRUE.
        return
    endif

    if (time_mode == IDS_TIME_MODE_HOMOGENEOUS) then
        is_defined = .TRUE.
        return
    endif

    if (time_mode == IDS_TIME_MODE_INDEPENDENT) then
        is_defined = .TRUE.
        return
    endif


    is_defined = .FALSE.

  end function

  end module
</xsl:result-document>
</xsl:template>

<!-- The bare spelling of one IDS's schema module.

     The type list comes from mode="declare_struct_recurse" with $emit='alias', i.e.
     from the very recursion that decides which types the module above declares -
     including its "has this type already been declared?" guard. An alias for a type
     that module does not declare, or a missing alias for one it does, is a compile
     error, so the two lists have to be produced by one code path rather than two
     that agree today. -->
<xsl:template match="IDS" mode="alias_in_file">
  <xsl:result-document href="alias_{@name}_schema.f90">
module <xsl:value-of select="local:schemas-module-base(string(@name))"/>
  use ids_types  ! the kind parameters and IDS_base, which the `only:` renames below would otherwise hide
  use ids_utilities  ! the bare spelling of the utilities types this IDS's fields are declared with
  use <xsl:value-of select="local:schemas-module(string(@name))"/>  ! everything, under its suffixed spelling
<xsl:variable name="this-ids" select="@name"/>
<xsl:for-each select="./field[@data_type='structure' or @data_type='struct_array']">
    <xsl:apply-templates select="." mode="declare_struct_recurse">
      <xsl:with-param name="this-type" select="local:structtypename(.)"/>
      <xsl:with-param name="this-ids" select="$this-ids"/>
      <xsl:with-param name="this-name" select="@name"/>
      <xsl:with-param name="emit" select="'alias'" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:for-each><xsl:call-template name="alias_type_use">
    <xsl:with-param name="module-base" select="local:schemas-module-base(string(@name))"/>
    <xsl:with-param name="dd-type" select="string(@name)"/>
  </xsl:call-template>end module
</xsl:result-document>
</xsl:template>

<xsl:template match="IDS" mode="sbrt_c_data">
  subroutine set_c_data_<xsl:value-of select="@name"/>(ids, bool)
    type(<xsl:value-of select="local:ids-type(string(@name))"/>), intent(inout) :: ids
    logical, intent(in) :: bool
    ids%c_data = bool
  end subroutine
  subroutine is_c_data_<xsl:value-of select="@name"/>(ids, bool)
    type(<xsl:value-of select="local:ids-type(string(@name))"/>), intent(in) :: ids
    logical, intent(out) :: bool
    bool = ids%c_data
  end subroutine
</xsl:template>

<xsl:template match="IDS" mode="sbrt_max_occurrences">
  function get_max_occurrences_<xsl:value-of select="@name"/>(ids)
    type(<xsl:value-of select="local:ids-type(string(@name))"/>), intent(in) :: ids
    integer :: get_max_occurrences_<xsl:value-of select="@name"/>
    get_max_occurrences_<xsl:value-of select="@name"/> = ids%max_occurrence
  end function
</xsl:template>



<!-- browse substructures recursively -->
<!-- make sure structures are declared before being used -->
<!-- $emit selects what to do with each type this recursion reaches: declare it
     ('declare', the default) or emit the alias layer's rename for it ('alias'). It
     is a tunnel parameter so that only the two ends of the recursion mention it.

     A flag rather than a second mode on purpose. What must not drift is the "has
     this type been declared already?" test below: it decides which types the schema
     module contains, and the alias layer has to name exactly those - one too few and
     a bare name is missing, one too many and it renames a type that does not exist.
     Two modes would mean two copies of that test. Modes cannot be chosen
     dynamically, and mode="#current" cannot help either, since it is the leaf
     template that has to differ while the recursion around it stays shared. -->
<xsl:template match="field" mode="declare_struct_recurse">
  <xsl:param name="this-type"/>
  <xsl:param name="this-ids"/>
  <xsl:param name="this-name"/>
  <xsl:param name="emit" as="xs:string" select="'declare'" tunnel="yes"/>

  <xsl:if test="descendant::field[(@data_type='structure' or @data_type='struct_array')]">
    <xsl:for-each select="./field[@data_type='structure' or @data_type='struct_array']">
      <xsl:variable name="this-type" select="local:structtypename(.)"/>
      <xsl:variable name="this-name" select="@name"/>
      <xsl:apply-templates select="." mode="declare_struct_recurse">
        <xsl:with-param name="this-type" select="$this-type"/>
        <xsl:with-param name="this-ids" select="$this-ids"/>
        <xsl:with-param name="this-name" select="$this-name"/>
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:if>  

  <xsl:if test="not(preceding::field[@structure_reference=$this-type and ancestor::IDS/@name=$this-ids] or /IDSs/utilities/field/@name=$this-type)">
    <xsl:choose>
      <xsl:when test="$emit = 'alias'">
        <xsl:call-template name="alias_type_use">
          <xsl:with-param name="module-base" select="local:schemas-module-base(string($this-ids))"/>
          <xsl:with-param name="dd-type" select="$this-type"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="declare_struct">
          <xsl:with-param name="this-type" select="$this-type"/>
          <xsl:with-param name="this-ids" select="$this-ids"/>
          <xsl:with-param name="this-name" select="$this-name"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>

</xsl:template>



<xsl:template match="field" mode="declare_struct">
  <xsl:param name="this-type"/>
  <xsl:param name="this-ids"/>
  <xsl:param name="this-name"/>
  type :: <xsl:value-of select="local:ids-type($this-type)"/>
  <xsl:for-each select="./field">
    <xsl:apply-templates select="." mode="declare_field"/>
  </xsl:for-each>
  end type
</xsl:template>



<xsl:template match="field" mode="declare_field">
  <xsl:choose>
    <xsl:when test="@data_type='structure'">
      type(<xsl:value-of select="local:ids-type(string(@structure_reference))"/>) :: <xsl:value-of select="@name"/> !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>

    <xsl:when test="@data_type='struct_array'">
      type(<xsl:value-of select="local:ids-type(string(@structure_reference))"/>), pointer :: <xsl:value-of select="@name"/>(:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>

    <xsl:when test="@data_type='str_type' or @data_type='str_1d_type' or @data_type='STR_0D' or @data_type='STR_1D'">
      character(len=ids_string_length), dimension(:), pointer :: <xsl:value-of select="@name"/> => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>

    <xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
      integer(ids_int) :: <xsl:value-of select="@name"/>=ids_int_invalid !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>
    <xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
      real(ids_real) :: <xsl:value-of select="@name"/>=ids_real_invalid !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>
    <xsl:when test="@data_type='cpx_type' or @data_type='CPX_0D'">
      complex(ids_real) :: <xsl:value-of select="@name"/>=ids_complex_invalid !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>

    <xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
      integer(ids_int), pointer :: <xsl:value-of select="@name"/>(:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>
    <xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
      real(ids_real), pointer :: <xsl:value-of select="@name"/>(:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>
    <xsl:when test="@data_type='cpx_1d_type' or @data_type='CPX_1D'">
      complex(ids_real), pointer :: <xsl:value-of select="@name"/>(:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>

    <xsl:when test="@data_type='int_2d_type' or @data_type='INT_2D'">
      integer(ids_int), pointer :: <xsl:value-of select="@name"/>(:,:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>
    <xsl:when test="@data_type='flt_2d_type' or @data_type='FLT_2D'">
      real(ids_real), pointer :: <xsl:value-of select="@name"/>(:,:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>
    <xsl:when test="@data_type='cpx_2d_type' or @data_type='CPX_2D'">
      complex(ids_real), pointer :: <xsl:value-of select="@name"/>(:,:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>

    <xsl:when test="@data_type='FLT_3D'">
      real(ids_real), pointer :: <xsl:value-of select="@name"/>(:,:,:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>
    <xsl:when test="@data_type='INT_3D'">
      integer(ids_int), pointer :: <xsl:value-of select="@name"/>(:,:,:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>
    <xsl:when test="@data_type='cpx_3d_type' or @data_type='CPX_3D'">
      complex(ids_real), pointer :: <xsl:value-of select="@name"/>(:,:,:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>

    <xsl:when test="@data_type='FLT_4D'">
      real(ids_real), pointer :: <xsl:value-of select="@name"/>(:,:,:,:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>
    <xsl:when test="@data_type='CPX_4D'">
      complex(ids_real), pointer :: <xsl:value-of select="@name"/>(:,:,:,:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>

    <xsl:when test="@data_type='FLT_5D'">
      real(ids_real), pointer :: <xsl:value-of select="@name"/>(:,:,:,:,:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>
    <xsl:when test="@data_type='CPX_5D'">
      complex(ids_real), pointer :: <xsl:value-of select="@name"/>(:,:,:,:,:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>

    <xsl:when test="@data_type='FLT_6D'">
      real(ids_real), pointer :: <xsl:value-of select="@name"/>(:,:,:,:,:,:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>
    <xsl:when test="@data_type='CPX_6D'">
      complex(ids_real), pointer :: <xsl:value-of select="@name"/>(:,:,:,:,:,:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>
    <xsl:otherwise>
      ERROR
    </xsl:otherwise>
  </xsl:choose>  
</xsl:template>



</xsl:stylesheet>
