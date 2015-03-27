<?xml version="1.0" encoding="UTF-8"?>
<?modxslt-stylesheet type="text/xsl" media="fuffa, screen and $GET[stylesheet]" href="./%24GET%5Bstylesheet%5D" alternate="no" title="Translation using provided stylesheet" charset="ISO-8859-1" ?>
<?modxslt-stylesheet type="text/xsl" media="screen" alternate="no" title="Show raw source of the XML file" charset="ISO-8859-1" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="1.0">
<!-- -->
  <xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>
<!-- -->
<!-- TOP -->
<xsl:template match="/*">! IDS FORTRAN 90 type definitions
! Contains the type definition of all IDSs

<!-- -->
<!-- ======================= ====   Begin : Common Types definition ==== =====================-->
module ids_utilities    ! declare the set of types common to all sub-trees

integer, parameter, public :: DP = kind(1.0d0)
<!-- This method to find all elements and Complex types in Utilities is not clean at all !!! Check when adding additional levels in utilities !-->
<!--
<xsl:apply-templates select="document('utilities/dd_support.xsd')/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType"/> --><!-- Original IDS structure -->
<!-- Redo it with Mask option <xsl:apply-templates select="document('utilities/dd_support.xsd')/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType">
<xsl:with-param name="mask" select="1"/>
</xsl:apply-templates> -->

<!--
<xsl:apply-templates select="document('utilities/dd_support.xsd')/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType"/> --><!-- Original IDS structure -->
<!-- Redo it with Mask option <xsl:apply-templates select="document('utilities/dd_support.xsd')/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType">
<xsl:with-param name="mask" select="1"/>
</xsl:apply-templates> -->
<!--
<xsl:apply-templates select="document('utilities/dd_support.xsd')/*/*/xs:complexType/*/*/xs:complexType"/> --><!-- Original IDS structure -->
<!-- Redo it with Mask option <xsl:apply-templates select="document('utilities/dd_support.xsd')/*/*/xs:complexType/*/*/xs:complexType">
<xsl:with-param name="mask" select="1"/>
</xsl:apply-templates> -->


<!--<xsl:apply-templates select="document('utilities/dd_support.xsd')/*/*/xs:complexType"/>--> <!-- Original IDS structure -->
<!-- Redo it with Mask option <xsl:apply-templates select="document('utilities/dd_support.xsd')/*/*/xs:complexType">
<xsl:with-param name="mask" select="1"/>
</xsl:apply-templates> -->
<!--
<xsl:apply-templates select="document('utilities/dd_support.xsd')/*/xs:complexType/*/*/xs:complexType"/> --><!-- Original IDS structure -->
<!-- Redo it with Mask option <xsl:apply-templates select="document('utilities/dd_support.xsd')/*/xs:complexType/*/*/xs:complexType">
<xsl:with-param name="mask" select="1"/>
</xsl:apply-templates> -->

<!-- Declare complex types -->
<xsl:apply-templates select="document('utilities/dd_support.xsd')/*/xs:complexType"/> <!-- Original IDS structure -->
<!-- Redo it with Mask option <xsl:apply-templates select="document('utilities/dd_support.xsd')/*/xs:complexType">
<xsl:with-param name="mask" select="1"/>
</xsl:apply-templates> -->

<!-- Declare Elements -->
<xsl:apply-templates select="document('utilities/dd_support.xsd')/*/xs:element"/> <!-- INDUCES SPURIOUS TEXT IF A SPECIFIC ELEMENT TEMPLATE IS NOT DECLARED ! -->

end module ! end of the utilities module
<!-- ======================= ====   End :Common Types definition ==== =====================-->
<!-- -->
<!-- Now we declare this schema module -->

<!-- ======================= ====   Begin : declare schema  ==== =====================-->
module ids_schemas       ! declaration of all IDSs
<!-- declare that utilities is an external  module -->
use ids_utilities

integer, parameter :: NON_TIMED=0
integer, parameter :: TIMED=1
integer, parameter :: TIMED_CLEAR=2

