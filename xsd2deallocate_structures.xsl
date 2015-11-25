<?xml version="1.0" encoding="UTF-8"?>
<?modxslt-stylesheet type="text/xsl" media="fuffa, screen and $GET[stylesheet]" href="./%24GET%5Bstylesheet%5D" alternate="no" title="Translation using provided stylesheet" charset="ISO-8859-1" ?>
<?modxslt-stylesheet type="text/xsl" media="screen" alternate="no" title="Show raw source of the XML file" charset="ISO-8859-1" ?>
<xsl:stylesheet xmlns:yaslt="http://www.mod-xslt2.com/ns/2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" extension-element-prefixes="yaslt" xmlns:fn="http://www.w3.org/2005/02/xpath-functions" xmlns:local="http://www.example.com/functions/local" exclude-result-prefixes="local xs">
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>
<!-- Author: Frederic Imbeaux (CEA) March 2015 -->
<!-- This XSL transform generates from the schemas the routines to copy and deallocate all DD substructures in Fortran -->

<xsl:function name="local:unique_name" as="xs:string">
<!-- Provides unique 12 characters reference to arbitrary long field name  -->
		<xsl:param name="FullName" as="xs:string"/>
<xsl:variable name="result" as="xs:string" select="concat(lower-case(substring($FullName,1,8)), sum(string-to-codepoints(lower-case(substring($FullName,9)))))"/>
<xsl:value-of select="$result"/>
</xsl:function>


<xsl:template match="/*">

<xsl:for-each select="/*/xs:include">  <!-- Scan all IDSs included in the top dd_physics_data_dictionary, plus utilities -->

<xsl:result-document href="{substring-before(@schemaLocation,'/')}_deallocate_struct.f90"> <!-- Create separate documents otherwise compiler explodes -->
module <xsl:value-of select="local:unique_name(substring-before(@schemaLocation,'/'))"/>_deallocate_struct

<xsl:if test="not(substring-before(@schemaLocation,'/')='utilities')">
use <xsl:value-of select="local:unique_name('utilities')"/>_deallocate_struct
</xsl:if>


interface ids_deallocate
<xsl:for-each select="document(@schemaLocation)/*/xs:complexType"> <!-- Scan all structures within the schema -->
   module procedure ids_deallocate_struct_<xsl:value-of select="local:unique_name(@name)"/>	<!-- The name is truncated since Fortran 90/95 does not authorize procedure names above 33 characters -->
</xsl:for-each>
<xsl:if test="substring-before(@schemaLocation,'/')='utilities'">  <!-- Declare also the reference elements in utilities -->
<xsl:for-each select="document(@schemaLocation)/*/xs:element[./xs:complexType]"> <!-- Scan all elements that are structures -->
   module procedure ids_deallocate_struct_<xsl:value-of select="local:unique_name(@name)"/>	<!-- The name is truncated since Fortran 90/95 does not authorize procedure names above 33 characters -->
</xsl:for-each>
</xsl:if>
end interface ids_deallocate

contains

<xsl:for-each select="document(@schemaLocation)/*/xs:complexType"> <!-- Scan all structures within the schema -->
subroutine ids_deallocate_struct_<xsl:value-of select="local:unique_name(@name)"/>(struct_in)

use ids_schemas
implicit none

integer :: i1,i2,i3,i4,i5,i6,i7

type(ids_<xsl:value-of select="@name"/>) :: struct_in

    <xsl:apply-templates select="./xs:sequence/xs:element" mode="DEALLOCATE_FIELD">
        <xsl:with-param name="level" select="1"/>
        <xsl:with-param name="idxpath" select="''"/>
    </xsl:apply-templates>

end subroutine ids_deallocate_struct_<xsl:value-of select="local:unique_name(@name)"/>

<xsl:text>

</xsl:text>
</xsl:for-each>

<xsl:if test="substring-before(@schemaLocation,'/')='utilities'">  <!-- Declare also the reference elements in utilities -->
<xsl:for-each select="document(@schemaLocation)/*/xs:element[./xs:complexType]"> <!-- Scan all elements that are structures -->

