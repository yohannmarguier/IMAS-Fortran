 <xsl:stylesheet version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:fn="http://www.w3.org/2005/xpath-functions"
        xmlns:xs="http://www.w3.org/2001/XMLSchema"
        xmlns:local="http://www.example.com/functions/local" 
        exclude-result-prefixes="local xs">
    <xsl:output method="text"/>
    <xsl:strip-space elements="*"/>

    <xsl:param name="newLowLevel" select="'no'" />


<xsl:function name="local:unique_name" as="xs:string">
  <!-- Provides pseudo-unique 16 characters reference to arbitrary long field name  -->
    <xsl:param name="FullName" as="xs:string"/>
    <xsl:choose>
        <xsl:when test="string-length($FullName) &lt; 51">
            <xsl:value-of select="$FullName"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="concat(lower-case(substring($FullName,1,50)), sum(string-to-codepoints(lower-case(substring($FullName,51)))))"/>
        </xsl:otherwise>
    </xsl:choose>

</xsl:function>

    <!-- Initial code -->
    <xsl:template match="IDSs">





  <xsl:apply-templates select="child::IDS" mode="init"/>
      <xsl:apply-templates select="child::IDS" mode="test"/>
     <xsl:apply-templates select="child::IDS" mode="all_test"/>


    </xsl:template>

 <!-- ============================= END OF GENERATED FILE ============================== -->
<xsl:template match="IDS" mode="print_stru">
  <xsl:result-document href="src/A_{@name}_stru.f90">

        <xsl:apply-templates select="descendant::field[(@data_type='struct_array' or @data_type='structure') and (not(n) or @structure_reference='self')]" mode="print_stru"/> 

     
  </xsl:result-document>
</xsl:template>
 
 <xsl:template match="field" mode="print_stru">
<xsl:value-of select="ancestor::IDS/@name"/><xsl:text>&#10;</xsl:text>
            <xsl:value-of select="@structure_reference"/><xsl:text>&#10;</xsl:text>
<xsl:call-template name="COMMENT_FIELD"/>
 
         
</xsl:template>


 <xsl:template match="utilities" mode="init_static">
  <xsl:result-document href="src/utilities_init.f90">

        <xsl:text>module utilities_init_mod&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text>
        <xsl:text>    use ids_schemas, only: ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>&#10;</xsl:text>
         <xsl:text>    use setter&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>    implicit none&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>contains</xsl:text>
        <xsl:text>&#xA;</xsl:text>

         <xsl:apply-templates select="field"  mode="xx"/>

        <xsl:text>&#10;</xsl:text>
        <xsl:text>END MODULE utilities_init_mod&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
  </xsl:result-document>
</xsl:template>


 <xsl:template match="field" mode="xx">
        <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>!         INIT  DATA: </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
        <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>SUBROUTINE init_utility_</xsl:text><xsl:value-of select="@name"/><xsl:text>( idsNode, setStatic, setDynamic, idsTimeMode, isSliceMode, sliceIdx)&#10;</xsl:text>
        <xsl:text>    TYPE (</xsl:text><xsl:value-of select="@name"/><xsl:text>), INTENT(INOUT) :: idsNode &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: setStatic &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: setDynamic &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: idsTimeMode &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: isSliceMode &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: sliceIdx &#10;</xsl:text>

        <xsl:text>&#10;</xsl:text>

        <!--<xsl:apply-templates select="field" mode="putStatic"/> 
-->
        <xsl:apply-templates select="field" mode="putStatic"/> 

        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE init_utility_</xsl:text> <xsl:value-of select="@name"/><xsl:text>&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
         
</xsl:template>

    <xsl:template match="field[@data_type='structure' or @data_type='struct_array']" mode="define_init_sbrt">
        <xsl:text>!===========================================================================================&#10;</xsl:text>
        <xsl:text>!         INIT : </xsl:text><xsl:value-of select="@name"/>::<xsl:value-of select="@path"/>    [<xsl:value-of select="@data_type"/>:<xsl:value-of select="@type"/>:<xsl:value-of select="@maxoccur"/><xsl:text>]&#xA;</xsl:text>
        <xsl:text>!===========================================================================================&#10;</xsl:text>
        <xsl:text>SUBROUTINE init_</xsl:text><xsl:value-of select="local:unique_name(translate(@path, '/', '_'))" /><xsl:text>( idsNode, setStatic, setDynamic, idsTimeMode, isSliceMode, sliceIdx)&#10;</xsl:text>
        <xsl:text>    TYPE (ids_</xsl:text><xsl:value-of select="@structure_reference"/><xsl:text>), INTENT(INOUT) :: idsNode &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: setStatic &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: setDynamic &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: idsTimeMode &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: isSliceMode &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: sliceIdx &#10;</xsl:text>
    	<xsl:text>    INTEGER  :: aosSize &#10;</xsl:text>
		<xsl:text>    INTEGER  :: i &#10;</xsl:text>



        <xsl:text>&#10;</xsl:text>


       <xsl:apply-templates select="field" mode="put"/> 
 
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE init_</xsl:text><xsl:value-of select="local:unique_name(translate(@path, '/', '_'))" /><xsl:text>&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
</xsl:template>


 <xsl:template match="field" mode="comm">

          <xsl:call-template name="COMMENT_FIELD"/>
<xsl:value-of select="@structure_reference"/><xsl:text>&#10;</xsl:text>
         
</xsl:template>



 <!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- INIT ALL IDS DATA                                                        -->
