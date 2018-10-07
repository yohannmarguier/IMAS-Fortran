<?xml version="1.0" encoding="UTF-8"?>
<?modxslt-stylesheet type="text/xsl" media="fuffa, screen and $GET[stylesheet]" href="./%24GET%5Bstylesheet%5D" alternate="no" title="Translation using provided stylesheet" charset="ISO-8859-1" ?>
<?modxslt-stylesheet type="text/xsl" media="screen" alternate="no" title="Show raw source of the XML file" charset="ISO-8859-1" ?>
<xsl:stylesheet xmlns:yaslt="http://www.mod-xslt2.com/ns/2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" extension-element-prefixes="yaslt" xmlns:fn="http://www.w3.org/2005/02/xpath-functions" xmlns:local="http://www.example.com/functions/local" exclude-result-prefixes="local xs">
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>	<!-- This XSL translates the list of IMAS IDSDefs to Fortran 90 GET/PUT Routines for IDSs -->

<xsl:function name="local:unique_name" as="xs:string">
<!-- Provides unique 12 characters reference to arbitrary long field name  -->
<xsl:param name="FullName" as="xs:string"/>
<xsl:variable name="result" as="xs:string" select="concat(lower-case(substring($FullName,1,8)), sum(string-to-codepoints(lower-case(substring($FullName,9)))))"/>
<xsl:value-of select="$result"/>
</xsl:function>

<xsl:template match="/IDSs">
 <xsl:result-document href="ids_routines.f90">
module ids_routines

use ids_schemas
use <xsl:value-of select="local:unique_name('utilities')"/>_copy_struct
use <xsl:value-of select="local:unique_name('utilities')"/>_deallocate_struct

<xsl:for-each select="IDS">
use <xsl:value-of select="local:unique_name(@name)"/>_ids_module_put
use <xsl:value-of select="local:unique_name(@name)"/>_ids_module_put_slice
use <xsl:value-of select="local:unique_name(@name)"/>_ids_module_put_non_timed
use <xsl:value-of select="local:unique_name(@name)"/>_ids_module_get
use <xsl:value-of select="local:unique_name(@name)"/>_ids_module_get_slice
use <xsl:value-of select="local:unique_name(@name)"/>_copy
use <xsl:value-of select="local:unique_name(@name)"/>_copy_struct
use <xsl:value-of select="local:unique_name(@name)"/>_deallocate_struct
</xsl:for-each>


contains

subroutine ids_get_times(idx,path,time)
implicit none

integer(ids_int) :: idx, status
character*(*) :: path
real(ids_real), pointer :: time(:)

integer(ids_int) :: ndims,dim1,dim2,dim3,dim4,dum1,dum2,dum3,dum4, dim5, dim6, dim7, lentime

call get_dimension(idx,path,"time",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
lentime = dim1

call begin_IDS_get(idx, path,1,dum1)

allocate(time(lentime))
call get_vect1d_double(idx,path,"time",time,lentime,dum1,status)

end subroutine
end module
</xsl:result-document>
<xsl:apply-templates select="IDS" mode="main"/>

</xsl:template>

 <xsl:template match="IDS" mode="main">

  <xsl:result-document href="{@name}_put.f90">
module <xsl:value-of select="local:unique_name(@name)"/>_ids_module_put

! Declaration of the generic IDS PUT routine
interface ids_put
   module procedure ids_put_<xsl:value-of select="local:unique_name(@name)"/>
end interface ids_put


<!--
! Declaration of the generic IDS FLUSH routine
interface ids_flush
   module procedure ids_flush_<xsl:value-of select="@name"/>
end interface ids_flush

! Declaration of the generic IDS DISCARD routine
interface ids_discard
   module procedure ids_discard_<xsl:value-of select="@name"/>
end interface ids_discard
-->

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

	if(0 .NE. is_critical_error(status) ) then
		exitRequest = .TRUE.
	endif

	if ( (ual_debug == 'yes') .OR. (ual_debug == 'vvv') .OR. exitRequest)then
		call get_last_errmsg(longstring)
		write(*,*) "ERROR! FIELD: ", trim(fieldPath), "    STATUS: ", status, "    MSG: ", trim(longstring)
	endif

END FUNCTION isErrorCritical

subroutine fput_int_in_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug)

use ids_schemas
implicit none
integer(ids_int) :: variable
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug

if (variable.NE.ids_int_invalid) then
   call put_int_in_object(idx, obj, path_in_object, index_in_object, variable)
   if (ual_debug =='yes') write(*,*) 'Put ', trim(variable_name), variable
endif

end subroutine fput_int_in_object

subroutine fput_vect1d_double_in_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug)

use ids_schemas
implicit none
real(ids_real), pointer :: variable(:)
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug

if (associated(variable)) then
   call put_vect1d_double_in_object(idx, obj, path_in_object, index_in_object, variable, size(variable))
   if (ual_debug =='yes') write(*,*) 'Put ', trim(variable_name), variable
endif

end subroutine fput_vect1d_double_in_object

subroutine fput_vect2d_double_in_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug)

use ids_schemas
implicit none
real(ids_real), pointer :: variable(:,:)
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug

if (associated(variable)) then
   call put_vect2d_double_in_object(idx, obj, path_in_object, index_in_object, variable, size(variable,1), size(variable,2))
   if (ual_debug =='yes') write(*,*) 'Put ', trim(variable_name), variable
endif

end subroutine fput_vect2d_double_in_object


<!-- ======================================  PUT ======================================= -->

!!!!!! Routines to PUT the full IDS
subroutine ids_put_<xsl:value-of select="local:unique_name(@name)"/>(idx, path,  IDS)

use ids_schemas
use <xsl:value-of select="local:unique_name(@name)"/>_copy  ! Needed since the _copy module contains the ids_delete routines
implicit none
integer(ids_int) :: status = 0, retStatus = 0

character*(*) :: path
integer(ids_int) :: idx, lentime

type(ids_<xsl:value-of select="@name"/>) :: IDS

! internal variables declaration

integer(ids_int) :: itime
integer(ids_int) :: int0D
integer(ids_int),pointer :: vect1DInt(:), vect2DInt(:,:), vect3DInt(:,:,:) => null()
integer(ids_int) :: i,dim1,dim2,dim3,dim4,dim5,dim6,dim7, lenstring, istring
integer(ids_int), pointer :: dimtab(:) => null()
real(ids_real) :: double0D
real(ids_real), pointer :: vect1DDouble(:), time(:), vect2DDouble(:,:), vect3DDouble(:,:,:), vect4DDouble(:,:,:,:) => null()
real(ids_real), pointer :: vect5DDouble(:,:,:,:,:), vect6DDouble(:,:,:,:,:,:) => null()
character(len=ids_string_length), dimension(:), pointer :: stri => null()
character(len=100000)::longstring
character(len=300) :: timepath
integer(ids_int) :: obj_all_times,obj1,obj2,obj3,obj4,obj5,obj6,obj7
integer(ids_int) :: i1,i2,i3,i4,i5,i6,i7
<xsl:for-each select=".//field[@data_type='struct_array' and @maxoccur!='unbounded']">
integer(ids_int) :: i<xsl:value-of select="concat(@name,generate-id(.))"/>
</xsl:for-each>

call getenv('ual_debug',ual_debug) ! Debug flag


if (IDS%IDS_Properties%homogeneous_time.EQ.ids_int_invalid) then
	write(*,*) "Warning: IDS <xsl:value-of select="@name"/> is found to be EMPTY (homogeneous_time undefined). PUT quits with no action."
	return
endif


! Systematic delete of the previous IDS, in case it existed
call ids_delete(idx,path,IDS)

! And systematic erase of the previous changes in cache
! The ids_discard routines are obsolete, do not call them anymore
! call ids_discard(idx,path,IDS)

<xsl:if test=".//field[@type='dynamic']"> <!-- if there is dynamic data in the IDS, check that the the IDS%time vector of an homogeneous_time IDS is associated -->
if ((IDS%IDS_Properties%homogeneous_time.EQ.1).AND.(.NOT.(associated(IDS%time)))) then
   write(*,*) "ERROR : the IDS%time vector of an homogeneous_time IDS must be associated"
   return
endif
</xsl:if>

call begin_ids_put(idx, path)

<xsl:apply-templates select="field" mode="PUT_SINGLE"/>

call end_ids_put(idx, path)

return
end subroutine ids_put_<xsl:value-of select="local:unique_name(@name)"/>


<!--
!!!!!! Routines to flush IDSs

subroutine ids_flush_<xsl:value-of select="@name"/>(idx,IDSpath,IDS) --> <!-- systematic calls to the low level ids_flush_cache routine. The IDS input argument is added just for the interface to identify the relevant IDS type -->
<!--
use ids_schemas
implicit none
character*(*) :: IDSpath
integer(ids_int) :: idx

  <xsl:choose>
			<xsl:when test="@timed = 'yes'">
type(ids_<xsl:value-of select="@name"/>),pointer :: IDS(:)
			</xsl:when>
			<xsl:otherwise>
type(ids_<xsl:value-of select="@name"/>) :: IDS
			</xsl:otherwise>
		</xsl:choose>


call getenv('ual_debug',ual_debug) ! Debug flag
if (ual_debug =='yes') write(*,*) 'Flushing IDS ',IDSpath
<xsl:apply-templates select="field" mode="FLUSH_CACHE"/>
if (ual_debug =='yes') write(*,*) 'Flushing IDS ',IDSpath,' done'
end subroutine ids_flush_<xsl:value-of select="@name"/>
-->

<!--!!!!!! Routine to discard IDS-->
<!--subroutine ids_discard_<xsl:value-of select="@name"/>(idx,IDSpath,IDS)-->
<!-- systematic calls to the low level ids_discard_cache routine. The IDS input argument is added just for the interface to identify the relevant IDS type -->
<!--
use ids_schemas
implicit none
character*(*) :: IDSpath
integer(ids_int) :: idx

type(ids_<xsl:value-of select="@name"/>) :: IDS
<xsl:for-each select=".//field[@data_type='struct_array' and @maxoccur!='unbounded']">
integer(ids_int) :: i<xsl:value-of select="concat(@name,generate-id(.))"/>
</xsl:for-each>

call getenv('ual_debug',ual_debug) ! Debug flag
if (ual_debug =='yes') write(*,*) 'Discarding IDS ',IDSpath
<xsl:apply-templates select="field" mode="DISCARD_CACHE"/>
if (ual_debug =='yes') write(*,*) 'Discarding IDS ',IDSpath,' done'
end subroutine ids_discard_<xsl:value-of select="@name"/>-->

end module <xsl:value-of select="local:unique_name(@name)"/>_ids_module_put
</xsl:result-document>



<xsl:result-document href="{@name}_put_non_timed.f90">
module <xsl:value-of select="local:unique_name(@name)"/>_ids_module_put_non_timed


! Declaration of the generic IDS PUT_NON_TIMED routine
interface ids_put_non_timed
   module procedure ids_put_non_timed_<xsl:value-of select="local:unique_name(@name)"/>
end interface ids_put_non_timed


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

	if(0 .NE. is_critical_error(status) ) then
		exitRequest = .TRUE.
	endif

	if ( (ual_debug == 'yes') .OR. (ual_debug == 'vvv') .OR. exitRequest)then
		call get_last_errmsg(longstring)
		write(*,*) "ERROR! FIELD: ", trim(fieldPath), "    STATUS: ", status, "    MSG: ", trim(longstring)
	endif

END FUNCTION isErrorCritical



<!-- ======================================  PUT NON TIMED ======================================= -->

!!!!!! Routines to PUT_NON_TIMED the time INdependent data of time dependent IDSs

subroutine ids_put_non_timed_<xsl:value-of select="local:unique_name(@name)"/>(idx, path,  IDS)

use ids_schemas
use <xsl:value-of select="local:unique_name(@name)"/>_copy  ! Needed since the _copy module contains the ids_delete routines
implicit none

character*(*) :: path
integer(ids_int) :: idx
integer(ids_int) :: status = 0, retStatus = 0
integer(ids_int) :: i,dim1,dim2,dim3,dim4,dim5,dim6,dim7, lenstring, istring
integer(ids_int), pointer :: dimtab(:) => null()
character(len=100000)::longstring
character(len=300) :: timepath
integer(ids_int) :: obj1,obj2,obj3,obj4,obj5,obj6,obj7
integer(ids_int) :: i1,i2,i3,i4,i5,i6,i7
<xsl:for-each select=".//field[@data_type='struct_array' and @maxoccur!='unbounded']">
integer(ids_int) :: i<xsl:value-of select="concat(@name,generate-id(.))"/>
</xsl:for-each>

type(ids_<xsl:value-of select="@name"/>) :: IDS       ! real declaration of the IDS for the put

call getenv('ual_debug',ual_debug) ! Debug flag

if (IDS%IDS_Properties%homogeneous_time.EQ.ids_int_invalid) then
	write(*,*) "Warning: IDS <xsl:value-of select="@name"/> is found to be EMPTY (homogeneous_time undefined). PUTNONTIMED quits with no action."
	return
endif


! Systematic delete of the previous IDS, in case it existed; guarantees the time-dependent data is deleted
call ids_delete(idx,path,IDS)

! And systematic erase of the previous changes in cache
! The ids_discard routines are obsolete, do not call them anymore
! call ids_discard(idx,path,IDS)


call begin_IDS_put_non_timed(idx, path)
		<xsl:apply-templates select="field" mode="PUT_SINGLE">
                <xsl:with-param name="non_timed" select="yes"/>
                </xsl:apply-templates>
call end_IDS_put_non_timed(idx, path)

return
end subroutine ids_put_non_timed_<xsl:value-of select="local:unique_name(@name)"/>




end module <xsl:value-of select="local:unique_name(@name)"/>_ids_module_put_non_timed
</xsl:result-document>


<xsl:result-document href="{@name}_put_slice.f90">
module <xsl:value-of select="local:unique_name(@name)"/>_ids_module_put_slice

<xsl:if test=".//field[@type='dynamic']"> <!-- Procedure put_slice should exist only for time-dependent IDSs -->
! Declaration of the generic IDS PUT_SLICE routine
interface ids_put_slice
   module procedure ids_put_slice_<xsl:value-of select="local:unique_name(@name)"/>
end interface ids_put_slice
</xsl:if >

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

	if(0 .NE. is_critical_error(status) ) then
		exitRequest = .TRUE.
	endif

	if ( (ual_debug == 'yes') .OR. (ual_debug == 'vvv') .OR. exitRequest)then
		call get_last_errmsg(longstring)
		write(*,*) "ERROR! FIELD: ", trim(fieldPath), "    STATUS: ", status, "    MSG: ", trim(longstring)
	endif

END FUNCTION isErrorCritical


subroutine fput_int_in_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug)

use ids_schemas
implicit none
integer(ids_int) :: variable
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug

if (variable.NE.ids_int_invalid) then
   call put_int_in_object(idx, obj, path_in_object, index_in_object, variable)
   if (ual_debug =='yes') write(*,*) 'Put ', trim(variable_name), variable
endif

end subroutine fput_int_in_object

subroutine fput_vect1d_double_in_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug)

use ids_schemas
implicit none
real(ids_real), pointer :: variable(:)
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug

if (associated(variable)) then
   call put_vect1d_double_in_object(idx, obj, path_in_object, index_in_object, variable, size(variable))
   if (ual_debug =='yes') write(*,*) 'Put ', trim(variable_name), variable
endif

end subroutine fput_vect1d_double_in_object

subroutine fput_vect2d_double_in_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug)

use ids_schemas
implicit none
real(ids_real), pointer :: variable(:,:)
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug

if (associated(variable)) then
   call put_vect2d_double_in_object(idx, obj, path_in_object, index_in_object, variable, size(variable,1), size(variable,2))
   if (ual_debug =='yes') write(*,*) 'Put ', trim(variable_name), variable
endif

end subroutine fput_vect2d_double_in_object




<!-- ======================================  PUT SLICE ======================================= -->

<xsl:if test=".//field[@type='dynamic']"> <!-- Procedure put_slice should exist only for time-dependent IDSs -->
!!!!!! Routines to PUT_SLICE one time slice of a time-dependent IDS (affects only time-dependent fields)

subroutine ids_put_slice_<xsl:value-of select="local:unique_name(@name)"/>(idx,path,IDS)

use ids_schemas
implicit none

character*(*) :: path
integer(ids_int) :: idx, lentime
integer(ids_int) :: status = 0, retStatus = 0

type(ids_<xsl:value-of select="@name"/>) :: IDS

