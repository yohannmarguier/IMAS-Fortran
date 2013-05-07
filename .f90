
module _ids_module
! Declaration of the generic IDS GET routine 

interface ids_get        
   module procedure ids_get_
end interface ids_get   

! Declaration of the generic IDS GET_SLICE routine 
interface ids_get_slice        
   module procedure  ids_get_slice_
end interface ids_get_slice

! Declaration of the generic IDS PUT routine 
interface ids_put        
   module procedure ids_put_		
end interface ids_put

! Declaration of the generic IDS PUT_NON_TIMED routine 
interface ids_put_non_timed        
   module procedure ids_put_		 
end interface ids_put_non_timed

! Declaration of the generic IDS DELETE routine 
interface ids_delete        
   module procedure ids_delete_		
end interface ids_delete

! Declaration of the generic IDS DEALLOCATE routine 
interface ids_deallocate        
   module procedure ids_deallocate_		
end interface ids_deallocate

! Declaration of the generic IDS COPY routine 
interface ids_copy        
   module procedure ids_copy_		
end interface ids_copy

! Declaration of the generic IDS FLUSH routine
interface ids_flush        
   module procedure ids_flush_		
end interface ids_flush

! Declaration of the generic IDS DISCARD routine
interface ids_discard        
   module procedure ids_discard_
end interface ids_discard

 contains
 !!!!!! Routines to GET the full IDSs (including the various time indices if time-dependent)
 ! All routines specialised for each IDS

!!!!!! Routines to GET the full IDSs (including the various time indices if time-dependent)
 
subroutine ids_get_(idx,path,  IDS)

use ids_schemas
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


type(type_) :: IDS       

call getenv('ual_debug',ual_debug) ! Debug flag

call begin_IDS_get(idx, path,0,dum1)
      
 ! Get IDS_Properties : PROBLEM : UNIDENTIFIED TYPE !!! 
 ! Get N_Turns : PROBLEM : UNIDENTIFIED TYPE !!! 
 ! Get N_Coils : PROBLEM : UNIDENTIFIED TYPE !!! 
 ! Get Current : PROBLEM : UNIDENTIFIED TYPE !!! 
 ! Get Voltage : PROBLEM : UNIDENTIFIED TYPE !!! 
 ! Get B_Tor_Vacuum_R : PROBLEM : UNIDENTIFIED TYPE !!! 
 ! Get Timebase : PROBLEM : UNIDENTIFIED TYPE !!! 
call end_IDS_get(idx, path)      
     
return
end subroutine ids_get_

!!!!!! Routines to GET one time slice of a IDS, with time interpolation

subroutine ids_get_slice_(idx,path,  IDS, twant, interpol)

use ids_schemas
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

type(type_) :: IDS      

call getenv('ual_debug',ual_debug)

write(*,*) 'Warning : GET_SLICE requested for a time-independent IDS is equivalent to a simple GET'
call ids_get_(idx,path,  IDS)
	

return
end subroutine ids_GET_SLICE_
!!!!!! Routines to PUT the full IDSs (including the various time indices if time-dependent)

subroutine ids_put_(idx, path,  IDS)

use ids_schemas
implicit none

character*(*) :: path
integer :: idx
integer :: i,dim1,dim2,dim3,dim4,dim5,dim6,dim7, lenstring, istring
integer, pointer :: dimtab(:) => null()
character(len=100000)::longstring    
character(len=3)::ual_debug
integer :: obj_all_times,obj1,obj2,obj3,obj4,obj5,obj6,obj7
integer :: i1,i2,i3,i4,i5,i6,i7

type(type_) :: IDS       


call getenv('ual_debug',ual_debug) ! Debug flag

! Systematic delete of the previous IDS, in case it existed
call ids_delete(idx,path,IDS)

! And systematic erase of the previous changes in cache
call ids_discard(idx,path,IDS)

call begin_IDS_put_non_timed(idx, path)

call end_IDS_put_non_timed(idx, path)

return
end subroutine ids_put_
!!!!!! Routines to DELETE IDSs 

subroutine ids_delete_(idx,IDSpath,IDS)  

use ids_schemas
implicit none
character*(*) :: IDSpath
integer :: idx
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug

  
type(type_) :: IDS       

call getenv('ual_debug',ual_debug) ! Debug flag
if (ual_debug =='yes') write(*,*) 'Deleting IDS ',IDSpath