<!--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="IDS" mode="init">
  <xsl:result-document href="src/{@name}_init.f90">
        <xsl:text>module </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_mod&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text>
        <xsl:text>    use ids_schemas_</xsl:text><xsl:value-of select="@name"/><xsl:text>&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_put_struct&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_put_slice_struct&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_get_struct&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_get_slice_struct&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_delete&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_copy_struct&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_deallocate_struct&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_validate_struct&#10;</xsl:text>
        <xsl:text>    !use generator&#10;</xsl:text>
         <xsl:text>    use setter&#10;</xsl:text>
         <xsl:text>    use helper&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>    implicit none&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>contains</xsl:text>
        <xsl:text>&#xA;</xsl:text>

      

        <xsl:apply-templates select="descendant-or-self::field" mode="define_init_sbrt"/> 


        <xsl:text>!===========================================================================================&#10;</xsl:text>
        <xsl:text>!         INIT IDS: </xsl:text><xsl:value-of select="@name"/><xsl:text> &#10;</xsl:text>
        <xsl:text>!===========================================================================================&#10;</xsl:text>
        <xsl:text>SUBROUTINE init_IDS_</xsl:text><xsl:value-of select="@name" /><xsl:text>( idsNode, setStatic, setDynamic, idsTimeMode, isSliceMode, sliceIdx )&#10;</xsl:text>
        <xsl:text>    TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>), INTENT(INOUT) :: idsNode &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: setStatic &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: setDynamic &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: idsTimeMode &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: isSliceMode &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: sliceIdx &#10;</xsl:text>
    	<xsl:text>    INTEGER  :: aosSize &#10;</xsl:text>
		<xsl:text>    INTEGER  :: i &#10;</xsl:text>

        <xsl:text>&#10;</xsl:text>
<!--
        <xsl:text>            IF (idsTimeMode == IDS_TIME_MODE_INDEPENDENT) RETURN&#10;</xsl:text>
   -->  <xsl:apply-templates select="field" mode="put"/> 
 
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE init_IDS_</xsl:text><xsl:value-of select="@name" /><xsl:text>&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>

        <xsl:text>&#10;</xsl:text>
        <xsl:text>END MODULE </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_mod&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
  </xsl:result-document>
</xsl:template>



 <!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS TEST                                              -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->

    <xsl:template match="field[@data_type='structure' or @data_type='struct_array']" mode="define_test_sbrt">
        <xsl:text>!===========================================================================================&#10;</xsl:text>
        <xsl:text>!         TEST : </xsl:text><xsl:value-of select="@name"/>::<xsl:value-of select="@path"/>    [<xsl:value-of select="@data_type"/>:<xsl:value-of select="@type"/>:<xsl:value-of select="@maxoccur"/><xsl:text>]&#xA;</xsl:text>
        <xsl:text>!===========================================================================================&#10;</xsl:text>
        <xsl:text>SUBROUTINE test_</xsl:text><xsl:value-of select="local:unique_name(translate(@path, '/', '_'))" /><xsl:text>(  idsNode, setStatic, setDynamic, idsTimeMode, isSliceMode, sliceIdx)&#10;</xsl:text>
        <xsl:text>    TYPE (ids_</xsl:text><xsl:value-of select="@structure_reference"/><xsl:text>), INTENT(INOUT) :: idsNode &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: setStatic &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: setDynamic &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: idsTimeMode &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: isSliceMode &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: sliceIdx &#10;</xsl:text>
    	<xsl:text>    INTEGER  :: aosSize &#10;</xsl:text>
		<xsl:text>    INTEGER  :: i &#10;</xsl:text>
        <xsl:text>    LOGICAL :: isEqual &#10;</xsl:text>


        <xsl:text>&#10;</xsl:text>


       <xsl:apply-templates select="field" mode="get"/> 
 
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE test_</xsl:text><xsl:value-of select="local:unique_name(translate(@path, '/', '_'))" /><xsl:text>&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
         
</xsl:template>

<xsl:template match="IDS" mode="test">
  <xsl:result-document href="src/{@name}_test.f90">
        <xsl:text>module </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_mod&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text>
        <xsl:text>    use generator&#10;</xsl:text>
        <xsl:text>    use comparator &#10;</xsl:text>
        <xsl:text>    use ids_schemas_</xsl:text><xsl:value-of select="@name"/><xsl:text>&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_put_struct&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_put_slice_struct&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_get_struct&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_get_slice_struct&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_delete&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_copy_struct&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_deallocate_struct&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_validate_struct&#10;</xsl:text>
         <xsl:text>    use helper&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>    implicit none&#10;</xsl:text>
        <xsl:text>&#xA;</xsl:text> 
        <xsl:text>contains</xsl:text>
        <xsl:text>&#xA;</xsl:text>

        <xsl:apply-templates select="descendant-or-self::field" mode="define_test_sbrt"/> 
        <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>!         TEST IDS DATA: </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
        <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>SUBROUTINE test_ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>(  idsNode, setStatic, setDynamic, idsTimeMode, isSliceMode, sliceIdx)&#10;</xsl:text>
        <xsl:text>    TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>), INTENT(INOUT) :: idsNode &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: setStatic &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: setDynamic &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: idsTimeMode &#10;</xsl:text>
        <xsl:text>    LOGICAL, INTENT(IN) :: isSliceMode &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: sliceIdx &#10;</xsl:text>
    	<xsl:text>    INTEGER  :: aosSize &#10;</xsl:text>
		<xsl:text>    INTEGER  :: i &#10;</xsl:text>
        <xsl:text>    LOGICAL :: isEqual &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>

        <xsl:text>&#10;</xsl:text>
        <xsl:apply-templates select="field" mode="get"/> 

        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE test_ids_</xsl:text> <xsl:value-of select="@name"/><xsl:text>&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END MODULE </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_mod&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
  </xsl:result-document>