<!-- -->
<!-- do the work on the entry file includes -->
<!-- -->
<xsl:apply-templates select="//*/xs:include"/>  <!-- Declares all IDSs which are explicitely defined by a IDS.xsd file, (those must have been included at the beginning of DD_TOP.xsd)-->
<!-- Next : declaration of possible structured objects defined explicitly in the TOP level (no ref, no special type), not adapted to ITER yet because a priori of no use
<xsl:apply-templates select="/*/xs:complexType"/>
<xsl:apply-templates select="/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType"/>
<xsl:apply-templates select="/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType"/>
<xsl:apply-templates select="/*/*/xs:complexType/*/*/xs:complexType"/>
-->
end module

</xsl:template>
<!-- ============================  End : declare schema ========================= -->

<!--                                                                                                                                                -->
<!-- *********************************** TEMPLATES ********************************************* -->
<!-- DOFILE handle all of the contents of one of the include files (in the main file, or the included files) -->
<!-- -->

<!-- ===================== Begin Macro : dofile=======================================-->
  <xsl:template name="dofile">
    <xsl:param name="thisschema"/>
<!-- -->
<!-- First we process the include files -->
<!-- -->
<!-- We no longer include the includes in an included file - it is simpler, but you have to be more explicit at the top level, i.e. must declare all sublevels include at the TOP.xsd level
<xsl:apply-templates select="document($thisschema)//*/xs:include"/>-->
<!-- -->
<!-- Find all required type declarations : does not consider all depths automatically but we are obliged to do so for Fortran since it compiles the Type Def from the beginning to the end of the file -->
<!-- -->
 <!--   <xsl:apply-templates select="document($thisschema)/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType"/> Original IDS structure -->
<!-- Redo it with Mask option <xsl:apply-templates select="document($thisschema)/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType">
<xsl:with-param name="mask" select="1"/>
</xsl:apply-templates>    -->

 <!--   <xsl:apply-templates select="document($thisschema)/*/xs:complexType/*/*/xs:complexType"/>     Original IDS structure -->
<!-- Redo it with Mask option <xsl:apply-templates select="document($thisschema)/*/xs:complexType/*/*/xs:complexType">
<xsl:with-param name="mask" select="1"/>
</xsl:apply-templates>    -->

   <xsl:apply-templates select="document($thisschema)/*/xs:complexType"/>  <!--Original IDS structure -->
 <!-- Redo it with Mask option        <xsl:apply-templates select="document($thisschema)/*/xs:complexType">
<xsl:with-param name="mask" select="1"/>
</xsl:apply-templates>      -->

<!--    <xsl:apply-templates select="document($thisschema)/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType"/>  Original IDS structure -->
 <!-- Redo it with Mask option        <xsl:apply-templates select="document($thisschema)/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType">
<xsl:with-param name="mask" select="1"/>
</xsl:apply-templates>    -->

<!--    <xsl:apply-templates select="document($thisschema)/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType"/>  Original IDS structure -->
 <!-- Redo it with Mask option        <xsl:apply-templates select="document($thisschema)/*/*/xs:complexType/*/*/xs:complexType/*/*/xs:complexType">
<xsl:with-param name="mask" select="1"/>
</xsl:apply-templates>    -->

<!--    <xsl:apply-templates select="document($thisschema)/*/*/xs:complexType/*/*/xs:complexType"/> Original IDS structure -->
 <!-- Redo it with Mask option    <xsl:apply-templates select="document($thisschema)/*/*/xs:complexType/*/*/xs:complexType">
<xsl:with-param name="mask" select="1"/>
</xsl:apply-templates>    -->

  <!-- <xsl:apply-templates select="document($thisschema)/*/*/xs:complexType"/> Original IDS structure -->
 <!-- Redo it with Mask option   <xsl:apply-templates select="document($thisschema)/*/*/xs:complexType">
    <xsl:with-param name="mask" select="1"/>
</xsl:apply-templates>    -->

