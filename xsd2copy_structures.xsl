<?xml version="1.0" encoding="UTF-8"?>
<?modxslt-stylesheet type="text/xsl" media="fuffa, screen and $GET[stylesheet]" href="./%24GET%5Bstylesheet%5D" alternate="no" title="Translation using provided stylesheet" charset="ISO-8859-1" ?>
<?modxslt-stylesheet type="text/xsl" media="screen" alternate="no" title="Show raw source of the XML file" charset="ISO-8859-1" ?>
<xsl:stylesheet xmlns:yaslt="http://www.mod-xslt2.com/ns/2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" extension-element-prefixes="yaslt" xmlns:fn="http://www.w3.org/2005/02/xpath-functions" xmlns:local="http://www.example.com/functions/local" exclude-result-prefixes="local xs">
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>
<!-- Author: Frederic Imbeaux (CEA) March 2015 -->

<xsl:function name="local:unique_name" as="xs:string">
<!-- Provides unique 12 characters reference to arbitrary long field name  -->
		<xsl:param name="FullName" as="xs:string"/>
<xsl:variable name="result" as="xs:string" select="concat(lower-case(substring($FullName,1,8)), sum(string-to-codepoints(lower-case(substring($FullName,9)))))"/>
<xsl:value-of select="$result"/>
</xsl:function>


<xsl:template match="/*">

<xsl:for-each select="/*/xs:include">  <!-- Scan all IDSs included in the top dd_physics_data_dictionary, plus utilities -->

<xsl:result-document href="{substring-before(@schemaLocation,'/')}_copy_struct.f90"> <!-- Create separate documents otherwise compiler explodes -->
module <xsl:value-of select="substring-before(@schemaLocation,'/')"/>_copy_struct

<xsl:if test="not(substring-before(@schemaLocation,'/')='utilities')">
use utilities_copy_struct
</xsl:if>

interface ids_copy
<xsl:for-each select="document(@schemaLocation)/*/xs:complexType"> <!-- Scan all structures within the schema -->
   module procedure ids_copy_struct_<xsl:value-of select="local:unique_name(@name)"/>	<!-- The name is truncated since Fortran 90/95 does not authorize procedure names above 33 characters -->
</xsl:for-each>
<xsl:if test="substring-before(@schemaLocation,'/')='utilities'">  <!-- Declare also the reference elements in utilities -->
<xsl:for-each select="document(@schemaLocation)/*/xs:element[./xs:complexType]"> <!-- Scan all elements that are structures -->
   module procedure ids_copy_struct_<xsl:value-of select="local:unique_name(@name)"/>	<!-- The name is truncated since Fortran 90/95 does not authorize procedure names above 33 characters -->
</xsl:for-each>
</xsl:if>
end interface ids_copy

contains

<xsl:for-each select="document(@schemaLocation)/*/xs:complexType"> <!-- Scan all structures within the schema -->
subroutine ids_copy_struct_<xsl:value-of select="local:unique_name(@name)"/>(struct_in,  struct_out)
! Copies all fields of struct_in to struct_out
! Assumes that struct_in is a single instance of a given structure

use ids_schemas
implicit none
!integer, parameter :: DP=kind(1.0D0)

integer :: itime, lentime, lenstring, istring
integer :: i1,i2,i3,i4,i5,i6,i7

type(ids_<xsl:value-of select="@name"/>) :: struct_in, struct_out

      <xsl:apply-templates select="./xs:sequence/xs:element" mode="COPY_FIELD">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="idxpath" select="''"/>
      </xsl:apply-templates>

return
end subroutine ids_copy_struct_<xsl:value-of select="local:unique_name(@name)"/>
<xsl:text>

</xsl:text>
</xsl:for-each>

<xsl:if test="substring-before(@schemaLocation,'/')='utilities'">  <!-- Declare also the reference elements in utilities -->
<xsl:for-each select="document(@schemaLocation)/*/xs:element[./xs:complexType]"> <!-- Scan all elements that are structures -->
subroutine ids_copy_struct_<xsl:value-of select="local:unique_name(@name)"/>(struct_in,  struct_out)
! Copies all fields of struct_in to struct_out
! Assumes that struct_in is a single instance of a given structure

