 <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions">
    <xsl:output method="text"/>
    <xsl:strip-space elements="*"/>

    <!-- Initial c ode -->
    <xsl:template match="IDSs">


   	<xsl:apply-templates select="child::IDS" mode="test"/>

     
    </xsl:template>

 <!-- ============================= END OF GENRATED FILE ============================== -->

 <!-- ============================= TEMPLATES ============================== -->

        <!--Documentation for a single field-->
    <xsl:template name = "COMMENT_FIELD">
        <xsl:text>&#xA;</xsl:text>
	<xsl:text>&#9;&#9;!!!  </xsl:text><xsl:value-of select="@name"/>:<xsl:value-of select="@path"/>:<xsl:value-of select="@data_type"/>:<xsl:value-of select="@type"/>:<xsl:text>&#xA;</xsl:text>

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


    <!-- IDS perform the tests -->
 <xsl:template match="IDS" mode="test">
	<xsl:result-document href="src/{@name}_test.f90" standalone="yes" method="text">



	 <!-- ================================ MAIN PROGRAM ================================= -->
         <xsl:text>PROGRAM </xsl:text><xsl:value-of select="@name"/><xsl:text>_test&#10;</xsl:text>
	<xsl:text>&#9;use comparator &#10;</xsl:text>
	<xsl:text>&#9;use ids_schemas &#10;</xsl:text>

	<xsl:text>&#9;use helper&#10;</xsl:text>
        <xsl:text>&#9;implicit none&#10;   </xsl:text>



    <xsl:text>&#9;INTEGER :: idx;&#10;</xsl:text>
    <xsl:text>&#9;INTEGER, PARAMETER :: IDS_PATH_LEN = 30;&#10;</xsl:text>
    <xsl:text>&#9;INTEGER :: N_SEED&#10;</xsl:text>
    <xsl:text>&#9;call random_seed(SIZE=N_SEED)&#10;</xsl:text>
    <xsl:text>&#9;ALLOCATE(SEED(N_SEED))&#10;</xsl:text>
    
    
        <xsl:text>&#10;</xsl:text>


	
        <xsl:text>&#9;call init(idx);&#10;</xsl:text>
  <!-- <xsl:apply-templates select="child::IDS[@name='temporary']" mode="test"/>   -->
   <xsl:apply-templates select="." mode="testCalls"/>

        <xsl:text>&#9;call finish(idx);&#10;</xsl:text>

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

    <!-- IDS put()-->
    <xsl:template match="IDS" mode="put">
        <xsl:text>!==================================================================&#10;</xsl:text>
       <xsl:text>!&#9;&#9; PUT </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_put&#10;</xsl:text>
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
	<xsl:apply-templates select="field" mode="put">
                  	<xsl:with-param name="dynamicOnly" select="false()"/>
			<xsl:with-param name="staticOnly" select="false()"/>
                </xsl:apply-templates>
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
	<xsl:text>&#9;CHARACTER (LEN = *), parameter :: idsName = "</xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
	<xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=IDS_PATH_LEN) :: idspath &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: i, j &#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: tmpInt = -1 &#10;</xsl:text>
        <xsl:text>&#9;WRITE(*,*) "Testing putSlice() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
        <xsl:text>&#9;!CALL srand(seed)&#10;</xsl:text>
        <xsl:text>&#9;CALL random_seed(PUT = seed)&#10;</xsl:text>
        <xsl:text>&#9;do i = 0, </xsl:text><xsl:value-of select="@maxoccur"/><xsl:text> - 1 &#10;</xsl:text>
	 <xsl:text>&#9;WRITE(*,*) "--- occurence: ", i&#10;</xsl:text>
 	<xsl:text>&#9;&#9;do j = 1, noOfSlices &#10;</xsl:text>
 	<xsl:text>&#9;WRITE(*,*) "--- --- slice : ", j&#10;</xsl:text>
