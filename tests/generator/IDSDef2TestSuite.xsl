<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions">
    <xsl:output method="text"/>
    <xsl:strip-space elements="*"/>

    <!-- Initial code -->
    <xsl:template match="IDSs">
    	
	 <!-- ================================ MAIN PROGRAM ================================= -->
        <xsl:text>PROGRAM test&#10;</xsl:text>
	<xsl:text>&#9;use comparator &#10;</xsl:text>
	<xsl:text>&#9;use ids_schemas &#10;</xsl:text>

	<xsl:text>&#9;use helper&#10;</xsl:text>
        <xsl:text>&#9;implicit none&#10;</xsl:text>



    <xsl:text>&#9;INTEGER :: idx;&#10;</xsl:text>
    
        <xsl:text>&#10;</xsl:text>
	

	<!-- READ args
	
	integer::narg,cptArg !#of arg & counter of arg character(len=20)::name !Arg name !Check if any arguments are found narg=command_argument_count()!Loop over the arguments if(narg>0)then!loop across options do cptArg=1,narg
	  call get_command_argument(cptArg,name)   select case(adjustl(name))    case("-help","-h")     write(*,*)"This is program TestArg : Version 0.1"    case default     write(*,*)"Option ",adjustl(name),"unknown"   end select end do end ifend program TestArg
        PROGRAM test_getarg INTEGER :: i CHARACTER(len=32) :: arg DO i = 1, iargc() CALL getarg(i, arg) WRITE (*,*) arg END DO END PROGRAMRead more: http://www.physicsforums.com
	-->
        <xsl:text>&#9;call init(idx);&#10;</xsl:text>
  <!-- <xsl:apply-templates select="child::IDS[@name='temporary']" mode="test"/>   -->
   <xsl:apply-templates select="child::IDS" mode="test"/> 
	
        <xsl:text>&#9;call finish();&#10;</xsl:text>
	
    <xsl:text>CONTAINS&#10;</xsl:text>
	
<!--        <xsl:call-template name="getArrayGenerator"/> -->
 <!--      <xsl:apply-templates select="child::IDS[@name='temporary' or @name='sdn']" mode="put"/>
        <xsl:apply-templates select="child::IDS[@name='temporary' or @name='sdn']" mode="get"/> 
-->
          <xsl:apply-templates select="child::IDS" mode="put"/>
        <xsl:apply-templates select="child::IDS" mode="get"/> 

<!--
         <xsl:apply-templates select="child::IDS[.//field[@type='dynamic'] and @name='temporary']" mode="putSlice"/>
        <xsl:apply-templates select="child::IDS[@name='temporary']" mode="getSlice"/>
