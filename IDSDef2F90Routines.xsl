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
use <xsl:value-of select="@name"/>_put_struct
use <xsl:value-of select="@name"/>_put_slice_struct
use <xsl:value-of select="@name"/>_get_struct
use <xsl:value-of select="@name"/>_get_slice_struct
use <xsl:value-of select="@name"/>_delete
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

<xsl:apply-templates select="/IDSs/utilities" mode="put_struct"/> 
<xsl:apply-templates select="IDS" mode="put_struct"/> 

<xsl:apply-templates select="/IDSs/utilities" mode="put_slice_struct"/> 
<xsl:apply-templates select="IDS" mode="put_slice_struct"/> 

<xsl:apply-templates select="/IDSs/utilities" mode="get_struct"/> 
<xsl:apply-templates select="IDS" mode="get_struct"/> 

<xsl:apply-templates select="IDS" mode="get_slice_struct"/> 

<xsl:apply-templates select="IDS" mode="delete"/>

</xsl:template>




<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_DELETE MODULE, PER IDS                                              -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="IDS" mode="delete">
  <xsl:result-document href="{@name}_delete.f90">
module <xsl:value-of select="@name"/>_delete

! Declaration of the generic IDS DELETE routine
interface ids_delete
  module procedure ids_delete_<xsl:value-of select="@name"/> <!-- subroutine for the whole IDS -->
end interface 

contains

!!!!!! Routine to DELETE the IDS
subroutine ids_delete_<xsl:value-of select="@name"/>(pulsectx, IDSpath, IDS)  <!-- systematic calls to the low level delete_data routine. The IDS input argument is added just for the interface to identify the relevant IDS type -->
  use ids_schemas
  use ual_low_level_wrap
  implicit none
  character*(*) :: IDSpath
  integer(ids_int) :: pulsectx, opctx, status
  type(ids_<xsl:value-of select="@name"/>) :: IDS

  call ual_begin_global_action(pulsectx, IDSpath, WRITE_OP, opctx)
  if (opctx.lt.0) then
     STOP 'Error in ual_begin_global_action (from ids_delete for IDS <xsl:value-of select="@name"/>)'
  end if

  <xsl:apply-templates select="field" mode="DELETE"/>

  call ual_end_action(opctx,status)

end subroutine ids_delete_<xsl:value-of select="@name"/>

end module <xsl:value-of select="@name"/>_delete
  </xsl:result-document>
</xsl:template>




<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_DEALLOCATE MODULE, UTILITIES                                        -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="utilities" mode="deallocate_struct">
  <xsl:result-document href="utilities_deallocate_struct.f90">
module utilities_deallocate_struct

interface ids_deallocate_struct
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
end interface 

interface ids_deallocate_struct
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

interface ids_copy_struct
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
  module procedure ids_copy_struct_<xsl:value-of select="@name"/>
end interface 

interface ids_copy_struct
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
<!-- IDS_PUT MODULE, UTILITIES                                               -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="utilities" mode="put_struct">
  <xsl:result-document href="utilities_put_struct.f90">
module utilities_put_struct

interface ids_put_struct
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
      module procedure put_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>
  </xsl:for-each>
end interface

 contains

<xsl:call-template name="isCriticalFuncCtx"/>

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

subroutine put_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>(ctx, path, struct, homogeneous, timedparent, retstatus)
  use ids_schemas
  use ual_low_level_wrap
  implicit none

  integer(ids_int), intent(in) :: ctx
  character*(*), intent(in) :: path
  type(ids_<xsl:value-of select="$this-type"/>), intent(in) :: struct
  logical, intent(in) :: homogeneous, timedparent
  integer(ids_int), intent(out) :: retstatus
  integer(ids_int) :: i, aoslen, lenstring, aosctx, lastdimsize
  integer :: status
  character(len=100000) :: longstring
  character(len=300) :: timepath

  <xsl:apply-templates select="./field" mode="PUT_FIELD">
    <xsl:with-param name="structvar" select="'struct'"/>
    <xsl:with-param name="contextvar" select="'ctx'"/>
    <xsl:with-param name="timedparentexpr" select="'timedparent.or.'"/>
  </xsl:apply-templates>      
   retstatus = 0
end subroutine put_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>

  </xsl:if>
</xsl:for-each>

end module 
  </xsl:result-document>
</xsl:template>


<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_PUT MODULE, PER IDS                                                 -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="IDS" mode="put_struct">
  <xsl:result-document href="{@name}_put.f90">
module <xsl:value-of select="@name"/>_put_struct

use utilities_put_struct

interface ids_put
  module procedure put_struct_ids_<xsl:value-of select="@name"/> <!-- subroutine for the whole IDS -->
end interface

interface ids_put_struct
  <xsl:for-each select=".//field[@data_type='structure' or @data_type='struct_array']">
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
  module procedure put_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>
    </xsl:if>
  </xsl:for-each>
end interface

 contains 

<!-- <xsl:call-template name="isCriticalFuncCtx"/> done in utilities! -->

<!-- subroutine for the whole IDS -->
!!! Routines to PUT the full IDS !!!
subroutine put_struct_ids_<xsl:value-of select="@name"/>(pulsectx, path, IDS)
  use ids_schemas
  use ual_low_level_wrap
  use <xsl:value-of select="@name"/>_delete  
  implicit none

  integer(ids_int) :: status = 0, retstatus
  character*(*) :: path
  integer(ids_int) :: pulsectx, opctx, aosctx
  type(ids_<xsl:value-of select="@name"/>) :: IDS
  ! internal variables declaration
  logical :: homogeneous, timedparent
  integer(ids_int) :: aoslen, i, lenstring, lastdimsize
  character(len=100000) :: longstring
  character(len=300) :: timepath

  ! Systematic delete of the previous IDS, in case it existed
  call ids_delete(pulsectx, path, IDS)

  if (IDS%ids_properties%homogeneous_time.EQ.ids_int_invalid) then
     write(*,*) "ERROR : the IDS%ids_properties%homogeneous_time property of this IDS must be provided"
     return
  endif
  homogeneous = IDS%ids_properties%homogeneous_time.EQ.1
  if ((homogeneous).AND.(.NOT.(associated(IDS%time)))) then
     write(*,*) "ERROR : the IDS%time vector of an homogeneous_time IDS must be associated"
     return
  endif

  call begin_ids_put_timed(pulsectx, path, opctx)
  if (opctx.lt.0) then
     STOP 'Error in begin_ids_put_timed (from ids_put for IDS amns_data)'
  end if

  timedparent=.false.
  <xsl:apply-templates select="./field" mode="PUT_FIELD">
    <xsl:with-param name="structvar" select="'IDS'"/>
    <xsl:with-param name="contextvar" select="'opctx'"/>
    <xsl:with-param name="timedparentexpr" select="''"/>
  </xsl:apply-templates>
