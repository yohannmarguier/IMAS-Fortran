<?xml version="1.0" encoding="UTF-8"?>
<?modxslt-stylesheet type="text/xsl" media="fuffa, screen and $GET[stylesheet]" href="./%24GET%5Bstylesheet%5D" alternate="no" title="Translation using provided stylesheet" charset="ISO-8859-1" ?>
<?modxslt-stylesheet type="text/xsl" media="screen" alternate="no" title="Show raw source of the XML file" charset="ISO-8859-1" ?>
<xsl:stylesheet xmlns:yaslt="http://www.mod-xslt2.com/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:exsl="http://exslt.org/common"
xmlns:xs="http://www.w3.org/2001/XMLSchema" version="1.0" extension-element-prefixes="yaslt exsl" xmlns:fn="http://www.w3.org/2005/02/xpath-functions">
	<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>
	<!-- This XSL translates the list of ITM CPODefs to Fortran 90 GET/PUT Routines for CPOs -->
	<!-- Written by F. Imbeaux and G. Manduchi -->
	<!-- 28/06/2007 : added proper declaration in interfaces of the Complex Type CPOs defined in Utilities  (like line_integral_diag, in order to have them declared twice in the interface). NB : the templates writing the CPO functions will still write one for each CPO, but this does not create problem as long as there is a uniwue function in the interface. F.Imbeaux -->
	<!--  Version 4.05 - July 2007, added the new vecstring_type, F. Imbeaux -->
	<!--  Version 4.05 - September 2007, added the string manipulation, F. Imbeaux -->
	<!--  Version 4.05 - October 2007, get vec_string debugged, ALL TYPES GET and PUT running ok, F. Imbeaux -->
	<!--  Version 4.05 - November 2007, isTimed argument added to all put_vect routines, following change of UAL_low_level from GM, F. Imbeaux -->
	<!--  Version 4.05 - January 2008, full GET and PUT, GET_SLICE routines modified : time index is now stored as the last one , following change of UAL_low_level from GM, F. Imbeaux -->
	<!--  Version 4.05 - 15th January 2008, PUT_SLICE routines added, F. Imbeaux -->
	<!--  Version 4.05 - 16th February 2008, PUT_NON_TIMED routines added, F. Imbeaux -->
	<!--  Version 4.05 - September 2008, add DELETE CPO routines at the high level, F. Imbeaux -->
	<!--  Version 4.06c - September 2008, remove all specific treatment of "generic (special) type" CPOs, now all declared explicitely with their own name, F. Imbeaux -->
	<!--  Version 4.06c - September 2008, add euitm_deallocate functions, F. Imbeaux -->
	<!--  Version 4.07 - March 2009, add euitm_copy functions, F. Imbeaux -->
	<!-- Version 4.07b - November 2009 correct bug on begin_cpo_get + add new euitm_copy functionalities -->
	<xsl:template match="/CPOs">
 <exsl:document href="euitm_routines.f90" method="text">
module euITM_routines

use euITM_schemas
 <xsl:for-each select="CPO">
use <xsl:value-of select="@type"/>_euitm_module</xsl:for-each>

contains

subroutine euitm_get_times(idx,path,time)
implicit none
integer, parameter :: DP=kind(1.0D0)

integer :: idx, status
character*(*) :: path
real(DP), pointer :: time(:)

integer :: ndims,dim1,dim2,dim3,dim4,dum1,dum2,dum3,dum4, dim5, dim6, dim7, lentime

call get_dimension(idx,path,"time",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
lentime = dim1

call begin_cpo_get(idx, path,1,dum1)

allocate(time(lentime))
call get_vect1d_double(idx,path,"time",time,lentime,dum1,status)

end subroutine
end module
</exsl:document>
<xsl:apply-templates select="CPO" mode="main"/>

</xsl:template>

 <xsl:template match="CPO" mode="main">

  <exsl:document href="{@type}.f90" method="text">
module <xsl:value-of select="@type"/>_euitm_module
! Declaration of the generic CPO GET routine

interface euITM_get
   module procedure euITM_get_<xsl:value-of select="@type"/>
end interface euITM_get

! Declaration of the generic CPO GET_SLICE routine
interface euITM_get_slice
   module procedure  euITM_get_slice_<xsl:value-of select="@type"/>
end interface euITM_get_slice
<xsl:if test="@timed='yes'">
! Declaration of the generic CPO PUT_SLICE routine
interface euITM_put_slice
 <!-- Procedure put_slice exists only for time-dependent CPOs -->
   module procedure euITM_put_slice_<xsl:value-of select="@type"/>
end interface euITM_put_slice
</xsl:if >
! Declaration of the generic CPO PUT routine
interface euITM_put        <!-- Declare here all the specialised routines -->
   module procedure euITM_put_<xsl:value-of select="@type"/>
end interface euITM_put

! Declaration of the generic CPO PUT_NON_TIMED routine
interface euITM_put_non_timed        <!-- Declare here all the specialised routines -->
   module procedure <xsl:choose> <xsl:when test="@timed='yes'"> euITM_put_non_timed_<xsl:value-of select="@type"/> </xsl:when><xsl:otherwise>euITM_put_<xsl:value-of select="@type"/>
				</xsl:otherwise>
			</xsl:choose>
end interface euITM_put_non_timed

! Declaration of the generic CPO DELETE routine
interface euITM_delete        <!-- Declare here all the specialised routines -->
   module procedure euITM_delete_<xsl:value-of select="@type"/>
end interface euITM_delete

! Declaration of the generic CPO DEALLOCATE routine
interface euITM_deallocate        <!-- Declare here all the specialised routines -->
   module procedure euITM_deallocate_<xsl:value-of select="@type"/>
end interface euITM_deallocate

! Declaration of the generic CPO COPY routine
interface euITM_copy
   module procedure <xsl:choose><xsl:when test="@timed='yes'">euITM_copy_<xsl:value-of select="@type"/>, &amp;
   euITM_copy_slice2slice_<xsl:value-of select="@type"/>, &amp;
   euITM_copy_pointer2slice_<xsl:value-of select="@type"/>, &amp;
   euITM_copy_slice2pointer_<xsl:value-of select="@type"/></xsl:when>
<xsl:otherwise>euITM_copy_<xsl:value-of select="@type"/>
				</xsl:otherwise>
			</xsl:choose>
end interface euITM_copy

! Declaration of the generic CPO FLUSH routine
interface euitm_flush        <!-- Declare here all the specialised routines -->
   module procedure euitm_flush_<xsl:value-of select="@type"/>
end interface euitm_flush

! Declaration of the generic CPO DISCARD routine
interface euitm_discard        <!-- Declare here all the specialised routines -->
   module procedure euitm_discard_<xsl:value-of select="@type"/>
end interface euitm_discard

 contains
 !!!!!! Routines to GET the full CPOs (including the various time indices if time-dependent)
 ! All routines specialised for each CPO

!!!!!! Routines to GET the full CPOs (including the various time indices if time-dependent)
 <!--<xsl:apply-templates select="CPO" mode="GET_FULL"/>-->
 		<xsl:choose>
			<xsl:when test="@timed = 'yes'">
subroutine euITM_get_<xsl:value-of select="@type"/>(idx,path,  cpos)
<!--, int REFERENCE(maxItems), int REFERENCE(retItems)) a quoi ca sert ??-->
use euITM_schemas
implicit none
integer, parameter :: DP=kind(1.0D0)

character*(*) :: path
integer :: idx, status, lentime, lenstring, istring
character(len=3)::ual_debug

type(type_<xsl:value-of select="@type"/>),pointer :: cpos(:)      <!-- cpos is an array of CPO structure (index of this array corresponds to time) -->

! internal variables declaration
integer :: itime
integer :: int0D
integer,pointer :: vect1DInt(:), vect2DInt(:,:), vect3DInt(:,:,:) => null()
integer :: ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7,dum1,dum2,dum3,dum4,dum5,dum6,dum7
real(DP) :: double0D
real(DP), pointer :: vect1DDouble(:), time(:), vect2DDouble(:,:), vect3DDouble(:,:,:), vect4DDouble(:,:,:,:) => null()
real(DP), pointer :: vect5DDouble(:,:,:,:,:), vect6DDouble(:,:,:,:,:,:) => null()
character(len=132) :: stringans
character(len=100000)::longstring
character(len=132), dimension(:), pointer ::stringpointer        => null()
integer :: obj_all_times,obj1,obj2,obj3,obj4,obj5,obj6,obj7
integer :: dimObj0,dimObj1,dimObj2,dimObj3,dimObj4,dimObj5,dimObj6,dimObj7
integer :: i1,i2,i3,i4,i5,i6,i7

<!-- -->
call getenv('ual_debug',ual_debug) ! Debug flag

call begin_cpo_get(idx, path,1,dum1)

! get time base and allocate the array of cpo structures
call get_dimension(idx,path,"time",ndims, dim1,dim2,dim3,dim4,dim5,dim6,dim7)
lentime = dim1
allocate(cpos(lentime))
<!-- -->
      <xsl:apply-templates select="field" mode="GET_FULL"/>
call end_cpo_get(idx, path)
      </xsl:when>
			<xsl:otherwise>
subroutine euITM_get_<xsl:value-of select="@type"/>(idx,path,  cpo)

use euITM_schemas
implicit none
integer, parameter :: DP=kind(1.0D0)
character*(*) :: path
integer :: idx, status, lenstring, istring
integer :: ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7,dum1,dum2,dum3,dum4,dum5,dum6,dum7
character(len=3)::ual_debug

character(len=132)::stringans      ! Temporary way of getting short strings
character(len=100000)::longstring
character(len=132), dimension(:), pointer ::stringpointer   => null()
integer :: obj_all_times,obj1,obj2,obj3,obj4,obj5,obj6,obj7
integer :: dimObj0,dimObj1,dimObj2,dimObj3,dimObj4,dimObj5,dimObj6,dimObj7
integer :: i1,i2,i3,i4,i5,i6,i7

integer :: int0d
real(DP) :: double0d


type(type_<xsl:value-of select="@type"/>) :: cpo       <!-- cpos is an array of CPO structure (index of this array corresponds to time) -->

call getenv('ual_debug',ual_debug) ! Debug flag

call begin_cpo_get(idx, path,0,dum1)
      <xsl:apply-templates select="field" mode="GET_SINGLE"/>
call end_cpo_get(idx, path)
     </xsl:otherwise>
		</xsl:choose>
return
end subroutine euITM_get_<xsl:value-of select="@type"/>

!!!!!! Routines to GET one time slice of a CPO, with time interpolation
<!--<xsl:apply-templates select="CPO" mode="GET_SLICE"/> -->
subroutine euITM_get_slice_<xsl:value-of select="@type"/>(idx,path,  cpo, twant, interpol)

use euITM_schemas
implicit none
integer, parameter :: DP=kind(1.0D0)

character*(*) :: path
integer :: status, interpol, idx, lenstring, istring
real(DP) :: twant,tret
character(len=3)::ual_debug

integer :: int0D
integer,pointer :: vect1DInt(:), vect2DInt(:,:), vect3DInt(:,:,:) => null()
integer :: ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7,dum1,dum2,dum3,dum4,dum5,dum6,dum7
real(DP) :: double0D
real(DP), pointer :: vect1DDouble(:), time(:), vect2DDouble(:,:), vect3DDouble(:,:,:), vect4DDouble(:,:,:,:) => null()
real(DP), pointer :: vect5DDouble(:,:,:,:,:), vect6DDouble(:,:,:,:,:,:) => null()
character(len=132), dimension(:), pointer :: stringans => null()
character(len=100000)::longstring
integer :: obj_single_time,obj1,obj2,obj3,obj4,obj5,obj6,obj7
integer :: dimObj1,dimObj2,dimObj3,dimObj4,dimObj5,dimObj6,dimObj7
integer :: i1,i2,i3,i4,i5,i6,i7

type(type_<xsl:value-of select="@type"/>) :: cpo

call getenv('ual_debug',ual_debug)
<!-- -->
		<xsl:choose>
			<xsl:when test="@timed = 'yes'">
call begin_CPO_Get_Slice(idx,path, twant,status)
if (status.EQ.0) then
	      <xsl:apply-templates select="field" mode="GET_SLICE"/>
else
   write(*,*) 'Get slice impossible, CPO is missing or requested time slice is not within the time interval of the CPO'
endif
call end_CPO_Get_Slice(idx,path)
	</xsl:when>
			<xsl:otherwise>
				<!-- a get_slice of a time-independent CPO is equivalent to a normal GET -->
write(*,*) 'Warning : GET_SLICE requested for a time-independent CPO is equivalent to a simple GET'
call euITM_get_<xsl:value-of select="@type"/>(idx,path,  cpo)
	</xsl:otherwise>
		</xsl:choose>

return
end subroutine euITM_GET_SLICE_<xsl:value-of select="@type"/>
!!!!!! Routines to PUT the full CPOs (including the various time indices if time-dependent)
<!--<xsl:apply-templates select="CPO" mode="PUT"/>-->
		<xsl:choose>
			<xsl:when test="@timed = 'yes'">