! internal variables declaration
integer(ids_int) :: itime
integer(ids_int) :: int0D
integer(ids_int),pointer :: vect1DInt(:), vect2DInt(:,:), vect3DInt(:,:,:) => null()
integer(ids_int) :: i,dim1,dim2,dim3,dim4,dim5,dim6,dim7, lenstring, istring
integer(ids_int), pointer :: dimtab(:) => null()
real(ids_real) :: double0D
real(ids_real), pointer :: vect1DDouble(:), time(:), vect2DDouble(:,:), vect3DDouble(:,:,:), vect4DDouble(:,:,:,:) => null()
real(ids_real), pointer :: vect5DDouble(:,:,:,:,:), vect6DDouble(:,:,:,:,:,:) => null()
character(len=ids_string_length), dimension(:), pointer :: stri => null()
character(len=100000)::longstring
character(len=300)::timepath
integer(ids_int) :: obj_single_time,obj1,obj2,obj3,obj4,obj5,obj6,obj7
integer(ids_int) :: i1,i2,i3,i4,i5,i6,i7
<xsl:for-each select=".//field[@data_type='struct_array' and @maxoccur!='unbounded']">
integer(ids_int) :: i<xsl:value-of select="concat(@name,generate-id(.))"/>
</xsl:for-each>

call getenv('ual_debug',ual_debug) ! Debug flag

if (IDS%IDS_Properties%homogeneous_time.EQ.ids_int_invalid) then
	write(*,*) "Warning: IDS <xsl:value-of select="@name"/> is found to be EMPTY (homogeneous_time undefined). PUTSLICE quits with no action."
	return
endif


if (IDS%IDS_Properties%homogeneous_time.NE.1) then
   write(*,*) "ERROR : the PUT_SLICE routine works only for homogeneous time IDS: check ids_properties%homogeneous_time"
   return
endif

if (.NOT.(associated(IDS%time))) then
   write(*,*) "ERROR : the ids%time vector of an homogeneous_time IDS must be associated"
   return
endif


timepath = "time"
call begin_IDS_put_slice(idx, path)
<xsl:apply-templates select="field" mode="PUT_SLICE"/>
call end_IDS_put_slice(idx, path)


return
end subroutine ids_put_slice_<xsl:value-of select="local:unique_name(@name)"/>
</xsl:if>



end module <xsl:value-of select="local:unique_name(@name)"/>_ids_module_put_slice
</xsl:result-document>




  <xsl:result-document href="{@name}_get.f90">
module <xsl:value-of select="local:unique_name(@name)"/>_ids_module_get
! Declaration of the generic IDS GET routine

interface ids_get
   module procedure ids_get_<xsl:value-of select="local:unique_name(@name)"/>
end interface ids_get



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

	if(0 .NE. is_critical_error(status) ) then
		exitRequest = .TRUE.
	endif

	if ( (ual_debug == 'yes') .OR. (ual_debug == 'vvv') .OR. exitRequest)then
		call get_last_errmsg(longstring)
		write(*,*) "ERROR! FIELD: ", trim(fieldPath), "    STATUS: ", status, "    MSG: ", trim(longstring)
	endif

END FUNCTION isErrorCritical

subroutine fget_vect1d_double_from_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug)

use ids_schemas
implicit none
real(ids_real), pointer :: variable(:)
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug
integer(ids_int) :: ndims,dim1,dum1,dim2,dim3,dim4,dim5,dim6,dim7,status

call get_dimension_from_object(idx,obj,path_in_object,index_in_object,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(variable(dim1))
   call get_vect1d_double_from_object(idx,obj,path_in_object,index_in_object, &amp;
   variable,dim1,dum1,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get ', trim(variable_name)
endif
end subroutine fget_vect1d_double_from_object

subroutine fget_vect2d_double_from_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug)

use ids_schemas
implicit none
real(ids_real), pointer :: variable(:,:)
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug
integer(ids_int) :: ndims,dim1,dum1,dim2,dum2,dim3,dim4,dim5,dim6,dim7,status

call get_dimension_from_object(idx,obj,path_in_object,index_in_object,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(variable(dim1,dim2))
   call get_vect2d_double_from_object(idx,obj,path_in_object,index_in_object, &amp;
   variable,dim1,dim2,dum1,dum2,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get ', trim(variable_name)
endif
end subroutine fget_vect2d_double_from_object

subroutine fget_double_from_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug, status)

use ids_schemas
implicit none
real(ids_real) :: variable, double0d
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug
integer(ids_int) :: status

call get_double_from_object(idx,obj,path_in_object,index_in_object,double0d,status)
if (status.EQ.0) then
   variable = double0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get ', trim(variable_name), 'value = ', variable
endif
end subroutine fget_double_from_object

subroutine fget_int_from_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug, status)

use ids_schemas
implicit none
integer(ids_int) :: variable, int0d
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug
integer(ids_int) :: status

call get_int_from_object(idx,obj,path_in_object,index_in_object,int0d,status)
if (status.EQ.0) then
   variable = int0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get ', trim(variable_name), 'value = ', variable
endif
end subroutine fget_int_from_object

<!-- ======================================  GET ======================================= -->

!!!!!! Routines to GET the full IDS
subroutine ids_get_<xsl:value-of select="local:unique_name(@name)"/>(idx,path,  IDS)

use ids_schemas
implicit none

character*(*) :: path
integer(ids_int) :: idx, retStatus = 0, status = 0, lenstring, istring, itime, lentime
integer(ids_int) :: ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7,dum1,dum2,dum3,dum4,dum5,dum6,dum7

character(len=ids_string_length)::stringans      ! Temporary way of getting short strings
character(len=100000)::longstring
character(len=300) :: timepath
character(len=ids_string_length), dimension(:), pointer ::stringpointer   => null()
integer(ids_int) :: obj_all_times,obj1,obj2,obj3,obj4,obj5,obj6,obj7
integer(ids_int) :: dimObj0,dimObj1,dimObj2,dimObj3,dimObj4,dimObj5,dimObj6,dimObj7
integer(ids_int) :: i1,i2,i3,i4,i5,i6,i7
<xsl:for-each select=".//field[@data_type='struct_array' and @maxoccur!='unbounded']">
integer(ids_int) :: i<xsl:value-of select="concat(@name,generate-id(.))"/>
</xsl:for-each>

integer(ids_int) :: int0d
real(ids_real) :: double0d


type(ids_<xsl:value-of select="@name"/>) :: IDS

call getenv('ual_debug',ual_debug) ! Debug flag

call begin_IDS_get(idx, path,0,dum1)
      <xsl:apply-templates select="field" mode="GET_SINGLE"/>
call end_IDS_get(idx, path)

return
end subroutine ids_get_<xsl:value-of select="local:unique_name(@name)"/>



end module <xsl:value-of select="local:unique_name(@name)"/>_ids_module_get
</xsl:result-document>


<xsl:result-document href="{@name}_get_slice.f90">
module <xsl:value-of select="local:unique_name(@name)"/>_ids_module_get_slice

! Declaration of the generic IDS GET_SLICE routine
interface ids_get_slice
   module procedure  ids_get_slice_<xsl:value-of select="local:unique_name(@name)"/>
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

	if(0 .NE. is_critical_error(status) ) then
		exitRequest = .TRUE.
	endif

	if ( (ual_debug == 'yes') .OR. (ual_debug == 'vvv') .OR. exitRequest)then
		call get_last_errmsg(longstring)
		write(*,*) "ERROR! FIELD: ", trim(fieldPath), "    STATUS: ", status, "    MSG: ", trim(longstring)
	endif

END FUNCTION isErrorCritical

subroutine fget_vect1d_double_from_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug)

use ids_schemas
implicit none
real(ids_real), pointer :: variable(:)
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug
integer(ids_int) :: ndims,dim1,dum1,dim2,dim3,dim4,dim5,dim6,dim7,status