end subroutine put_struct_ids_<xsl:value-of select="@name"/>

<xsl:for-each select=".//field[@data_type='structure' or @data_type='struct_array']">
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
subroutine put_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>(ctx, path, struct, homogeneous, timedparent, retstatus)
  use ids_schemas
  use ual_low_level_wrap
  implicit none

  integer(ids_int), intent(in) :: ctx
  character*(*), intent(in) :: path
  type(ids_<xsl:value-of select="$this-type"/>), intent(in) :: struct      
  logical, intent(in) :: homogeneous, timedparent
  integer(ids_int), intent(out) :: retstatus
  integer(ids_int) :: i, aoslen, lenstring, aosctx, lastdimsize
  integer :: status
  character(len=100000) :: longstring
  character(len=300) :: timepath

  <xsl:apply-templates select="./field" mode="PUT_FIELD">
    <xsl:with-param name="structvar" select="'struct'"/>
    <xsl:with-param name="contextvar" select="'ctx'"/>
    <xsl:with-param name="timedparentexpr" select="'timedparent.or.'"/>
  </xsl:apply-templates>      
   retstatus = 0
end subroutine put_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>

  </xsl:if>
</xsl:for-each>

end module    
  </xsl:result-document>
</xsl:template>




<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_PUT_SLICE MODULE, UTILITIES                                         -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="utilities" mode="put_slice_struct">
  <xsl:result-document href="utilities_put_slice_struct.f90">
module utilities_put_slice_struct

interface ids_put_slice_struct
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
      module procedure put_slice_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>
  </xsl:for-each>
end interface

 contains

<xsl:call-template name="isCriticalFuncCtx"/>

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

subroutine put_slice_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>(ctx, path, struct, homogeneous, timedparent, retstatus)
  use ids_schemas
  use ual_low_level_wrap
  implicit none

  integer(ids_int), intent(in) :: ctx
  character*(*), intent(in) :: path
  type(ids_<xsl:value-of select="$this-type"/>), intent(in) :: struct
  logical, intent(in) :: homogeneous, timedparent
  integer(ids_int), intent(out) :: retstatus
  integer(ids_int) :: i, aoslen, lenstring, aosctx, lastdimsize
  integer :: status
  character(len=100000) :: longstring
  character(len=300) :: timepath

  <xsl:apply-templates select="./field" mode="PUT_FIELD">
    <xsl:with-param name="structvar" select="'struct'"/>
    <xsl:with-param name="contextvar" select="'ctx'"/>
    <xsl:with-param name="timedparentexpr" select="'timedparent.or.'"/>
    <xsl:with-param name="slice" select="'yes'"/>
  </xsl:apply-templates>      
   retstatus = 0
end subroutine put_slice_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>

  </xsl:if>
</xsl:for-each>

end module 
  </xsl:result-document>
</xsl:template>


<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_PUT_SLICE MODULE, PER IDS                                           -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="IDS" mode="put_slice_struct">
  <xsl:result-document href="{@name}_put_slice.f90">
module <xsl:value-of select="@name"/>_put_slice_struct

use utilities_put_slice_struct

interface ids_put_slice
  module procedure put_slice_struct_ids_<xsl:value-of select="@name"/> <!-- subroutine for the whole IDS -->
end interface 

interface ids_put_slice_struct
  <xsl:for-each select=".//field[@data_type='structure' or @data_type='struct_array']">
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
  module procedure put_slice_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>
    </xsl:if>
  </xsl:for-each>
end interface

 contains 

<!-- subroutine for the whole IDS -->
!!! Routines to PUT_SLICE one time slice of an IDS !!!
subroutine put_slice_struct_ids_<xsl:value-of select="@name"/>(pulsectx, path, IDS)
  use ids_schemas
  use ual_low_level_wrap
  implicit none

  integer(ids_int) :: status = 0, retstatus
  character*(*) :: path
  integer(ids_int) :: pulsectx, opctx, aosctx
  type(ids_<xsl:value-of select="@name"/>) :: IDS
  ! internal variables declaration
  logical :: homogeneous, timedparent
  integer(ids_int) :: aoslen, i, lenstring, lastdimsize
  character(len=100000) :: longstring
  character(len=300) :: timepath

  homogeneous = IDS%ids_properties%homogeneous_time.EQ.1
  if (.not.homogeneous) then
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

  timedparent=.false.
  <xsl:apply-templates select="./field" mode="PUT_FIELD">
    <xsl:with-param name="structvar" select="'IDS'"/>
    <xsl:with-param name="contextvar" select="'opctx'"/>
    <xsl:with-param name="timedparentexpr" select="''"/>
    <xsl:with-param name="slice" select="'yes'"/>
  </xsl:apply-templates>
end subroutine put_slice_struct_ids_<xsl:value-of select="@name"/>

<xsl:for-each select=".//field[@data_type='structure' or @data_type='struct_array']">
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
subroutine put_slice_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>(ctx, path, struct, homogeneous, timedparent, retstatus)
  use ids_schemas
  use ual_low_level_wrap
  implicit none

  integer(ids_int), intent(in) :: ctx
  character*(*), intent(in) :: path
  type(ids_<xsl:value-of select="$this-type"/>), intent(in) :: struct      
  logical, intent(in) :: homogeneous, timedparent
  integer(ids_int), intent(out) :: retstatus
  integer(ids_int) :: i, aoslen, lenstring, aosctx, lastdimsize
  integer :: status
  character(len=100000) :: longstring
  character(len=300) :: timepath

  <xsl:apply-templates select="./field" mode="PUT_FIELD">
    <xsl:with-param name="structvar" select="'struct'"/>
    <xsl:with-param name="contextvar" select="'ctx'"/>
    <xsl:with-param name="timedparentexpr" select="'timedparent.or.'"/>
    <xsl:with-param name="slice" select="'yes'"/>
  </xsl:apply-templates>      
   retstatus = 0
end subroutine put_slice_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>

  </xsl:if>
</xsl:for-each>

end module    
  </xsl:result-document>
</xsl:template>





<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_GET MODULE, UTILITIES                                               -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="utilities" mode="get_struct">
  <xsl:result-document href="utilities_get_struct.f90">
