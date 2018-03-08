<?xml version="1.0" encoding="UTF-8"?>
<?modxslt-stylesheet type="text/xsl" media="fuffa, screen and $GET[stylesheet]" href="./%24GET%5Bstylesheet%5D" alternate="no" title="Translation using provided stylesheet" charset="ISO-8859-1" ?>
<?modxslt-stylesheet type="text/xsl" media="screen" alternate="no" title="Show raw source of the XML file" charset="ISO-8859-1" ?>
<xsl:stylesheet xmlns:yaslt="http://www.mod-xslt2.com/ns/2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" extension-element-prefixes="yaslt" xmlns:fn="http://www.w3.org/2005/02/xpath-functions" xmlns:local="http://www.example.com/functions/local" exclude-result-prefixes="local xs">
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>	<!-- This XSL translates the list of IMAS IDSDefs to Fortran 90 GET/PUT Routines for IDSs -->

<xsl:function name="local:unique_name" as="xs:string">
  <!-- Provides pseudo-unique 16 characters reference to arbitrary long field name  -->
  <xsl:param name="FullName" as="xs:string"/>
<!--  <xsl:variable name="result" as="xs:string">-->
    <xsl:choose>
      <xsl:when test="string-length($FullName) &lt; 16">
	<xsl:value-of select="$FullName"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="concat(lower-case(substring($FullName,1,15)), sum(string-to-codepoints(lower-case(substring($FullName,16)))))"/>
      </xsl:otherwise>
    </xsl:choose>
<!--  </xsl:variable>
  <xsl:value-of select="$result"/>-->
</xsl:function>

<xsl:template match="/IDSs">
  <xsl:result-document href="ids_routines.f90">
module ids_routines
use ids_schemas
use ual_low_level_wrap
use utilities_copy_struct
use utilities_deallocate_struct

<xsl:for-each select="IDS">
use <xsl:value-of select="@name"/>_ids_module_put
use <xsl:value-of select="@name"/>_ids_module_put_slice
use <xsl:value-of select="@name"/>_ids_module_put_non_timed
use <xsl:value-of select="@name"/>_ids_module_get
use <xsl:value-of select="@name"/>_ids_module_get_slice
use <xsl:value-of select="@name"/>_copy
use <xsl:value-of select="@name"/>_copy_struct
use <xsl:value-of select="@name"/>_deallocate_struct
</xsl:for-each>

contains

subroutine ids_get_times(pulseCtx,path,time)
use ual_low_level_wrap
use ids_types
implicit none

integer(ids_int) :: pulsectx, opctx, status
character*(*) :: path
real(ids_real), pointer :: time(:)
integer(ids_int) :: dim1

call begin_IDS_get(pulsectx, path, opctx) 
if (opctx.lt.0) then
   STOP 'Error in begin_ids_get from ids_get_times'
end if

call get_vect1d_double(opctx, "time", "time", time, dim1, status)

call ual_end_action(opctx, status)

end subroutine
end module
</xsl:result-document>

<xsl:apply-templates select="/IDSs/utilities" mode="deallocate_struct"/> 
<xsl:apply-templates select="IDS" mode="deallocate_struct"/> 

<xsl:apply-templates select="/IDSs/utilities" mode="copy_struct"/> 
<xsl:apply-templates select="IDS" mode="copy_struct"/> 

<xsl:apply-templates select="IDS" mode="main"/>

</xsl:template>



<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_DEALLOCATE MODULE, UTILITIES                                        -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="utilities" mode="deallocate_struct">
  <xsl:result-document href="utilities_deallocate_struct.f90">
module utilities_deallocate_struct

interface ids_deallocate
  <xsl:for-each select="/IDSs/utilities/field[@data_type='structure' or @data_type='struct_array']">
  <xsl:variable name="this-type">
    <xsl:choose>
      <xsl:when test="@structure_reference='self'">
	<xsl:value-of select="@name"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="@structure_reference"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  module procedure ids_deallocate_struct_<xsl:value-of select="local:unique_name($this-type)"/>
  </xsl:for-each>
end interface

 contains

<xsl:for-each select="/IDSs/utilities//field[@data_type='structure' or @data_type='struct_array']">
  <xsl:variable name="this-name" select="@name"/>
  <xsl:variable name="this-type">
    <xsl:choose>
      <xsl:when test="@structure_reference='self'">
	<xsl:value-of select="@name"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="@structure_reference"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:if test="not (preceding::field[@structure_reference=$this-type or @name=$this-type])">

subroutine ids_deallocate_struct_<xsl:value-of select="local:unique_name($this-type)"/>(struct_in,  c_data)
  use ual_low_level_wrap
  use, intrinsic :: ISO_C_BINDING, only: C_LOC
  use ids_schemas
  implicit none

  integer(ids_int) :: i
  logical, intent(in) :: c_data
  type(ids_<xsl:value-of select="$this-type"/>) :: struct_in

  <xsl:apply-templates select="./field" mode="DEALLOCATE_FIELD">
    <xsl:with-param name="idxpath" select="''"/>
  </xsl:apply-templates>
end subroutine ids_deallocate_struct_<xsl:value-of select="local:unique_name($this-type)"/>

  </xsl:if>
</xsl:for-each>

end module    
  </xsl:result-document>
</xsl:template>



<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_DEALLOCATE MODULE, PER IDS                                          -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="IDS" mode="deallocate_struct">
  <xsl:result-document href="{@name}_deallocate_struct.f90">
module <xsl:value-of select="@name"/>_deallocate_struct

use utilities_deallocate_struct

interface ids_deallocate
  module procedure ids_deallocate_struct_<xsl:value-of select="@name"/> <!-- subroutine for the whole IDS -->
  <xsl:for-each select=".//field[@data_type='structure' or @data_type='struct_array']">
    <xsl:variable name="this-name" select="@name"/>
    <xsl:variable name="this-type">
      <xsl:choose>
	<xsl:when test="@structure_reference='self'">
	  <xsl:value-of select="@name"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="@structure_reference"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="this-ids" select="ancestor::IDS/@name"/>
    <xsl:if test="not (preceding::field[@structure_reference=$this-type and ancestor::IDS/@name=$this-ids] or /IDSs/utilities/field/@name=$this-type)">
  module procedure ids_deallocate_struct_<xsl:value-of select="local:unique_name($this-type)"/>
    </xsl:if>
  </xsl:for-each>
end interface

 contains 

<!-- subroutine for the whole IDS -->
subroutine ids_deallocate_struct_<xsl:value-of select="@name"/>(struct_in)
  use ual_low_level_wrap
  use, intrinsic :: ISO_C_BINDING, only: C_LOC
  use ids_schemas
  implicit none

  integer(ids_int) :: i
  logical :: c_data
  type(ids_<xsl:value-of select="@name"/>) :: struct_in

  call is_c_data(struct_in, c_data)

  <xsl:apply-templates select="./field" mode="DEALLOCATE_FIELD">
    <xsl:with-param name="idxpath" select="''"/>
  </xsl:apply-templates>
  call set_c_data(struct_in, c_data)
end subroutine ids_deallocate_struct_<xsl:value-of select="@name"/>

<xsl:for-each select=".//field[@data_type='structure' or @data_type='struct_array']">
  <xsl:variable name="this-name" select="@name"/>
  <xsl:variable name="this-type">
    <xsl:choose>
      <xsl:when test="@structure_reference='self'">
	<xsl:value-of select="@name"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="@structure_reference"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="this-ids" select="ancestor::IDS/@name"/>
  <xsl:if test="not (preceding::field[@structure_reference=$this-type and ancestor::IDS/@name=$this-ids] or /IDSs/utilities/field/@name=$this-type)">

subroutine ids_deallocate_struct_<xsl:value-of select="local:unique_name($this-type)"/>(struct_in,  c_data)
  use ual_low_level_wrap
  use, intrinsic :: ISO_C_BINDING, only: C_LOC
  use ids_schemas
  implicit none

  integer(ids_int) :: i
  logical, intent(in) :: c_data
  type(ids_<xsl:value-of select="$this-type"/>) :: struct_in

  <xsl:apply-templates select="./field" mode="DEALLOCATE_FIELD">
    <xsl:with-param name="idxpath" select="''"/>
  </xsl:apply-templates>
end subroutine ids_deallocate_struct_<xsl:value-of select="local:unique_name($this-type)"/>
  </xsl:if>
</xsl:for-each>

end module    
  </xsl:result-document>
</xsl:template>



<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_COPY MODULE, UTILITIES                                              -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="utilities" mode="copy_struct">
  <xsl:result-document href="utilities_copy_struct.f90">
module utilities_copy_struct

interface ids_copy
  <xsl:for-each select="/IDSs/utilities/field[@data_type='structure' or @data_type='struct_array']">
  <xsl:variable name="this-type">
    <xsl:choose>
      <xsl:when test="@structure_reference='self'">
	<xsl:value-of select="@name"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="@structure_reference"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  module procedure ids_copy_struct_<xsl:value-of select="local:unique_name($this-type)"/>
  </xsl:for-each>
end interface    

 contains

<xsl:for-each select="/IDSs/utilities//field[@data_type='structure' or @data_type='struct_array']">
  <xsl:variable name="this-name" select="@name"/>
  <xsl:variable name="this-type">
    <xsl:choose>
      <xsl:when test="@structure_reference='self'">
	<xsl:value-of select="@name"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="@structure_reference"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:if test="not (preceding::field[@structure_reference=$this-type or @name=$this-type])">

subroutine ids_copy_struct_<xsl:value-of select="local:unique_name($this-type)"/>(struct_in,  struct_out)
  ! Copies all fields of struct_in to struct_out
  ! Assumes that struct_in is a single instance of a given structure
  use ids_schemas
  implicit none

  integer(ids_int) :: i

  type(ids_<xsl:value-of select="$this-type"/>) :: struct_in, struct_out

  <xsl:apply-templates select="./field" mode="COPY_FIELD">
    <xsl:with-param name="idxpath" select="''"/>
  </xsl:apply-templates>
  return
end subroutine ids_copy_struct_<xsl:value-of select="local:unique_name($this-type)"/>
  </xsl:if>
</xsl:for-each>

end module    
  </xsl:result-document>  
</xsl:template>



<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_COPY MODULE, PER IDS                                                -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="IDS" mode="copy_struct">
  <xsl:result-document href="{@name}_copy_struct.f90">
module <xsl:value-of select="@name"/>_copy_struct

use utilities_copy_struct

interface ids_copy
  module procedure ids_copy_struct_<xsl:value-of select="@name"/> <!-- subroutine for the whole IDS -->
  <xsl:for-each select=".//field[@data_type='structure' or @data_type='struct_array']">
    <xsl:variable name="this-name" select="@name"/>
    <xsl:variable name="this-type">
      <xsl:choose>
	<xsl:when test="@structure_reference='self'">
	  <xsl:value-of select="@name"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="@structure_reference"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!--<xsl:variable name="this-type" select="@structure_reference"/>-->
    <xsl:variable name="this-ids" select="ancestor::IDS/@name"/>
    <xsl:if test="not (preceding::field[@structure_reference=$this-type and ancestor::IDS/@name=$this-ids] or /IDSs/utilities/field/@name=$this-type)">
  module procedure ids_copy_struct_<xsl:value-of select="local:unique_name($this-type)"/> 
    </xsl:if>
  </xsl:for-each>
end interface 

 contains

<!-- subroutine for the whole IDS -->
subroutine ids_copy_struct_<xsl:value-of select="@name"/>(struct_in, struct_out)
  ! Copies all fields of struct_in to struct_out
  ! Assumes that struct_in is a single instance of a given structure
  use ids_schemas
  implicit none

  integer(ids_int) :: i

  type(ids_<xsl:value-of select="@name"/>) :: struct_in, struct_out

  <xsl:apply-templates select="./field" mode="COPY_FIELD">
    <xsl:with-param name="idxpath" select="''"/>
  </xsl:apply-templates>
  return
end subroutine ids_copy_struct_<xsl:value-of select="@name"/>

<xsl:for-each select=".//field[@data_type='structure' or @data_type='struct_array']">
  <xsl:variable name="this-name" select="@name"/>
  <xsl:variable name="this-type">
    <xsl:choose>
      <xsl:when test="@structure_reference='self'">
	<xsl:value-of select="@name"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="@structure_reference"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="this-ids" select="ancestor::IDS/@name"/>
  <xsl:if test="not (preceding::field[@structure_reference=$this-type and ancestor::IDS/@name=$this-ids] or /IDSs/utilities/field/@name=$this-type)">

subroutine ids_copy_struct_<xsl:value-of select="local:unique_name($this-type)"/>(struct_in,  struct_out)
  ! Copies all fields of struct_in to struct_out
  ! Assumes that struct_in is a single instance of a given structure
  use ids_schemas
  implicit none

  integer(ids_int) :: i

  type(ids_<xsl:value-of select="$this-type"/>) :: struct_in, struct_out

  <xsl:apply-templates select="./field" mode="COPY_FIELD">
    <xsl:with-param name="idxpath" select="''"/>
  </xsl:apply-templates>
  return
end subroutine ids_copy_struct_<xsl:value-of select="local:unique_name($this-type)"/>
  </xsl:if>
</xsl:for-each>