call get_dimension_from_object(idx,obj,path_in_object,index_in_object,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(variable(dim1))
   call get_vect1d_double_from_object(idx,obj,path_in_object,index_in_object, &amp;
   variable,dim1,dum1,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get ', trim(variable_name)
endif
end subroutine fget_vect1d_double_from_object

subroutine fget_vect2d_double_from_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug)

use ids_schemas
implicit none
real(ids_real), pointer :: variable(:,:)
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug
integer(ids_int) :: ndims,dim1,dum1,dim2,dum2,dim3,dim4,dim5,dim6,dim7,status

call get_dimension_from_object(idx,obj,path_in_object,index_in_object,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(variable(dim1,dim2))
   call get_vect2d_double_from_object(idx,obj,path_in_object,index_in_object, &amp;
   variable,dim1,dim2,dum1,dum2,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get ', trim(variable_name)
endif
end subroutine fget_vect2d_double_from_object

subroutine fget_double_from_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug, status)

use ids_schemas
implicit none
real(ids_real) :: variable, double0d
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug
integer(ids_int) :: status

call get_double_from_object(idx,obj,path_in_object,index_in_object,double0d,status)
if (status.EQ.0) then
   variable = double0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get ', trim(variable_name), 'value = ', variable
endif
end subroutine fget_double_from_object

subroutine fget_int_from_object(idx, obj, path_in_object, index_in_object, variable, variable_name, ual_debug, status)

use ids_schemas
implicit none
integer(ids_int) :: variable, int0d
integer(ids_int) :: idx, obj, index_in_object
character*(*) :: path_in_object, variable_name
character(len=3) :: ual_debug
integer(ids_int) :: status

call get_int_from_object(idx,obj,path_in_object,index_in_object,int0d,status)
if (status.EQ.0) then
   variable = int0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get ', trim(variable_name), 'value = ', variable
endif
end subroutine fget_int_from_object



<!-- ======================================  GET SLICE ======================================= -->

!!!!!! Routines to GET one time slice of a IDS, with time interpolation -->
subroutine ids_get_slice_<xsl:value-of select="local:unique_name(@name)"/>(idx,path,  IDS, twant, interpol)

use ids_schemas
implicit none

character*(*) :: path
integer(ids_int) :: status = 0, interpol, idx, lenstring, istring
real(ids_real) :: twant,tret

integer(ids_int) :: int0D
integer(ids_int),pointer :: vect1DInt(:), vect2DInt(:,:), vect3DInt(:,:,:) => null()
integer(ids_int) :: ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7,dum1,dum2,dum3,dum4,dum5,dum6,dum7
real(ids_real) :: double0D
real(ids_real), pointer :: vect1DDouble(:), time(:), vect2DDouble(:,:), vect3DDouble(:,:,:), vect4DDouble(:,:,:,:) => null()
real(ids_real), pointer :: vect5DDouble(:,:,:,:,:), vect6DDouble(:,:,:,:,:,:) => null()
character(len=ids_string_length), dimension(:), pointer :: stringans => null()
character(len=100000)::longstring
character(len=300) :: timepath
integer(ids_int) :: obj_single_time,obj1,obj2,obj3,obj4,obj5,obj6,obj7
integer(ids_int) :: dimObj1,dimObj2,dimObj3,dimObj4,dimObj5,dimObj6,dimObj7
integer(ids_int) :: i1,i2,i3,i4,i5,i6,i7
<xsl:for-each select=".//field[@data_type='struct_array' and @maxoccur!='unbounded']">
integer(ids_int) :: i<xsl:value-of select="concat(@name,generate-id(.))"/>
</xsl:for-each>

type(ids_<xsl:value-of select="@name"/>) :: IDS

call getenv('ual_debug',ual_debug)


call begin_IDS_Get_Slice(idx,path, twant,status)
if (status.EQ.0) then
	      <xsl:apply-templates select="field" mode="GET_SLICE"/>
else
   write(*,*) 'Get slice impossible, IDS is missing or requested time slice is not within the time interval of the IDS'
endif
call end_IDS_Get_Slice(idx,path)

return
end subroutine ids_GET_SLICE_<xsl:value-of select="local:unique_name(@name)"/>

end module <xsl:value-of select="local:unique_name(@name)"/>_ids_module_get_slice
</xsl:result-document>



<xsl:result-document href="{@name}_copy.f90">
module <xsl:value-of select="local:unique_name(@name)"/>_copy
! Declaration of the generic IDS DELETE routine
interface ids_delete
   module procedure ids_delete_<xsl:value-of select="local:unique_name(@name)"/>
end interface ids_delete

<!-- ! Declaration of the generic IDS DEALLOCATE routine
interface ids_deallocate
   module procedure ids_deallocate_<xsl:value-of select="local:unique_name(@name)"/>
end interface ids_deallocate -->


<!-- ! Declaration of the generic IDS COPY routine
interface ids_copy
   module procedure ids_copy_<xsl:value-of select="local:unique_name(@name)"/>
end interface ids_copy -->




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

	if(0 .NE. is_critical_error(status) ) then
		exitRequest = .TRUE.
	endif

	if ( (ual_debug == 'yes') .OR. (ual_debug == 'vvv') .OR. exitRequest)then
		call get_last_errmsg(longstring)
		write(*,*) "ERROR! FIELD: ", trim(fieldPath), "    STATUS: ", status, "    MSG: ", trim(longstring)
	endif

END FUNCTION isErrorCritical


subroutine copy_flt1d(in, out)
use ids_schemas
implicit none
real(ids_real), pointer :: in(:), out(:)

if (associated(in)) then
   allocate(out(size(in)))
   out = in
endif
end subroutine copy_flt1d

<!-- ======================================  DELETE======================================= -->
!!!!!! Routine to DELETE the IDS

subroutine ids_delete_<xsl:value-of select="local:unique_name(@name)"/>(idx,IDSpath,IDS)  <!-- systematic calls to the low level delete_data routine. The IDS input argument is added just for the interface to identify the relevant IDS type -->

use ids_schemas
implicit none
character*(*) :: IDSpath
integer(ids_int) :: idx

type(ids_<xsl:value-of select="@name"/>) :: IDS
<xsl:for-each select=".//field[@data_type='struct_array' and @maxoccur!='unbounded']">
integer(ids_int) :: i<xsl:value-of select="concat(@name,generate-id(.))"/>
</xsl:for-each>

call getenv('ual_debug',ual_debug) ! Debug flag
if (ual_debug =='yes') write(*,*) 'Deleting IDS ',IDSpath
<xsl:apply-templates select="field" mode="DELETE"/>
if (ual_debug =='yes') write(*,*) 'Delete IDS ',IDSpath,' done'
end subroutine ids_delete_<xsl:value-of select="local:unique_name(@name)"/>



<!-- ======================================  DEALLOCATE ======================================= -->
<!-- !!!!!! Routines to DEALLOCATE IDSs

subroutine ids_deallocate_<xsl:value-of select="local:unique_name(@name)"/>(IDS)

use ids_schemas
implicit none

integer(ids_int) :: i1,i2,i3,i4,i5,i6,i7

type(ids_<xsl:value-of select="@name"/>) :: IDS
    <xsl:apply-templates select="field" mode="DEALLOCATE">
        <xsl:with-param name="level" select="1"/>
        <xsl:with-param name="idxpath" select="'IDS'"/>
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

integer(ids_int) :: itime, lentime, lenstring, istring
integer(ids_int) :: i1,i2,i3,i4,i5,i6,i7

type(ids_<xsl:value-of select="@name"/>) :: IDSin, IDSout

call getenv('ual_debug',ual_debug) ! Debug flag

      <xsl:apply-templates select="field" mode="COPY_FIELD">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="idxpath" select="''"/>
      </xsl:apply-templates>

return
end subroutine ids_copy_<xsl:value-of select="local:unique_name(@name)"/>
-->


end module <xsl:value-of select="local:unique_name(@name)"/>_copy
</xsl:result-document>
</xsl:template>














<!--!!!!!!!!!!!!!!!!!!!!!!!!!             GET SLICE ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->

  <!--<xsl:template match="IDS" mode="GET_SLICE_OLD">

</xsl:template>-->
	<xsl:template match="field" mode="GET_SLICE_OLD">
		<xsl:choose>
			<xsl:when test="@name='structure'">
				<xsl:apply-templates select="field" mode="GET_SLICE"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="@timed = 'yes'">
						<xsl:choose>
                     <xsl:when test="@name='struct_array'">
! Get <xsl:value-of select="@path"/>
                        <!-- for comment only -->
! Read timed content
! timed arrays of structures are included inside a time container, even if there is a single time
call get_object_slice(idx,path,"<xsl:value-of select = "@path"/>",twant,obj_single_time,status) ! read the whole timed block
if (status.EQ.0) then
   call get_object_from_object(idx,obj_single_time,"ALLTIMES",1,obj1,status)
   if (status.EQ.0) then
      call get_object_dim(idx,obj1,dimObj1)
      if (dimObj1.GT.0) then
         if (ual_debug =='yes') write(*,*) &amp;
            'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
         allocate(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>(dimObj1))
         do i1 = 1,dimObj1     ! process array elements
            <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
               <xsl:with-param name="level" select="1"/>
               <xsl:with-param name="objpath" select="@name"/>
               <xsl:with-param name="idxpath" select="concat('IDS%',translate(@path,'/','%'),'(i1)')"/>
               <xsl:with-param name="timed" select="'yes'"/>
            </xsl:apply-templates>
         enddo
      else
         if (associated(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
            deallocate(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>);
         endif
      endif
   endif
   call release_object(idx,obj_single_time)
endif

! Read non-timed content
call get_object(idx,path,"<xsl:value-of select = "@path"/>",obj1,0,status); ! read the whole non-timed block
if (status.EQ.0) then
   call get_object_dim(idx,obj1,dimObj1)
   if (dimObj1.NE.0) then
      if (.NOT.associated(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
         allocate(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>(dimObj1))
      endif
      ! must have same number of non-timed elements and timed elements
      if (size(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>).NE.dimObj1) then
         write(*,*) "Error in getSlice: array of structures has different number of timed and nontimed elements for <xsl:value-of select = "@path"/>"
      else
         do i1 = 1,dimObj1     ! process array elements
            <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
               <xsl:with-param name="level" select="1"/>
               <xsl:with-param name="objpath" select="@name"/>
               <xsl:with-param name="idxpath" select="concat('IDS%',translate(@path,'/','%'),'(i1)')"/>
               <xsl:with-param name="timed" select="'no'"/>
            </xsl:apply-templates>
         enddo
      endif
   endif
   call release_object(idx,obj1)
endif
<!-- -->
                     </xsl:when>
                     <xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
! Get <xsl:value-of select="@path"/>
                        <!-- for comment only -->
! TIME DEPENDENT STRINGS NOT TREATED YET !!!
<!-- -->
                     </xsl:when>
							<xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_Int_Slice(idx,path, "<xsl:value-of select="@path"/>",int0d, twant,tret,interpol,status)
if (status.EQ.0) then
   IDS%<xsl:value-of select="translate(@path,'/','%')"/> = int0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_double_Slice(idx,path, "<xsl:value-of select="@path"/>",double0d, twant,tret,interpol,status)
if (status.EQ.0) then
   IDS%<xsl:value-of select="translate(@path,'/','%')"/> = double0d
   if (ual_debug =='yes') write(*,*) &amp;
       'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
   call get_vect1d_Int_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dum1,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
       'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>", &amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
   call get_vect1d_double_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dum1,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test=" @data_type='FLT_2D'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
   call get_vect2d_double_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dum1,dum2,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test=" @data_type='INT_2D'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
   call get_vect2d_int_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dum1,dum2,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@data_type='FLT_3D'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
   call get_vect3d_double_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dim3,dum1,dum2,dum3,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@data_type='INT_3D'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
   call get_vect3d_int_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dim3,dum1,dum2,dum3,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>

							<xsl:when test="@data_type='FLT_4D'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4))
   call get_vect4d_double_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dim3,dim4,dum1,dum2,dum3,dum4,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>

							<xsl:when test="@data_type='FLT_5D'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5))
   call get_vect5d_double_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dim3,dim4,dim5,dum1,dum2,dum3,dum4,dum5,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@data_type='FLT_6D'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5,dim6))
   call get_vect6d_double_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dim3,dim4,dim5,dim6,dum1,dum2,dum3,dum4,dum5,dum6,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>




							<xsl:otherwise>
 ! Get <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<!-- Get the data from a time-independent field (straightforward) -->
						<!-- Elementary GET : same procedure as GET_SINGLE -->
						<xsl:apply-templates select="." mode="GET_SINGLE"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             GET FULL IDS ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->

	<xsl:template match="field" mode="GET_FULL">
		<xsl:choose>
			<xsl:when test="@timed = 'yes'">
				<!-- Time dependent dynamics in time-dependent IDS : copy the time-dependent value in the proper index of the array of IDS structure -->
				<xsl:choose>
					<xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
allocate(vect1DInt(lentime))
call get_vect1d_int(idx,path,"<xsl:value-of select="@path"/>",vect1DInt,lentime,dum1,status)
if (status.EQ.0) then
   IDSs(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect1DInt(1:lentime)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
deallocate(vect1DInt)
    <!-- -->
					</xsl:when>
					<xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
allocate(vect1Ddouble(lentime))
call get_vect1d_double(idx,path,"<xsl:value-of select="@path"/>",vect1Ddouble,lentime,dum1,status)
if (status.EQ.0) then
   IDSs(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect1Ddouble(1:lentime)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
deallocate(vect1Ddouble)
<!--do itime=1,lentime
   IDSs(itime)%<xsl:value-of select = "translate(@path,'/','%')"/> = vect1DDouble(itime)
enddo -->
						<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect2Ddouble(dim1,dim2)) <!-- dim2 contains lentime-->
   call get_vect2d_double(idx,path,"<xsl:value-of select="@path"/>",vect2Ddouble,dim1,dim2,dum1,dum2,status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect2DDouble(:,itime)   <!-- assign the value to the IDS structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect2DDouble)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect2Dint(dim1,dim2)) <!-- dim2 contains lentime-->
   call get_vect2d_int(idx,path,"<xsl:value-of select="@path"/>", &amp;
   vect2Dint,dim1,dim2,dum1,dum2,status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect2Dint(:,itime)   <!-- assign the value to the IDS structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect2Dint)
endif
<!-- -->
					</xsl:when>
					<xsl:when test=" @data_type='FLT_2D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect3Ddouble(dim1,dim2,dim3)) <!-- dim3 contains lentime-->
   call get_vect3D_double(idx,path,"<xsl:value-of select="@path"/>",vect3Ddouble,  &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect3DDouble(:,:,itime)   <!-- assign the value to the IDS structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect3DDouble)
endif
<!-- -->
					</xsl:when>
					<xsl:when test=" @data_type='INT_2D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect3DInt(dim1,dim2,dim3)) <!-- dim3 contains lentime-->
   call get_vect3D_Int(idx,path,"<xsl:value-of select="@path"/>",vect3DInt,dim1,dim2,dim3, &amp;
   dum1,dum2,dum3,status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect3DInt(:,:,itime)   <!-- assign the value to the IDS structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect3DInt)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='FLT_3D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect4Ddouble(dim1,dim2,dim3,dim4)) <!-- dim4 contains lentime-->
   call get_vect4D_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
         vect4Ddouble,dim1,dim2,dim3,dim4,dum1,dum2,dum3,dum4,status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect4DDouble(:,:,:,itime)   <!-- assign the value to the IDS structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect4DDouble)
endif
<!-- -->
					</xsl:when>
										<xsl:when test="@data_type='FLT_4D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect5Ddouble(dim1,dim2,dim3,dim4,dim5)) <!-- dim5 contains lentime-->
   call get_vect5D_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
         vect5Ddouble,dim1,dim2,dim3,dim4,dim5,dum1,dum2,dum3,dum4,dum5,status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect5DDouble(:,:,:,:,itime)   <!-- assign the value to the IDS structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect5DDouble)
endif
<!-- -->
					</xsl:when>
										<xsl:when test="@data_type='FLT_5D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect6Ddouble(dim1,dim2,dim3,dim4,dim5,dim6)) <!-- dim6 contains lentime-->
   call get_vect6D_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
         vect6Ddouble,dim1,dim2,dim3,dim4,dim5,dim6,dum1,dum2,dum3,dum4,dum5,dum6,status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect6DDouble(:,:,:,:,:,itime)   <!-- assign the value to the IDS structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect6DDouble)
endif
<!-- -->
					</xsl:when>

					<xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
! Get <xsl:value-of select="@path"/>  TIME-DEPENDENT STRING : NOT TREATED YET ... (NOT ALLOWED IN SCHEMAS YET !!!) <!-- for comment only -->
					</xsl:when>
					<xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
! Get <xsl:value-of select="@path"/>  TIME-DEPENDENT VECTOR OF STRINGS : NOT TREATED YET ... (NOT ALLOWED IN SCHEMAS YET !!!) <!-- for comment only -->
					</xsl:when>
					<xsl:when test="@name='structure'">
						<xsl:apply-templates select="field" mode="GET_FULL"/>
					</xsl:when>
               <xsl:when test="@name='struct_array'">
! Get <xsl:value-of select="@path"/>
                        <!-- for comment only -->
! Read timed content
! timed arrays of structures are included inside a time container, even if there is a single time
call get_object(idx,path,"<xsl:value-of select = "@path"/>",obj_all_times,1,status) ! read the whole timed block
if (status.EQ.0) then
   call get_object_dim(idx,obj_all_times,dimObj0)
   if (dimObj0.NE.lentime) then  ! // object must contain the right number of times
      write(*,*) "Error in get: array of structures is missing time slices for <xsl:value-of select = "@path"/>"
   else
      if (ual_debug =='yes') write(*,*) &amp;
         'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
      do itime = 1,lentime     ! fill every time slice
         call get_object_from_object(idx,obj_all_times,"ALLTIMES",itime,obj1,status)
         if (status.EQ.0) then
            call get_object_dim(idx,obj1,dimObj1)
            if (dimObj1.GT.0) then
               allocate(IDSs(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>(dimObj1))
               do i1 = 1,dimObj1     ! process array elements
                  <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
                     <xsl:with-param name="level" select="1"/>
                     <xsl:with-param name="objpath" select="@name"/>
                     <xsl:with-param name="idxpath" select="concat('IDSs(itime)%',translate(@path,'/','%'),'(i1)')"/>
                     <xsl:with-param name="timed" select="'yes'"/>
                  </xsl:apply-templates>
               enddo
            else
               if (associated(IDSs(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
                  deallocate(IDSs(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)
               endif
            endif
         endif
      enddo
   endif
   call release_object(idx,obj_all_times)
endif

! Read non-timed content
call get_object(idx,path,"<xsl:value-of select = "@path"/>",obj1,0,status); ! read the whole non-timed block
if (status.EQ.0) then
   call get_object_dim(idx,obj1,dimObj1)
   if (dimObj1.NE.0) then
      do itime = 1,lentime     ! fill every time slice
         ! does not exist yet (there was no timed content)
         if (.NOT.associated(IDSs(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
            allocate(IDSs(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>(dimObj1))
         endif
         ! must have same number of non-timed elements and timed elements
         if (size(IDSs(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>).NE.dimObj1) then
            write(*,*) "Error in get: array of structures has different number of timed and nontimed elements for <xsl:value-of select = "@path"/>"
         else
            do i1 = 1,dimObj1     ! process array elements
               <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
                  <xsl:with-param name="level" select="1"/>
                  <xsl:with-param name="objpath" select="@name"/>
                  <xsl:with-param name="idxpath" select="concat('IDSs(itime)%',translate(@path,'/','%'),'(i1)')"/>
                  <xsl:with-param name="timed" select="'no'"/>
               </xsl:apply-templates>
            enddo
         endif
      enddo
   endif
   call release_object(idx,obj1)
endif
<!-- -->
               </xsl:when>
					<xsl:otherwise>
 ! Get <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<!-- Time independent dynamics in time-dependent IDS : copy value to all time indices -->
				<xsl:choose>
					<xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
longstring = ' '
call get_String(idx,path, "<xsl:value-of select="@path"/>",longstring, status)
if (status.EQ.0) then
   do itime=1,lentime
      lenstring = len_trim(longstring)
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(floor(real(lenstring/ids_string_length))+1))
      if (lenstring &lt;= ids_string_length) then
         IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(1) = trim(longstring)
      else
         do istring=1,floor(real(lenstring/ids_string_length))+1
             IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(istring) = trim(longstring(1+(istring-1)*ids_string_length : istring*ids_string_length))
         enddo
      endif
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))  <!-- Do all allocate first together, otherwise problems if Get between two allocations of IDS(i)-->
   enddo
   allocate(stringpointer(dim1))
   call get_Vect1d_string(idx,path, "<xsl:value-of select="@path"/>", &amp;
                        stringpointer,dim1,dum1,status)
   do itime=1,lentime
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = stringpointer
   enddo
   deallocate(stringpointer)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_Int(idx,path, "<xsl:value-of select="@path"/>",Int0D, status)           <!--reads the MDS dynamic, which has one more dimension (time)-->
if (status.EQ.0) then
   IDSs(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/> = Int0D   <!-- assign the value to the IDS structure -->
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_Double(idx,path, "<xsl:value-of select="@path"/>",double0D, status)           <!--reads the MDS dynamic, which has one more dimension (time)-->
if (status.EQ.0) then
   IDSs(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/> = double0D   <!-- assign the value to the IDS structure -->
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect1DDouble(dim1))
   call get_vect1D_Double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect1DDouble,dim1,dum1, status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect1DDouble   <!-- assign the value to the IDS structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect1DDouble)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect1Dint(dim1))
   call get_vect1D_int(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect1Dint,dim1,dum1, status)           <!--reads the MDS dynamic, which has one more dimension (time)-->
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect1Dint   <!-- assign the value to the IDS structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect1Dint)
endif
<!-- -->
					</xsl:when>
					<xsl:when test=" @data_type='FLT_2D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect2DDouble(dim1,dim2))
   call get_vect2D_Double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect2DDouble,dim1,dim2,dum1,dum2, status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect2DDouble   <!-- assign the value to the IDS structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect2DDouble)
endif
<!-- -->
					</xsl:when>
					<xsl:when test=" @data_type='INT_2D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect2DInt(dim1,dim2))
   call get_vect2D_Int(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect2DInt,dim1,dim2,dum1,dum2, status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect2DInt   <!-- assign the value to the IDS structure -->
   enddo
   deallocate(vect2DInt)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='FLT_3D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect3DDouble(dim1,dim2,dim3))
   call get_vect3D_Double(idx,path, "<xsl:value-of select="@path"/>",vect3DDouble, &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect3DDouble   <!-- assign the value to the IDS structure -->
   enddo
   deallocate(vect3DDouble)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='INT_3D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect3DInt(dim1,dim2,dim3))
   call get_vect3D_Int(idx,path, "<xsl:value-of select="@path"/>",vect3DInt, &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect3DInt   <!-- assign the value to the IDS structure -->
   enddo
   deallocate(vect3DInt)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='FLT_4D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect4dDouble(dim1,dim2,dim3,dim4))
   call get_vect4d_Double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect4dDouble,dim1,dim2,dim3,dim4,dum1,dum2,dum3,dum4,status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect4dDouble   <!-- assign the value to the IDS structure -->
   enddo
   deallocate(vect4dDouble)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
										<xsl:when test="@data_type='FLT_5D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect5dDouble(dim1,dim2,dim3,dim4,dim5))
   call get_vect5d_Double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect5dDouble,dim1,dim2,dim3,dim4,dim5,dum1,dum2,dum3,dum4,dum5,status)
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect5dDouble   <!-- assign the value to the IDS structure -->
   enddo
   deallocate(vect5dDouble)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
										<xsl:when test="@data_type='FLT_6D'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect6dDouble(dim1,dim2,dim3,dim4,dim5,dim6))
   call get_vect6d_Double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect6dDouble,dim1,dim2,dim3,dim4,dim5,dim6,dum1,dum2,dum3,dum4,dum5,dum6,status)           <!--reads the MDS dynamic, which has one more dimension (time)-->
   do itime=1,lentime
      allocate(IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5,dim6))
      IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect6dDouble   <!-- assign the value to the IDS structure -->
   enddo
   deallocate(vect6dDouble)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
               <xsl:when test="@name='struct_array'">
! Get <xsl:value-of select="@path"/>
                        <!-- for comment only -->
! Read non-timed content
call get_object(idx,path,"<xsl:value-of select = "@path"/>",obj1,0,status); ! read the whole non-timed block
if (status.EQ.0) then
   do itime = 1,lentime     ! fill every time slice
      call get_object_dim(idx,obj1,dimObj1)
      if (dimObj1.GT.0) then
         allocate(IDSs(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>(dimObj1))
         do i1 = 1,dimObj1     ! process array elements
            <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
               <xsl:with-param name="level" select="1"/>
               <xsl:with-param name="objpath" select="@name"/>
               <xsl:with-param name="idxpath" select="concat('IDSs(itime)%',translate(@path,'/','%'),'(i1)')"/>
               <xsl:with-param name="timed" select="'no'"/>
            </xsl:apply-templates>
         enddo
      else
         if (associated(IDSs(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
            deallocate(IDSs(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)
         endif
      endif
   enddo
   call release_object(idx,obj1)
endif
<!-- -->
               </xsl:when>
					<xsl:when test="@name='structure'">
						<xsl:apply-templates select="field" mode="GET_FULL"/>
					</xsl:when>
					<xsl:otherwise>
 ! Get <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

<!--!!!!!!!!!!!!!!!!!!!!!!!!!             GET SINGLE IDS ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
	<xsl:template match="field" mode="GET_SINGLE_OLD">
		<!-- to get an element from a IDS which is NOT time-dependent : easy : elementary GET-->
		<xsl:choose>
			<xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
longstring = ' '
call get_string(idx,path, "<xsl:value-of select="@path"/>",longstring,status)
if (status.EQ.0) then
   lenstring = len_trim(longstring)
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(floor(real(lenstring/ids_string_length))+1))
   if (lenstring &lt;= ids_string_length) then
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> = trim(longstring)
   else
      do istring=1,floor(real(lenstring/ids_string_length))+1
          IDS%<xsl:value-of select="translate(@path,'/','%')"/>(istring) = trim(longstring(1+(istring-1)*ids_string_length : istring*ids_string_length))
      enddo
   endif
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
   call get_Vect1d_string(idx,path, "<xsl:value-of select="@path"/>", &amp;
                        IDS%<xsl:value-of select="translate(@path,'/','%')"/>,dim1,dum1,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_int(idx,path, "<xsl:value-of select="@path"/>",int0d,status)
if (status.EQ.0) then
   IDS%<xsl:value-of select="translate(@path,'/','%')"/> = int0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_double(idx,path, "<xsl:value-of select="@path"/>",double0d,status)
if (status.EQ.0) then
   IDS%<xsl:value-of select="translate(@path,'/','%')"/> = double0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
   call get_vect1d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>,dim1,dum1,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
   call get_vect1d_int(idx,path,"<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>,dim1,dum1,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test=" @data_type='FLT_2D'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
   call get_vect2d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dum1,dum2,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test=" @data_type='INT_2D'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
   call get_vect2d_int(idx,path,"<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dum1,dum2,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='FLT_3D'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
   call get_vect3d_double(idx,path,"<xsl:value-of select="@path"/>",&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='INT_3D'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
   call get_vect3d_int(idx,path,"<xsl:value-of select="@path"/>",&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='FLT_4D'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4))
   call get_vect4d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dim3,dim4,dum1,dum2,dum3,dum4,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>

			<xsl:when test="@data_type='FLT_5D'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5))
   call get_vect5d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dim3,dim4,dim5,dum1,dum2,dum3,dum4,dum5,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
						<xsl:when test="@data_type='FLT_6D'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
   ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5,dim6))
   call get_vect6d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dim3,dim4,dim5,dim6,dum1,dum2,dum3,dum4,dum5,dum6,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>

         <xsl:when test="@name='struct_array'">
! Get <xsl:value-of select="@path"/>
                        <!-- for comment only -->
! Read non-timed content
call get_object(idx,path,"<xsl:value-of select = "@path"/>",obj1,0,status); ! read the whole non-timed block
if (status.EQ.0) then
   call get_object_dim(idx,obj1,dimObj1)
   if (dimObj1.GT.0) then
      allocate(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>(dimObj1))
      do i1 = 1,dimObj1     ! process array elements
         <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
            <xsl:with-param name="level" select="1"/>
            <xsl:with-param name="objpath" select="@name"/>
            <xsl:with-param name="idxpath" select="concat('IDS%',translate(@path,'/','%'),'(i1)')"/>
            <xsl:with-param name="timed" select="'no'"/>
         </xsl:apply-templates>
      enddo
   else
      if (associated(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
         deallocate(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)
      endif
   endif
   call release_object(idx,obj1)
endif
<!-- -->
         </xsl:when>
			<xsl:when test="@name='structure'">
				<xsl:apply-templates select="field" mode="GET_SINGLE"/>
			</xsl:when>
			<xsl:otherwise>
 ! Get <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>



   <!--!!!!!!!!!!!!!!!!!!!!!!!!!             GET FROM OBJECT           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->

<xsl:template match = "field" mode = "GET_FROM_OBJECT">
  <xsl:param name="level"/>     <!-- recursion level -->
  <xsl:param name="objpath"/>   <!-- path inside the object -->
  <xsl:param name="idxpath"/>   <!-- full C++ path including indices -->
  <xsl:param name="timed"/>     <!-- are we looking for timed or non-timed fields? -->

  <!-- build the path of the current field inside the object -->
  <xsl:param name="currentobjpath" select="concat($objpath,'/',@name)"/>
  <!-- build the complete path of the current field -->
  <xsl:param name="currentidxpath" select="concat($idxpath,'%',@name)"/>

  <xsl:choose>
    <!--========== Arrays of structures ==========-->
    <xsl:when test="@data_type='struct_array'">
! Get <xsl:value-of select="@path"/>
<!-- -->
<xsl:choose>
<xsl:when test="$timed = 'yes'">
<!-- We are scanning the children of a Type 3 AoS, so we extract the child object at index 1 of the parent object -->
call get_object_from_object(idx, obj<xsl:value-of select="$level"/>, "<xsl:value-of select = "$currentobjpath"/>", 1, obj<xsl:value-of select="$level + 1"/>,status)
</xsl:when>
<xsl:otherwise>
<!-- Otherwise we assume it is a Type 2 AoS, so we extract the child object at index iobject -->
call get_object_from_object(idx, obj<xsl:value-of select="$level"/>, "<xsl:value-of select = "$currentobjpath"/>", i<xsl:value-of select="$level"/>, obj<xsl:value-of select="$level + 1"/>,status)
</xsl:otherwise>
</xsl:choose>

if (status.EQ.0) then
   call get_object_dim(idx,obj<xsl:value-of select="$level + 1"/>,dimObj<xsl:value-of select="$level + 1"/>)
   if (dimObj<xsl:value-of select="$level + 1"/>.GT.0) then
      if (associated(<xsl:value-of select="$currentidxpath"/>)) then ! does this array already exist? (timed and non timed parts can share the same array)
         if (size(<xsl:value-of select="$currentidxpath"/>).NE.dimObj<xsl:value-of select="$level + 1"/>) then ! then it must have the right number of elements
            write(*,*) "Error in get: array of structures has different number of timed and nontimed elements for <xsl:value-of select = "@path"/>"
            deallocate(<xsl:value-of select="$currentidxpath"/>)
         endif
      else
         allocate(<xsl:value-of select="$currentidxpath"/>(dimObj<xsl:value-of select="$level + 1"/>))
      endif
      if (associated(<xsl:value-of select="$currentidxpath"/>)) then
         do i<xsl:value-of select="$level + 1"/> = 1,dimObj<xsl:value-of select="$level + 1"/>     ! process array elements
            <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
               <xsl:with-param name="level" select="$level + 1"/>
               <xsl:with-param name="objpath" select="@name"/>
               <xsl:with-param name="idxpath" select="concat($currentidxpath,'(i',$level + 1,')')"/>
               <xsl:with-param name="timed" select="'no'"/>  <!-- We assume the nested children are necessarily Type 2 -->
            </xsl:apply-templates>
         enddo
      endif
   endif
endif
  <!--    </xsl:if> -->
    </xsl:when>

    <!--========== Regular structure ==========-->
    <xsl:when test="@data_type='structure'">
      <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
         <xsl:with-param name="level" select="$level"/>
         <xsl:with-param name="objpath" select="$currentobjpath"/>
         <xsl:with-param name="idxpath" select="$currentidxpath"/>
         <xsl:with-param name="timed" select="$timed"/>
      </xsl:apply-templates>
    </xsl:when>

    <xsl:otherwise>
      <!--========== select either timed or non-timed fields ==========-->
      <!--<xsl:if test="@timed=$timed">-->
        <xsl:choose>
         <xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
longstring = ' '
call get_string_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>,longstring,status)
if (status.EQ.0) then
   lenstring = len_trim(longstring)
   allocate(<xsl:value-of select="$currentidxpath"/>(floor(real(lenstring/ids_string_length))+1))
   if (lenstring &lt;= ids_string_length) then
      <xsl:value-of select="$currentidxpath"/> = trim(longstring)
   else
      do istring=1,floor(real(lenstring/ids_string_length))+1
          <xsl:value-of select="$currentidxpath"/>(istring) = trim(longstring(1+(istring-1)*ids_string_length : istring*ids_string_length))
      enddo
   endif
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1))
   call get_vect1d_string_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>, &amp;
                        <xsl:value-of select="$currentidxpath"/>,dim1,dum1,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Get <xsl:value-of select="@path"/>
call fget_int_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   "<xsl:value-of select="$currentidxpath"/>", ual_debug, status)
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Get <xsl:value-of select="@path"/>
call fget_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose> , &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   "<xsl:value-of select="$currentidxpath"/>", ual_debug, status)
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Get <xsl:value-of select="@path"/>
call fget_vect1d_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   "<xsl:value-of select="$currentidxpath"/>", ual_debug)
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1))
   call get_vect1d_int_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>, &amp;
   <xsl:value-of select="$currentidxpath"/>,dim1,dum1,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test=" @data_type='FLT_2D'">
! Get <xsl:value-of select="@path"/>
call fget_vect2d_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   "<xsl:value-of select="$currentidxpath"/>", ual_debug)
<!-- -->
         </xsl:when>
         <xsl:when test=" @data_type='INT_2D'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1,dim2))
   call get_vect2d_int_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   dim1,dim2,dum1,dum2,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='FLT_3D'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1,dim2,dim3))
   call get_vect3d_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>,&amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='INT_3D'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1,dim2,dim3))
   call get_vect3d_int_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>,&amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='FLT_4D'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1,dim2,dim3,dim4))
   call get_vect4d_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   dim1,dim2,dim3,dim4,dum1,dum2,dum3,dum4,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>

         <xsl:when test="@data_type='FLT_5D'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1,dim2,dim3,dim4,dim5))
   call get_vect5d_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   dim1,dim2,dim3,dim4,dim5,dum1,dum2,dum3,dum4,dum5,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
                  <xsl:when test="@data_type='FLT_6D'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1,dim2,dim3,dim4,dim5,dim6))
   call get_vect6d_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:choose><xsl:when test="$timed='yes'">1</xsl:when><xsl:otherwise>i<xsl:value-of select="$level"/></xsl:otherwise></xsl:choose>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   dim1,dim2,dim3,dim4,dim5,dim6,dum1,dum2,dum3,dum4,dum5,dum6,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
         </xsl:when>
        </xsl:choose>
      <!--</xsl:if>-->
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

   <!--!!!!!!!!!!!!!!!!!!!!!!!!!             PUT FULL IDS ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
	<!--<xsl:template match="IDS" mode="PUT">-->