use ids_schemas
implicit none
!integer, parameter :: DP=kind(1.0D0)

integer :: itime, lentime, lenstring, istring
integer :: i1,i2,i3,i4,i5,i6,i7

type(ids_<xsl:value-of select="@name"/>) :: struct_in, struct_out

      <xsl:apply-templates select="./xs:complexType/xs:sequence/xs:element" mode="COPY_FIELD">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="idxpath" select="''"/>
      </xsl:apply-templates>

return
end subroutine ids_copy_struct_<xsl:value-of select="local:unique_name(@name)"/>
<xsl:text>

</xsl:text>
</xsl:for-each>
</xsl:if>

end module
</xsl:result-document>
</xsl:for-each>
</xsl:template>


<xsl:template match="xs:element" mode="COPY_FIELD">
<!-- copy an element from an IDS, almost the same routine as in IDSDef2F90Routines but adapted to work directly on the XSD schemas -->
<xsl:param name="level"/>     <!-- recursion level -->
<xsl:param name="idxpath"/>   <!-- full fortran path including indices -->
<!-- build the complete path of the current field -->
<xsl:param name="currentidxpath" select="concat($idxpath,'%',@name)"/>

		<xsl:choose>
         <xsl:when test="@maxOccurs">  <!-- Case of a struct array -->
! Copy <xsl:value-of select="$currentidxpath"/>
if (associated(struct_in<xsl:value-of select = "$currentidxpath"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(struct_out<xsl:value-of select="$currentidxpath"/>(size(struct_in<xsl:value-of select = "$currentidxpath"/>)))
   do i<xsl:value-of select="$level"/> = 1,size(struct_in<xsl:value-of select = "$currentidxpath"/>)
      call ids_copy(struct_in<xsl:value-of select = "$currentidxpath"/>(i<xsl:value-of select="$level"/>), struct_out<xsl:value-of select = "$currentidxpath"/>(i<xsl:value-of select="$level"/>))
<!-- Let's be clever and make it recursive -->
<!-- OLD version    <xsl:apply-templates select = "./xs:sequence/xs:element" mode = "COPY_FIELD">
         <xsl:with-param name="level" select="$level + 1"/>
         <xsl:with-param name="idxpath" select="concat($currentidxpath,'(i',$level,')')"/>
      </xsl:apply-templates> -->
   enddo
endif
         </xsl:when>
			<xsl:when test="@type and not(@type='int_type' or @type='flt_type'  or @type='str_type' or @type='flt_1d_type') and not(@maxOccurs)"> <!-- Case of a simple structure -->
      call ids_copy(struct_in<xsl:value-of select = "$currentidxpath"/>, struct_out<xsl:value-of select = "$currentidxpath"/>)

        <!-- Let's be clever and make it recursive -->
<!-- OLD version   <xsl:apply-templates select = "./xs:sequence/xs:element" mode = "COPY_FIELD">
          <xsl:with-param name="level" select="$level"/>
          <xsl:with-param name="idxpath" select="$currentidxpath"/>
        </xsl:apply-templates> -->
			</xsl:when>
			<xsl:when test="@type='str_type' or @type='str_1d_type' or ./xs:complexType/xs:group[@ref='STR_0D'] or ./xs:complexType/xs:group[@ref='STR_1D'] or @type='flt_1d_type' or ./xs:complexType/xs:group[@ref='FLT_1D'] or @type='int_1d_type' or ./xs:complexType/xs:group[@ref='INT_1D'] ">
! Copy <xsl:value-of select="$currentidxpath"/>
if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
   allocate(struct_out<xsl:value-of select="$currentidxpath"/>&amp;
      (size(struct_in<xsl:value-of select="$currentidxpath"/>,1)))
   struct_out<xsl:value-of select="$currentidxpath"/> = &amp;
   struct_in<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='int_type' or ./xs:complexType/xs:group[@ref='INT_0D']">
! Copy <xsl:value-of select="$currentidxpath"/>
if (struct_in<xsl:value-of select="$currentidxpath"/>/=-999999999)  then
   struct_out<xsl:value-of select="$currentidxpath"/> = &amp;
   struct_in<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='flt_type' or ./xs:complexType/xs:group[@ref='FLT_0D']">
! Copy <xsl:value-of select="$currentidxpath"/>
if (struct_in<xsl:value-of select="$currentidxpath"/>.NE.-9.D40) then
   struct_out<xsl:value-of select="$currentidxpath"/> = &amp;
   struct_in<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='int_2d_type' or ./xs:complexType/xs:group[@ref='INT_2D'] or @type='flt_2d_type' or ./xs:complexType/xs:group[@ref='FLT_2D']">
! Copy <xsl:value-of select="$currentidxpath"/>
if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
   allocate(struct_out<xsl:value-of select="$currentidxpath"/>&amp;
      (size(struct_in<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,2)))
   struct_out<xsl:value-of select="$currentidxpath"/> = &amp;
   struct_in<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="./xs:complexType/xs:group[@ref='INT_3D'] or ./xs:complexType/xs:group[@ref='FLT_3D']">
! Copy <xsl:value-of select="$currentidxpath"/>
if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
   allocate(struct_out<xsl:value-of select="$currentidxpath"/>&amp;
      (size(struct_in<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,3)))
   struct_out<xsl:value-of select="$currentidxpath"/> = &amp;
   struct_in<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="./xs:complexType/xs:group[@ref='INT_4D'] or ./xs:complexType/xs:group[@ref='FLT_4D']">
! Copy <xsl:value-of select="$currentidxpath"/>
if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
   allocate(struct_out<xsl:value-of select="$currentidxpath"/>&amp;
      (size(struct_in<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,3), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,4)))
   struct_out<xsl:value-of select="$currentidxpath"/> = &amp;
   struct_in<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="./xs:complexType/xs:group[@ref='INT_5D'] or ./xs:complexType/xs:group[@ref='FLT_5D']">
! Copy <xsl:value-of select="$currentidxpath"/>
if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
   allocate(struct_out<xsl:value-of select="$currentidxpath"/>&amp;
      (size(struct_in<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,3), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,4), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,5)))
   struct_out<xsl:value-of select="$currentidxpath"/> = &amp;
   struct_in<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