end module    
  </xsl:result-document>
</xsl:template>




<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_DEALLOCATE TEMPLATE                                                 -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="field" mode="DEALLOCATE_FIELD">
  <xsl:param name="idxpath"/>   
  <!-- build the complete path of the current field -->
  <xsl:param name="currentidxpath" select="concat($idxpath,'%',@name)"/>

  <xsl:choose>

    <!-- Case of a struct array -->
    <xsl:when test="@data_type='struct_array'">  
  ! deallocate <xsl:value-of select="$currentidxpath"/>
  if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
    do i = 1,size(struct_in<xsl:value-of select = "$currentidxpath"/>)
      call ids_deallocate_struct_<xsl:value-of select="local:unique_name(@structure_reference)"/>(struct_in<xsl:value-of select = "$currentidxpath"/>(i),c_data)
    enddo
    deallocate(struct_in<xsl:value-of select="$currentidxpath"/>)
  endif
    </xsl:when>

    <!-- Case of a struct array -->
    <xsl:when test="@data_type='structure'">  
  call ids_deallocate_struct_<xsl:value-of select="local:unique_name(@structure_reference)"/>(struct_in<xsl:value-of select = "$currentidxpath"/>,c_data)
    </xsl:when>

    <!-- Case of a string data, only Fortran string is there (C array was copied) -->
    <xsl:when test="@data_type='str_type' or @data_type='STR_0D' or @data_type='str_1d_type' or @data_type='STR_1D'"> 
  ! deallocate <xsl:value-of select="$currentidxpath"/>
  if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
    deallocate(struct_in<xsl:value-of select="$currentidxpath"/>)
  endif
    </xsl:when>

    <!-- Case of all other vector data -->
    <xsl:when test="@data_type='flt_1d_type' or @data_type='int_1d_type' or
		    @data_type='flt_2d_type' or @data_type='int_2d_type' or 
		    @data_type='FLT_1D' or @data_type='INT_1D' or 
		    @data_type='FLT_2D' or @data_type='INT_2D' or 
		    @data_type='FLT_3D' or @data_type='INT_3D' or 
		    @data_type='FLT_4D' or @data_type='INT_4D' or 
		    @data_type='FLT_5D' or @data_type='INT_5D' or 
		    @data_type='FLT_6D' or @data_type='INT_6D'">
  ! deallocate <xsl:value-of select="$currentidxpath"/>
  if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
    if (c_data) then
      call c_free(C_LOC(struct_in<xsl:value-of select="$currentidxpath"/>))
    else
      deallocate(struct_in<xsl:value-of select="$currentidxpath"/>)
    endif
  endif
    </xsl:when>

    <!-- Case of scalar data (just to differenciate with errors "otherwise") -->
    <xsl:when test="@data_type='int_type' or @data_type='INT_0D' or 
		    @data_type='flt_type' or @data_type='FLT_0D'">
    </xsl:when>

    <!-- Error case: could throw error or generate code that can't compile? -->
    <xsl:otherwise>
  ! Deallocate <xsl:value-of select="$currentidxpath"/> : PROBLEM: UNIDENTIFIED TYPE !!!
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>




<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_COPY TEMPLATE                                                       -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="field" mode="COPY_FIELD">
  <xsl:param name="idxpath"/>   <!-- passed current path -->
  <!-- build the complete path of the current field -->
  <xsl:param name="currentidxpath" select="concat($idxpath,'%',@name)"/>

  <xsl:choose>

    <!-- Case of a struct array -->
    <xsl:when test="@data_type='struct_array'">  
  ! Copy <xsl:value-of select="$currentidxpath"/>
  if (associated(struct_in<xsl:value-of select = "$currentidxpath"/>)) then  
    allocate(struct_out<xsl:value-of select="$currentidxpath"/>(size(struct_in<xsl:value-of select = "$currentidxpath"/>)))
    do i = 1,size(struct_in<xsl:value-of select = "$currentidxpath"/>)
      call ids_copy_struct_<xsl:value-of select="local:unique_name(@structure_reference)"/>(struct_in<xsl:value-of select = "$currentidxpath"/>(i), struct_out<xsl:value-of select = "$currentidxpath"/>(i))
    enddo
  endif
    </xsl:when>

    <!-- Case of a simple structure -->
    <xsl:when test="@data_type='structure'">  
  call ids_copy_struct_<xsl:value-of select="local:unique_name(@structure_reference)"/>(struct_in<xsl:value-of select = "$currentidxpath"/>, struct_out<xsl:value-of select = "$currentidxpath"/>)
    </xsl:when>

    <!-- 0D scalar, integer data -->
    <xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
  ! Copy <xsl:value-of select="$currentidxpath"/>
  if (struct_in<xsl:value-of select="$currentidxpath"/>/=ids_int_invalid)  then
    struct_out<xsl:value-of select="$currentidxpath"/> = &amp;
    struct_in<xsl:value-of select="$currentidxpath"/>
  endif
    </xsl:when>

    <!-- 0D scalar, float data -->
    <xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
  ! Copy <xsl:value-of select="$currentidxpath"/>
  if (struct_in<xsl:value-of select="$currentidxpath"/>.NE.ids_real_invalid) then
    struct_out<xsl:value-of select="$currentidxpath"/> = &amp;
    struct_in<xsl:value-of select="$currentidxpath"/>
  endif
    </xsl:when>

    <!-- 1D vector data -->
    <xsl:when test="@data_type='STR_0D' or @data_type='STR_1D' or 
		    @data_type='str_type' or @data_type='str_1d_type' or 
		    @data_type='FLT_1D' or @data_type='INT_1D' or 
		    @data_type='flt_1d_type' or @data_type='int_1d_type'">
  ! Copy <xsl:value-of select="$currentidxpath"/>
  if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
    allocate(struct_out<xsl:value-of select="$currentidxpath"/>&amp;
       (size(struct_in<xsl:value-of select="$currentidxpath"/>,1)))
    struct_out<xsl:value-of select="$currentidxpath"/> = &amp;
    struct_in<xsl:value-of select="$currentidxpath"/>
  endif
    </xsl:when>

    <!-- 2D vector data -->
    <xsl:when test="@data_type='int_2d_type' or @data_type='INT_2D' or 
		    @data_type='flt_2d_type' or @data_type='FLT_2D'">
  ! Copy <xsl:value-of select="$currentidxpath"/>
  if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
    allocate(struct_out<xsl:value-of select="$currentidxpath"/>&amp;
       (size(struct_in<xsl:value-of select="$currentidxpath"/>,1), &amp;
       size(struct_in<xsl:value-of select="$currentidxpath"/>,2)))
    struct_out<xsl:value-of select="$currentidxpath"/> = &amp;
    struct_in<xsl:value-of select="$currentidxpath"/>
  endif
    </xsl:when>

    <!-- 3D vector data -->
    <xsl:when test="@data_type='INT_3D' or @data_type='FLT_3D'">
  ! Copy <xsl:value-of select="$currentidxpath"/>
  if (associated(struct_in<xsl:value-of select="$currentidxpath"/>)) then
    allocate(struct_out<xsl:value-of select="$currentidxpath"/>&amp;
       (size(struct_in<xsl:value-of select="$currentidxpath"/>,1), &amp;
       size(struct_in<xsl:value-of select="$currentidxpath"/>,2), &amp;
       size(struct_in<xsl:value-of select="$currentidxpath"/>,3)))
    struct_out<xsl:value-of select="$currentidxpath"/> = &amp;
    struct_in<xsl:value-of select="$currentidxpath"/>
  endif
    </xsl:when>

    <!-- 4D vector data -->
    <xsl:when test="@data_type='INT_4D' or @data_type='FLT_4D'">
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
    </xsl:when>

    <!-- 5D vector data -->
    <xsl:when test="@data_type='INT_5D' or @data_type='FLT_5D'">
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
    </xsl:when>

    <!-- 6D vector data -->
    <xsl:when test="@data_type='INT_6D' or @data_type='FLT_6D'">
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
    </xsl:when>

    <!-- Error case: could throw error or generate code that can't compile? -->
    <xsl:otherwise>
  ! Copy <xsl:value-of select="$currentidxpath"/> : PROBLEM: UNIDENTIFIED TYPE !!! 
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>




<xsl:template match="IDS" mode="main">
   
   <!-- ======================================  PUT ======================================= -->
   <xsl:result-document href="{@name}_put.f90">
module <xsl:value-of select="@name"/>_ids_module_put
! Declaration of the generic IDS PUT routine
interface ids_put
   module procedure ids_put_<xsl:value-of select="@name"/>
end interface ids_put

character(len=3)::ual_debug

contains

  character(10) function int2str(num)
    use ids_types
    integer(ids_int), intent(in):: num
    character(10) :: str
    ! convert integer to string using formatted write
    write(str, '(i10)') num
    int2str = adjustl(str)
  end function int2str

<xsl:call-template name="isCriticalFunc"/>


!!!!!! Routines to PUT the full IDS
subroutine ids_put_<xsl:value-of select="@name"/>(pulsectx, path, IDS)
use ids_schemas
use ual_low_level_wrap
use <xsl:value-of select="@name"/>_copy  ! Needed since the _copy module contains the ids_delete routines
implicit none
integer(ids_int) :: status = 0
character*(*) :: path
integer(ids_int) :: pulsectx, opctx
type(ids_<xsl:value-of select="@name"/>) :: IDS
! internal variables declaration
integer(ids_int) :: homogeneous_time
integer(ids_int) :: dim1,dim2,dim3,dim4,dim5,dim6,dim7, lenstring
character(len=100000)::longstring
character(len=300) :: timepath
integer(ids_int) :: aosctx1,aosctx2,aosctx3,aosctx4,aosctx5,aosctx6,aosctx7
integer(ids_int) :: i1,i2,i3,i4,i5,i6,i7

call getenv('ual_debug',ual_debug) ! Debug flag

! Systematic delete of the previous IDS, in case it existed
call ids_delete(pulsectx,path,IDS)

<xsl:if test=".//field[@type='dynamic']"> <!-- if there is dynamic data in the IDS, check that the the IDS%time vector of an homogeneous_time IDS is associated -->
homogeneous_time = IDS%ids_properties%homogeneous_time
if (homogeneous_time.EQ.ids_int_invalid) then
   write(*,*) "ERROR : the IDS%ids_properties%homogeneous_time property of this IDS must be provided"
   return
endif
if ((homogeneous_time.EQ.1).AND.(.NOT.(associated(IDS%time)))) then
   write(*,*) "ERROR : the IDS%time vector of an homogeneous_time IDS must be associated"
   return
endif
</xsl:if>

call begin_ids_put_timed(pulsectx, path, opctx)
    if (opctx.lt.0) then
       STOP 'Error in begin_ids_put_timed (from ids_put for IDS <xsl:value-of select="@name"/>)'
    end if
    
<xsl:apply-templates select="field" mode="PUT_SINGLE">
  <xsl:with-param name="variable_path" select="'IDS'"/>
  <!--<xsl:with-param name="mds_path" select="'&quot;&quot;'"/>-->
</xsl:apply-templates>

call ual_end_action(opctx, status)

return
end subroutine ids_put_<xsl:value-of select="@name"/>

end module <xsl:value-of select="@name"/>_ids_module_put
</xsl:result-document>


<!-- ======================================  PUT NON TIMED ======================================= -->
<xsl:result-document href="{@name}_put_non_timed.f90">
module <xsl:value-of select="@name"/>_ids_module_put_non_timed
! Declaration of the generic IDS PUT_NON_TIMED routine
interface ids_put_non_timed
   module procedure ids_put_non_timed_<xsl:value-of select="@name"/>
end interface ids_put_non_timed

character(len=3)::ual_debug

contains

<xsl:call-template name="isCriticalFunc"/>


!!!!!! Routines to PUT_NON_TIMED the time INdependent data of time dependent IDSs
subroutine ids_put_non_timed_<xsl:value-of select="@name"/>(pulsectx, path, IDS)
use ids_schemas
use ual_low_level_wrap
use <xsl:value-of select="@name"/>_copy  ! Needed since the _copy module contains the ids_delete routines
implicit none

character*(*) :: path
integer(ids_int) :: pulsectx, opctx
integer(ids_int) :: status = 0
integer(ids_int) :: dim1,dim2,dim3,dim4,dim5,dim6,dim7, lenstring
character(len=100000)::longstring
character(len=300) :: timepath
integer(ids_int) :: aosctx1,aosctx2,aosctx3,aosctx4,aosctx5,aosctx6,aosctx7
integer(ids_int) :: i1,i2,i3,i4,i5,i6,i7
type(ids_<xsl:value-of select="@name"/>) :: IDS       ! real declaration of the IDS for the put

call getenv('ual_debug',ual_debug) ! Debug flag

! Systematic delete of the previous IDS, in case it existed; guarantees the time-dependent data is deleted
call ids_delete(pulsectx,path,IDS)

<xsl:if test=".//field[@type='dynamic']"> <!-- if there is dynamic data in the IDS, check that the the IDS%ids_properties%time is provided (since it will be filled by this put_non_timed routine !) -->
if (IDS%ids_properties%homogeneous_time.EQ.ids_int_invalid) then
   write(*,*) "ERROR : the IDS%ids_properties%homogeneous_time property of this IDS must be provided"
   return
