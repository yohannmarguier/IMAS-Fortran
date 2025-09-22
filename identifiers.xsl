<?xml version="1.0" encoding="UTF-8"?>
<?modxslt-stylesheet type="text/xsl" media="fuffa, screen and $GET[stylesheet]" href="./%24GET%5Bstylesheet%5D" alternate="no" title="Translation using provided stylesheet" charset="ISO-8859-1" ?>
<?modxslt-stylesheet type="text/xsl" media="screen" alternate="no" title="Show raw source of the XML file" charset="ISO-8859-1" ?>

<xsl:stylesheet 
   xmlns:yaslt="http://www.mod-xslt2.com/ns/1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" 
   xmlns:fn="http://www.w3.org/2005/02/xpath-functions"
   xmlns:exsl="http://exslt.org/common"
   xmlns:str="http://exslt.org/strings"
   xmlns:func="http://exslt.org/functions"
   xmlns:my="http://localhost.localdomain/localns"
   exclude-result-prefixes="my"
   extension-element-prefixes="yaslt exsl func str">
   <xsl:include href="./identifiers.common.xsl"/>
   
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>


<!-- MAIN, FILE GENERATION -->
<xsl:template match="/constants">

  <!-- FORTRAN FILE -->
  <exsl:document href="{$prefix}{$name}.f90" method="text">
    <xsl:apply-templates select="header" mode="Fortran"/>

      <xsl:text>&#xA;&#xA;module al_</xsl:text><xsl:value-of select="$name"/><xsl:text>&#xA;</xsl:text>

    <xsl:apply-templates select="include[@name='Fortran']"/><xsl:text>&#xA;&#xA;</xsl:text>
    <xsl:text>  use ids_utilities&#xA;</xsl:text>
    <xsl:text>  implicit none&#xA;</xsl:text>
    <xsl:text>  private&#xA;</xsl:text>
    <xsl:text>  &#xA;</xsl:text>

    <xsl:if test="//constants[not(@create_mapping_function)]">
      <xsl:apply-templates select="*[name()!='header' and name()!='include' and @used_internally]" mode="Fortran"/>
    </xsl:if>
      <xsl:text>  type :: type_</xsl:text><xsl:value-of select="$name"/><xsl:text>&#xA;</xsl:text>
      <xsl:if test="//constants[@create_mapping_function]">
	<xsl:text>  contains&#xA;</xsl:text>
	<xsl:text>    procedure :: index => get_type_index&#xA;</xsl:text>
	<xsl:text>    procedure :: name => get_type_name&#xA;</xsl:text>
	<xsl:text>    procedure :: description => get_type_description&#xA;</xsl:text>
	<xsl:text>    procedure, private :: set_ids_identifier => set_identifier&#xA;</xsl:text>
	<xsl:text>    procedure, private :: set_ids_identifier_static => set_identifier_static&#xA;</xsl:text>
	<xsl:text>    procedure, private :: set_ids_identifier_static_1d => set_identifier_static_1d&#xA;</xsl:text>
	<xsl:text>    procedure, private :: set_ids_identifier_dynamic_aos3 => set_identifier_dynamic_aos3&#xA;</xsl:text>
	<xsl:text>    procedure, private :: set_ids_identifier_dynamic_aos3_1d => set_identifier_dynamic_aos3_1d&#xA;</xsl:text>
	<xsl:text>    generic :: set_identifier => set_ids_identifier, set_ids_identifier_static, &amp;&#xA;</xsl:text>
	<xsl:text>                                 set_ids_identifier_static_1d, set_ids_identifier_dynamic_aos3, &amp;&#xA;</xsl:text>
	<xsl:text>                                 set_ids_identifier_dynamic_aos3_1d&#xA;</xsl:text>
      </xsl:if>
      <xsl:text>  end type type_</xsl:text><xsl:value-of select="$name"/><xsl:text>&#xA;</xsl:text>

	<xsl:text>&#xA;  type(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), public,parameter :: </xsl:text><xsl:value-of select="$name"/><xsl:text> = &amp;&#xA;</xsl:text>
	<xsl:text>       type_</xsl:text><xsl:value-of select="$name"/><xsl:text>()&#xA;</xsl:text>

      <xsl:if test="//constants[@create_mapping_function]">

	<xsl:call-template name="translations_Fortran"/>
      </xsl:if>

	<xsl:text>&#xA;end module al_</xsl:text><xsl:value-of select="$name"/><xsl:text>&#xA;</xsl:text>

  </exsl:document>

  <!-- DOCBOOK FILE -->
  <exsl:document href="{$prefix}{$name}.xml" method="text">
    <xsl:call-template name="docbook"/>
  </exsl:document>