subroutine euITM_put_<xsl:value-of select="@type"/>(idx, path,  cpos)

use euITM_schemas
implicit none
integer, parameter :: DP=kind(1.0D0)

character*(*) :: path
integer :: idx, lentime
character(len=3)::ual_debug

type(type_<xsl:value-of select="@type"/>),pointer :: cpos(:)       <!-- cpos is an array of CPO structure (index of this array corresponds to time) -->

! internal variables declaration
integer :: itime
integer :: int0D
integer,pointer :: vect1DInt(:), vect2DInt(:,:), vect3DInt(:,:,:) => null()
integer :: i,dim1,dim2,dim3,dim4,dim5,dim6,dim7, lenstring, istring
integer, pointer :: dimtab(:) => null()
real(DP) :: double0D
real(DP), pointer :: vect1DDouble(:), time(:), vect2DDouble(:,:), vect3DDouble(:,:,:), vect4DDouble(:,:,:,:) => null()
real(DP), pointer :: vect5DDouble(:,:,:,:,:), vect6DDouble(:,:,:,:,:,:) => null()
character(len=132), dimension(:), pointer :: stri => null()
character(len=100000)::longstring
integer :: obj_all_times,obj1,obj2,obj3,obj4,obj5,obj6,obj7
integer :: i1,i2,i3,i4,i5,i6,i7

call getenv('ual_debug',ual_debug) ! Debug flag

! Systematic delete of the previous CPO, in case it existed
call euitm_delete(idx,path,cpos)

! And systematic erase of the previous changes in cache
call euitm_discard(idx,path,cpos)

<!-- -->
! check whether CPO is empty
if (.NOT.associated(cpos)) then
   write (*,*) "WARNING: trying to put empty '<xsl:value-of select="@type"/>'"
   return
endif

if (size(cpos).EQ.0) then
   write (*,*) "WARNING: trying to put empty '<xsl:value-of select="@type"/>'"
   return
endif

! find the length of the time base
lentime = size(cpos)
! find time vector
allocate(time(lentime))
time(1:lentime) = cpos(1:lentime)%time
<!-- -->
call begin_cpo_put_timed(idx, path,lentime,time)
deallocate(time)
<!-- -->
				<xsl:apply-templates select="field" mode="PUT_TIMED"/>
call end_cpo_put_timed(idx, path)
<!-- -->
			</xsl:when>
			<xsl:otherwise>
subroutine euITM_put_<xsl:value-of select="@type"/>(idx, path,  cpo)

use euITM_schemas
implicit none

character*(*) :: path
integer :: idx
integer :: i,dim1,dim2,dim3,dim4,dim5,dim6,dim7, lenstring, istring
integer, pointer :: dimtab(:) => null()
character(len=100000)::longstring
character(len=3)::ual_debug
integer :: obj_all_times,obj1,obj2,obj3,obj4,obj5,obj6,obj7
integer :: i1,i2,i3,i4,i5,i6,i7

type(type_<xsl:value-of select="@type"/>) :: cpo       <!-- cpos is an array of CPO structure (index of this array corresponds to time) -->


call getenv('ual_debug',ual_debug) ! Debug flag

! Systematic delete of the previous CPO, in case it existed
call euitm_delete(idx,path,cpo)

! And systematic erase of the previous changes in cache
call euitm_discard(idx,path,cpo)

call begin_cpo_put_non_timed(idx, path)
<!-- -->
				<xsl:apply-templates select="field" mode="PUT_SINGLE"/>
call end_cpo_put_non_timed(idx, path)
<!-- -->
			</xsl:otherwise>
		</xsl:choose>
return
end subroutine euITM_put_<xsl:value-of select="@type"/>
<xsl:if test="@timed='yes'">
!!!!!! Routines to PUT_SLICE one time slice of a time-dependent CPO (affects only time-dependent fields)
<!--<xsl:apply-templates select="CPO[@timed='yes']" mode="PUT_SLICE"/>-->
subroutine euITM_put_slice_<xsl:value-of select="@type"/>(idx,path,cpo)

use euITM_schemas
implicit none
integer, parameter :: DP=kind(1.0D0)

character*(*) :: path
integer :: idx, lentime
character(len=3)::ual_debug

type(type_<xsl:value-of select="@type"/>) :: cpo

! internal variables declaration
integer :: itime
integer :: int0D
integer,pointer :: vect1DInt(:), vect2DInt(:,:), vect3DInt(:,:,:) => null()
integer :: i,dim1,dim2,dim3,dim4,dim5,dim6,dim7, lenstring, istring
integer, pointer :: dimtab(:) => null()
real(DP) :: double0D
real(DP), pointer :: vect1DDouble(:), time(:), vect2DDouble(:,:), vect3DDouble(:,:,:), vect4DDouble(:,:,:,:) => null()
real(DP), pointer :: vect5DDouble(:,:,:,:,:), vect6DDouble(:,:,:,:,:,:) => null()
character(len=132), dimension(:), pointer :: stri => null()
character(len=100000)::longstring
integer :: obj_single_time,obj1,obj2,obj3,obj4,obj5,obj6,obj7
integer :: i1,i2,i3,i4,i5,i6,i7

call getenv('ual_debug',ual_debug) ! Debug flag

<!-- -->
call begin_cpo_put_slice(idx, path,cpo%time)
<!-- -->
		<xsl:apply-templates select="field" mode="PUT_SLICE"/>
call end_cpo_put_slice(idx, path)
<!-- -->

return
end subroutine euITM_put_slice_<xsl:value-of select="@type"/>
!!!!!! Routines to PUT_NON_TIMED the time INdependent data of time dependent CPOs
<!--<xsl:apply-templates select="CPO[@timed='yes']" mode="PUT_NON_TIMED"/>-->
subroutine euITM_put_non_timed_<xsl:value-of select="@type"/>(idx, path,  cpo)

use euITM_schemas
implicit none

character*(*) :: path
integer :: idx
integer :: i,dim1,dim2,dim3,dim4,dim5,dim6,dim7, lenstring, istring
integer, pointer :: dimtab(:) => null()
character(len=100000)::longstring
character(len=3)::ual_debug
integer :: obj1,obj2,obj3,obj4,obj5,obj6,obj7
integer :: i1,i2,i3,i4,i5,i6,i7

type(type_<xsl:value-of select="@type"/>) :: cpo       ! real declaration of the CPO for the put
type(type_<xsl:value-of select="@type"/>),pointer :: cpos(:)       ! dummy declaration used for the euitm_delete interface only

call getenv('ual_debug',ual_debug) ! Debug flag

! Systematic delete of the previous CPO, in case it existed; guarantees the time-dependent data is deleted
call euitm_delete(idx,path,cpos)

! And systematic erase of the previous changes in cache
call euitm_discard(idx,path,cpos)

<!-- -->
call begin_cpo_put_non_timed(idx, path)
<!-- -->
		<xsl:apply-templates select="field" mode="PUT_SINGLE"/>
		<!-- Applies the PUT_SINGLE method (putting a individual non time dependent signal) to all non time dependent fields of the CPO, whatever their level (child, grand-child, grand-grand-child ... verifying @timed = 'no') -->
call end_cpo_put_non_timed(idx, path)
<!-- -->
return
end subroutine euITM_put_non_timed_<xsl:value-of select="@type"/>
</xsl:if >
!!!!!! Routines to DELETE CPOs
<!--<xsl:apply-templates select="CPO" mode="DELETE"/>-->
subroutine euITM_delete_<xsl:value-of select="@type"/>(idx,cpopath,cpo)  <!-- systematic calls to the low level delete_data routine. The cpo input argument is added just for the interface to identify the relevant CPO type -->

use euITM_schemas
implicit none
character*(*) :: cpopath
integer :: idx
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug

  <xsl:choose>
			<xsl:when test="@timed = 'yes'">
type(type_<xsl:value-of select="@type"/>),pointer :: cpo(:)       <!-- cpos is an array of CPO structure (index of this array corresponds to time) -->
			</xsl:when>
			<xsl:otherwise>
type(type_<xsl:value-of select="@type"/>) :: cpo       <!-- cpos is an array of CPO structure (index of this array corresponds to time) -->
			</xsl:otherwise>
		</xsl:choose>
		<!-- -->

call getenv('ual_debug',ual_debug) ! Debug flag
if (ual_debug =='yes') write(*,*) 'Deleting CPO ',cpopath
<xsl:apply-templates select="field" mode="DELETE"/>
if (ual_debug =='yes') write(*,*) 'Delete CPO ',cpopath,' done'
end subroutine euITM_delete_<xsl:value-of select="@type"/>

!!!!!! Routines to DEALLOCATE CPOs
<!--<xsl:apply-templates select="CPO" mode="DEALLOCATE"/>-->
subroutine euITM_deallocate_<xsl:value-of select="@type"/>(cpo)  <!-- Deallocates all allocated fields in the cpo variable sent as argument -->

use euITM_schemas
implicit none
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug
integer :: i1,i2,i3,i4,i5,i6,i7

  <xsl:choose>
			<xsl:when test="@timed = 'yes'">
type(type_<xsl:value-of select="@type"/>),pointer :: cpo(:)
integer :: itime

call getenv('ual_debug',ual_debug) ! Debug flag

! check whether CPO is empty
if (.NOT.associated(cpo)) then
   write (*,*) "WARNING: trying to deallocate empty '<xsl:value-of select="@type"/>'"
   return
endif

if (ual_debug =='yes') write(*,*) 'Deallocating <xsl:value-of select="@type"/> CPO'
do itime=1,size(cpo)    ! loop on time
    <xsl:apply-templates select="field" mode="DEALLOCATE">
        <xsl:with-param name="level" select="1"/>
        <xsl:with-param name="idxpath" select="'cpo(itime)'"/>
    </xsl:apply-templates>
enddo

! Finally, deallocate the CPO itself
deallocate(cpo)
</xsl:when>
			<xsl:otherwise>
type(type_<xsl:value-of select="@type"/>) :: cpo
    <xsl:apply-templates select="field" mode="DEALLOCATE">
        <xsl:with-param name="level" select="1"/>
        <xsl:with-param name="idxpath" select="'cpo'"/>
    </xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
		<!-- -->

if (ual_debug =='yes') write(*,*) 'Deallocate an <xsl:value-of select="@type"/> CPO : done'
end subroutine euITM_deallocate_<xsl:value-of select="@type"/>
!!!!!! Routines to COPY CPOs
<!--<xsl:apply-templates select="CPO" mode="COPY"/>-->
		<xsl:choose>
			<xsl:when test="@timed = 'yes'">
subroutine euITM_copy_<xsl:value-of select="@type"/>(cpoin,  cpoout)
! Copies all fields of cpoin to cpoout, both are pointers of time slices; cpoout allocated to the same size as cpoin

use euITM_schemas
implicit none
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug

integer :: itime, lentime, lenstring, istring
integer :: i1,i2,i3,i4,i5,i6,i7

type(type_<xsl:value-of select="@type"/>),pointer :: cpoin(:), cpoout(:)

call getenv('ual_debug',ual_debug) ! Debug flag

! check whether CPO is empty
if (.NOT.associated(cpoin)) then
   write (*,*) "WARNING: trying to copy empty '<xsl:value-of select="@type"/>'"
   return
endif

<!-- -->
! Allocate cpoout to the same size as cpoin
lentime = size(cpoin)
allocate(cpoout(lentime))
<!-- -->
do itime=1,lentime
      <xsl:apply-templates select="field" mode="COPY_TIMED">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="idxpath" select="''"/>
      </xsl:apply-templates>
enddo
return
end subroutine euITM_copy_<xsl:value-of select="@type"/>

subroutine euITM_copy_slice2slice_<xsl:value-of select="@type"/>(cpoin,  cpoout)
! Copies all fields of cpoin to cpoout; both are single time slices of the time-dependent CPO

use euITM_schemas
implicit none
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug

integer :: itime, lentime, lenstring, istring
integer :: i1,i2,i3,i4,i5,i6,i7

type(type_<xsl:value-of select="@type"/>) :: cpoin, cpoout

call getenv('ual_debug',ual_debug) ! Debug flag

      <xsl:apply-templates select="field" mode="COPY_NON_TIMED">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="idxpath" select="''"/>
      </xsl:apply-templates>
return
end subroutine euITM_copy_slice2slice_<xsl:value-of select="@type"/>

subroutine euITM_copy_pointer2slice_<xsl:value-of select="@type"/>(cpoin,  cpoout)
! Copies all fields of cpoin to cpoout, cpoin is a pointer, cpoout is a single time slice

use euITM_schemas
implicit none
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug

integer :: lenstring, istring
integer :: i1,i2,i3,i4,i5,i6,i7

type(type_<xsl:value-of select="@type"/>),pointer :: cpoin(:)
type(type_<xsl:value-of select="@type"/>) :: cpoout

call getenv('ual_debug',ual_debug) ! Debug flag

! check whether CPO is empty
if (.NOT.associated(cpoin)) then
   write (*,*) "WARNING: trying to copy empty '<xsl:value-of select="@type"/>'"
   return
endif

      <xsl:apply-templates select="field" mode="COPY_TIMED_POINTER2SLICE">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="idxpath" select="''"/>
      </xsl:apply-templates>