endif
</xsl:if>

call begin_IDS_put_non_timed(pulsectx, path, opctx)
if (opctx.lt.0) then
    !! error when trying to get new ctx => stop!
    STOP 'Error in begin_IDS_put_non_timed (from ids_put_non_timed for IDS <xsl:value-of select="@name"/>)'
end if

<xsl:apply-templates select="field" mode="PUT_SINGLE">
  <xsl:with-param name="variable_path" select="'IDS'"/>
  <!--<xsl:with-param name="mds_path" select="'&quot;&quot;'"/>-->
  <xsl:with-param name="non_timed" select="yes"/>
</xsl:apply-templates>

call ual_end_action(opctx, status)

return
end subroutine ids_put_non_timed_<xsl:value-of select="@name"/>

end module <xsl:value-of select="@name"/>_ids_module_put_non_timed
</xsl:result-document>


<!-- ======================================  PUT SLICE ======================================= -->
<xsl:result-document href="{@name}_put_slice.f90">
module <xsl:value-of select="@name"/>_ids_module_put_slice
<xsl:if test=".//field[@type='dynamic']"> <!-- Procedure put_slice should exist only for time-dependent IDSs -->
! Declaration of the generic IDS PUT_SLICE routine
interface ids_put_slice
   module procedure ids_put_slice_<xsl:value-of select="@name"/>
end interface ids_put_slice
</xsl:if >

character(len=3)::ual_debug

contains

<xsl:call-template name="isCriticalFunc"/>


<xsl:if test=".//field[@type='dynamic']"> <!-- Procedure put_slice should exist only for time-dependent IDSs -->
!!!!!! Routines to PUT_SLICE one time slice of a time-dependent IDS (affects only time-dependent fields)
subroutine ids_put_slice_<xsl:value-of select="@name"/>(pulsectx,path,IDS)
use ids_schemas
use ual_low_level_wrap
implicit none

character*(*) :: path
integer(ids_int) :: pulsectx, opctx
integer(ids_int) :: status = 0
type(ids_<xsl:value-of select="@name"/>) :: IDS
! internal variables declaration
integer(ids_int) :: homogeneous_time
integer(ids_int) :: i,dim1,dim2,dim3,dim4,dim5,dim6,dim7, lenstring
character(len=100000)::longstring
character(len=300)::timepath
integer(ids_int) :: aosctx1,aosctx2,aosctx3,aosctx4,aosctx5,aosctx6,aosctx7
integer(ids_int) :: i1,i2,i3,i4,i5,i6,i7

call getenv('ual_debug',ual_debug) ! Debug flag

homogeneous_time = IDS%ids_properties%homogeneous_time
if (IDS%IDS_Properties%homogeneous_time.NE.1) then
   write(*,*) "ERROR : the PUT_SLICE routine works only for homogeneous time IDS: check ids_properties%homogeneous_time"
   return
endif

if (.NOT.(associated(IDS%time))) then
   write(*,*) "ERROR : the ids%time vector of an homogeneous_time IDS must be associated"
   return
endif

timepath = "time"
call begin_ids_put_slice(pulsectx, path, IDS%time(1), opctx)
if (opctx.lt.0) then
   !! error when trying to get new ctx => stop!
   STOP 'Error in begin_ids_put_slice (from ids_put_slice for IDS <xsl:value-of select="@name"/>)'
end if

<xsl:apply-templates select="field" mode="PUT_SINGLE">
  <xsl:with-param name="variable_path" select="'IDS'"/>
  <!--<xsl:with-param name="mds_path" select="'&quot;&quot;'"/>-->
  <xsl:with-param name="slice" select="yes"/>
</xsl:apply-templates>

call ual_end_action(opctx, status)

return
end subroutine ids_put_slice_<xsl:value-of select="@name"/>
</xsl:if>



end module <xsl:value-of select="@name"/>_ids_module_put_slice
</xsl:result-document>




<!-- ======================================  GET ======================================= -->
<xsl:result-document href="{@name}_get.f90">
module <xsl:value-of select="@name"/>_ids_module_get
! Declaration of the generic IDS GET routine
interface ids_get
   module procedure ids_get_<xsl:value-of select="@name"/>
end interface ids_get

character(len=3)::ual_debug

contains

<xsl:call-template name="isCriticalFunc"/>


!!!!!! Routines to GET the full IDS
subroutine ids_get_<xsl:value-of select="@name"/>(pulsectx, path, IDS)
use ids_schemas
use ual_low_level_wrap
implicit none

character*(*) :: path
integer(ids_int) :: pulsectx, opctx, status = 0, lenstring 
character(len=100000)::longstring
character(len=300) :: timepath
integer(ids_int) :: homogeneous_time
integer(ids_int) :: aosctx1,aosctx2,aosctx3,aosctx4,aosctx5,aosctx6,aosctx7
integer(ids_int) :: dim1,dim2,dim3,dim4,dim5,dim6,dim7
integer(ids_int) :: size1,size2,size3,size4,size5,size6,size7
integer(ids_int) :: i1,i2,i3,i4,i5,i6,i7
type(ids_<xsl:value-of select="@name"/>) :: IDS

call getenv('ual_debug',ual_debug) ! Debug flag

call begin_IDS_get(pulsectx, path, opctx) ! TIMED is deprecated if timedep is of no use in operation contexts // to be checked in backend implementation
    if (opctx.lt.0) then
       !! error when trying to get new ctx => stop!
       STOP 'Error in begin_ids_get (from ids_get for IDS <xsl:value-of select="@name"/>)'
    end if

    <xsl:apply-templates select="field" mode="GET_SINGLE">
      <xsl:with-param name="variable_path" select="'IDS'"/>
      <!--<xsl:with-param name="mds_path" select="'&quot;&quot;'"/>-->
    </xsl:apply-templates>
    
call ual_end_action(opctx, status)

call set_c_data(IDS,.true.)

return
end subroutine ids_get_<xsl:value-of select="@name"/>



end module <xsl:value-of select="@name"/>_ids_module_get
</xsl:result-document>


<!-- ======================================  GET SLICE ======================================= -->
<xsl:result-document href="{@name}_get_slice.f90">
module <xsl:value-of select="@name"/>_ids_module_get_slice
! Declaration of the generic IDS GET_SLICE routine
interface ids_get_slice
   module procedure  ids_get_slice_<xsl:value-of select="@name"/>
end interface ids_get_slice

character(len=3)::ual_debug

contains

  character(10) function int2str(num)
    use ids_types
    integer(ids_int), intent(in):: num
    character(10) :: str
    ! convert integer to string using formatted write
    write(str, '(i10)') num
    int2str = adjustl(str)
  end function int2str

<xsl:call-template name="isCriticalFunc"/>


!!!!!! Routines to GET one time slice of a IDS, with time interpolation -->
subroutine ids_get_slice_<xsl:value-of select="@name"/>(pulsectx,path,  IDS, twant, interpol)
use ids_schemas
use ual_low_level_wrap
implicit none

character*(*) :: path
integer(ids_int) :: status = 0, interpol, pulsectx, opctx, lenstring
real(ids_real) :: twant
character(len=100000)::longstring
character(len=300) :: timepath
integer(ids_int) :: homogeneous_time
integer(ids_int) :: aosctx1,aosctx2,aosctx3,aosctx4,aosctx5,aosctx6,aosctx7
integer(ids_int) :: dim1,dim2,dim3,dim4,dim5,dim6,dim7
integer(ids_int) :: size1,size2,size3,size4,size5,size6,size7
integer(ids_int) :: i1,i2,i3,i4,i5,i6,i7
type(ids_<xsl:value-of select="@name"/>) :: IDS

call getenv('ual_debug',ual_debug)


    call begin_ids_get_slice(pulsectx, path, twant, interpol, opctx)
    if (opctx.lt.0) then
       !! error when trying to get new ctx => stop!
       STOP 'Error in begin_ids_get_slice (from ids_get_slice for IDS <xsl:value-of select="@name"/>)'
    end if

    <xsl:apply-templates select="field" mode="GET_SINGLE">
      <xsl:with-param name="variable_path" select="'IDS'"/>
      <!--<xsl:with-param name="mds_path" select="'&quot;&quot;'"/>-->
      <xsl:with-param name="non_timed" select="yes"/>
    </xsl:apply-templates>

call ual_end_action(opctx,status)

call set_c_data(IDS,.true.)

return
end subroutine ids_GET_SLICE_<xsl:value-of select="@name"/>

end module <xsl:value-of select="@name"/>_ids_module_get_slice
</xsl:result-document>



<!-- ======================================  DELETE======================================= -->
<xsl:result-document href="{@name}_copy.f90">
module <xsl:value-of select="@name"/>_copy
! Declaration of the generic IDS DELETE routine
interface ids_delete
   module procedure ids_delete_<xsl:value-of select="@name"/>
end interface ids_delete

character(len=3)::ual_debug

contains

<xsl:call-template name="isCriticalFunc"/>

subroutine copy_flt1d(in, out)
use ids_schemas
implicit none
real(ids_real), pointer :: in(:), out(:)

if (associated(in)) then
   allocate(out(size(in)))
   out = in
endif
end subroutine copy_flt1d


!!!!!! Routine to DELETE the IDS
subroutine ids_delete_<xsl:value-of select="@name"/>(pulsectx,IDSpath,IDS)  <!-- systematic calls to the low level delete_data routine. The IDS input argument is added just for the interface to identify the relevant IDS type -->
use ids_schemas
use ual_low_level_wrap
implicit none
character*(*) :: IDSpath
integer(ids_int) :: pulsectx, opctx, status
type(ids_<xsl:value-of select="@name"/>) :: IDS

<xsl:for-each select=".//field[@data_type='struct_array' and @maxoccur!='unbounded']">
integer(ids_int) :: i<xsl:value-of select="concat(@name,generate-id(.))"/>
</xsl:for-each>

call getenv('ual_debug',ual_debug) ! Debug flag
if (ual_debug =='yes') write(*,*) 'Deleting IDS ',IDSpath

call ual_begin_global_action(pulsectx, IDSpath, WRITE_OP, opctx)
    if (opctx.lt.0) then
       STOP 'Error in ual_begin_global_action (from ids_delete  for IDS <xsl:value-of select="@name"/>)'
    end if

    <xsl:apply-templates select="field" mode="DELETE">
      <xsl:with-param name="variable_path" select="'IDS'"/>
    </xsl:apply-templates>

call ual_end_action(opctx,status)

if (ual_debug =='yes') write(*,*) 'Delete IDS ',IDSpath,' done'
end subroutine ids_delete_<xsl:value-of select="@name"/>



<!-- ======================================  DEALLOCATE ======================================= -->
<!-- !!!!!! Routines to DEALLOCATE IDSs

subroutine ids_deallocate_<xsl:value-of select="local:unique_name(@name)"/>(IDS)

use ids_schemas
implicit none

integer :: i1,i2,i3,i4,i5,i6,i7

type(ids_<xsl:value-of select="@name"/>) :: IDS
    <xsl:apply-templates select="field" mode="DEALLOCATE">
        <xsl:with-param name="level" select="1"/>
        <xsl:with-param name="variablename" select="'IDS'"/>
    </xsl:apply-templates>

if (ual_debug =='yes') write(*,*) 'Deallocate an <xsl:value-of select="@name"/> IDS : done'
end subroutine ids_deallocate_<xsl:value-of select="local:unique_name(@name)"/>
-->
<!--
!!!!!! Routines to COPY IDSs
subroutine ids_copy_<xsl:value-of select="local:unique_name(@name)"/>(IDSin,  IDSout)
! Copies all fields of IDSin to IDSout

use ids_schemas
implicit none
!integer, parameter :: DP=kind(1.0D0)

integer :: itime, lentime, lenstring, istring
integer :: i1,i2,i3,i4,i5,i6,i7

type(ids_<xsl:value-of select="@name"/>) :: IDSin, IDSout

call getenv('ual_debug',ual_debug) ! Debug flag

      <xsl:apply-templates select="field" mode="COPY_FIELD">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="variablename" select="''"/>
      </xsl:apply-templates>

return
end subroutine ids_copy_<xsl:value-of select="local:unique_name(@name)"/>
-->


end module <xsl:value-of select="@name"/>_copy
</xsl:result-document>
</xsl:template>




<!--!!!!!!!!!!!!!!!!!!!!!!!!!             GET SINGLE IDS ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
   <!--!!!!!!!!!!!!!!!!!!!!!!!!!             GET FROM OBJECT    HANDLES ALSO GET_SLICE from Aos objects       !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->

<xsl:template match = "field" mode = "GET_FROM_OBJECT">
  <xsl:param name="level"/>     <!-- recursion level -->
  <xsl:param name="objpath"/>   <!-- path inside the object -->
  <xsl:param name="variablename"/>   <!-- full C++ path including indices -->
  <xsl:param name="timed"/>     <!-- are we looking for timed or non-timed fields? Still useful ???-->
  <xsl:param name="slice"/>     <!-- are during a GET_SLICE (yes) or a GET ? If in a GET_SLICE, dynamic fields must me get_sliced, while constant/static fields remain with GET -->

  <!-- build the path of the current field inside the object -->
  <xsl:param name="currentobjpath" select="concat($objpath,@name)"/>
  <!-- build the complete path of the current field -->
  <xsl:param name="currentvariablename" select="concat($variablename,'%',@name)"/>

  <xsl:choose>
    <!--========== Arrays of structures ==========-->
    <xsl:when test="@data_type='struct_array'">