<!--!!!!!!!!!!!!!!!!!!!!!!!!!        PUT FULL TIME DEPENDENT OBJECT       !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<!--</xsl:template>-->
	<xsl:template match="field" mode="PUT_TIMED">
		<xsl:choose>
			<xsl:when test="@timed = 'yes'">
				<!-- Time dependent dynamics in time-dependent IDS : copy the time-dependent value from the proper index of the array of IDS structure -->
				<xsl:choose>
					<xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Put <xsl:value-of select="@path"/>
if (any(IDSs(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/>/=ids_int_invalid))  then
   allocate(vect1Dint(lentime))
   vect1DInt(1:lentime) = IDSs(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/>
   call put_vect1D_int(idx,path, "<xsl:value-of select="@path"/>",&amp;
   vect1DInt,lentime,1, status)
   deallocate(vect1DInt)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>


endif
        <!-- -->
					</xsl:when>
					<xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Put <xsl:value-of select="@path"/>
if (any(IDSs(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/>/=ids_real_invalid))  then
   allocate(vect1DDouble(lentime))
   vect1DDouble(1:lentime) = IDSs(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/>
   call put_vect1D_double(idx,path, "<xsl:value-of select="@path"/>",vect1DDouble,lentime,1, status)
   deallocate(vect1DDouble)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! put <xsl:value-of select="@path"/>
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect2DDouble(size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),lentime))
   do itime=1,lentime
      vect2DDouble(:,itime) = IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect2D_Double(idx,path, "<xsl:value-of select="@path"/>",vect2DDouble, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),lentime,1, status)
   deallocate(vect2DDouble)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>
               <xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! put <xsl:value-of select="@path"/>
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect2DInt(size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),lentime))
   do itime=1,lentime
      vect2DInt(:,itime) = IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect2D_Int(idx,path, "<xsl:value-of select="@path"/>",vect2DInt, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),lentime,1, status)
   deallocate(vect2DInt)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>
					<xsl:when test=" @data_type='FLT_2D'">
! put <xsl:value-of select="@path"/>
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect3DDouble(size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),lentime))
   do itime=1,lentime
      vect3DDouble(:,:,itime)  = IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect3D_Double(idx,path, "<xsl:value-of select="@path"/>",vect3DDouble, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),lentime,1, status)
   deallocate(vect3DDouble)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>
					<xsl:when test=" @data_type='INT_2D'">
! put <xsl:value-of select="@path"/>
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect3Dint(size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),lentime))
   do itime=1,lentime
      vect3Dint(:,:,itime)  = IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect3D_int(idx,path, "<xsl:value-of select="@path"/>",vect3Dint, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),lentime,1, status)
   deallocate(vect3Dint)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='FLT_3D'">
! put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect4dDouble(size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),lentime))
   do itime=1,lentime
      vect4dDouble(:,:,:,itime)  = IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect4d_Double(idx,path, "<xsl:value-of select="@path"/>",vect4dDouble, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),lentime,1, status)
   deallocate(vect4dDouble)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>

					<xsl:when test="@data_type='FLT_4D'">
! put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect5dDouble(size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3), &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4), lentime))
   do itime=1,lentime
      vect5dDouble(:,:,:,:,itime)  = IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect5d_Double(idx,path, "<xsl:value-of select="@path"/>",vect5dDouble, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   lentime,1, status)
   deallocate(vect5dDouble)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='FLT_5D'">
! put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect6dDouble(size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3), &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4), &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,5), lentime))
   do itime=1,lentime
      vect6dDouble(:,:,:,:,:,itime)  = IDSs(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect6d_Double(idx,path, "<xsl:value-of select="@path"/>",vect6dDouble, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,5),lentime,1, status)
   deallocate(vect6dDouble)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
<!-- -->
					</xsl:when>
               <xsl:when test="@name='struct_array'">