module utilities_get_struct

interface ids_get_struct
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
      module procedure get_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>
  </xsl:for-each>
end interface

 contains

<xsl:call-template name="isCriticalFuncCtx"/>

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

subroutine get_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>(ctx, path, struct, homogeneous, timedparent, retstatus)
  use ids_schemas
  use ual_low_level_wrap
  implicit none

  integer(ids_int), intent(in) :: ctx
  character*(*), intent(in) :: path
  type(ids_<xsl:value-of select="$this-type"/>), intent(inout) :: struct
  logical, intent(in) :: homogeneous, timedparent
  integer(ids_int), intent(out) :: retstatus
  integer(ids_int) :: i, aoslen, lenstring, aosctx
  integer(ids_int) :: size1, size2, size3, size4, size5, size6, size7
  integer :: status
  character(len=100000) :: longstring
  character(len=300) :: timepath

  <xsl:apply-templates select="./field" mode="GET_FIELD">
    <xsl:with-param name="structvar" select="'struct'"/>
    <xsl:with-param name="contextvar" select="'ctx'"/>
    <xsl:with-param name="timedparentexpr" select="'timedparent.or.'"/>
  </xsl:apply-templates>      
   retstatus = 0
end subroutine get_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>

  </xsl:if>
</xsl:for-each>

end module 
  </xsl:result-document>
</xsl:template>


<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_GET MODULE, PER IDS                                                 -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="IDS" mode="get_struct">
  <xsl:result-document href="{@name}_get.f90">
module <xsl:value-of select="@name"/>_get_struct

use utilities_get_struct

interface ids_get
  module procedure get_struct_ids_<xsl:value-of select="@name"/> <!-- subroutine for the whole IDS -->
end interface 

interface ids_get_struct
  <xsl:for-each select=".//field[@data_type='structure' or @data_type='struct_array']">
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
  module procedure get_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>
    </xsl:if>
  </xsl:for-each>
end interface

 contains 

<!-- <xsl:call-template name="isCriticalFuncCtx"/> done in utilities! -->

<!-- subroutine for the whole IDS -->
!!! Routines to GET the full IDS !!!
subroutine get_struct_ids_<xsl:value-of select="@name"/>(pulsectx, path, IDS)
  use ids_schemas
  use ual_low_level_wrap
  implicit none

  integer(ids_int) :: status = 0, retstatus
  character*(*) :: path
  integer(ids_int) :: pulsectx, opctx, aosctx
  type(ids_<xsl:value-of select="@name"/>) :: IDS
  ! internal variables declaration
  logical :: homogeneous, timedparent
  integer(ids_int) :: aoslen, i, lenstring
  integer(ids_int) :: size1, size2, size3, size4, size5, size6, size7
  character(len=100000) :: longstring
  character(len=300) :: timepath

  call begin_IDS_get(pulsectx, path, opctx) 
  if (opctx.lt.0) then
     !! error when trying to get new ctx => stop!
     STOP 'Error in begin_ids_get (from ids_get for IDS <xsl:value-of select="@name"/>)'
  end if

  timedparent=.false.
  <xsl:apply-templates select="./field" mode="GET_FIELD">
    <xsl:with-param name="structvar" select="'IDS'"/>
    <xsl:with-param name="contextvar" select="'opctx'"/>
    <xsl:with-param name="timedparentexpr" select="''"/>
  </xsl:apply-templates>

  call ual_end_action(opctx, status)

  call set_c_data(IDS,.true.)

  return
end subroutine get_struct_ids_<xsl:value-of select="@name"/>


<xsl:for-each select=".//field[@data_type='structure' or @data_type='struct_array']">
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
subroutine get_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>(ctx, path, struct, homogeneous, timedparent, retstatus)
  use ids_schemas
  use ual_low_level_wrap
  implicit none

  integer(ids_int), intent(in) :: ctx
  character*(*), intent(in) :: path
  type(ids_<xsl:value-of select="$this-type"/>), intent(inout) :: struct      
  logical, intent(in) :: homogeneous, timedparent
  integer(ids_int), intent(out) :: retstatus
  integer(ids_int) :: i, aoslen, lenstring, aosctx
  integer(ids_int) :: size1, size2, size3, size4, size5, size6, size7
  integer :: status
  character(len=100000) :: longstring
  character(len=300) :: timepath

  <xsl:apply-templates select="./field" mode="GET_FIELD">
    <xsl:with-param name="structvar" select="'struct'"/>
    <xsl:with-param name="contextvar" select="'ctx'"/>
    <xsl:with-param name="timedparentexpr" select="'timedparent.or.'"/>
  </xsl:apply-templates>      
   retstatus = 0
end subroutine get_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>

  </xsl:if>
</xsl:for-each>

end module    
  </xsl:result-document>
</xsl:template>



<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_GET_SLICE MODULE, PER IDS                                           -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="IDS" mode="get_slice_struct">
  <xsl:result-document href="{@name}_get_slice.f90">
module <xsl:value-of select="@name"/>_get_slice_struct

use utilities_get_struct
use <xsl:value-of select="@name"/>_get_struct

interface ids_get_slice
  module procedure get_slice_struct_ids_<xsl:value-of select="@name"/> <!-- subroutine for the whole IDS -->
<!--
  <xsl:for-each select=".//field[@data_type='structure' or @data_type='struct_array']">
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
  module procedure get_slice_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>
    </xsl:if>
  </xsl:for-each>
-->
end interface

 contains 

<!-- subroutine for the whole IDS -->
!!! Routines to GET one time slice of an IDS, with time interpolation !!!
subroutine get_slice_struct_ids_<xsl:value-of select="@name"/>(pulsectx, path, IDS, twant, interpol)
  use ids_schemas
  use ual_low_level_wrap
  implicit none

  integer(ids_int) :: status = 0, retstatus
  character*(*) :: path
  real(ids_real), intent(in) :: twant
  integer(ids_int), intent(in) :: interpol
  integer(ids_int) :: pulsectx, opctx, aosctx
  type(ids_<xsl:value-of select="@name"/>) :: IDS
  ! internal variables declaration
  logical :: homogeneous, timedparent
  integer(ids_int) :: aoslen, i, lenstring
  integer(ids_int) :: size1, size2, size3, size4, size5, size6, size7
  character(len=100000) :: longstring
  character(len=300) :: timepath

  call begin_ids_get_slice(pulsectx, path, twant, interpol, opctx)
  if (opctx.lt.0) then
     !! error when trying to get new ctx => stop!
     STOP 'Error in begin_ids_get_slice (from ids_get_slice for IDS <xsl:value-of select="@name"/>)'
  end if

  timedparent=.false.
  <xsl:apply-templates select="./field" mode="GET_FIELD">
    <xsl:with-param name="structvar" select="'IDS'"/>
    <xsl:with-param name="contextvar" select="'opctx'"/>
    <xsl:with-param name="timedparentexpr" select="''"/>
  </xsl:apply-templates>

  call ual_end_action(opctx, status)

  call set_c_data(IDS,.true.)

  return