return
end subroutine euITM_copy_pointer2slice_<xsl:value-of select="@type"/>

subroutine euITM_copy_slice2pointer_<xsl:value-of select="@type"/>(cpoin,  cpoout)
! Copies all fields of cpoin to cpoout, cpoin is a single time slice, cpoout is a pointer (allocated to size 1 inside this routine)

use euITM_schemas
implicit none
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug

integer :: lenstring, istring
integer :: i1,i2,i3,i4,i5,i6,i7

type(type_<xsl:value-of select="@type"/>) :: cpoin
type(type_<xsl:value-of select="@type"/>),pointer :: cpoout(:)

call getenv('ual_debug',ual_debug) ! Debug flag

allocate(cpoout(1))

      <xsl:apply-templates select="field" mode="COPY_TIMED_SLICE2POINTER">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="idxpath" select="''"/>
      </xsl:apply-templates>

return
end subroutine euITM_copy_slice2pointer_<xsl:value-of select="@type"/>

      </xsl:when>
			<xsl:otherwise>
subroutine euITM_copy_<xsl:value-of select="@type"/>(cpoin,  cpoout)
! Copies all fields of cpoin to cpoout; Time-independent CPO

use euITM_schemas
implicit none
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug

integer :: itime, lentime, lenstring, istring
integer :: i1,i2,i3,i4,i5,i6,i7

type(type_<xsl:value-of select="@type"/>) :: cpoin, cpoout

call getenv('ual_debug',ual_debug) ! Debug flag

      <xsl:apply-templates select="field" mode="COPY_NON_TIMED">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="idxpath" select="''"/>
      </xsl:apply-templates>

return
end subroutine euITM_copy_<xsl:value-of select="@type"/>
     </xsl:otherwise>
		</xsl:choose>
!!!!!! Routines to flush CPOs
<!--<xsl:apply-templates select="CPO" mode="FLUSH_CACHE"/>-->
subroutine euitm_flush_<xsl:value-of select="@type"/>(idx,cpopath,cpo)  <!-- systematic calls to the low level euitm_flush_cache routine. The cpo input argument is added just for the interface to identify the relevant CPO type -->

use euITM_schemas
implicit none
character*(*) :: cpopath
integer :: idx
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug

  <xsl:choose>
			<xsl:when test="@timed = 'yes'">
type(type_<xsl:value-of select="@type"/>),pointer :: cpo(:)       <!-- cpos is an array of CPO structure (index of this array corresponds to time) -->
			</xsl:when>
			<xsl:otherwise>
type(type_<xsl:value-of select="@type"/>) :: cpo       <!-- cpos is an array of CPO structure (index of this array corresponds to time) -->
			</xsl:otherwise>
		</xsl:choose>
		<!-- -->

call getenv('ual_debug',ual_debug) ! Debug flag
if (ual_debug =='yes') write(*,*) 'Flushing CPO ',cpopath
<xsl:apply-templates select="field" mode="FLUSH_CACHE"/>
if (ual_debug =='yes') write(*,*) 'Flushing CPO ',cpopath,' done'
end subroutine euitm_flush_<xsl:value-of select="@type"/>

!!!!!! Routines to discard CPOs
<!--<xsl:apply-templates select="CPO" mode="DISCARD_CACHE"/>-->
subroutine euitm_discard_<xsl:value-of select="@type"/>(idx,cpopath,cpo)  <!-- systematic calls to the low level euitm_discard_cache routine. The cpo input argument is added just for the interface to identify the relevant CPO type -->

use euITM_schemas
implicit none
character*(*) :: cpopath
integer :: idx
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug

  <xsl:choose>
			<xsl:when test="@timed = 'yes'">
type(type_<xsl:value-of select="@type"/>),pointer :: cpo(:)       <!-- cpos is an array of CPO structure (index of this array corresponds to time) -->
			</xsl:when>
			<xsl:otherwise>
type(type_<xsl:value-of select="@type"/>) :: cpo       <!-- cpos is an array of CPO structure (index of this array corresponds to time) -->
			</xsl:otherwise>
		</xsl:choose>
		<!-- -->

call getenv('ual_debug',ual_debug) ! Debug flag
if (ual_debug =='yes') write(*,*) 'Discarding CPO ',cpopath
<xsl:apply-templates select="field" mode="DISCARD_CACHE"/>
if (ual_debug =='yes') write(*,*) 'Discarding CPO ',cpopath,' done'
end subroutine euitm_discard_<xsl:value-of select="@type"/>
end module <xsl:value-of select="@type"/>_euitm_module
</exsl:document>

</xsl:template>
	<!-- This was a beautiful way to select a unique CPO of a given generic type in the structure, not used anymore, but kept for the esthetics in the comments !
<xsl:template match = "CPO" mode = "getlist">
<xsl:param name="special_type"/>
<xsl:param name="cpo_name"/>
<xsl:param name="function"/>
    <xsl:apply-templates select="//CPO[@special_type=$special_type]" mode = "getlist2">-->
	<!-- calls the next template with only the CPOs corresponding to the given special_type  -->
	<!--   <xsl:with-param name = "special_type" select = "$special_type"/>
      <xsl:with-param name = "cpo_name" select = "$cpo_name"/>
      <xsl:with-param name = "function" select = "$function"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match = "CPO" mode = "getlist2">
<xsl:param name="special_type"/>
<xsl:param name="cpo_name"/>
<xsl:param name="function"/> -->
	<!-- this template is applied to all CPOs matching the special_type-->
	<!--<xsl:if test="position()=1">-->
	<!-- we apply the next template only to the first of the list !! -->
	<!--
<xsl:apply-templates select="." mode = "getlist3">
      <xsl:with-param name = "special_type" select = "$special_type"/>
      <xsl:with-param name = "cpo_name" select = "$cpo_name"/>
      <xsl:with-param name = "function" select = "$function"/>
      </xsl:apply-templates>
</xsl:if>
</xsl:template>

<xsl:template match = "CPO" mode = "getlist3">
<xsl:param name="special_type"/>
<xsl:param name="cpo_name"/>
<xsl:param name="function"/> -->
	<!-- in this template, we have only the first CPO of special_type of the whole list : we just need to check that it is indeed the same as the one we are going to declare in the interface - otherwise we do not declare it to avoid conflict -->
	<!-- <xsl:if test="@type=$cpo_name">
   euITM_<xsl:value-of select="$function"/>_<xsl:value-of select="@type"/>, &amp; </xsl:if>
</xsl:template>-->


<!--!!!!!!!!!!!!!!!!!!!!!!!!!             GET SLICE ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->

  <!--<xsl:template match="CPO" mode="GET_SLICE">

</xsl:template>-->
	<xsl:template match="field" mode="GET_SLICE">
		<xsl:choose>
			<xsl:when test="@type='structure'">
				<xsl:apply-templates select="field" mode="GET_SLICE"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="@timed = 'yes'">
						<xsl:choose>
                     <xsl:when test="@type='struct_array'">
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
            'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
         allocate(cpo%<xsl:value-of select = "translate(@path,'/','%')"/>(dimObj1))
         do i1 = 1,dimObj1     ! process array elements
            <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
               <xsl:with-param name="level" select="1"/>
               <xsl:with-param name="objpath" select="@name"/>
               <xsl:with-param name="idxpath" select="concat('cpo%',translate(@path,'/','%'),'(i1)')"/>
               <xsl:with-param name="timed" select="'yes'"/>
            </xsl:apply-templates>
         enddo
      else
         if (associated(cpo%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
            deallocate(cpo%<xsl:value-of select = "translate(@path,'/','%')"/>);
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
      if (.NOT.associated(cpo%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
         allocate(cpo%<xsl:value-of select = "translate(@path,'/','%')"/>(dimObj1))
      endif
      ! must have same number of non-timed elements and timed elements
      if (size(cpo%<xsl:value-of select = "translate(@path,'/','%')"/>).NE.dimObj1) then
         write(*,*) "Error in getSlice: array of structures has different number of timed and nontimed elements for <xsl:value-of select = "@path"/>"
      else
         do i1 = 1,dimObj1     ! process array elements
            <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
               <xsl:with-param name="level" select="1"/>
               <xsl:with-param name="objpath" select="@name"/>
               <xsl:with-param name="idxpath" select="concat('cpo%',translate(@path,'/','%'),'(i1)')"/>
               <xsl:with-param name="timed" select="'no'"/>
            </xsl:apply-templates>
         enddo
      endif
   endif
   call release_object(idx,obj1)
endif
<!-- -->
                     </xsl:when>
                     <xsl:when test="@type='xs:string'">
! Get <xsl:value-of select="@path"/>
                        <!-- for comment only -->
! TIME DEPENDENT STRINGS NOT TREATED YET !!!
<!-- -->
                     </xsl:when>
							<xsl:when test="@type='xs:integer'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_Int_Slice(idx,path, "<xsl:value-of select="@path"/>",int0d, twant,tret,interpol,status)
if (status.EQ.0) then
   cpo%<xsl:value-of select="translate(@path,'/','%')"/> = int0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@type='xs:float'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_double_Slice(idx,path, "<xsl:value-of select="@path"/>",double0d, twant,tret,interpol,status)
if (status.EQ.0) then
   cpo%<xsl:value-of select="translate(@path,'/','%')"/> = double0d
   if (ual_debug =='yes') write(*,*) &amp;
       'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@type='vecint_type'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
   call get_vect1d_Int_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dum1,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
       'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@type='vecflt_type'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
   call get_vect1d_double_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dum1,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@type='matflt_type'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
   call get_vect2d_double_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dum1,dum2,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@type='matint_type'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
   call get_vect2d_int_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dum1,dum2,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@type='array3dflt_type'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
   call get_vect3d_double_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dim3,dum1,dum2,dum3,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@type='array3dint_type'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
   call get_vect3d_int_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dim3,dum1,dum2,dum3,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>

							<xsl:when test="@type='array4dflt_type'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4))
   call get_vect4d_double_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dim3,dim4,dum1,dum2,dum3,dum4,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>

							<xsl:when test="@type='array5dflt_type'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5))
   call get_vect5d_double_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dim3,dim4,dim5,dum1,dum2,dum3,dum4,dum5,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
							</xsl:when>
							<xsl:when test="@type='array6dflt_type'">
! Get <xsl:value-of select="@path"/>
								<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5,dim6))
   call get_vect6d_double_Slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   dim1,dim2,dim3,dim4,dim5,dim6,dum1,dum2,dum3,dum4,dum5,dum6,twant,tret,interpol,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
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


	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             GET FULL CPO ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<!--<xsl:template match="CPO" mode="GET_FULL">

</xsl:template>-->
	<xsl:template match="field" mode="GET_FULL">
		<xsl:choose>
			<xsl:when test="@timed = 'yes'">
				<!-- Time dependent signals in time-dependent CPO : copy the time-dependent value in the proper index of the array of cpo structure -->
				<xsl:choose>
					<xsl:when test="@type='xs:integer'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
allocate(vect1DInt(lentime))
call get_vect1d_int(idx,path,"<xsl:value-of select="@path"/>",vect1DInt,lentime,dum1,status)
if (status.EQ.0) then
   cpos(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect1DInt(1:lentime)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
deallocate(vect1DInt)
    <!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:float'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
allocate(vect1Ddouble(lentime))
call get_vect1d_double(idx,path,"<xsl:value-of select="@path"/>",vect1Ddouble,lentime,dum1,status)
if (status.EQ.0) then
   cpos(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect1Ddouble(1:lentime)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
deallocate(vect1Ddouble)
<!--do itime=1,lentime
   cpos(itime)%<xsl:value-of select = "translate(@path,'/','%')"/> = vect1DDouble(itime)
enddo -->
						<!-- -->
					</xsl:when>
					<xsl:when test="@type='vecflt_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect2Ddouble(dim1,dim2)) <!-- dim2 contains lentime-->
   call get_vect2d_double(idx,path,"<xsl:value-of select="@path"/>",vect2Ddouble,dim1,dim2,dum1,dum2,status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect2DDouble(:,itime)   <!-- assign the value to the CPO structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect2DDouble)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='vecint_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect2Dint(dim1,dim2)) <!-- dim2 contains lentime-->
   call get_vect2d_int(idx,path,"<xsl:value-of select="@path"/>", &amp;
   vect2Dint,dim1,dim2,dum1,dum2,status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect2Dint(:,itime)   <!-- assign the value to the CPO structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect2Dint)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='matflt_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect3Ddouble(dim1,dim2,dim3)) <!-- dim3 contains lentime-->
   call get_vect3D_double(idx,path,"<xsl:value-of select="@path"/>",vect3Ddouble,  &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect3DDouble(:,:,itime)   <!-- assign the value to the CPO structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect3DDouble)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='matint_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect3DInt(dim1,dim2,dim3)) <!-- dim3 contains lentime-->
   call get_vect3D_Int(idx,path,"<xsl:value-of select="@path"/>",vect3DInt,dim1,dim2,dim3, &amp;
   dum1,dum2,dum3,status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect3DInt(:,:,itime)   <!-- assign the value to the CPO structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect3DInt)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array3dflt_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect4Ddouble(dim1,dim2,dim3,dim4)) <!-- dim4 contains lentime-->
   call get_vect4D_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
         vect4Ddouble,dim1,dim2,dim3,dim4,dum1,dum2,dum3,dum4,status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect4DDouble(:,:,:,itime)   <!-- assign the value to the CPO structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect4DDouble)
endif
<!-- -->
					</xsl:when>
										<xsl:when test="@type='array4dflt_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect5Ddouble(dim1,dim2,dim3,dim4,dim5)) <!-- dim5 contains lentime-->
   call get_vect5D_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
         vect5Ddouble,dim1,dim2,dim3,dim4,dim5,dum1,dum2,dum3,dum4,dum5,status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect5DDouble(:,:,:,:,itime)   <!-- assign the value to the CPO structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect5DDouble)
endif
<!-- -->
					</xsl:when>
										<xsl:when test="@type='array5dflt_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect6Ddouble(dim1,dim2,dim3,dim4,dim5,dim6)) <!-- dim6 contains lentime-->
   call get_vect6D_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
         vect6Ddouble,dim1,dim2,dim3,dim4,dim5,dim6,dum1,dum2,dum3,dum4,dum5,dum6,status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect6DDouble(:,:,:,:,:,itime)   <!-- assign the value to the CPO structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect6DDouble)