<!-- Prior the declaration of the top level element, declare any special structure it may contain at its top level  (e.g. a data/time couple) -->
<xsl:apply-templates mode="special_structure" select="document($thisschema)/*/xs:element/xs:complexType/xs:sequence/xs:element[xs:complexType/xs:sequence/xs:element[@ref='time']]">
<xsl:with-param name="level" select="'ids'"/></xsl:apply-templates>


   <xsl:apply-templates select="document($thisschema)/*/xs:element"><xsl:with-param name="level" select="'ids'"/></xsl:apply-templates> <!-- Original IDS structure -->
 <!-- Redo it with Mask option     <xsl:apply-templates select="document($thisschema)/*/*/xs:element">
    <xsl:with-param name="mask" select="1"/>
</xsl:apply-templates>    -->

<!-- -->
  </xsl:template>

  <!-- ===================== End Macro : dofile =======================================-->
<!-- -->


<!-- ===================== Begin Template : xs:include =======================================-->
<!-- XS:INCLUDE template to handle the top include files -->
<!-- -->
  <xsl:template match="xs:include">
    <xsl:variable name="myschema"><xsl:value-of select="@schemaLocation"/></xsl:variable>
    <xsl:if test="$myschema != 'utilities/dd_support.xsd'">
! ***********  Include <xsl:value-of select="@schemaLocation"/>
<xsl:call-template name="dofile"><xsl:with-param name="thisschema" select="$myschema"/></xsl:call-template>
</xsl:if>
  </xsl:template>

  <!-- ===================== Begin Template : Special structure  =======================================-->
<!-- Handles special structures not explicitly declared in the DD, e.g. a data/time couple when a time is introduced directly below an element -->
<!-- -->
  <xsl:template match="xs:element" mode="special_structure">
  <xsl:param name="level"/>
! SPECIAL STRUCTURE data / time<xsl:choose>
	<xsl:when test="$level='complexType'">
type ids_<xsl:for-each select="ancestor::xs:complexType"><xsl:value-of select="@name"/>_</xsl:for-each><xsl:value-of select="@name"/>  !    <xsl:value-of select="substring(./xs:annotation/xs:documentation,1,130)"/> <!-- some compilers do not like too long lines, thus limit the documentation to 130 characters -->
	</xsl:when>
<xsl:otherwise>
type ids_<xsl:for-each select="ancestor::xs:element"><xsl:value-of select="@name"/>_</xsl:for-each><xsl:value-of select="@name"/>  !    <xsl:value-of select="substring(./xs:annotation/xs:documentation,1,130)"/> <!-- some compilers do not like too long lines, thus limit the documentation to 130 characters -->
</xsl:otherwise>
</xsl:choose>
<xsl:choose>
<xsl:when test="@type='str_type' or @type='str_1d_type' or ./xs:complexType/xs:sequence/xs:group[@ref='STR_0D'] or ./xs:complexType/xs:sequence/xs:group[@ref='STR_1D']" >
  character(len=132), dimension(:), pointer ::data => null()     <xsl:call-template name="printnode"/>
</xsl:when>
      <xsl:when test="@type='int_1d_type' or ./xs:complexType/xs:sequence/xs:group[@ref='INT_1D']">
  integer, pointer  :: data(:) => null()    <xsl:call-template name="printnode"/>
</xsl:when>
      <xsl:when test="@type='flt_1d_type' or ./xs:complexType/xs:sequence/xs:group[@ref='FLT_1D']">
  real(DP), pointer  :: data(:) => null()   <xsl:call-template name="printnode"/>
</xsl:when>
      <xsl:when test="@type='int_2d_type' or ./xs:complexType/xs:sequence/xs:group[@ref='INT_2D']">
  integer, pointer  :: data(:,:) => null()   <xsl:call-template name="printnode"/>
</xsl:when>
      <xsl:when test="@type='flt_2d_type' or ./xs:complexType/xs:sequence/xs:group[@ref='FLT_2D']">
  real(DP), pointer  :: data(:,:) => null()   <xsl:call-template name="printnode"/>
  </xsl:when>
  <xsl:when test="./xs:complexType/xs:sequence/xs:group[@ref='FLT_3D']">
  real(DP), pointer  :: data(:,:,:) => null()   <xsl:call-template name="printnode"/>
</xsl:when>
  <xsl:when test="./xs:complexType/xs:sequence/xs:group[@ref='INT_3D'] ">
  integer, pointer  :: data(:,:,:) => null()   <xsl:call-template name="printnode"/>