end subroutine get_slice_struct_ids_<xsl:value-of select="@name"/>

<!--
<xsl:for-each select=".//field[@data_type='structure' or @data_type='struct_array']">
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
subroutine get_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>(ctx, path, struct, homogeneous, timedparent, retstatus)
  use ids_schemas
  use ual_low_level_wrap
  implicit none

  integer(ids_int), intent(in) :: ctx
  character*(*), intent(in) :: path
  type(ids_<xsl:value-of select="$this-type"/>), intent(inout) :: struct      
  logical, intent(in) :: homogeneous, timedparent
  integer(ids_int), intent(out) :: retstatus
  integer(ids_int) :: i, aoslen, lenstring, aosctx
  integer(ids_int) :: size1, size2, size3, size4, size5, size6, size7
  integer :: status
  character(len=100000) :: longstring
  character(len=300) :: timepath

  <xsl:apply-templates select="./field" mode="GET_FIELD">
    <xsl:with-param name="structvar" select="'struct'"/>
    <xsl:with-param name="contextvar" select="'ctx'"/>
    <xsl:with-param name="timedparentexpr" select="'timedparent.or.'"/>
  </xsl:apply-templates>      
   retstatus = 0
end subroutine get_struct_ids_<xsl:value-of select="local:unique_name($this-type)"/>

  </xsl:if>
</xsl:for-each>
-->

end module    
  </xsl:result-document>
</xsl:template>












<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!--                                                                         -->
<!--                                TEMPLATES                                -->
<!--                                                                         -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->




<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_DELETE TEMPLATE                                                     -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="field" mode="DELETE">
  <xsl:param name="field_path"/>

  <xsl:variable name="updated_field_path">
    <xsl:choose>
      <xsl:when test="$field_path">
	<xsl:value-of select="concat(substring($field_path,1,string-length($field_path)-1),'/',@name,'&quot;')"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="concat('&quot;',@name,'&quot;')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:choose>
    <xsl:when test="@data_type='structure'">
      <xsl:apply-templates select="field" mode="DELETE">
	<xsl:with-param name ="field_path" select="$updated_field_path"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>call delete_data(opctx, <xsl:value-of select="$updated_field_path"/>, status)
    </xsl:otherwise>
  </xsl:choose>
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



<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_PUT TEMPLATE                                                        -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="field" mode="PUT_FIELD">
  <xsl:param name="structvar"/>
  <xsl:param name="contextvar"/>
  <xsl:param name="timedparentexpr"/>
  <xsl:param name="slice"/>

  <xsl:if test="$slice !='yes' or @type ='dynamic' or @data_type='structure' or (@data_type='struct_array' and .//field[@type='dynamic'])"> <!-- This skips the routine for non-timed fields when using this template in PUT_SLICE mode -->

    <xsl:variable name="fieldvar"><xsl:value-of select="$structvar"/>%<xsl:value-of select="@name"/></xsl:variable>
    <xsl:variable name="timedexpr">
      <xsl:choose>
	<xsl:when test="@type='dynamic'"><xsl:value-of select="$timedparentexpr"/>.true.</xsl:when>
	<xsl:otherwise><xsl:value-of select="$timedparentexpr"/>.false.</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="fieldpath">
      <xsl:choose>
	<xsl:when test="$contextvar='aosctx' or $contextvar='opctx'">"<xsl:value-of select="@name"/>"</xsl:when>
	<xsl:otherwise>path//"<xsl:value-of select="@name"/>"</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