-->

    <xsl:apply-templates select="child::IDS[.//field[@type='dynamic']]" mode="putSlice"/>
        <xsl:apply-templates select="child::IDS" mode="getSlice"/>

        <xsl:text>END PROGRAM test&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
	<!-- ================================ MAIN PROGRAM (end)================================= -->
    </xsl:template>

 <!-- ============================= END OF GENRATED FILE ============================== -->

 <!-- ============================= TEMPLATES ============================== -->

        <!--Documentation for a single field-->
    <xsl:template name = "COMMENT_FIELD">
        <xsl:text>&#xA;</xsl:text>
	<xsl:text>&#9;&#9;!!!  </xsl:text><xsl:value-of select="@name"/>:<xsl:value-of select="@path"/>:<xsl:value-of select="@data_type"/>:<xsl:value-of select="@type"/>:<xsl:text>&#xA;</xsl:text>
   
    </xsl:template>

    <xsl:template name="getArrayGenerator">
        <xsl:text>&#9;private static Object getArray(Types t, int length) {&#10;</xsl:text>
        <xsl:text>&#9;&#9;switch (t) {&#10;</xsl:text>
        <xsl:text>&#9;&#9;case DOUBLE:&#10;</xsl:text>
        <xsl:call-template name="generateArray">
            <xsl:with-param name="type" select="'double'"/>
        </xsl:call-template>

        <xsl:text>&#9;&#9;case COMPLEX:&#10;</xsl:text>
        <xsl:call-template name="generateArray">
            <xsl:with-param name="type" select="'UALComplexNumber'"/>
        </xsl:call-template>
   
    <xsl:text>&#9;&#9;case INTEGER:&#10;</xsl:text>
        <xsl:call-template name="generateArray">
            <xsl:with-param name="type" select="'int'"/>
        </xsl:call-template>
        <xsl:text>&#9;&#9;case STRING:&#10;</xsl:text>
        <xsl:call-template name="generateArray">
            <xsl:with-param name="type" select="'String'"/>
        </xsl:call-template>
        <xsl:text>&#9;&#9;default:&#10;</xsl:text>
        <xsl:text>&#9;&#9;&#9;return null;&#10;</xsl:text>
        <xsl:text>&#9;&#9;}&#10;</xsl:text>
        <xsl:text>&#9;}&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>


    <xsl:template name="generateArray">
        <xsl:param name="type"/>
  	       <xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$type"/><xsl:text>[] array</xsl:text><xsl:value-of select="$type"/><xsl:text> = new </xsl:text><xsl:value-of select="$type"/><xsl:text>[length];&#10;</xsl:text>
               <xsl:text>&#9;&#9;&#9;while (--length >= 0)&#10;</xsl:text>
               <xsl:text>&#9;&#9;&#9;&#9;array</xsl:text><xsl:value-of select="$type"/><xsl:text>[length] = get</xsl:text><xsl:value-of select="$type"/><xsl:text>();&#10;</xsl:text>
               <xsl:text>&#9;&#9;&#9;return array</xsl:text><xsl:value-of select="$type"/><xsl:text>;&#10;</xsl:text>        
    </xsl:template>


    <!-- IDS perform the tests -->
 <xsl:template match="IDS" mode="test"> 
        <xsl:text>&#10;</xsl:text>
        <xsl:text>&#9;! --- IDS: </xsl:text><xsl:value-of select="@name"/><xsl:text> ---&#10;</xsl:text>
	
	
	
       <xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_put()&#10;</xsl:text>
       <xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_get()&#10;</xsl:text> 
       <!--   -->
       <!-- Procedure put_slice should exist only for time-dependent IDSs -->  

	<xsl:if test=".//field[@type='dynamic']">  
	
       		<xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_putSlice()&#10;</xsl:text>
       </xsl:if>
       <xsl:text>&#9;call </xsl:text><xsl:value-of select="@name"/><xsl:text>_getSlice()&#10;</xsl:text> 
   
    </xsl:template>

    
    <!-- IDS put()-->
    <xsl:template match="IDS" mode="put">
        <xsl:text>!==================================================================&#10;</xsl:text>
       <xsl:text>!&#9;&#9; PUT </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_put&#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN = *), parameter :: idsName = "</xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
	<xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=20) :: idspath &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: i &#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: tmpInt = -1 &#10;</xsl:text>
        <xsl:text>&#9;WRITE(*,*) "Testing put() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
        <xsl:text>&#9;!CALL srand(seed)&#10;</xsl:text>
	<xsl:text>&#9;CALL random_seed(PUT = seed)&#10;</xsl:text>
        <xsl:text>&#9;do i = 0, </xsl:text><xsl:value-of select="@maxoccur"/><xsl:text> &#10;</xsl:text>
         <xsl:apply-templates select="field" mode="put"/> 
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
       <xsl:text>!&#9;&#9; PUT </xsl:text><xsl:value-of select="@name"/> <xsl:text> &#10;</xsl:text>
       <xsl:text>!==================================================================&#10;</xsl:text>
	<xsl:text>SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_putSlice&#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN = *), parameter :: idsName = "</xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
	<xsl:text>&#9;TYPE (ids_</xsl:text><xsl:value-of select="@name"/><xsl:text>) :: ids &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=20) :: idspath &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: i &#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: tmpInt = -1 &#10;</xsl:text>
        <xsl:text>&#9;WRITE(*,*) "Testing putSlice() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
        <xsl:text>&#9;!CALL srand(seed)&#10;</xsl:text>
        <xsl:text>&#9;CALL random_seed(PUT = seed)&#10;</xsl:text>
        <xsl:text>&#9;do i = 0, </xsl:text><xsl:value-of select="@maxoccur"/><xsl:text> &#10;</xsl:text>
         <xsl:apply-templates select="field" mode="put"/> 
	<xsl:text>&#9;&#9;!------------&#10;</xsl:text>
	<xsl:text>&#9;&#9;if (i == 0) then &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;idspath = idsName  &#10;</xsl:text>
	<xsl:text>&#9;&#9;else&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;WRITE( occurence, '(i2)' )  i &#10;</xsl:text>
        <xsl:text>&#9;&#9;&#9;idspath = idsName//'/'//ADJUSTL(occurence)&#10;</xsl:text>
	<xsl:text>&#9;&#9;end if &#10;</xsl:text>
	<xsl:text>  &#10;</xsl:text>
	
	
        <xsl:text>&#9;&#9;call ids_put_non_timed(idx ,idspath, ids);&#10;</xsl:text>
	<xsl:text>&#9;&#9;call ids_put_slice(idx ,idspath, ids);&#10;</xsl:text>
        
	 <xsl:text>&#9;call ids_deallocate(ids)&#10;</xsl:text> 
	  <xsl:text>&#9;end do &#10;</xsl:text>
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
	<xsl:text>&#9;CHARACTER (LEN=20) :: idspath &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: i &#10;</xsl:text>
        <xsl:text>&#9;WRITE(*,*) "Testing get() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
        <xsl:text>&#9;!CALL srand(seed)&#10;</xsl:text>
	<xsl:text>&#9;CALL random_seed(PUT = seed)&#10;</xsl:text>
        <xsl:text>&#9;do i = 0, </xsl:text><xsl:value-of select="@maxoccur"/><xsl:text> &#10;</xsl:text>