<xsl:when test="./xs:complexType/xs:group[@ref='INT_6D'] or ./xs:complexType/xs:group[@ref='FLT_6D']">
! Copy <xsl:value-of select="$currentidxpath"/>
if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
   allocate(struct_out<xsl:value-of select="$currentidxpath"/>&amp;
      (size(struct_in<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,3), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,4), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,5), &amp;
      size(struct_in<xsl:value-of select="$currentidxpath"/>,6)))
   struct_out<xsl:value-of select="$currentidxpath"/> = &amp;
   struct_in<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
<xsl:when test="./xs:complexType/xs:sequence/xs:group[@ref='FLT_1D']">
<!-- Special data/time case for FLT 1D -->
! Copy <xsl:value-of select="$currentidxpath"/>
if (associated(struct_in<xsl:value-of select="$currentidxpath"/>%data)) then
   allocate(struct_out<xsl:value-of select="$currentidxpath"/>%data&amp;
      (size(struct_in<xsl:value-of select="$currentidxpath"/>%data,1)))
   struct_out<xsl:value-of select="$currentidxpath"/>%data = &amp;
   struct_in<xsl:value-of select="$currentidxpath"/>%data

   allocate(struct_out<xsl:value-of select="$currentidxpath"/>%time&amp;
      (size(struct_in<xsl:value-of select="$currentidxpath"/>%time,1)))
   struct_out<xsl:value-of select="$currentidxpath"/>%time = &amp;
   struct_in<xsl:value-of select="$currentidxpath"/>%time
endif

</xsl:when>

			<xsl:otherwise>
 ! Copy <xsl:value-of select="$currentidxpath"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
			</xsl:otherwise>
		</xsl:choose>
</xsl:template>

</xsl:stylesheet>