! Get <xsl:value-of select="@path"/>
<!-- -->
   <xsl:choose>
   <xsl:when test="@type='dynamic'"> <!-- Aos indexed on time (type 3) -->
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
      timepath = "<xsl:value-of select = "$currentobjpath"/>/time"   <!-- Question to Olivier: shouldn't this simply be "time" if we indicate the path relative to the current node ? -->
   else
      timepath = "/time"
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ""
   </xsl:otherwise>
   </xsl:choose>
<!--NEWAPI call get_object_from_object(aosctx<xsl:value-of select="$level"/>, "<xsl:value-of select = "$currentobjpath"/>", trim(timepath), i<xsl:value-of select="$level"/> ,&amp;
     dim<xsl:value-of select="$level + 1"/>, aosctx<xsl:value-of select="$level + 1"/>) -->
call ual_begin_arraystruct_action(aosctx<xsl:value-of select="$level"/>, "<xsl:value-of select = "$currentobjpath"/>", trim(timepath), &amp;
     dim<xsl:value-of select="$level + 1"/>, aosctx<xsl:value-of select="$level + 1"/>)
if (aosctx<xsl:value-of select="$level + 1"/>.GE.0) then
   if (dim<xsl:value-of select="$level + 1"/>.gt.0) allocate(<xsl:value-of select="$currentvariablename"/>(dim<xsl:value-of select="$level + 1"/>))
   do i<xsl:value-of select="$level + 1"/> = 1,dim<xsl:value-of select="$level + 1"/>      ! process array elements
      <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
        <xsl:with-param name="level" select="$level + 1"/>
        <xsl:with-param name="objpath" select="''"/>
        <xsl:with-param name="variablename" select="concat($currentvariablename,'(i',$level + 1,')')"/>
        <xsl:with-param name="timed" select="'no'"/>  <!-- We assume the nested children are necessarily Type 2 -->
        <xsl:with-param name="slice" select="$slice"/>
      </xsl:apply-templates>
      call ual_iterate_over_arraystruct(aosctx<xsl:value-of select="$level + 1"/>, 1, status)
   enddo
   call ual_end_action(aosctx<xsl:value-of select="$level + 1"/>, status)
endif
    </xsl:when>
<!--========== Regular structure ==========-->
    <xsl:when test="@data_type='structure'">
      <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
         <xsl:with-param name="level" select="$level"/>
         <xsl:with-param name="objpath" select="concat($currentobjpath,'/')"/>
         <xsl:with-param name="variablename" select="$currentvariablename"/>
         <xsl:with-param name="timed" select="$timed"/>
         <xsl:with-param name="slice" select="$slice"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
! Get <xsl:value-of select="@path"/>
call get_string(aosctx<xsl:value-of select="$level"/>, "<xsl:value-of select="$currentobjpath"/>", "", &amp;
               longstring, lenstring, status)
if (status.EQ.0) then
   call unpack_string(longstring, lenstring, <xsl:value-of select="$currentvariablename"/>)
     if (ual_debug =='yes') write(*,*) &amp;
                  'Get <xsl:value-of select="$currentvariablename"/>',&amp;
                  <xsl:value-of select="$currentvariablename"/>
          endif
        </xsl:when>
<!-- OH: get_vect1d_string_from_object TO BE CHECKED FOR TIMED CASE -->
        <xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
! Get <xsl:value-of select="@path"/>
   <xsl:choose>
   <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
       </xsl:otherwise>
       </xsl:choose>
   else
        timepath="/time"
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
call get_vect1d_string(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", timepath,&amp;
     <xsl:value-of select="$currentvariablename"/>, size1, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentvariablename"/>'
        </xsl:when>
<!-- -->
        <xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Get <xsl:value-of select="@path"/>
call get_int(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", "", <xsl:value-of select="$currentvariablename"/>, status)
if (status.EQ.0) then
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentvariablename"/>'
endif
        </xsl:when>
<!-- -->
        <xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Get <xsl:value-of select="@path"/>
call get_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", "", <xsl:value-of select="$currentvariablename"/>, status)
if (status.EQ.0) then
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentvariablename"/>'
endif
        </xsl:when>
<!-- -->
        <xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Get <xsl:value-of select="@path"/>
   <xsl:choose>
   <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
       </xsl:otherwise>
       </xsl:choose>
   else
        timepath="/time"
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   <xsl:choose>
     <!-- OH: LOGIC TO BE CHECKED AS WE SAID THAT LL CALLS ALWAYS CONSIDER THE TARGET DIM, EVEN FOR SLICE OP -->
   <xsl:when test="@type='dynamic' and $slice='yes'">
   call get_double_slice_from_object(aosctx<xsl:value-of select="$level"/>, &amp;
        "<xsl:value-of select="$currentobjpath"/>", trim(timepath), i<xsl:value-of select="$level"/>, &amp;
        <xsl:value-of select="$currentvariablename"/>, status)
        if (status.EQ.0) then
           if (ual_debug =='yes') write(*,*) &amp;
              'Get <xsl:value-of select="$currentvariablename"/>'
        endif
   </xsl:when>
   <xsl:otherwise>
   call get_vect1d_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", timepath, &amp;
   <xsl:value-of select="$currentvariablename"/>, size1, status)
   if (status.EQ.0) then
      if (ual_debug =='yes') write(*,*) &amp;
         'Get <xsl:value-of select="$currentvariablename"/>'
   endif
   </xsl:otherwise>
   </xsl:choose>
        </xsl:when>
<!-- -->
        <xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Get <xsl:value-of select="@path"/>
   <xsl:choose>
   <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
       </xsl:otherwise>
       </xsl:choose>
   else
        timepath="/time"
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   <xsl:choose>
   <xsl:when test="@type='dynamic' and $slice='yes'">
   call get_int_slice_from_object(aosctx<xsl:value-of select="$level"/>, &amp;
        "<xsl:value-of select="$currentobjpath"/>", trim(timepath), i<xsl:value-of select="$level"/>, &amp;
        <xsl:value-of select="$currentvariablename"/>, status)
        if (status.EQ.0) then
           if (ual_debug =='yes') write(*,*) &amp;
              'Get <xsl:value-of select="$currentvariablename"/>'
        endif
   </xsl:when>
   <xsl:otherwise>
   call get_vect1d_int(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", timepath, &amp;
   <xsl:value-of select="$currentvariablename"/>, size1, status)
   if (status.EQ.0) then
      if (ual_debug =='yes') write(*,*) &amp;
         'Get <xsl:value-of select="$currentvariablename"/>'
   endif
   </xsl:otherwise>
   </xsl:choose>
        </xsl:when>
<!-- -->
        <xsl:when test=" @data_type='FLT_2D'">
! Get <xsl:value-of select="@path"/>
   <xsl:choose>
   <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
       </xsl:otherwise>
       </xsl:choose>
   else
        timepath="/time"
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   <xsl:choose>
   <xsl:when test="@type='dynamic' and $slice='yes'">
   call get_vect1d_double_slice_from_object(aosctx<xsl:value-of select="$level"/>, &amp;
        "<xsl:value-of select="$currentobjpath"/>", trim(timepath), i<xsl:value-of select="$level"/>, &amp;
        <xsl:value-of select="$currentvariablename"/>, status)
        if (status.EQ.0) then
           if (ual_debug =='yes') write(*,*) &amp;
              'Get <xsl:value-of select="$currentvariablename"/>'
        endif
   </xsl:when>
   <xsl:otherwise>
   call get_vect2d_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", timepath, &amp;
   <xsl:value-of select="$currentvariablename"/>, size1, size2, status)
   if (status.EQ.0) then
      if (ual_debug =='yes') write(*,*) &amp;
         'Get <xsl:value-of select="$currentvariablename"/>'
   endif
   </xsl:otherwise>
   </xsl:choose>
        </xsl:when>	
<!-- -->
	<xsl:when test=" @data_type='INT_2D'">
! Get <xsl:value-of select="@path"/>
   <xsl:choose>
   <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
       </xsl:otherwise>
       </xsl:choose>
   else
        timepath="/time"
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   <xsl:choose>
   <xsl:when test="@type='dynamic' and $slice='yes'">
   call get_vect1d_int_slice_from_object(aosctx<xsl:value-of select="$level"/>, &amp;
        "<xsl:value-of select="$currentobjpath"/>", trim(timepath), i<xsl:value-of select="$level"/>, &amp;
        <xsl:value-of select="$currentvariablename"/>, status)
        if (status.EQ.0) then
           if (ual_debug =='yes') write(*,*) &amp;
              'Get <xsl:value-of select="$currentvariablename"/>'
        endif
   </xsl:when>
   <xsl:otherwise>
   call get_vect2d_int(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", timepath, &amp;
   <xsl:value-of select="$currentvariablename"/>, size1, size2, status)
   if (status.EQ.0) then
      if (ual_debug =='yes') write(*,*) &amp;
         'Get <xsl:value-of select="$currentvariablename"/>'
   endif
      </xsl:otherwise>
   </xsl:choose>
        </xsl:when>
<!-- -->
        <xsl:when test="@data_type='FLT_3D'">
! Get <xsl:value-of select="@path"/>
   <xsl:choose>
   <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
       </xsl:otherwise>
       </xsl:choose>
   else
        timepath="/time"
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
      <xsl:choose>
   <xsl:when test="@type='dynamic' and $slice='yes'">
   call get_vect2d_double_slice_from_object(aosctx<xsl:value-of select="$level"/>, &amp;
        "<xsl:value-of select="$currentobjpath"/>", trim(timepath), i<xsl:value-of select="$level"/>, &amp;
        <xsl:value-of select="$currentvariablename"/>, status)
        if (status.EQ.0) then
           if (ual_debug =='yes') write(*,*) &amp;
              'Get <xsl:value-of select="$currentvariablename"/>'
        endif
   </xsl:when>
   <xsl:otherwise>
   call get_vect3d_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", timepath, &amp;
   <xsl:value-of select="$currentvariablename"/>, size1, size2, size3, status)
   if (status.EQ.0) then
      if (ual_debug =='yes') write(*,*) &amp;
         'Get <xsl:value-of select="$currentvariablename"/>'
   endif
      </xsl:otherwise>
   </xsl:choose>
        </xsl:when>
<!-- -->
        <xsl:when test="@data_type='INT_3D'">
! Get <xsl:value-of select="@path"/>
   <xsl:choose>
   <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
       </xsl:otherwise>
       </xsl:choose>
   else
        timepath="/time"
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
         <xsl:choose>
   <xsl:when test="@type='dynamic' and $slice='yes'">
   call get_vect2d_int_slice_from_object(aosctx<xsl:value-of select="$level"/>, &amp;
        "<xsl:value-of select="$currentobjpath"/>", trim(timepath), i<xsl:value-of select="$level"/>, &amp;
        <xsl:value-of select="$currentvariablename"/>, status)
        if (status.EQ.0) then
           if (ual_debug =='yes') write(*,*) &amp;
              'Get <xsl:value-of select="$currentvariablename"/>'
        endif
   </xsl:when>
   <xsl:otherwise>
   call get_vect3d_int(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", timepath, &amp;
   <xsl:value-of select="$currentvariablename"/>, size1, size2, size3, status)
   if (status.EQ.0) then
      if (ual_debug =='yes') write(*,*) &amp;
         'Get <xsl:value-of select="$currentvariablename"/>'
   endif
      </xsl:otherwise>
   </xsl:choose>
        </xsl:when>
<!-- -->
        <xsl:when test="@data_type='FLT_4D'">
! Get <xsl:value-of select="@path"/>
! Get <xsl:value-of select="@path"/>
   <xsl:choose>
   <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
       </xsl:otherwise>
       </xsl:choose>
   else
        timepath="/time"
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
            <xsl:choose>
   <xsl:when test="@type='dynamic' and $slice='yes'">
   call get_vect3d_double_slice_from_object(aosctx<xsl:value-of select="$level"/>, &amp;
        "<xsl:value-of select="$currentobjpath"/>", trim(timepath), i<xsl:value-of select="$level"/>, &amp;
        <xsl:value-of select="$currentvariablename"/>, status)
        if (status.EQ.0) then
           if (ual_debug =='yes') write(*,*) &amp;
              'Get <xsl:value-of select="$currentvariablename"/>'
        endif
   </xsl:when>
   <xsl:otherwise>
   call get_vect4d_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", timepath, &amp;
   <xsl:value-of select="$currentvariablename"/>, size1, size2, size3, size4, status)
   if (status.EQ.0) then
      if (ual_debug =='yes') write(*,*) &amp;
         'Get <xsl:value-of select="$currentvariablename"/>'
   endif
      </xsl:otherwise>
   </xsl:choose>
        </xsl:when>
<!-- -->
        <xsl:when test="@data_type='FLT_5D'">