<xsl:text>&#9;&#9;!------------&#10;</xsl:text>
	<xsl:text>&#9;&#9;if (i == 0) then &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;idspath = idsName  &#10;</xsl:text>
	<xsl:text>&#9;&#9;else&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;WRITE( occurence, '(i2)' )  i &#10;</xsl:text>
        <xsl:text>&#9;&#9;&#9;idspath = idsName//'/'//ADJUSTL(occurence)&#10;</xsl:text>
	<xsl:text>&#9;&#9;end if &#10;</xsl:text>
	<xsl:text>  &#10;</xsl:text>
  	
	<xsl:text>&#9;&#9;call ids_get(idx, idspath, ids);&#10;</xsl:text>
	
        <xsl:apply-templates select="field" mode="get"/>
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
	<xsl:text>&#9;CHARACTER (LEN=20) :: idspath &#10;</xsl:text>
	<xsl:text>&#9;CHARACTER (LEN=2) :: occurence = "" &#10;</xsl:text>
	<xsl:text>&#9;INTEGER :: i &#10;</xsl:text>
        <xsl:text>&#9;WRITE(*,*) "Testing getSlice() on </xsl:text><xsl:value-of select="@name"/><xsl:text>"&#10;</xsl:text>
        <xsl:text>&#9;!CALL srand(seed)&#10;</xsl:text>
	<xsl:text>&#9;CALL random_seed(PUT = seed)&#10;</xsl:text>
        <xsl:text>&#9;do i = 0, </xsl:text><xsl:value-of select="@maxoccur"/><xsl:text> &#10;</xsl:text>