! Write timed fields    */
call begin_object(idx,-1,1,path//"/<xsl:value-of select = "@path"/>",TIMED_CLEAR,obj_all_times)
do itime = 1,lentime
   call begin_object(idx,obj_all_times,itime,"ALLTIMES",TIMED,obj1)
   if (associated(IDSs(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
      do i1 = 1,size(IDSs(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)
         <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
               <xsl:with-param name="level" select="1"/>
               <xsl:with-param name="objpath" select="@name"/>
               <xsl:with-param name="idxpath" select="concat('IDSs(itime)%',translate(@path,'/','%'),'(i1)')"/>
               <xsl:with-param name="child_index" select="1"/>
         </xsl:apply-templates>
      enddo
   endif
   call put_object_in_object(idx,obj_all_times,"ALLTIMES",itime,obj1)
enddo
call put_object(idx,path,"<xsl:value-of select = "@path"/>",obj_all_times,1, status)

! Write non-timed fields    */
call begin_object(idx,-1,1,path//"/<xsl:value-of select = "@path"/>",NON_TIMED,obj1)
if (associated(IDSs(1)%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
   do i1 = 1,size(IDSs(1)%<xsl:value-of select = "translate(@path,'/','%')"/>)
      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="objpath" select="@name"/>
         <xsl:with-param name="idxpath" select="concat('IDSs(1)%',translate(@path,'/','%'),'(i1)')"/>
         <xsl:with-param name="timed" select="'no'"/>
      </xsl:apply-templates>
   enddo
endif
call put_object(idx,path,"<xsl:value-of select = "@path"/>",obj1,0, status)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
               </xsl:when>

					<xsl:when test="@name='structure'">
						<xsl:apply-templates select="field" mode="PUT_TIMED"/>
					</xsl:when>
					<xsl:otherwise>
 ! Get <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!!
        </xsl:otherwise>
				</xsl:choose>
			</xsl:when>

			<xsl:otherwise>
				<!-- Time independent dynamics in time-dependent IDS : the first index IDSs(1) defines the value of the time-independent data -->
				<xsl:choose>
               <xsl:when test="@name='struct_array'">
! Put <xsl:value-of select="@path"/>
                  <!-- for comment only -->
! Write non-timed fields    */
call begin_object(idx,-1,1,path//"/<xsl:value-of select = "@path"/>",NON_TIMED,obj1)
if (associated(IDSs(1)%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
   do i1 = 1,size(IDSs(1)%<xsl:value-of select = "translate(@path,'/','%')"/>)
      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="objpath" select="@name"/>
         <xsl:with-param name="idxpath" select="concat('IDSs(1)%',translate(@path,'/','%'),'(i1)')"/>
         <xsl:with-param name="timed" select="'no'"/>
      </xsl:apply-templates>
   enddo
endif
call put_object(idx,path,"<xsl:value-of select = "@path"/>",obj1,0, status)

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

               </xsl:when>
					<xsl:when test="@name='structure'">
						<xsl:apply-templates select="field" mode="PUT_TIMED"/>
					</xsl:when>
					<xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   longstring = ' '    <!-- Initialisation of longstring, otherwise strange problems occur !-->
   lenstring = size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)
   if (lenstring.EQ.1) then
      longstring = trim(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>(1))
   else
      do istring=1,lenstring
          longstring(1+(istring-1)*ids_string_length : istring*ids_string_length) = IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>(istring)
      enddo
   endif
   call put_string(idx,path, "<xsl:value-of select="@path"/>",trim(longstring), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   dim1 = size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)
   allocate(dimtab(dim1))
   do i=1,dim1
      dimtab(i) = len_trim(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>(i))
   enddo
   call put_Vect1d_String(idx,path, "<xsl:value-of select="@path"/>", &amp;
         IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,dim1,dimtab,0, status)
   deallocate(dimtab)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>.NE.ids_int_invalid) then
   call put_int(idx,path, "<xsl:value-of select="@path"/>",IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>.NE.ids_real_invalid) then
   call put_double(idx,path, "<xsl:value-of select="@path"/>",IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect1d_double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>),0, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect1d_int(idx,path, "<xsl:value-of select="@path"/>",&amp;
   IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>),0, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>
					<xsl:when test=" @data_type='FLT_2D'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect2d_double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),0, status)
   if (ual_debug =='yes') write(*,*) &amp;
       'Put IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>
					<xsl:when test=" @data_type='INT_2D'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect2d_int(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1), &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='FLT_3D'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect3d_double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1), &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),0, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='INT_3D'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect3d_int(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1), &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),0, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>
					<xsl:when test="@data_type='FLT_4D'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect4d_double(idx,path, "<xsl:value-of select="@path"/>",IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4),0, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>
<xsl:when test="@data_type='FLT_5D'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect5d_double(idx,path, "<xsl:value-of select="@path"/>",IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,5),0, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
</xsl:when>
<xsl:when test="@data_type='FLT_6D'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect6d_double(idx,path, "<xsl:value-of select="@path"/>",IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,5),size(IDSs(1)%<xsl:value-of select="translate(@path,'/','%')"/>,6),0, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDSs%<xsl:value-of select="translate(@path,'/','%')"/>'
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
<!-- -->
					</xsl:when>


					<xsl:otherwise>
 ! Put <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

<!--!!!!!!!!!!!!!!!!!!!!!!!!!        PUT_SINGLE for FIELDS       !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="PUT_SINGLE">
<xsl:param name="variable_path"/>
<xsl:param name="mds_path"/>
<xsl:param name="non_timed"/>

<xsl:if test="$non_timed !='yes' or @type !='dynamic' or not(@type) or @data_type='structure' or (@data_type='struct_array' and @type !='dynamic')"> <!-- This skips the routine for timed fields when using this template in PUT_NON_TIMED mode -->
		<xsl:choose>
			<xsl:when test="@data_type='structure'">
<xsl:choose>
<xsl:when test="$variable_path">
<xsl:apply-templates select="field" mode="PUT_SINGLE">
<xsl:with-param name ="variable_path" select="concat($variable_path,'%',@name)"/>
<xsl:with-param name ="mds_path" select="concat($mds_path,'//&quot;/',@name,'&quot;')"/>
<xsl:with-param name="non_timed" select="$non_timed"/>
</xsl:apply-templates>
</xsl:when>
<xsl:otherwise>
<xsl:apply-templates select="field" mode="PUT_SINGLE">
<xsl:with-param name ="variable_path" select="@name"/>
<xsl:with-param name ="mds_path" select="concat('&quot;',@name,'&quot;')"/>
<xsl:with-param name="non_timed" select="$non_timed"/>
</xsl:apply-templates>
</xsl:otherwise>
</xsl:choose>

			</xsl:when>
         <xsl:when test="@data_type='struct_array' and @maxoccur!='unbounded'">
<!-- Type 1 arrays of structure, with potentially multiple time bases -->
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>)) then
   call put_int(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>/Shape_of&quot;,&amp;
       size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>), status)
   do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,size(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>)
      <xsl:apply-templates select = "field" mode = "PUT_SINGLE">
<xsl:with-param name ="variable_path" select="concat($variable_path,'%',@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat($mds_path,'//','&quot;/',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
<xsl:with-param name="non_timed" select="$non_timed"/>
</xsl:apply-templates>
   enddo
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
   call put_int(idx,path, &quot;<xsl:value-of select="@name"/>/Shape_of&quot;,&amp;
       size(IDS%<xsl:value-of select="@name"/>), status)
      <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

   do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,size(IDS%<xsl:value-of select = "@name"/>)
      <xsl:apply-templates select = "field" mode = "PUT_SINGLE">
<xsl:with-param name ="variable_path" select="concat(@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat('&quot;',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
<xsl:with-param name="non_timed" select="$non_timed"/>

</xsl:apply-templates>
   enddo
endif
</xsl:otherwise>
</xsl:choose>
</xsl:when>
          <xsl:when test="@data_type='struct_array' and @maxoccur='unbounded' and @type='dynamic'">
<!-- Type 3 arrays of structure, with a unique time base -->
<xsl:choose>
<xsl:when test="$variable_path">
! Structure array of type 3 nested below a Type 1 : <xsl:value-of select = "concat($variable_path,'%',@name)"/>
if (associated(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>)) then

   call begin_object(idx,-1,1,path//<xsl:value-of select = "concat('&quot;','/',substring($mds_path,2),'//&quot;/',@name,'&quot;')"/>,TIMED_CLEAR,obj_all_times)
   do i1 = 1,size(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>)
      call begin_object(idx,obj_all_times,i1,"ALLTIMES",TIMED,obj1)
         <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
               <xsl:with-param name="level" select="1"/>
               <xsl:with-param name="objpath" select="@name"/>
               <xsl:with-param name="idxpath" select="concat('IDS%',$variable_path,'%',@name,'(i1)')"/>
               <xsl:with-param name="child_index" select="1"/>
         </xsl:apply-templates>
      call put_object_in_object(idx,obj_all_times,"ALLTIMES",i1,obj1)
   enddo

   ! Store time of the array of structure (hidden variable for the user, but used by the UAL for future get_slice operations)
   ! A temporary "time" vector is filled then put as a regular variable (outside of the object) as AoS%time
   allocate(time(size(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>)))


   if (IDS%IDS_Properties%homogeneous_time.EQ.1) then
           ! Use the general time vector of the IDS to fill time
      		do i1 = 1,size(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>) 
         		time(i1) = ids%time(i1) 
      		enddo
   else
   	if (IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>(1)%time.EQ.ids_real_invalid) then ! Check the presence of a time vector at the root of the AoS (on the first index only)
	         write(*,*) "ERROR : the time vector of the type 3 array of structure <xsl:value-of select = "concat($variable_path,'%',@name)"/> must be filled"
        	 return
   	else
      		do i1 = 1,size(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>) ! the AoS time vector is there, fill time with it
         		time(i1) = IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>(i1)%time
      		enddo
	endif
   endif

   timepath=<xsl:value-of select="concat($mds_path,'//&quot;/',@name,'/time')"/>" ! Start to put time
   call begin_IDS_put_timed(idx, path,size(time),time)
   call put_vect1d_double(idx,path, trim(timepath),&amp;
        trim(timepath),&amp;
        time,&amp;
        size(time),1, status)

   call end_IDS_put_timed(idx, path)
   if (ual_debug =='yes') write(*,*) &amp;
   'Put <xsl:value-of select="concat($mds_path,'//&quot;/',@name,'/time')"/>', time
   deallocate(time)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

   call put_object(idx,path,<xsl:value-of select = "concat($mds_path,'//&quot;/',@name)"/>",obj_all_times,1, status)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
! Structure array of type 3 : <xsl:value-of select = "@path"/>
if (associated(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
   call begin_object(idx,-1,1,path//"/<xsl:value-of select = "@path"/>",TIMED_CLEAR,obj_all_times)
   do i1 = 1,size(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)
      call begin_object(idx,obj_all_times,i1,"ALLTIMES",TIMED,obj1)
         <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
               <xsl:with-param name="level" select="1"/>
               <xsl:with-param name="objpath" select="@name"/>
               <xsl:with-param name="idxpath" select="concat('IDS%',translate(@path,'/','%'),'(i1)')"/>
               <xsl:with-param name="child_index" select="1"/>
         </xsl:apply-templates>
      call put_object_in_object(idx,obj_all_times,"ALLTIMES",i1,obj1)
   enddo

   ! Store time of the array of structure (hidden variable for the user, but used by the UAL for future get_slice operations)
  allocate(time(size(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)))
   if (IDS%IDS_Properties%homogeneous_time.EQ.1) then
           time = ids%time ! Use the general time vector of the IDS to fill time
   else
         if (IDS%<xsl:value-of select = "translate(@path,'/','%')"/>(1)%time.EQ.ids_real_invalid) then ! Check the presence of a time vector at the root of the AoS (on the first index only)
                 write(*,*) "ERROR : the time vector of the type 3 array of structure <xsl:value-of select = "translate(@path,'/','%')"/> must be filled"
                 return
         else
     		 do i1 = 1,size(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>) ! the AoS time vector is there, fill time with it
         		time(i1) = IDS%<xsl:value-of select = "translate(@path,'/','%')"/>(i1)%time
      		 enddo
         endif
   endif

    timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
    call begin_IDS_put_timed(idx, path,size(time),time)
    call put_vect1d_double(idx,path, trim(timepath),&amp;
        trim(timepath),&amp;
        time,&amp;
        size(time),1, status)

    call end_IDS_put_timed(idx, path)
    if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:call-template name="printtimevariable"/>',time
    deallocate(time)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

    call put_object(idx,path,"<xsl:value-of select = "@path"/>",obj_all_times,1, status)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>
         </xsl:when>
          <xsl:when test="@data_type='struct_array' and @maxoccur='unbounded' and @type!='dynamic'">
<!-- Type 2 arrays of structure-->
<xsl:choose>
<xsl:when test="$variable_path">
! Structure array of type 2 nested below a Type 1 : ERROR: NOT HANDLED YET <xsl:value-of select = "concat($variable_path,'%',@name)"/>
</xsl:when>
<xsl:otherwise>
! Structure array of type 2 : <xsl:value-of select = "@path"/>
<!-- Handle only non-timed descendants of type 2 AoS for the moment -->
<!-- Type 2 structure arrays not handled yet, I put here a copy of the ITM treatment for recall -->
! Write non-timed fields    */
call begin_object(idx,-1,1,path//"/<xsl:value-of select = "@path"/>",NON_TIMED,obj1)
if (associated(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
   do i1 = 1,size(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)
      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">  <!-- Select at this level dynamic fields only ? (how does it behave in time-dependent structures ? -->
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="objpath" select="@name"/>
         <xsl:with-param name="idxpath" select="concat('IDS%',translate(@path,'/','%'),'(i1)')"/>
         <xsl:with-param name="child_index" select="1"/> <!--Not sure here, maybe i1 is the correct way... -->
      </xsl:apply-templates>
   enddo
endif
call put_object(idx,path,"<xsl:value-of select = "@path"/>",obj1,0, status)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

</xsl:otherwise>
</xsl:choose>
         </xsl:when>
			<xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   longstring = ' '    <!-- Initialisation of longstring, otherwise strange problems occur !-->
   lenstring = size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)
   if (lenstring.EQ.1) then
      longstring = trim(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(1))
   else
      do istring=1,lenstring
          longstring(1+(istring-1)*ids_string_length : istring*ids_string_length) = IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(istring)
      enddo
   endif
   call put_string(idx,path,&amp;
       <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
       trim(longstring), status)
       ! should clean up longstring after that, or send to the put only the right length, which has been updated
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
<!-- -->
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="@name"/>)) then
   longstring = ' '    <!-- Initialisation of longstring, otherwise strange problems occur !-->
   lenstring = size(IDS%<xsl:value-of select="@name"/>)
   if (lenstring.EQ.1) then
      longstring = trim(IDS%<xsl:value-of select="@name"/>(1))
   else
      do istring=1,lenstring
          longstring(1+(istring-1)*ids_string_length : istring*ids_string_length) = IDS%<xsl:value-of select="@name"/>(istring)
      enddo
   endif
   call put_string(idx,path, "<xsl:value-of select="@name"/>",trim(longstring), status)       ! should clean up longstring after that, or send to the put only the right length, which has been updated
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="@name"/>',&amp;
      IDS%<xsl:value-of select="@name"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
<!-- -->
</xsl:otherwise>
</xsl:choose>



<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=<xsl:value-of select="$mds_path"/>//&quot;/time&quot;
       call begin_IDS_put_timed(idx, path,size(IDS%<xsl:value-of select="concat($variable_path,'%time')"/>),&amp;
       IDS%<xsl:value-of select="concat($variable_path,'%time')"/>)
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>), &amp;
       <xsl:call-template name="printtimevariable"/>)
       </xsl:otherwise>
       </xsl:choose>
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   dim1 = size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)
   allocate(dimtab(dim1))
   do i=1,dim1
      dimtab(i) = len_trim(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(i))
   enddo
   call put_Vect1d_String(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
          trim(timepath),IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,dim1,dimtab,<xsl:call-template name="printIsTimed"/>, status)
   deallocate(dimtab)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
<!-- -->
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="@name"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       timepath="<xsl:call-template name="printtimepath"/>"
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   dim1 = size(IDS%<xsl:value-of select="@name"/>)
   allocate(dimtab(dim1))
   do i=1,dim1
      dimtab(i) = len_trim(IDS%<xsl:value-of select="@name"/>(i))
   enddo
   call put_Vect1d_String(idx,path, "<xsl:value-of select="@name"/>", &amp;
          trim(timepath),IDS%<xsl:value-of select="@name"/>,dim1,dimtab,<xsl:call-template name="printIsTimed"/>, status)
   deallocate(dimtab)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="@name"/>'
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
<!-- -->
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>.NE.ids_int_invalid) then
   call put_int(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
       IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (IDS%<xsl:value-of select="translate(@path,'/','%')"/>.NE.ids_int_invalid) then
   call put_int(idx,path, "<xsl:value-of select="@path"/>",IDS%<xsl:value-of select="translate(@path,'/','%')"/>, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',IDS%<xsl:value-of select="translate(@path,'/','%')"/>

      <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>.NE.ids_real_invalid) then
   call put_double(idx,path,&amp;
       <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
       IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,&amp;
       status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
          IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
<!-- -->
</xsl:when>
<xsl:otherwise>
if (IDS%<xsl:value-of select="@name"/>.NE.ids_real_invalid) then
   call put_double(idx,path, "<xsl:value-of select="@path"/>",IDS%<xsl:value-of select="translate(@path,'/','%')"/>, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',IDS%<xsl:value-of select="translate(@path,'/','%')"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
<!-- -->
</xsl:otherwise>
</xsl:choose>


			</xsl:when>
			<xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=<xsl:value-of select="$mds_path"/>//&quot;/time&quot;
       call begin_IDS_put_timed(idx, path,size(IDS%<xsl:value-of select="concat($variable_path,'%time')"/>),&amp;
       IDS%<xsl:value-of select="concat($variable_path,'%time')"/>)
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
       </xsl:otherwise>
       </xsl:choose>
   else
        timepath="time"
        call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect1d_double(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>),<xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       timepath="<xsl:call-template name="printtimepath"/>"
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect1d_double(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>),<xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=<xsl:value-of select="$mds_path"/>//&quot;/time&quot;
       call begin_IDS_put_timed(idx, path,size(IDS%<xsl:value-of select="concat($variable_path,'%time')"/>),&amp;
       IDS%<xsl:value-of select="concat($variable_path,'%time')"/>)
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
       </xsl:otherwise>
       </xsl:choose>
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect1d_int(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath), &amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>),<xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       timepath="<xsl:call-template name="printtimepath"/>"
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect1d_int(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>),<xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>

<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='FLT_2D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=<xsl:value-of select="$mds_path"/>//&quot;/time&quot;
       call begin_IDS_put_timed(idx, path,size(IDS%<xsl:value-of select="concat($variable_path,'%time')"/>),&amp;
       IDS%<xsl:value-of select="concat($variable_path,'%time')"/>)
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
       </xsl:otherwise>
       </xsl:choose>
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect2d_double(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>, &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,2),<xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       timepath="<xsl:call-template name="printtimepath"/>"
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect2d_double(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),<xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>

<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='INT_2D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=<xsl:value-of select="$mds_path"/>//&quot;/time&quot;
       call begin_IDS_put_timed(idx, path,size(IDS%<xsl:value-of select="concat($variable_path,'%time')"/>),&amp;
       IDS%<xsl:value-of select="concat($variable_path,'%time')"/>)
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
       </xsl:otherwise>
       </xsl:choose>
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect2d_int(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>, &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,2),<xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       timepath="<xsl:call-template name="printtimepath"/>"
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect2d_int(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),<xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>

<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='FLT_3D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=<xsl:value-of select="$mds_path"/>//&quot;/time&quot;
       call begin_IDS_put_timed(idx, path,size(IDS%<xsl:value-of select="concat($variable_path,'%time')"/>),&amp;
       IDS%<xsl:value-of select="concat($variable_path,'%time')"/>)
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
       </xsl:otherwise>
       </xsl:choose>
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect3d_double(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>, &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,2),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,3),&amp;
   <xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       timepath="<xsl:call-template name="printtimepath"/>"
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect3d_double(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,3),&amp;
   <xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>
    <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='INT_3D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=<xsl:value-of select="$mds_path"/>//&quot;/time&quot;
       call begin_IDS_put_timed(idx, path,size(IDS%<xsl:value-of select="concat($variable_path,'%time')"/>),&amp;
       IDS%<xsl:value-of select="concat($variable_path,'%time')"/>)
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
       </xsl:otherwise>
       </xsl:choose>
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect3d_int(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>, &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,2),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,3),&amp;
   <xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       timepath="<xsl:call-template name="printtimepath"/>"
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect3d_int(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,3),&amp;
   <xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>

 endif
</xsl:otherwise>
</xsl:choose>

			</xsl:when>
			<xsl:when test="@data_type='FLT_4D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=<xsl:value-of select="$mds_path"/>//&quot;/time&quot;
       call begin_IDS_put_timed(idx, path,size(IDS%<xsl:value-of select="concat($variable_path,'%time')"/>),&amp;
       IDS%<xsl:value-of select="concat($variable_path,'%time')"/>)
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
       </xsl:otherwise>
       </xsl:choose>
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect4d_double(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>, &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,2),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,3),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,4),&amp;
   <xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       timepath="<xsl:call-template name="printtimepath"/>"
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect4d_double(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,3),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   <xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>

    <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>

endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
         <xsl:when test="@data_type='FLT_5D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=<xsl:value-of select="$mds_path"/>//&quot;/time&quot;
       call begin_IDS_put_timed(idx, path,size(IDS%<xsl:value-of select="concat($variable_path,'%time')"/>),&amp;
       IDS%<xsl:value-of select="concat($variable_path,'%time')"/>)
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
       </xsl:otherwise>
       </xsl:choose>
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect5d_double(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>, &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,2),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,3),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,4),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,5),&amp;
   <xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       timepath="<xsl:call-template name="printtimepath"/>"
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect5d_double(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,3),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,5),&amp;
   <xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
         <xsl:when test="@data_type='FLT_6D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       <!--XSLtest whether this is a data/time structure, otherwise assume that the timepath attribute from IDSDef is correct-->
       <xsl:choose>
       <xsl:when test="(@name='data' and ../field[@name='time']) or (@name='time' and ../field[@name='data']) or @name='data_error_upper' or @name='data_error_lower'">
       timepath=<xsl:value-of select="$mds_path"/>//&quot;/time&quot;
       call begin_IDS_put_timed(idx, path,size(IDS%<xsl:value-of select="concat($variable_path,'%time')"/>),&amp;
       IDS%<xsl:value-of select="concat($variable_path,'%time')"/>)
       </xsl:when>
       <xsl:otherwise>
       timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
       </xsl:otherwise>
       </xsl:choose>
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time),&amp;
       IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect6d_double(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>, &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,2),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,3),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,4),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,5),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,6),&amp;
   <xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   <xsl:choose>
   <xsl:when test="@type='dynamic'">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       timepath="<xsl:call-template name="printtimepath"/>"
       call begin_IDS_put_timed(idx, path,size(<xsl:call-template name="printtimevariable"/>),&amp;
       <xsl:call-template name="printtimevariable"/>)
   else
       timepath="time"
       call begin_IDS_put_timed(idx, path,size(IDS%time) &amp;
       IDS%time)
   endif
   </xsl:when>
   <xsl:otherwise>
   timepath = ''
   </xsl:otherwise>
   </xsl:choose>
   call put_vect6d_double(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,3),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,5),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,6),&amp;
   <xsl:call-template name="printIsTimed"/>, status)
   <xsl:if test="@type='dynamic'">
   call end_IDS_put_timed(idx, path)
   </xsl:if>
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>

			<xsl:otherwise>
 ! Put <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
			</xsl:otherwise>
		</xsl:choose>
   </xsl:if>
