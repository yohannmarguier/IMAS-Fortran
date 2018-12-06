 <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions">
    <xsl:output method="text"/>
    <xsl:strip-space elements="*"/>

    <xsl:param name="newLowLevel" select="'no'" />

    <!-- Initial c ode -->
    <xsl:template match="IDSs">

      <xsl:if test="$newLowLevel ='yes'">
	######### GENERATION FOR NEW LOW LEVEL #####
      </xsl:if>

	  <xsl:apply-templates select="child::IDS" mode="init_static"/>
	  <xsl:apply-templates select="child::IDS" mode="init_dynamic"/>
	  <xsl:apply-templates select="child::IDS" mode="test_static"/>
          <xsl:apply-templates select="child::IDS" mode="test_dynamic"/>
	  <xsl:apply-templates select="child::IDS" mode="all_test"/>
	  <xsl:apply-templates select="child::IDS" mode="put_test"/>
	  <xsl:apply-templates select="child::IDS" mode="get_test"/>
    </xsl:template>

 <!-- ============================= END OF GENRATED FILE ============================== -->

 
 
 
 <!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS INIT STATIC                                             -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="IDS" mode="init_static">
  <xsl:result-document href="src/{@name}_init_static.f90">
        <xsl:text>module </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_static_mod&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text>
        <xsl:text>&#9;use ids_schemas, only: ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>&#10;</xsl:text>
        <xsl:text>&#9;use generator&#10;</xsl:text>
         <xsl:text>&#9;use setter&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>&#9;implicit none&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>contains</xsl:text>
        <xsl:text>&#xA;</xsl:text>

        <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>!&#9;&#9; INIT STATIC DATA: </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
        <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_static( ids )&#10;</xsl:text>
        <xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>), INTENT(INOUT) :: ids &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>

        <xsl:apply-templates select="field" mode="putStatic"/> 

        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text> <xsl:value-of select="@name"/><xsl:text>_init_static&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END MODULE </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_static_mod&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
  </xsl:result-document>
</xsl:template>


 <!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS INIT DYNAMIC                                             -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="IDS" mode="init_dynamic">
  <xsl:result-document href="src/{@name}_init_dynamic.f90">
        <xsl:text>module </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_dynamic_mod&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text>
        <xsl:text>&#9;use ids_schemas, only: ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>&#10;</xsl:text>
        <xsl:text>&#9;use generator&#10;</xsl:text>
            <xsl:text>&#9;use setter&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>&#9;implicit none&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>contains</xsl:text>
        <xsl:text>&#xA;</xsl:text>

        <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>!&#9;&#9; INIT DYNAMIC DATA: </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
        <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_dynamic( ids, isSliceMode, j )&#10;</xsl:text>
        <xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>), INTENT(INOUT) :: ids &#10;</xsl:text>
        <xsl:text>&#9;LOGICAL, INTENT(IN) :: isSliceMode &#10;</xsl:text>
        <xsl:text>&#9;INTEGER, INTENT(IN) :: j &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>

        <xsl:apply-templates select="field" mode="putDynamic"/> 

        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text> <xsl:value-of select="@name"/><xsl:text>_init_dynamic&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END MODULE </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_dynamic_mod&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
  </xsl:result-document>
</xsl:template>

 <!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS TEST STATIC                                             -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="IDS" mode="test_static">
  <xsl:result-document href="src/{@name}_test_static.f90">
        <xsl:text>module </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_static_mod&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text>
         <xsl:text>&#9;use generator&#10;</xsl:text>
        <xsl:text>&#9;use comparator &#10;</xsl:text>
        <xsl:text>&#9;use ids_schemas, only: ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>&#10;</xsl:text>
        <xsl:text>&#9;implicit none&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>contains</xsl:text>
        <xsl:text>&#xA;</xsl:text>

        <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>!&#9;&#9; TEST STATIC DATA: </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
        <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_static( ids )&#10;</xsl:text>
        <xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>), INTENT(INOUT) :: ids &#10;</xsl:text>
        <xsl:text>&#9;LOGICAL :: isEqual &#10;</xsl:text>
        
        <xsl:text>&#10;</xsl:text>

        <xsl:apply-templates select="field" mode="getStatic"/> 

        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text> <xsl:value-of select="@name"/><xsl:text>_test_static&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END MODULE </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_static_mod&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
  </xsl:result-document>
</xsl:template>


 <!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS TEST DYNAMIC                                             -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="IDS" mode="test_dynamic">
  <xsl:result-document href="src/{@name}_test_dynamic.f90">
        <xsl:text>module </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_dynamic_mod&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text>
        <xsl:text>&#9;use generator&#10;</xsl:text>
        <xsl:text>&#9;use comparator &#10;</xsl:text>
        <xsl:text>&#9;use ids_schemas, only: ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>&#9;implicit none&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>contains</xsl:text>
        <xsl:text>&#xA;</xsl:text>

        <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>!&#9;&#9; TEST DYNAMIC DATA: </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
        <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_dynamic( ids, isSliceMode, j )&#10;</xsl:text>
        <xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>), INTENT(INOUT) :: ids &#10;</xsl:text>
        <xsl:text>&#9;LOGICAL, INTENT(IN) :: isSliceMode &#10;</xsl:text>
        <xsl:text>&#9;INTEGER, INTENT(IN) :: j &#10;</xsl:text>
        <xsl:text>&#9;LOGICAL :: isEqual &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>

        <xsl:apply-templates select="field" mode="getDynamic"/> 

        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text> <xsl:value-of select="@name"/><xsl:text>_test_dynamic&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END MODULE </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_dynamic_mod&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
  </xsl:result-document>