<xsl:text>&#9;&#9;!------------&#10;</xsl:text>
	<xsl:text>&#9;&#9;if (i == 0) then &#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;idspath = idsName  &#10;</xsl:text>
	<xsl:text>&#9;&#9;else&#10;</xsl:text>
	<xsl:text>&#9;&#9;&#9;WRITE( occurence, '(i2)' )  i &#10;</xsl:text>
        <xsl:text>&#9;&#9;&#9;idspath = idsName//'/'//ADJUSTL(occurence)&#10;</xsl:text>
	<xsl:text>&#9;&#9;end if &#10;</xsl:text>
	<xsl:text>  &#10;</xsl:text>
  	
	<xsl:text>&#9;&#9;call ids_get_slice(idx ,idspath, ids, 1.0, 1);&#10;</xsl:text>

        <xsl:apply-templates select="field" mode="getSlice"/>
		 <!-- <xsl:text>&#9;call ids_deallocate(ids)&#10;</xsl:text> -->
	  <xsl:text>&#9;end do &#10;</xsl:text>
        <xsl:text>&#9;&#10;</xsl:text>
        <xsl:text>END SUBROUTINE </xsl:text><xsl:value-of select="@name"/><xsl:text>_getSlice&#10;</xsl:text>
	<xsl:text>&#10;</xsl:text>
    </xsl:template>
    
    <!-- field put() -->  
    <xsl:template match="field[not(@data_type='structure' or @data_type='struct_array')]" mode="put">
	  <xsl:variable name="IDS_FIELD_PATH">  <xsl:text>&#9;&#9;ids%</xsl:text><xsl:value-of select="translate(@path, '/', '%')"/></xsl:variable> 
	<xsl:text>&#10;&#9;&#9;!!!</xsl:text><xsl:value-of select="@name"/> : <xsl:value-of select="@path"/> : <xsl:value-of select="@data_type"/><xsl:text>&#10;</xsl:text>
            <xsl:call-template name="setValue">
                <xsl:with-param name="fieldPath" select="concat('ids%',translate(@path, '/', '%'))"/>
            </xsl:call-template>
    </xsl:template>




  <!-- field put() -->  
    <xsl:template match="field[ @data_type='struct_array']" mode="put">
	  <xsl:variable name="IDS_FIELD_PATH">  <xsl:text>&#9;&#9;ids%</xsl:text><xsl:value-of select="translate(@path, '/', '%')"/><xsl:text> = </xsl:text> </xsl:variable> 
	<xsl:text>&#10;&#9;&#9;!!!</xsl:text><xsl:value-of select="@name"/> : <xsl:value-of select="@path"/> : <xsl:value-of select="@data_type"/><xsl:text>&#10;</xsl:text>

        <xsl:call-template name="putStructArray">
            <xsl:with-param name="path" select="concat(translate(@path, '/', '%'), '(1)')"/>
            <xsl:with-param name="resize" select="true()"/>
        </xsl:call-template>

    </xsl:template>


    <xsl:template name="putStructArray">
        <xsl:param name="path"/>
        <xsl:param name="resize"/>
        <xsl:if test="$resize">
		<xsl:text>&#9;&#9;&#9;allocate(ids%</xsl:text><xsl:value-of select="substring($path, 1, string-length($path) - 3)"/><xsl:text> (1))&#10; </xsl:text>
	</xsl:if> 
        <xsl:for-each select="field[not(@data_type='struct_array' or @data_type='structure')]">
	            <xsl:call-template name="setValue">
                <xsl:with-param name="fieldPath" select="concat('ids%', $path, '%', @name)"/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="field[@data_type='structure']">
            <xsl:call-template name="putStructArray">
                <xsl:with-param name="path" select="concat($path, '%', @name)"/>
                <xsl:with-param name="resize" select="false()"/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="field[@data_type='struct_array']">
            <xsl:call-template name="putStructArray">
                <xsl:with-param name="path" select="concat($path, '%', @name, '(1)')"/>
                <xsl:with-param name="resize" select="true()"/>
            </xsl:call-template>
        </xsl:for-each>
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
    	<xsl:call-template name="COMMENT_FIELD"/>      
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
    </xsl:template>



    <!-- field get() for array of structures -->

    <xsl:template match="field[@data_type='struct_array']" mode="get">
        	<xsl:call-template name="COMMENT_FIELD"/> 
			
	<xsl:text>&#9;&#9;if(.not. associated(ids%</xsl:text>  <xsl:value-of select="translate(@path, '/', '%')" /> <xsl:text>)) then &#10;</xsl:text>
		<xsl:text>&#9;&#9;&#9;write(*,*) "ERROR! IDS: </xsl:text> <xsl:value-of select="ancestor::IDS/@name"/> <xsl:text> Field: </xsl:text> <xsl:value-of select="translate(@path, '/', '%')" /> <xsl:text> is not associated!"&#10; </xsl:text>
			<!-- <xsl:text>&#9;&#9;&#9;return &#10;</xsl:text> -->
					<xsl:text>&#9;&#9;&#9;else &#10;</xsl:text>  

        <xsl:call-template name="getStructArray">
            <xsl:with-param name="path" select="concat(translate(@path, '/', '%'), '(1)')"/>
	     <xsl:with-param name="slice" select="false()"/>
        </xsl:call-template>
		<xsl:text>&#9;&#9;end if &#10;</xsl:text> 
    </xsl:template>
    
    
    	        
		 
        <xsl:template match="field[@data_type='struct_array']" mode="getSlice">
        	<xsl:call-template name="COMMENT_FIELD"/> 
			
	<xsl:text>&#9;&#9;if(.not. associated(ids%</xsl:text>  <xsl:value-of select="translate(@path, '/', '%')" /> <xsl:text>)) then &#10;</xsl:text>
		<xsl:text>&#9;&#9;&#9;write(*,*) "ERROR! IDS: </xsl:text> <xsl:value-of select="ancestor::IDS/@name"/> <xsl:text> Field: </xsl:text> <xsl:value-of select="translate(@path, '/', '%')" /> <xsl:text> is not associated!"&#10; </xsl:text>
			<!-- <xsl:text>&#9;&#9;&#9;return &#10;</xsl:text> -->
					<xsl:text>&#9;&#9;&#9;else &#10;</xsl:text>  

        <xsl:call-template name="getStructArray">
            <xsl:with-param name="path" select="concat(translate(@path, '/', '%'), '(1)')"/>
	     <xsl:with-param name="slice" select="true()"/>
        </xsl:call-template>
		<xsl:text>&#9;&#9;end if &#10;</xsl:text> 
    </xsl:template>

    

    <xsl:template name="getStructArray">
        <xsl:param name="path"/>
	<xsl:param name="slice"/>
        <xsl:for-each select="field[not(@data_type='struct_array' or @data_type='structure')]">
	
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
        
          
        </xsl:for-each>
	
	
	
        <xsl:for-each select="field[@data_type='structure']">
	<xsl:call-template name="COMMENT_FIELD"/>
            <xsl:call-template name="getStructArray">
                <xsl:with-param name="path" select="concat($path, '%', @name)"/>
			   <xsl:with-param name="slice" select="$slice"/>
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
            </xsl:call-template>
	<xsl:text>&#9;&#9;end if &#10;</xsl:text> 
        </xsl:for-each>
    </xsl:template> 


    <xsl:template name="setValue">
            <xsl:param name="fieldPath"/>
	     
        <xsl:choose>
	
	      <xsl:when test="@name='homogeneous_time'">          
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/> <xsl:text>= 1&#10;</xsl:text>
	    </xsl:when>
	    
           <!-- <xsl:when test="@name='time'">          
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/> <xsl:text>= getTime()&#10;</xsl:text>
	    </xsl:when>