</xsl:template>



<!--!!!!!!!!!!!!!!!!!!!!!!!!!        PUT_SLICE for FIELDS       !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="PUT_SLICE">
<xsl:param name="variable_path"/>
<xsl:param name="mds_path"/>
<xsl:if test="@type ='dynamic' or @data_type='structure' or @data_type='struct_array'"> <!-- This skips the routine for non timed fields -->
		<xsl:choose>
			<xsl:when test="@data_type='structure'">
<xsl:choose>
<xsl:when test="$variable_path">
<xsl:apply-templates select="field" mode="PUT_SLICE">
<xsl:with-param name ="variable_path" select="concat($variable_path,'%',@name)"/>
<xsl:with-param name ="mds_path" select="concat($mds_path,'//&quot;/',@name,'&quot;')"/>
</xsl:apply-templates>
</xsl:when>
<xsl:otherwise>
<xsl:apply-templates select="field" mode="PUT_SLICE">
<xsl:with-param name ="variable_path" select="@name"/>
<xsl:with-param name ="mds_path" select="concat('&quot;',@name,'&quot;')"/>
</xsl:apply-templates>
</xsl:otherwise>
</xsl:choose>

			</xsl:when>
         <xsl:when test="@data_type='struct_array' and @maxoccur!='unbounded'">
<!-- Type 1 arrays of structure, with potentially multiple time bases -->
! Put_slice <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>)) then
   call put_int(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>/Shape_of&quot;,&amp;
       size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>), status)
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
   do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,size(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>)
      <xsl:apply-templates select = "field" mode = "PUT_SLICE">
<xsl:with-param name ="variable_path" select="concat($variable_path,'%',@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat($mds_path,'//','&quot;/',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
</xsl:apply-templates>
   enddo
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
   call put_int(idx,path, &quot;<xsl:value-of select="@name"/>/Shape_of&quot;,&amp;
       size(IDS%<xsl:value-of select="@name"/>), status)
     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put'"/>
   </xsl:call-template>
   do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,size(IDS%<xsl:value-of select = "@name"/>)
      <xsl:apply-templates select = "field" mode = "PUT_SLICE">
<xsl:with-param name ="variable_path" select="concat(@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat('&quot;',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
</xsl:apply-templates>
   enddo
endif
</xsl:otherwise>
</xsl:choose>
</xsl:when>
          <xsl:when test="@data_type='struct_array' and @maxoccur='unbounded' and @type='dynamic'">
