<?xml version="1.0" encoding="UTF-8"?>
<?modxslt-stylesheet type="text/xsl" media="fuffa, screen and $GET[stylesheet]" href="./%24GET%5Bstylesheet%5D" alternate="no" title="Translation using provided stylesheet" charset="ISO-8859-1" ?>
<?modxslt-stylesheet type="text/xsl" media="screen" alternate="no" title="Show raw source of the XML file" charset="ISO-8859-1" ?>
<xsl:stylesheet xmlns:yaslt="http://www.mod-xslt2.com/ns/2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" extension-element-prefixes="yaslt" xmlns:fn="http://www.w3.org/2005/02/xpath-functions" xmlns:local="http://www.example.com/functions/local" exclude-result-prefixes="local xs">
<!-- -->
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>
<!-- -->
<xsl:param name="DD_GIT_DESCRIBE" as="xs:string" required="yes"/>
<xsl:param name="AL_GIT_DESCRIBE" as="xs:string" required="yes"/>

<xsl:variable name="version_regex" select="'^([0-9]+)\.([0-9]+)\.([0-9]+)(-.*)?$'"/>
<xsl:variable name="DD_MAJOR" as="xs:int" select="xs:int(replace($DD_GIT_DESCRIBE, $version_regex, '$1'))"/>
<xsl:variable name="DD_MINOR" as="xs:int" select="xs:int(replace($DD_GIT_DESCRIBE, $version_regex, '$2'))"/>
<xsl:variable name="DD_PATCH" as="xs:int" select="xs:int(replace($DD_GIT_DESCRIBE, $version_regex, '$3'))"/>

<xsl:variable name="HLI_MAJOR" as="xs:int" select="xs:int(replace($AL_GIT_DESCRIBE, $version_regex, '$1'))"/>
<xsl:variable name="HLI_MINOR" as="xs:int" select="xs:int(replace($AL_GIT_DESCRIBE, $version_regex, '$2'))"/>
<xsl:variable name="HLI_PATCH" as="xs:int" select="xs:int(replace($AL_GIT_DESCRIBE, $version_regex, '$3'))"/>
<!-- TOP -->

<xsl:include href="utils.xsl"/>


<xsl:template match="/IDSs">
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
  complex(ids_real), parameter :: ids_complex_invalid = CMPLX(-9.0E40_ids_real,-9.0E40_ids_real)

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
  character(*), parameter :: al_fortran_version = '<xsl:value-of select="$UAL_GIT_DESCRIBE"/>'
  integer(ids_int), parameter :: al_fortran_major_version = <xsl:value-of select="$HLI_MAJOR"/>
  integer(ids_int), parameter :: al_fortran_minor_version = <xsl:value-of select="$HLI_MINOR"/>
  integer(ids_int), parameter :: al_fortran_patch_version = <xsl:value-of select="$HLI_PATCH"/>
  ! DD version
  character(*), parameter :: al_dd_version = '<xsl:value-of select="$DD_GIT_DESCRIBE"/>'
  integer(ids_int), parameter :: al_dd_major_version = <xsl:value-of select="$DD_MAJOR"/>
  integer(ids_int), parameter :: al_dd_minor_version = <xsl:value-of select="$DD_MINOR"/>
  integer(ids_int), parameter :: al_dd_patch_version = <xsl:value-of select="$DD_PATCH"/>

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
<xsl:result-document href="ids_utilities.f90">
module ids_utilities    ! declare the set of types common to all sub-trees

use ids_types

<!-- Base IDS type -->
type, abstract :: IDS_base
end type

<!-- Declare utilities types -->
<xsl:apply-templates select="/IDSs/utilities" mode="module"/> <!-- Original IDS structure -->

end module ! end of the utilities module
</xsl:result-document>
<!-- ======================= ====   End :Common Utility definition ==== =====================-->

<!-- ======================= ====   Begin : declare schema  ==== =====================-->

  <xsl:apply-templates select="IDS" mode="declare_in_file"/>  

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
    <xsl:variable name="this-type">
      <xsl:choose>
	<xsl:when test="@structure_reference='self'">
	  <xsl:value-of select="@name"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="@structure_reference"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    type ids_<xsl:value-of select="$this-type"/> !<xsl:value-of select="local:commentstring(@documentation)"/>
    <xsl:apply-templates select="./field" mode="declare_field"/>
    end type
  </xsl:for-each>
</xsl:template>



<xsl:template match="IDS" mode="declare">
  use <xsl:value-of select="@name"/>
</xsl:template>