<xsl:text>&#9;&#9;&#9;!------------&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;if (i == 0) then &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;&#9;idspath = idsName  &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;else&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;&#9;WRITE( occurence, '(i2)' )  i &#10;</xsl:text>
        <xsl:text>&#9;&#9;&#9;&#9;idspath = idsName//'/'//ADJUSTL(occurence)&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;end if &#10;</xsl:text>
	<xsl:text>  &#10;</xsl:text>

	
	<xsl:text>&#9;&#9;&#9;if (j == 1) then &#10;</xsl:text>
<xsl:text>&#9;&#9;&#9;! =================== PUT STATIC DATA (ONCE) ================  &#10;</xsl:text>
	 <xsl:apply-templates select="field" mode="putStatic"/>
         <xsl:text>&#9;&#9;&#9;&#9;call ids_put_non_timed(idx ,idspath, ids);&#10;</xsl:text> 
	<xsl:text>&#9;&#9;&#9;! =================== PUT STATIC DATA (ONCE) ================  &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;end if &#10;</xsl:text>

	<xsl:text>&#9;&#9;! ======================== PUT DYNAMIC DATA (LOOP) =====================  &#10;</xsl:text>
       <xsl:apply-templates select="field" mode="putDynamic"/>
	<xsl:text>&#9;&#9;! ======================== PUT DYNAMIC DATA (LOOP) =====================  &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;call ids_put_slice(idx ,idspath, ids);&#10;</xsl:text>

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
	<xsl:text>&#9;CHARACTER (LEN = *), parameter :: idsName = "</xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
	<xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
	<xsl:text>&#9;LOGICAL :: isEqual &#10;</xsl:text>
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

        	<xsl:apply-templates select="field" mode="get">
                  	<xsl:with-param name="dynamicOnly" select="false()"/>
			<xsl:with-param name="staticOnly" select="false()"/>
                </xsl:apply-templates>
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
	<xsl:text>&#9;LOGICAL :: isEqual &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN = *), parameter :: idsName = "</xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
	<xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=IDS_PATH_LEN) :: idspath &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: i, j &#10;</xsl:text>
        <xsl:text>&#9;WRITE(*,*) "Testing getSlice() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
        <xsl:text>&#9;!CALL srand(seed)&#10;</xsl:text>
	<xsl:text>&#9;CALL random_seed(PUT = seed)&#10;</xsl:text>
        <xsl:text>&#9;do i = 0, </xsl:text><xsl:value-of select="@maxoccur"/><xsl:text> - 1  &#10;</xsl:text>
	<xsl:text>&#9;WRITE(*,*) "---  occurence: ", i&#10;</xsl:text>
	<xsl:text>&#9;&#9;if (i == 0) then &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;idspath = idsName  &#10;</xsl:text>
	<xsl:text>&#9;&#9;else&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;WRITE( occurence, '(i2)' )  i &#10;</xsl:text>
        <xsl:text>&#9;&#9;&#9;idspath = idsName//'/'//ADJUSTL(occurence)&#10;</xsl:text>
	<xsl:text>&#9;&#9;end if &#10;</xsl:text>

	<xsl:text>&#9;&#9;do j = 1, noOfSlices &#10;</xsl:text>
	<xsl:text>&#9;WRITE(*,*) "--- --- slice : ", j&#10;</xsl:text>

	<xsl:text>&#9;&#9;&#9;call ids_get_slice(idx ,idspath, ids, getTimeScalar(j), 1);&#10;</xsl:text>

	<xsl:text>&#9;&#9;&#9;if (j == 1) then &#10;</xsl:text>
	<xsl:text>  &#10;</xsl:text>
	<xsl:text>&#9;&#9;! ======================== GET STATIC DATA (ONCE) =====================  &#10;</xsl:text>
	<xsl:apply-templates select="field" mode="getSlice">
                  	<xsl:with-param name="dynamicOnly" select="false()"/>
			<xsl:with-param name="staticOnly" select="true()"/>
                </xsl:apply-templates>

	<xsl:text>&#9;&#9;! ======================== GET STATIC DATA (ONCE) =====================  &#10;</xsl:text>

	<xsl:text>&#9;&#9;&#9;end if &#10;</xsl:text>
	<xsl:text>&#9;&#9;! ======================== GET DYNAMIC DATA (LOOP) =====================  &#10;</xsl:text>
  		<xsl:apply-templates select="field" mode="getSlice">
                  	<xsl:with-param name="dynamicOnly" select="true()"/>
			<xsl:with-param name="staticOnly" select="false()"/>
                </xsl:apply-templates>
	<xsl:text>&#9;&#9;! ======================== GET DYNAMIC DATA (LOOP) =====================  &#10;</xsl:text>
		 <!-- <xsl:text>&#9;call ids_deallocate(ids)&#10;</xsl:text> -->
  	<xsl:text>&#9;&#9;end do &#10;</xsl:text>
	  <xsl:text>&#9;end do &#10;</xsl:text>
        <xsl:text>&#9;&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_getSlice&#10;</xsl:text>
	<xsl:text>&#10;</xsl:text>
    </xsl:template>


 
  <xsl:template match="field" mode="putDynamic">



	<xsl:if test="@type ='dynamic' or @data_type='structure' or @data_type='struct_array'"> <!-- This skips the routine for non timed fields -->
	<xsl:text>&#10;&#9;&#9;&#9;!!!!! </xsl:text><xsl:value-of select="@name"/> : <xsl:value-of select="@path"/> : <xsl:value-of select="@data_type"/> : :<xsl:value-of select="@type"/>:<xsl:text>&#10;</xsl:text>
		<xsl:apply-templates select="." mode="put">
                	<xsl:with-param name="dynamicOnly" select="true()"/>
			<xsl:with-param name="staticOnly" select="false()"/>
                </xsl:apply-templates>
	</xsl:if>
    </xsl:template>


 <xsl:template match="field" mode="putStatic">