endif
<!-- -->
					</xsl:when>

					<xsl:when test="@type='xs:string'">
! Get <xsl:value-of select="@path"/>  TIME-DEPENDENT STRING : NOT TREATED YET ... (NOT ALLOWED IN SCHEMAS YET !!!) <!-- for comment only -->
					</xsl:when>
					<xsl:when test="@type='vecstring_type'">
! Get <xsl:value-of select="@path"/>  TIME-DEPENDENT VECTOR OF STRINGS : NOT TREATED YET ... (NOT ALLOWED IN SCHEMAS YET !!!) <!-- for comment only -->
					</xsl:when>
					<xsl:when test="@type='structure'">
						<xsl:apply-templates select="field" mode="GET_FULL"/>
					</xsl:when>
               <xsl:when test="@type='struct_array'">
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
         'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
      do itime = 1,lentime     ! fill every time slice
         call get_object_from_object(idx,obj_all_times,"ALLTIMES",itime,obj1,status)
         if (status.EQ.0) then
            call get_object_dim(idx,obj1,dimObj1)
            if (dimObj1.GT.0) then
               allocate(cpos(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>(dimObj1))
               do i1 = 1,dimObj1     ! process array elements
                  <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
                     <xsl:with-param name="level" select="1"/>
                     <xsl:with-param name="objpath" select="@name"/>
                     <xsl:with-param name="idxpath" select="concat('cpos(itime)%',translate(@path,'/','%'),'(i1)')"/>
                     <xsl:with-param name="timed" select="'yes'"/>
                  </xsl:apply-templates>
               enddo
            else
               if (associated(cpos(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
                  deallocate(cpos(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)
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
<!-- -->
               </xsl:when>
					<xsl:otherwise>
 ! Get <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<!-- Time independent signals in time-dependent CPO : copy value to all time indices -->
				<xsl:choose>
					<xsl:when test="@type='xs:string'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
longstring = ' '
call get_String(idx,path, "<xsl:value-of select="@path"/>",longstring, status)
if (status.EQ.0) then
   do itime=1,lentime
      lenstring = len_trim(longstring)
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(floor(real(lenstring/132))+1))
      if (lenstring &lt;= 132) then
         cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(1) = trim(longstring)
      else
         do istring=1,floor(real(lenstring/132))+1
             cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(istring) = trim(longstring(1+(istring-1)*132 : istring*132))
         enddo
      endif
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='vecstring_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))  <!-- Do all allocate first together, otherwise problems if Get between two allocations of cpo(i)-->
   enddo
   allocate(stringpointer(dim1))
   call get_Vect1d_string(idx,path, "<xsl:value-of select="@path"/>", &amp;
                        stringpointer,dim1,dum1,status)
   do itime=1,lentime
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = stringpointer
   enddo
   deallocate(stringpointer)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:integer'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_Int(idx,path, "<xsl:value-of select="@path"/>",Int0D, status)           <!--reads the MDS signal, which has one more dimension (time)-->
if (status.EQ.0) then
   cpos(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/> = Int0D   <!-- assign the value to the CPO structure -->
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:float'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_Double(idx,path, "<xsl:value-of select="@path"/>",double0D, status)           <!--reads the MDS signal, which has one more dimension (time)-->
if (status.EQ.0) then
   cpos(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/> = double0D   <!-- assign the value to the CPO structure -->
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='vecflt_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect1DDouble(dim1))
   call get_vect1D_Double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect1DDouble,dim1,dum1, status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect1DDouble   <!-- assign the value to the CPO structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect1DDouble)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='vecint_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect1Dint(dim1))
   call get_vect1D_int(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect1Dint,dim1,dum1, status)           <!--reads the MDS signal, which has one more dimension (time)-->
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect1Dint   <!-- assign the value to the CPO structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect1Dint)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='matflt_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect2DDouble(dim1,dim2))
   call get_vect2D_Double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect2DDouble,dim1,dim2,dum1,dum2, status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect2DDouble   <!-- assign the value to the CPO structure -->
   enddo
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
   deallocate(vect2DDouble)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='matint_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect2DInt(dim1,dim2))
   call get_vect2D_Int(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect2DInt,dim1,dim2,dum1,dum2, status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect2DInt   <!-- assign the value to the CPO structure -->
   enddo
   deallocate(vect2DInt)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array3dflt_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect3DDouble(dim1,dim2,dim3))
   call get_vect3D_Double(idx,path, "<xsl:value-of select="@path"/>",vect3DDouble, &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect3DDouble   <!-- assign the value to the CPO structure -->
   enddo
   deallocate(vect3DDouble)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array3dint_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect3DInt(dim1,dim2,dim3))
   call get_vect3D_Int(idx,path, "<xsl:value-of select="@path"/>",vect3DInt, &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect3DInt   <!-- assign the value to the CPO structure -->
   enddo
   deallocate(vect3DInt)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array4dflt_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect4dDouble(dim1,dim2,dim3,dim4))
   call get_vect4d_Double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect4dDouble,dim1,dim2,dim3,dim4,dum1,dum2,dum3,dum4,status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect4dDouble   <!-- assign the value to the CPO structure -->
   enddo
   deallocate(vect4dDouble)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
										<xsl:when test="@type='array5dflt_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect5dDouble(dim1,dim2,dim3,dim4,dim5))
   call get_vect5d_Double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect5dDouble,dim1,dim2,dim3,dim4,dim5,dum1,dum2,dum3,dum4,dum5,status)
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect5dDouble   <!-- assign the value to the CPO structure -->
   enddo
   deallocate(vect5dDouble)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
										<xsl:when test="@type='array6dflt_type'">
! Get <xsl:value-of select="@path"/>
						<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(vect6dDouble(dim1,dim2,dim3,dim4,dim5,dim6))
   call get_vect6d_Double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   vect6dDouble,dim1,dim2,dim3,dim4,dim5,dim6,dum1,dum2,dum3,dum4,dum5,dum6,status)           <!--reads the MDS signal, which has one more dimension (time)-->
   do itime=1,lentime
      allocate(cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5,dim6))
      cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/> = vect6dDouble   <!-- assign the value to the CPO structure -->
   enddo
   deallocate(vect6dDouble)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
               <xsl:when test="@type='struct_array'">
! Get <xsl:value-of select="@path"/>
                        <!-- for comment only -->
! Read non-timed content
call get_object(idx,path,"<xsl:value-of select = "@path"/>",obj1,0,status); ! read the whole non-timed block
if (status.EQ.0) then
   do itime = 1,lentime     ! fill every time slice
      call get_object_dim(idx,obj1,dimObj1)
      if (dimObj1.GT.0) then
         allocate(cpos(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>(dimObj1))
         do i1 = 1,dimObj1     ! process array elements
            <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
               <xsl:with-param name="level" select="1"/>
               <xsl:with-param name="objpath" select="@name"/>
               <xsl:with-param name="idxpath" select="concat('cpos(itime)%',translate(@path,'/','%'),'(i1)')"/>
               <xsl:with-param name="timed" select="'no'"/>
            </xsl:apply-templates>
         enddo
      else
         if (associated(cpos(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
            deallocate(cpos(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)
         endif
      endif
   enddo
   call release_object(idx,obj1)
endif
<!-- -->
               </xsl:when>
					<xsl:when test="@type='structure'">
						<xsl:apply-templates select="field" mode="GET_FULL"/>
					</xsl:when>
					<xsl:otherwise>
 ! Get <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

<!--!!!!!!!!!!!!!!!!!!!!!!!!!             GET SINGLE CPO ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
	<xsl:template match="field" mode="GET_SINGLE">
		<!-- to get an element from a CPO which is NOT time-dependent : easy : elementary GET-->
		<xsl:choose>
			<xsl:when test="@type='xs:string'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
longstring = ' '
call get_string(idx,path, "<xsl:value-of select="@path"/>",longstring,status)
if (status.EQ.0) then
   lenstring = len_trim(longstring)
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(floor(real(lenstring/132))+1))
   if (lenstring &lt;= 132) then
      cpo%<xsl:value-of select="translate(@path,'/','%')"/> = trim(longstring)
   else
      do istring=1,floor(real(lenstring/132))+1
          cpo%<xsl:value-of select="translate(@path,'/','%')"/>(istring) = trim(longstring(1+(istring-1)*132 : istring*132))
      enddo
   endif
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='vecstring_type'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
   call get_Vect1d_string(idx,path, "<xsl:value-of select="@path"/>", &amp;
                        cpo%<xsl:value-of select="translate(@path,'/','%')"/>,dim1,dum1,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='xs:integer'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_int(idx,path, "<xsl:value-of select="@path"/>",int0d,status)
if (status.EQ.0) then
   cpo%<xsl:value-of select="translate(@path,'/','%')"/> = int0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='xs:float'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_double(idx,path, "<xsl:value-of select="@path"/>",double0d,status)
if (status.EQ.0) then
   cpo%<xsl:value-of select="translate(@path,'/','%')"/> = double0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='vecflt_type'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
   call get_vect1d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>,dim1,dum1,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='vecint_type'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1))
   call get_vect1d_int(idx,path,"<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>,dim1,dum1,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='matflt_type'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
   call get_vect2d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dum1,dum2,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='matint_type'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2))
   call get_vect2d_int(idx,path,"<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dum1,dum2,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='array3dflt_type'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
   call get_vect3d_double(idx,path,"<xsl:value-of select="@path"/>",&amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='array3dint_type'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3))
   call get_vect3d_int(idx,path,"<xsl:value-of select="@path"/>",&amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='array4dflt_type'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4))
   call get_vect4d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dim3,dim4,dum1,dum2,dum3,dum4,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>

			<xsl:when test="@type='array5dflt_type'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5))
   call get_vect5d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dim3,dim4,dim5,dum1,dum2,dum3,dum4,dum5,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
						<xsl:when test="@type='array6dflt_type'">
! Get <xsl:value-of select="@path"/>
				<!-- for comment only -->
call get_dimension(idx,path, "<xsl:value-of select="@path"/>",ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(dim1,dim2,dim3,dim4,dim5,dim6))
   call get_vect6d_double(idx,path,"<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   dim1,dim2,dim3,dim4,dim5,dim6,dum1,dum2,dum3,dum4,dum5,dum6,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>

         <xsl:when test="@type='struct_array'">
! Get <xsl:value-of select="@path"/>
                        <!-- for comment only -->
! Read non-timed content
call get_object(idx,path,"<xsl:value-of select = "@path"/>",obj1,0,status); ! read the whole non-timed block
if (status.EQ.0) then
   call get_object_dim(idx,obj1,dimObj1)
   if (dimObj1.GT.0) then
      allocate(cpo%<xsl:value-of select = "translate(@path,'/','%')"/>(dimObj1))
      do i1 = 1,dimObj1     ! process array elements
         <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
            <xsl:with-param name="level" select="1"/>
            <xsl:with-param name="objpath" select="@name"/>
            <xsl:with-param name="idxpath" select="concat('cpo%',translate(@path,'/','%'),'(i1)')"/>
            <xsl:with-param name="timed" select="'no'"/>
         </xsl:apply-templates>
      enddo
   else
      if (associated(cpo%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
         deallocate(cpo%<xsl:value-of select = "translate(@path,'/','%')"/>)
      endif
   endif
   call release_object(idx,obj1)
endif
<!-- -->
         </xsl:when>
			<xsl:when test="@type='structure'">
				<xsl:apply-templates select="field" mode="GET_SINGLE"/>
			</xsl:when>
			<xsl:otherwise>
 ! Get <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

<!--!!!!!!!!!!!!!!!!!!!!!!     GET RESAMPLED routines      !!!!!!!!!!!!!!!!!!!!!!!!!-->
	<xsl:template match="CPO" mode="GET_RESAMPLED">
  void euitm_get_resampled(char *path, double start, double end, double delta, <xsl:value-of select="@type"/> cpos[], int REFERENCE(maxItems), int REFERENCE(retSamples))
  {
      float *times;
      int i, dim1, dim2, dim3, status;
      float *floatArray;
      int *intArray;
      double *doubleArray;
      char *str;
      getVect1DFloatResampled(idx,path, "time", start, end, delta, REFERENCE(times), REFERENCE(retSamples));
  <xsl:apply-templates select="field" mode="GET_RESAMPLED"/>
  }
</xsl:template>
	<xsl:template match="field" mode="GET_RESAMPLED">
		<xsl:choose>
			<xsl:when test="@timed = 'yes'">
				<xsl:choose>
					<xsl:when test="@type='xs:integer'">
           status = getVect1DIntResampled(idx,path, "<xsl:value-of select="@path"/>", start, end, delta, REFERENCE(intArray), REFERENCE(dim1));
           CHECK_STATUS(status)
           ASSIGN_1D_TO_CPOS(intArray, <xsl:value-of select="translate(@path,'/','.')"/>, dim1, maxItems)
           free((char *)intArray);
        </xsl:when>
					<xsl:when test="@type='xs:boolean'">
          status = getVect1DIntResampled(idx,path, "<xsl:value-of select="@path"/>", start, end, delta, REFERENCE(intArray), REFERENCE(dim1));
          CHECK_STATUS(status)
           ASSIGN_1D_TO_CPOS(intArray, <xsl:value-of select="translate(@path,'/','.')"/>, dim1, maxItems)
           free((char *)intArray);
         </xsl:when>
					<xsl:when test="@type='xs:double'">
           status = getVect1DDoubleResampled(idx,path, "<xsl:value-of select="@path"/>", start, end, delta, REFERENCE(doubleArray), REFERENCE(dim1));
          CHECK_STATUS(status)
           ASSIGN_1D_TO_CPOS(doubleArray, <xsl:value-of select="translate(@path,'/','.')"/>, dim2, maxItems)
           free((char *)doubleArray);
         </xsl:when>
					<xsl:when test="@type='vecflt_type'">
          status = getVect2DFloatResampled(idx,path, "<xsl:value-of select="@path"/>", start, end, delta, REFERENCE(floatArray), REFERENCE(dim1), REFERENCE(dim2));
          CHECK_STATUS(status)
          ASSIGN_2D_TO_CPOS(floatArray, <xsl:value-of select="translate(@path,'/','.')"/>, dim1, dim2, maxItems)
           free((char *)floatArray);
        </xsl:when>
					<xsl:when test="@type='matflt_type'">
          status = getVect3DFloatResampled(idx,path, "<xsl:value-of select="@path"/>", start, end, delta, REFERENCE(floatArray), REFERENCE(dim1), REFERENCE(dim2), REFERENCE(dim3));
          CHECK_STATUS(status)
          ASSIGN_3D_TO_CPOS(floatArray, <xsl:value-of select="translate(@path,'/','.')"/>, dim1, dim2, dim3, maxItems)
          free((char *)floatArray);
        </xsl:when>
					<xsl:when test="@type='matint_type'">
          status = getVect3DIntResampled(idx,path, "<xsl:value-of select="@path"/>", start, end, delta, REFERENCE(intArray), REFERENCE(dim1), REFERENCE(dim2), REFERENCE(dim3));
          CHECK_STATUS(status)
          ASSIGN_3D_TO_CPOS(intArray, <xsl:value-of select="translate(@path,'/','.')"/>, dim1, dim2, dim3, maxItems)
          free((char *)intArray);
        </xsl:when>
					<xsl:when test="@type='structure'">
						<xsl:apply-templates select="field" mode="GET_RESAMPLED"/>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="@type='xs:string'">
          status = getString(idx,path, "<xsl:value-of select="@path"/>", REFERENCE(str));
          CHECK_STATUS(status)
          ASSIGN_STRING_TO_CPOS(str, <xsl:value-of select="translate(@path,'/','.')"/>, retSamples, maxItems)
          free(str);
        </xsl:when>
					<xsl:when test="@type='xs:integer'">
          status = getInt(idx,path, "<xsl:value-of select="@path"/>", REFERENCE(cpos[0].<xsl:value-of select="translate(@path,'/','.')"/>));
          CHECK_STATUS(status)
          PROPAGATE_TO_CPOS(<xsl:value-of select="translate(@path,'/','.')"/>, retSamples, maxItems)
        </xsl:when>
					<xsl:when test="@type='xs:boolean'">
          status = getInt(idx,path, "<xsl:value-of select="@path"/>", REFERENCE(cpos[0].<xsl:value-of select="translate(@path,'/','.')"/>));
          CHECK_STATUS(status)
          PROPAGATE_TO_CPOS(<xsl:value-of select="translate(@path,'/','.')"/>, retSamples, maxItems)
        </xsl:when>
					<xsl:when test="@type='xs:double'">
          status = getDouble(idx,path, "<xsl:value-of select="@path"/>", REFERENCE(cpos[0].<xsl:value-of select="translate(@path,'/','.')"/>));
          CHECK_STATUS(status)
          PROPAGATE_TO_CPOS(<xsl:value-of select="translate(@path,'/','.')"/>, retSamples, maxItems)
        </xsl:when>
					<xsl:when test="@type='vecflt_type'">
          status = getVect1DFloat(idx,path, "<xsl:value-of select="@path"/>", REFERENCE(floatArray), REFERENCE(dim1));
          CHECK_STATUS(status)
          PROPAGATE_1D_TO_CPOS(<xsl:value-of select="translate(@path,'/','.')"/>, floatArray, dim1, retSamples, maxItems)
           free((char *)floatArray);
          </xsl:when>
					<xsl:when test="@type='matflt_type'">
          status = getVect2DFloat(idx,path, "<xsl:value-of select="@path"/>", REFERENCE(floatArray), REFERENCE(dim1), REFERENCE(dim2));
          CHECK_STATUS(status)
          PROPAGATE_2D_TO_CPOS(<xsl:value-of select="translate(@path,'/','.')"/>, floatArray, dim1, dim2, retSamples, maxItems)
           free((char *)floatArray);
        </xsl:when>
					<xsl:when test="@type='matint_type'">
          status = getVect2DInt(idx,path, "<xsl:value-of select="@path"/>", REFERENCE(intArray), REFERENCE(dim1), REFERENCE(dim2));
          CHECK_STATUS(status)
          PROPAGATE_2D_TO_CPOS(<xsl:value-of select="translate(@path,'/','.')"/>, intArray, dim1, dim2, retSamples, maxItems)
           free((char *)intArray);
        </xsl:when>
					<xsl:when test="@type='structure'">
						<xsl:apply-templates select="field" mode="GET_RESAMPLED"/>
					</xsl:when>
				</xsl:choose>
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
    <xsl:when test="@type='struct_array'">
      <xsl:if test="@timed='yes' or $timed='no'">  <!-- Non-timed struct_array must not appear in the timed section -->
! Get <xsl:value-of select="@path"/>
                        <!-- for comment only -->
call get_object_from_object(idx, obj<xsl:value-of select="$level"/>, "<xsl:value-of select = "$currentobjpath"/>", i<xsl:value-of select="$level"/>, obj<xsl:value-of select="$level + 1"/>,status)
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
               <xsl:with-param name="timed" select="$timed"/>
            </xsl:apply-templates>
         enddo
      endif
   endif
endif
      </xsl:if>
    </xsl:when>

    <!--========== Regular structure ==========-->
    <xsl:when test="@type='structure'">
      <xsl:apply-templates select = "field" mode = "GET_FROM_OBJECT">
         <xsl:with-param name="level" select="$level"/>
         <xsl:with-param name="objpath" select="$currentobjpath"/>
         <xsl:with-param name="idxpath" select="$currentidxpath"/>
         <xsl:with-param name="timed" select="$timed"/>
      </xsl:apply-templates>
    </xsl:when>

    <xsl:otherwise>
      <!--========== select either timed or non-timed fields ==========-->
      <xsl:if test="@timed=$timed">
        <xsl:choose>
         <xsl:when test="@type='xs:string'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
longstring = ' '
call get_string_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,longstring,status)
if (status.EQ.0) then
   lenstring = len_trim(longstring)
   allocate(<xsl:value-of select="$currentidxpath"/>(floor(real(lenstring/132))+1))
   if (lenstring &lt;= 132) then
      <xsl:value-of select="$currentidxpath"/> = trim(longstring)
   else
      do istring=1,floor(real(lenstring/132))+1
          <xsl:value-of select="$currentidxpath"/>(istring) = trim(longstring(1+(istring-1)*132 : istring*132))
      enddo
   endif
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='vecstring_type'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1))
   call get_vect1d_string_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>, &amp;
                        <xsl:value-of select="$currentidxpath"/>,dim1,dum1,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='xs:integer'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_int_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,int0d,status)
if (status.EQ.0) then
   <xsl:value-of select="$currentidxpath"/> = int0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='xs:float'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,double0d,status)