</xsl:template>

<!-- FORTRAN TEMPLATES -->

<xsl:template match="header" mode="Fortran">
  <xsl:call-template name="replace-string">
    <xsl:with-param name="text" select="concat('&#xA;',text())"/>
    <xsl:with-param name="replace" select="'&#xA;'"/>
    <xsl:with-param name="with" select="'&#xA;!> '"/>
  </xsl:call-template>
</xsl:template>
  
<xsl:template match="int" mode="Fortran">
  <xsl:text>  integer, parameter :: </xsl:text>
  <xsl:value-of select="@name"/>
  <xsl:text> = </xsl:text>
  <xsl:value-of select="."/>
  <xsl:text>&#xA;</xsl:text>
</xsl:template>

<xsl:template match="float" mode="Fortran">
  <xsl:text>  real(kind=c_double), parameter :: </xsl:text>
  <xsl:value-of select="@name"/>
  <xsl:text> = </xsl:text>
  <xsl:value-of select="."/>
  <xsl:text>_c_double&#xA;</xsl:text>
</xsl:template>

<xsl:template match="string" mode="Fortran">
  <xsl:text>  character(len=*), parameter :: </xsl:text>
  <xsl:value-of select="@name"/>
  <xsl:text> = "</xsl:text>
  <xsl:choose>
    <xsl:when test="string-length(.) > 132">
      <xsl:value-of select="substring(., 1, 132)"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="."/>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:text>"&#xA;</xsl:text>
</xsl:template>

<xsl:template match="comment" mode="Fortran">
  <xsl:call-template name="replace-string">
    <xsl:with-param name="text" select="concat('&#xA;',text())"/>
    <xsl:with-param name="replace" select="'&#xA;'"/>
    <xsl:with-param name="with" select="'&#xA;  !> '"/>
  </xsl:call-template>
  <xsl:text>&#xA;</xsl:text>
</xsl:template>

<!-- Declare fortran variables -->
<xsl:template name="declareFortranIntegers">
    <xsl:for-each select="//constants/int[@name]">
            <xsl:text>    integer :: </xsl:text><xsl:value-of select="@name"/><xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
    <xsl:for-each select="//constants/float[@name]">
      <xsl:text>    real(c_double) :: </xsl:text><xsl:value-of select="@name"/><xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
    <xsl:text>    integer :: version&#xA;</xsl:text>
</xsl:template>

<!-- Assign Fortran variables -->
<xsl:template name="assignFortran">
  <xsl:for-each select="//constants/int[@name]">
    <xsl:text>    </xsl:text><xsl:value-of select="@name"/><xsl:text> = </xsl:text><xsl:value-of select="."/><xsl:text>, &amp;&#xA;</xsl:text>
  </xsl:for-each>
  <xsl:for-each select="//constants/float[@name]">
    <xsl:text>    </xsl:text><xsl:value-of select="@name"/><xsl:text> = </xsl:text><xsl:value-of select="."/><xsl:text>, &amp;&#xA;</xsl:text>
  </xsl:for-each>
  <xsl:text>    version=-999999999)&#xA;</xsl:text>
</xsl:template>