! Get <xsl:value-of select="@path"/>
   <xsl:choose>
   <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
       </xsl:otherwise>
       </xsl:choose>
   else
        timepath="/time"
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   <xsl:choose>
     <xsl:when test="@type='dynamic' and $slice='yes'">
   call get_vect4d_double_slice_from_object(aosctx<xsl:value-of select="$level"/>, &amp;
        "<xsl:value-of select="$currentobjpath"/>", trim(timepath), i<xsl:value-of select="$level"/>, &amp;
        <xsl:value-of select="$currentvariablename"/>, status)
        if (status.EQ.0) then
           if (ual_debug =='yes') write(*,*) &amp;
              'Get <xsl:value-of select="$currentvariablename"/>'
        endif
     </xsl:when>
     <xsl:otherwise>
   call get_vect5d_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", timepath, &amp;
   <xsl:value-of select="$currentvariablename"/>, size1, size2, size3, size4, size5, status)
   if (status.EQ.0) then
      if (ual_debug =='yes') write(*,*) &amp;
         'Get <xsl:value-of select="$currentvariablename"/>'
   endif
     </xsl:otherwise>
   </xsl:choose>
        </xsl:when>
<!-- -->
        <xsl:when test="@data_type='FLT_6D'">
! Get <xsl:value-of select="@path"/>
   <xsl:choose>
   <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
       </xsl:otherwise>
       </xsl:choose>
   else
        timepath="/time"
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   <xsl:choose>
     <xsl:when test="@type='dynamic' and $slice='yes'">
   call get_vect5d_double_slice_from_object(aosctx<xsl:value-of select="$level"/>, &amp;
        "<xsl:value-of select="$currentobjpath"/>", trim(timepath), i<xsl:value-of select="$level"/>, &amp;
        <xsl:value-of select="$currentvariablename"/>, status)
        if (status.EQ.0) then
           if (ual_debug =='yes') write(*,*) &amp;
              'Get <xsl:value-of select="$currentvariablename"/>'
        endif
     </xsl:when>
     <xsl:otherwise>
   call get_vect6d_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", timepath, &amp;
   <xsl:value-of select="$currentvariablename"/>, size1, size2, size3, size4, size5, size6, status)
   if (status.EQ.0) then
      if (ual_debug =='yes') write(*,*) &amp;
         'Get <xsl:value-of select="$currentvariablename"/>'
   endif
     </xsl:otherwise>
   </xsl:choose>
        </xsl:when>
<!-- -->
</xsl:choose>
</xsl:otherwise>
</xsl:choose>
</xsl:template>


<!--!!!!!!!!!!!!!!!!!!!!!!!!!        PUT_SINGLE for FIELDS       !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="PUT_SINGLE">
<xsl:param name="variable_path"/>
<xsl:param name="mds_path"/>
<xsl:param name="non_timed"/>
<xsl:param name="slice"/>

<xsl:variable name="new_path" select="concat($variable_path,'%',@name)"/>