</xsl:template>
 
 <!-- ============================= TEMPLATES ============================== -->

        <!--Documentation for a single field-->
      <!--Documentation for a single field-->
    <xsl:template name = "COMMENT_FIELD">
        <xsl:text>&#xA;</xsl:text>
	<xsl:text>&#9;&#9;!!-----------------------------------------------------------------------------------------!!&#xA;</xsl:text>
	<xsl:text>&#9;&#9;!!  </xsl:text><xsl:value-of select="@name"/>:<xsl:value-of select="@path"/>:<xsl:value-of select="@data_type"/>:<xsl:value-of select="@type"/>:<xsl:text>&#xA;</xsl:text>
	<xsl:text>&#9;&#9;!!-----------------------------------------------------------------------------------------!!&#xA;</xsl:text>

	  <xsl:if test="@type='dynamic' and @maxoccur='unbounded' and @data_type='struct_array'">
		<xsl:text>&#9;&#9;!  ARRAY of TYPE 3 &#xA;</xsl:text>
		<xsl:text>&#9;&#9;!-----------------------------------------------------------------------------------------!&#xA;</xsl:text>

	  </xsl:if>
     <xsl:if test="(not(@type) or @type!='dynamic') and @maxoccur='unbounded' and @data_type='struct_array'">
		<xsl:text>&#9;&#9;!  ARRAY of TYPE 2  &#xA;</xsl:text>
		<xsl:text>&#9;&#9;!-----------------------------------------------------------------------------------------!&#xA;</xsl:text>

	  </xsl:if>

	       <xsl:if test="@maxoccur!='unbounded' and @data_type='struct_array'">
		<xsl:text>&#9;&#9;!  ARRAY of TYPE 1  &#xA;</xsl:text>
		<xsl:text>&#9;&#9;!-----------------------------------------------------------------------------------------!&#xA;</xsl:text>

	  </xsl:if>
    </xsl:template>


    <!-- IDS perform the tests -->
    <xsl:template match="IDS" mode="testCalls">
      <xsl:text>&#10;</xsl:text>
      <xsl:text>&#9;! --- IDS: </xsl:text><xsl:value-of select="@name"/><xsl:text> ---&#10;</xsl:text>

      <xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_put()&#10;</xsl:text>
      <xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_get()&#10;</xsl:text>
      
      <!-- Procedure put_slice should exist only for time-dependent IDSs -->

      <xsl:if test=".//field[@type='dynamic']">
       	<xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_putSlice()&#10;</xsl:text>
      </xsl:if>
      <xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_getSlice()&#10;</xsl:text>
    </xsl:template>

    <!-- IDS perform the put tests -->
    <xsl:template match="IDS" mode="testPutCalls">
      <xsl:text>&#10;</xsl:text>
      <xsl:text>&#9;! --- IDS: </xsl:text><xsl:value-of select="@name"/><xsl:text> ---&#10;</xsl:text>

      <xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_put()&#10;</xsl:text>
      <xsl:if test=".//field[@type='dynamic']">
       	<xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_putSlice()&#10;</xsl:text>
      </xsl:if>
      
    </xsl:template>

    <!-- IDS perform the get tests -->
    <xsl:template match="IDS" mode="testGetCalls">
      <xsl:text>&#10;</xsl:text>
      <xsl:text>&#9;! --- IDS: </xsl:text><xsl:value-of select="@name"/><xsl:text> ---&#10;</xsl:text>

      <xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_get()&#10;</xsl:text>
      <xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_getSlice()&#10;</xsl:text>
    </xsl:template>


    <!-- IDS perform the tests -->
    <xsl:template match="IDS" mode="all_test">
      <xsl:result-document href="src/{@name}_all_test.f90" standalone="yes" method="text">
	
	<!-- ================================ MAIN PROGRAM ================================= -->
        <xsl:text>PROGRAM </xsl:text><xsl:value-of select="@name"/><xsl:text>_test&#10;</xsl:text>
	<xsl:text>&#9;!use comparator &#10;</xsl:text>
	<xsl:text>&#9;!use ids_schemas &#10;</xsl:text>
	<xsl:text>&#9;use helper&#10;</xsl:text>
	<xsl:text>&#9;use generator&#10;</xsl:text>
        
        <xsl:text>&#9;implicit none&#10;   </xsl:text>

	<xsl:text>&#9;INTEGER :: idx,idxslice&#10;</xsl:text>
	<xsl:text>&#9;INTEGER, PARAMETER :: IDS_PATH_LEN = 30&#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: N_SEED&#10;</xsl:text>
	<xsl:text>&#9;call random_seed(SIZE=N_SEED)&#10;</xsl:text>
	<xsl:text>&#9;ALLOCATE(SEED(N_SEED))&#10;</xsl:text>
	
        <xsl:text>&#10;</xsl:text>
	
        <xsl:text>&#9;call create(idx);&#10;</xsl:text>
	<!-- <xsl:apply-templates select="child::IDS[@name='temporary']" mode="all_test"/>   -->
	<!--<xsl:apply-templates select="." mode="testCalls"/>-->
	<xsl:text>&#10;</xsl:text>
	<xsl:text>&#9;! --- IDS: </xsl:text><xsl:value-of select="@name"/><xsl:text> ---&#10;</xsl:text>
	<xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_put()&#10;</xsl:text>
	<xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_get()&#10;</xsl:text>
        <!-- Procedure put_slice should exist only for time-dependent IDSs -->
        <xsl:text>&#9;call createslice(idxslice);&#10;</xsl:text>
	<xsl:if test=".//field[@type='dynamic']">
       	  <xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_putSlice()&#10;</xsl:text>
	</xsl:if>
	<xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_getSlice()&#10;</xsl:text>
	
        <xsl:text>&#9;call close(idx);&#10;</xsl:text>
        <xsl:text>&#9;call close(idxslice);&#10;</xsl:text>

	<xsl:text>CONTAINS&#10;</xsl:text>
	<!-- sdd       <xsl:call-template name="getArrayGenerator"/> -->
	<!--      <xsl:apply-templates select="child::IDS[@name='temporary' or @name='sdn']" mode="put"/>
             <xsl:apply-templates select="child::IDS[@name='temporary' or @name='sdn']" mode="get"/>
	-->

        <xsl:apply-templates select="." mode="put"/>
        <xsl:apply-templates select="." mode="get"/>

	<!--
            <xsl:apply-templates select="child::IDS[.//field[@type='dynamic'] and @name='temporary']" mode="putSlice"/>
            <xsl:apply-templates select="child::IDS[@name='temporary']" mode="getSlice"/>
	-->
	<xsl:apply-templates select=".[.//field[@type='dynamic']]" mode="putSlice"/>
        <xsl:apply-templates select="." mode="getSlice"/>
        <xsl:text>END PROGRAM </xsl:text><xsl:value-of select="@name"/><xsl:text>_test&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
	<!-- ================================ MAIN PROGRAM (end)================================= -->
	
      </xsl:result-document>
    </xsl:template>


    <!-- IDS perform the put tests -->
    <xsl:template match="IDS" mode="put_test">
      <xsl:result-document href="src/{@name}_put_test.f90" standalone="yes" method="text">

	<!-- ================================ MAIN PROGRAM ================================= -->
        <xsl:text>PROGRAM </xsl:text><xsl:value-of select="@name"/><xsl:text>_put_test&#10;</xsl:text>
	<xsl:text>&#9;use comparator &#10;</xsl:text>
	<xsl:text>&#9;use ids_schemas &#10;</xsl:text>
	
	<xsl:text>&#9;use helper&#10;</xsl:text>
        <xsl:text>&#9;implicit none&#10;</xsl:text>
	
	<xsl:text>&#9;INTEGER :: idx, idxslice&#10;</xsl:text>
	<xsl:text>&#9;INTEGER, PARAMETER :: IDS_PATH_LEN = 30&#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: N_SEED=1&#10;</xsl:text>
	<xsl:text>&#9;call random_seed(SIZE=N_SEED)&#10;</xsl:text>
	<xsl:text>&#9;ALLOCATE(SEED(N_SEED))&#10;</xsl:text>
        
        <xsl:text>&#10;</xsl:text>
	
        <xsl:text>&#9;call open(idx)&#10;</xsl:text>
	<xsl:text>&#10;</xsl:text>
	<xsl:text>&#9;! --- IDS: </xsl:text><xsl:value-of select="@name"/><xsl:text> ---&#10;</xsl:text>
	<xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_put()&#10;</xsl:text>

	<xsl:if test=".//field[@type='dynamic']">
          <xsl:text>&#9;call openslice(idxslice)&#10;</xsl:text>
       	  <xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_putSlice()&#10;</xsl:text>
	</xsl:if>

        <xsl:text>&#9;call close(idx);&#10;</xsl:text>
        <xsl:text>&#9;call close(idxslice);&#10;</xsl:text>
      
	<!-- <xsl:apply-templates select="child::IDS[@name='temporary']" mode="all_test"/>   -->
	<!--<xsl:apply-templates select="." mode="testPutCalls"/>-->
	
	<xsl:text>CONTAINS&#10;</xsl:text>
	<!-- sdd       <xsl:call-template name="getArrayGenerator"/> -->
	<!--      <xsl:apply-templates select="child::IDS[@name='temporary' or @name='sdn']" mode="put"/>
             <xsl:apply-templates select="child::IDS[@name='temporary' or @name='sdn']" mode="get"/>
	-->
	
        <xsl:apply-templates select="." mode="put"/>
        <!--<xsl:apply-templates select="." mode="get"/>-->
	
	<!--
            <xsl:apply-templates select="child::IDS[.//field[@type='dynamic'] and @name='temporary']" mode="putSlice"/>
            <xsl:apply-templates select="child::IDS[@name='temporary']" mode="getSlice"/>
	-->

	<xsl:apply-templates select=".[.//field[@type='dynamic']]" mode="putSlice"/>
        <!--<xsl:apply-templates select="." mode="getSlice"/>-->
        <xsl:text>END PROGRAM </xsl:text><xsl:value-of select="@name"/><xsl:text>_put_test&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
	<!-- ================================ MAIN PROGRAM (end)================================= -->
	
      </xsl:result-document>
    </xsl:template>

    <!-- IDS perform the put tests -->
    <xsl:template match="IDS" mode="get_test">
      <xsl:result-document href="src/{@name}_get_test.f90" standalone="yes" method="text">

	<!-- ================================ MAIN PROGRAM ================================= -->
        <xsl:text>PROGRAM </xsl:text><xsl:value-of select="@name"/><xsl:text>_get_test&#10;</xsl:text>
	<xsl:text>&#9;use comparator &#10;</xsl:text>
	<xsl:text>&#9;use ids_schemas &#10;</xsl:text>
	
	<xsl:text>&#9;use helper&#10;</xsl:text>
        <xsl:text>&#9;implicit none&#10;</xsl:text>
	
	<xsl:text>&#9;INTEGER :: idx, idxslice&#10;</xsl:text>
	<xsl:text>&#9;INTEGER, PARAMETER :: IDS_PATH_LEN = 30&#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: N_SEED=1&#10;</xsl:text>
	<xsl:text>&#9;call random_seed(SIZE=N_SEED)&#10;</xsl:text>
	<xsl:text>&#9;ALLOCATE(SEED(N_SEED))&#10;</xsl:text>
        
        <xsl:text>&#10;</xsl:text>
	
        <xsl:text>&#9;call open(idx)&#10;</xsl:text>
	<xsl:text>&#10;</xsl:text>
	<xsl:text>&#9;! --- IDS: </xsl:text><xsl:value-of select="@name"/><xsl:text> ---&#10;</xsl:text>
	<xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_get()&#10;</xsl:text>

        <xsl:text>&#9;call openslice(idxslice)&#10;</xsl:text>
	<xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_getSlice()&#10;</xsl:text>

        <xsl:text>&#9;call close(idx);&#10;</xsl:text>
        <xsl:text>&#9;call close(idxslice);&#10;</xsl:text>

	<!-- <xsl:apply-templates select="child::IDS[@name='temporary']" mode="all_test"/>   -->
	<!-- <xsl:apply-templates select="." mode="testGetCalls"/> -->

	<xsl:text>CONTAINS&#10;</xsl:text>
	<!-- sdd       <xsl:call-template name="getArrayGenerator"/> -->
	<!--      <xsl:apply-templates select="child::IDS[@name='temporary' or @name='sdn']" mode="put"/>
             <xsl:apply-templates select="child::IDS[@name='temporary' or @name='sdn']" mode="get"/>
	-->
	
        <!--<xsl:apply-templates select="." mode="put"/>-->
        <xsl:apply-templates select="." mode="get"/>
	
	<!--
            <xsl:apply-templates select="child::IDS[.//field[@type='dynamic'] and @name='temporary']" mode="putSlice"/>
            <xsl:apply-templates select="child::IDS[@name='temporary']" mode="getSlice"/>
	-->

        <xsl:apply-templates select="." mode="getSlice"/>
        <xsl:text>END PROGRAM </xsl:text><xsl:value-of select="@name"/><xsl:text>_get_test&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
	<!-- ================================ MAIN PROGRAM (end)================================= -->
	
      </xsl:result-document>
    </xsl:template>


    <!-- IDS put()-->
    <xsl:template match="IDS" mode="put">
        <xsl:text>!==================================================================&#10;</xsl:text>
       <xsl:text>!&#9;&#9; PUT </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_put&#10;</xsl:text>
	<xsl:text>&#9;use </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_static_mod&#10;</xsl:text> 
	<xsl:text>&#9;use </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_dynamic_mod&#10;</xsl:text> 
	<xsl:text>&#9;CHARACTER (LEN = *), parameter :: idsName = "</xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
	<xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=IDS_PATH_LEN) :: idspath &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: i &#10;</xsl:text>
        <xsl:text>&#9;WRITE(*,*) "Testing put() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
        <xsl:text>&#9;!CALL srand(seed)&#10;</xsl:text>
	<xsl:text>&#9;CALL random_seed(PUT = seed)&#10;</xsl:text>
        <xsl:text>&#9;do i = 0, </xsl:text><xsl:value-of select="@maxoccur"/><xsl:text> - 1 &#10;</xsl:text>
    	<xsl:text>&#9;WRITE(*,*) "--- occurence: ", i&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_static(ids);&#10;</xsl:text> 
       	<xsl:text>&#9;&#9;&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_dynamic(ids, .FALSE., -1);&#10;</xsl:text> 
	<xsl:text>&#9;&#9;!------------&#10;</xsl:text>
	<xsl:text>&#9;&#9;if (i == 0) then &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;idspath = idsName  &#10;</xsl:text>
	<xsl:text>&#9;&#9;else&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;WRITE( occurence, '(i2)' )  i &#10;</xsl:text>
        <xsl:text>&#9;&#9;&#9;idspath = idsName//'/'//ADJUSTL(occurence)&#10;</xsl:text>
	<xsl:text>&#9;&#9;end if &#10;</xsl:text>
	<xsl:text>  &#10;</xsl:text>

	<xsl:text>&#9;&#9;call ids_put(idx, idspath, ids);&#10;</xsl:text>


	<!-- <xsl:text>&#9;call ids_deallocate(ids)&#10;</xsl:text> -->
	<xsl:text>&#9;end do &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text> <xsl:value-of select="@name"/><xsl:text>_put &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>

   <!-- IDS putSlice()-->
    <xsl:template match="IDS" mode="putSlice">
        <xsl:text>!==================================================================&#10;</xsl:text>
       <xsl:text>!&#9;&#9; PUT SLICE </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_putSlice&#10;</xsl:text>
	<xsl:text>&#9;use </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_static_mod&#10;</xsl:text> 
        <xsl:text>&#9;use </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_dynamic_mod&#10;</xsl:text> 
	<xsl:text>&#9;CHARACTER (LEN = *), parameter :: idsName = "</xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
	<xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=IDS_PATH_LEN) :: idspath &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: i, j &#10;</xsl:text>
        <xsl:text>&#9;WRITE(*,*) "Testing putSlice() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
        <xsl:text>&#9;CALL random_seed(PUT = seed)&#10;</xsl:text>
        <xsl:text>&#9;do i = 0, </xsl:text><xsl:value-of select="@maxoccur"/><xsl:text> - 1 &#10;</xsl:text>
	<xsl:text>&#9;WRITE(*,*) "--- occurence: ", i&#10;</xsl:text>
 	<xsl:text>&#9;&#9;do j = 1, noOfSlices &#10;</xsl:text>
 	<xsl:text>&#9;&#9;WRITE(*,*) "--- --- slice : ", j&#10;</xsl:text>
        <xsl:text>&#9;&#9;&#9;!------------&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;if (i == 0) then &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;&#9;idspath = idsName  &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;else&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;&#9;WRITE( occurence, '(i2)' )  i &#10;</xsl:text>
        <xsl:text>&#9;&#9;&#9;&#9;idspath = idsName//'/'//ADJUSTL(occurence)&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;end if &#10;</xsl:text>
	<xsl:text>  &#10;</xsl:text>

	<xsl:choose>
            <xsl:when test="$newLowLevel!='yes'">
            <xsl:text>&#9;&#9;&#9;if (j == 1) then &#10;</xsl:text>
		<xsl:text>&#9;&#9;&#9;! ------ PUT STATIC DATA (ONCE)   &#10;</xsl:text>
		<xsl:text>&#9;&#9;&#9;&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_static(ids);&#10;</xsl:text> 
         <xsl:text>&#9;&#9;&#9;&#9;call ids_put_non_timed(idxslice, idspath, ids);&#10;</xsl:text> 
	<xsl:text>&#9;&#9;&#9;end if &#10;</xsl:text>

		<xsl:text>&#9;&#9;&#9;! ------ PUT DYNAMIC DATA (LOOP) &#10;</xsl:text>
       		<xsl:text>&#9;&#9;&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_dynamic(ids, j);&#10;</xsl:text> 

	<xsl:text>&#9;&#9;&#9;call ids_put_slice(idxslice, idspath, ids);&#10;</xsl:text>
            </xsl:when>
	    <xsl:otherwise>
		<xsl:text>&#9;&#9;&#9;if (j == 1) then &#10;</xsl:text>
		<xsl:text>&#9;&#9;&#9;&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_static(ids);&#10;</xsl:text> 
       		<xsl:text>&#9;&#9;&#9;&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_dynamic(ids, .TRUE., j);&#10;</xsl:text> 
        	<xsl:text>&#9;&#9;&#9;&#9;call ids_put(idxslice ,idspath, ids);&#10;</xsl:text> 
		<xsl:text>&#9;&#9;&#9;else&#10;</xsl:text>
       		<xsl:text>&#9;&#9;&#9;&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_dynamic(ids, .TRUE., j);&#10;</xsl:text> 
		<xsl:text>&#9;&#9;&#9;&#9;call ids_put_slice(idxslice ,idspath, ids);&#10;</xsl:text>
		<xsl:text>&#9;&#9;&#9;end if &#10;</xsl:text>
	   </xsl:otherwise>
	</xsl:choose>

	 <xsl:text>&#9;&#9;&#9;call ids_deallocate(ids)&#10;</xsl:text>
	  <xsl:text>&#9;&#9;end do ! === SLICE ==&#10;</xsl:text>
	  <xsl:text>&#9;end do ! === OCCURENCE == &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text> <xsl:value-of select="@name"/><xsl:text>_putSlice &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>

    
    

    <!-- IDS get()-->
    <xsl:template match="IDS" mode="get">
       <xsl:text>!==================================================================&#10;</xsl:text>
       <xsl:text>!&#9;&#9; GET </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_get&#10;</xsl:text>
	<xsl:text>&#9;use </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_static_mod&#10;</xsl:text> 
        <xsl:text>&#9;use </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_dynamic_mod&#10;</xsl:text> 
	<xsl:text>&#9;CHARACTER (LEN = *), parameter :: idsName = "</xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
	<xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=IDS_PATH_LEN) :: idspath &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: i &#10;</xsl:text>
        <xsl:text>&#9;WRITE(*,*) "Testing get() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
	<xsl:text>&#9;CALL random_seed(PUT = seed)&#10;</xsl:text>
        <xsl:text>&#9;do i = 0, </xsl:text><xsl:value-of select="@maxoccur"/><xsl:text> - 1 &#10;</xsl:text>
 	<xsl:text>&#9;WRITE(*,*) "--- occurence: ", i&#10;</xsl:text>
        <xsl:text>&#9;&#9;!------------&#10;</xsl:text>
	<xsl:text>&#9;&#9;if (i == 0) then &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;idspath = idsName  &#10;</xsl:text>
	<xsl:text>&#9;&#9;else&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;WRITE( occurence, '(i2)' )  i &#10;</xsl:text>
        <xsl:text>&#9;&#9;&#9;idspath = idsName//'/'//ADJUSTL(occurence)&#10;</xsl:text>
	<xsl:text>&#9;&#9;end if &#10;</xsl:text>
	<xsl:text>  &#10;</xsl:text>

	<xsl:text>&#9;&#9;call ids_get(idx, idspath, ids);&#10;</xsl:text>
	<xsl:text>&#9;&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_static(ids)&#10;</xsl:text> 
       	<xsl:text>&#9;&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_dynamic(ids, .FALSE., -1)&#10;</xsl:text> 
		
		
		 <!-- <xsl:text>&#9;call ids_deallocate(ids)&#10;</xsl:text> -->
	  <xsl:text>&#9;end do &#10;</xsl:text>
        <xsl:text>&#9;&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_get&#10;</xsl:text>
	<xsl:text>&#10;</xsl:text>
    </xsl:template>





    <!-- IDS getSlice()-->
    <xsl:template match="IDS" mode="getSlice">
       <xsl:text>!==================================================================&#10;</xsl:text>
       <xsl:text>!&#9;&#9; GET </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_getSlice&#10;</xsl:text>
	<xsl:text>&#9;use </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_static_mod&#10;</xsl:text> 
        <xsl:text>&#9;use </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_dynamic_mod&#10;</xsl:text> 
	<xsl:text>&#9;LOGICAL :: isEqual &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN = *), parameter :: idsName = "</xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
	<xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=IDS_PATH_LEN) :: idspath &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: i, j &#10;</xsl:text>
        <xsl:text>&#9;WRITE(*,*) "Testing getSlice() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
	<xsl:text>&#9;CALL random_seed(PUT = seed)&#10;</xsl:text>
        <xsl:text>&#9;do i = 0, </xsl:text><xsl:value-of select="@maxoccur"/><xsl:text> - 1  &#10;</xsl:text>
	<xsl:text>&#9;&#9;WRITE(*,*) "---  occurence: ", i&#10;</xsl:text>
	<xsl:text>&#9;&#9;if (i == 0) then &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;idspath = idsName  &#10;</xsl:text>
	<xsl:text>&#9;&#9;else&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;WRITE( occurence, '(i2)' )  i &#10;</xsl:text>
        <xsl:text>&#9;&#9;&#9;idspath = idsName//'/'//ADJUSTL(occurence)&#10;</xsl:text>
	<xsl:text>&#9;&#9;end if &#10;</xsl:text>

	<xsl:text>&#9;&#9;do j = 1, noOfSlices &#10;</xsl:text>
	<xsl:text>&#9;WRITE(*,*) "--- --- slice : ", j&#10;</xsl:text>

	<xsl:text>&#9;&#9;&#9;call ids_get_slice(idxslice ,idspath, ids, getTimeScalar(j), 1);&#10;</xsl:text>

	<xsl:text>&#9;&#9;&#9;if (j == 1) then &#10;</xsl:text>
	<xsl:text>  &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_static(ids);&#10;</xsl:text> 
	<xsl:text>&#9;&#9;&#9;end if &#10;</xsl:text>
       	<xsl:text>&#9;&#9;&#9;&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_dynamic(ids, .TRUE., j);&#10;</xsl:text> 
  	<xsl:text>&#9;&#9;end do &#10;</xsl:text>
        <xsl:text>&#9;end do &#10;</xsl:text>
        <xsl:text>&#9;&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_getSlice&#10;</xsl:text>
	<xsl:text>&#10;</xsl:text>
    </xsl:template>


 <xsl:template match="IDS" mode="assign_non_timed">
        <xsl:text>!==================================================================&#10;</xsl:text>
       <xsl:text>!&#9;&#9; ASSIGN NON TIMED </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_assign_non_timed( ids )&#10;</xsl:text>
	<xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>), INTENT(INOUT) :: ids &#10;</xsl:text>
	<xsl:text>&#9;&#10;</xsl:text>

	<xsl:text>&#9;&#9;! =================== PUT STATIC DATA (BEGIN) ================  &#10;</xsl:text>
	<xsl:apply-templates select="field" mode="putStatic"/> 
	<xsl:text>&#9;&#9;! =================== PUT STATIC DATA (END) ================  &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text> <xsl:value-of select="@name"/><xsl:text>_assign_non_timed &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>

 <xsl:template match="IDS" mode="assign_timed">
        <xsl:text>!==================================================================&#10;</xsl:text>
       <xsl:text>!&#9;&#9; ASSIGN TIMED </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_assign_timed( ids, isSliceMode, j )&#10;</xsl:text>
	<xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>), INTENT(INOUT) :: ids &#10;</xsl:text>
	<xsl:text>&#9;LOGICAL, INTENT(IN) :: isSliceMode &#10;</xsl:text>
	<xsl:text>&#9;INTEGER, INTENT(IN) :: j &#10;</xsl:text>
	<xsl:text>&#9;&#10;</xsl:text>

	<xsl:text>&#9;&#9;! =================== PUT DYNAMIC DATA (BEGIN) ================  &#10;</xsl:text>
	 <xsl:apply-templates select="field" mode="putDynamic"/> 
	<xsl:text>&#9;&#9;! =================== PUT DYNAMIC DATA (END) ================  &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text> <xsl:value-of select="@name"/><xsl:text>_assign_timed &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>

 
  <xsl:template match="IDS" mode="get_non_timed">
        <xsl:text>!==================================================================&#10;</xsl:text>
       <xsl:text>!&#9;&#9; GET NON TIMED </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_get_non_timed( ids )&#10;</xsl:text>
	<xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>), INTENT(INOUT) :: ids &#10;</xsl:text>
	<xsl:text>&#9;LOGICAL :: isEqual &#10;</xsl:text>
	<xsl:text>&#9;&#10;</xsl:text>
	<xsl:apply-templates select="field" mode="getStatic"/> 
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text> <xsl:value-of select="@name"/><xsl:text>_get_non_timed &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>

 <xsl:template match="IDS" mode="get_timed">
        <xsl:text>!==================================================================&#10;</xsl:text>
       <xsl:text>!&#9;&#9; GET TIMED </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_get_timed( ids, isSliceMode, j )&#10;</xsl:text>
	<xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>), INTENT(INOUT) :: ids &#10;</xsl:text>
	<xsl:text>&#9;LOGICAL, INTENT(IN) :: isSliceMode&#10;</xsl:text>
	<xsl:text>&#9;INTEGER, INTENT(IN) :: j &#10;</xsl:text>
	<xsl:text>&#9;LOGICAL :: isEqual &#10;</xsl:text>
	<xsl:text>&#9;&#10;</xsl:text>
        <xsl:apply-templates select="field" mode="getDynamic"/> 
	<xsl:text>&#9;&#9;! =================== GET DYNAMIC DATA (END) ================  &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text> <xsl:value-of select="@name"/><xsl:text>_get_timed &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>
 
    <!-- ========================================================================================================================= -->
    <!-- ========================================================================================================================= -->
    <!-- ======================================================= TEMPLATES ======================================================= -->
    <!-- ========================================================================================================================= -->
    <!-- ========================================================================================================================= -->
    
    
    
    

 
  <xsl:template match="field" mode="putDynamic">



	<xsl:if test="@type ='dynamic' or (@data_type='structure' and .//field[@type='dynamic'])  or  (@data_type='struct_array' and .//field[@type='dynamic'])"> 
	      <xsl:call-template name="COMMENT_FIELD"/>
		<xsl:apply-templates select="." mode="put">
                	<xsl:with-param name="dynamicOnly" select="true()"/>
			<xsl:with-param name="staticOnly" select="false()"/>
                </xsl:apply-templates>
	</xsl:if>
    </xsl:template>


 <xsl:template match="field" mode="putStatic">