<!-- Type 3 arrays of structure, with a unique time base -->
<xsl:choose>
<xsl:when test="$variable_path">
! Structure array of type 3 nested below a Type 1 : <xsl:value-of select = "concat($variable_path,'%',@name)"/>
if (associated(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>)) then
   call begin_object(idx,-1,1,path//<xsl:value-of select = "concat('&quot;','/',substring($mds_path,2),'//&quot;/',@name,'&quot;')"/>,TIMED,obj_single_time);
   call begin_object(idx,obj_single_time,1,"ALLTIMES",TIMED,obj1)

      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="objpath" select="@name"/>
         <xsl:with-param name="idxpath" select="concat('IDS%',$variable_path,'%',@name,'(1)')"/>
         <xsl:with-param name="child_index" select="1"/>
      </xsl:apply-templates>

   call put_object_in_object(idx,obj_single_time,"ALLTIMES",1,obj1);
   call put_object_slice(idx,path,<xsl:value-of select = "concat($mds_path,'//&quot;/',@name)"/>",IDS%time,obj_single_time, status);
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>

   ! Store time of the array of structure (hidden variable for the user, but used by the UAL for future get_slice operations)
   allocate(time(1))
   if (IDS%IDS_Properties%homogeneous_time.EQ.1) then
           time(1) = ids%time(1) ! Use the general time vector of the IDS to fill time
   else
         if (IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>(1)%time.EQ.ids_real_invalid) then ! Check the presence of a time vector at the root of the AoS (on the first index only)
                 write(*,*) "ERROR : the time vector of the type 3 array of structure <xsl:value-of select = "concat($variable_path,'%',@name)"/> must be filled"
                 return
         else
                 time(1) = IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>(1)%time
         endif
   endif


   timepath=<xsl:value-of select="concat($mds_path,'//&quot;/',@name,'/time')"/>" ! Start to put time
   call put_double_slice(idx,path, trim(timepath),&amp;
      trim(timepath),&amp;
      time,&amp;
      time, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>%time', time
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
! Structure array of type 3 : <xsl:value-of select = "@path"/>
! timed arrays of structures must be put inside a time container, even if there is a single time */
if (associated(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
   call begin_object(idx,-1,1,path//"/<xsl:value-of select = "@path"/>",TIMED,obj_single_time);
   call begin_object(idx,obj_single_time,1,"ALLTIMES",TIMED,obj1)

      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="objpath" select="@name"/>
         <xsl:with-param name="idxpath" select="concat('IDS%',translate(@path,'/','%'),'(1)')"/>
         <xsl:with-param name="child_index" select="1"/>
      </xsl:apply-templates>

   call put_object_in_object(idx,obj_single_time,"ALLTIMES",1,obj1);
   call put_object_slice(idx,path,"<xsl:value-of select="@path"/>",IDS%time,obj_single_time, status);
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>

   ! Store time of the array of structure (hidden variable for the user, but used by the UAL for future get_slice operations)
   allocate(time(1))
   if (IDS%IDS_Properties%homogeneous_time.EQ.1) then
           time(1) = ids%time(1) ! Use the general time vector of the IDS to fill time
   else
         if (IDS%<xsl:value-of select = "translate(@path,'/','%')"/>(1)%time.EQ.ids_real_invalid) then ! Check the presence of a time vector at the root of the AoS (on the first index only)
                 write(*,*) "ERROR : the time vector of the type 3 array of structure <xsl:value-of select = "translate(@path,'/','%')"/> must be filled"
                 return
         else
                 time(1) = IDS%<xsl:value-of select = "translate(@path,'/','%')"/>(1)%time
         endif
   endif


   timepath=&quot;<xsl:call-template name="printtimepath"/>&quot;
   call put_double_slice(idx,path,trim(timepath),&amp;
      trim(timepath),&amp;
      time,&amp;
      time, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>%time',time
    <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>

endif
</xsl:otherwise>
</xsl:choose>
         </xsl:when>
			<xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   call put_string_slice(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
          trim(timepath),IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(1),IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'

    <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
<!-- -->
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="@name"/>)) then
   call put_String_slice(idx,path, "<xsl:value-of select="@name"/>", &amp;
          trim(timepath),IDS%<xsl:value-of select="@name"/>,(1),IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="@name"/>'
         <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
<!-- -->
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>


			<xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   call put_double_slice(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(1),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_double_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>(1),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   call put_int_slice(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath), &amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(1),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>

endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_int_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>(1),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>

<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='FLT_2D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   call put_vect1d_double_slice(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(:,1), &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>

     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect1d_double_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>(:,1), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>

endif
</xsl:otherwise>
</xsl:choose>

<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='INT_2D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   call put_vect1d_int_slice(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(:,1), &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect1d_int_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>(:,1), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>

<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='FLT_3D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   call put_vect2d_double_slice(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(:,:,1), &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,2),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect2d_double_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>(:,:,1), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='INT_3D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   call put_vect2d_int_slice(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(:,:,1), &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,2),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect2d_int_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>(:,:,1), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
                        </xsl:when>
			<xsl:when test="@data_type='FLT_4D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   call put_vect3d_double_slice(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(:,:,:,1), &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,2),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,3),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect3d_double_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>(:,:,:,1), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,3),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
         <xsl:when test="@data_type='FLT_5D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   call put_vect4d_double_slice(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(:,:,:,:,1), &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,2),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,3),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,4),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect4d_double_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>(:,:,:,:,1), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,3),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>

   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
         <xsl:when test="@data_type='FLT_6D'">
! Put <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
if (associated(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>)) then
   call put_vect5d_double_slice(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(:,:,:,:,:,1), &amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,1),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,2),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,3),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,4),&amp;
   size(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,5),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
   <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:when>
<xsl:otherwise>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect5d_double_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   trim(timepath),&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>(:,:,:,:,:,1), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,3),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,5),&amp;
   IDS%time(1), status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>


     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>

			<xsl:otherwise>
 ! Put <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
			</xsl:otherwise>
		</xsl:choose>
   </xsl:if>
</xsl:template>


<!--!!!!!!!!!!!!!!!!!!!!!!!!!        GET_SINGLE for FIELDS       !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="GET_SINGLE">
<xsl:param name="variable_path"/>
<xsl:param name="mds_path"/>
		<xsl:choose>
			<xsl:when test="@data_type='structure'">
<xsl:choose>
<xsl:when test="$variable_path">
<xsl:apply-templates select="field" mode="GET_SINGLE">
<xsl:with-param name ="variable_path" select="concat($variable_path,'%',@name)"/>
<xsl:with-param name ="mds_path" select="concat($mds_path,'//&quot;/',@name,'&quot;')"/>
</xsl:apply-templates>
</xsl:when>
<xsl:otherwise>
<xsl:apply-templates select="field" mode="GET_SINGLE">
<xsl:with-param name ="variable_path" select="@name"/>
<xsl:with-param name ="mds_path" select="concat('&quot;',@name,'&quot;')"/>
</xsl:apply-templates>
</xsl:otherwise>
</xsl:choose>

			</xsl:when>
         <xsl:when test="@data_type='struct_array' and @maxoccur!='unbounded'">
<!-- Type 1 arrays of structure, with potentially multiple time bases -->
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
call get_int(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>/Shape_of&quot;,int0d,status)
if (status.EQ.0) then
   allocate(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>(int0d))
   do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,size(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>)
      <xsl:apply-templates select = "field" mode = "GET_SINGLE">
<xsl:with-param name ="variable_path" select="concat($variable_path,'%',@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat($mds_path,'//','&quot;/',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
</xsl:apply-templates>
   enddo
endif
</xsl:when>
<xsl:otherwise>
call get_int(idx,path, &quot;<xsl:value-of select="@name"/>/Shape_of&quot;,int0d,status)
if (status.EQ.0) then
   allocate(IDS%<xsl:value-of select = "@name"/>(int0d))
   do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,size(IDS%<xsl:value-of select = "@name"/>)
      <xsl:apply-templates select = "field" mode = "GET_SINGLE">
<xsl:with-param name ="variable_path" select="concat(@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat('&quot;',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
</xsl:apply-templates>
   enddo
endif
</xsl:otherwise>
</xsl:choose>
</xsl:when>
<xsl:when test="@data_type='struct_array' and @maxoccur='unbounded' and @type='dynamic'">
<!-- Type 3 arrays of structure, with a unique time base -->
<xsl:choose>
<xsl:when test="$variable_path">
! Structure array of type 3 nested below a Type 1 : <xsl:value-of select = "concat($variable_path,'%',@name)"/>
call get_object(idx,path,<xsl:value-of select = "concat($mds_path,'//&quot;/',@name,'&quot;')"/>,obj_all_times,TIMED,status) ! read the whole timed block
if (status.EQ.0) then
   call get_object_dim(idx,obj_all_times,lentime)  ! the size of this top object is the number of time slices
   if (lentime > 0) then
      allocate(ids%<xsl:value-of select = "concat($variable_path,'%',@name)"/>(lentime))
      if (ual_debug =='yes') write(*,*) &amp;
      'Get ids%<xsl:value-of select = "concat($variable_path,'%',@name)"/>, lentime =', lentime
      do i1 = 1,lentime     ! fill every time slice
         call get_object_from_object(idx,obj_all_times,"ALLTIMES",i1,obj1,status)
         if (status.EQ.0) then
            !call get_object_dim(idx,obj1,dimObj1)
               <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
                  <xsl:with-param name="level" select="1"/>
                  <xsl:with-param name="objpath" select="@name"/>
                  <xsl:with-param name="idxpath" select="concat('IDS%',$variable_path,'%',@name,'(i1)')"/>
                  <xsl:with-param name="timed" select="'yes'"/>
               </xsl:apply-templates>
         endif
      enddo
   endif
   call release_object(idx,obj_all_times)
endif
</xsl:when>
<xsl:otherwise>
! Structure array of type 3 : <xsl:value-of select = "@path"/>
call get_object(idx,path,"<xsl:value-of select = "@path"/>",obj_all_times,TIMED,status) ! read the whole timed block
if (status.EQ.0) then
   call get_object_dim(idx,obj_all_times,lentime)  ! the size of this top object is the number of time slices
   if (lentime > 0) then
      allocate(ids%<xsl:value-of select = "translate(@path,'/','%')"/>(lentime))
      if (ual_debug =='yes') write(*,*) &amp;
      'Get ids%<xsl:value-of select="translate(@path,'/','%')"/>, lentime =', lentime
      do i1 = 1,lentime     ! fill every time slice
         call get_object_from_object(idx,obj_all_times,"ALLTIMES",i1,obj1,status)
         if (status.EQ.0) then
         !call get_object_dim(idx,obj1,dimObj1)
               <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
                  <xsl:with-param name="level" select="1"/>
                  <xsl:with-param name="objpath" select="@name"/>
                  <xsl:with-param name="idxpath" select="concat('ids%',translate(@path,'/','%'),'(i1)')"/>
                  <xsl:with-param name="timed" select="'yes'"/>
               </xsl:apply-templates>
         endif
      enddo
   endif
   call release_object(idx,obj_all_times)
endif
</xsl:otherwise>
</xsl:choose>


</xsl:when>


<!-- old comment from ITM MDS object tobe implemented for AoS type 2
! Read non-timed content
call get_object(idx,path,"<xsl:value-of select = "@path"/>",obj1,0,status); ! read the whole non-timed block
if (status.EQ.0) then
   call get_object_dim(idx,obj1,dimObj1)
   if (dimObj1.NE.0) then
      do itime = 1,lentime     ! fill every time slice
         ! does not exist yet (there was no timed content)
         if (.NOT.associated(cpos(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
            allocate(cpos(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>(dimObj1))
         endif
         ! must have same number of non-timed elements and timed elements
         if (size(cpos(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>).NE.dimObj1) then
            write(*,*) "Error in get: array of structures has different number of timed and nontimed elements for <xsl:value-of select = "@path"/>"
         else
            do i1 = 1,dimObj1     ! process array elements
               <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
                  <xsl:with-param name="level" select="1"/>
                  <xsl:with-param name="objpath" select="@name"/>
                  <xsl:with-param name="idxpath" select="concat('cpos(itime)%',translate(@path,'/','%'),'(i1)')"/>
                  <xsl:with-param name="timed" select="'no'"/>
               </xsl:apply-templates>
            enddo
         endif
      enddo
   endif
   call release_object(idx,obj1)
endif
 -->
			<xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
longstring = ' '    <!-- Initialisation of longstring, otherwise strange problems occur !-->
call get_string(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,longstring, status)
if (status.EQ.0) then
   lenstring = len_trim(longstring)
   allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(floor(real(lenstring/ids_string_length))+1))
   if (lenstring &lt;= ids_string_length) then
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> = trim(longstring)
   else
      do istring=1,floor(real(lenstring/ids_string_length))+1
          IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(istring) = trim(longstring(1+(istring-1)*ids_string_length : istring*ids_string_length))
      enddo
   endif
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>',&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>
endif
<!-- -->
</xsl:when>
<xsl:otherwise>
longstring = ' '    <!-- Initialisation of longstring, otherwise strange problems occur !-->
call get_string(idx,path, "<xsl:value-of select="@name"/>",longstring, status)
if (status.EQ.0) then
   lenstring = len_trim(longstring)
   allocate(IDS%<xsl:value-of select="@name"/>(floor(real(lenstring/ids_string_length))+1))
   if (lenstring &lt;= ids_string_length) then
      IDS%<xsl:value-of select="@name"/> = trim(longstring)
   else
      do istring=1,floor(real(lenstring/ids_string_length))+1
          IDS%<xsl:value-of select="@name"/>(istring) = trim(longstring(1+(istring-1)*ids_string_length : istring*ids_string_length))
      enddo
   endif
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="@name"/>',&amp;
      IDS%<xsl:value-of select="@name"/>
endif
<!-- -->
</xsl:otherwise>
</xsl:choose>
			</xsl:when>
			<xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
      ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1))
      call get_Vect1d_string(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
          IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,dim1,dum1,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
<!-- -->
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@name"/>",&amp;
      ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="@name"/>(dim1))
      call get_Vect1d_string(idx,path, "<xsl:value-of select="@name"/>", &amp;
          IDS%<xsl:value-of select="@name"/>,dim1,dum1,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="@name"/>'
   endif
<!-- -->
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
call get_int(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,int0d,status)
if (status.EQ.0) then
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> = int0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
endif
</xsl:when>
<xsl:otherwise>
call get_int(idx,path, "<xsl:value-of select="@path"/>",int0d,status)
if (status.EQ.0) then
   IDS%<xsl:value-of select="translate(@path,'/','%')"/> = int0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
call get_double(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,double0d,status)
if (status.EQ.0) then
   IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> = double0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
endif
</xsl:when>
<xsl:otherwise>
call get_double(idx,path, "<xsl:value-of select="@path"/>",double0d,status)
if (status.EQ.0) then
   IDS%<xsl:value-of select="translate(@path,'/','%')"/> = double0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
</xsl:otherwise>
</xsl:choose>
<!-- -->


			</xsl:when>
			<xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
      ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1))
      call get_vect1d_double(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dum1,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
      ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
      call get_vect1d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dum1,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
      ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1))
      call get_vect1d_int(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dum1,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
      ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
      call get_vect1d_int(idx,path,"<xsl:value-of select="@path"/>", &amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dum1,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->

			</xsl:when>
			<xsl:when test="@data_type='FLT_2D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
      ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,dim2))
      call get_vect2d_double(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dim2, dum1,dum2, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
      ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
      call get_vect2d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dim2, dum1, dum2, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
</xsl:when>
			<xsl:when test="@data_type='INT_2D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
      ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,dim2))
      call get_vect2d_int(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dim2, dum1, dum2, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
      ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
      call get_vect2d_int(idx,path,"<xsl:value-of select="@path"/>", &amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dim2,dum1, dum2, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='FLT_3D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,&amp;
      ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,dim2,dim3))
      call get_vect3d_double(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dim2, dim3, dum1,dum2, dum3, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",&amp;
      ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
      call get_vect3d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dim2, dim3, dum1, dum2, dum3, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
		</xsl:when>
			<xsl:when test="@data_type='INT_3D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,dim2,dim3))
      call get_vect3d_int(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dim2, dim3, dum1, dum2, dum3, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
      call get_vect3d_int(idx,path,"<xsl:value-of select="@path"/>", &amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dim2, dim3, dum1, dum2, dum3, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->				</xsl:when>
			<xsl:when test="@data_type='FLT_4D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,dim2,dim3, dim4))
      call get_vect4d_double(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dim2, dim3, dim4, dum1, dum2, dum3, dum4, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3, dim4))
      call get_vect4d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dim2, dim3, dim4, dum1, dum2, dum3, dum4, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
         <xsl:when test="@data_type='FLT_5D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,dim2,dim3,dim4,dim5))
      call get_vect5d_double(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dim2, dim3, dim4, dim5, dum1, dum2, dum3, dum4, dum5, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5))
      call get_vect5d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dim2, dim3, dim4, dim5, dum1, dum2, dum3, dum4, dum5, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
         <xsl:when test="@data_type='FLT_6D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,dim2,dim3,dim4,dim5,dim6))
      call get_vect6d_double(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dim2, dim3, dim4, dim5, dim6, dum1, dum2, dum3, dum4, dum5, dum6, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5,dim6))
      call get_vect6d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dim2, dim3, dim4, dim5, dim6, dum1, dum2, dum3, dum4, dum5, dum6, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>

			<xsl:otherwise>
 ! Get <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
			</xsl:otherwise>
		</xsl:choose>
   <!--</xsl:if>-->
</xsl:template>






<!--!!!!!!!!!!!!!!!!!!!!!!!!!        GET_SLICE for FIELDS       !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="GET_SLICE">
<xsl:param name="variable_path"/>
<xsl:param name="mds_path"/>
		<xsl:choose>
			<xsl:when test="@data_type='structure'">
<xsl:choose>
<xsl:when test="$variable_path">
<xsl:apply-templates select="field" mode="GET_SLICE">
<xsl:with-param name ="variable_path" select="concat($variable_path,'%',@name)"/>
<xsl:with-param name ="mds_path" select="concat($mds_path,'//&quot;/',@name,'&quot;')"/>
</xsl:apply-templates>
</xsl:when>
<xsl:otherwise>
<xsl:apply-templates select="field" mode="GET_SLICE">
<xsl:with-param name ="variable_path" select="@name"/>
<xsl:with-param name ="mds_path" select="concat('&quot;',@name,'&quot;')"/>
</xsl:apply-templates>
</xsl:otherwise>
</xsl:choose>

			</xsl:when>
         <xsl:when test="@data_type='struct_array' and @maxoccur!='unbounded'">
<!-- Type 1 arrays of structure, with potentially multiple time bases -->! Get_slice <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
call get_int(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>/Shape_of&quot;,int0d,status)
if (status.EQ.0) then
   allocate(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>(int0d))
   do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,size(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>)
      <xsl:apply-templates select = "field" mode = "GET_SLICE">
<xsl:with-param name ="variable_path" select="concat($variable_path,'%',@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat($mds_path,'//','&quot;/',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
</xsl:apply-templates>
   enddo
endif
</xsl:when>
<xsl:otherwise>
call get_int(idx,path, &quot;<xsl:value-of select="@name"/>/Shape_of&quot;,int0d,status)
if (status.EQ.0) then
   allocate(IDS%<xsl:value-of select = "@name"/>(int0d))
   do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,size(IDS%<xsl:value-of select = "@name"/>)
      <xsl:apply-templates select = "field" mode = "GET_SLICE">
<xsl:with-param name ="variable_path" select="concat(@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat('&quot;',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
</xsl:apply-templates>
   enddo
endif
</xsl:otherwise>
</xsl:choose>

         </xsl:when>

<xsl:when test="@data_type='struct_array' and @maxoccur='unbounded' and @type='dynamic'">
<!-- Type 3 arrays of structure, with a unique time base -->
<xsl:choose>
<xsl:when test="$variable_path">
! Structure array of type 3 nested below a Type 1 : <xsl:value-of select = "concat($variable_path,'%',@name)"/>
call get_object_slice(idx,path,<xsl:value-of select = "concat($mds_path,'//&quot;/',@name,'&quot;')"/>,twant,obj_single_time,status) ! read the timed block containing a single slice
if (status.EQ.0) then
   call get_object_from_object(idx,obj_single_time,"ALLTIMES",1,obj1,status)   ! Even if obj_single_time contains a single slice, the slice has to be extracted like this as obj1
   if (status.EQ.0) then
      call get_object_dim(idx,obj1,dimObj1)
      if (dimObj1.GT.0) then
         allocate(ids%<xsl:value-of select = "concat($variable_path,'%',@name)"/>(1))
         if (ual_debug =='yes') write(*,*) &amp;
            'Get_slice ids%<xsl:value-of select = "concat($variable_path,'%',@name)"/>'
               <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
                  <xsl:with-param name="level" select="1"/>
                  <xsl:with-param name="objpath" select="@name"/>
                  <xsl:with-param name="idxpath" select="concat('IDS%',$variable_path,'%',@name,'(1)')"/>
                  <xsl:with-param name="timed" select="'yes'"/>
               </xsl:apply-templates>
      else
         if (associated(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>)) then
            deallocate(IDS%<xsl:value-of select = "concat($variable_path,'%',@name)"/>);
         endif
      endif
   endif
   call release_object(idx,obj_single_time)
endif
</xsl:when>
<xsl:otherwise>
! Structure array of type 3 : <xsl:value-of select = "@path"/>
call get_object_slice(idx,path,"<xsl:value-of select = "@path"/>",twant,obj_single_time,status) ! read the timed block containing a single slice
if (status.EQ.0) then
   call get_object_from_object(idx,obj_single_time,"ALLTIMES",1,obj1,status)   ! Even if obj_single_time contains a single slice, the slice has to be extracted like this as obj1
   if (status.EQ.0) then
      call get_object_dim(idx,obj1,dimObj1)
      if (dimObj1.GT.0) then
         allocate(ids%<xsl:value-of select = "translate(@path,'/','%')"/>(1))
         if (ual_debug =='yes') write(*,*) &amp;
            'Get_slice ids%<xsl:value-of select="translate(@path,'/','%')"/>'
               <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
                  <xsl:with-param name="level" select="1"/>
                  <xsl:with-param name="objpath" select="@name"/>
                  <xsl:with-param name="idxpath" select="concat('ids%',translate(@path,'/','%'),'(1)')"/>
                  <xsl:with-param name="timed" select="'yes'"/>
               </xsl:apply-templates>
      else
         if (associated(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
            deallocate(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>);
         endif
      endif
   endif
   call release_object(idx,obj_single_time)
endif
</xsl:otherwise>
</xsl:choose>
</xsl:when>


   <xsl:when test="@type='dynamic'">
<!-- Get slice is specific only for dynamicS -->
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
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
       timepath="time"
   endif
</xsl:when>
<xsl:otherwise>
   if (IDS%IDS_Properties%Homogeneous_time.EQ.0) then
       timepath="<xsl:call-template name="printtimepath"/>"
   else
       timepath="time"
   endif
</xsl:otherwise>
</xsl:choose>

<xsl:choose>
			<xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(1))
      call get_string_slice(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
          trim(timepath),&amp;
          IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>,twant,tret,interpol,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
<!-- -->
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@name"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="@name"/>(1))
      call get_string_slice(idx,path, "<xsl:value-of select="@name"/>", &amp;
          trim(timepath),&amp;
          IDS%<xsl:value-of select="@name"/>,twant,tret,interpol,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="@name"/>'
   endif
<!-- -->
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>

			<xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(1))
      call get_double_slice(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,twant,tret,interpol,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(1))
      call get_double_slice(idx,path,"<xsl:value-of select="@path"/>", &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,twant,tret,interpol,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(1))
      call get_int_slice(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,twant,tret,interpol,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(1))
      call get_int_slice(idx,path,"<xsl:value-of select="@path"/>", &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,twant,tret,interpol,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->

			</xsl:when>
			<xsl:when test="@data_type='FLT_2D'">
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,1))
      call get_vect1d_double_slice(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1, dum1,twant,tret,interpol,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,1))
      call get_vect1d_double_slice(idx,path,"<xsl:value-of select="@path"/>", &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1, dum1, twant,tret,interpol,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
</xsl:when>
			<xsl:when test="@data_type='INT_2D'">
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,1))
      call get_vect1d_int_slice(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dum1,twant,tret,interpol,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,1))
      call get_vect1d_int_slice(idx,path,"<xsl:value-of select="@path"/>", &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dum1, twant,tret,interpol,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
			<xsl:when test="@data_type='FLT_3D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,dim2,1))
      call get_vect2d_double_slice(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dim2, dum1,dum2, twant,tret,interpol,status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,1))
      call get_vect2d_double_slice(idx,path,"<xsl:value-of select="@path"/>", &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dim2, dum1, dum2, twant,tret,interpol, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
		</xsl:when>
			<xsl:when test="@data_type='INT_3D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,dim2,1))
      call get_vect2d_int_slice(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dim2, dum1, dum2, twant,tret,interpol, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,1))
      call get_vect2d_int_slice(idx,path,"<xsl:value-of select="@path"/>", &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dim2, dum1, dum2, twant,tret,interpol,  status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->				</xsl:when>
			<xsl:when test="@data_type='FLT_4D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,dim2,dim3, 1))
      call get_vect3d_double_slice(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dim2, dim3, dum1, dum2, dum3, twant,tret,interpol, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3, 1))
      call get_vect3d_double_slice(idx,path,"<xsl:value-of select="@path"/>", &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dim2, dim3, dum1, dum2, dum3, twant,tret,interpol, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
         <xsl:when test="@data_type='FLT_5D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,dim2,dim3,dim4,1))
      call get_vect4d_double_slice(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dim2, dim3, dim4, dum1, dum2, dum3, dum4, twant,tret,interpol,  status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,1))
      call get_vect4d_double_slice(idx,path,"<xsl:value-of select="@path"/>", &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dim2, dim3, dim4, dum1, dum2, dum3, dum4, twant,tret,interpol, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>
         <xsl:when test="@data_type='FLT_6D'">
! Get <xsl:value-of select="@path"/>
<xsl:choose>
<xsl:when test="$variable_path">
   call get_dimension(idx,path, <xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>(dim1,dim2,dim3,dim4,dim5,dim6))
      call get_vect5d_double_slice(idx,path,<xsl:value-of select="$mds_path"/>//&quot;/<xsl:value-of select="@name"/>&quot;, &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/> &amp;
      ,dim1,dim2, dim3, dim4, dim5, dum1, dum2, dum3, dum4, dum5, twant,tret,interpol,  status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="concat($variable_path,'%',@name)"/>'
   endif
</xsl:when>
<xsl:otherwise>
   call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
   if (dim1.GT.0) then
      allocate(IDS%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5,1))
      call get_vect5d_double_slice(idx,path,"<xsl:value-of select="@path"/>", &amp;
      trim(timepath),&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/> &amp;
      ,dim1,dim2, dim3, dim4, dim5, dum1, dum2, dum3, dum4, dum5, twant,tret,interpol, status)
      if (ual_debug =='yes') write(*,*) &amp;
      'Get IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
   endif
</xsl:otherwise>
</xsl:choose>
<!-- -->
			</xsl:when>

			<xsl:otherwise>
 ! Get <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
			</xsl:otherwise>
		</xsl:choose>

</xsl:when>
<xsl:otherwise>
   <!-- Get the data from a time-independent field is the same procedure as GET_SINGLE -->
   <xsl:apply-templates select="." mode="GET_SINGLE">
   <xsl:with-param name="variable_path" select="$variable_path"/>
   <xsl:with-param name="mds_path" select="$mds_path"/>
   </xsl:apply-templates>
</xsl:otherwise>
</xsl:choose>

</xsl:template>














	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             PUT_SLICE IDS ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
	<!--<xsl:template match="IDS" mode="PUT_SLICE_OLD">

</xsl:template>-->
	<xsl:template match="field" mode="PUT_SLICE_OLD">
		<!-- to put (append) one time slice of a time-dependent element from a time-dependent IDS (very similar to PUT_SINGLE, but deals only with time-dependent elements, and isTimed = 1 in the individual type put -->
		<xsl:choose>
			<xsl:when test="@name='structure'">
				<xsl:apply-templates select="field" mode="PUT_SLICE"/>
			</xsl:when>
         <xsl:when test="@name='struct_array' and @timed='yes'">
! Put <xsl:value-of select="@path"/>
                  <!-- for comment only -->
! timed arrays of structures must be put inside a time container, even if there is a single time */
call begin_object(idx,-1,1,path//"/<xsl:value-of select = "@path"/>",TIMED,obj_single_time);
call begin_object(idx,obj_single_time,1,"ALLTIMES",TIMED,obj1)
if (associated(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
   do i1 = 1,size(IDS%<xsl:value-of select = "translate(@path,'/','%')"/>)
      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="objpath" select="@name"/>
         <xsl:with-param name="idxpath" select="concat('IDS%',translate(@path,'/','%'),'(i1)')"/>
         <xsl:with-param name="timed" select="'yes'"/>
      </xsl:apply-templates>
   enddo
endif
call put_object_in_object(idx,obj_single_time,"ALLTIMES",1,obj1);
call put_object_slice(idx,path,"<xsl:value-of select="@path"/>",IDS%time,obj_single_time, status);
     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>

         </xsl:when>
			<xsl:when test="@name='xs:string' and @timed='yes'">
! Put <xsl:value-of select="@path"/>  ERROR : NO TIME DEPENDENT STRING EXPECTED IN THE data STRUCTURE
<!-- -->
			</xsl:when>
			<xsl:when test="@name='vecstring_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>  ERROR : NO TIME DEPENDENT VECSTRING EXPECTED IN THE data STRUCTURE
<!-- -->
			</xsl:when>
			<xsl:when test="@name='xs:integer'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (IDS%<xsl:value-of select="translate(@path,'/','%')"/>.NE.ids_int_invalid) then
   call put_int_slice(idx,path, "<xsl:value-of select="@path"/>",IDS%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   IDS%time, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>

     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@name='xs:float'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (IDS%<xsl:value-of select="translate(@path,'/','%')"/>.NE.ids_real_invalid) then
   call put_double_slice(idx,path, "<xsl:value-of select="@path"/>",IDS%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   IDS%time, status)
   if (ual_debug =='yes') write(*,*) &amp;
       'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
       IDS%<xsl:value-of select="translate(@path,'/','%')"/>
     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@name='vecflt_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect1d_double_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>),IDS%time, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>
     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@name='vecint_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect1d_int_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>),IDS%time, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>
           <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>endif
<!-- -->
			</xsl:when>
			<xsl:when test="@name='matflt_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect2d_double_slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),IDS%time, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>
         <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@name='matint_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect2d_int_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),IDS%time, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>
     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@name='array3dflt_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect3d_double_slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,3),IDS%time, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>'
     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@name='array3dint_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect3d_int_slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,3),IDS%time, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
      IDS%<xsl:value-of select="translate(@path,'/','%')"/>

     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@name='array4dflt_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect4d_double_slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,3), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,4),IDS%time, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>'

     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
<!-- -->
			</xsl:when>
						<xsl:when test="@name='array5dflt_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect5d_double_slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,3), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,4), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,5),IDS%time, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>'

     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
<!-- -->
			</xsl:when>
									<xsl:when test="@name='array6dflt_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
if (associated(IDS%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect6d_double_slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   IDS%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,3), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,4), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,5), &amp;
   size(IDS%<xsl:value-of select="translate(@path,'/','%')"/>,6),IDS%time, status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put IDS%<xsl:value-of select="translate(@path,'/','%')"/>'

     <xsl:call-template name="checkError">
        <xsl:with-param name="method" select="'put_slice'"/>
   </xsl:call-template>
endif
<!-- -->
			</xsl:when>

		</xsl:choose>
	</xsl:template>

	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             PUT NON TIMED IDS ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
	<!--<xsl:template match="IDS" mode="PUT_NON_TIMED">

</xsl:template>-->

<!--!!!!!!!!!!!!!!!!!!!!!!!!!        PUT IN OBJECT       !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="PUT_IN_OBJECT">
  <xsl:param name="level"/>     <!-- recursion level -->
  <xsl:param name="objpath"/>   <!-- path inside the object -->
  <xsl:param name="idxpath"/>   <!-- full C++ path including indices -->
  <xsl:param name="child_index"/>     <!-- Index to use to add a child in the current object -->

  <!-- build the path of the current field inside the object -->
  <xsl:param name="currentobjpath" select="concat($objpath,'/',@name)"/>
  <!-- build the complete path of the current field -->
  <xsl:param name="currentidxpath" select="concat($idxpath,'%',@name)"/>


  <xsl:choose>
    <!--========== Arrays of structures ==========-->
    <xsl:when test="@data_type='struct_array'">
! Put <xsl:value-of select="@path"/>
<!-- Present implementation assumes that nested AoS are necessarily of level 2, this may need to be upgraded for other cases later (?) -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
call begin_object(idx,obj<xsl:value-of select="$level"/>,1,"<xsl:value-of select="$currentobjpath"/>",NON_TIMED,obj<xsl:value-of select="$level + 1"/>)
! Start to declare a nested Type 2 Aos
   do i<xsl:value-of select="$level + 1"/> = 1,size(<xsl:value-of select="$currentidxpath"/>)
         <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
            <xsl:with-param name="level" select="$level + 1"/>
            <xsl:with-param name="objpath" select="@name"/>
            <xsl:with-param name="idxpath" select="concat($currentidxpath,'(i',$level + 1,')')"/>
            <xsl:with-param name="child_index" select="concat('i',$level+1)"/>
         </xsl:apply-templates>
   enddo
call put_object_in_object(idx,obj<xsl:value-of select="$level"/>, "<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>, obj<xsl:value-of select="$level + 1"/>)
endif
    </xsl:when>

    <!--========== Regular structure ==========-->
    <xsl:when test="@data_type='structure'">
     <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
        <xsl:with-param name="level" select="$level"/>
        <xsl:with-param name="objpath" select="$currentobjpath"/>
        <xsl:with-param name="idxpath" select="$currentidxpath"/>
        <xsl:with-param name="child_index" select="$child_index"/>
      </xsl:apply-templates>
    </xsl:when>

    <!--========== select either timed or non-timed fields ==========-->
    <xsl:otherwise>
 <!--     <xsl:if test="(@type='dynamic' and $timed='yes') or (@type!='dynamic' and $timed='no')"> -->
        <xsl:choose>
         <xsl:when test="@data_type='str_type' or @data_type='STR_0D'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   longstring = ' '    <!-- Initialisation of longstring, otherwise strange problems occur !-->
   lenstring = size(<xsl:value-of select="$currentidxpath"/>)
   if (lenstring.EQ.1) then
      longstring = trim(<xsl:value-of select="$currentidxpath"/>(1))
   else
      do istring=1,lenstring
          longstring(1+(istring-1)*ids_string_length : istring*ids_string_length) = <xsl:value-of select="$currentidxpath"/>(istring)
      enddo
   endif
   call put_string_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>,trim(longstring))       ! should clean up longstring after that, or send to the put only the right length, which has been updated
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',&amp;
      <xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='str_1d_type' or @data_type='STR_1D'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   dim1 = size(<xsl:value-of select="$currentidxpath"/>)
   allocate(dimtab(dim1))
   do i=1,dim1
      dimtab(i) = len_trim(<xsl:value-of select="$currentidxpath"/>(i))
   enddo
   call put_vect1d_string_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>, &amp;
         <xsl:value-of select="$currentidxpath"/>,dim1,dimtab)
   deallocate(dimtab)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='int_type' or @data_type='INT_0D'">
! Put <xsl:value-of select="@path"/>
call fput_int_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>,<xsl:value-of select="$currentidxpath"/>,&amp;
   &quot;<xsl:value-of select="$currentidxpath"/>&quot;,ual_debug)
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='flt_type' or @data_type='FLT_0D'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (<xsl:value-of select="$currentidxpath"/>.NE.ids_real_invalid) then
   call put_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>,<xsl:value-of select="$currentidxpath"/>)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>', &amp;
      <xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='flt_1d_type' or @data_type='FLT_1D'">
! Put <xsl:value-of select="@path"/>
call fput_vect1d_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>,&amp;
   <xsl:value-of select="$currentidxpath"/>,&amp;
   &quot;<xsl:value-of select="$currentidxpath"/>&quot;,ual_debug)

<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='int_1d_type' or @data_type='INT_1D'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect1d_int_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>,&amp;
      <xsl:value-of select="$currentidxpath"/>,&amp;
      size(<xsl:value-of select="$currentidxpath"/>))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',&amp;
      <xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
         <xsl:when test=" @data_type='FLT_2D'">