<xsl:variable name="new_mds_path">
  <xsl:choose>
    <xsl:when test="$mds_path">
      <xsl:value-of select="concat(substring($mds_path,1,string-length($mds_path)-1),'/',@name,'&quot;')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="concat('&quot;',@name,'&quot;')"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:if test="$slice !='yes' or @type ='dynamic' or @data_type='structure' or (@data_type='struct_array' and .//field[@type='dynamic'])"> <!-- This skips the routine for non-timed fields when using this template in PUT_SLICE mode -->
<xsl:if test="$non_timed !='yes' or @type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')"> <!-- This skips the routine for timed fields when using this template in PUT_NON_TIMED mode -->

  <xsl:choose>
    <xsl:when test="@data_type='structure'">
      <xsl:apply-templates select="field" mode="PUT_SINGLE">
	<xsl:with-param name ="variable_path" select="$new_path"/>
	<xsl:with-param name ="mds_path" select="$new_mds_path"/>
	<xsl:with-param name="non_timed" select="$non_timed"/>
	<xsl:with-param name="slice" select="$slice"/>
      </xsl:apply-templates>
    </xsl:when>


    <xsl:when test="@data_type='struct_array'">
      <!-- With the new LL, we generalize this to all types of struct_array -->
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$new_path"/>)) then 
<xsl:choose>
  <xsl:when test="@type='dynamic'">
    <xsl:choose>
      <xsl:when test="$slice='yes'">
	dim1 = 1
      </xsl:when>
      <xsl:otherwise>
	dim1 = size(<xsl:value-of select = "$new_path"/>)
      </xsl:otherwise>
    </xsl:choose>
    if (homogeneous_time.EQ.0) then
       timepath = "time"
    else
       timepath = "/time"
    endif
  </xsl:when>
  <xsl:otherwise>
    dim1 = size(<xsl:value-of select = "$new_path"/>)
    timepath = ""
  </xsl:otherwise>
</xsl:choose>
   <!--NEWAPI call begin_object(opctx, 0, <xsl:value-of select = "$new_mds_path"/>, trim(timepath), dim1, aosctx1) -->
   call ual_begin_arraystruct_action(opctx, <xsl:value-of select = "$new_mds_path"/>, trim(timepath), dim1, aosctx1)
   if (aosctx1.ge.0) then
      do i1 = 1,dim1
      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
           <xsl:with-param name="level" select="1"/>
           <xsl:with-param name="variablename" select="concat($new_path,'(i1)')"/>
           <!--<xsl:with-param name="variablename" select="concat($variable_path,@name,'(i1)')"/>-->
           <xsl:with-param name="child_index" select="1"/>
           <xsl:with-param name="non_timed" select="$non_timed"/>
           <xsl:with-param name="slice" select="$slice"/>
      </xsl:apply-templates> 
         call ual_iterate_over_arraystruct(aosctx1, 1, status)
      enddo
      call ual_end_action(aosctx1, status) 
   endif
endif
    </xsl:when>

    <xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$new_path"/>)) then
   call pack_string(<xsl:value-of select="$new_path"/>, longstring, lenstring)
   call put_string(opctx,<xsl:value-of select="$new_mds_path"/>,&amp;
       '', longstring(1:lenstring), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$new_path"/>',&amp;
      <xsl:value-of select="$new_path"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
    </xsl:when>

    <xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$new_path"/>)) then
   <xsl:choose>
     <xsl:when test="@type='dynamic'">
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=<xsl:value-of select="$mds_path"/>//&quot;/time&quot;
       OH: THIS IS PROBABLY WRONG!!!
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
       </xsl:otherwise>
       </xsl:choose>
   else
       timepath="time"
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       dim1 = 1
     </xsl:when>
     <xsl:otherwise>
       dim1 = size(<xsl:value-of select="$new_path"/>)
     </xsl:otherwise>
   </xsl:choose>
   call put_Vect1d_String(opctx, <xsl:value-of select="$new_mds_path"/>, &amp;
          trim(timepath), <xsl:value-of select="$new_path"/>,dim1, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(pulsectx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$new_path"/>'

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>

<xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Put <xsl:value-of select="@path"/>
if (<xsl:value-of select="$new_path"/>.NE.ids_int_invalid) then
   call put_int(opctx, <xsl:value-of select="$new_mds_path"/>,&amp;
       '', <xsl:value-of select="$new_path"/>, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$new_path"/>',&amp;
      <xsl:value-of select="$new_path"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>

<xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Put <xsl:value-of select="@path"/>
if (<xsl:value-of select="$new_path"/>.NE.ids_real_invalid) then
   call put_double(opctx,<xsl:value-of select="$new_mds_path"/>,&amp;
       '', <xsl:value-of select="$new_path"/>,&amp;
       status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$new_path"/>',&amp;
          <xsl:value-of select="$new_path"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>

<xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$new_path"/>)) then
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/><!-- deprecated? -->
</xsl:call-template>
   call put_vect1d_double(opctx, <xsl:value-of select="$new_mds_path"/>,&amp;
   trim(timepath),&amp;
   <xsl:value-of select="$new_path"/>,&amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$new_path"/>), status)
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$new_path"/>',&amp;
      <xsl:value-of select="$new_path"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>

<xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$new_path"/>)) then
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/><!-- deprecated? -->
</xsl:call-template>
   call put_vect1d_int(opctx, <xsl:value-of select="$new_mds_path"/>,&amp;
   trim(timepath), &amp;
   <xsl:value-of select="$new_path"/>, &amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$new_path"/>), status)
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$new_path"/>',&amp;
      <xsl:value-of select="$new_path"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>

<xsl:when test="@data_type='FLT_2D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$new_path"/>)) then
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/><!-- deprecated? -->
</xsl:call-template>
   call put_vect2d_double(opctx, <xsl:value-of select="$new_mds_path"/>,&amp;
   trim(timepath),&amp;
   <xsl:value-of select="$new_path"/>, &amp;
   size(<xsl:value-of select="$new_path"/>,1),&amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$new_path"/>,2), status)
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$new_path"/>',&amp;
      <xsl:value-of select="$new_path"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>

<xsl:when test="@data_type='INT_2D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$new_path"/>)) then
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/><!-- deprecated? -->
</xsl:call-template>
   call put_vect2d_int(opctx, <xsl:value-of select="$new_mds_path"/>,&amp;
   trim(timepath),&amp;
   <xsl:value-of select="$new_path"/>, &amp;
   size(<xsl:value-of select="$new_path"/>,1),&amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$new_path"/>,2), status)
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$new_path"/>',&amp;
      <xsl:value-of select="$new_path"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>

<xsl:when test="@data_type='FLT_3D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$new_path"/>)) then
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/><!-- deprecated? -->
</xsl:call-template>
   call put_vect3d_double(opctx, <xsl:value-of select="$new_mds_path"/>,&amp;
   trim(timepath),&amp;
   <xsl:value-of select="$new_path"/>, &amp;
   size(<xsl:value-of select="$new_path"/>,1),&amp;
   size(<xsl:value-of select="$new_path"/>,2),&amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$new_path"/>,3), status)
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$new_path"/>',&amp;
      <xsl:value-of select="$new_path"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>

<xsl:when test="@data_type='INT_3D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$new_path"/>)) then
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/><!-- deprecated? -->
</xsl:call-template>
   call put_vect3d_int(opctx, <xsl:value-of select="$new_mds_path"/>,&amp;
   trim(timepath),&amp;
   <xsl:value-of select="$new_path"/>, &amp;
   size(<xsl:value-of select="$new_path"/>,1),&amp;
   size(<xsl:value-of select="$new_path"/>,2),&amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$new_path"/>,3), status)
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$new_path"/>',&amp;
      <xsl:value-of select="$new_path"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>

<xsl:when test="@data_type='FLT_4D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$new_path"/>)) then
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/><!-- deprecated? -->
</xsl:call-template>
   call put_vect4d_double(opctx, <xsl:value-of select="$new_mds_path"/>,&amp;
   trim(timepath),&amp;
   <xsl:value-of select="$new_path"/>, &amp;
   size(<xsl:value-of select="$new_path"/>,1),&amp;
   size(<xsl:value-of select="$new_path"/>,2),&amp;
   size(<xsl:value-of select="$new_path"/>,3),&amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$new_path"/>,4), status)
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$new_path"/>',&amp;
      <xsl:value-of select="$new_path"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>

<xsl:when test="@data_type='FLT_5D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$new_path"/>)) then
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/><!-- deprecated? -->
</xsl:call-template>
   call put_vect5d_double(opctx, <xsl:value-of select="$new_mds_path"/>,&amp;
   trim(timepath),&amp;
   <xsl:value-of select="$new_path"/>, &amp;
   size(<xsl:value-of select="$new_path"/>,1),&amp;
   size(<xsl:value-of select="$new_path"/>,2),&amp;
   size(<xsl:value-of select="$new_path"/>,3),&amp;
   size(<xsl:value-of select="$new_path"/>,4),&amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$new_path"/>,5), status)
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$new_path"/>',&amp;
      <xsl:value-of select="$new_path"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>

<xsl:when test="@data_type='FLT_6D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$new_path"/>)) then
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/><!-- deprecated? -->
</xsl:call-template>
   call put_vect6d_double(opctx, <xsl:value-of select="$new_mds_path"/>,&amp;
   trim(timepath),&amp;
   <xsl:value-of select="$new_path"/>, &amp;
   size(<xsl:value-of select="$new_path"/>,1),&amp;
   size(<xsl:value-of select="$new_path"/>,2),&amp;
   size(<xsl:value-of select="$new_path"/>,3),&amp;
   size(<xsl:value-of select="$new_path"/>,4),&amp;
   size(<xsl:value-of select="$new_path"/>,5),&amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$new_path"/>,6), status)
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$new_path"/>',&amp;
      <xsl:value-of select="$new_path"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>

<xsl:otherwise>
  ! Put <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! 
  <xsl:message select="concat('PROBLEM : UNIDENTIFIED TYPE detected in PUT routine for ',@path)" terminate="yes"/>
</xsl:otherwise>
</xsl:choose>
</xsl:if>
</xsl:if>
</xsl:template>



<!--!!!!!!!!!!!!!!!!!!!!!!!!!        GET_SINGLE for FIELDS       !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="GET_SINGLE">
<xsl:param name="variable_path"/>
<xsl:param name="mds_path"/>

<xsl:variable name="new_path" select="concat($variable_path,'%',@name)"/>

<xsl:variable name="new_mds_path">
  <xsl:choose>
    <xsl:when test="$mds_path">
      <xsl:value-of select="concat(substring($mds_path,1,string-length($mds_path)-1),'/',@name,'&quot;')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="concat('&quot;',@name,'&quot;')"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>


<xsl:choose>
  <xsl:when test="@data_type='structure'">
    <xsl:apply-templates select="field" mode="GET_SINGLE">
      <xsl:with-param name="variable_path" select="$new_path"/>
      <xsl:with-param name="mds_path" select="$new_mds_path"/>
    </xsl:apply-templates>
  </xsl:when>

  <xsl:when test="@data_type='struct_array'">
<!-- This WHEN case must now cover all AoS cases -->
! Get <xsl:value-of select="@path"/>
<xsl:choose>
  <xsl:when test="@type='dynamic'"> <!-- Aos indexed on time (type 3) -->
    if (IDS%ids_properties%homogeneous_time.EQ.0) then
       timepath = "time" 
    else
       timepath = "/time"
    endif
  </xsl:when>
  <xsl:otherwise>
    timepath = ""
  </xsl:otherwise>
</xsl:choose>

<!--NEWAPI call get_object(opctx, <xsl:value-of select="$new_mds_path"/>, trim(timepath), dim1, aosctx1) -->
call ual_begin_arraystruct_action(opctx, <xsl:value-of select="$new_mds_path"/>, trim(timepath), dim1, aosctx1)
if (aosctx1.GE.0) then
   if (dim1.gt.0) allocate(<xsl:value-of select="$new_path"/>(dim1))
   do i1 = 1,dim1
   <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
     <xsl:with-param name="level" select="1"/>
     <xsl:with-param name="objpath" select="''"/>
     <xsl:with-param name="variablename" select="concat($new_path,'(i1)')"/>
     <xsl:with-param name="timed" select="'yes'"/>
   </xsl:apply-templates>
      call ual_iterate_over_arraystruct(aosctx1, 1, status)
   enddo
   call ual_end_action(aosctx1, status)
endif
  </xsl:when>

  <xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
! Get <xsl:value-of select="@path"/>
longstring = ' ' 
call get_string(opctx, <xsl:value-of select="$new_mds_path"/>, '', longstring, lenstring, status)
if (status.EQ.0) then
   call unpack_string(longstring, lenstring, <xsl:value-of select="$new_path"/>)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$new_path"/>',&amp;
      <xsl:value-of select="$new_path"/>
endif
  </xsl:when>
  
  <xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
! Get <xsl:value-of select="@path"/>
call get_Vect1d_string(opctx, <xsl:value-of select="$new_mds_path"/>, '', &amp;
<xsl:value-of select="$new_path"/>, dim1, status)
if (ual_debug =='yes') write(*,*) &amp;
   'Get <xsl:value-of select="$new_path"/>'
  </xsl:when>

  <xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Get <xsl:value-of select="@path"/>
call get_int(opctx, <xsl:value-of select="$new_mds_path"/>, '', &amp;
<xsl:value-of select="$new_path"/>, status)
if (status.EQ.0) then
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$new_path"/>'
endif
  </xsl:when>

  <xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Get <xsl:value-of select="@path"/>
call get_double(opctx, <xsl:value-of select="$new_mds_path"/>, '', &amp;
<xsl:value-of select="$new_path"/>, status)
if (status.EQ.0) then
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$new_path"/>'
endif
  </xsl:when>
	
  <xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Get <xsl:value-of select="@path"/>
   <xsl:call-template name="evaluate_time_path_mdspath">
     <xsl:with-param name="mds_path" select="$mds_path"/> <!-- deprecated -->
   </xsl:call-template>
call get_vect1d_double(opctx,<xsl:value-of select="$new_mds_path"/>, timepath, &amp;
<xsl:value-of select="$new_path"/>, &amp;
dim1, status)
if (status.EQ.0) then
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$new_path"/>'
endif
  </xsl:when>

  <xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Get <xsl:value-of select="@path"/>
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/>  <!-- deprecated -->
</xsl:call-template>
call get_vect1d_int(opctx,<xsl:value-of select="$new_mds_path"/>, timepath,&amp;
<xsl:value-of select="$new_path"/>, &amp;
dim1, status)
if (status.EQ.0) then
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$new_path"/>'
endif
  </xsl:when>

  <xsl:when test="@data_type='FLT_2D'">
! Get <xsl:value-of select="@path"/>
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/> <!-- deprecated -->
</xsl:call-template>
call get_vect2d_double(opctx,<xsl:value-of select="$new_mds_path"/>, timepath,&amp;
<xsl:value-of select="$new_path"/>, &amp;
dim1, dim2, status)
if (status.EQ.0) then
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$new_path"/>'
endif
  </xsl:when>

  <xsl:when test="@data_type='INT_2D'">
! Get <xsl:value-of select="@path"/>
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/> <!-- deprecated -->
</xsl:call-template>
call get_vect2d_int(opctx,<xsl:value-of select="$new_mds_path"/>, timepath, &amp;
<xsl:value-of select="$new_path"/>, &amp;
dim1, dim2, status)
if (status.EQ.0) then
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$new_path"/>'
endif
  </xsl:when>

  <xsl:when test="@data_type='FLT_3D'">
! Get <xsl:value-of select="@path"/>
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/> <!-- deprecated -->
</xsl:call-template>
call get_vect3d_double(opctx,<xsl:value-of select="$new_mds_path"/>, timepath, &amp;
<xsl:value-of select="$new_path"/>, &amp;
dim1, dim2, dim3, status)
if (status.EQ.0) then
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$new_path"/>'
endif
  </xsl:when>

  <xsl:when test="@data_type='INT_3D'">
! Get <xsl:value-of select="@path"/>
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/> <!-- deprecated -->
</xsl:call-template>
call get_vect3d_int(opctx,<xsl:value-of select="$new_mds_path"/>, timepath, &amp;
<xsl:value-of select="$new_path"/>, &amp;
dim1, dim2, dim3, status)
if (status.EQ.0) then
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$new_path"/>'
endif
  </xsl:when>

  <xsl:when test="@data_type='FLT_4D'">
! Get <xsl:value-of select="@path"/>
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/> <!-- deprecated -->
</xsl:call-template>
call get_vect4d_double(opctx,<xsl:value-of select="$new_mds_path"/>, timepath, &amp;
<xsl:value-of select="$new_path"/>, &amp;
dim1, dim2, dim3, dim4, status)
if (status.EQ.0) then
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$new_path"/>'
endif
  </xsl:when>
  
  <xsl:when test="@data_type='FLT_5D'">
! Get <xsl:value-of select="@path"/>
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/> <!-- deprecated -->
</xsl:call-template>
call get_vect5d_double(opctx,<xsl:value-of select="$new_mds_path"/>, timepath, &amp;
<xsl:value-of select="$new_path"/>, &amp;
dim1, dim2, dim3, dim4, dim5, status)
if (status.EQ.0) then
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$new_path"/>'
endif
  </xsl:when>
  
  <xsl:when test="@data_type='FLT_6D'">
! Get <xsl:value-of select="@path"/>
<xsl:call-template name="evaluate_time_path_mdspath">
  <xsl:with-param name="mds_path" select="$mds_path"/> <!-- deprecated -->
</xsl:call-template>
call get_vect6d_double(opctx,<xsl:value-of select="$new_mds_path"/>, timepath, &amp;
<xsl:value-of select="$new_path"/>, &amp;
dim1, dim2, dim3, dim4, dim5, dim6, status)
if (status.EQ.0) then
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$new_path"/>'
endif
  </xsl:when>

  <xsl:otherwise>
 ! Get <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
  </xsl:otherwise>
</xsl:choose>
</xsl:template>





<!--!!!!!!!!!!!!!!!!!!!!!!!!!        PUT IN OBJECT       !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="PUT_IN_OBJECT">
  <xsl:param name="level"/>     <!-- recursion level -->
  <xsl:param name="objpath"/>   <!-- path inside the object -->
  <xsl:param name="variablename"/>   <!-- full C++ path including indices -->
  <xsl:param name="child_index"/>     <!-- Index to use to add a child in the current object -->
  <!-- build the path of the current field inside the object -->
  <xsl:param name="currentobjpath" select="concat($objpath,@name)"/>
  <!-- build the complete path of the current field -->
  <xsl:param name="currentvariablename" select="concat($variablename,'%',@name)"/>
  <xsl:param name="slice"/>
  <xsl:param name="non_timed"/>

<xsl:if test="$slice !='yes' or @type ='dynamic' or @data_type='structure' or (@data_type='struct_array' and .//field[@type='dynamic'])"> <!-- This skips the routine for non-timed fields when using this template in PUT_SLICE mode -->
<xsl:if test="$non_timed !='yes' or @type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')"> <!-- This skips the routine for timed fields when using this template in PUT_NON_TIMED mode -->

  <xsl:choose>
    <!--========== Arrays of structures ==========-->
    <xsl:when test="@data_type='struct_array'">
! Put <xsl:value-of select="@path"/>
<!-- Present implementation assumes that nested AoS are non timed, this may need to be upgraded for other cases -->
if (associated(<xsl:value-of select="$currentvariablename"/>)) then
<xsl:choose>
  <xsl:when test="@type='dynamic'">
    <xsl:choose>
      <xsl:when test="$slice='yes'">
	dim<xsl:value-of select="$level + 1"/> = 1
      </xsl:when>
      <xsl:otherwise>
	dim<xsl:value-of select="$level + 1"/> = size(<xsl:value-of select="$currentvariablename"/>)
      </xsl:otherwise>
    </xsl:choose>
    if (homogeneous_time.EQ.0) then
       timepath = "<xsl:value-of select="$currentobjpath"/>/time"
    else
       timepath = "/time"
    endif
  </xsl:when>
  <xsl:otherwise>
    dim<xsl:value-of select="$level + 1"/> = size(<xsl:value-of select="$currentvariablename"/>)
    timepath = ""
  </xsl:otherwise>
</xsl:choose>
   <!--NEWAPI call begin_object(aosctx<xsl:value-of select="$level"/>, i<xsl:value-of select="$level"/>, "<xsl:value-of select="$currentobjpath"/>", timepath, dim<xsl:value-of select="$level + 1"/>, aosctx<xsl:value-of select="$level + 1"/>) -->
   call ual_begin_arraystruct_action(aosctx<xsl:value-of select="$level"/>, "<xsl:value-of select="$currentobjpath"/>", timepath, dim<xsl:value-of select="$level + 1"/>, aosctx<xsl:value-of select="$level + 1"/>)
   if (aosctx<xsl:value-of select="$level + 1"/>.ge.0) then
      do i<xsl:value-of select="$level + 1"/> = 1,dim<xsl:value-of select="$level + 1"/>
         <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
            <xsl:with-param name="level" select="$level + 1"/>
            <xsl:with-param name="objpath" select="''"/>
            <xsl:with-param name="variablename" select="concat($currentvariablename,'(i',$level + 1,')')"/>
            <xsl:with-param name="child_index" select="concat('i',$level+1)"/>
            <xsl:with-param name="non_timed" select="$non_timed"/>
            <xsl:with-param name="slice" select="$slice"/>
         </xsl:apply-templates>
	 call ual_iterate_over_arraystruct(aosctx<xsl:value-of select="$level + 1"/>, 1, status)
      enddo
      call ual_end_action(aosctx<xsl:value-of select="$level + 1"/>, status) 
   endif
endif
    </xsl:when>

    <!--========== Regular structure ==========-->
    <xsl:when test="@data_type='structure'">
     <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
        <xsl:with-param name="level" select="$level"/>
        <xsl:with-param name="objpath" select="concat($currentobjpath,'/')"/>
        <xsl:with-param name="variablename" select="$currentvariablename"/>
        <xsl:with-param name="child_index" select="$child_index"/>
        <xsl:with-param name="non_timed" select="$non_timed"/>
        <xsl:with-param name="slice" select="$slice"/>
      </xsl:apply-templates>
    </xsl:when>

    <!--========== select either timed or non-timed fields ==========-->
    <xsl:otherwise>
 <!--     <xsl:if test="(@type='dynamic' and $timed='yes') or (@type!='dynamic' and $timed='no')"> -->
        <xsl:choose>
         <xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$currentvariablename"/>)) then
   call pack_string(<xsl:value-of select="$currentvariablename"/>, longstring, lenstring)
   call put_string(aosctx<xsl:value-of select="$level"/>, "<xsl:value-of select="$currentobjpath"/>", "", &amp;
                   longstring(1:lenstring), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentvariablename"/>',&amp;
      <xsl:value-of select="$currentvariablename"/>
   <xsl:call-template name="checkError"/>
endif
         </xsl:when>
<!-- -->
         <xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
! Put <xsl:value-of select="@path"/>
	 <!-- OH: put_vect1d_string_in_object TO BE CHECKED FOR TIMED CASE -->
   <xsl:choose>
     <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
       if (IDS%ids_properties%homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
	 <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
	   timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
	 </xsl:when>
	 <xsl:otherwise>
	   timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
	 </xsl:otherwise>
       </xsl:choose>
       else
          timepath="/time"
       endif
     </xsl:when>
     <xsl:otherwise>
   timepath = ""
   </xsl:otherwise>
   </xsl:choose>
if (associated(<xsl:value-of select="$currentvariablename"/>)) then
   call put_vect1d_string(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", timepath, &amp;
   <xsl:value-of select="$currentvariablename"/>, &amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$currentvariablename"/>), status)
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentvariablename"/>'
endif
         </xsl:when>
<!-- -->
         <xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Put <xsl:value-of select="@path"/>
if (<xsl:value-of select="$currentvariablename"/>.NE.ids_int_invalid) then
   call put_int(aosctx<xsl:value-of select="$level"/>, "<xsl:value-of select="$currentobjpath"/>", "", &amp;
        <xsl:value-of select="$currentvariablename"/>, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentvariablename"/>', &amp;
      <xsl:value-of select="$currentvariablename"/>
   <xsl:call-template name="checkError"/>
endif
         </xsl:when>
<!-- -->
         <xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (<xsl:value-of select="$currentvariablename"/>.NE.ids_real_invalid) then
   call put_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", "", &amp;
        <xsl:value-of select="$currentvariablename"/>, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentvariablename"/>', &amp;
      <xsl:value-of select="$currentvariablename"/>
   <xsl:call-template name="checkError"/>
endif
         </xsl:when>
<!-- -->
         <xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$currentvariablename"/>)) then
<xsl:choose>
  <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
    if (IDS%ids_properties%homogeneous_time.EQ.0) then
    <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
    <xsl:choose>
      <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
	timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
      </xsl:when>
      <xsl:otherwise>
	timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
      </xsl:otherwise>
    </xsl:choose>
    else
       timepath="/time"
    endif
  </xsl:when>
  <xsl:otherwise>
    timepath = ""
  </xsl:otherwise>
</xsl:choose>
   call put_vect1d_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", &amp;
   trim(timepath), <xsl:value-of select="$currentvariablename"/>, &amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$currentvariablename"/>), status)                  
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentvariablename"/>',&amp;
      <xsl:value-of select="$currentvariablename"/>
   <xsl:call-template name="checkError"/>
endif
         </xsl:when>
<!-- -->
         <xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentvariablename"/>)) then
<xsl:choose>
  <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
    if (IDS%ids_properties%homogeneous_time.EQ.0) then
    <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
    <xsl:choose>
      <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
	timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
      </xsl:when>
      <xsl:otherwise>
	timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
      </xsl:otherwise>
    </xsl:choose>
    else
       timepath="/time"
    endif
  </xsl:when>
  <xsl:otherwise>
    timepath = ""
  </xsl:otherwise>
</xsl:choose>
   call put_vect1d_int(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", &amp;
   trim(timepath), <xsl:value-of select="$currentvariablename"/>, &amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$currentvariablename"/>), status)                  
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentvariablename"/>',&amp;
      <xsl:value-of select="$currentvariablename"/>
   <xsl:call-template name="checkError"/>
endif
         </xsl:when>
<!-- -->
         <xsl:when test=" @data_type='FLT_2D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$currentvariablename"/>)) then
<xsl:choose>
  <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
    if (IDS%ids_properties%homogeneous_time.EQ.0) then
    <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
    <xsl:choose>
      <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
	timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
      </xsl:when>
      <xsl:otherwise>
	timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
      </xsl:otherwise>
    </xsl:choose>
    else
       timepath="/time"
    endif
  </xsl:when>
  <xsl:otherwise>
    timepath = ""
  </xsl:otherwise>
</xsl:choose>
   call put_vect2d_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", &amp;
   trim(timepath), <xsl:value-of select="$currentvariablename"/>, &amp;
   size(<xsl:value-of select="$currentvariablename"/>,1), &amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$currentvariablename"/>,2), status)  
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentvariablename"/>',&amp;
      <xsl:value-of select="$currentvariablename"/>
   <xsl:call-template name="checkError"/>
endif
         </xsl:when>
<!-- -->
         <xsl:when test=" @data_type='INT_2D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$currentvariablename"/>)) then
<xsl:choose>
  <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
    if (IDS%ids_properties%homogeneous_time.EQ.0) then
    <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
    <xsl:choose>
      <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
	timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
      </xsl:when>
      <xsl:otherwise>
	timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
      </xsl:otherwise>
    </xsl:choose>
    else
       timepath="/time"
    endif
  </xsl:when>
  <xsl:otherwise>
    timepath = ""
  </xsl:otherwise>
</xsl:choose>
   call put_vect2d_int(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", &amp;
   trim(timepath), <xsl:value-of select="$currentvariablename"/>, &amp;
   size(<xsl:value-of select="$currentvariablename"/>,1), &amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$currentvariablename"/>,2), status)
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentvariablename"/>',&amp;
      <xsl:value-of select="$currentvariablename"/>
   <xsl:call-template name="checkError"/>
endif
         </xsl:when>
<!-- -->
         <xsl:when test="@data_type='FLT_3D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$currentvariablename"/>)) then
<xsl:choose>
  <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
    if (IDS%ids_properties%homogeneous_time.EQ.0) then
    <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
    <xsl:choose>
      <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
	timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
      </xsl:when>
      <xsl:otherwise>
	timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
      </xsl:otherwise>
    </xsl:choose>
    else
       timepath="/time"
    endif
  </xsl:when>
  <xsl:otherwise>
    timepath = ""
  </xsl:otherwise>
</xsl:choose>
   call put_vect3d_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", &amp;
   trim(timepath), <xsl:value-of select="$currentvariablename"/>, &amp;
   size(<xsl:value-of select="$currentvariablename"/>,1), &amp;
   size(<xsl:value-of select="$currentvariablename"/>,2), &amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$currentvariablename"/>,3), status) 
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentvariablename"/>',&amp;
      <xsl:value-of select="$currentvariablename"/>
   <xsl:call-template name="checkError"/>
endif
         </xsl:when>
<!-- -->
         <xsl:when test="@data_type='INT_3D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$currentvariablename"/>)) then