<xsl:if test="@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')"> <!-- This skips the routine for timed fields when using this template in PUT_NON_TIMED mode -->

	      <xsl:call-template name="COMMENT_FIELD"/>


		<xsl:apply-templates select="." mode="put">
                  	<xsl:with-param name="dynamicOnly" select="false()"/>
			<xsl:with-param name="staticOnly" select="true()"/>
                </xsl:apply-templates>
	</xsl:if>
    </xsl:template>
    
    
      <xsl:template match="field" mode="getDynamic">



	<xsl:if test="@type ='dynamic' or @data_type='structure' or @data_type='struct_array'"> <!-- This skips the routine for non timed fields -->
	    <!--  <xsl:call-template name="COMMENT_FIELD"/>
	-->  	<xsl:apply-templates select="." mode="get">
                	<xsl:with-param name="dynamicOnly" select="true()"/>
			<xsl:with-param name="staticOnly" select="false()"/>
                </xsl:apply-templates>
	</xsl:if>
    </xsl:template>


 <xsl:template match="field" mode="getStatic">

<xsl:if test="@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')"> <!-- This skips the routine for timed fields when using this template in PUT_NON_TIMED mode -->

	<!--      <xsl:call-template name="COMMENT_FIELD"/>
-->

		<xsl:apply-templates select="." mode="get">
                  	<xsl:with-param name="dynamicOnly" select="false()"/>
			<xsl:with-param name="staticOnly" select="true()"/>
                </xsl:apply-templates>
	</xsl:if>
    </xsl:template>
    

    <!-- field put() -->
    <xsl:template match="field[not(@data_type='structure' or @data_type='struct_array')]" mode="put">
	<xsl:param name="dynamicOnly"/>
	<xsl:param name="staticOnly"/>
	  <xsl:variable name="IDS_FIELD_PATH">  <xsl:text>&#9;&#9;ids%</xsl:text><xsl:value-of select="translate(@path, '/', '%')"/></xsl:variable>