<xsl:template match="IDS" mode="declare_in_file">
  <xsl:result-document href="{@name}_schema.f90">
    module ids_schemas_<xsl:value-of select="@name"/>
    use ids_types
    use ids_utilities


    interface set_c_data
      module procedure set_c_data_<xsl:value-of select="@name"/>
    end interface

    interface is_c_data
      module procedure is_c_data_<xsl:value-of select="@name"/> 
    end interface

    interface get_max_occurrences
      module procedure get_max_occurrences_<xsl:value-of select="@name"/>
    end interface


  ! ***********  <xsl:value-of select="@name"/> IDS internal structures declaration
  <xsl:variable name="this-ids" select="@name"/>
  <xsl:for-each select="./field[@data_type='structure' or @data_type='struct_array']">
    <xsl:variable name="this-name" select="@name"/>
    <xsl:variable name="this-type">
      <xsl:choose>
	<xsl:when test="@structure_reference='self'">
	  <xsl:value-of select="@name"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="@structure_reference"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:apply-templates select="." mode="declare_struct_recurse">
      <xsl:with-param name="this-type" select="$this-type"/>
      <xsl:with-param name="this-ids" select="$this-ids"/>
      <xsl:with-param name="this-name" select="$this-name"/>
    </xsl:apply-templates>
  </xsl:for-each>

  ! ***********  <xsl:value-of select="@name"/> IDS 
  type, extends(IDS_base) :: ids_<xsl:value-of select="@name"/> !<xsl:value-of select="local:commentstring(@documentation)"/>
    logical, private :: c_data = .FALSE. ! Fortran specific metadata telling whether the IDS has been populated from C allocated data (LL) or not
    integer, private :: max_occurrence = <xsl:value-of select="@maxoccur"/>! Maximum occurrence allowed as defined in the DD
    <xsl:apply-templates select="./field" mode="declare_field"/>
  end type

  contains 

    subroutine set_c_data_<xsl:value-of select="@name"/>(ids, bool)
    type(ids_<xsl:value-of select="@name"/>), intent(inout) :: ids
    logical, intent(in) :: bool
    ids%c_data = bool
  end subroutine
  subroutine is_c_data_<xsl:value-of select="@name"/>(ids, bool)
    type(ids_<xsl:value-of select="@name"/>), intent(in) :: ids
    logical, intent(out) :: bool
    bool = ids%c_data
  end subroutine

function get_max_occurrences_<xsl:value-of select="@name"/>(ids)
    type(ids_<xsl:value-of select="@name"/>), intent(in) :: ids
    integer :: get_max_occurrences_<xsl:value-of select="@name"/>
    get_max_occurrences_<xsl:value-of select="@name"/> = ids%max_occurrence
  end function

  end module
</xsl:result-document>
</xsl:template>

<xsl:template match="IDS" mode="sbrt_c_data">
  subroutine set_c_data_<xsl:value-of select="@name"/>(ids, bool)
    type(ids_<xsl:value-of select="@name"/>), intent(inout) :: ids
    logical, intent(in) :: bool
    ids%c_data = bool
  end subroutine
  subroutine is_c_data_<xsl:value-of select="@name"/>(ids, bool)
    type(ids_<xsl:value-of select="@name"/>), intent(in) :: ids
    logical, intent(out) :: bool
    bool = ids%c_data
  end subroutine
</xsl:template>

<xsl:template match="IDS" mode="sbrt_max_occurrences">
  function get_max_occurrences_<xsl:value-of select="@name"/>(ids)
    type(ids_<xsl:value-of select="@name"/>), intent(in) :: ids
    integer :: get_max_occurrences_<xsl:value-of select="@name"/>
    get_max_occurrences_<xsl:value-of select="@name"/> = ids%max_occurrence
  end function
</xsl:template>



<!-- browse substructures recursively -->
<!-- make sure structures are declared before being used -->
<xsl:template match="field" mode="declare_struct_recurse">
  <xsl:param name="this-type"/>
  <xsl:param name="this-ids"/>
  <xsl:param name="this-name"/>

  <xsl:if test="descendant::field[(@data_type='structure' or @data_type='struct_array')]">
    <xsl:for-each select="./field[@data_type='structure' or @data_type='struct_array']">
      <xsl:variable name="this-type">
	<xsl:choose>
	  <xsl:when test="@structure_reference='self'">
	    <xsl:value-of select="@name"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="@structure_reference"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:variable>
      <xsl:variable name="this-name" select="@name"/>
      <xsl:apply-templates select="." mode="declare_struct_recurse">
	<xsl:with-param name="this-type" select="$this-type"/>
	<xsl:with-param name="this-ids" select="$this-ids"/>
	<xsl:with-param name="this-name" select="$this-name"/>
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:if>  

  <xsl:if test="not(preceding::field[@structure_reference=$this-type and ancestor::IDS/@name=$this-ids] or /IDSs/utilities/field/@name=$this-type)">
    <xsl:apply-templates select="." mode="declare_struct">
      <xsl:with-param name="this-type" select="$this-type"/>
      <xsl:with-param name="this-ids" select="$this-ids"/>
      <xsl:with-param name="this-name" select="$this-name"/>
    </xsl:apply-templates>
  </xsl:if>

</xsl:template>



<xsl:template match="field" mode="declare_struct">
  <xsl:param name="this-type"/>
  <xsl:param name="this-ids"/>
  <xsl:param name="this-name"/>
  type :: ids_<xsl:value-of select="$this-type"/>
  <xsl:for-each select="./field">
    <xsl:apply-templates select="." mode="declare_field"/>
  </xsl:for-each>
  end type
</xsl:template>



<xsl:template match="field" mode="declare_field">
  <xsl:choose>
    <xsl:when test="@data_type='structure'">
      type(ids_<xsl:value-of select="@structure_reference"/>) :: <xsl:value-of select="@name"/> !<xsl:value-of select="local:commentstring(@documentation)"/>
    </xsl:when>

    <xsl:when test="@data_type='struct_array'">
      type(ids_<xsl:value-of select="@structure_reference"/>), pointer :: <xsl:value-of select="@name"/>(:) => null() !<xsl:value-of select="local:commentstring(@documentation)"/>
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