<xsl:choose>
  <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
    if (IDS%ids_properties%homogeneous_time.EQ.0) then
    <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
    <xsl:choose>
      <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
	timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
      </xsl:when>
      <xsl:otherwise>
	timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
      </xsl:otherwise>
    </xsl:choose>
    else
       timepath="/time"
    endif
  </xsl:when>
  <xsl:otherwise>
    timepath = ""
  </xsl:otherwise>
</xsl:choose>
   call put_vect3d_int(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", &amp;
   trim(timepath), <xsl:value-of select="$currentvariablename"/>, &amp;
   size(<xsl:value-of select="$currentvariablename"/>,1), &amp;
   size(<xsl:value-of select="$currentvariablename"/>,2), &amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$currentvariablename"/>,3), status)
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentvariablename"/>',&amp;
      <xsl:value-of select="$currentvariablename"/>
   <xsl:call-template name="checkError"/>
endif
         </xsl:when>
<!-- --> 
         <xsl:when test="@data_type='FLT_4D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$currentvariablename"/>)) then
<xsl:choose>
  <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
    if (IDS%ids_properties%homogeneous_time.EQ.0) then
    <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
    <xsl:choose>
      <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
	timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
      </xsl:when>
      <xsl:otherwise>
	timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
      </xsl:otherwise>
    </xsl:choose>
    else
       timepath="/time"
    endif
  </xsl:when>
  <xsl:otherwise>
    timepath = ""
  </xsl:otherwise>
</xsl:choose>
   call put_vect4d_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", &amp;
   trim(timepath), <xsl:value-of select="$currentvariablename"/>, &amp;
   size(<xsl:value-of select="$currentvariablename"/>,1), &amp;
   size(<xsl:value-of select="$currentvariablename"/>,2), &amp;
   size(<xsl:value-of select="$currentvariablename"/>,3), &amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$currentvariablename"/>,4), status) 
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentvariablename"/>',&amp;
      <xsl:value-of select="$currentvariablename"/>
   <xsl:call-template name="checkError"/>
endif
	 </xsl:when>
<!-- -->         
         <xsl:when test="@data_type='FLT_5D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$currentvariablename"/>)) then
<xsl:choose>
  <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
    if (IDS%ids_properties%homogeneous_time.EQ.0) then
    <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
    <xsl:choose>
      <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
	timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
      </xsl:when>
      <xsl:otherwise>
	timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
      </xsl:otherwise>
    </xsl:choose>
    else
       timepath="/time"
    endif
  </xsl:when>
  <xsl:otherwise>
    timepath = ""
  </xsl:otherwise>
</xsl:choose>
   call put_vect5d_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", &amp;
   trim(timepath), <xsl:value-of select="$currentvariablename"/>, &amp;
   size(<xsl:value-of select="$currentvariablename"/>,1), &amp;
   size(<xsl:value-of select="$currentvariablename"/>,2), &amp;
   size(<xsl:value-of select="$currentvariablename"/>,3), &amp;
   size(<xsl:value-of select="$currentvariablename"/>,4), &amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$currentvariablename"/>,5), status) 
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentvariablename"/>',&amp;
      <xsl:value-of select="$currentvariablename"/>
   <xsl:call-template name="checkError"/>
endif
         </xsl:when>
<!-- -->
         <xsl:when test="@data_type='FLT_6D'">
! Put <xsl:value-of select="@path"/>
if (associated(<xsl:value-of select="$currentvariablename"/>)) then
<xsl:choose>
  <xsl:when test="@type='dynamic' and not(ancestor::field[@type='dynamic' and @data_type='struct_array'])">
    if (IDS%ids_properties%homogeneous_time.EQ.0) then
    <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
    <xsl:choose>
      <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
	timepath=&quot;<xsl:value-of select="$objpath"/>&quot;//&quot;time&quot;
      </xsl:when>
      <xsl:otherwise>
	timepath=&quot;<xsl:call-template name="printtimepathrelative"/>&quot;
      </xsl:otherwise>
    </xsl:choose>
    else
       timepath="/time"
    endif
  </xsl:when>
  <xsl:otherwise>
    timepath = ""
  </xsl:otherwise>
</xsl:choose>
   call put_vect6d_double(aosctx<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>", &amp;
   trim(timepath), <xsl:value-of select="$currentvariablename"/>, &amp;
   size(<xsl:value-of select="$currentvariablename"/>,1), &amp;
   size(<xsl:value-of select="$currentvariablename"/>,2), &amp;
   size(<xsl:value-of select="$currentvariablename"/>,3), &amp;
   size(<xsl:value-of select="$currentvariablename"/>,4), &amp;
   size(<xsl:value-of select="$currentvariablename"/>,5), &amp;
   <xsl:choose>
     <xsl:when test="$slice='yes' and @type='dynamic'">
       1, status)
     </xsl:when>
     <xsl:otherwise>
       size(<xsl:value-of select="$currentvariablename"/>,6), status) 
     </xsl:otherwise>
   </xsl:choose>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentvariablename"/>',&amp;
      <xsl:value-of select="$currentvariablename"/>
   <xsl:call-template name="checkError"/>
endif
         </xsl:when>
<!-- -->
         <xsl:otherwise>
 ! Put <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
         </xsl:otherwise>
      </xsl:choose>
   <!-- </xsl:if> -->
   </xsl:otherwise>
 </xsl:choose>
</xsl:if>
</xsl:if>
</xsl:template>


<!--!!!!!!!!!!!!!!!!!!!!!!!!!             DELETE IDS ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="DELETE">
<xsl:param name="variable_path"/>
<xsl:param name="mds_path"/>

<xsl:variable name="new_path" select="concat($variable_path,'%',@name)"/>

<xsl:variable name="new_mds_path">
  <xsl:choose>
    <xsl:when test="$mds_path">
      <xsl:value-of select="concat(substring($mds_path,1,string-length($mds_path)-1),'/',@name,'&quot;')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="concat('&quot;',@name,'&quot;')"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:choose>
  <xsl:when test="@data_type='structure'">
    <xsl:apply-templates select="field" mode="DELETE">
      <xsl:with-param name ="variable_path" select="$new_path"/>
      <xsl:with-param name ="mds_path" select="$new_mds_path"/>
    </xsl:apply-templates>
  </xsl:when>

  <!-- Struct arrays are deleted as simple field in the new low level, so all this is commented out 
<xsl:when test="@data_type='struct_array' and @maxoccur!='unbounded'">
   <xsl:choose>
   <xsl:when test="$mds_path">
do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,<xsl:value-of select = "@maxoccur"/>
<xsl:apply-templates select = "field" mode = "DELETE">
<xsl:with-param name ="variable_path" select="concat($variable_path,'%',@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat($mds_path,'//','&quot;/',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
</xsl:apply-templates>
enddo
call delete_data(pulsectx,IDSpath,<xsl:value-of select="concat($mds_path,'//&quot;/',@name,'/Shape_of&quot;')"/>)
   </xsl:when>
   <xsl:otherwise>
do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,<xsl:value-of select = "@maxoccur"/>
      <xsl:apply-templates select = "field" mode = "DELETE">
<xsl:with-param name ="variable_path" select="concat(@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat('&quot;/',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
</xsl:apply-templates>
enddo
call delete_data(pulsectx,IDSpath,<xsl:value-of select="concat('&quot;/',@name,'/Shape_of&quot;')"/>)

   </xsl:otherwise>
   </xsl:choose>
</xsl:when>
<xsl:when test="@data_type='struct_array' and @maxoccur='unbounded'">
   <xsl:choose>
   <xsl:when test="$mds_path">
