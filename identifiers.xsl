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
    <xsl:text>  implicit none&#xA;</xsl:text>
    <xsl:text>  private&#xA;</xsl:text>

      <xsl:if test="//constants[not(@create_mapping_function)]">
	<xsl:apply-templates select="*[name()!='header' and name()!='include' and @used_internally]" mode="Fortran"/>
      </xsl:if>

      <xsl:text>&#xA;  !--- A record for one entry (code, string name, string description)&#xA;</xsl:text>
      <xsl:text>  type :: EnumStruct&#xA;</xsl:text>
      <xsl:text>    integer :: code&#xA;</xsl:text>
      <xsl:text>    character(len=132) :: name&#xA;</xsl:text>
      <xsl:text>    character(len=132) :: description&#xA;</xsl:text>
      <xsl:text>  end type EnumStruct&#xA;&#xA;</xsl:text>

      <xsl:text>  !--- Constant table of all sources (no identifier components needed)&#xA;</xsl:text>
      <xsl:text>  integer, parameter :: n_sources = </xsl:text>
      <xsl:value-of select="count(//constants/int[@name])"/>
      <xsl:text>&#xA;</xsl:text>
      <xsl:text>  type(EnumStruct), parameter :: SOURCES(n_sources) = [ &amp;&#xA;</xsl:text>
      <xsl:call-template name="createSourcesArray"/>
      <xsl:text>&#xA;  !--- An empty type whose methods give you the same API as before&#xA;</xsl:text>
      <xsl:text>  type :: type_</xsl:text><xsl:value-of select="$name"/><xsl:text>&#xA;</xsl:text>
      <xsl:if test="//constants[@create_mapping_function]">
	<xsl:text>  contains&#xA;</xsl:text>
	<xsl:text>    procedure :: index => get_type_index&#xA;</xsl:text>
	<xsl:text>    procedure :: name => get_type_name&#xA;</xsl:text>
	<xsl:text>    procedure :: description => get_type_description&#xA;</xsl:text>
      </xsl:if>
      <xsl:text>  end type type_</xsl:text><xsl:value-of select="$name"/><xsl:text>&#xA;</xsl:text>

	<xsl:text>&#xA;  !--- Public singleton (no per-reaction variables inside!)&#xA;</xsl:text>
	<xsl:text>  type(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), public, parameter :: </xsl:text><xsl:value-of select="$name"/><xsl:text> = &amp;&#xA;</xsl:text>
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
  <xsl:value-of select="my:desc('!&lt;')"/>
</xsl:template>

<xsl:template match="float" mode="Fortran">
  <xsl:text>  real(kind=c_double), parameter :: </xsl:text>
  <xsl:value-of select="@name"/>
  <xsl:text> = </xsl:text>
  <xsl:choose>
    <xsl:when test="@alias!='' or @alias='true'">
      <xsl:call-template name="alias">
        <xsl:with-param name="text" select="."/>
        <xsl:with-param name="symb" select="'_c_double'"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="."/>
      <xsl:text>_c_double</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:value-of select="my:desc('!&lt;')"/>
</xsl:template>

<xsl:template match="string" mode="Fortran">
  <xsl:text>  character(len=*), parameter :: </xsl:text>
  <xsl:value-of select="@name"/>
  <xsl:text> = "</xsl:text>
  <xsl:value-of select="."/><xsl:text>"</xsl:text>
  <xsl:value-of select="my:desc('!&lt;')"/>
</xsl:template>

<xsl:template match="comment" mode="Fortran">
  <xsl:call-template name="replace-string">
    <xsl:with-param name="text" select="concat('&#xA;',text())"/>
    <xsl:with-param name="replace" select="'&#xA;'"/>
    <xsl:with-param name="with" select="'&#xA;  !> '"/>
  </xsl:call-template>
  <xsl:text>&#xA;</xsl:text>
</xsl:template>

<!-- Create sources array -->
<xsl:template name="createSourcesArray">
  <xsl:for-each select="//constants/int[@name]">
    <xsl:text>    EnumStruct(</xsl:text>
    <xsl:choose>
      <xsl:when test="string-length(.) &lt; 4">
        <xsl:text>  </xsl:text><xsl:value-of select="."/>
      </xsl:when>
      <xsl:when test="string-length(.) = 4">
        <xsl:text> </xsl:text><xsl:value-of select="."/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>, '</xsl:text><xsl:value-of select="@name"/><xsl:text>', '</xsl:text>
    <xsl:choose>
      <xsl:when test="string-length(@description) &gt; 132">
        <xsl:value-of select="concat(substring(@description,1,129),'...')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="@description"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>')</xsl:text>
    <xsl:if test="position() != last()">
      <xsl:text>, &amp;&#xA;</xsl:text>
    </xsl:if>
  </xsl:for-each>
  <xsl:text> ]&#xA;</xsl:text>
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

    <!-- Translation from NAME to VALUE -->
    <xsl:if test="int!='' and */@name!=''">
      <xsl:text>  ! Return the code for a given (string) name; -999999999 if not found&#xA;</xsl:text>
      <xsl:text>  integer function </xsl:text>
      <xsl:text>get_type_index(self, NAME)&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), intent(in) :: self&#xA;</xsl:text>
      <xsl:text>    character(*), intent(in) :: NAME&#xA;</xsl:text>
      <xsl:text>    integer :: i&#xA;</xsl:text>
      <xsl:text>    character(len=:), allocatable :: key&#xA;</xsl:text>
      <xsl:text>    key = trim(NAME)&#xA;</xsl:text>
      <xsl:text>    get_type_index = -999999999&#xA;</xsl:text>
      <xsl:text>    do i = 1, n_sources&#xA;</xsl:text>
      <xsl:text>      if (trim(SOURCES(i)%name) == key) then&#xA;</xsl:text>
      <xsl:text>        get_type_index = SOURCES(i)%code&#xA;</xsl:text>
      <xsl:text>        return&#xA;</xsl:text>
      <xsl:text>      end if&#xA;</xsl:text>
      <xsl:text>    end do&#xA;</xsl:text>
      <xsl:text>  end function </xsl:text>
      <xsl:text>get_type_index&#xA;&#xA;</xsl:text>
    </xsl:if>

    <!-- Translation from VALUE to NAME -->
    <xsl:if test="int!=''">
      <xsl:text>  ! Return the name for a given code; empty string if not found&#xA;</xsl:text>
      <xsl:text>  character(132) function </xsl:text>
      <xsl:text>get_type_name(self, IND)&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), intent(in) :: self&#xA;</xsl:text>
      <xsl:text>    integer, intent(in) :: IND&#xA;</xsl:text>
      <xsl:text>    integer :: i&#xA;</xsl:text>
      <xsl:text>    get_type_name = ''&#xA;</xsl:text>
      <xsl:text>    do i = 1, n_sources&#xA;</xsl:text>
      <xsl:text>      if (SOURCES(i)%code == IND) then&#xA;</xsl:text>
      <xsl:text>        get_type_name = SOURCES(i)%name&#xA;</xsl:text>
      <xsl:text>        return&#xA;</xsl:text>
      <xsl:text>      end if&#xA;</xsl:text>
      <xsl:text>    end do&#xA;</xsl:text>
      <xsl:text>  end function </xsl:text>
      <xsl:text>get_type_name&#xA;&#xA;</xsl:text>
    </xsl:if>

    <!-- Translation from VALUE to DESCRIPTION -->
    <xsl:if test="int!=''">
      <xsl:text>  ! Return the description for a given code; empty string if not found&#xA;</xsl:text>
      <xsl:text>  character(132) function </xsl:text>
      <xsl:text>get_type_description(self, IND)&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), intent(in) :: self&#xA;</xsl:text>
      <xsl:text>    integer, intent(in) :: IND&#xA;</xsl:text>
      <xsl:text>    integer :: i&#xA;</xsl:text>
      <xsl:text>    get_type_description = ''&#xA;</xsl:text>
      <xsl:text>    do i = 1, n_sources&#xA;</xsl:text>
      <xsl:text>      if (SOURCES(i)%code == IND) then&#xA;</xsl:text>
      <xsl:text>        get_type_description = SOURCES(i)%description&#xA;</xsl:text>
      <xsl:text>        return&#xA;</xsl:text>
      <xsl:text>      end if&#xA;</xsl:text>
      <xsl:text>    end do&#xA;</xsl:text>
      <xsl:text>  end function </xsl:text>
      <xsl:text>get_type_description&#xA;&#xA;</xsl:text>
    </xsl:if>

</xsl:template>

</xsl:stylesheet>