if (status.EQ.0) then
   <xsl:value-of select="$currentidxpath"/> = double0d
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='vecflt_type'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1))
   call get_vect1d_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>, &amp;
   <xsl:value-of select="$currentidxpath"/>,dim1,dum1,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='vecint_type'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1))
   call get_vect1d_int_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>, &amp;
   <xsl:value-of select="$currentidxpath"/>,dim1,dum1,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='matflt_type'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1,dim2))
   call get_vect2d_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   dim1,dim2,dum1,dum2,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='matint_type'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1,dim2))
   call get_vect2d_int_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   dim1,dim2,dum1,dum2,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='array3dflt_type'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1,dim2,dim3))
   call get_vect3d_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,&amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='array3dint_type'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1,dim2,dim3))
   call get_vect3d_int_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,&amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   dim1,dim2,dim3,dum1,dum2,dum3,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='array4dflt_type'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1,dim2,dim3,dim4))
   call get_vect4d_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   dim1,dim2,dim3,dim4,dum1,dum2,dum3,dum4,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>

         <xsl:when test="@type='array5dflt_type'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1,dim2,dim3,dim4,dim5))
   call get_vect5d_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   dim1,dim2,dim3,dim4,dim5,dum1,dum2,dum3,dum4,dum5,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
                  <xsl:when test="@type='array6dflt_type'">
! Get <xsl:value-of select="@path"/>
            <!-- for comment only -->
call get_dimension_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,ndims,dim1,dim2,dim3,dim4,dim5,dim6,dim7)
if (dim1.GT.0) then
   allocate(<xsl:value-of select="$currentidxpath"/>(dim1,dim2,dim3,dim4,dim5,dim6))
   call get_vect6d_double_from_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   dim1,dim2,dim3,dim4,dim5,dim6,dum1,dum2,dum3,dum4,dum5,dum6,status)
   if (ual_debug =='yes') write(*,*) &amp;
      'Get <xsl:value-of select="$currentidxpath"/>'
endif
         </xsl:when>
        </xsl:choose>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

   <!--!!!!!!!!!!!!!!!!!!!!!!!!!             PUT FULL CPO ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
	<!--<xsl:template match="CPO" mode="PUT">-->


<!--!!!!!!!!!!!!!!!!!!!!!!!!!        PUT FULL TIME DEPENDENT OBJECT       !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<!--</xsl:template>-->
	<xsl:template match="field" mode="PUT_TIMED">
		<xsl:choose>
			<xsl:when test="@timed = 'yes'">
				<!-- Time dependent signals in time-dependent CPO : copy the time-dependent value from the proper index of the array of cpo structure -->
				<xsl:choose>
					<xsl:when test="@type='xs:integer'">
! Put <xsl:value-of select="@path"/>
if (any(cpos(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/>/=-999999999))  then
   allocate(vect1Dint(lentime))
   vect1DInt(1:lentime) = cpos(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/>
   call put_vect1D_int(idx,path, "<xsl:value-of select="@path"/>",&amp;
   vect1DInt,lentime,1)
   deallocate(vect1DInt)
endif
        <!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:float'">
! Put <xsl:value-of select="@path"/>
if (any(cpos(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/>/=-9.D40))  then
   allocate(vect1DDouble(lentime))
   vect1DDouble(1:lentime) = cpos(1:lentime)%<xsl:value-of select="translate(@path,'/','%')"/>
   call put_vect1D_double(idx,path, "<xsl:value-of select="@path"/>",vect1DDouble,lentime,1)
   deallocate(vect1DDouble)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='vecflt_type'">
! put <xsl:value-of select="@path"/>
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect2DDouble(size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),lentime))
   do itime=1,lentime
      vect2DDouble(:,itime) = cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect2D_Double(idx,path, "<xsl:value-of select="@path"/>",vect2DDouble, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),lentime,1)
   deallocate(vect2DDouble)
endif
<!-- -->
					</xsl:when>
               <xsl:when test="@type='vecint_type'">