<!-- Detect type of the field -->
<xsl:choose>

  <!-- Array of structure -->
  <xsl:when test="@data_type='struct_array' and $contextvar!='aosctx'">
    <xsl:variable name="this-type">
      <xsl:choose>
	<xsl:when test="@structure_reference='self'">
	  <xsl:value-of select="local:unique_name(@name)"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="local:unique_name(@structure_reference)"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    ! Put <xsl:value-of select="@name"/>
    if (associated(<xsl:value-of select="$fieldvar"/>)) then
       aoslen = size(<xsl:value-of select="$fieldvar"/>)
       <xsl:choose>
	 <xsl:when test="@type='dynamic'">
       if (homogeneous) then
          timepath = "/time"
       else
          timepath = <xsl:value-of select="$fieldpath"/>//"/time"
       endif
	 </xsl:when>
	 <xsl:otherwise>
       timepath = ""
	 </xsl:otherwise>
       </xsl:choose>
       call ual_begin_arraystruct_action(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>, timepath, aoslen, aosctx)
       if (aosctx.ge.0) then
          do i = 1,aoslen
	  <xsl:apply-templates select="." mode="PUT_FIELD">
	    <xsl:with-param name="structvar" select="$structvar"/>
	    <xsl:with-param name="contextvar" select="'aosctx'"/>
	    <xsl:with-param name="timedparentexpr" select="'timedparent.or.'"/>
	    <xsl:with-param name="slice" select="$slice"/>
	  </xsl:apply-templates> 
             call ual_iterate_over_arraystruct(aosctx, 1, status)
          enddo
          call ual_end_action(aosctx, status)
       endif
    endif
  </xsl:when>

  <!-- Structure -->
  <xsl:when test="@data_type='structure' or (@data_type='struct_array' and $contextvar='aosctx')">
    <xsl:variable name="this-type">
      <xsl:choose>
	<xsl:when test="@structure_reference='self'">
	  <xsl:value-of select="local:unique_name(@name)"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="local:unique_name(@structure_reference)"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    ! Put <xsl:value-of select="@name"/>
    call put_<xsl:if test="$slice='yes'">slice_</xsl:if>struct_ids_<xsl:value-of select="$this-type"/>(<xsl:value-of select="$contextvar"/>, &amp;
    <xsl:choose>
      <xsl:when test="$contextvar='aosctx'">'', </xsl:when>
      <xsl:otherwise><xsl:value-of select="concat(substring($fieldpath,1,string-length($fieldpath)-1),'/&quot;')"/>, </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="$fieldvar"/><xsl:if test="@data_type='struct_array'">(i)</xsl:if>, homogeneous, <xsl:value-of select="$timedexpr"/>, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'put'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
      <xsl:with-param name="closectx" select="'yes'"/>
    </xsl:call-template>
  </xsl:when>

  <!-- String data -->
  <xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
    ! Put <xsl:value-of select="@name"/>
    if (associated(<xsl:value-of select="$fieldvar"/>)) then
       call pack_string(<xsl:value-of select="$fieldvar"/>, longstring, lenstring)
       call put_string(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          '', longstring(1:lenstring), status)
       <xsl:call-template name="checkErrorCtx">
         <xsl:with-param name="method" select="'put'"/>
	 <xsl:with-param name="ctx" select="$contextvar"/>
	 <xsl:with-param name="path" select="$fieldpath"/>
       </xsl:call-template>
    endif
  </xsl:when>

  <!-- 1D array of string data -->
  <xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
    ! Put <xsl:value-of select="@name"/>
    if (associated(<xsl:value-of select="$fieldvar"/>)) then
    <xsl:call-template name="set_timepath_and_lastdimsize">
      <xsl:with-param name="slice" select="$slice"/>
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
      <xsl:with-param name="rank" select="1"/>
    </xsl:call-template>
    call put_vect1d_string(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
       trim(timepath), <xsl:value-of select="$fieldvar"/>, lastdimsize, status)
       <xsl:call-template name="checkErrorCtx">
         <xsl:with-param name="method" select="'put'"/>
	 <xsl:with-param name="ctx" select="$contextvar"/>
	 <xsl:with-param name="path" select="$fieldpath"/>
       </xsl:call-template>
    endif
  </xsl:when>

  <!-- integer scalar data -->
  <xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
    ! Put <xsl:value-of select="@name"/>
    if (<xsl:value-of select="$fieldvar"/>.NE.ids_int_invalid) then
       call put_int(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          '', <xsl:value-of select="$fieldvar"/>, status)
	  <xsl:call-template name="checkErrorCtx">
	    <xsl:with-param name="method" select="'put'"/>
	    <xsl:with-param name="ctx" select="$contextvar"/>
	    <xsl:with-param name="path" select="$fieldpath"/>
	  </xsl:call-template>
    endif
  </xsl:when>

  <!-- float scalar data -->
  <xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
    ! Put <xsl:value-of select="@name"/>
    if (<xsl:value-of select="$fieldvar"/>.NE.ids_real_invalid) then
       call put_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          '', <xsl:value-of select="$fieldvar"/>, status)
	  <xsl:call-template name="checkErrorCtx">
            <xsl:with-param name="method" select="'put'"/>
	    <xsl:with-param name="ctx" select="$contextvar"/>
	    <xsl:with-param name="path" select="$fieldpath"/>
	  </xsl:call-template>
    endif
  </xsl:when>

  <!-- float 1D vector data -->
  <xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
    ! Put <xsl:value-of select="@name"/>
    if (associated(<xsl:value-of select="$fieldvar"/>)) then
    <xsl:call-template name="set_timepath_and_lastdimsize">
      <xsl:with-param name="slice" select="$slice"/>
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
      <xsl:with-param name="rank" select="1"/>
    </xsl:call-template>
       call put_vect1d_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>, lastdimsize, status)
	  <xsl:call-template name="checkErrorCtx">
            <xsl:with-param name="method" select="'put'"/>
	    <xsl:with-param name="ctx" select="$contextvar"/>
	    <xsl:with-param name="path" select="$fieldpath"/>
	  </xsl:call-template>
    endif
  </xsl:when>

  <!-- integer 1D vector data -->
  <xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
    ! Put <xsl:value-of select="@name"/>
    if (associated(<xsl:value-of select="$fieldvar"/>)) then
    <xsl:call-template name="set_timepath_and_lastdimsize">
      <xsl:with-param name="slice" select="$slice"/>
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
      <xsl:with-param name="rank" select="1"/>
    </xsl:call-template>
       call put_vect1d_int(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>, lastdimsize, status)
	  <xsl:call-template name="checkErrorCtx">
            <xsl:with-param name="method" select="'put'"/>
	    <xsl:with-param name="ctx" select="$contextvar"/>
	    <xsl:with-param name="path" select="$fieldpath"/>
	  </xsl:call-template>
    endif
  </xsl:when>

  <!-- float 2D vector data -->
  <xsl:when test="@data_type='FLT_2D'">
    ! Put <xsl:value-of select="@name"/>
    if (associated(<xsl:value-of select="$fieldvar"/>)) then
    <xsl:call-template name="set_timepath_and_lastdimsize">
      <xsl:with-param name="slice" select="$slice"/>
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
      <xsl:with-param name="rank" select="2"/>
    </xsl:call-template>
       call put_vect2d_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>,&amp;
	  size(<xsl:value-of select="$fieldvar"/>,1),&amp;
	  lastdimsize, status)
	  <xsl:call-template name="checkErrorCtx">
            <xsl:with-param name="method" select="'put'"/>
	    <xsl:with-param name="ctx" select="$contextvar"/>
	    <xsl:with-param name="path" select="$fieldpath"/>
	  </xsl:call-template>
    endif
  </xsl:when>

  <!-- integer 2D vector data -->
  <xsl:when test="@data_type='INT_2D'">
    ! Put <xsl:value-of select="@name"/>
    if (associated(<xsl:value-of select="$fieldvar"/>)) then
    <xsl:call-template name="set_timepath_and_lastdimsize">
      <xsl:with-param name="slice" select="$slice"/>
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
      <xsl:with-param name="rank" select="2"/>
    </xsl:call-template>
       call put_vect2d_int(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>,&amp;
          size(<xsl:value-of select="$fieldvar"/>,1),&amp;
          lastdimsize, status)
	  <xsl:call-template name="checkErrorCtx">
            <xsl:with-param name="method" select="'put'"/>
	    <xsl:with-param name="ctx" select="$contextvar"/>
	    <xsl:with-param name="path" select="$fieldpath"/>
	  </xsl:call-template>
    endif
  </xsl:when>

  <!-- float 3D vector data -->
  <xsl:when test="@data_type='FLT_3D'">
    ! Put <xsl:value-of select="@name"/>
    if (associated(<xsl:value-of select="$fieldvar"/>)) then
    <xsl:call-template name="set_timepath_and_lastdimsize">
      <xsl:with-param name="slice" select="$slice"/>
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
      <xsl:with-param name="rank" select="3"/>
    </xsl:call-template>
       call put_vect3d_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>, &amp;
          size(<xsl:value-of select="$fieldvar"/>,1),&amp;
          size(<xsl:value-of select="$fieldvar"/>,2),&amp;
          lastdimsize, status)
	  <xsl:call-template name="checkErrorCtx">
            <xsl:with-param name="method" select="'put'"/>
	    <xsl:with-param name="ctx" select="$contextvar"/>
	    <xsl:with-param name="path" select="$fieldpath"/>
	  </xsl:call-template>
    endif
  </xsl:when>

  <!-- integer 3D vector data -->
  <xsl:when test="@data_type='INT_3D'">
    ! Put <xsl:value-of select="@path"/>
    if (associated(<xsl:value-of select="$fieldvar"/>)) then
    <xsl:call-template name="set_timepath_and_lastdimsize">
      <xsl:with-param name="slice" select="$slice"/>
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
      <xsl:with-param name="rank" select="3"/>
    </xsl:call-template>
       call put_vect3d_int(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>,&amp;
          size(<xsl:value-of select="$fieldvar"/>,1),&amp;
	  size(<xsl:value-of select="$fieldvar"/>,2),&amp;
	  lastdimsize, status)
	  <xsl:call-template name="checkErrorCtx">
            <xsl:with-param name="method" select="'put'"/>
	    <xsl:with-param name="ctx" select="$contextvar"/>
	    <xsl:with-param name="path" select="$fieldpath"/>
	  </xsl:call-template>
    endif
  </xsl:when>

  <!-- float 4D vector data -->
  <xsl:when test="@data_type='FLT_4D'">
    ! Put <xsl:value-of select="@name"/>
    if (associated(<xsl:value-of select="$fieldvar"/>)) then
    <xsl:call-template name="set_timepath_and_lastdimsize">
      <xsl:with-param name="slice" select="$slice"/>
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
      <xsl:with-param name="rank" select="4"/>
    </xsl:call-template>
       call put_vect4d_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>,&amp;
	  size(<xsl:value-of select="$fieldvar"/>,1),&amp;
	  size(<xsl:value-of select="$fieldvar"/>,2),&amp;
	  size(<xsl:value-of select="$fieldvar"/>,3),&amp;
	  lastdimsize, status)
	  <xsl:call-template name="checkErrorCtx">
            <xsl:with-param name="method" select="'put'"/>
	    <xsl:with-param name="ctx" select="$contextvar"/>
	    <xsl:with-param name="path" select="$fieldpath"/>
	  </xsl:call-template>
    endif
  </xsl:when>

  <!-- float 5D vector data -->
  <xsl:when test="@data_type='FLT_5D'">
    ! Put <xsl:value-of select="@name"/>
    if (associated(<xsl:value-of select="$fieldvar"/>)) then
    <xsl:call-template name="set_timepath_and_lastdimsize">
      <xsl:with-param name="slice" select="$slice"/>
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
      <xsl:with-param name="rank" select="5"/>
    </xsl:call-template>
       call put_vect5d_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>,&amp;
	  size(<xsl:value-of select="$fieldvar"/>,1),&amp;
	  size(<xsl:value-of select="$fieldvar"/>,2),&amp;
	  size(<xsl:value-of select="$fieldvar"/>,3),&amp;
	  size(<xsl:value-of select="$fieldvar"/>,4),&amp;
	  lastdimsize, status)
	  <xsl:call-template name="checkErrorCtx">
            <xsl:with-param name="method" select="'put'"/>
	    <xsl:with-param name="ctx" select="$contextvar"/>
	    <xsl:with-param name="path" select="$fieldpath"/>
	  </xsl:call-template>
    endif
  </xsl:when>

  <!-- float 6D vector data -->
  <xsl:when test="@data_type='FLT_6D'">
    ! Put <xsl:value-of select="@name"/>
    if (associated(<xsl:value-of select="$fieldvar"/>)) then
    <xsl:call-template name="set_timepath_and_lastdimsize">
      <xsl:with-param name="slice" select="$slice"/>
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
      <xsl:with-param name="rank" select="6"/>
    </xsl:call-template>
       call put_vect6d_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>,&amp;
	  size(<xsl:value-of select="$fieldvar"/>,1),&amp;
	  size(<xsl:value-of select="$fieldvar"/>,2),&amp;
	  size(<xsl:value-of select="$fieldvar"/>,3),&amp;
	  size(<xsl:value-of select="$fieldvar"/>,4),&amp;
	  size(<xsl:value-of select="$fieldvar"/>,5),&amp;
	  lastdimsize, status)
	  <xsl:call-template name="checkErrorCtx">
            <xsl:with-param name="method" select="'put'"/>
	    <xsl:with-param name="ctx" select="$contextvar"/>
	    <xsl:with-param name="path" select="$fieldpath"/>
	  </xsl:call-template>
    endif
  </xsl:when>
  <xsl:otherwise>
    ! Put <xsl:value-of select="@name"/> : PROBLEM : UNIDENTIFIED TYPE !!! 
    <xsl:message select="concat('PROBLEM : UNIDENTIFIED TYPE detected in PUT routine for ',@path)" terminate="yes"/>
  </xsl:otherwise>