<xsl:if test="@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')"> <!-- This skips the routine for timed fields when using this template in PUT_NON_TIMED mode -->

	<xsl:text>&#10;&#9;&#9;&#9;!!!STATIC!! </xsl:text><xsl:value-of select="@name"/> : <xsl:value-of select="@path"/> : <xsl:value-of select="@data_type"/> : :<xsl:value-of select="@type"/>:<xsl:text>&#10;</xsl:text>


		<xsl:apply-templates select="." mode="put">
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

	<xsl:text>&#10;&#9;&#9;&#9;!!X!</xsl:text><xsl:value-of select="@name"/> : <xsl:value-of select="@path"/> : <xsl:value-of select="@data_type"/> : <xsl:value-of select="@type"/>:<xsl:text>&#10;</xsl:text>
            <xsl:call-template name="setValue">
                <xsl:with-param name="fieldPath" select="concat('ids%',translate(@path, '/', '%'))"/>
		<xsl:with-param name="slice" select="$dynamicOnly or $staticOnly"/>
            </xsl:call-template>
</xsl:if>
    </xsl:template>

  <!-- field put() -->
    <xsl:template match="field[  @data_type='struct_array']" mode="put">
	<xsl:param name="dynamicOnly"/>
	<xsl:param name="staticOnly"/>
	  <xsl:variable name="IDS_FIELD_PATH">  <xsl:text>&#9;&#9;ids%</xsl:text><xsl:value-of select="translate(@path, '/', '%')"/><xsl:text> = </xsl:text> </xsl:variable>
	<xsl:text>&#10;&#9;&#9;&#9;!!!</xsl:text><xsl:value-of select="@name"/> : <xsl:value-of select="@path"/> : <xsl:value-of select="@data_type"/> : :<xsl:value-of select="@type"/>:<xsl:text>&#10;</xsl:text>

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
		<xsl:text>&#9;&#9;&#9;allocate(ids%</xsl:text><xsl:value-of select="substring($path, 1, string-length($path) - 3)"/><xsl:text> (1))&#10; </xsl:text>
	</xsl:if>
        <xsl:for-each select="field[not(@data_type='struct_array' or @data_type='structure')]">
	<xsl:if test="(not($dynamicOnly) and (@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')))