<!--	<xsl:value-of select="@name"/><xsl:text>YYYY &#10;</xsl:text>
	-->	<xsl:if test="(not($dynamicOnly) and (@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')))
or
(not($staticOnly) and (@type ='dynamic' or @data_type='structure' or @data_type='struct_array'))"> 

	      <xsl:call-template name="COMMENT_FIELD"/>
            <xsl:call-template name="setValue">
                <xsl:with-param name="fieldPath" select="concat('ids%',translate(@path, '/', '%'))"/>
		<xsl:with-param name="slice" select="$dynamicOnly or $staticOnly"/>
            </xsl:call-template>
</xsl:if>
    </xsl:template>

  <!-- field put() -->
    <xsl:template match="field[ @data_type='struct_array']" mode="put">
	<xsl:param name="dynamicOnly"/>
	<xsl:param name="staticOnly"/>
	  <xsl:variable name="IDS_FIELD_PATH">  <xsl:text>&#9;&#9;ids%</xsl:text><xsl:value-of select="translate(@path, '/', '%')"/><xsl:text> = </xsl:text> </xsl:variable>
	      <xsl:call-template name="COMMENT_FIELD"/>

        <xsl:call-template name="putStructArray">
            <xsl:with-param name="path" select="concat(translate(@path, '/', '%'), '(1)')"/>
            <xsl:with-param name="resize" select="true()"/>
	    <xsl:with-param name="dynamicOnly" select="$dynamicOnly"/>
   	    <xsl:with-param name="staticOnly" select="$staticOnly"/>
        </xsl:call-template>

    </xsl:template>


    <xsl:template name="putStructArray">
        <xsl:param name="path"/>
        <xsl:param name="resize"/>
	<xsl:param name="dynamicOnly"/>
	<xsl:param name="staticOnly"/>

	
	<!-- This skips the routine for timed fields when using this template in staticOnly mode -->
	<xsl:if test="(not($dynamicOnly) and (@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')))