! put <xsl:value-of select="@path"/>
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect2DInt(size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),lentime))
   do itime=1,lentime
      vect2DInt(:,itime) = cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect2D_Int(idx,path, "<xsl:value-of select="@path"/>",vect2DInt, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),lentime,1)
   deallocate(vect2DInt)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='matflt_type'">
! put <xsl:value-of select="@path"/>
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect3DDouble(size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),lentime))
   do itime=1,lentime
      vect3DDouble(:,:,itime)  = cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect3D_Double(idx,path, "<xsl:value-of select="@path"/>",vect3DDouble, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),lentime,1)
   deallocate(vect3DDouble)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='matint_type'">
! put <xsl:value-of select="@path"/>
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect3Dint(size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),lentime))
   do itime=1,lentime
      vect3Dint(:,:,itime)  = cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect3D_int(idx,path, "<xsl:value-of select="@path"/>",vect3Dint, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),lentime,1)
   deallocate(vect3Dint)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array3dflt_type'">
! put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect4dDouble(size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),lentime))
   do itime=1,lentime
      vect4dDouble(:,:,:,itime)  = cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect4d_Double(idx,path, "<xsl:value-of select="@path"/>",vect4dDouble, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),lentime,1)
   deallocate(vect4dDouble)
endif
<!-- -->
					</xsl:when>

					<xsl:when test="@type='array4dflt_type'">
! put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect5dDouble(size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3), &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4), lentime))
   do itime=1,lentime
      vect5dDouble(:,:,:,:,itime)  = cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect5d_Double(idx,path, "<xsl:value-of select="@path"/>",vect5dDouble, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   lentime,1)
   deallocate(vect5dDouble)
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array5dflt_type'">
! put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(vect6dDouble(size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3), &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4), &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,5), lentime))
   do itime=1,lentime
      vect6dDouble(:,:,:,:,:,itime)  = cpos(itime)%<xsl:value-of select="translate(@path,'/','%')"/>
   enddo
   call put_vect6d_Double(idx,path, "<xsl:value-of select="@path"/>",vect6dDouble, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,5),lentime,1)
   deallocate(vect6dDouble)
endif
<!-- -->
					</xsl:when>
               <xsl:when test="@type='struct_array'">
! Write timed fields    */
call begin_object(idx,-1,1,path//"/<xsl:value-of select = "@path"/>",TIMED_CLEAR,obj_all_times)
do itime = 1,lentime
   call begin_object(idx,obj_all_times,itime,"ALLTIMES",TIMED,obj1)
   if (associated(cpos(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
      do i1 = 1,size(cpos(itime)%<xsl:value-of select = "translate(@path,'/','%')"/>)
         <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
               <xsl:with-param name="level" select="1"/>
               <xsl:with-param name="objpath" select="@name"/>
               <xsl:with-param name="idxpath" select="concat('cpos(itime)%',translate(@path,'/','%'),'(i1)')"/>
               <xsl:with-param name="timed" select="'yes'"/>
         </xsl:apply-templates>
      enddo
   endif
   call put_object_in_object(idx,obj_all_times,"ALLTIMES",itime,obj1)
enddo
call put_object(idx,path,"<xsl:value-of select = "@path"/>",obj_all_times,1)

! Write non-timed fields    */
call begin_object(idx,-1,1,path//"/<xsl:value-of select = "@path"/>",NON_TIMED,obj1)
if (associated(cpos(1)%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
   do i1 = 1,size(cpos(1)%<xsl:value-of select = "translate(@path,'/','%')"/>)
      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="objpath" select="@name"/>
         <xsl:with-param name="idxpath" select="concat('cpos(1)%',translate(@path,'/','%'),'(i1)')"/>
         <xsl:with-param name="timed" select="'no'"/>
      </xsl:apply-templates>
   enddo
endif
call put_object(idx,path,"<xsl:value-of select = "@path"/>",obj1,0)
               </xsl:when>

					<xsl:when test="@type='structure'">
						<xsl:apply-templates select="field" mode="PUT_TIMED"/>
					</xsl:when>
					<xsl:otherwise>
 ! Get <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!!
        </xsl:otherwise>
				</xsl:choose>
			</xsl:when>

			<xsl:otherwise>
				<!-- Time independent signals in time-dependent CPO : the first index cpos(1) defines the value of the time-independent data -->
				<xsl:choose>
               <xsl:when test="@type='struct_array'">
! Put <xsl:value-of select="@path"/>
                  <!-- for comment only -->
! Write non-timed fields    */
call begin_object(idx,-1,1,path//"/<xsl:value-of select = "@path"/>",NON_TIMED,obj1)
if (associated(cpos(1)%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
   do i1 = 1,size(cpos(1)%<xsl:value-of select = "translate(@path,'/','%')"/>)
      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="objpath" select="@name"/>
         <xsl:with-param name="idxpath" select="concat('cpos(1)%',translate(@path,'/','%'),'(i1)')"/>
         <xsl:with-param name="timed" select="'no'"/>
      </xsl:apply-templates>
   enddo
endif
call put_object(idx,path,"<xsl:value-of select = "@path"/>",obj1,0)
               </xsl:when>
					<xsl:when test="@type='structure'">
						<xsl:apply-templates select="field" mode="PUT_TIMED"/>
					</xsl:when>
					<xsl:when test="@type='xs:string'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   longstring = ' '    <!-- Initialisation of longstring, otherwise strange problems occur !-->
   lenstring = size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)
   if (lenstring.EQ.1) then
      longstring = trim(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>(1))
   else
      do istring=1,lenstring
          longstring(1+(istring-1)*132 : istring*132) = cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>(istring)
      enddo
   endif
   call put_string(idx,path, "<xsl:value-of select="@path"/>",trim(longstring))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='vecstring_type'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   dim1 = size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)
   allocate(dimtab(dim1))
   do i=1,dim1
      dimtab(i) = len_trim(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>(i))
   enddo
   call put_Vect1d_String(idx,path, "<xsl:value-of select="@path"/>", &amp;
         cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,dim1,dimtab,0)
   deallocate(dimtab)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:integer'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>.NE.-999999999) then
   call put_int(idx,path, "<xsl:value-of select="@path"/>",cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:float'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>.NE.-9.D40) then
   call put_double(idx,path, "<xsl:value-of select="@path"/>",cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='vecflt_type'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect1d_double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='vecint_type'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect1d_int(idx,path, "<xsl:value-of select="@path"/>",&amp;
   cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='matflt_type'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect2d_double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),0)
   if (ual_debug =='yes') write(*,*) &amp;
       'Put cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='matint_type'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect2d_int(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1), &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array3dflt_type'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect3d_double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1), &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array3dint_type'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect3d_int(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1), &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array4dflt_type'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect4d_double(idx,path, "<xsl:value-of select="@path"/>",cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
					</xsl:when>
<xsl:when test="@type='array5dflt_type'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect5d_double(idx,path, "<xsl:value-of select="@path"/>",cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,5),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
</xsl:when>
<xsl:when test="@type='array6dflt_type'">
! Put <xsl:value-of select="@path"/>
						<!-- for comment only -->
if (associated(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect6d_double(idx,path, "<xsl:value-of select="@path"/>",cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,3),size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,5),size(cpos(1)%<xsl:value-of select="translate(@path,'/','%')"/>,6),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpos%<xsl:value-of select="translate(@path,'/','%')"/>'
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

<!--!!!!!!!!!!!!!!!!!!!!!!!!!        PUT SINGLE CPO       !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="PUT_SINGLE">
		<!-- to put an element from a CPO which is NOT time-dependent : easy : elementary PUT -->
      <xsl:if test="@timed='no' or @type='structure' or @type='struct_array'">  <!-- discard timed fields so that we can use it as PUT_NON_TIMED -->
		<xsl:choose>
			<xsl:when test="@type='structure'">
				<xsl:apply-templates select="field" mode="PUT_SINGLE"/>
			</xsl:when>
         <xsl:when test="@type='struct_array'">
! Put <xsl:value-of select="@path"/>
                  <!-- for comment only -->
! Write non-timed fields    */
call begin_object(idx,-1,1,path//"/<xsl:value-of select = "@path"/>",NON_TIMED,obj1)
if (associated(cpo%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
   do i1 = 1,size(cpo%<xsl:value-of select = "translate(@path,'/','%')"/>)
      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="objpath" select="@name"/>
         <xsl:with-param name="idxpath" select="concat('cpo%',translate(@path,'/','%'),'(i1)')"/>
         <xsl:with-param name="timed" select="'no'"/>
      </xsl:apply-templates>
   enddo
endif
call put_object(idx,path,"<xsl:value-of select = "@path"/>",obj1,0)
         </xsl:when>
			<xsl:when test="@type='xs:string'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   longstring = ' '    <!-- Initialisation of longstring, otherwise strange problems occur !-->
   lenstring = size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)
   if (lenstring.EQ.1) then
      longstring = trim(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(1))
   else
      do istring=1,lenstring
          longstring(1+(istring-1)*132 : istring*132) = cpo%<xsl:value-of select="translate(@path,'/','%')"/>(istring)
      enddo
   endif
   call put_string(idx,path, "<xsl:value-of select="@path"/>",trim(longstring))       ! should clean up longstring after that, or send to the put only the right length, which has been updated
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='vecstring_type'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   dim1 = size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)
   allocate(dimtab(dim1))
   do i=1,dim1
      dimtab(i) = len_trim(cpo%<xsl:value-of select="translate(@path,'/','%')"/>(i))
   enddo
   call put_Vect1d_String(idx,path, "<xsl:value-of select="@path"/>", &amp;
         cpo%<xsl:value-of select="translate(@path,'/','%')"/>,dim1,dimtab,0)
   deallocate(dimtab)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='xs:integer'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (cpo%<xsl:value-of select="translate(@path,'/','%')"/>.NE.-999999999) then
   call put_int(idx,path, "<xsl:value-of select="@path"/>",cpo%<xsl:value-of select="translate(@path,'/','%')"/>)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='xs:float'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (cpo%<xsl:value-of select="translate(@path,'/','%')"/>.NE.-9.D40) then
   call put_double(idx,path, "<xsl:value-of select="@path"/>",cpo%<xsl:value-of select="translate(@path,'/','%')"/>)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='vecflt_type'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect1d_double(idx,path, "<xsl:value-of select="@path"/>",&amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='vecint_type'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect1d_int(idx,path, "<xsl:value-of select="@path"/>",&amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='matflt_type'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect2d_double(idx,path, "<xsl:value-of select="@path"/>",&amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='matint_type'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect2d_int(idx,path, "<xsl:value-of select="@path"/>",&amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1), &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='array3dflt_type'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect3d_double(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,3),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='array3dint_type'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect3d_int(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,3),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='array4dflt_type'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect4d_double(idx,path, "<xsl:value-of select="@path"/>",cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,3),size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,4),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
         <xsl:when test="@type='array5dflt_type'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect5d_double(idx,path, "<xsl:value-of select="@path"/>",cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,3),size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,5),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
         <xsl:when test="@type='array6dflt_type'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect6d_double(idx,path, "<xsl:value-of select="@path"/>",cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1),size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,3),size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,4),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,5),size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,6),0)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>

			<xsl:otherwise>
 ! Put <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
			</xsl:otherwise>
		</xsl:choose>
   </xsl:if>
</xsl:template>

	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             PUT_SLICE CPO ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
	<!--<xsl:template match="CPO" mode="PUT_SLICE">

</xsl:template>-->
	<xsl:template match="field" mode="PUT_SLICE">
		<!-- to put (append) one time slice of a time-dependent element from a time-dependent CPO (very similar to PUT_SINGLE, but deals only with time-dependent elements, and isTimed = 1 in the individual type put -->
		<xsl:choose>
			<xsl:when test="@type='structure'">
				<xsl:apply-templates select="field" mode="PUT_SLICE"/>
			</xsl:when>
         <xsl:when test="@type='struct_array' and @timed='yes'">
! Put <xsl:value-of select="@path"/>
                  <!-- for comment only -->
! timed arrays of structures must be put inside a time container, even if there is a single time */
call begin_object(idx,-1,1,path//"/<xsl:value-of select = "@path"/>",TIMED,obj_single_time);
call begin_object(idx,obj_single_time,1,"ALLTIMES",TIMED,obj1)
if (associated(cpo%<xsl:value-of select = "translate(@path,'/','%')"/>)) then
   do i1 = 1,size(cpo%<xsl:value-of select = "translate(@path,'/','%')"/>)
      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
         <xsl:with-param name="level" select="1"/>
         <xsl:with-param name="objpath" select="@name"/>
         <xsl:with-param name="idxpath" select="concat('cpo%',translate(@path,'/','%'),'(i1)')"/>
         <xsl:with-param name="timed" select="'yes'"/>
      </xsl:apply-templates>
   enddo
endif
call put_object_in_object(idx,obj_single_time,"ALLTIMES",1,obj1);
call put_object_slice(idx,path,"<xsl:value-of select="@path"/>",cpo%time,obj_single_time);
         </xsl:when>
			<xsl:when test="@type='xs:string' and @timed='yes'">
! Put <xsl:value-of select="@path"/>  ERROR : NO TIME DEPENDENT STRING EXPECTED IN THE DATA STRUCTURE
<!-- -->
			</xsl:when>
			<xsl:when test="@type='vecstring_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>  ERROR : NO TIME DEPENDENT VECSTRING EXPECTED IN THE DATA STRUCTURE
<!-- -->
			</xsl:when>
			<xsl:when test="@type='xs:integer'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (cpo%<xsl:value-of select="translate(@path,'/','%')"/>.NE.-999999999) then
   call put_int_slice(idx,path, "<xsl:value-of select="@path"/>",cpo%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   cpo%time)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='xs:float'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (cpo%<xsl:value-of select="translate(@path,'/','%')"/>.NE.-9.D40) then
   call put_double_slice(idx,path, "<xsl:value-of select="@path"/>",cpo%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   cpo%time)
   if (ual_debug =='yes') write(*,*) &amp;
       'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='vecflt_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect1d_double_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>),cpo%time)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',&amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='vecint_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect1d_int_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>,&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>),cpo%time)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='matflt_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect2d_double_slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2),cpo%time)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='matint_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect2d_int_slice(idx,path, "<xsl:value-of select="@path"/>",&amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1), &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2),cpo%time)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='array3dflt_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect3d_double_slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,3),cpo%time)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='array3dint_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect3d_int_slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,3),cpo%time)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>',cpo%<xsl:value-of select="translate(@path,'/','%')"/>
endif
<!-- -->
			</xsl:when>
			<xsl:when test="@type='array4dflt_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
				<!-- for comment only -->
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect4d_double_slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,3), &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,4),cpo%time)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
						<xsl:when test="@type='array5dflt_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect5d_double_slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,3), &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,4), &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,5),cpo%time)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>
									<xsl:when test="@type='array6dflt_type'  and @timed='yes'">
! Put <xsl:value-of select="@path"/>
if (associated(cpo%<xsl:value-of select="translate(@path,'/','%')"/>)) then
   call put_vect6d_double_slice(idx,path, "<xsl:value-of select="@path"/>", &amp;
   cpo%<xsl:value-of select="translate(@path,'/','%')"/>, &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,1),&amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,2), &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,3), &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,4), &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,5), &amp;
   size(cpo%<xsl:value-of select="translate(@path,'/','%')"/>,6),cpo%time)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put cpo%<xsl:value-of select="translate(@path,'/','%')"/>'