or
(not($staticOnly) and (@type ='dynamic' or @data_type='structure' or @data_type='struct_array'))"> 

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
    	<xsl:call-template name="COMMENT_FIELD"/>
        <xsl:text>&#9;&#9;&#9; isEqual = assertField(ids%</xsl:text><xsl:value-of select="translate(@path, '/', '%')"/><xsl:text>, </xsl:text>
		<xsl:call-template name="type2value">
			 <xsl:with-param name="lastDimSize" select="'DIM_SIZE'"/>
		</xsl:call-template>
	<xsl:text>, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>/</xsl:text><xsl:value-of select="@path"/><xsl:text>");&#10;</xsl:text>
    </xsl:template>


    <!-- field get() -->
    <xsl:template match="field[not(@data_type='structure' or @data_type='struct_array')]" mode="getSlice">
	<xsl:param name="dynamicOnly"/>
	<xsl:param name="staticOnly"/>
    	<xsl:call-template name="COMMENT_FIELD"/>
	<xsl:if test="(not($dynamicOnly) and (@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')))
or
(not($staticOnly) and (@type ='dynamic' or @data_type='structure' or @data_type='struct_array'))"> 

    <xsl:choose>
            <xsl:when test="@type='dynamic'">

           <xsl:text>&#9;&#9;&#9; isEqual = assertField(ids%</xsl:text><xsl:value-of select="translate(@path, '/', '%')"/><xsl:text>, </xsl:text>
		<xsl:call-template name="type2value">
			 <xsl:with-param name="lastDimSize" select="1"/>
			  <xsl:with-param name="slice" select="true()"/>
		</xsl:call-template>
	<xsl:text>, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>/</xsl:text><xsl:value-of select="@path"/><xsl:text>");&#10;</xsl:text>        </xsl:when>
	    <xsl:otherwise>
		<xsl:text>&#9;&#9;&#9; isEqual = assertField(ids%</xsl:text><xsl:value-of select="translate(@path, '/', '%')"/><xsl:text>, </xsl:text>
		<xsl:call-template name="type2value">
			 <xsl:with-param name="lastDimSize" select="'DIM_SIZE'"/>
			 	 <xsl:with-param name="slice" select="true()"/>
		</xsl:call-template>
	<xsl:text>, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>/</xsl:text><xsl:value-of select="@path"/><xsl:text>");&#10;</xsl:text>
	</xsl:otherwise>
    </xsl:choose>

</xsl:if>
    </xsl:template>



    <!-- field get() for array of structures -->

    <xsl:template match="field[@data_type='struct_array']" mode="get">
	<xsl:param name="dynamicOnly"/>
	<xsl:param name="staticOnly"/>
        	<xsl:call-template name="COMMENT_FIELD"/>

	<xsl:text>&#9;&#9;if(.not. associated(ids%</xsl:text>  <xsl:value-of select="translate(@path, '/', '%')" /> <xsl:text>)) then &#10;</xsl:text>
		<xsl:text>&#9;&#9;&#9;write(*,*) "ERROR! IDS: </xsl:text> <xsl:value-of select="ancestor::IDS/@name"/> <xsl:text> Field: </xsl:text> <xsl:value-of select="translate(@path, '/', '%')" /> <xsl:text> is not associated!"&#10; </xsl:text>
			<!-- <xsl:text>&#9;&#9;&#9;return &#10;</xsl:text> -->
					<xsl:text>&#9;&#9;&#9;else &#10;</xsl:text>

        <xsl:call-template name="getStructArray">
            <xsl:with-param name="path" select="concat(translate(@path, '/', '%'), '(1)')"/>
	     <xsl:with-param name="slice" select="false()"/>
	    	<xsl:with-param name="dynamicOnly" select="$dynamicOnly"/>
   	    	<xsl:with-param name="staticOnly" select="$staticOnly"/>
        </xsl:call-template>
		<xsl:text>&#9;&#9;end if &#10;</xsl:text>
    </xsl:template>




        <xsl:template match="field[@data_type='struct_array']" mode="getSlice">
	<xsl:param name="dynamicOnly"/>
	<xsl:param name="staticOnly"/>
        	<xsl:call-template name="COMMENT_FIELD"/>

	<xsl:text>&#9;&#9;if(.not. associated(ids%</xsl:text>  <xsl:value-of select="translate(@path, '/', '%')" /> <xsl:text>)) then &#10;</xsl:text>
		<xsl:text>&#9;&#9;&#9;write(*,*) "ERROR! IDS: </xsl:text> <xsl:value-of select="ancestor::IDS/@name"/> <xsl:text> Field: </xsl:text> <xsl:value-of select="translate(@path, '/', '%')" /> <xsl:text> is not associated!"&#10; </xsl:text>
			<!-- <xsl:text>&#9;&#9;&#9;return &#10;</xsl:text> -->
					<xsl:text>&#9;&#9;&#9;else &#10;</xsl:text>

        <xsl:call-template name="getStructArray">
            <xsl:with-param name="path" select="concat(translate(@path, '/', '%'), '(1)')"/>
	     <xsl:with-param name="slice" select="true()"/>
	    	<xsl:with-param name="dynamicOnly" select="$dynamicOnly"/>
   	    	<xsl:with-param name="staticOnly" select="$staticOnly"/>

        </xsl:call-template>
		<xsl:text>&#9;&#9;end if &#10;</xsl:text>
    </xsl:template>



    <xsl:template name="getStructArray">
        <xsl:param name="path"/>
	<xsl:param name="slice"/>
	<xsl:param name="dynamicOnly"/>
	<xsl:param name="staticOnly"/>