or
(not($staticOnly) and (@type ='dynamic' or @data_type='structure' or @data_type='struct_array'))"> 


        <xsl:if test="$resize">
		<xsl:text>&#9;&#9;&#9;if ( .NOT. associated(ids%</xsl:text><xsl:value-of select="substring($path, 1, string-length($path) - 3)"/><xsl:text>)) then&#10; </xsl:text>
		<xsl:text>&#9;&#9;&#9;&#9;allocate(ids%</xsl:text><xsl:value-of select="substring($path, 1, string-length($path) - 3)"/><xsl:text> (1))&#10; </xsl:text>
		<xsl:text>&#9;&#9;&#9;endif&#10; </xsl:text>
	</xsl:if>
        <xsl:for-each select="field[not(@data_type='struct_array' or @data_type='structure')]">
	<xsl:if test="(not($dynamicOnly) and (@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')))
or
  (not($staticOnly) and (@type ='dynamic' or (@data_type='structure' and .//field[@type='dynamic'])  or  (@data_type='struct_array' and .//field[@type='dynamic'])))"> 

		<xsl:call-template name="COMMENT_FIELD"/>
		
	            <xsl:call-template name="setValue">
                <xsl:with-param name="fieldPath" select="concat('ids%', $path, '%', @name)"/>
 			<xsl:with-param name="slice" select="$dynamicOnly or $staticOnly"/>
            </xsl:call-template>
		</xsl:if>
        </xsl:for-each>
        <xsl:for-each select="field[@data_type='structure']">
            <xsl:call-template name="putStructArray">
                <xsl:with-param name="path" select="concat($path, '%', @name)"/>
                <xsl:with-param name="resize" select="false()"/>
	    	<xsl:with-param name="dynamicOnly" select="$dynamicOnly"/>
   	    	<xsl:with-param name="staticOnly" select="$staticOnly"/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="field[@data_type='struct_array']">
            <xsl:call-template name="putStructArray">
                <xsl:with-param name="path" select="concat($path, '%', @name, '(1)')"/>
                <xsl:with-param name="resize" select="true()"/>
	    	<xsl:with-param name="dynamicOnly" select="$dynamicOnly"/>
   	    	<xsl:with-param name="staticOnly" select="$staticOnly"/>
            </xsl:call-template>
        </xsl:for-each>
</xsl:if>
    </xsl:template>


    <!-- field get() -->


    <xsl:template match="field[not(@data_type='structure' or @data_type='struct_array') ]" mode="get">
    <xsl:param name="dynamicOnly"/>
    <xsl:param name="staticOnly"/>
 <!--     <xsl:call-template name="COMMENT_FIELD"/>
      <xsl:text>&#9;&#9;&#9; isEqual = assertField(ids%</xsl:text><xsl:value-of select="translate(@path, '/', '%')"/><xsl:text>, </xsl:text>
      <xsl:call-template name="type2value"/>
      <xsl:text>, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>/</xsl:text><xsl:value-of select="@path"/><xsl:text>");&#10;</xsl:text>
      <xsl:text>&#9;&#9;&#9; if (.not.isEqual) STOP &#10;</xsl:text>
     --> 

   
        <xsl:if test="(not($dynamicOnly) and (@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')))
            or
             (not($staticOnly) and (@type ='dynamic' or (@data_type='structure' and .//field[@type='dynamic'])  or  (@data_type='struct_array' and .//field[@type='dynamic'])))"> 

                 <xsl:call-template name="COMMENT_FIELD"/>
            <xsl:call-template name="getValue">
                <xsl:with-param name="fieldPath" select="concat('ids%', translate(@path, '/', '%'))"/>

            </xsl:call-template>
           </xsl:if>

    </xsl:template>




    <!-- field get() for array of structures -->

    <xsl:template match="field[@data_type='struct_array']" mode="get">
      <xsl:param name="dynamicOnly"/>
      <xsl:param name="staticOnly"/>
      
      
        <xsl:if test="(not($dynamicOnly) and (@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')))
		    or
		     (not($staticOnly) and (@type ='dynamic' or (@data_type='structure' and .//field[@type='dynamic'])  or  (@data_type='struct_array' and .//field[@type='dynamic'])))"> 
		    
		    
     <!-- <xsl:call-template name="COMMENT_FIELD"/>
      
      -->
      
      <xsl:text>&#9;&#9;if(.not. associated(ids%</xsl:text>  <xsl:value-of select="translate(@path, '/', '%')" /> <xsl:text>)) then &#10;</xsl:text>
      <xsl:text>&#9;&#9;&#9; write(*,*) "ERROR! IDS: </xsl:text> <xsl:value-of select="ancestor::IDS/@name"/> <xsl:text> Field: </xsl:text> <xsl:value-of select="translate(@path, '/', '%')" /> <xsl:text> is not associated!"&#10; </xsl:text>
      <!-- <xsl:text>&#9;&#9;&#9;return &#10;</xsl:text> -->
      <xsl:text>&#9;&#9;&#9; STOP &#10;</xsl:text>
      <xsl:text>&#9;&#9;else &#10;</xsl:text>
      
      <xsl:call-template name="getStructArray">
        <xsl:with-param name="path" select="concat(translate(@path, '/', '%'), '(1)')"/>
	<xsl:with-param name="dynamicOnly" select="$dynamicOnly"/>
   	<xsl:with-param name="staticOnly" select="$staticOnly"/>
      </xsl:call-template>
      <xsl:text>&#9;&#9;end if &#10;</xsl:text>
           </xsl:if>
    </xsl:template>
    
   <!--
    
       <xsl:template match="field[@data_type='structure']" mode="get">
      <xsl:param name="dynamicOnly"/>
      <xsl:param name="staticOnly"/>
      
      
        <xsl:if test="(not($dynamicOnly) and (@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')))
		    or
		    (not($staticOnly) and (@type ='dynamic' or @data_type='structure' or @data_type='struct_array'))"> 
		    
		    

      
        <xsl:call-template name="getStructArray">
        <xsl:with-param name="path" select="translate(@path, '/', '%')"/>
	<xsl:with-param name="dynamicOnly" select="$dynamicOnly"/>
   	<xsl:with-param name="staticOnly" select="$staticOnly"/>
      </xsl:call-template>

           </xsl:if>
 </xsl:template>
-->
    <xsl:template name="getStructArray">
      <xsl:param name="path"/>
      <xsl:param name="dynamicOnly"/>
      <xsl:param name="staticOnly"/>
      
      <xsl:if test="(not($dynamicOnly) and (@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')))
		    or
		    (not($staticOnly) and (@type ='dynamic' or (@data_type='structure' and .//field[@type='dynamic'])  or  (@data_type='struct_array' and .//field[@type='dynamic'])))"> 
		    
		    <xsl:call-template name="COMMENT_FIELD"/>
	
        <xsl:for-each select="field[not(@data_type='struct_array' or @data_type='structure')]">
	  <xsl:if test="(not($dynamicOnly) and (@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')))
			or
			(not($staticOnly) and (@type ='dynamic' or @data_type='structure' or @data_type='struct_array'))"> 
	    <xsl:call-template name="COMMENT_FIELD"/>
		<!--
		<xsl:text>&#9;&#9;&#9;  isEqual =  assertField(ids%</xsl:text><xsl:value-of select="concat($path, '%', @name)"/><xsl:text>, </xsl:text>
	    	<xsl:call-template name="type2value"/>
		<xsl:text>, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>/</xsl:text><xsl:value-of select="@path"/><xsl:text>");&#10;</xsl:text>
		
		

 		<xsl:text>&#9;&#9;&#9; if (.not.isEqual) STOP &#10;</xsl:text>
 		
 		-->
 		

              <xsl:call-template name="COMMENT_FIELD"/>
            <xsl:call-template name="getValue">
                <xsl:with-param name="fieldPath" select="concat('ids%', $path, '%', @name)"/>
                <xsl:with-param name="slice" select="$dynamicOnly or $staticOnly"/>
            </xsl:call-template>

	  </xsl:if>
	 
        </xsl:for-each>


        <xsl:for-each select="field[@data_type='structure']">
	 <!-- <xsl:call-template name="COMMENT_FIELD"/>
         --> <xsl:call-template name="getStructArray">
            <xsl:with-param name="path" select="concat($path, '%', @name)"/>
	    <xsl:with-param name="dynamicOnly" select="$dynamicOnly"/>
   	    <xsl:with-param name="staticOnly" select="$staticOnly"/>
          </xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="field[@data_type='struct_array']">
	 <!-- <xsl:call-template name="COMMENT_FIELD"/>
	  -->
	  <xsl:text>&#9;&#9;if(.not. associated(ids%</xsl:text>  <xsl:value-of select="concat($path, '%', @name)" /> <xsl:text>)) then &#10;</xsl:text>
	  <xsl:text>&#9;&#9;&#9; write(*,*) "ERROR! IDS: </xsl:text>  <xsl:value-of select="ancestor::IDS/@name"/> <xsl:text> Field: </xsl:text><xsl:value-of select="concat($path, '%', @name, '(1)')" /> <xsl:text> is not associated!"&#10; </xsl:text>
	  <xsl:text>&#9;&#9;&#9; STOP &#10;</xsl:text>  
	  <xsl:text>&#9;&#9;else &#10;</xsl:text>
	  
	  <xsl:call-template name="getStructArray">
            <xsl:with-param name="path" select="concat($path, '%', @name, '(1)')"/>
	    <xsl:with-param name="dynamicOnly" select="$dynamicOnly"/>
   	    <xsl:with-param name="staticOnly" select="$staticOnly"/>
	    
          </xsl:call-template>
	  <xsl:text>&#9;&#9;end if &#10;</xsl:text>
        </xsl:for-each>
      </xsl:if>
    </xsl:template>



      <xsl:template name="setValue">
        <xsl:param name="fieldPath"/>

        <xsl:variable name="sliceMode">
                <xsl:choose>
                        <xsl:when test="@type ='dynamic' and not(ancestor::field[@data_type='struct_array' and @maxoccur='unbounded'])" >
                                <xsl:value-of select="'isSliceMode'" />
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:value-of select="'.FALSE.'" />
                        </xsl:otherwise>
                </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="@name='homogeneous_time'">
                        <xsl:text>&#9;&#9;&#9;call initHomogeneousTime( </xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> )</xsl:text>
            </xsl:when>

            <xsl:when test="@name='time' and (@data_type='flt_1d_type' or @data_type='FLT_1D')">
                          <xsl:text>&#9;&#9;&#9;call initTimeField( </xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>, isSliceMode, j)</xsl:text>
            </xsl:when>

            <xsl:when test="@data_type='str_type' or @data_type='STR_0D' or
                            @data_type='str_1d_type' or @data_type='STR_1D' or
                            @data_type='flt_type' or @data_type='FLT_0D' or
                            @data_type='flt_1d_type' or @data_type='FLT_1D'or
                            @data_type='flt_2d_type' or @data_type='FLT_2D' or
                            @data_type='FLT_3D'or  @data_type='FLT_4D'or  @data_type='FLT_5D' or @data_type='FLT_6D' or
                            @data_type='int_type' or @data_type='INT_0D' or 
                            @data_type='int_1d_type' or @data_type='INT_1D' or 
                            @data_type='INT_2D' or @data_type='INT_3D' or @data_type='INT_4D'">
                      <xsl:text>&#9;&#9;&#9;call initField(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>, </xsl:text><xsl:value-of select="$sliceMode"/><xsl:text> ) &#10;</xsl:text>

            </xsl:when>

            <xsl:otherwise>
                <xsl:message terminate='no'> ERROR! Unknown type: <xsl:value-of select="@data_type"/>  (<xsl:value-of select="ancestor::IDS/@name"/>:  <xsl:value-of select="@path" />)</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

<xsl:text>&#9;&#10;</xsl:text>

    </xsl:template>
    
    
    
          <xsl:template name="getValue">
        <xsl:param name="fieldPath"/>
        <xsl:variable name="sliceMode">
                <xsl:choose>
                        <xsl:when test="@type ='dynamic' and not(ancestor::field[@data_type='struct_array' and @maxoccur='unbounded'])" >
                                <xsl:value-of select="'isSliceMode'" />
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:value-of select="'.FALSE.'" />
                        </xsl:otherwise>
                </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="@name='homogeneous_time'">
                                           <xsl:text>&#9;&#9;&#9;isEqual = assertHomogeneousTimeField(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>, </xsl:text><xsl:value-of select="$sliceMode"/><xsl:text>, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>:</xsl:text><xsl:value-of select="@path"/><xsl:text>")&#10;</xsl:text>
            </xsl:when>

            <xsl:when test="@name='time' and (@data_type='flt_1d_type' or @data_type='FLT_1D')">
                              <xsl:text>&#9;&#9;&#9;isEqual = assertTimeField(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>, </xsl:text><xsl:value-of select="$sliceMode"/><xsl:text>, j, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>:</xsl:text><xsl:value-of select="@path"/><xsl:text>")&#10;</xsl:text>
            </xsl:when>

            <xsl:when test="@data_type='str_type' or @data_type='STR_0D' or
                            @data_type='str_1d_type' or @data_type='STR_1D' or
                            @data_type='flt_type' or @data_type='FLT_0D' or
                            @data_type='flt_1d_type' or @data_type='FLT_1D'or
                            @data_type='flt_2d_type' or @data_type='FLT_2D' or
                            @data_type='FLT_3D'or  @data_type='FLT_4D'or  @data_type='FLT_5D' or @data_type='FLT_6D' or
                            @data_type='int_type' or @data_type='INT_0D' or 
                            @data_type='int_1d_type' or @data_type='INT_1D' or 
                            @data_type='INT_2D' or @data_type='INT_3D' or @data_type='INT_4D'">
                      <xsl:text>&#9;&#9;&#9;isEqual = assertField(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>, </xsl:text><xsl:value-of select="$sliceMode"/><xsl:text>, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>:</xsl:text><xsl:value-of select="@path"/><xsl:text>")&#10;</xsl:text>


                <xsl:text>&#9;&#9;&#9; if (.not.isEqual) STOP &#10;</xsl:text>
            </xsl:when>

            <xsl:otherwise>
                <xsl:message terminate='no'> ERROR! Unknown type: <xsl:value-of select="@data_type"/>  (<xsl:value-of select="ancestor::IDS/@name"/>:  <xsl:value-of select="@path" />)</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

<xsl:text>&#9;&#10;</xsl:text>

    </xsl:template>
 
</xsl:stylesheet>
