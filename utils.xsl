<?xml version="1.0" encoding="UTF-8"?>
<?modxslt-stylesheet type="text/xsl" media="fuffa, screen and $GET[stylesheet]" href="./%24GET%5Bstylesheet%5D" alternate="no" title="Translation using provided stylesheet" charset="ISO-8859-1" ?>
<?modxslt-stylesheet type="text/xsl" media="screen" alternate="no" title="Show raw source of the XML file" charset="ISO-8859-1" ?>
<xsl:stylesheet xmlns:yaslt="http://www.mod-xslt2.com/ns/2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" extension-element-prefixes="yaslt" xmlns:fn="http://www.w3.org/2005/02/xpath-functions" xmlns:local="http://www.example.com/functions/local" exclude-result-prefixes="local xs">
  <!-- -->
  <xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>

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

  <!-- function that breaks long strings into smaller ones over several lines (addind specified character at the end and begin of each new lines) -->
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