<xsl:if test="(not($dynamicOnly) and (@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')))
or
(not($staticOnly) and (@type ='dynamic' or @data_type='structure' or @data_type='struct_array'))"> 

        <xsl:for-each select="field[not(@data_type='struct_array' or @data_type='structure')]">
	<xsl:if test="(not($dynamicOnly) and (@type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')))
or
(not($staticOnly) and (@type ='dynamic' or @data_type='structure' or @data_type='struct_array'))"> 
	<xsl:call-template name="COMMENT_FIELD"/>

	     <xsl:choose>
                <xsl:when test="$slice and @type='dynamic' and not(ancestor::field[@data_type='struct_array' and @maxoccur='unbounded'])  ">

     		<xsl:text>&#9;&#9;&#9; isEqual = assertField(ids%</xsl:text><xsl:value-of select="concat($path, '%', @name)"/><xsl:text>, </xsl:text>
	    	<xsl:call-template name="type2value">
			 <xsl:with-param name="lastDimSize" select="1"/>
			 	<xsl:with-param name="slice" select="true()"/>
		</xsl:call-template>
		<xsl:text>, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>/</xsl:text><xsl:value-of select="@path"/><xsl:text>");&#10;</xsl:text>
		           </xsl:when>
	        <xsl:otherwise>


		<xsl:text>&#9;&#9;&#9; isEqual =  assertField(ids%</xsl:text><xsl:value-of select="concat($path, '%', @name)"/><xsl:text>, </xsl:text>
	    	<xsl:call-template name="type2value">
			 <xsl:with-param name="lastDimSize" select="'DIM_SIZE'"/>
				 <xsl:with-param name="slice" select="$slice"/>
		</xsl:call-template>
		<xsl:text>, "</xsl:text><xsl:value-of select="ancestor::IDS/@name"/><xsl:text>/</xsl:text><xsl:value-of select="@path"/><xsl:text>");&#10;</xsl:text>


		</xsl:otherwise>
            </xsl:choose>