-->
            <xsl:when test="@data_type='str_type' or @data_type='STR_0D'"> 
	        	     	<xsl:text>&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(1)) &#10;</xsl:text>        
	    		 <xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/> <xsl:text> = getString()&#10;</xsl:text> 
	    		<!-- <xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/> <xsl:text>(1) = 'abc123' &#10;</xsl:text> -->
	    </xsl:when>
            <xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">  
    	<xsl:text>&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(1)) &#10;</xsl:text>
	    <xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/>     <xsl:text> = getString()&#10;</xsl:text>
	   </xsl:when>

            <xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">            	
	   	<xsl:text>&#9;&#9;&#9;</xsl:text>  <xsl:value-of select="$fieldPath"/> <xsl:text> = getDouble()&#10;</xsl:text>
	    </xsl:when>
	    
	
          <xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">  
	    	     	<xsl:text>&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE)) &#10;</xsl:text>
	             	<xsl:text>&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getDouble1DArray(DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>
             <xsl:when test="@data_type='flt_2d_type' or @data_type='FLT_2D'">        
	    	<xsl:text>&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE)) &#10;</xsl:text>
	       		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getDouble2DArray(DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
	</xsl:when>
      
	   <xsl:when test="@data_type='FLT_3D'">     
	    	    	<xsl:text>&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE, DIM_SIZE)) &#10;</xsl:text> 
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getDouble3DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
		</xsl:when>
            <xsl:when test="@data_type='FLT_4D'">      	
	    	    	    	<xsl:text>&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) &#10;</xsl:text> 
	    	<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getDouble4DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>
            <xsl:when test="@data_type='FLT_5D'">     
	    	   	 <xsl:text>&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) &#10;</xsl:text> 
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/> <xsl:text> = getDouble5DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>
            <xsl:when test="@data_type='FLT_6D'">      
	    	    	    	    	    	<xsl:text>&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) &#10;</xsl:text> 
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getDouble6DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>

             <xsl:when test="@data_type='int_type' or @data_type='INT_0D'">  
	     		<xsl:text>&#9;&#9;&#9;tmpInt = getInteger()&#10;</xsl:text>
	           		<!-- <xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/> <xsl:text>= getInteger()&#10;</xsl:text> -->
			 <xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/> <xsl:text>= tmpInt&#10;</xsl:text>
	     	<!--	<xsl:text>&#9;&#9;&#9;write(*,*) "</xsl:text><xsl:value-of select="$fieldPath"/> <xsl:text>", tmpInt&#10;</xsl:text>  -->
	    </xsl:when>
	
             <xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">        
	        	     	<xsl:text>&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE)) &#10;</xsl:text>
	      		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getInteger1DArray(DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>
      
	    <xsl:when test="@data_type='INT_2D'">        
	    <xsl:text>&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE)) &#10;</xsl:text>
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getInteger2DArray(DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>
             <xsl:when test="@data_type='INT_3D'"> 
	    	    	    	<xsl:text>&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE, DIM_SIZE)) &#10;</xsl:text>      
	    		<xsl:text>&#9;&#9;&#9;</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text> = getInteger3DArray(DIM_SIZE, DIM_SIZE, DIM_SIZE)&#10;</xsl:text>
	    </xsl:when>
            <xsl:when test="@data_type='INT_4D'"> 
	    	    	    	    	<xsl:text>&#9;&#9;allocate(</xsl:text><xsl:value-of select="$fieldPath"/><xsl:text>(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) &#10;</xsl:text>   
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
	  
	  <xsl:when test="@name='time' and $slice and (@data_type='flt_1d_type' or @data_type='FLT_1D')"><xsl:text>getDouble1DArray(1)</xsl:text></xsl:when>
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