subroutine ids_deallocate_struct_<xsl:value-of select="local:unique_name(@name)"/>(struct_in)

use ids_schemas
implicit none

integer :: i1,i2,i3,i4,i5,i6,i7

type(ids_<xsl:value-of select="@name"/>) :: struct_in

    <xsl:apply-templates select="./xs:complexType/xs:sequence/xs:element" mode="DEALLOCATE_FIELD">
        <xsl:with-param name="level" select="1"/>
        <xsl:with-param name="idxpath" select="''"/>
    </xsl:apply-templates>

<xsl:text>

</xsl:text>
end subroutine ids_deallocate_struct_<xsl:value-of select="local:unique_name(@name)"/>

</xsl:for-each>
</xsl:if>

end module
</xsl:result-document>
</xsl:for-each>
</xsl:template>


<xsl:template match="xs:element" mode="DEALLOCATE_FIELD">
    <xsl:param name="level"/>     <!-- recursion level -->
    <xsl:param name="idxpath"/>   <!-- full fortran path including indices -->

    <!-- build the complete path of the current field -->
    <xsl:param name="currentidxpath" select="concat($idxpath,'%',@name)"/>

    <xsl:choose>
<!-- xs:integer and xs:float are not deallocated (they are not allocatable !) -->
			<xsl:when test="@type='str_type' or ./xs:complexType/xs:group[@ref='STR_0D'] or @type='str_1d_type' or ./xs:complexType/xs:group[@ref='STR_1D'] or @type='flt_1d_type' or ./xs:complexType/xs:group[@ref='FLT_1D'] or @type='int_1d_type' or ./xs:complexType/xs:group[@ref='INT_1D'] or ./xs:complexType/xs:group[@ref='FLT_2D'] or ./xs:complexType/xs:group[@ref='INT_2D'] or ./xs:complexType/xs:group[@ref='FLT_3D'] or ./xs:complexType/xs:group[@ref='INT_3D'] or ./xs:complexType/xs:group[@ref='FLT_4D'] or ./xs:complexType/xs:group[@ref='INT_4D'] or ./xs:complexType/xs:group[@ref='FLT_5D'] or ./xs:complexType/xs:group[@ref='FLT_6D'] ">
   ! deallocate <xsl:value-of select="$currentidxpath"/>
   if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
        deallocate(struct_in<xsl:value-of select="$currentidxpath"/>)
   endif
   			</xsl:when>
	<xsl:when test="@type and not(@type='int_type' or @type='flt_type'  or @type='str_type' or @type='flt_1d_type') and not(@maxOccurs)"> <!-- Case of a simple structure -->
	call ids_deallocate(struct_in<xsl:value-of select = "$currentidxpath"/>)			
	</xsl:when>
         <xsl:when test="@maxOccurs">  <!-- Case of a struct array -->
    ! deallocate <xsl:value-of select="$currentidxpath"/>
    if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
        do i<xsl:value-of select="$level"/> = 1,size(struct_in<xsl:value-of select = "$currentidxpath"/>)
             call ids_deallocate(struct_in<xsl:value-of select = "$currentidxpath"/>(i<xsl:value-of select="$level"/>))
        enddo
        deallocate(struct_in<xsl:value-of select="$currentidxpath"/>)
    endif
         </xsl:when>

<xsl:when test="./xs:complexType/xs:sequence/xs:group[@ref='FLT_1D']">
<!-- Special data/time case for FLT 1D -->
! Deallocate <xsl:value-of select="$currentidxpath"/> 
if (associated(struct_in<xsl:value-of select="$currentidxpath"/>%data)) &amp;
   deallocate(struct_in<xsl:value-of select="$currentidxpath"/>%data)

if (associated(struct_in<xsl:value-of select="$currentidxpath"/>%time)) &amp;
   deallocate(struct_in<xsl:value-of select="$currentidxpath"/>%time)
</xsl:when>

			<xsl:otherwise>
 ! Deallocate <xsl:value-of select="$currentidxpath"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
			</xsl:otherwise>
</xsl:choose>
</xsl:template>




</xsl:stylesheet>