</xsl:template>
 
 <!-- ============================= TEMPLATES ============================== -->

        <!--Documentation for a single field-->
      <!--Documentation for a single field-->
    <xsl:template name = "COMMENT_FIELD">
        <xsl:text>&#xA;</xsl:text>
	<xsl:text>        !!-----------------------------------------------------------------------------------------!!&#xA;</xsl:text>
	<xsl:text>        !!  </xsl:text><xsl:value-of select="@name"/>:<xsl:value-of select="@path"/>:<xsl:value-of select="@data_type"/>:<xsl:value-of select="@type"/>:<xsl:text>&#xA;</xsl:text>
	<xsl:text>        !!-----------------------------------------------------------------------------------------!!&#xA;</xsl:text>

	  <xsl:if test="@type='dynamic' and @maxoccur='unbounded' and @data_type='struct_array'">
		<xsl:text>        !  ARRAY of TYPE 3 &#xA;</xsl:text>
		<xsl:text>        !-----------------------------------------------------------------------------------------!&#xA;</xsl:text>

	  </xsl:if>
     <xsl:if test="(not(@type) or @type!='dynamic') and @maxoccur='unbounded' and @data_type='struct_array'">
		<xsl:text>        !  ARRAY of TYPE 2  &#xA;</xsl:text>
		<xsl:text>        !-----------------------------------------------------------------------------------------!&#xA;</xsl:text>

	  </xsl:if>

	       <xsl:if test="@maxoccur!='unbounded' and @data_type='struct_array'">
		<xsl:text>        !  ARRAY of TYPE 1  &#xA;</xsl:text>
		<xsl:text>        !-----------------------------------------------------------------------------------------!&#xA;</xsl:text>

	  </xsl:if>
    </xsl:template>


    <!-- IDS perform the tests -->
    <xsl:template match="IDS" mode="all_test">
      <xsl:result-document href="src/{@name}_test_routines.f90" standalone="yes" method="text">
	
    <!-- ================================ MODULE TEST SUBROUTINES ================================= -->
    <xsl:text>MODULE </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_routines&#10;</xsl:text>
    <xsl:text>    use helper &#10;</xsl:text>
    <xsl:text>    use ids_schemas_</xsl:text><xsl:value-of select="@name"/><xsl:text>&#10;</xsl:text>
    <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_put_struct&#10;</xsl:text>
    <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_put_slice_struct&#10;</xsl:text>
    <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_get_struct&#10;</xsl:text>
    <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_get_slice_struct&#10;</xsl:text>
    <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_delete&#10;</xsl:text>
    <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_copy_struct&#10;</xsl:text>
    <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_deallocate_struct&#10;</xsl:text>
    <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_validate_struct&#10;</xsl:text>
    <xsl:text>&#xA;</xsl:text> 
    <xsl:text>    IMPLICIT NONE&#10;</xsl:text>
    <xsl:text>&#xA;</xsl:text> 
    <xsl:text>    INTEGER, PARAMETER :: IDS_PATH_LEN = 30&#10;</xsl:text>
    <xsl:text>    CHARACTER (LEN = *), PARAMETER :: IDS_NAME = "</xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
    <xsl:text>    INTEGER, PARAMETER :: MAX_OCCURENCES = </xsl:text><xsl:value-of select="@maxoccur"/><xsl:text>&#10;</xsl:text>
    <xsl:text>CONTAINS&#10;</xsl:text>

        <xsl:apply-templates select="." mode="put"/>
        <xsl:apply-templates select="." mode="get"/>

    <xsl:if test="not(@type='constant')">
        <xsl:apply-templates select=".[.//field[@type='dynamic']]" mode="putSlice"/>
        <xsl:apply-templates select="." mode="getSlice"/>
    </xsl:if>

        <xsl:apply-templates select="." mode="validate"/>


    <xsl:text>END MODULE </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_routines&#10;</xsl:text>
      </xsl:result-document>

	<!-- ================================ MAIN PROGRAM ================================= -->
      <xsl:result-document href="src/{@name}_all_tests.f90" standalone="yes" method="text">
    <xsl:text>!==================================================================&#10;</xsl:text>
    <xsl:text>!                MAIN PROGRAM   &#10;</xsl:text>
    <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>PROGRAM </xsl:text><xsl:value-of select="@name"/><xsl:text>_test&#10;</xsl:text>
	<xsl:text>    use helper&#10;</xsl:text>
        <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_routines&#10;</xsl:text>
        <xsl:text>    implicit none&#10;   </xsl:text>
    <xsl:text>    INTEGER :: i, sliceIdx&#10;</xsl:text>
	<xsl:text>    INTEGER :: idx&#10;</xsl:text>
    <xsl:text>    INTEGER :: backendID = NO_BACKEND&#10;</xsl:text>
    <xsl:text>    INTEGER :: idsTimeMode = IDS_TIME_MODE_HOMOGENEOUS&#10;</xsl:text>
    <xsl:text>    INTEGER :: testMode = TEST_MODE_ALL&#10;</xsl:text>
    <xsl:text>    LOGICAL :: useExistingPulseFile&#10;</xsl:text>

	<xsl:text>    INTEGER :: N_SEED&#10;</xsl:text>
	<xsl:text>    call random_seed(SIZE=N_SEED)&#10;</xsl:text>
	<xsl:text>    ALLOCATE(SEED(N_SEED))&#10;</xsl:text>
	
    <xsl:text>&#10;</xsl:text>
    <xsl:text>    CALL initEnv()&#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>            testMode = config%testMode&#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>    DO i = 1, SIZE(config%backendIDArray)&#10;</xsl:text>
    <xsl:text>        backendID = config%backendIDArray(i)&#10;</xsl:text>
    <xsl:text>        IF (backendID == NO_BACKEND) CYCLE&#10;</xsl:text>
    <xsl:text>        WRITE(*,*) "=== BACKEND : ", backend2str(backendID), "=== === === === === === === ==="&#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>        call create_db(backendID, TEST_PULSE, TEST_RUN, idx);&#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
    <xsl:choose>
      <xsl:when test="@type='constant'">
    <xsl:text>            idsTimeMode = IDS_TIME_MODE_INDEPENDENT ! Test only the constant mode for constant IDSs &#10;</xsl:text>
    <xsl:text>            IF (idsTimeMode == IDS_TIME_MODE_UNKNOWN) CYCLE&#10;</xsl:text>
    <xsl:text>            WRITE(*,*) "--- --- TIME MODE ", timeMode2str(idsTimeMode), "--- --- --- --- --- ---" &#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
	<xsl:text>            ! --- IDS: </xsl:text><xsl:value-of select="@name"/><xsl:text> ---&#10;</xsl:text>
    <xsl:text>            IF (testMode == TEST_MODE_ALL .OR. testMode == TEST_MODE_GLOBAL) THEN&#10;</xsl:text>
	<xsl:text>                call </xsl:text><xsl:value-of select="@name"/><xsl:text>_put(idx, idsTimeMode, config%occToTest)&#10;</xsl:text>
	<xsl:text>                call </xsl:text><xsl:value-of select="@name"/><xsl:text>_get(idx, idsTimeMode, config%occToTest)&#10;</xsl:text>
    <xsl:text>            END IF&#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
      </xsl:when>
      <xsl:otherwise>

    <xsl:text>        DO sliceIdx = 1, SIZE(config%idsTimeModeArray)&#10;</xsl:text>
    <xsl:text>            idsTimeMode = config%idsTimeModeArray(sliceIdx)&#10;</xsl:text>
    <xsl:text>            IF (idsTimeMode == IDS_TIME_MODE_UNKNOWN) CYCLE&#10;</xsl:text>
    <xsl:text>            WRITE(*,*) "--- --- TIME MODE ", timeMode2str(idsTimeMode), "--- --- --- --- --- ---" &#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
	<xsl:text>            ! --- IDS: </xsl:text><xsl:value-of select="@name"/><xsl:text> ---&#10;</xsl:text>
    <xsl:text>            IF (testMode == TEST_MODE_ALL .OR. testMode == TEST_MODE_GLOBAL) THEN&#10;</xsl:text>
	<xsl:text>                call </xsl:text><xsl:value-of select="@name"/><xsl:text>_put(idx, idsTimeMode, config%occToTest)&#10;</xsl:text>
	<xsl:text>                call </xsl:text><xsl:value-of select="@name"/><xsl:text>_get(idx, idsTimeMode, config%occToTest)&#10;</xsl:text>
    <xsl:text>            END IF&#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>

    <xsl:text>            IF (backendID /= ASCII_BACKEND .AND. idsTimeMode /= IDS_TIME_MODE_INDEPENDENT .AND. (testMode == TEST_MODE_ALL .OR. testMode == TEST_MODE_SLICE)) THEN&#10;</xsl:text>
    <xsl:text>                call </xsl:text><xsl:value-of select="@name"/><xsl:text>_putSlice(idx, idsTimeMode, config%occToTest, config%timeSize)&#10;</xsl:text>
	<xsl:text>                call </xsl:text><xsl:value-of select="@name"/><xsl:text>_getSlice(idx, idsTimeMode, config%occToTest, config%timeSize)&#10;</xsl:text>
   <xsl:text>            END IF&#10;</xsl:text>
    <xsl:text>        END DO  ! time mode  &#10;</xsl:text>
      </xsl:otherwise>
   </xsl:choose>

    <xsl:text>&#10;</xsl:text>
    <xsl:text>        </xsl:text>call <xsl:value-of select="@name"/>_validation_tests()<xsl:text>&#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>        call close_db(idx);&#10;</xsl:text>
    <xsl:text>    END DO  ! backend  &#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
        <xsl:text>END PROGRAM </xsl:text><xsl:value-of select="@name"/><xsl:text>_test&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
	<!-- ================================ MAIN PROGRAM (end)================================= -->
	
      </xsl:result-document>
    </xsl:template>

    <!-- IDS validate() -->
    <xsl:template match="IDS" mode="validate">
    <xsl:text>!==================================================================&#10;</xsl:text>
    <xsl:text>!         VALIDATE </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
    <xsl:text>!==================================================================&#10;</xsl:text>
    <xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_validation_tests()&#10;</xsl:text>

    <xsl:text>    IMPLICIT NONE&#10;</xsl:text> 
    <xsl:text>    TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
    <xsl:text>    CHARACTER(:) , ALLOCATABLE:: err_msg&#10;</xsl:text>
    <xsl:text>    INTEGER         :: status &#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>    write(*,*) "--- </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>    write(*,*) "--- Testing empty ids"&#10;</xsl:text>
    <xsl:text>    call ids_validate(ids, status, err_msg) &#10;</xsl:text>
    <xsl:text>    if (status.ne.-1 .and. trim(err_msg) .ne. "ids_properties.homogeneous_time wrong value") STOP "Testing empty ids error" &#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