</xsl:when>
<xsl:when test="./xs:complexType/xs:sequence/xs:group[@ref='FLT_4D'] ">
  real(DP), pointer  :: data(:,:,:,:) => null()   <xsl:call-template name="printnode"/>
  </xsl:when>
  <xsl:when test="./xs:complexType/xs:sequence/xs:group[@ref='FLT_5D']">
  real(DP), pointer  :: data(:,:,:,:,:) => null()   <xsl:call-template name="printnode"/>
  </xsl:when>
  <xsl:when test="./xs:complexType/xs:sequence/xs:group[@ref='FLT_6D'] ">
  real(DP), pointer  :: data(:,:,:,:,:,:) => null()   <xsl:call-template name="printnode"/>
  </xsl:when>
<xsl:when test="./xs:complexType/xs:sequence/xs:group[@ref='FLT_7D'] ">
  real(DP), pointer  :: data(:,:,:,:,:,:,:) => null()   <xsl:call-template name="printnode"/>
  </xsl:when>
</xsl:choose>
<xsl:for-each select="xs:complexType/xs:sequence/xs:element"><xsl:call-template name="declare"/></xsl:for-each>
endtype
 </xsl:template>


<!-- ===================== Begin Template: ComplexType =======================================-->
<!-- -->
<!-- XS:COMPLEXTYPE template for all complexType structures -->
<!-- -->
  <xsl:template match="xs:complexType">
  <xsl:param name="mask"/>
  <xsl:if test="not(./xs:group)">  <!-- if there is a group below, means this is a leaf, do not declare it as a structure, so skip all the template-->

<!-- Prior the declaration of the Complex Type, declare any special structure it may contain at its top level  (e.g. a data/time couple) -->
<xsl:apply-templates mode="special_structure" select="./xs:sequence/xs:element[xs:complexType/xs:sequence/xs:element[@ref='time']]">
<xsl:with-param name="level" select="'complexType'"/></xsl:apply-templates>


  <xsl:choose>
	<xsl:when test="$mask">
type ids_<xsl:value-of select="../@name"/><xsl:value-of select="@name"/>_mask  !    <xsl:value-of select="substring(./xs:annotation/xs:documentation,1,130)"/> <!-- some compilers do not like too long lines, thus limit the documentation to 130 characters -->
	</xsl:when>
  <xsl:otherwise>
type ids_<xsl:value-of select="../@name"/><xsl:value-of select="@name"/>  !    <xsl:value-of select="substring(./xs:annotation/xs:documentation,1,130)"/> <!-- some compilers do not like too long lines, thus limit the documentation to 130 characters -->
</xsl:otherwise>
</xsl:choose>
<xsl:for-each select="xs:sequence/xs:element"><xsl:call-template name="declare"><xsl:with-param name="mask" select="$mask"/><xsl:with-param name="level" select="'complexType'"/></xsl:call-template></xsl:for-each>
endtype
</xsl:if>
</xsl:template>
<!-- ===================== End Template :ComplexType =======================================-->

<!-- ===================== Begin Template: Element in Utilities=======================================-->
<!-- -->
  <xsl:template name="declare_element" match="xs:element">
  <xsl:param name="mask"/>
  <xsl:if test="not(./xs:group) and not(@name='time')">  <!-- if there is a group below, means this is a leaf, do not declare it as a structure, so skip all the template. Skip also the time, which is a reserved name-->
  <xsl:choose>
	<xsl:when test="$mask">
type ids_<xsl:value-of select="../@name"/><xsl:value-of select="@name"/>_mask  !    <xsl:value-of select="substring(./xs:annotation/xs:documentation,1,130)"/> <!-- some compilers do not like too long lines, thus limit the documentation to 130 characters -->
	</xsl:when>
  <xsl:otherwise>
type ids_<xsl:value-of select="../@name"/><xsl:value-of select="@name"/>  !    <xsl:value-of select="substring(./xs:annotation/xs:documentation,1,130)"/> <!-- some compilers do not like too long lines, thus limit the documentation to 130 characters -->
</xsl:otherwise>
</xsl:choose>
<xsl:for-each select="./xs:complexType/xs:sequence/xs:element"><xsl:call-template name="declare"><xsl:with-param name="mask" select="$mask"/></xsl:call-template></xsl:for-each>
endtype
</xsl:if>
</xsl:template>
<!-- ===================== End Template :Element in Utilities =======================================-->


