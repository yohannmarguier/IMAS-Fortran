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
   <xsl:include href="../identifiers/identifiers.common.xsl"/>
   
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>


<!-- MAIN, FILE GENERATION -->
<xsl:template match="/constants">

  <!-- FORTRAN FILE -->
  <exsl:document href="{$prefix}{$name}.f90" method="text">
    <xsl:apply-templates select="header" mode="Fortran"/>

      <xsl:text>&#xA;&#xA;module imas_</xsl:text><xsl:value-of select="$name"/><xsl:text>&#xA;</xsl:text>

    <xsl:apply-templates select="include[@name='Fortran']"/><xsl:text>&#xA;&#xA;</xsl:text>
    <xsl:text>  implicit none&#xA;</xsl:text>
    <xsl:text>  private&#xA;</xsl:text>

      <xsl:if test="//constants[not(@create_mapping_function)]">
	<xsl:apply-templates select="*[name()!='header' and name()!='include' and @used_internally]" mode="Fortran"/>
      </xsl:if>

      <xsl:text>&#xA;  type :: type_</xsl:text><xsl:value-of select="$name"/><xsl:text>&#xA;</xsl:text>
      <xsl:call-template name="declareFortranIntegers"/>
      <xsl:if test="//constants[@create_mapping_function]">
	<xsl:text>  contains&#xA;</xsl:text>
	<xsl:text>    procedure :: index => get_type_index&#xA;</xsl:text>
	<xsl:text>    procedure :: name => get_type_name&#xA;</xsl:text>
	<xsl:text>    procedure :: description => get_type_description&#xA;</xsl:text>
      </xsl:if>
      <xsl:text>  end type type_</xsl:text><xsl:value-of select="$name"/><xsl:text>&#xA;</xsl:text>

	<xsl:text>&#xA;  type(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>), public,parameter :: </xsl:text><xsl:value-of select="$name"/><xsl:text> = type_</xsl:text><xsl:value-of select="$name"/><xsl:text>( &amp;&#xA;</xsl:text>

      <xsl:call-template name="assignFortran"/>

      <xsl:if test="//constants[@create_mapping_function]">

	<xsl:call-template name="translations_Fortran"/>
      </xsl:if>

	<xsl:text>&#xA;end module imas_</xsl:text><xsl:value-of select="$name"/><xsl:text>&#xA;</xsl:text>

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
      <xsl:text>  !&gt; Function returning the VALUE of the type with name NAME.&#xA;</xsl:text>
      <xsl:text>  integer function </xsl:text>
      <xsl:text>get_type_index(SELF,NAME)&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>) :: SELF&#xA;</xsl:text>
      <xsl:text>    character(*) :: NAME  !&lt; The name of the type&#xA;</xsl:text>
      <xsl:text>    </xsl:text>
      <xsl:text>get_type_index=-999999999&#xA;</xsl:text>
      <xsl:text>    select case (trim(NAME))&#xA;</xsl:text>
      <xsl:for-each select="int[@name]">
        <xsl:text>      case ('</xsl:text>
        <xsl:value-of select="@name"/>    
        <xsl:text>')&#xA;</xsl:text>
        <xsl:text>        get_type_index=</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:for-each>
      <xsl:text>    end select&#xA;</xsl:text>
      <xsl:text>  end function </xsl:text>
      <xsl:text>get_type_index&#xA;&#xA;</xsl:text>
    </xsl:if>

    <!-- Translation from VALUE to NAME -->
    <xsl:if test="int!='' and */@unique='yes'">
      <xsl:text>  !&gt; Function returning the NAME of the type with index IND.&#xA;</xsl:text>
      <xsl:text>  character(132) function </xsl:text>
      <xsl:text>get_type_name(SELF,IND)&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>) :: SELF&#xA;</xsl:text>
      <xsl:text>    integer :: IND  !&lt; Type index&#xA;</xsl:text>
      <xsl:text>    </xsl:text>
      <xsl:text>get_type_name=''&#xA;</xsl:text>
      <xsl:text>    select case (IND)&#xA;</xsl:text>
      <xsl:for-each select="int[@name]">
        <xsl:text>      case (</xsl:text>
        <xsl:value-of select="."/>    
        <xsl:text>)&#xA;</xsl:text>
        <xsl:text>        </xsl:text>
        <xsl:text>get_type_name='</xsl:text>
        <xsl:value-of select="@name"/>    
        <xsl:text>'&#xA;</xsl:text>
      </xsl:for-each>
      <xsl:text>    end select&#xA;</xsl:text>
      <xsl:text>  end function </xsl:text>
      <xsl:text>get_type_name&#xA;&#xA;</xsl:text>
    </xsl:if>

    <!-- Translation from VALUE to DESCRIPTION -->
    <xsl:if test="int!='' and */@unique='yes'">
      <xsl:text>  !&gt; Function returning the DESCRIPTION of the type with index IND.&#xA;</xsl:text>
      <xsl:text>  function </xsl:text>
      <xsl:text>get_type_description(SELF,IND)&#xA;</xsl:text>
      <xsl:text>    character(132) :: </xsl:text>
      <xsl:text>get_type_description&#xA;</xsl:text>
      <xsl:text>    class(type_</xsl:text><xsl:value-of select="$name"/><xsl:text>) :: SELF&#xA;</xsl:text>
      <xsl:text>    integer :: IND  !&lt; Type index&#xA;</xsl:text>
      <xsl:text>    </xsl:text>
      <xsl:text>get_type_description=''&#xA;</xsl:text>
      <xsl:text>    select case (IND)&#xA;</xsl:text>
      <xsl:for-each select="*[@unique]">
        <xsl:if test="@unique='yes'">
          <xsl:text>      case (</xsl:text>
          <xsl:value-of select="."/>    
          <xsl:text>)&#xA;</xsl:text>
          <xsl:text>        </xsl:text>
          <xsl:text>get_type_description=&amp; &#xA;'</xsl:text>
	  <xsl:choose>
	    <xsl:when test="string-length(@description) &gt; 132">
	      <xsl:value-of select="concat(substring(@description,1,129),'...')"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:value-of select="@description"/>
	    </xsl:otherwise>
	  </xsl:choose>
          <xsl:text>'&#xA;</xsl:text>
        </xsl:if>
      </xsl:for-each>
      <xsl:text>    end select&#xA;</xsl:text>
      <xsl:text>  end function </xsl:text>
      <xsl:text>get_type_description&#xA;&#xA;</xsl:text>
    </xsl:if>

</xsl:template>

</xsl:stylesheet>