</xsl:choose>
</xsl:if>

</xsl:template>



<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- IDS_GET TEMPLATE                                                        -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<xsl:template match="field" mode="GET_FIELD">
  <xsl:param name="structvar"/>
  <xsl:param name="contextvar"/>
  <xsl:param name="timedparentexpr"/>
  <xsl:param name="slice"/>

  <xsl:if test="$slice !='yes' or @type ='dynamic' or @data_type='structure' or (@data_type='struct_array' and .//field[@type='dynamic'])"> <!-- This skips the routine for non-timed fields when using this template in GET_SLICE mode -->

    <xsl:variable name="fieldvar"><xsl:value-of select="$structvar"/>%<xsl:value-of select="@name"/></xsl:variable>
    <xsl:variable name="timedexpr">
      <xsl:choose>
	<xsl:when test="@type='dynamic'"><xsl:value-of select="$timedparentexpr"/>.true.</xsl:when>
	<xsl:otherwise><xsl:value-of select="$timedparentexpr"/>.false.</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="fieldpath">
      <xsl:choose>
	<xsl:when test="$contextvar='aosctx' or $contextvar='opctx'">"<xsl:value-of select="@name"/>"</xsl:when>
	<xsl:otherwise>path//"<xsl:value-of select="@name"/>"</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