</xsl:if>
        </xsl:for-each>



        <xsl:for-each select="field[@data_type='structure']">
	<xsl:call-template name="COMMENT_FIELD"/>
            <xsl:call-template name="getStructArray">
                <xsl:with-param name="path" select="concat($path, '%', @name)"/>
			   <xsl:with-param name="slice" select="$slice"/>
	    	<xsl:with-param name="dynamicOnly" select="$dynamicOnly"/>
   	    	<xsl:with-param name="staticOnly" select="$staticOnly"/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="field[@data_type='struct_array']">
	<xsl:call-template name="COMMENT_FIELD"/>

	<xsl:text>&#9;&#9;if(.not. associated(ids%</xsl:text>  <xsl:value-of select="concat($path, '%', @name)" /> <xsl:text>)) then &#10;</xsl:text>
		<xsl:text>&#9;&#9;&#9;write(*,*) "ERROR! IDS: </xsl:text>  <xsl:value-of select="ancestor::IDS/@name"/> <xsl:text> Field: </xsl:text><xsl:value-of select="concat($path, '%', @name, '(1)')" /> <xsl:text> is not associated!"&#10; </xsl:text>
		<!-- <xsl:text>&#9;&#9;&#9;return &#10;</xsl:text>  -->
			<xsl:text>&#9;&#9;&#9;else &#10;</xsl:text>

	     <xsl:call-template name="getStructArray">
                <xsl:with-param name="path" select="concat($path, '%', @name, '(1)')"/>
			   <xsl:with-param name="slice" select="$slice"/>
	    	<xsl:with-param name="dynamicOnly" select="$dynamicOnly"/>
   	    	<xsl:with-param name="staticOnly" select="$staticOnly"/>

            </xsl:call-template>
	<xsl:text>&#9;&#9;end if &#10;</xsl:text>
        </xsl:for-each>