<!-- Translations between VALUE, NAME and DESCRIPTION -->
<xsl:template name="translations_Fortran">
    <xsl:text>&#xA;</xsl:text>

    <!-- Contains -->
    <xsl:text>contains&#xA;&#xA;</xsl:text>

    <!-- Private helper subroutine -->
    <xsl:text>  ! helper to get </xsl:text><xsl:value-of select="$name"/><xsl:text> data by name&#xA;</xsl:text>
    <xsl:text>  subroutine get_type_data_by_name(name, coord_index, coord_name, coord_description)&#xA;</xsl:text>
    <xsl:text>    character(*), intent(in) :: name&#xA;</xsl:text>
    <xsl:text>    integer, intent(out) :: coord_index&#xA;</xsl:text>
    <xsl:text>    character(len=ids_string_length), intent(out) :: coord_name&#xA;</xsl:text>
    <xsl:text>    character(len=ids_string_length), intent(out) :: coord_description&#xA;</xsl:text>
    <xsl:text>    character(len=:), allocatable :: key&#xA;</xsl:text>
    <xsl:text>    &#xA;</xsl:text>
    <xsl:text>    key = trim(name)&#xA;</xsl:text>
    <xsl:text>    coord_index = ids_int_invalid&#xA;</xsl:text>
    <xsl:text>    coord_name = ''&#xA;</xsl:text>
    <xsl:text>    coord_description = ''&#xA;</xsl:text>
    <xsl:text>    &#xA;</xsl:text>
    <xsl:text>    select case (key)&#xA;</xsl:text>
    <xsl:for-each select="//constants/int[@name]">
      <xsl:text>      case ('</xsl:text><xsl:value-of select="@name"/><xsl:text>')&#xA;</xsl:text>
      <xsl:text>        coord_index = </xsl:text><xsl:value-of select="."/><xsl:text>&#xA;</xsl:text>
      <xsl:text>        coord_name = '</xsl:text><xsl:value-of select="@name"/><xsl:text>'&#xA;</xsl:text>
      <xsl:text>        coord_description = '</xsl:text>
      <xsl:choose>
        <xsl:when test="string-length(@description) > 132">
          <xsl:value-of select="substring(@description, 1, 132)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@description"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>'&#xA;</xsl:text>
    </xsl:for-each>
    <xsl:text>      case default&#xA;</xsl:text>
    <xsl:text>        ! Raise error for unknown identifier&#xA;</xsl:text>
    <xsl:text>        ERROR STOP 'get_type_data_by_name: Unknown coordinate identifier: ' // trim(name)&#xA;</xsl:text>
    <xsl:text>    end select&#xA;</xsl:text>
    <xsl:text>  end subroutine get_type_data_by_name&#xA;&#xA;</xsl:text>

    <!-- Translation from NAME to VALUE -->
    <xsl:if test="int!='' and */@name!=''">
      <xsl:text>  ! Get </xsl:text><xsl:value-of select="$name"/><xsl:text> index from string name&#xA;</xsl:text>
      <xsl:text>  integer function get_type_index(self, NAME)&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), intent(in) :: self&#xA;</xsl:text>
      <xsl:text>    character(*), intent(in) :: NAME&#xA;</xsl:text>
      <xsl:text>    character(len=:), allocatable :: key&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    key = trim(NAME)&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    select case (key)&#xA;</xsl:text>
      <xsl:for-each select="//constants/int[@name]">
        <xsl:text>      case ('</xsl:text><xsl:value-of select="@name"/><xsl:text>')&#xA;</xsl:text>
        <xsl:text>        get_type_index = </xsl:text><xsl:value-of select="."/><xsl:text>&#xA;</xsl:text>
      </xsl:for-each>
      <xsl:text>      case default&#xA;</xsl:text>
            <xsl:text>        get_type_index = ids_int_invalid&#xA;</xsl:text>
            <xsl:text>        write(*,*) 'get_type_index: Unknown identifier name:', NAME&#xA;</xsl:text>
      <xsl:text>    end select&#xA;</xsl:text>
      <xsl:text>  end function get_type_index&#xA;&#xA;</xsl:text>
    </xsl:if>

    <!-- Translation from VALUE to NAME -->
    <xsl:if test="int!=''">
      <xsl:text>  ! Get </xsl:text><xsl:value-of select="$name"/><xsl:text> name from index&#xA;</xsl:text>
      <xsl:text>  function get_type_name(self, IND) result(name)&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), intent(in) :: self&#xA;</xsl:text>
      <xsl:text>    integer, intent(in) :: IND&#xA;</xsl:text>
      <xsl:text>    character(len=:), allocatable :: name&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    name = ''&#xA;</xsl:text>
      <xsl:text>    select case (IND)&#xA;</xsl:text>
      <xsl:for-each select="//constants/int[@name]">
        <xsl:text>      case (</xsl:text><xsl:value-of select="."/><xsl:text>)&#xA;</xsl:text>
        <xsl:text>        name = '</xsl:text><xsl:value-of select="@name"/><xsl:text>'&#xA;</xsl:text>
      </xsl:for-each>
      <xsl:text>      case default&#xA;</xsl:text>
      <xsl:text>        name = ''&#xA;</xsl:text>
      <xsl:text>        write(*,*) 'get_type_name: Unknown identifier index:', IND&#xA;</xsl:text>
      <xsl:text>    end select&#xA;</xsl:text>
      <xsl:text>  end function get_type_name&#xA;&#xA;</xsl:text>
    </xsl:if>

    <!-- Translation from VALUE to DESCRIPTION -->
    <xsl:if test="int!=''">
      <xsl:text>  ! Get </xsl:text><xsl:value-of select="$name"/><xsl:text> description from index&#xA;</xsl:text>
      <xsl:text>  function get_type_description(self, IND) result(description)&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), intent(in) :: self&#xA;</xsl:text>
      <xsl:text>    integer, intent(in) :: IND&#xA;</xsl:text>
      <xsl:text>    character(len=:), allocatable :: description&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    description = ''&#xA;</xsl:text>
      <xsl:text>    select case (IND)&#xA;</xsl:text>
      <xsl:for-each select="//constants/int[@name]">
        <xsl:text>      case (</xsl:text><xsl:value-of select="."/><xsl:text>)&#xA;</xsl:text>
        <xsl:text>        description = '</xsl:text>
        <xsl:choose>
          <xsl:when test="string-length(@description) > 132">
            <xsl:value-of select="substring(@description, 1, 132)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@description"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>'&#xA;</xsl:text>
      </xsl:for-each>
      <xsl:text>      case default&#xA;</xsl:text>
      <xsl:text>        description = ''&#xA;</xsl:text>
      <xsl:text>        write(*,*) 'get_type_description: Unknown identifier index:', IND&#xA;</xsl:text>
      <xsl:text>    end select&#xA;</xsl:text>
      <xsl:text>  end function get_type_description&#xA;&#xA;</xsl:text>
    </xsl:if>

    <!-- Set complete ids_identifier structure -->
    <xsl:if test="int!=''">
      <xsl:text>  ! Set complete ids_identifier structure&#xA;</xsl:text>
      <xsl:text>  subroutine set_identifier(self, identifier, name)&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), intent(in) :: self&#xA;</xsl:text>
      <xsl:text>    type(ids_identifier), intent(out) :: identifier&#xA;</xsl:text>
      <xsl:text>    character(*), intent(in) :: name&#xA;</xsl:text>
      <xsl:text>    integer :: coord_index&#xA;</xsl:text>
      <xsl:text>    character(len=ids_string_length) :: coord_name, coord_description&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    call get_type_data_by_name(name, coord_index, coord_name, coord_description)&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    identifier%index = coord_index&#xA;</xsl:text>
      <xsl:text>    allocate(identifier%name(1))&#xA;</xsl:text>
      <xsl:text>    allocate(identifier%description(1))&#xA;</xsl:text>
      <xsl:text>    identifier%name(1) = coord_name&#xA;</xsl:text>
      <xsl:text>    identifier%description(1) = coord_description&#xA;</xsl:text>
      <xsl:text>  end subroutine set_identifier&#xA;&#xA;</xsl:text>
    </xsl:if>

    <!-- Set complete ids_identifier_static structure -->
    <xsl:if test="int!=''">
      <xsl:text>  ! Set complete ids_identifier_static structure&#xA;</xsl:text>
      <xsl:text>  subroutine set_identifier_static(self, identifier, name)&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), intent(in) :: self&#xA;</xsl:text>
      <xsl:text>    type(ids_identifier_static), intent(out) :: identifier&#xA;</xsl:text>
      <xsl:text>    character(*), intent(in) :: name&#xA;</xsl:text>
      <xsl:text>    integer :: coord_index&#xA;</xsl:text>
      <xsl:text>    character(len=ids_string_length) :: coord_name, coord_description&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    call get_type_data_by_name(name, coord_index, coord_name, coord_description)&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    identifier%index = coord_index&#xA;</xsl:text>
      <xsl:text>    allocate(identifier%name(1))&#xA;</xsl:text>
      <xsl:text>    allocate(identifier%description(1))&#xA;</xsl:text>
      <xsl:text>    identifier%name(1) = coord_name&#xA;</xsl:text>
      <xsl:text>    identifier%description(1) = coord_description&#xA;</xsl:text>
      <xsl:text>  end subroutine set_identifier_static&#xA;&#xA;</xsl:text>
    </xsl:if>

    <!-- Set complete ids_identifier_static_1d structure -->
    <xsl:if test="int!=''">
      <xsl:text>  ! Set complete ids_identifier_static_1d structure&#xA;</xsl:text>
      <xsl:text>  subroutine set_identifier_static_1d(self, identifier, name)&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), intent(in) :: self&#xA;</xsl:text>
      <xsl:text>    type(ids_identifier_static_1d), intent(out) :: identifier&#xA;</xsl:text>
      <xsl:text>    character(*), intent(in) :: name&#xA;</xsl:text>
      <xsl:text>    integer :: coord_index&#xA;</xsl:text>
      <xsl:text>    character(len=ids_string_length) :: coord_name, coord_description&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    call get_type_data_by_name(name, coord_index, coord_name, coord_description)&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    allocate(identifier%indices(1))&#xA;</xsl:text>
      <xsl:text>    allocate(identifier%names(1))&#xA;</xsl:text>
      <xsl:text>    allocate(identifier%descriptions(1))&#xA;</xsl:text>
      <xsl:text>    identifier%indices(1) = coord_index&#xA;</xsl:text>
      <xsl:text>    identifier%names(1) = coord_name&#xA;</xsl:text>
      <xsl:text>    identifier%descriptions(1) = coord_description&#xA;</xsl:text>
      <xsl:text>  end subroutine set_identifier_static_1d&#xA;&#xA;</xsl:text>
    </xsl:if>

    <!-- Set complete ids_identifier_dynamic_aos3 structure -->
    <xsl:if test="int!=''">
      <xsl:text>  ! Set complete ids_identifier_dynamic_aos3 structure&#xA;</xsl:text>
      <xsl:text>  subroutine set_identifier_dynamic_aos3(self, identifier, name)&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), intent(in) :: self&#xA;</xsl:text>
      <xsl:text>    type(ids_identifier_dynamic_aos3), intent(out) :: identifier&#xA;</xsl:text>
      <xsl:text>    character(*), intent(in) :: name&#xA;</xsl:text>
      <xsl:text>    integer :: coord_index&#xA;</xsl:text>
      <xsl:text>    character(len=ids_string_length) :: coord_name, coord_description&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    call get_type_data_by_name(name, coord_index, coord_name, coord_description)&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    identifier%index = coord_index&#xA;</xsl:text>
      <xsl:text>    allocate(identifier%name(1))&#xA;</xsl:text>
      <xsl:text>    allocate(identifier%description(1))&#xA;</xsl:text>
      <xsl:text>    identifier%name(1) = coord_name&#xA;</xsl:text>
      <xsl:text>    identifier%description(1) = coord_description&#xA;</xsl:text>
      <xsl:text>  end subroutine set_identifier_dynamic_aos3&#xA;&#xA;</xsl:text>
    </xsl:if>

    <!-- Set complete ids_identifier_dynamic_aos3_1d structure -->
    <xsl:if test="int!=''">
      <xsl:text>  ! Set complete ids_identifier_dynamic_aos3_1d structure&#xA;</xsl:text>
      <xsl:text>  subroutine set_identifier_dynamic_aos3_1d(self, identifier, name)&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), intent(in) :: self&#xA;</xsl:text>
      <xsl:text>    type(ids_identifier_dynamic_aos3_1d), intent(out) :: identifier&#xA;</xsl:text>
      <xsl:text>    character(*), intent(in) :: name&#xA;</xsl:text>
      <xsl:text>    integer :: coord_index&#xA;</xsl:text>
      <xsl:text>    character(len=ids_string_length) :: coord_name, coord_description&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    call get_type_data_by_name(name, coord_index, coord_name, coord_description)&#xA;</xsl:text>
      <xsl:text>    &#xA;</xsl:text>
      <xsl:text>    allocate(identifier%indices(1))&#xA;</xsl:text>
      <xsl:text>    allocate(identifier%names(1))&#xA;</xsl:text>
      <xsl:text>    allocate(identifier%descriptions(1))&#xA;</xsl:text>
      <xsl:text>    identifier%indices(1) = coord_index&#xA;</xsl:text>
      <xsl:text>    identifier%names(1) = coord_name&#xA;</xsl:text>
      <xsl:text>    identifier%descriptions(1) = coord_description&#xA;</xsl:text>
      <xsl:text>  end subroutine set_identifier_dynamic_aos3_1d&#xA;</xsl:text>
    </xsl:if>

</xsl:template>

</xsl:stylesheet>