<xsl:if test="not(@type='constant')">
    <xsl:text>    write(*,*) "--- Testing time mode"&#10;</xsl:text>
    <xsl:text>    ids%ids_properties%homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS&#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
	<xsl:text>    call ids_validate(ids, status, err_msg) &#10;</xsl:text>
    <xsl:text>    if (status.ne.-1 .and. trim(err_msg) .ne. "the time array must be associated") STOP "Testing time mode error" &#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
</xsl:if> 
   <xsl:text>END SUBROUTINE </xsl:text> <xsl:value-of select="@name"/><xsl:text>_validation_tests &#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
    </xsl:template>

    <!-- IDS put()-->
    <xsl:template match="IDS" mode="put">
        <xsl:text>!==================================================================&#10;</xsl:text>
       <xsl:text>!         PUT </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_put( pulseCtx, idsTimeMode, numOccurrences )&#10;</xsl:text>
    <xsl:text>    use helper&#10;</xsl:text> 
	<xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_mod&#10;</xsl:text> 
    <xsl:text>    INTEGER, INTENT(IN) :: pulseCtx &#10;</xsl:text>
    <xsl:text>    INTEGER, INTENT(IN) :: idsTimeMode &#10;</xsl:text>
    <xsl:text>    INTEGER, INTENT(IN) :: numOccurrences &#10;</xsl:text>
	<xsl:text>    TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
	<xsl:text>    CHARACTER (LEN=IDS_PATH_LEN) :: idspath &#10;</xsl:text>
	<xsl:text>    CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>    INTEGER :: i &#10;</xsl:text>
    <xsl:text>    LOGICAL :: setDynamicFields &#10;</xsl:text>
        <xsl:text>    WRITE(*,*) "--- --- --- Testing put() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
        <xsl:text>    !CALL srand(seed)&#10;</xsl:text>
	<xsl:text>    CALL random_seed(PUT = seed)&#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>    if (idsTimeMode == IDS_TIME_MODE_INDEPENDENT) then &#10;</xsl:text>
    <xsl:text>        setDynamicFields = .FALSE.&#10;</xsl:text>
    <xsl:text>    else&#10;</xsl:text>
    <xsl:text>        setDynamicFields = .TRUE.&#10;</xsl:text>
    <xsl:text>    end if &#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
        <xsl:text>    do i = 0, MIN(MAX_OCCURENCES, numOccurrences) - 1 &#10;</xsl:text>
    	<xsl:text>    WRITE(*,*) "--- --- --- --- occurence: ", i&#10;</xsl:text>
	<xsl:text>            call  init_ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>(ids, .TRUE., setDynamicFields, idsTimeMode,  .FALSE., -1);&#10;</xsl:text> 
	<xsl:text>        !------------&#10;</xsl:text>
	<xsl:text>        if (i == 0) then &#10;</xsl:text>
	<xsl:text>            idspath = IDS_NAME  &#10;</xsl:text>
	<xsl:text>        else&#10;</xsl:text>
	<xsl:text>            WRITE( occurence, '(i2)' )  i &#10;</xsl:text>
        <xsl:text>            idspath = IDS_NAME//'/'//ADJUSTL(occurence)&#10;</xsl:text>
	<xsl:text>        end if &#10;</xsl:text>
	<xsl:text>  &#10;</xsl:text>

	<xsl:text>        call ids_put(pulseCtx, idspath, ids);&#10;</xsl:text>


	<xsl:text>        call ids_deallocate(ids)&#10;</xsl:text>
	<xsl:text>    end do &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text> <xsl:value-of select="@name"/><xsl:text>_put &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>

   <!-- IDS putSlice()-->
    <xsl:template match="IDS" mode="putSlice">
    <xsl:if test="not(@type='constant')">
 
       <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>!         PUT SLICE </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
        <xsl:text>!==================================================================&#10;</xsl:text>
        <xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_putSlice( pulseCtx, idsTimeMode, numOccurrences, numSlices  )&#10;</xsl:text>
	    <xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_init_mod&#10;</xsl:text> 
        <xsl:text>    INTEGER, INTENT(IN) :: pulseCtx &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: idsTimeMode &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: numOccurrences &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: numSlices &#10;</xsl:text>


	<xsl:text>    TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
	<xsl:text>    CHARACTER (LEN=IDS_PATH_LEN) :: idspath &#10;</xsl:text>
	<xsl:text>    CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>    INTEGER :: i, sliceIdx &#10;</xsl:text>
        <xsl:text>    WRITE(*,*) "--- --- --- Testing putSlice() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
        <xsl:text>    CALL random_seed(PUT = seed)&#10;</xsl:text>

        <xsl:text>    do i = 0, MIN(MAX_OCCURENCES, numOccurrences) - 1 &#10;</xsl:text>
	<xsl:text>        WRITE(*,*) "--- --- --- --- occurence: ", i&#10;</xsl:text>
 	<xsl:text>        do sliceIdx = 1, numSlices &#10;</xsl:text>
 	<xsl:text>            WRITE(*,*) "--- --- --- --- --- slice : ", sliceIdx&#10;</xsl:text>
    <xsl:text>            !------------&#10;</xsl:text>
	<xsl:text>            if (i == 0) then &#10;</xsl:text>
	<xsl:text>                idspath = IDS_NAME  &#10;</xsl:text>
	<xsl:text>            else&#10;</xsl:text>
	<xsl:text>                WRITE( occurence, '(i2)' )  i &#10;</xsl:text>
    <xsl:text>                idspath = IDS_NAME//'/'//ADJUSTL(occurence)&#10;</xsl:text>
	<xsl:text>            end if &#10;</xsl:text>
	<xsl:text>&#10;</xsl:text>


		<xsl:text>            if (sliceIdx == 1) then &#10;</xsl:text>
        <xsl:text>                call  init_ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>(ids, .TRUE., .TRUE., idsTimeMode,   .TRUE., sliceIdx);&#10;</xsl:text> 
        	<xsl:text>                call ids_put(pulseCtx ,idspath, ids);&#10;</xsl:text> 
		<xsl:text>            else&#10;</xsl:text>
        <xsl:text>            call  init_ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>(ids, .FALSE., .TRUE., idsTimeMode,   .TRUE., sliceIdx);&#10;</xsl:text> 
		<xsl:text>                call ids_put_slice(pulseCtx ,idspath, ids);&#10;</xsl:text>
		<xsl:text>            end if &#10;</xsl:text>

	 <xsl:text>            call ids_deallocate(ids)&#10;</xsl:text>
	  <xsl:text>        end do ! === SLICE ==&#10;</xsl:text>
	  <xsl:text>    end do ! === OCCURENCE == &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text> <xsl:value-of select="@name"/><xsl:text>_putSlice &#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
    </xsl:if>
    </xsl:template>

    
    

    <!-- IDS get()-->
    <xsl:template match="IDS" mode="get">
       <xsl:text>!==================================================================&#10;</xsl:text>
       <xsl:text>!         GET </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_get( pulseCtx, idsTimeMode, numOccurrences )&#10;</xsl:text>
	<xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_mod&#10;</xsl:text> 
    <xsl:text>    INTEGER, INTENT(IN) :: pulseCtx &#10;</xsl:text>
    <xsl:text>    INTEGER, INTENT(IN) :: idsTimeMode &#10;</xsl:text>
    <xsl:text>    INTEGER, INTENT(IN) :: numOccurrences &#10;</xsl:text>
	<xsl:text>    TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
	<xsl:text>    CHARACTER (LEN=IDS_PATH_LEN) :: idspath &#10;</xsl:text>
	<xsl:text>    CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>    INTEGER :: i &#10;</xsl:text>
    <xsl:text>    LOGICAL :: setDynamicFields &#10;</xsl:text>
        <xsl:text>    WRITE(*,*) "--- --- --- Testing get() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
	<xsl:text>    CALL random_seed(PUT = seed)&#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>    if (idsTimeMode == IDS_TIME_MODE_INDEPENDENT) then &#10;</xsl:text>
    <xsl:text>        setDynamicFields = .FALSE.&#10;</xsl:text>
    <xsl:text>    else&#10;</xsl:text>
    <xsl:text>        setDynamicFields = .TRUE.&#10;</xsl:text>
    <xsl:text>    end if &#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
        <xsl:text>    do i = 0, MIN(MAX_OCCURENCES, numOccurrences) - 1 &#10;</xsl:text>
 	<xsl:text>    WRITE(*,*) "--- --- --- --- occurence: ", i&#10;</xsl:text>
        <xsl:text>        !------------&#10;</xsl:text>
	<xsl:text>        if (i == 0) then &#10;</xsl:text>
	<xsl:text>            idspath = IDS_NAME  &#10;</xsl:text>
	<xsl:text>        else&#10;</xsl:text>
	<xsl:text>            WRITE( occurence, '(i2)' )  i &#10;</xsl:text>
        <xsl:text>            idspath = IDS_NAME//'/'//ADJUSTL(occurence)&#10;</xsl:text>
	<xsl:text>        end if &#10;</xsl:text>
	<xsl:text>  &#10;</xsl:text>

	<xsl:text>        call ids_get(pulseCtx, idspath, ids);&#10;</xsl:text>
	<xsl:text>        call test_ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>(ids, .TRUE., setDynamicFields, idsTimeMode, .FALSE., -1)&#10;</xsl:text> 
		
	<xsl:text>        call ids_deallocate(ids)&#10;</xsl:text>
	<xsl:text>    end do &#10;</xsl:text>
        <xsl:text>    &#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_get&#10;</xsl:text>
	<xsl:text>&#10;</xsl:text>
    </xsl:template>





    <!-- IDS getSlice()-->
    <xsl:template match="IDS" mode="getSlice">
       <xsl:text>!==================================================================&#10;</xsl:text>
       <xsl:text>!         GET </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_getSlice( pulseCtx, idsTimeMode, numOccurrences, numSlices )&#10;</xsl:text>
	<xsl:text>    use </xsl:text><xsl:value-of select="@name"/><xsl:text>_test_mod&#10;</xsl:text> 
    <xsl:text>    INTEGER, INTENT(IN) :: pulseCtx &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: idsTimeMode &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: numOccurrences &#10;</xsl:text>
        <xsl:text>    INTEGER, INTENT(IN) :: numSlices &#10;</xsl:text>
	<xsl:text>    LOGICAL :: isEqual &#10;</xsl:text>
	<xsl:text>    TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
	<xsl:text>    CHARACTER (LEN=IDS_PATH_LEN) :: idspath &#10;</xsl:text>
	<xsl:text>    CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>    INTEGER :: i, sliceIdx &#10;</xsl:text>
        <xsl:text>    WRITE(*,*) "--- --- --- Testing getSlice() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
	<xsl:text>    CALL random_seed(PUT = seed)&#10;</xsl:text>
        <xsl:text>    do i = 0, MIN(MAX_OCCURENCES, numOccurrences) - 1 &#10;</xsl:text>
	<xsl:text>        WRITE(*,*) "--- --- --- --- occurence: ", i&#10;</xsl:text>
	<xsl:text>        if (i == 0) then &#10;</xsl:text>
	<xsl:text>            idspath = IDS_NAME  &#10;</xsl:text>
	<xsl:text>        else&#10;</xsl:text>
	<xsl:text>            WRITE( occurence, '(i2)' )  i &#10;</xsl:text>
        <xsl:text>            idspath = IDS_NAME//'/'//ADJUSTL(occurence)&#10;</xsl:text>
	<xsl:text>        end if &#10;</xsl:text>

	<xsl:text>        do sliceIdx = 1, numSlices &#10;</xsl:text>
	<xsl:text>    WRITE(*,*) "--- --- --- --- --- slice : ", sliceIdx&#10;</xsl:text>

	<xsl:text>            call ids_get_slice(pulseCtx ,idspath, ids, getTimeScalar(sliceIdx), 1);&#10;</xsl:text>

	<xsl:text>            if (sliceIdx == 1) then &#10;</xsl:text>
	<xsl:text>&#10;</xsl:text>
	<xsl:text>                call test_ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>(ids, .TRUE., .TRUE., idsTimeMode, .TRUE., sliceIdx)&#10;</xsl:text>
	<xsl:text>            else&#10;</xsl:text>
	<xsl:text>                call test_ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>(ids, .FALSE., .TRUE., idsTimeMode, .TRUE., sliceIdx)&#10;</xsl:text>
	<xsl:text>            end if &#10;</xsl:text>
	<xsl:text>            call ids_deallocate(ids)&#10;</xsl:text>
  	<xsl:text>        end do &#10;</xsl:text>
    	<xsl:text>    end do &#10;</xsl:text>
    	<xsl:text>&#10;</xsl:text>
    	<xsl:text>END SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_getSlice&#10;</xsl:text>
	<xsl:text>&#10;</xsl:text>
    </xsl:template>



 

 
    <!-- ========================================================================================================================= -->
    <!-- ========================================================================================================================= -->
    <!-- ======================================================= TEMPLATES ======================================================= -->
    <!-- ========================================================================================================================= -->
    <!-- ========================================================================================================================= -->


    <!-- ========================================================================================================================= -->
    <!-- field put() -->
    <xsl:template match="field[not(@data_type='structure' or @data_type='struct_array')]" mode="put">
       
        <xsl:call-template name="COMMENT_FIELD"/>
            <xsl:if test="(@type !='dynamic' or not(@type)) and not(ancestor::field[@type='dynamic'])">
             <xsl:text>        if ( setStatic ) then&#10;</xsl:text>
        </xsl:if>        
        <xsl:if test="@type='dynamic' or ancestor::field[@type='dynamic']"> 
            <xsl:text>        if ( setDynamic ) then&#10;</xsl:text>
        </xsl:if>
 
        <xsl:call-template name="setValue"/>
        <xsl:text>        endif&#10;</xsl:text>
    </xsl:template>

  <!-- field put() -->
    <xsl:template match="field[ @data_type='structure']" mode="put">
	    <xsl:param name="dynamicOnly"/>
	    <xsl:param name="staticOnly"/>
	      <xsl:call-template name="COMMENT_FIELD"/>
		<xsl:if test="not(descendant::field[@type='dynamic'])">
			<xsl:text>        if ( setStatic ) then&#10;</xsl:text>
			<xsl:text>            ! Static fields only. No dynamic descendants. &#10;</xsl:text>
		</xsl:if>        
		<xsl:if test="not(descendant::field[@type!='dynamic'])"> 
			<xsl:text>        if ( setDynamic ) then&#10;</xsl:text>
			<xsl:text>            ! Dynamic fields only. No static descendants. &#10;</xsl:text>
		</xsl:if>
		<xsl:text>            CALL init_</xsl:text><xsl:value-of select="local:unique_name(translate(@path, '/', '_'))" /><xsl:text>(idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text>, setStatic, setDynamic, idsTimeMode, isSliceMode, sliceIdx)&#10;</xsl:text>
		<xsl:if test="not(descendant::field[@type='dynamic']) or not(descendant::field[@type!='dynamic'])"> 
			<xsl:text>        endif&#10;</xsl:text>
		</xsl:if>
    </xsl:template>

    <xsl:template match="field[ @data_type='struct_array']" mode="put">
        <xsl:call-template name="COMMENT_FIELD"/>
		<xsl:choose>
			<xsl:when test="@maxoccur='unbounded'">
				<xsl:text>            aosSize = config%timeSize&#10;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>            aosSize = MIN(config%timeSize, </xsl:text><xsl:value-of select="@maxoccur"/><xsl:text>)     ! AoS1 of size: </xsl:text> <xsl:value-of select="@maxoccur"/><xsl:text>&#10;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
        <xsl:if test="(@type !='dynamic' or not(@type)) and not(ancestor::field[@type='dynamic'] or descendant::field[@type='dynamic'])">
             <xsl:text>        if ( setStatic ) then&#10;</xsl:text>
			 
       </xsl:if>
       <xsl:if test="@type='dynamic' and not(descendant::field[@type!='dynamic'])"> 
			<xsl:text>        if ( setDynamic ) then&#10;</xsl:text>
       
       </xsl:if>
		<xsl:if test="@type='dynamic'">    
			<xsl:text>            if ( isSliceMode )     aosSize = 1&#10;</xsl:text>
        </xsl:if>

        <xsl:text>            if ( .NOT. associated(idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text>)) then&#10; </xsl:text>
        <xsl:text>                allocate(idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text> (aosSize))&#10; </xsl:text>
        <xsl:text>            endif&#10; </xsl:text>
		<xsl:text>            DO i = 1, aosSize&#10;</xsl:text>
        <xsl:text>                CALL init_</xsl:text><xsl:value-of select="local:unique_name(translate(@path, '/', '_'))" /><xsl:text>(idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text>(i), setStatic, setDynamic, idsTimeMode, isSliceMode, sliceIdx)&#10;</xsl:text>
    	<xsl:text>            END DO&#10;</xsl:text>
		  <xsl:if test="((@type !='dynamic' or not(@type)) and not(ancestor::field[@type='dynamic'] or descendant::field[@type='dynamic'])) or (@type='dynamic' and not(descendant::field[@type!='dynamic']))">
			<xsl:text>        endif&#10;</xsl:text>
		</xsl:if>
    </xsl:template>



    <!-- field get() -->

    <!-- ========================================================================================================================= -->
    <xsl:template match="field[not(@data_type='structure' or @data_type='struct_array') ]" mode="get">
		<xsl:call-template name="COMMENT_FIELD"/>
		<xsl:if test="(@type !='dynamic' or not(@type)) and not(ancestor::field[@type='dynamic'])">
			<xsl:text>        if ( setStatic ) then&#10;</xsl:text>
		</xsl:if>        
		<xsl:if test="@type='dynamic' or ancestor::field[@type='dynamic']"> 
			<xsl:text>        if ( setDynamic ) then&#10;</xsl:text>
		</xsl:if>
		<xsl:call-template name="getValue"/>
		<xsl:text>        endif&#10;</xsl:text>
	</xsl:template>


    <!-- field get() for array of structures -->

    <xsl:template match="field[@data_type='structure']" mode="get">
		<xsl:call-template name="COMMENT_FIELD"/>
		<xsl:if test="not(descendant::field[@type='dynamic'])">
			<xsl:text>        if ( setStatic ) then&#10;</xsl:text>
			<xsl:text>            ! Static fields only. No dynamic descendants. &#10;</xsl:text>
		</xsl:if>        
		<xsl:if test="not(descendant::field[@type!='dynamic'])"> 
			<xsl:text>        if ( setDynamic ) then&#10;</xsl:text>
			<xsl:text>            ! Dynamic fields only. No static descendants. &#10;</xsl:text>
		</xsl:if>
		<xsl:text>            CALL test_</xsl:text><xsl:value-of select="local:unique_name(translate(@path, '/', '_'))" /><xsl:text>(idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text>, setStatic, setDynamic, idsTimeMode, isSliceMode, sliceIdx)&#10;</xsl:text>
		<xsl:if test="not(descendant::field[@type='dynamic']) or not(descendant::field[@type!='dynamic'])"> 
			<xsl:text>        endif&#10;</xsl:text>
		</xsl:if>
	</xsl:template>
	
		<!-- field get() for array of structures -->

	<xsl:template match="field[@data_type='struct_array']" mode="get">
		<xsl:call-template name="COMMENT_FIELD"/>
		<xsl:choose>
			<xsl:when test="@maxoccur='unbounded'">
				<xsl:text>            aosSize = config%timeSize&#10;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>            aosSize = MIN(config%timeSize, </xsl:text><xsl:value-of select="@maxoccur"/><xsl:text>)     ! AoS1 of size: </xsl:text> <xsl:value-of select="@maxoccur"/><xsl:text>&#10;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="(@type !='dynamic' or not(@type)) and not(ancestor::field[@type='dynamic'] or descendant::field[@type='dynamic'])">
             <xsl:text>        if ( setStatic ) then&#10;</xsl:text>
       </xsl:if>
       <xsl:if test="@type='dynamic' and not(descendant::field[@type!='dynamic'])"> 
			<xsl:text>        if ( setDynamic ) then&#10;</xsl:text>
       </xsl:if>
		<xsl:if test="@type='dynamic'">    
			<xsl:text>            if ( isSliceMode ) then&#10;</xsl:text>
			<xsl:text>                aosSize = 1&#10;</xsl:text>
			<xsl:text>            else&#10;</xsl:text>
			<xsl:text>                aosSize = config%timeSize&#10;</xsl:text>
			<xsl:text>            end if&#10;</xsl:text>
        </xsl:if>

        <xsl:text>            if ( .NOT. associated(idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text>)) then&#10; </xsl:text>
        <xsl:text>                allocate(idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text> (aosSize))&#10; </xsl:text>
        <xsl:text>            endif&#10; </xsl:text>
    	<xsl:text>            DO i = 1, aosSize&#10;</xsl:text>
        <xsl:text>                CALL test_</xsl:text><xsl:value-of select="local:unique_name(translate(@path, '/', '_'))" /><xsl:text>(idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text>(i), setStatic, setDynamic, idsTimeMode, isSliceMode, sliceIdx)&#10;</xsl:text>
    	<xsl:text>            END DO&#10;</xsl:text>
		  <xsl:if test="((@type !='dynamic' or not(@type)) and not(ancestor::field[@type='dynamic'] or descendant::field[@type='dynamic'])) or (@type='dynamic' and not(descendant::field[@type!='dynamic']))">
			<xsl:text>        endif&#10;</xsl:text>
		</xsl:if>

    </xsl:template>
    



      <xsl:template name="setValue">
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
                        <xsl:text>            idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text> = idsTimeMode</xsl:text>
            </xsl:when>

            <xsl:when test="@name='time' and (@data_type='flt_1d_type' or @data_type='FLT_1D')">
                          <xsl:text>            call initTimeField( idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text>, isSliceMode, sliceIdx)</xsl:text>
            </xsl:when>
            <xsl:when test="@name='time' and (@data_type='flt_type' or @data_type='FLT_0D') and parent::field[@data_type='struct_array' and @type ='dynamic']">
                          <xsl:text>            call initTimeFieldScalar( idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text>, isSliceMode, sliceIdx)</xsl:text>
            </xsl:when>

            <xsl:when test="@data_type='str_type' or @data_type='STR_0D' or
                            @data_type='str_1d_type' or @data_type='STR_1D' or
                            @data_type='flt_type' or @data_type='FLT_0D' or
			    @data_type='cpx_type' or @data_type='CPX_0D' or
                            @data_type='flt_1d_type' or @data_type='FLT_1D'or
			    @data_type='cpx_1d_type' or @data_type='CPX_1D'or
                            @data_type='flt_2d_type' or @data_type='FLT_2D' or
                            @data_type='cpx_2d_type' or @data_type='CPX_2D' or
                            @data_type='FLT_3D' or @data_type='FLT_4D' or  @data_type='FLT_5D' or @data_type='FLT_6D' or
			    @data_type='CPX_3D' or @data_type='CPX_4D' or @data_type='CPX_5D' or @data_type='CPX_6D' or
                            @data_type='int_type' or @data_type='INT_0D' or 
                            @data_type='int_1d_type' or @data_type='INT_1D' or 
                            @data_type='INT_2D' or @data_type='INT_3D' or @data_type='INT_4D'">
                      <xsl:text>            call initField(idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text>, </xsl:text><xsl:value-of select="$sliceMode"/><xsl:text> ) &#10;</xsl:text>
            </xsl:when>

            <xsl:otherwise>
                <xsl:message terminate="yes"> ERROR! Unknown type: <xsl:value-of select="@data_type"/>  (<xsl:value-of select="ancestor::IDS/@name"/>:  <xsl:value-of select="@path" />)</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