! Put <xsl:value-of select="@path"/>
call fput_vect2d_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>,&amp;
   <xsl:value-of select="$currentidxpath"/>,&amp;
   &quot;<xsl:value-of select="$currentidxpath"/>&quot;,ual_debug)
<!-- -->
         </xsl:when>
         <xsl:when test=" @data_type='INT_2D'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect2d_int_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>,&amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   size(<xsl:value-of select="$currentidxpath"/>,1), &amp;
   size(<xsl:value-of select="$currentidxpath"/>,2))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',&amp;
      <xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='FLT_3D'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect3d_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   size(<xsl:value-of select="$currentidxpath"/>,1),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,2), &amp;
   size(<xsl:value-of select="$currentidxpath"/>,3))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='INT_3D'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect3d_int_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   size(<xsl:value-of select="$currentidxpath"/>,1),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,2),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,3))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',&amp;
      <xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@data_type='FLT_4D'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect4d_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>,<xsl:value-of select="$currentidxpath"/>, &amp;
   size(<xsl:value-of select="$currentidxpath"/>,1),size(<xsl:value-of select="$currentidxpath"/>,2),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,3),size(<xsl:value-of select="$currentidxpath"/>,4))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',&amp;
      <xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
                  <xsl:when test="@data_type='FLT_5D'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect5d_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>,<xsl:value-of select="$currentidxpath"/>, &amp;
   size(<xsl:value-of select="$currentidxpath"/>,1),size(<xsl:value-of select="$currentidxpath"/>,2),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,3),size(<xsl:value-of select="$currentidxpath"/>,4),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,5))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',&amp;
      <xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>


                  <xsl:when test="@data_type='FLT_6D'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect6d_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",<xsl:value-of select="$child_index"/>,<xsl:value-of select="$currentidxpath"/>, &amp;
   size(<xsl:value-of select="$currentidxpath"/>,1),size(<xsl:value-of select="$currentidxpath"/>,2),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,3),size(<xsl:value-of select="$currentidxpath"/>,4),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,5),size(<xsl:value-of select="$currentidxpath"/>,6))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',&amp;
      <xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>

         <xsl:otherwise>
 ! Put <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
         </xsl:otherwise>
      </xsl:choose>
   <!-- </xsl:if> -->
   </xsl:otherwise>
 </xsl:choose>
</xsl:template>

<!--!!!!!!!!!!!!!!!!!!!!!!!!!             DELETE IDS ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="DELETE">
<xsl:param name="variable_path"/>
<xsl:param name="mds_path"/>
<xsl:choose>
<xsl:when test="@data_type='structure'">
   <xsl:choose>
   <xsl:when test="$variable_path">
   <xsl:apply-templates select="field" mode="DELETE">
   <xsl:with-param name ="variable_path" select="concat($variable_path,'%',@name)"/>
   <xsl:with-param name ="mds_path" select="concat($mds_path,'//&quot;/',@name,'&quot;')"/>
   </xsl:apply-templates>
   </xsl:when>
   <xsl:otherwise>
   <xsl:apply-templates select="field" mode="DELETE">
   <xsl:with-param name ="variable_path" select="@name"/>
   <xsl:with-param name ="mds_path" select="concat('&quot;',@name,'&quot;')"/>
   </xsl:apply-templates>
   </xsl:otherwise>
   </xsl:choose>
</xsl:when>
<xsl:when test="@data_type='struct_array' and @maxoccur!='unbounded'">
   <xsl:choose>
   <xsl:when test="$mds_path">
do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,<xsl:value-of select = "@maxoccur"/>
<xsl:apply-templates select = "field" mode = "DELETE">
<xsl:with-param name ="variable_path" select="concat($variable_path,'%',@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat($mds_path,'//','&quot;/',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
</xsl:apply-templates>
enddo
call delete_data(idx,IDSpath,<xsl:value-of select="concat($mds_path,'//&quot;/',@name,'/Shape_of&quot;')"/>)
   </xsl:when>
   <xsl:otherwise>
do i<xsl:value-of select = "concat(@name,generate-id(.))"/> = 1,<xsl:value-of select = "@maxoccur"/>
      <xsl:apply-templates select = "field" mode = "DELETE">
<xsl:with-param name ="variable_path" select="concat(@name,'(i',@name,generate-id(.),')')"/>
<xsl:with-param name="mds_path" select="concat('&quot;/',@name,'/&quot;//trim(int2str(i',@name,generate-id(.),'))')"/>
</xsl:apply-templates>
enddo
call delete_data(idx,IDSpath,<xsl:value-of select="concat('&quot;/',@name,'/Shape_of&quot;')"/>)

   </xsl:otherwise>
   </xsl:choose>
</xsl:when>
<xsl:when test="@data_type='struct_array' and @maxoccur='unbounded'">
   <xsl:choose>
   <xsl:when test="$mds_path">
call delete_data(idx,IDSpath,<xsl:value-of select="concat($mds_path,'//&quot;/',@name,'/timed&quot;')"/>)
call delete_data(idx,IDSpath,<xsl:value-of select="concat($mds_path,'//&quot;/',@name,'/non_timed&quot;')"/>)
call delete_data(idx,IDSpath,<xsl:value-of select="concat($mds_path,'//&quot;/',@name,'/time&quot;')"/>)
   </xsl:when>
   <xsl:otherwise>
call delete_data(idx,IDSpath,<xsl:value-of select="concat('&quot;/',@name,'/timed&quot;')"/>)
call delete_data(idx,IDSpath,<xsl:value-of select="concat('&quot;/',@name,'/non_timed&quot;')"/>)
call delete_data(idx,IDSpath,<xsl:value-of select="concat('&quot;/',@name,'/time&quot;')"/>)
   </xsl:otherwise>
   </xsl:choose>
</xsl:when>




			<xsl:otherwise>
   <xsl:choose>
   <xsl:when test="$mds_path">
call delete_data(idx,IDSpath,<xsl:value-of select="concat($mds_path,'//&quot;/',@name,'&quot;')"/>)         <!-- call to the low level delete_data routine -->
   </xsl:when>
   <xsl:otherwise>
call delete_data(idx,IDSpath,"<xsl:value-of select="@path"/>")         <!-- call to the low level delete_data routine -->
   </xsl:otherwise>
   </xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             DEALLOCATE IDS ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="DEALLOCATE">
    <xsl:param name="level"/>     <!-- recursion level -->
    <xsl:param name="idxpath"/>   <!-- full fortran path including indices -->

    <!-- build the complete path of the current field -->
    <xsl:param name="currentidxpath" select="concat($idxpath,'%',@name)"/>

    <xsl:choose>
<!-- xs:integer and xs:float are not deallocated (they are not allocatable !) -->
			<xsl:when test="@data_type='str_type' or @data_type='STR_0D' or @data_type='str_1d_type' or @data_type='STR_1D' or @data_type='flt_1d_type' or @data_type='FLT_1D' or @data_type='int_1d_type' or @data_type='INT_1D' or @data_type='FLT_2D' or @data_type='INT_2D' or @data_type='FLT_3D' or @data_type='INT_3D' or @data_type='FLT_4D' or @data_type='FLT_5D' or @data_type='FLT_6D' ">
   ! deallocate <xsl:value-of select="@path"/>
   if (associated(<xsl:value-of select="$currentidxpath"/>)) then
        deallocate(<xsl:value-of select="$currentidxpath"/>)
   endif
   			</xsl:when>
			<xsl:when test="@data_type='structure'">
				<xsl:apply-templates select="field" mode="DEALLOCATE">
                <xsl:with-param name="level" select="$level"/>
                <xsl:with-param name="idxpath" select="$currentidxpath"/>
            </xsl:apply-templates>
			</xsl:when>
         <xsl:when test="@data_type='struct_array'">
    ! deallocate <xsl:value-of select="@path"/>
    if (associated(<xsl:value-of select="$currentidxpath"/>)) then
        do i<xsl:value-of select="$level"/> = 1,size(<xsl:value-of select = "$currentidxpath"/>)
             <xsl:apply-templates select="field" mode="DEALLOCATE">
                 <xsl:with-param name="level" select="$level + 1"/>
                 <xsl:with-param name="idxpath" select="concat($currentidxpath,'(i',$level,')')"/>
             </xsl:apply-templates>
        enddo
        deallocate(<xsl:value-of select="$currentidxpath"/>)
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
call ids_flush_cache(idx,IDSpath,"<xsl:value-of select="@path"/>")         <!-- call to the low level ids_flush_cache routine -->
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
call ids_discard_cache(idx,IDSpath,<xsl:value-of select="concat($mds_path,'//&quot;/',@name,'&quot;')"/>)         <!-- call to the low level ids_discard_cache routine -->
   </xsl:when>
   <xsl:otherwise>
call ids_discard_cache(idx,IDSpath,"<xsl:value-of select="@path"/>")         <!-- call to the low level delete_data routine -->
   </xsl:otherwise>
   </xsl:choose>
</xsl:otherwise>
</xsl:choose>
</xsl:template>


<xsl:template name ="checkError">
	<xsl:param name="method"/>
   retStatus = status
   if(isErrorCritical(status, "<xsl:value-of select="ancestor::IDS/@name"/> : <xsl:value-of select="@path"/>")) then
   	call end_ids_<xsl:value-of select="$method"/>(idx, path)
   	return
    endif
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

</xsl:stylesheet>