call delete_data(opctx,<xsl:value-of select="concat($mds_path,'//&quot;/',@name,'/timed&quot;')"/>, status)
call delete_data(opctx,<xsl:value-of select="concat($mds_path,'//&quot;/',@name,'/non_timed&quot;')"/>, status)
call delete_data(opctx,<xsl:value-of select="concat($mds_path,'//&quot;/',@name,'/time&quot;')"/>, status)
   </xsl:when>
   <xsl:otherwise>
call delete_data(opctx,<xsl:value-of select="concat('&quot;/',@name,'/timed&quot;')"/>, status)
call delete_data(opctx,<xsl:value-of select="concat('&quot;/',@name,'/non_timed&quot;')"/>, status)
call delete_data(opctx,<xsl:value-of select="concat('&quot;/',@name,'/time&quot;')"/>, status)
   </xsl:otherwise>
   </xsl:choose>
</xsl:when>
  -->

  <xsl:otherwise>
call delete_data(opctx, <xsl:value-of select="$new_mds_path"/>, status) 
  </xsl:otherwise>
</xsl:choose>
</xsl:template>


	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             DEALLOCATE IDS ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="DEALLOCATE">
    <xsl:param name="level"/>     <!-- recursion level -->
    <xsl:param name="variablename"/>   <!-- full fortran path including indices -->

    <!-- build the complete path of the current field -->
    <xsl:param name="currentvariablename" select="concat($variablename,'%',@name)"/>

    <xsl:choose>
<!-- xs:integer and xs:float are not deallocated (they are not allocatable !) -->
			<xsl:when test="@data_type='str_type' or @data_type='STR_0D' or @data_type='str_1d_type' or @data_type='STR_1D' or @data_type='flt_1d_type' or @data_type='FLT_1D' or @data_type='int_1d_type' or @data_type='INT_1D' or @data_type='FLT_2D' or @data_type='INT_2D' or @data_type='FLT_3D' or @data_type='INT_3D' or @data_type='FLT_4D' or @data_type='FLT_5D' or @data_type='FLT_6D' ">
   ! deallocate <xsl:value-of select="@path"/>
   if (associated(<xsl:value-of select="$currentvariablename"/>)) then
        deallocate(<xsl:value-of select="$currentvariablename"/>)
   endif
   			</xsl:when>
			<xsl:when test="@data_type='structure'">
				<xsl:apply-templates select="field" mode="DEALLOCATE">
                <xsl:with-param name="level" select="$level"/>
                <xsl:with-param name="variablename" select="$currentvariablename"/>
            </xsl:apply-templates>
			</xsl:when>
         <xsl:when test="@data_type='struct_array'">
    ! deallocate <xsl:value-of select="@path"/>
    if (associated(<xsl:value-of select="$currentvariablename"/>)) then
        do i<xsl:value-of select="$level"/> = 1,size(<xsl:value-of select = "$currentvariablename"/>)
             <xsl:apply-templates select="field" mode="DEALLOCATE">
                 <xsl:with-param name="level" select="$level + 1"/>
                 <xsl:with-param name="variablename" select="concat($currentvariablename,'(i',$level,')')"/>
             </xsl:apply-templates>
        enddo
        deallocate(<xsl:value-of select="$currentvariablename"/>)
    endif
         </xsl:when>
		</xsl:choose>
	</xsl:template>


	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             FLUSH IDS ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
	<!--<xsl:template match="IDS" mode="FLUSH_CACHE">
        </xsl:template>-->
	<xsl:template match="field" mode="FLUSH_CACHE">
		<xsl:choose>
			<xsl:when test="@name='structure'">
				<!-- If the node is a substructure, call flush recursively on the children -->
				<xsl:apply-templates select="field" mode="FLUSH_CACHE"/>
			</xsl:when>
			<xsl:otherwise>
call ids_flush_cache(pulsectx,IDSpath,"<xsl:value-of select="@path"/>")         <!-- call to the low level ids_flush_cache routine -->
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

<!--!!!!!!!!!!!!!!!!!!!!!!!!!             DISCARD IDS ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="DISCARD_CACHE">
<xsl:param name="variable_path"/>
<xsl:param name="mds_path"/>
<xsl:choose>
<xsl:when test="@data_type='structure'">
   <xsl:choose>
   <xsl:when test="$variable_path">
   <xsl:apply-templates select="field" mode="DISCARD_CACHE">
   <xsl:with-param name ="variable_path" select="concat($variable_path,'%',@name)"/>
   <xsl:with-param name ="mds_path" select="concat($mds_path,'//&quot;/',@name,'&quot;')"/>
   </xsl:apply-templates>
   </xsl:when>
   <xsl:otherwise>
   <xsl:apply-templates select="field" mode="DISCARD_CACHE">
   <xsl:with-param name ="variable_path" select="@name"/>
   <xsl:with-param name ="mds_path" select="concat('&quot;',@name,'&quot;')"/>
   </xsl:apply-templates>
   </xsl:otherwise>
   </xsl:choose>
</xsl:when>
<xsl:when test="@data_type='struct_array'">
   <xsl:choose>
   <xsl:when test="$mds_path">
do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,<xsl:value-of select = "@maxoccur"/>
<xsl:apply-templates select = "field" mode = "DISCARD_CACHE">
<xsl:with-param name ="variable_path" select="concat($variable_path,'%',@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat($mds_path,'//','&quot;/',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
</xsl:apply-templates>
enddo
   </xsl:when>
   <xsl:otherwise>
do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,<xsl:value-of select = "@maxoccur"/>
      <xsl:apply-templates select = "field" mode = "DISCARD_CACHE">
<xsl:with-param name ="variable_path" select="concat(@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat('&quot;/',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
</xsl:apply-templates>
enddo
   </xsl:otherwise>
   </xsl:choose>
</xsl:when>
			<xsl:otherwise>
   <xsl:choose>
   <xsl:when test="$mds_path">
call ids_discard_cache(pulsectx,IDSpath,<xsl:value-of select="concat($mds_path,'//&quot;/',@name,'&quot;')"/>)         <!-- call to the low level ids_discard_cache routine -->
   </xsl:when>
   <xsl:otherwise>
call ids_discard_cache(pulsectx,IDSpath,"<xsl:value-of select="@path"/>")         <!-- call to the low level delete_data routine -->
   </xsl:otherwise>
   </xsl:choose>
</xsl:otherwise>
</xsl:choose>
</xsl:template>


<xsl:template name ="checkError">
	<xsl:param name="method"/>  <!-- Seems we can get rid of this parameter with the new ual_end_action method -->
   if(isErrorCritical(status, "<xsl:value-of select="ancestor::IDS/@name"/> : <xsl:value-of select="@path"/>")) then
        call ual_end_action(opctx, status)
        return
   endif
</xsl:template>


<xsl:template name="evaluate_time_path_mdspath">
  <xsl:param name="mds_path"/>
  <xsl:choose>
    <xsl:when test="@type='dynamic'">
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
   <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
   <xsl:choose>
     <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=<xsl:value-of select="$mds_path"/>//&quot;/time&quot;
     </xsl:when>
     <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
     </xsl:otherwise>
   </xsl:choose>
   else
       timepath="/time"
   endif
    </xsl:when>
    <xsl:otherwise>
   timepath = ''
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="evaluate_time_path_simple">
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%ids_properties%homogeneous_time.EQ.0) then
       timepath="<xsl:call-template name="printtimepath"/>"
   else
       timepath="/time"
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
</xsl:template>




<xsl:template name ="printtimepathrelative">
<xsl:if test="@type = 'dynamic'">
<xsl:choose>
<xsl:when test="contains(@coordinate7_AosParent_relative,'time')"> <xsl:value-of select="@coordinate7_AosParent_relative"/></xsl:when> <!-- We remove the (itime) pattern from the coordinate attribute in IDSDef, which is documentation-oriented -->
<xsl:when test="contains(@coordinate6_AosParent_relative,'time')"> <xsl:value-of select="@coordinate6_AosParent_relative"/></xsl:when>
<xsl:when test="contains(@coordinate5_AosParent_relative,'time')"> <xsl:value-of select="@coordinate5_AosParent_relative"/></xsl:when>
<xsl:when test="contains(@coordinate4_AosParent_relative,'time')"> <xsl:value-of select="@coordinate4_AosParent_relative"/></xsl:when>
<xsl:when test="contains(@coordinate3_AosParent_relative,'time')"> <xsl:value-of select="@coordinate3_AosParent_relative"/></xsl:when>
<xsl:when test="contains(@coordinate2_AosParent_relative,'time')"> <xsl:value-of select="@coordinate2_AosParent_relative"/></xsl:when>
<xsl:when test="contains(@coordinate1_AosParent_relative,'time')"> <xsl:value-of select="@coordinate1_AosParent_relative"/></xsl:when>
</xsl:choose>
</xsl:if>
<xsl:if test="@name='time'"><xsl:value-of select="@path"/></xsl:if>  <!-- If the field itself IS time, then it is its own time coordinate -->
</xsl:template>

<xsl:template name ="printtimepath">
<xsl:if test="@type = 'dynamic'">
<xsl:choose>
<xsl:when test="contains(@coordinate7,'time')"> <xsl:value-of select="translate(replace(@coordinate7,'(itime)',''),'()','')"/></xsl:when> <!-- We remove the (itime) pattern from the coordinate attribute in IDSDef, which is documentation-oriented -->
<xsl:when test="contains(@coordinate6,'time')"> <xsl:value-of select="translate(replace(@coordinate6,'(itime)',''),'()','')"/></xsl:when>
<xsl:when test="contains(@coordinate5,'time')"> <xsl:value-of select="translate(replace(@coordinate5,'(itime)',''),'()','')"/></xsl:when>
<xsl:when test="contains(@coordinate4,'time')"> <xsl:value-of select="translate(replace(@coordinate4,'(itime)',''),'()','')"/></xsl:when>
<xsl:when test="contains(@coordinate3,'time')"> <xsl:value-of select="translate(replace(@coordinate3,'(itime)',''),'()','')"/></xsl:when>
<xsl:when test="contains(@coordinate2,'time')"> <xsl:value-of select="translate(replace(@coordinate2,'(itime)',''),'()','')"/></xsl:when>
<xsl:when test="contains(@coordinate1,'time')"> <xsl:value-of select="translate(replace(@coordinate1,'(itime)',''),'()','')"/></xsl:when>
</xsl:choose>
</xsl:if>
<xsl:if test="@name='time'"><xsl:value-of select="@path"/></xsl:if>  <!-- If the field itself IS time, then it is its own time coordinate -->
</xsl:template>

<xsl:template name ="printtimevariable">
<xsl:if test="@type = 'dynamic'">
<xsl:choose>
<xsl:when test="contains(@coordinate7,'time')"> IDS%<xsl:value-of select="translate(@coordinate7,'/','%')"/></xsl:when>
<xsl:when test="contains(@coordinate6,'time')"> IDS%<xsl:value-of select="translate(@coordinate6,'/','%')"/></xsl:when>
<xsl:when test="contains(@coordinate5,'time')"> IDS%<xsl:value-of select="translate(@coordinate5,'/','%')"/></xsl:when>
<xsl:when test="contains(@coordinate4,'time')"> IDS%<xsl:value-of select="translate(@coordinate4,'/','%')"/></xsl:when>
<xsl:when test="contains(@coordinate3,'time')"> IDS%<xsl:value-of select="translate(@coordinate3,'/','%')"/></xsl:when>
<xsl:when test="contains(@coordinate2,'time')"> IDS%<xsl:value-of select="translate(@coordinate2,'/','%')"/></xsl:when>
<xsl:when test="contains(@coordinate1,'time')"> IDS%<xsl:value-of select="translate(@coordinate1,'/','%')"/></xsl:when>
</xsl:choose>
</xsl:if>
<xsl:if test="@name='time'">IDS%<xsl:value-of select="translate(@path,'/','%')"/></xsl:if>  <!-- If the field itself IS time, then it is its own time coordinate -->
</xsl:template>

<xsl:template name ="printIsTimed">
<xsl:choose><xsl:when test="@type = 'dynamic'"> <xsl:value-of select="1"/> </xsl:when> <xsl:otherwise> <xsl:value-of select="0"/> </xsl:otherwise> </xsl:choose>
</xsl:template>

<xsl:template name="isCriticalFunc">
FUNCTION isErrorCritical(status, fieldPath) RESULT (exitRequest)
        use ids_types
	integer(ids_int) :: status
	character*(*) :: fieldPath
	logical :: exitRequest
	character(len=100000)::longstring

	exitRequest = .FALSE.

	if(status == 0) then
		exitRequest = .FALSE.
		return
	endif

	!if(0 .NE. is_critical_error(status) ) then
	!	exitRequest = .TRUE.
	!endif
	!if ( (ual_debug == 'yes') .OR. (ual_debug == 'vvv') .OR. exitRequest)then
	!	call get_last_errmsg(longstring)
	!	write(*,*) "ERROR! FIELD: ", trim(fieldPath), "    STATUS: ", status, "    MSG: ", trim(longstring)
	!endif
END FUNCTION isErrorCritical
</xsl:template>



</xsl:stylesheet>
