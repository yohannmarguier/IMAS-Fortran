<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- XSL transformation reducing the Data Dictionary to a subset of its IDSs.

     Everything except the <IDS> elements is copied verbatim - in particular the
     <utilities> node, which is a sibling of <IDS> and is needed by every
     generator regardless of which IDSs are kept.

     Parameter:
       keep   comma-separated list of IDS names to retain (e.g. "equilibrium")
              A comma is used rather than a semicolon because CMake would split
              a semicolon-containing string into separate command line arguments.
-->

<xsl:output method="xml" encoding="UTF-8" />

<xsl:param name="keep" />

<!-- Comma-delimited on both ends, so that a name never matches a substring of
     another name (e.g. "waves" must not match "em_coupling_waves"). -->
<xsl:variable name="keep-list"
  select="concat(',', translate($keep, ' &#9;&#10;&#13;', ''), ',')" />

<!-- Identity transformation -->
<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<!-- ... except for IDSs that are not in the subset -->
<xsl:template match="/IDSs/IDS">
  <xsl:if test="contains($keep-list, concat(',', @name, ','))">
    <xsl:copy-of select="."/>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