<!-- -->
<!-- DECLARE  Make a declaration of the current element -->
<!-- -->
<!-- ===================== Begin Macro : declare =======================================-->
  <xsl:template name="declare">
  <xsl:param name="mask"/>
    <xsl:param name="level"/>

<xsl:choose>
	<xsl:when test="$mask">  <!-- Mask mode : declare all leaves as integers, meaning : 0: no put, 1: put with serial UAL, 2: put with // UAL-->
	<!-- This part is not active since for the moment we do not use the mask -->
  <xsl:choose>
      <xsl:when test="@ref">
  type (ids_<xsl:value-of select="@ref"/>_mask)<xsl:if test="@maxOccurs ='unbounded'">,pointer</xsl:if> :: <xsl:value-of select="@ref"/> <xsl:if test="@maxOccurs ='unbounded'">(:) => null()</xsl:if>       <xsl:call-template name="printnode"/>
      </xsl:when>
      <xsl:when test="not(@ref) and not(@type)">  <!--case of a sub-structure with no external reference (not in utilities or elsewhere) -->
  type (ids_<xsl:value-of select="@name"/>_mask)<xsl:if test="@maxOccurs &gt; 1 or @maxOccurs ='unbounded'">,pointer</xsl:if> :: <xsl:value-of select="@name"/>  <xsl:if test="@maxOccurs &gt; 1 or @maxOccurs ='unbounded'">(:) => null()</xsl:if>     <xsl:call-template name="printnode"/>
</xsl:when>
<xsl:when test="@type='xs:string' or @type='vecstring_type' or @type='vecint_type' or @type='vecflt_type' or @type='matint_type' or @type='matflt_type'  or @type='array3dflt_type' or  @type='array3dint_type' or @type='array4dflt_type' or @type='array5dflt_type' or @type='array6dflt_type' or @type='array7dflt_type' or @type='xs:integer' or @type='xs:float' ">
  integer  :: <xsl:value-of select="@name"/>=0     <xsl:call-template name="printnode"/>
</xsl:when>
<xsl:otherwise>
   <!-- assume this is a complex type defined somewhere else, likely in utilities or at the beginning of the xsd file -->
  type (ids_<xsl:value-of select="@type"/>_mask)<xsl:if test="@maxOccurs ='unbounded'">,pointer</xsl:if> :: <xsl:value-of select="@name"/><xsl:if test="@maxOccurs ='unbounded'">(:) => null()</xsl:if>   <xsl:call-template name="printnode"/>
      </xsl:otherwise>
    </xsl:choose>

	</xsl:when>
<xsl:otherwise>
    <xsl:choose>
      <xsl:when test="@ref">
      <xsl:choose>
<xsl:when test="@ref='time'">  <!-- time is a reserved name and case-->
  real(DP), pointer  :: time(:) => null()  ! time</xsl:when>
<xsl:otherwise>
  type (ids_<xsl:value-of select="@ref"/>)<xsl:if test="@maxOccurs &gt; 1or @maxOccurs ='unbounded'">,pointer</xsl:if> :: <xsl:value-of select="@ref"/> <xsl:if test="@maxOccurs &gt; 1or @maxOccurs ='unbounded'">(:) => null()</xsl:if>       <xsl:call-template name="printnode"/>
</xsl:otherwise>
						</xsl:choose>
      </xsl:when>
      <!-- This case should not happen if we declare properly all complex types at the beginning of the XSDs ? -->
  <!--<xsl:when test="not(@ref) and not(@type) and not(./xs:complexType/xs:group)">
  type (ids_<xsl:value-of select="@name"/>)<xsl:if test="@maxOccurs &gt; 1 or @maxOccurs ='unbounded'">,pointer</xsl:if> :: <xsl:value-of select="@name"/>  <xsl:if test="@maxOccurs &gt; 1 or @maxOccurs ='unbounded'">(:) => null()</xsl:if>     <xsl:call-template name="printnode"/>