<!-- Detect type of the field -->
<xsl:choose>

  <!-- Array of structure -->
  <xsl:when test="@data_type='struct_array' and $contextvar!='aosctx'">
    <xsl:variable name="this-type">
      <xsl:choose>
	<xsl:when test="@structure_reference='self'">
	  <xsl:value-of select="local:unique_name(@name)"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="local:unique_name(@structure_reference)"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    ! Get <xsl:value-of select="@name"/>
    <xsl:choose>
      <xsl:when test="@type='dynamic'">
       if (homogeneous) then
          timepath = "/time"
       else
          timepath = <xsl:value-of select="$fieldpath"/>//"/time"
       endif
      </xsl:when>
      <xsl:otherwise>
       timepath = ""
      </xsl:otherwise>
    </xsl:choose>
    call ual_begin_arraystruct_action(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>, timepath, aoslen, aosctx)
    if (aosctx.ge.0) then
       if (aoslen.gt.0) allocate(<xsl:value-of select="$fieldvar"/>(aoslen))
       do i = 1,aoslen
       <xsl:apply-templates select="." mode="GET_FIELD">
	 <xsl:with-param name="structvar" select="$structvar"/>
	 <xsl:with-param name="contextvar" select="'aosctx'"/>
	 <xsl:with-param name="timedparentexpr" select="'timedparent.or.'"/>
       </xsl:apply-templates> 
          call ual_iterate_over_arraystruct(aosctx, 1, status)
       enddo
       call ual_end_action(aosctx, status)
    endif
  </xsl:when>

  <!-- Structure -->
  <xsl:when test="@data_type='structure' or (@data_type='struct_array' and $contextvar='aosctx')">
    <xsl:variable name="this-type">
      <xsl:choose>
	<xsl:when test="@structure_reference='self'">
	  <xsl:value-of select="local:unique_name(@name)"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="local:unique_name(@structure_reference)"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="closectx">
      <xsl:choose>
	<xsl:when test="@data_type='structure'">
	  <xsl:value-of select="'no'"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="'yes'"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    ! Get <xsl:value-of select="@name"/>
    call get_struct_ids_<xsl:value-of select="$this-type"/>(<xsl:value-of select="$contextvar"/>, &amp;
    <xsl:choose>
      <xsl:when test="$contextvar='aosctx'">'', </xsl:when>
      <xsl:otherwise><xsl:value-of select="concat(substring($fieldpath,1,string-length($fieldpath)-1),'/&quot;')"/>, </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="$fieldvar"/><xsl:if test="@data_type='struct_array'">(i)</xsl:if>, homogeneous, <xsl:value-of select="$timedexpr"/>, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'get'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
      <xsl:with-param name="closectx" select="$closectx"/>
    </xsl:call-template>
  </xsl:when>

  <!-- String data -->
  <xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
    ! Get <xsl:value-of select="@name"/>
    longstring = ' '
    call get_string(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          '', longstring, lenstring, status)
    if (status.EQ.0) then
       call unpack_string(longstring, lenstring, <xsl:value-of select="$fieldvar"/>)
    else
      <xsl:call-template name="checkErrorCtx">
	<xsl:with-param name="method" select="'get'"/>
	<xsl:with-param name="ctx" select="$contextvar"/>
	<xsl:with-param name="path" select="$fieldpath"/>
      </xsl:call-template>
    endif
  </xsl:when>

  <!-- 1D array of string data -->
  <xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
    ! Get <xsl:value-of select="@name"/>
    <xsl:call-template name="set_timepath">
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
    </xsl:call-template>
    call get_vect1d_string(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
       trim(timepath), <xsl:value-of select="$fieldvar"/>, size1, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'get'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
    </xsl:call-template>
  </xsl:when>

  <!-- integer scalar data -->
  <xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
    ! Get <xsl:value-of select="@name"/>
    call get_int(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          '', <xsl:value-of select="$fieldvar"/>, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'get'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
    </xsl:call-template>
  </xsl:when>

  <!-- float scalar data -->
  <xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
    ! Get <xsl:value-of select="@name"/>
    call get_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          '', <xsl:value-of select="$fieldvar"/>, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'get'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
    </xsl:call-template>
  </xsl:when>

  <!-- float 1D vector data -->
  <xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
    ! Get <xsl:value-of select="@name"/>
    <xsl:call-template name="set_timepath">
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
    </xsl:call-template>
    call get_vect1d_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>, size1, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'get'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
    </xsl:call-template>
  </xsl:when>

  <!-- integer 1D vector data -->
  <xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
    ! Get <xsl:value-of select="@name"/>
    <xsl:call-template name="set_timepath">
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
    </xsl:call-template>
    call get_vect1d_int(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>, size1, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'get'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
    </xsl:call-template>
  </xsl:when>

  <!-- float 2D vector data -->
  <xsl:when test="@data_type='FLT_2D'">
    ! Get <xsl:value-of select="@name"/>
    <xsl:call-template name="set_timepath">
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
    </xsl:call-template>
    call get_vect2d_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>,&amp;
	  size1, size2, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'get'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
    </xsl:call-template>
  </xsl:when>

  <!-- integer 2D vector data -->
  <xsl:when test="@data_type='INT_2D'">
    ! Get <xsl:value-of select="@name"/>
    <xsl:call-template name="set_timepath">
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
    </xsl:call-template>
    call get_vect2d_int(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>,&amp;
          size1, size2, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'get'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
    </xsl:call-template>
  </xsl:when>

  <!-- float 3D vector data -->
  <xsl:when test="@data_type='FLT_3D'">
    ! Get <xsl:value-of select="@name"/>
    <xsl:call-template name="set_timepath">
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
    </xsl:call-template>
    call get_vect3d_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>, &amp;
          size1, size2, size3, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'get'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
    </xsl:call-template>
  </xsl:when>

  <!-- integer 3D vector data -->
  <xsl:when test="@data_type='INT_3D'">
    ! Get <xsl:value-of select="@path"/>
    <xsl:call-template name="set_timepath">
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
    </xsl:call-template>
    call get_vect3d_int(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>,&amp;
          size1, size2, size3, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'get'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
    </xsl:call-template>
  </xsl:when>

  <!-- float 4D vector data -->
  <xsl:when test="@data_type='FLT_4D'">
    ! Get <xsl:value-of select="@name"/>
    <xsl:call-template name="set_timepath">
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
    </xsl:call-template>
    call get_vect4d_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>,&amp;
	  size1, size2, size3, size4, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'get'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
    </xsl:call-template>
  </xsl:when>

  <!-- float 5D vector data -->
  <xsl:when test="@data_type='FLT_5D'">
    ! Get <xsl:value-of select="@name"/>
    <xsl:call-template name="set_timepath">
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
    </xsl:call-template>
    call get_vect5d_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>,&amp;
	  size1, size2, size3, size4, size5, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'get'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
    </xsl:call-template>
  </xsl:when>

  <!-- float 6D vector data -->
  <xsl:when test="@data_type='FLT_6D'">
    ! Get <xsl:value-of select="@name"/>
    <xsl:call-template name="set_timepath">
      <xsl:with-param name="fieldpath" select="$fieldpath"/>
      <xsl:with-param name="fieldvar" select="$fieldvar"/>
    </xsl:call-template>
    call get_vect6d_double(<xsl:value-of select="$contextvar"/>, <xsl:value-of select="$fieldpath"/>,&amp;
          trim(timepath), <xsl:value-of select="$fieldvar"/>,&amp;
	  size1, size2, size3, size4, size5, size6, status)
    <xsl:call-template name="checkErrorCtx">
      <xsl:with-param name="method" select="'put'"/>
      <xsl:with-param name="ctx" select="$contextvar"/>
      <xsl:with-param name="path" select="$fieldpath"/>
    </xsl:call-template>
  </xsl:when>
  <xsl:otherwise>
    ! Get <xsl:value-of select="@name"/> : PROBLEM : UNIDENTIFIED TYPE !!! 
    <xsl:message select="concat('PROBLEM : UNIDENTIFIED TYPE detected in PUT routine for ',@path)" terminate="yes"/>
  </xsl:otherwise>
</xsl:choose>
</xsl:if>

</xsl:template>






<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
<!-- MISC LOCAL TEMPLATES                                                    -->
<!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->

<xsl:template name ="checkErrorCtx">
  <xsl:param name="method"/> 
  <xsl:param name="ctx"/>
  <xsl:param name="path"/>
  <xsl:param name="closectx"/>
  <xsl:choose>
    <xsl:when test="$method='put'">
  if(isErrorCritical(status, <xsl:value-of select="$ctx"/>, <xsl:value-of select="$path"/>)) then
     retstatus = status
     <xsl:if test="$closectx='yes'">call ual_end_action(<xsl:value-of select="$ctx"/>, status)</xsl:if>
     return
  endif
    </xsl:when>
    <xsl:otherwise>
  if(isErrorCritical(status, <xsl:value-of select="$ctx"/>, <xsl:value-of select="$path"/>)) then
     retstatus = status
     <xsl:if test="$closectx='yes'">call ual_end_action(<xsl:value-of select="$ctx"/>, status)</xsl:if>
     return
  endif
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>



<xsl:template name="set_timepath">
  <xsl:param name="fieldpath"/>
  <xsl:param name="fieldvar"/>
  <xsl:choose>
    <xsl:when test="@type='dynamic'">
      if (timedparent) then
         timepath=""
      else
         if (homogeneous) then
            timepath="/time"
         else
      <xsl:choose>
	<xsl:when test="@coordinate7_AosParent_relative">timepath="<xsl:value-of select="@coordinate7_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@coordinate6_AosParent_relative">timepath="<xsl:value-of select="@coordinate6_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@coordinate5_AosParent_relative">timepath="<xsl:value-of select="@coordinate5_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@coordinate4_AosParent_relative">timepath="<xsl:value-of select="@coordinate4_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@coordinate3_AosParent_relative">timepath="<xsl:value-of select="@coordinate3_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@coordinate2_AosParent_relative">timepath="<xsl:value-of select="@coordinate2_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@coordinate1_AosParent_relative">timepath="<xsl:value-of select="@coordinate1_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@name='time'">timepath=<xsl:value-of select="$fieldpath"/></xsl:when>
      </xsl:choose>
         endif
      endif
    </xsl:when>
    <xsl:otherwise>
      timepath = ""
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>



<xsl:template name="set_timepath_and_lastdimsize">
  <xsl:param name="slice"/>
  <xsl:param name="fieldpath"/>
  <xsl:param name="fieldvar"/>
  <xsl:param name="rank"/>
  <xsl:choose>
    <xsl:when test="@type='dynamic'">
      if (timedparent) then
         timepath=""
	 lastdimsize = size(<xsl:value-of select="$fieldvar"/>,<xsl:value-of select="$rank"/>)
      else
         if (homogeneous) then
            timepath="/time"
         else
      <xsl:choose>
	<xsl:when test="@coordinate7_AosParent_relative">timepath="<xsl:value-of select="@coordinate7_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@coordinate6_AosParent_relative">timepath="<xsl:value-of select="@coordinate6_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@coordinate5_AosParent_relative">timepath="<xsl:value-of select="@coordinate5_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@coordinate4_AosParent_relative">timepath="<xsl:value-of select="@coordinate4_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@coordinate3_AosParent_relative">timepath="<xsl:value-of select="@coordinate3_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@coordinate2_AosParent_relative">timepath="<xsl:value-of select="@coordinate2_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@coordinate1_AosParent_relative">timepath="<xsl:value-of select="@coordinate1_AosParent_relative"/>"</xsl:when>
	<xsl:when test="@name='time'">timepath=<xsl:value-of select="$fieldpath"/></xsl:when>
      </xsl:choose>
         endif
	 <xsl:choose>
	   <xsl:when test="$slice='yes'">
         lastdimsize = 1
	   </xsl:when>
	   <xsl:otherwise>
         lastdimsize = size(<xsl:value-of select="$fieldvar"/>,<xsl:value-of select="$rank"/>)
	   </xsl:otherwise>
	 </xsl:choose>
      endif
    </xsl:when>
    <xsl:otherwise>
      timepath = ""
      lastdimsize = size(<xsl:value-of select="$fieldvar"/>,<xsl:value-of select="$rank"/>)
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>



<xsl:template name="isCriticalFuncCtx">
FUNCTION isErrorCritical(status, ctx, path) RESULT (exitRequest)
   use ids_types
   use ual_low_level_wrap
   implicit none

   integer(ids_int) :: status, ctx
   character*(*) :: path
   logical :: exitRequest

   exitRequest = .FALSE.

   if(status == 0) then
      exitRequest = .FALSE.
      return
   else
      exitRequest = .TRUE.
      write(*,*) "ERROR! with field '",path,"' from context:"
      call ual_print_context(ctx)
      return
   endif
END FUNCTION isErrorCritical
</xsl:template>



</xsl:stylesheet>