endif
<!-- -->
			</xsl:when>

		</xsl:choose>
	</xsl:template>

	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             PUT NON TIMED CPO ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
	<!--<xsl:template match="CPO" mode="PUT_NON_TIMED">

</xsl:template>-->

<!--!!!!!!!!!!!!!!!!!!!!!!!!!        PUT IN OBJECT       !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<xsl:template match="field" mode="PUT_IN_OBJECT">
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
    <xsl:when test="@type='struct_array'">

      <xsl:if test="@timed='yes' or $timed='no'">  <!-- Non-timed struct_array must not appear in the timed section -->
! Put <xsl:value-of select="@path"/>
                        <!-- for comment only -->

      <!-- OH fix -->
      <xsl:choose>
        <xsl:when test="$timed='yes'">
call begin_object(idx,obj<xsl:value-of select="$level"/>,i<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",TIMED,obj<xsl:value-of select="$level + 1"/>)
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   do i<xsl:value-of select="$level + 1"/> = 1,size(<xsl:value-of select="$currentidxpath"/>)
      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
         <xsl:with-param name="level" select="$level + 1"/>
         <xsl:with-param name="objpath" select="@name"/>
         <xsl:with-param name="idxpath" select="concat($currentidxpath,'(i',$level + 1,')')"/>
         <xsl:with-param name="timed" select="$timed"/>
      </xsl:apply-templates>
   enddo
endif
call put_object_in_object(idx,obj<xsl:value-of select="$level"/>, "<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>, obj<xsl:value-of select="$level + 1"/>);
        </xsl:when>
        <xsl:otherwise>
call begin_object(idx,obj<xsl:value-of select="$level"/>,i<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",NON_TIMED,obj<xsl:value-of select="$level + 1"/>)
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   do i<xsl:value-of select="$level + 1"/> = 1,size(<xsl:value-of select="$currentidxpath"/>)
      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
         <xsl:with-param name="level" select="$level + 1"/>
         <xsl:with-param name="objpath" select="@name"/>
         <xsl:with-param name="idxpath" select="concat($currentidxpath,'(i',$level + 1,')')"/>
         <xsl:with-param name="timed" select="$timed"/>
      </xsl:apply-templates>
   enddo
endif
call put_object_in_object(idx,obj<xsl:value-of select="$level"/>, "<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>, obj<xsl:value-of select="$level + 1"/>);
        </xsl:otherwise>
      </xsl:choose>

      </xsl:if>

    </xsl:when>

    <!--========== Regular structure ==========-->
    <xsl:when test="@type='structure'">
      <xsl:apply-templates select = "field" mode = "PUT_IN_OBJECT">
        <xsl:with-param name="level" select="$level"/>
        <xsl:with-param name="objpath" select="$currentobjpath"/>
        <xsl:with-param name="idxpath" select="$currentidxpath"/>
        <xsl:with-param name="timed" select="$timed"/>
      </xsl:apply-templates>
    </xsl:when>

    <!--========== select either timed or non-timed fields ==========-->
    <xsl:otherwise>
      <xsl:if test="@timed=$timed">
        <xsl:choose>
         <xsl:when test="@type='xs:string'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   longstring = ' '    <!-- Initialisation of longstring, otherwise strange problems occur !-->
   lenstring = size(<xsl:value-of select="$currentidxpath"/>)
   if (lenstring.EQ.1) then
      longstring = trim(<xsl:value-of select="$currentidxpath"/>(1))
   else
      do istring=1,lenstring
          longstring(1+(istring-1)*132 : istring*132) = <xsl:value-of select="$currentidxpath"/>(istring)
      enddo
   endif
   call put_string_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,trim(longstring))       ! should clean up longstring after that, or send to the put only the right length, which has been updated
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='vecstring_type'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   dim1 = size(<xsl:value-of select="$currentidxpath"/>)
   allocate(dimtab(dim1))
   do i=1,dim1
      dimtab(i) = len_trim(<xsl:value-of select="$currentidxpath"/>(i))
   enddo
   call put_vect1d_string_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>, &amp;
         <xsl:value-of select="$currentidxpath"/>,dim1,dimtab)
   deallocate(dimtab)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='xs:integer'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (<xsl:value-of select="$currentidxpath"/>.NE.-999999999) then
   call put_int_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,<xsl:value-of select="$currentidxpath"/>)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='xs:float'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (<xsl:value-of select="$currentidxpath"/>.NE.-9.D40) then
   call put_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,<xsl:value-of select="$currentidxpath"/>)
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='vecflt_type'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect1d_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,&amp;
   <xsl:value-of select="$currentidxpath"/>,&amp;
   size(<xsl:value-of select="$currentidxpath"/>))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='vecint_type'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect1d_int_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,&amp;
   <xsl:value-of select="$currentidxpath"/>,&amp;
   size(<xsl:value-of select="$currentidxpath"/>))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='matflt_type'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect2d_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,&amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   size(<xsl:value-of select="$currentidxpath"/>,1),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,2))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='matint_type'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect2d_int_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,&amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   size(<xsl:value-of select="$currentidxpath"/>,1), &amp;
   size(<xsl:value-of select="$currentidxpath"/>,2))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='array3dflt_type'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect3d_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   size(<xsl:value-of select="$currentidxpath"/>,1),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,2), &amp;
   size(<xsl:value-of select="$currentidxpath"/>,3))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>'
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='array3dint_type'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect3d_int_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>, &amp;
   <xsl:value-of select="$currentidxpath"/>, &amp;
   size(<xsl:value-of select="$currentidxpath"/>,1),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,2),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,3))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
         <xsl:when test="@type='array4dflt_type'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect4d_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,<xsl:value-of select="$currentidxpath"/>, &amp;
   size(<xsl:value-of select="$currentidxpath"/>,1),size(<xsl:value-of select="$currentidxpath"/>,2),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,3),size(<xsl:value-of select="$currentidxpath"/>,4))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>
                  <xsl:when test="@type='array5dflt_type'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect5d_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,<xsl:value-of select="$currentidxpath"/>, &amp;
   size(<xsl:value-of select="$currentidxpath"/>,1),size(<xsl:value-of select="$currentidxpath"/>,2),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,3),size(<xsl:value-of select="$currentidxpath"/>,4),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,5))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>


                  <xsl:when test="@type='array6dflt_type'">
! Put <xsl:value-of select="@path"/>
            <!-- for comment only -->
if (associated(<xsl:value-of select="$currentidxpath"/>)) then
   call put_vect6d_double_in_object(idx,obj<xsl:value-of select="$level"/>,"<xsl:value-of select="$currentobjpath"/>",i<xsl:value-of select="$level"/>,<xsl:value-of select="$currentidxpath"/>, &amp;
   size(<xsl:value-of select="$currentidxpath"/>,1),size(<xsl:value-of select="$currentidxpath"/>,2),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,3),size(<xsl:value-of select="$currentidxpath"/>,4),&amp;
   size(<xsl:value-of select="$currentidxpath"/>,5),size(<xsl:value-of select="$currentidxpath"/>,6))
   if (ual_debug =='yes') write(*,*) &amp;
      'Put <xsl:value-of select="$currentidxpath"/>',<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
         </xsl:when>

         <xsl:otherwise>
 ! Put <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
         </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
   </xsl:otherwise>
 </xsl:choose>
</xsl:template>

	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             DELETE CPO ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
	<!--<xsl:template match="CPO" mode="DELETE">

</xsl:template>-->
	<xsl:template match="field" mode="DELETE">
		<xsl:choose>
			<xsl:when test="@type='structure'">
				<!-- If the node is a substructure, call delete recursively on the children -->
				<xsl:apply-templates select="field" mode="DELETE"/>
			</xsl:when>
			<xsl:otherwise>
call delete_data(idx,cpopath,"<xsl:value-of select="@path"/>")         <!-- call to the low level delete_data routine -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             DEALLOCATE CPO ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
<!--<xsl:template match="CPO" mode="DEALLOCATE">

</xsl:template>-->


<xsl:template match="field" mode="DEALLOCATE">
    <xsl:param name="level"/>     <!-- recursion level -->
    <xsl:param name="idxpath"/>   <!-- full fortran path including indices -->

    <!-- build the complete path of the current field -->
    <xsl:param name="currentidxpath" select="concat($idxpath,'%',@name)"/>

    <xsl:choose>
<!-- xs:integer and xs:float are not deallocated (they are not allocatable !) -->
			<xsl:when test="@type='vecflt_type' or @type='vecint_type' or @type='matflt_type' or @type='matint_type' or @type='array3dflt_type' or @type='array4dflt_type' or @type='xs:string' or @type='vecstring_type'">
   ! deallocate <xsl:value-of select="@path"/>
   if (associated(<xsl:value-of select="$currentidxpath"/>)) then
        deallocate(<xsl:value-of select="$currentidxpath"/>)
   endif
   			</xsl:when>
			<xsl:when test="@type='structure'">
				<xsl:apply-templates select="field" mode="DEALLOCATE">
                <xsl:with-param name="level" select="$level"/>
                <xsl:with-param name="idxpath" select="$currentidxpath"/>
            </xsl:apply-templates>
			</xsl:when>
         <xsl:when test="@type='struct_array'">
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


	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             COPY CPO ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
	<!--<xsl:template match="CPO" mode="COPY">

</xsl:template>-->

	<xsl:template match="field" mode="COPY_TIMED">
      <xsl:param name="level"/>     <!-- recursion level -->
      <xsl:param name="idxpath"/>   <!-- full fortran path including indices -->

      <!-- build the complete path of the current field -->
      <xsl:param name="currentidxpath" select="concat($idxpath,'%',@name)"/>

		<xsl:choose>
			<xsl:when test="@timed = 'yes'">
				<!-- Time dependent signals in time-dependent CPO : copy the time-dependent value from the proper index of the array of cpo structure -->
				<xsl:choose>
					<xsl:when test="@type='xs:integer'">
! Copy <xsl:value-of select="@path"/>
if (cpoin(itime)<xsl:value-of select="$currentidxpath"/>/=-999999999)  then
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(itime)<xsl:value-of select="$currentidxpath"/>
endif
        <!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:float'">