call delete_data(idx,IDSpath,"IDS_Properties")         
call delete_data(idx,IDSpath,"N_Turns")         
call delete_data(idx,IDSpath,"N_Coils")         
call delete_data(idx,IDSpath,"Current")         
call delete_data(idx,IDSpath,"Voltage")         
call delete_data(idx,IDSpath,"B_Tor_Vacuum_R")         
call delete_data(idx,IDSpath,"Timebase")         
if (ual_debug =='yes') write(*,*) 'Delete IDS ',IDSpath,' done'
end subroutine ids_delete_

!!!!!! Routines to DEALLOCATE IDSs 

subroutine ids_deallocate_(IDS)  

use ids_schemas
implicit none
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug
integer :: i1,i2,i3,i4,i5,i6,i7

  
type(type_) :: IDS       
    

if (ual_debug =='yes') write(*,*) 'Deallocate an  IDS : done'
end subroutine ids_deallocate_
!!!!!! Routines to COPY IDSs 

subroutine ids_copy_(IDSin,  IDSout)
! Copies all fields of IDSin to IDSout; Time-independent IDS

use ids_schemas
implicit none
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug

integer :: itime, lentime, lenstring, istring
integer :: i1,i2,i3,i4,i5,i6,i7

type(type_) :: IDSin, IDSout      

call getenv('ual_debug',ual_debug) ! Debug flag

      
 ! Copy IDS_Properties : PROBLEM : UNIDENTIFIED TYPE !!! 
 ! Copy N_Turns : PROBLEM : UNIDENTIFIED TYPE !!! 
 ! Copy N_Coils : PROBLEM : UNIDENTIFIED TYPE !!! 
 ! Copy Current : PROBLEM : UNIDENTIFIED TYPE !!! 
 ! Copy Voltage : PROBLEM : UNIDENTIFIED TYPE !!! 
 ! Copy B_Tor_Vacuum_R : PROBLEM : UNIDENTIFIED TYPE !!! 
 ! Copy Timebase : PROBLEM : UNIDENTIFIED TYPE !!! 

return
end subroutine ids_copy_ 
!!!!!! Routines to flush IDSs

subroutine ids_flush_(idx,IDSpath,IDS)  

use ids_schemas
implicit none
character*(*) :: IDSpath
integer :: idx
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug

  
type(type_) :: IDS       

call getenv('ual_debug',ual_debug) ! Debug flag
if (ual_debug =='yes') write(*,*) 'Flushing IDS ',IDSpath

call ids_flush_cache(idx,IDSpath,"IDS_Properties")         
call ids_flush_cache(idx,IDSpath,"N_Turns")         
call ids_flush_cache(idx,IDSpath,"N_Coils")         
call ids_flush_cache(idx,IDSpath,"Current")         
call ids_flush_cache(idx,IDSpath,"Voltage")         
call ids_flush_cache(idx,IDSpath,"B_Tor_Vacuum_R")         
call ids_flush_cache(idx,IDSpath,"Timebase")         
if (ual_debug =='yes') write(*,*) 'Flushing IDS ',IDSpath,' done'
end subroutine ids_flush_

!!!!!! Routines to discard IDSs 

subroutine ids_discard_(idx,IDSpath,IDS)  

use ids_schemas
implicit none
character*(*) :: IDSpath
integer :: idx
integer, parameter :: DP=kind(1.0D0)
character(len=3)::ual_debug

  
type(type_) :: IDS       

call getenv('ual_debug',ual_debug) ! Debug flag
if (ual_debug =='yes') write(*,*) 'Discarding IDS ',IDSpath

call ids_discard_cache(idx,IDSpath,"IDS_Properties")         
call ids_discard_cache(idx,IDSpath,"N_Turns")         
call ids_discard_cache(idx,IDSpath,"N_Coils")         
call ids_discard_cache(idx,IDSpath,"Current")         
call ids_discard_cache(idx,IDSpath,"Voltage")         
call ids_discard_cache(idx,IDSpath,"B_Tor_Vacuum_R")         
call ids_discard_cache(idx,IDSpath,"Timebase")         
if (ual_debug =='yes') write(*,*) 'Discarding IDS ',IDSpath,' done'
end subroutine ids_discard_
end module _ids_module