</xsl:when> -->
<xsl:when test="@type='str_type' or @type='str_1d_type' or ./xs:complexType/xs:group[@ref='STR_0D'] or ./xs:complexType/xs:group[@ref='STR_1D']" >
  character(len=132), dimension(:), pointer ::<xsl:value-of select="@name"/> => null()     <xsl:call-template name="printnode"/>
</xsl:when>
      <xsl:when test="@type='int_1d_type' or ./xs:complexType/xs:group[@ref='INT_1D']">
  integer,pointer  :: <xsl:value-of select="@name"/>(:) => null()    <xsl:call-template name="printnode"/>
</xsl:when>
      <xsl:when test="@type='flt_1d_type' or ./xs:complexType/xs:group[@ref='FLT_1D']">
  real(DP),pointer  :: <xsl:value-of select="@name"/>(:) => null()   <xsl:call-template name="printnode"/>
</xsl:when>
      <xsl:when test="@type='int_2d_type' or ./xs:complexType/xs:group[@ref='INT_2D']">
  integer,pointer  :: <xsl:value-of select="@name"/>(:,:) => null()   <xsl:call-template name="printnode"/>
</xsl:when>
      <xsl:when test="@type='flt_2d_type' or ./xs:complexType/xs:group[@ref='FLT_2D']">
  real(DP),pointer  :: <xsl:value-of select="@name"/>(:,:) => null()   <xsl:call-template name="printnode"/>
  </xsl:when>
  <xsl:when test="./xs:complexType/xs:group[@ref='FLT_3D']">
  real(DP),pointer  :: <xsl:value-of select="@name"/>(:,:,:) => null()   <xsl:call-template name="printnode"/>
</xsl:when>
  <xsl:when test="./xs:complexType/xs:group[@ref='INT_3D'] ">
  integer,pointer  :: <xsl:value-of select="@name"/>(:,:,:) => null()   <xsl:call-template name="printnode"/>
</xsl:when>
<xsl:when test="./xs:complexType/xs:group[@ref='FLT_4D'] ">
  real(DP),pointer  :: <xsl:value-of select="@name"/>(:,:,:,:) => null()   <xsl:call-template name="printnode"/>
  </xsl:when>
  <xsl:when test="./xs:complexType/xs:group[@ref='FLT_5D']">
  real(DP),pointer  :: <xsl:value-of select="@name"/>(:,:,:,:,:) => null()   <xsl:call-template name="printnode"/>
  </xsl:when>
  <xsl:when test="./xs:complexType/xs:group[@ref='FLT_6D'] ">
  real(DP),pointer  :: <xsl:value-of select="@name"/>(:,:,:,:,:,:) => null()   <xsl:call-template name="printnode"/>
  </xsl:when>
<xsl:when test="./xs:complexType/xs:group[@ref='FLT_7D'] ">
  real(DP),pointer  :: <xsl:value-of select="@name"/>(:,:,:,:,:,:,:) => null()   <xsl:call-template name="printnode"/>
  </xsl:when>
      <xsl:when test="@type='int_type' or ./xs:complexType/xs:group[@ref='INT_0D']">
  integer  :: <xsl:value-of select="@name"/>=-999999999     <xsl:call-template name="printnode"/>
</xsl:when>
      <xsl:when test="@type='flt_type' or ./xs:complexType/xs:group[@ref='FLT_0D']">
  real(DP)  :: <xsl:value-of select="@name"/>=-9.0D40     <xsl:call-template name="printnode"/>
</xsl:when>
<!--<xsl:when test="@type and contains(string(xs:annotation/xs:documentation), 'IDS')"> --><!-- Special case of IDSs defined in the schemas with a generic type defined somewhere else, e.g. utilities : like interfdiag, polardiag -->
 <!--  type (ids_<xsl:value-of select="@name"/>) -->   <!-- IDS declaration with its explicit name -->
 <!-- ! NEWSEPTEMBER-->
   <!--<xsl:call-template name="declare_specialids_IDS">
   <xsl:with-param name="IDS_specialtype" select="@type"/>
   </xsl:call-template>-->
   <!--endtype-->