! Copy <xsl:value-of select="@path"/>
if (cpoin(itime)<xsl:value-of select="$currentidxpath"/>/=-9.D40)  then
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(itime)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='vecflt_type' or @type='vecint_type' ">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(itime)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/> &amp;
   (size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,1)))
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(itime)<xsl:value-of select="$currentidxpath"/>
endif
					</xsl:when>
					<xsl:when test="@type='matflt_type' or @type='matint_type' ">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(itime)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/>&amp;
   (size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,1), &amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,2)))
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(itime)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array3dflt_type' or @type='array3dint_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(itime)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/>&amp;
   (size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,1), &amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,2),&amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,3)))
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(itime)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array4dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(itime)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/>&amp;
   (size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,1), &amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,2),&amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,3),&amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,4)))
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(itime)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array5dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(itime)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/>&amp;
   (size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,1), &amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,2),&amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,3),&amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,4),&amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,5)))
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(itime)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>


					<xsl:when test="@type='array6dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(itime)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/>&amp;
   (size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,1), &amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,2),&amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,3),&amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,4),&amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,5),&amp;
   size(cpoin(itime)<xsl:value-of select="$currentidxpath"/>,6)))
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(itime)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>

               <xsl:when test="@type='struct_array'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(itime)<xsl:value-of select = "$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/>(size(cpoin(itime)<xsl:value-of select = "$currentidxpath"/>)))
   do i<xsl:value-of select="$level"/> = 1,size(cpoin(itime)<xsl:value-of select = "$currentidxpath"/>)
      <xsl:apply-templates select = "field" mode = "COPY_TIMED">
         <xsl:with-param name="level" select="$level + 1"/>
         <xsl:with-param name="idxpath" select="concat($currentidxpath,'(i',$level,')')"/>
      </xsl:apply-templates>
   enddo
endif
               </xsl:when>
               <xsl:when test="@type='structure'">
						<xsl:apply-templates select="field" mode="COPY_TIMED">
                     <xsl:with-param name="level" select="$level"/>
                     <xsl:with-param name="idxpath" select="$currentidxpath"/>
                  </xsl:apply-templates>
					</xsl:when>
					<xsl:otherwise>
 ! Copy <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!!
        </xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<!-- Time independent signals in time-dependent CPO : the first index cpos(1) defines the value of the time-independent data -->
				<xsl:choose>
               <xsl:when test="@type='struct_array'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select = "$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/>(size(cpoin(1)<xsl:value-of select = "$currentidxpath"/>)))
   do i<xsl:value-of select="$level"/> = 1,size(cpoin(1)<xsl:value-of select = "$currentidxpath"/>)
      <xsl:apply-templates select = "field" mode = "COPY_TIMED">
         <xsl:with-param name="level" select="$level + 1"/>
         <xsl:with-param name="idxpath" select="concat($currentidxpath,'(i',$level,')')"/>
      </xsl:apply-templates>
   enddo
endif
               </xsl:when>
					<xsl:when test="@type='structure'">
                  <xsl:apply-templates select="field" mode="COPY_TIMED">
                     <xsl:with-param name="level" select="$level"/>
                     <xsl:with-param name="idxpath" select="$currentidxpath"/>
                  </xsl:apply-templates>
					</xsl:when>
					<xsl:when test="@type='xs:string' or @type='vecstring_type' or @type='vecflt_type' or @type='vecint_type' ">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/>&amp;
   (size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,1)))
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/> <!-- copy first time index to all indices -->
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:integer'">
! Copy <xsl:value-of select="@path"/>
if (cpoin(1)<xsl:value-of select="$currentidxpath"/>/=-999999999)  then
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:float'">
! Copy <xsl:value-of select="@path"/>
if (cpoin(1)<xsl:value-of select="$currentidxpath"/>.NE.-9.D40) then
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='matflt_type' or @type='matint_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/>&amp;
   (size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,1), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,2)))
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/> <!-- copy first time index to all indices -->
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array3dflt_type' or @type='array3dint_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/>&amp;
   (size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,1), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,2), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,3)))
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/> <!-- copy first time index to all indices -->
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array4dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/>&amp;
   (size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,1), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,2), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,3), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,4)))
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/> <!-- copy first time index to all indices -->
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array5dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/>&amp;
   (size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,1), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,2), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,3), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,4), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,5)))
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/> <!-- copy first time index to all indices -->
endif
<!-- -->
					</xsl:when>
										<xsl:when test="@type='array6dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(itime)<xsl:value-of select="$currentidxpath"/>&amp;
   (size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,1), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,2), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,3), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,4), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,5), &amp;
   size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,6)))
   cpoout(itime)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/> <!-- copy first time index to all indices -->
endif
<!-- -->
					</xsl:when>

					<xsl:otherwise>
 ! Copy <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="field" mode="COPY_NON_TIMED">
		<!-- copy an element from a CPO which is NOT time-dependent  -->
      <xsl:param name="level"/>     <!-- recursion level -->
      <xsl:param name="idxpath"/>   <!-- full fortran path including indices -->

      <!-- build the complete path of the current field -->
      <xsl:param name="currentidxpath" select="concat($idxpath,'%',@name)"/>

		<xsl:choose>
         <xsl:when test="@type='struct_array'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select = "$currentidxpath"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>(size(cpoin<xsl:value-of select = "$currentidxpath"/>)))
   do i<xsl:value-of select="$level"/> = 1,size(cpoin<xsl:value-of select = "$currentidxpath"/>)
      <xsl:apply-templates select = "field" mode = "COPY_NON_TIMED">
         <xsl:with-param name="level" select="$level + 1"/>
         <xsl:with-param name="idxpath" select="concat($currentidxpath,'(i',$level,')')"/>
      </xsl:apply-templates>
   enddo
endif
         </xsl:when>
			<xsl:when test="@type='structure'">
        <xsl:apply-templates select = "field" mode = "COPY_NON_TIMED">
          <xsl:with-param name="level" select="$level"/>
          <xsl:with-param name="idxpath" select="$currentidxpath"/>
        </xsl:apply-templates>
			</xsl:when>
			<xsl:when test="@type='xs:string' or @type='vecstring_type' or @type='vecflt_type' or @type='vecint_type' ">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin<xsl:value-of select="$currentidxpath"/>,1)))
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:integer'">
! Copy <xsl:value-of select="@path"/>
if (cpoin<xsl:value-of select="$currentidxpath"/>/=-999999999)  then
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:float'">
! Copy <xsl:value-of select="@path"/>
if (cpoin<xsl:value-of select="$currentidxpath"/>.NE.-9.D40) then
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='matflt_type' or @type='matint_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,2)))
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array3dflt_type' or @type='array3dint_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,3)))
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array4dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,3), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,4)))
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
										<xsl:when test="@type='array5dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,3), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,4), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,5)))
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
															<xsl:when test="@type='array6dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,3), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,4), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,5), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,6)))
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
			<xsl:otherwise>
 ! Copy <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>



	<xsl:template match="field" mode="COPY_TIMED_POINTER2SLICE">
      <xsl:param name="level"/>     <!-- recursion level -->
      <xsl:param name="idxpath"/>   <!-- full fortran path including indices -->

      <!-- build the complete path of the current field -->
      <xsl:param name="currentidxpath" select="concat($idxpath,'%',@name)"/>

		<xsl:choose>
         <xsl:when test="@type='struct_array'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select = "$currentidxpath"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>(size(cpoin(1)<xsl:value-of select = "$currentidxpath"/>)))
   do i<xsl:value-of select="$level"/> = 1,size(cpoin(1)<xsl:value-of select = "$currentidxpath"/>)
      <xsl:apply-templates select = "field" mode = "COPY_TIMED_POINTER2SLICE">
         <xsl:with-param name="level" select="$level + 1"/>
         <xsl:with-param name="idxpath" select="concat($currentidxpath,'(i',$level,')')"/>
      </xsl:apply-templates>
   enddo
endif
         </xsl:when>
			<xsl:when test="@type='structure'">
        <xsl:apply-templates select = "field" mode = "COPY_TIMED_POINTER2SLICE">
          <xsl:with-param name="level" select="$level"/>
          <xsl:with-param name="idxpath" select="$currentidxpath"/>
        </xsl:apply-templates>
			</xsl:when>
			<xsl:when test="@type='xs:string' or @type='vecstring_type' or @type='vecflt_type' or @type='vecint_type' ">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,1)))
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:integer'">
! Copy <xsl:value-of select="@path"/>
if (cpoin(1)<xsl:value-of select="$currentidxpath"/>/=-999999999)  then
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:float'">
! Copy <xsl:value-of select="@path"/>
if (cpoin(1)<xsl:value-of select="$currentidxpath"/>.NE.-9.D40) then
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='matflt_type' or @type='matint_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,2)))
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array3dflt_type' or @type='array3dint_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,3)))
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array4dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,3), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,4)))
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
										<xsl:when test="@type='array5dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,3), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,4), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,5)))
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
															<xsl:when test="@type='array6dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin(1)<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,3), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,4), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,5), &amp;
      size(cpoin(1)<xsl:value-of select="$currentidxpath"/>,6)))
   cpoout<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin(1)<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
			<xsl:otherwise>
 ! Copy <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


<xsl:template match="field" mode="COPY_TIMED_SLICE2POINTER">
      <xsl:param name="level"/>     <!-- recursion level -->
      <xsl:param name="idxpath"/>   <!-- full fortran path including indices -->

      <!-- build the complete path of the current field -->
      <xsl:param name="currentidxpath" select="concat($idxpath,'%',@name)"/>

		<xsl:choose>
         <xsl:when test="@type='struct_array'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select = "$currentidxpath"/>)) then  <!-- assumes that either all time indices are associated, or none-->
   allocate(cpoout(1)<xsl:value-of select="$currentidxpath"/>(size(cpoin<xsl:value-of select = "$currentidxpath"/>)))
   do i<xsl:value-of select="$level"/> = 1,size(cpoin<xsl:value-of select = "$currentidxpath"/>)
      <xsl:apply-templates select = "field" mode = "COPY_TIMED_SLICE2POINTER">
         <xsl:with-param name="level" select="$level + 1"/>
         <xsl:with-param name="idxpath" select="concat($currentidxpath,'(i',$level,')')"/>
      </xsl:apply-templates>
   enddo
endif
         </xsl:when>
			<xsl:when test="@type='structure'">
        <xsl:apply-templates select = "field" mode = "COPY_TIMED_SLICE2POINTER">
          <xsl:with-param name="level" select="$level"/>
          <xsl:with-param name="idxpath" select="$currentidxpath"/>
        </xsl:apply-templates>
			</xsl:when>
			<xsl:when test="@type='xs:string' or @type='vecstring_type' or @type='vecflt_type' or @type='vecint_type' ">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(1)<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin<xsl:value-of select="$currentidxpath"/>,1)))
   cpoout(1)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:integer'">
! Copy <xsl:value-of select="@path"/>
if (cpoin<xsl:value-of select="$currentidxpath"/>/=-999999999)  then
   cpoout(1)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='xs:float'">
! Copy <xsl:value-of select="@path"/>
if (cpoin<xsl:value-of select="$currentidxpath"/>.NE.-9.D40) then
   cpoout(1)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='matflt_type' or @type='matint_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(1)<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,2)))
   cpoout(1)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array3dflt_type' or @type='array3dint_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(1)<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,3)))
   cpoout(1)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
					<xsl:when test="@type='array4dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(1)<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,3), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,4)))
   cpoout(1)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
										<xsl:when test="@type='array5dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(1)<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,3), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,4), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,5)))
   cpoout(1)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
															<xsl:when test="@type='array6dflt_type'">
! Copy <xsl:value-of select="@path"/>
if (associated(cpoin<xsl:value-of select="$currentidxpath"/>)) then
   allocate(cpoout(1)<xsl:value-of select="$currentidxpath"/>&amp;
      (size(cpoin<xsl:value-of select="$currentidxpath"/>,1), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,2), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,3), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,4), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,5), &amp;
      size(cpoin<xsl:value-of select="$currentidxpath"/>,6)))
   cpoout(1)<xsl:value-of select="$currentidxpath"/> = &amp;
   cpoin<xsl:value-of select="$currentidxpath"/>
endif
<!-- -->
					</xsl:when>
			<xsl:otherwise>
 ! Copy <xsl:value-of select="@path"/> : PROBLEM : UNIDENTIFIED TYPE !!! <!-- for comment only -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             FLUSH CPO ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
	<!--<xsl:template match="CPO" mode="FLUSH_CACHE">
        </xsl:template>-->
	<xsl:template match="field" mode="FLUSH_CACHE">
		<xsl:choose>
			<xsl:when test="@type='structure'">
				<!-- If the node is a substructure, call flush recursively on the children -->
				<xsl:apply-templates select="field" mode="FLUSH_CACHE"/>
			</xsl:when>
			<xsl:otherwise>
call euitm_flush_cache(idx,cpopath,"<xsl:value-of select="@path"/>")         <!-- call to the low level euitm_flush_cache routine -->
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!--!!!!!!!!!!!!!!!!!!!!!!!!!             DISCARD CPO ROUTINES           !!!!!!!!!!!!!!!!!!!!!!!!!!!!! -->
	<!--<xsl:template match="CPO" mode="DISCARD_CACHE">


</xsl:template>-->
	<xsl:template match="field" mode="DISCARD_CACHE">
		<xsl:choose>
			<xsl:when test="@type='structure'">
				<!-- If the node is a substructure, call delete recursively on the children -->
				<xsl:apply-templates select="field" mode="DISCARD_CACHE"/>
			</xsl:when>
			<xsl:otherwise>
call euitm_discard_cache(idx,cpopath,"<xsl:value-of select="@path"/>")         <!-- call to the low level euitm_discard_cache routine -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


</xsl:stylesheet>