</xsl:if>
    </xsl:template>


    <xsl:template name="setValue">
            <xsl:param name="fieldPath"/>
	          <xsl:param name="slice"/>

        <xsl:choose>

	      <xsl:when test="@name='homogeneous_time'">
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/> <xsl:text>= 1&#10;</xsl:text>
	    </xsl:when>

          <xsl:when test="@name='time' and $slice and (@data_type='flt_1d_type' or @data_type='FLT_1D')">
	    		

    			<xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(1)) &#10;</xsl:text>
	             	<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getTime(j)&#10;</xsl:text>
	    </xsl:when>
    	<xsl:when test="@name='time' and not($slice) and (@data_type='flt_1d_type' or @data_type='FLT_1D')">
	    		

    			<xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE)) &#10;</xsl:text>
	             	<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getTimeVector()&#10;</xsl:text>
	    </xsl:when>

            <xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
	        	     <xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(1)) &#10;</xsl:text>
	    		 <xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/> <xsl:text> = getString()&#10;</xsl:text>
	    		<!-- <xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/> <xsl:text>(1) = 'abc123' &#10;</xsl:text> -->
	    </xsl:when>
            <xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
    	<xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(1)) &#10;</xsl:text>
	    <xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/>     <xsl:text> = getString()&#10;</xsl:text>
	   </xsl:when>

            <xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
	   	<xsl:text>&#9;&#9;&#9;</xsl:text>  <xsl:value-of select="$fieldPath"/> <xsl:text> = getDouble()&#10;</xsl:text>
	    </xsl:when>


          <xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
	    	     	<xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE)) &#10;</xsl:text>
	             	<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getDouble1DArray(DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>
             <xsl:when test="@data_type='flt_2d_type' or @data_type='FLT_2D'">
	    	<xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE)) &#10;</xsl:text>
	       		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getDouble2DArray(DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
	</xsl:when>

	   <xsl:when test="@data_type='FLT_3D'">
	    	    	<xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE, DIM_SIZE)) &#10;</xsl:text>
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getDouble3DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
		</xsl:when>
            <xsl:when test="@data_type='FLT_4D'">
	    	    	    	<xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) &#10;</xsl:text>
	    	<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getDouble4DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>
            <xsl:when test="@data_type='FLT_5D'">
	    	   	 <xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) &#10;</xsl:text>
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/> <xsl:text> = getDouble5DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>
            <xsl:when test="@data_type='FLT_6D'">
	    	    	    	    	    	<xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) &#10;</xsl:text>
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getDouble6DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>

             <xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
			 <xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/> <xsl:text>= getInteger()&#10;</xsl:text>
	    </xsl:when>

             <xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
	        	     	<xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE)) &#10;</xsl:text>
	      		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getInteger1DArray(DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>

	    <xsl:when test="@data_type='INT_2D'">
	    <xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE)) &#10;</xsl:text>
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getInteger2DArray(DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>
             <xsl:when test="@data_type='INT_3D'">
	    	    	    	<xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE, DIM_SIZE)) &#10;</xsl:text>
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getInteger3DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>
            <xsl:when test="@data_type='INT_4D'">
	    	    	    	    	<xsl:text>&#9;&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) &#10;</xsl:text>
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getInteger4DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>

            <xsl:otherwise>

	    <xsl:message terminate='no'> ERROR! Unknown type: <xsl:value-of select="@data_type"/>  (<xsl:value-of select="ancestor::IDS/@name"/>:  <xsl:value-of select="@path" />)</xsl:message>
	    </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="type2value">
         <xsl:param name="lastDimSize"/>
	          <xsl:param name="slice"/>



        <xsl:choose>
          <!--  <xsl:when test="@name='time'">              <xsl:text>getTime()</xsl:text></xsl:when> -->

	  <xsl:when test="@name='time' and $slice and (@data_type='flt_1d_type' or @data_type='FLT_1D')"><xsl:text>getTime(j)</xsl:text></xsl:when>
  <xsl:when test="@name='time' and not($slice) and (@data_type='flt_1d_type' or @data_type='FLT_1D')"><xsl:text>getTimeVector()</xsl:text></xsl:when>
		<xsl:when test="@name='homogeneous_time'">              <xsl:text>1</xsl:text></xsl:when>
            <xsl:when test="@data_type='str_type' or @data_type='STR_0D'">         <xsl:text>getString()</xsl:text></xsl:when>
            <xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">   <xsl:text> getString()</xsl:text></xsl:when>

            <xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">           	<xsl:text>getDouble()</xsl:text></xsl:when>
            <xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">       	<xsl:text>getDouble1DArray(</xsl:text><xsl:value-of select="$lastDimSize"/><xsl:text>)</xsl:text></xsl:when>
            <xsl:when test="@data_type='FLT_2D'">        				<xsl:text>getDouble2DArray(DIM_SIZE, </xsl:text><xsl:value-of select="$lastDimSize"/><xsl:text>)</xsl:text></xsl:when>
            <xsl:when test="@data_type='FLT_3D'">  					<xsl:text>getDouble3DArray(DIM_SIZE, DIM_SIZE, </xsl:text><xsl:value-of select="$lastDimSize"/><xsl:text>)</xsl:text></xsl:when>
            <xsl:when test="@data_type='FLT_4D'">  					<xsl:text>getDouble4DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, </xsl:text><xsl:value-of select="$lastDimSize"/><xsl:text>)</xsl:text></xsl:when>
            <xsl:when test="@data_type='FLT_5D'">   					<xsl:text>getDouble5DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, </xsl:text><xsl:value-of select="$lastDimSize"/><xsl:text>)</xsl:text></xsl:when>
            <xsl:when test="@data_type='FLT_6D'">   					<xsl:text>getDouble6DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, </xsl:text><xsl:value-of select="$lastDimSize"/><xsl:text>)</xsl:text></xsl:when>

            <xsl:when test="@data_type='int_type' or @data_type='INT_0D'">          	<xsl:text>getInteger()</xsl:text></xsl:when>
            <xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">       	<xsl:text>getInteger1DArray(</xsl:text><xsl:value-of select="$lastDimSize"/><xsl:text>)</xsl:text></xsl:when>
            <xsl:when test="@data_type='INT_2D'">   					<xsl:text>getInteger2DArray(DIM_SIZE, </xsl:text><xsl:value-of select="$lastDimSize"/><xsl:text>)</xsl:text></xsl:when>
            <xsl:when test="@data_type='INT_3D'">   					<xsl:text>getInteger3DArray(DIM_SIZE, DIM_SIZE, </xsl:text><xsl:value-of select="$lastDimSize"/><xsl:text>)</xsl:text></xsl:when>
            <xsl:when test="@data_type='INT_4D'">   					<xsl:text>getInteger4DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, </xsl:text><xsl:value-of select="$lastDimSize"/><xsl:text>)</xsl:text></xsl:when>
    <xsl:otherwise>
	    <xsl:message terminate='no'> ERROR! Unknown type: <xsl:value-of select="@data_type"/>  (<xsl:value-of select="ancestor::IDS/@name"/>:  <xsl:value-of select="@path" />)</xsl:message>
         </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