<!--</xsl:when>-->
<xsl:when test="xs:complexType/xs:sequence/xs:element[@ref='time']">  <!-- special structure data / time -->

<xsl:choose>
	<xsl:when test="$level='complexType'">
  type (ids_<xsl:for-each select="ancestor::xs:complexType"><xsl:value-of select="@name"/>_</xsl:for-each><xsl:value-of select="@name"/>)<xsl:if test="@maxOccurs &gt; 1or @maxOccurs ='unbounded'">,pointer</xsl:if> :: <xsl:value-of select="@name"/><xsl:if test="@maxOccurs &gt; 1or @maxOccurs ='unbounded'">(:) => null()</xsl:if>   <xsl:call-template name="printnode"/>
 </xsl:when>
<xsl:otherwise>
  type (ids_<xsl:for-each select="ancestor::xs:element"><xsl:value-of select="@name"/>_</xsl:for-each><xsl:value-of select="@name"/>)<xsl:if test="@maxOccurs &gt; 1or @maxOccurs ='unbounded'">,pointer</xsl:if> :: <xsl:value-of select="@name"/><xsl:if test="@maxOccurs &gt; 1or @maxOccurs ='unbounded'">(:) => null()</xsl:if>   <xsl:call-template name="printnode"/></xsl:otherwise>
</xsl:choose>


</xsl:when>

<xsl:otherwise>
   <!-- assume this is a complex type defined somewhere else, likely in utilities or at the beginning of the xsd file -->
  type (ids_<xsl:value-of select="@type"/>)<xsl:if test="@maxOccurs &gt; 1or @maxOccurs ='unbounded'">,pointer</xsl:if> :: <xsl:value-of select="@name"/><xsl:if test="@maxOccurs &gt; 1or @maxOccurs ='unbounded'">(:) => null()</xsl:if>   <xsl:call-template name="printnode"/>
      </xsl:otherwise>
    </xsl:choose>

    </xsl:otherwise>
  </xsl:choose>
  </xsl:template>

<!-- ===================== End Macro : declare =======================================-->

<!-- =================================== Begin Macro : declare IDS of generic type defined in utilities, e.g. lineintegraldiag ===========================-->
<!--<xsl:template match="*[@type and contains(string(xs:annotation/xs:documentation), 'IDS')]" mode="special_type">
type ids_<xsl:value-of select="@name"/>  ! Special type IDS (<xsl:value-of select="@type"/>) <xsl:call-template name="declare_specialids_IDS">
   <xsl:with-param name="IDS_specialtype" select="@type"/>
   </xsl:call-template>
end type
</xsl:template>-->
<!-- =================================== End Macro : declare IDS of generic type defined in utilities, e.g. lineintegraldiag ===========================-->



<!-- =================================== Begin Macro : declare_specialids_IDS : for a IDS of generic type defined in utilities, e.g. lineintegraldiag, copies explicitely all elements from the definition in utilities/dd_support.xsd. NB : only the first level is copied, the deeper level have been declared before during the work on utilities/dd_support.xsd ===========================-->
<!--<xsl:template name="declare_specialids_IDS">
<xsl:param name="IDS_specialtype"/>
   <xsl:for-each select="document('utilities/dd_support.xsd')/*/xs:complexType[@name=$IDS_specialtype]/*/xs:element"><xsl:call-template name="declare"/></xsl:for-each>
</xsl:template>  -->
<!-- =================================== End Macro : declare_specialids_IDS IDS of generic type defined in utilities, e.g. lineintegraldiag ===========================-->

  <!-- =================================== Begin Macro : printnode===========================-->
  <xsl:template name="printnode">  ! <xsl:for-each select="ancestor-or-self::xs:element"><xsl:text>/</xsl:text><xsl:value-of select="@name"/><xsl:value-of select="@ref"/><xsl:if test="@maxOccurs &gt; 1 or @maxOccurs ='unbounded'">(i)</xsl:if></xsl:for-each> - <xsl:value-of select="substring(xs:annotation/xs:documentation,1,100)"/>  <!-- some compilers do not like too long lines, thus limit the documentation to 130 characters -->
 </xsl:template>
 <!-- =================================== End Macro : printnode===========================-->

</xsl:stylesheet>