<xsl:text>    &#10;</xsl:text>
    </xsl:template>
    
    
    
          <xsl:template name="getValue">
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
	  <!-- SKIP VALUE CHECK FOR version_dd_al NODES -->
	  <!-- (would require a cleaner implementation) -->
            <xsl:when test="@name='data_dictionary'">
              <xsl:text>            !!! DON'T CHECK VALUE !!!&#10;</xsl:text>
            </xsl:when>
            <xsl:when test="@name='access_layer'">
              <xsl:text>            !!! DON'T CHECK VALUE !!!&#10;</xsl:text>
            </xsl:when>
            <xsl:when test="@name='access_layer_language'">
              <xsl:text>            !!! DON'T CHECK VALUE !!!&#10;</xsl:text>
            </xsl:when>

            <xsl:when test="@name='homogeneous_time'">
                                           <xsl:text>            isEqual = assertHomogeneousTimeField(idsTimeMode, idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text>, </xsl:text><xsl:value-of select="$sliceMode"/><xsl:text>, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>:</xsl:text><xsl:value-of select="@path"/><xsl:text>")&#10;</xsl:text>
            </xsl:when>

            <xsl:when test="@name='time' and (@data_type='flt_1d_type' or @data_type='FLT_1D')">
                              <xsl:text>            isEqual = assertTimeField(idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text>, </xsl:text><xsl:value-of select="$sliceMode"/><xsl:text>, sliceIdx, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>:</xsl:text><xsl:value-of select="@path"/><xsl:text>")&#10;</xsl:text>
            </xsl:when>
            <xsl:when test="@name='time' and (@data_type='flt_type' or @data_type='FLT_0D') and parent::field[@data_type='struct_array' and @type ='dynamic']">
                              <xsl:text>            isEqual = assertTimeFieldScalar(idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text>, </xsl:text><xsl:value-of select="$sliceMode"/><xsl:text>, sliceIdx, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>:</xsl:text><xsl:value-of select="@path"/><xsl:text>")&#10;</xsl:text>
            </xsl:when>

            <xsl:when test="@data_type='str_type' or @data_type='STR_0D' or
                            @data_type='str_1d_type' or @data_type='STR_1D' or
                            @data_type='flt_type' or @data_type='FLT_0D' or
                            @data_type='flt_1d_type' or @data_type='FLT_1D'or
                            @data_type='flt_2d_type' or @data_type='FLT_2D' or
                            @data_type='FLT_3D' or @data_type='FLT_4D'or  @data_type='FLT_5D' or @data_type='FLT_6D' or
			    @data_type='cpx_type' or @data_type='CPX_0D' or
			    @data_type='cpx_1d_type' or @data_type='CPX_1D' or
			    @data_type='cpx_2d_type' or @data_type='CPX_2D' or
			    @data_type='CPX_3D' or @data_type='CPX_4D'or  @data_type='CPX_5D' or @data_type='CPX_6D' or
                            @data_type='int_type' or @data_type='INT_0D' or 
                            @data_type='int_1d_type' or @data_type='INT_1D' or 
                            @data_type='INT_2D' or @data_type='INT_3D' or @data_type='INT_4D'">
                      <xsl:text>            isEqual = assertField(idsNode%</xsl:text><xsl:value-of select="@name"/><xsl:text>, </xsl:text><xsl:value-of select="$sliceMode"/><xsl:text>, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>:</xsl:text><xsl:value-of select="@path"/><xsl:text>")&#10;</xsl:text>


                <xsl:text>             if (.not.isEqual) STOP &#10;</xsl:text>
            </xsl:when>

            <xsl:otherwise>
                <xsl:message terminate="yes"> ERROR! Unknown type: <xsl:value-of select="@data_type"/>  (<xsl:value-of select="ancestor::IDS/@name"/>:  <xsl:value-of select="@path" />)</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

<xsl:text>    &#10;</xsl:text>

    </xsl:template>
 
</xsl:stylesheet>
