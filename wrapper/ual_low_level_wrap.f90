! F90 wrappers for C lowlevel functions defined in ual_lowlevel.h
! and subroutines (non-overloaded at this stage) for translating typed
! data to void C pointers
module ual_low_level_wrap
  use ual_defs
  integer, parameter :: STRMAXLEN = 100000

  ! C functions interface
  ! use iso_c_binding: only C_INT, C_CHAR, etc...
  interface

     !!! standard functions !!!
     subroutine c_free(ptr) bind(C,name="free")
       use, intrinsic :: ISO_C_BINDING
       type(C_PTR), value, intent(in) :: ptr
     end subroutine c_free

     !!!!! direct wrappers to new API !!!!!
     function c_ual_print_context(ctx) bind(C,name="ual_print_context")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_print_context
       integer(C_INT), value, intent(in) :: ctx
     end function c_ual_print_context

     function c_ual_get_backendID(ctx) bind(C,name="ual_get_backendID")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_get_backendID
       integer(C_INT), value, intent(in) :: ctx
     end function c_ual_get_backendID

     function c_ual_begin_pulse_action(beid, shot, run, usr, tok, ver) bind(C,name="ual_begin_pulse_action")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_begin_pulse_action
       integer(C_INT), value, intent(in) :: beid, shot, run
       character(C_CHAR), dimension(*), intent(in) :: usr, tok, ver
     end function c_ual_begin_pulse_action

     function c_ual_open_pulse(pctx, mode, opt) bind(C,name="ual_open_pulse")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_open_pulse
       integer(C_INT), value, intent(in) :: pctx, mode
       character(C_CHAR), dimension(*), intent(in) :: opt
     end function c_ual_open_pulse

     function c_ual_close_pulse(pctx, mode, opt) bind(C,name="ual_close_pulse")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_close_pulse
       integer(C_INT), value, intent(in) :: pctx, mode
       character(C_CHAR), dimension(*), intent(in) :: opt
     end function c_ual_close_pulse

     function c_ual_begin_global_action(pctx, dataobjectname, rwmode) bind(C,name="ual_begin_global_action")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_begin_global_action
       integer(C_INT), value, intent(in) :: pctx, rwmode
       character(C_CHAR), dimension(*), intent(in) :: dataobjectname
     end function c_ual_begin_global_action
     
     function c_ual_begin_slice_action(pctx, dataobjectname, rwmode, time, interpmode) bind(C,name="ual_begin_slice_action")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_begin_slice_action
       integer(C_INT), value, intent(in) :: pctx, rwmode, interpmode
       real(C_DOUBLE), value, intent(in) :: time
       character(C_CHAR), dimension(*), intent(in) :: dataobjectname
     end function c_ual_begin_slice_action

     function c_ual_end_action(ctx) bind(C,name="ual_end_action")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_end_action
       integer(C_INT), value, intent(in) :: ctx
     end function c_ual_end_action

     function c_ual_write_data(ctx, fieldname, timebasename, data, datatype, dim, size) bind(C,name="ual_write_data")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_write_data
       integer(C_INT), value, intent(in) :: ctx, datatype, dim
       character(C_CHAR), dimension(*), intent(in) :: fieldname, timebasename
       type(C_PTR), value, intent(in) :: data
       type(C_PTR), value, intent(in) :: size
     end function c_ual_write_data

     function c_ual_read_data(ctx, fieldname, timebase, data, datatype, dim, size) bind(C,name="ual_read_data")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_read_data
       integer(C_INT), value, intent(in) :: ctx, datatype, dim
       character(C_CHAR), dimension(*), intent(in) :: fieldname, timebase
       type(C_PTR), intent(out) :: data
       type(C_PTR), value, intent(in) :: size
     end function c_ual_read_data

     function c_ual_delete_data(ctx, path) bind(C,name="ual_delete_data")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_delete_data
       integer(C_INT), value, intent(in) :: ctx
       character(C_CHAR), dimension(*), intent(in) :: path
     end function c_ual_delete_data

     function c_ual_begin_arraystruct_action(ctx, path, timebase, size) bind(C,name="ual_begin_arraystruct_action")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_begin_arraystruct_action
       integer(C_INT), value, intent(in) :: ctx
       integer(C_INT), intent(inout) :: size
       character(C_CHAR), dimension(*), intent(in) :: path, timebase
     end function c_ual_begin_arraystruct_action

     function c_ual_iterate_over_arraystruct(aosctx, step) bind(C,name="ual_iterate_over_arraystruct")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_iterate_over_arraystruct
       integer(C_INT), value, intent(in) :: aosctx, step
     end function c_ual_iterate_over_arraystruct

  end interface



contains 

  subroutine unpack_string(longstring, lenstring, cpostring)
    implicit none
    character(*), intent(in) :: longstring
    integer, intent(in) :: lenstring
    character(132), dimension(:), pointer :: cpostring
    integer :: i
    allocate(cpostring(floor(real(lenstring/132))+1)) 
    if (lenstring <= 132) then             
       cpostring(1) = longstring(1:lenstring)
    else
       do i=1,floor(real(lenstring/132))+1
          cpostring(i) = trim(longstring(1+(i-1)*132 : i*132))  
       enddo
    endif
  end subroutine unpack_string

  subroutine pack_string(cpostring, longstring, lenstring)
    implicit none
    character(132), dimension(:), pointer :: cpostring
    character(STRMAXLEN), intent(out) :: longstring
    integer, intent(out) :: lenstring
    integer :: arrsize, i
    longstring = ' '
    lenstring = 0
    arrsize = size(cpostring)      
    if (arrsize.EQ.1) then             
       lenstring = len_trim(cpostring(1))
       longstring = cpostring(1)(1:lenstring)
    else
       do i=1,arrsize
          longstring(1+(i-1)*132 : i*132) = cpostring(i)
       enddo
       lenstring = (arrsize-1)*132 + len_trim(cpostring(arrsize))
    endif
  end subroutine pack_string

  subroutine ual_print_context(ctx)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: ctx
    integer :: status
    status = c_ual_print_context(ctx)
  end subroutine ual_print_context

  subroutine ual_get_backendID(ctx, beID)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: ctx
    integer, intent(out) :: beID
    beid = c_ual_get_backendID(ctx)
  end subroutine ual_get_backendID

  subroutine ual_begin_pulse_action(beid, shot, run, usr, tok, ver, pctx)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: beid, shot, run
    character(*), intent(in) :: usr, tok, ver
    integer, intent(out) :: pctx
    pctx = c_ual_begin_pulse_action(beid, shot, run, trim(usr)//C_NULL_CHAR, &
         trim(tok)//C_NULL_CHAR, trim(ver)//C_NULL_CHAR)
  end subroutine ual_begin_pulse_action

  subroutine ual_open_pulse(pctx, mode, opt, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pctx, mode
    character(*), intent(in) :: opt
    integer, intent(out) :: status
    status = c_ual_open_pulse(pctx, mode, trim(opt)//C_NULL_CHAR)
  end subroutine ual_open_pulse

  subroutine ual_close_pulse(pctx, mode, opt, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pctx, mode
    character(*), intent(in) :: opt
    integer, intent(out) :: status
    status = c_ual_close_pulse(pctx, mode, trim(opt)//C_NULL_CHAR)
  end subroutine ual_close_pulse

  subroutine ual_begin_global_action(pctx, cponame, rwmode, octx)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pctx, rwmode
    character(*), intent(in) :: cponame
    integer, intent(out) :: octx
    octx = c_ual_begin_global_action(pctx, trim(cponame)//C_NULL_CHAR, rwmode)
  end subroutine ual_begin_global_action

  subroutine ual_begin_slice_action(pctx, cponame, rwmode, time, interpmode, octx)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pctx, rwmode, interpmode
    real(8), intent(in) :: time
    character(*), intent(in) :: cponame
    integer, intent(out) :: octx
    octx = c_ual_begin_slice_action(pctx, trim(cponame)//C_NULL_CHAR, rwmode, time, interpmode)
  end subroutine ual_begin_slice_action

  subroutine ual_end_action(ctx, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: ctx
    integer, intent(out) :: status
    status = c_ual_end_action(ctx)
  end subroutine ual_end_action

  !WHAT TO DO WHEN EXPECTING VOID TYPE TO BE PASSED IN FORTRAN??? overloaded module procedure?
  !subroutine ual_write_data(ctx, fieldname, timebase, data, datatype, dim, size)
  !subroutine ual_read_data(ctx, fieldname, timebase, data, datatype, dim, size)

  subroutine ual_delete_data(ctx, path, status) 
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: ctx
    character(*), intent(in) :: path
    integer, intent(out) :: status
    status = c_ual_delete_data(ctx, trim(path)//C_NULL_CHAR)
  end subroutine ual_delete_data

  subroutine ual_begin_arraystruct_action(ctx, path, timebase, size, aosctx)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: ctx
    integer(C_INT) :: csize
    integer, intent(inout) :: size
    character(*), intent(in) :: path, timebase
    integer, intent(out) :: aosctx
    csize = size
    aosctx = c_ual_begin_arraystruct_action(ctx, trim(path)//C_NULL_CHAR, trim(timebase)//C_NULL_CHAR, csize)
    if (aosctx.ge.0) then
       size = csize
    endif
  end subroutine ual_begin_arraystruct_action

  subroutine ual_iterate_over_arraystruct(aosctx, step, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: aosctx, step
    integer, intent(out) :: status
    status = c_ual_iterate_over_arraystruct(aosctx, step)
  end subroutine ual_iterate_over_arraystruct


  !!! old API !!!

  subroutine imas_create_env(name, shot, run, refShot, refRun, pulseCtx, user, tokamak, version, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    character(*), intent(in) :: name, user, tokamak, version
    integer, intent(in) :: shot, run, refShot, refRun
    integer, intent(out) :: pulseCtx
    integer, intent(out), optional :: retstatus
    integer :: status
    call ual_begin_pulse_action(MDSPLUS_BACKEND, shot, run, user, tokamak, version, pulseCtx)
    if (pulseCtx < 0) then 
       status = pulseCtx
    else
       call ual_open_pulse(pulseCtx, FORCE_CREATE_PULSE, "", status)
    end if
    if (present(retstatus)) retstatus = status
  end subroutine imas_create_env

  subroutine imas_open_env(name, shot, run, pulseCtx, user, tokamak, version, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    character(*), intent(in) :: name, user, tokamak, version
    integer, intent(in) :: shot, run
    integer, intent(out) :: pulseCtx
    integer, optional, intent(out) :: retstatus
    integer :: status
    call ual_begin_pulse_action(MDSPLUS_BACKEND, shot, run, user, tokamak, version, pulseCtx)
    if (pulseCtx < 0) then 
       status = pulseCtx
    else
       call ual_open_pulse(pulseCtx, OPEN_PULSE, "", status)
    end if
    if (present(retstatus)) retstatus = status
  end subroutine imas_open_env

  subroutine imas_close(pulseCtx, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pulseCtx
    integer, optional, intent(out) :: retstatus
    integer :: status
    call ual_close_pulse(pulseCtx, CLOSE_PULSE, "", status)
    if (present(retstatus)) retstatus = status
  end subroutine imas_close

  subroutine put_char(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character, intent(in), target :: data
    integer, intent(out) :: status
    type(C_PTR) :: pdata
    pdata = C_LOC(data)
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, pdata, CHAR_DATA, 0, C_NULL_PTR)
  end subroutine put_char

  subroutine put_int(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, intent(in), target :: data
    integer, intent(out) :: status
    type(C_PTR) :: pdata
    pdata = C_LOC(data)
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, pdata, INTEGER_DATA, 0, C_NULL_PTR)
  end subroutine put_int
  
  subroutine put_double(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), intent(in), target :: data
    integer, intent(out) :: status
    type(C_PTR) :: pdata
    pdata = C_LOC(data)
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, pdata, DOUBLE_DATA, 0, C_NULL_PTR)
  end subroutine put_double

  subroutine put_complex(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), intent(in), target :: data
    integer, intent(out) :: status
    type(C_PTR) :: pdata
    pdata = C_LOC(data)
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, pdata, COMPLEX_DATA, 0, C_NULL_PTR)
  end subroutine put_complex

  subroutine put_string(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath, data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    character(C_CHAR), dimension(:), pointer :: cdata
    integer, target :: dsize(1)
    integer :: i
    dsize = (/ len_trim(data) /)
    allocate(cdata(dsize(1)))
    do i=1,dsize(1)
       cdata(i) = data(i:i)
    end do
    cptr = C_LOC(cdata(1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, CHAR_DATA, 1, csize)
    deallocate(cdata)
  end subroutine put_string

  subroutine put_vect1d_int(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(1)
    dsize = (/ dim1 /)
    cptr = C_LOC(data(1))    
    csize = C_LOC(dsize)
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 1, csize)
  end subroutine put_vect1d_int

  subroutine put_vect1d_double(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(1)
    dsize = (/ dim1 /)
    cptr = C_LOC(data(1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 1, csize)
  end subroutine put_vect1d_double

  subroutine put_vect1d_complex(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(1)
    dsize = (/ dim1 /)
    cptr = C_LOC(data(1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 1, csize)
  end subroutine put_vect1d_complex

  subroutine put_vect1d_string(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none 
    integer, intent(in) :: opCtx, dim1
    character(*), intent(in) :: fieldPath, timebasePath
    character(132), dimension(:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    character(C_CHAR), dimension(:,:), pointer :: cdata
    integer(C_INT) :: csize1, csize2
    integer :: i,j
    integer, target :: dsize(2)
    csize1 = dim1
    csize2 = MAXVAL(len_trim(data(1:dim1)))
    dsize = (/ csize1, csize2 /)
    allocate(cdata(csize1, csize2))
    do i=1,csize1
       do j=1,csize2
          cdata(i,j) = data(i)(j:j)
       end do
    end do
    cptr = C_LOC(cdata(1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, CHAR_DATA, 2, csize)
    deallocate(cdata)
  end subroutine put_vect1d_string

  subroutine put_vect2d_int(opCtx, fieldPath, timebasePath, data, dim1, dim2, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(2)
    dsize = (/ dim1, dim2 /)
    cptr = C_LOC(data(1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 2, csize)
  end subroutine put_vect2d_int

  subroutine put_vect2d_double(opCtx, fieldPath, timebasePath, data, dim1, dim2, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(2)
    dsize = (/ dim1, dim2 /)
    cptr = C_LOC(data(1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 2, csize)
  end subroutine put_vect2d_double

  subroutine put_vect2d_complex(opCtx, fieldPath, timebasePath, data, dim1, dim2, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(2)
    dsize = (/ dim1, dim2 /)
    cptr = C_LOC(data(1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 2, csize)
  end subroutine put_vect2d_complex
  
  subroutine put_vect3d_int(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(3)
    dsize = (/ dim1, dim2, dim3 /)
    cptr = C_LOC(data(1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 3, csize)
  end subroutine put_vect3d_int

  subroutine put_vect3d_double(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(3)
    dsize = (/ dim1, dim2, dim3 /)
    cptr = C_LOC(data(1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 3, csize)
  end subroutine put_vect3d_double

  subroutine put_vect3d_complex(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(3)
    dsize = (/ dim1, dim2, dim3 /)
    cptr = C_LOC(data(1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 3, csize)
  end subroutine put_vect3d_complex
  
  subroutine put_vect4d_int(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(4)
    dsize = (/ dim1, dim2, dim3, dim4 /)
    cptr = C_LOC(data(1,1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 4, csize)
  end subroutine put_vect4d_int

  subroutine put_vect4d_double(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(4)
    dsize = (/ dim1, dim2, dim3, dim4 /)
    cptr = C_LOC(data(1,1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 4, csize)
  end subroutine put_vect4d_double

  subroutine put_vect4d_complex(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(4)
    dsize = (/ dim1, dim2, dim3, dim4 /)
    cptr = C_LOC(data(1,1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 4, csize)
  end subroutine put_vect4d_complex
  
  subroutine put_vect5d_int(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(5)
    dsize = (/ dim1, dim2, dim3, dim4, dim5 /)
    cptr = C_LOC(data(1,1,1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 5, csize)
  end subroutine put_vect5d_int

  subroutine put_vect5d_double(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(5)
    dsize = (/ dim1, dim2, dim3, dim4, dim5 /)
    cptr = C_LOC(data(1,1,1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 5, csize)
  end subroutine put_vect5d_double

  subroutine put_vect5d_complex(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(5)
    dsize = (/ dim1, dim2, dim3, dim4, dim5 /)
    cptr = C_LOC(data(1,1,1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 5, csize)
  end subroutine put_vect5d_complex
  
  subroutine put_vect6d_int(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, dim6, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(6)
    dsize = (/ dim1, dim2, dim3, dim4, dim5, dim6 /)
    cptr = C_LOC(data(1,1,1,1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 6, csize)
  end subroutine put_vect6d_int

  subroutine put_vect6d_double(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, dim6, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(6)
    dsize = (/ dim1, dim2, dim3, dim4, dim5, dim6 /)
    cptr = C_LOC(data(1,1,1,1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 6, csize)
  end subroutine put_vect6d_double

  subroutine put_vect6d_complex(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, dim6, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(6)
    dsize = (/ dim1, dim2, dim3, dim4, dim5, dim6 /)
    cptr = C_LOC(data(1,1,1,1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 6, csize)
  end subroutine put_vect6d_complex
  
  subroutine put_vect7d_int(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, dim6, dim7, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6, dim7
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(7)
    dsize = (/ dim1, dim2, dim3, dim4, dim5, dim6, dim7 /)
    cptr = C_LOC(data(1,1,1,1,1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 7, csize)
  end subroutine put_vect7d_int

  subroutine put_vect7d_double(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, dim6, dim7, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6, dim7
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(7)
    dsize = (/ dim1, dim2, dim3, dim4, dim5, dim6, dim7 /)
    cptr = C_LOC(data(1,1,1,1,1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 7, csize)
  end subroutine put_vect7d_double

  subroutine put_vect7d_complex(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, dim6, dim7, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6, dim7
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(7)
    dsize = (/ dim1, dim2, dim3, dim4, dim5, dim6, dim7 /)
    cptr = C_LOC(data(1,1,1,1,1,1,1))
    csize = C_LOC(dsize(1))
    status = c_ual_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 7, csize)
  end subroutine put_vect7d_complex
  

  subroutine get_char(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character(1), intent(inout) :: data
    integer, intent(out) :: status
    character(C_CHAR), target :: cdata
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(MAXDIM)
    csize = C_LOC(dsize)
    cptr = C_LOC(cdata)
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, CHAR_DATA, 0, csize)
    if (status.eq.0) data = cdata
  end subroutine get_char

  subroutine get_int(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, intent(inout) :: data
    integer, intent(out) :: status
    integer(C_INT), target :: cdata
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(MAXDIM)
    csize = C_LOC(dsize)
    cptr = C_LOC(cdata)
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 0, csize)
    if (status.eq.0) data = cdata
  end subroutine get_int

  subroutine get_double(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), intent(inout) :: data
    integer, intent(out) :: status
    real(C_DOUBLE), target :: cdata
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(MAXDIM)
    csize = C_LOC(dsize)
    cptr = C_LOC(cdata)
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 0, csize)
    if (status.eq.0) data = cdata
  end subroutine get_double

  subroutine get_complex(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), intent(inout) :: data
    integer, intent(out) :: status
    complex(C_DOUBLE_COMPLEX), target :: cdata
    type(C_PTR) :: cptr, csize
    integer, target :: dsize(MAXDIM)
    csize = C_LOC(dsize)
    cptr = C_LOC(cdata)
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 0, csize)
    if (status.eq.0) data = cdata
  end subroutine get_complex

  subroutine get_vect1D_char(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character, dimension(:), pointer :: data
    integer, intent(out) :: dim1, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, CHAR_DATA, 1, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:1))
       end if
       dim1 = dsize(1)
    end if
  end subroutine get_vect1D_char

  subroutine get_string(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character(STRMAXLEN), intent(inout) :: data
    integer, intent(out) :: dim1, status
    character, dimension(:), pointer :: tmpdata
    integer :: size,i
    call get_vect1D_char(opCtx, fieldPath, timebasePath, &
         tmpdata, size, status)
    data = ' '
    if (status.eq.0) then
       do i=1,size
          data(i:i) = tmpdata(i)
       end do
       if (size.gt.0) then
          call c_free(C_LOC(tmpdata))
          nullify(tmpdata)
       endif
       dim1 = size
    end if
  end subroutine get_string

  subroutine get_vect1d_int(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:), pointer :: data
    integer, intent(out) :: dim1, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 1, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:1))
       end if
       dim1 = dsize(1)
    end if
  end subroutine get_vect1d_int

  subroutine get_vect1d_double(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:), pointer :: data
    integer, intent(out) :: dim1, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 1, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:1))
       end if
       dim1 = dsize(1)
    end if
  end subroutine get_vect1d_double

  subroutine get_vect1d_complex(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:), pointer :: data
    integer, intent(out) :: dim1, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 1, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:1))
       end if
       dim1 = dsize(1)
    end if
  end subroutine get_vect1d_complex
  
  subroutine get_vect2d_char(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character, dimension(:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, CHAR_DATA, 2, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:2))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
    end if
  end subroutine get_vect2D_char

  subroutine get_vect1D_string(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character(132), dimension(:), pointer :: data
    integer, intent(out) :: dim1, status
    character, dimension(:,:), pointer :: tmpdata
    character(132) :: tmpstr
    integer :: size1, size2, i, j
    call get_vect2D_char(opCtx, fieldPath, timebasePath, &
         tmpdata, size1, size2, status)
    if (status.eq.0) then
       if (size1.gt.0) then
          allocate(data(size1))
          do i=1,size1
             tmpstr = ' '
             do j=1,size2
                tmpstr(j:j) = tmpdata(i,j)
             end do
             data(i) = trim(tmpstr)
          end do
          dim1 = size1
          call c_free(C_LOC(tmpdata))
          nullify(tmpdata)
       end if
    end if
  end subroutine get_vect1D_string

  subroutine get_vect2d_int(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 2, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:2))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
    end if
  end subroutine get_vect2d_int

  subroutine get_vect2d_double(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 2, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:2))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
    end if
  end subroutine get_vect2d_double

  subroutine get_vect2d_complex(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 2, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:2))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
    end if
  end subroutine get_vect2d_complex

  subroutine get_vect3d_int(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 3, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:3))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
    end if
  end subroutine get_vect3d_int

  subroutine get_vect3d_double(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 3, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:3))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
    end if
  end subroutine get_vect3d_double

  subroutine get_vect3d_complex(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 3, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:3))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
    end if
  end subroutine get_vect3d_complex

  subroutine get_vect4d_int(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 4, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:4))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
    end if
  end subroutine get_vect4d_int

  subroutine get_vect4d_double(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 4, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:4))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
    end if
  end subroutine get_vect4d_double

  subroutine get_vect4d_complex(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 4, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:4))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
    end if
  end subroutine get_vect4d_complex

  subroutine get_vect5d_int(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 5, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:5))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
    end if
  end subroutine get_vect5d_int

  subroutine get_vect5d_double(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 5, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:5))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
    end if
  end subroutine get_vect5d_double

  subroutine get_vect5d_complex(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 5, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:5))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
    end if
  end subroutine get_vect5d_complex

  subroutine get_vect6d_int(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, dim6, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 6, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:6))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
       dim6 = dsize(6)
    end if
  end subroutine get_vect6d_int

  subroutine get_vect6d_double(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, dim6, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 6, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:6))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
       dim6 = dsize(6)
    end if
  end subroutine get_vect6d_double

  subroutine get_vect6d_complex(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, dim6, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 6, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:6))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
       dim6 = dsize(6)
    end if
  end subroutine get_vect6d_complex

  subroutine get_vect7d_int(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, dim6, dim7, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, dim7, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 7, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:7))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
       dim6 = dsize(6)
       dim7 = dsize(7)
    end if
  end subroutine get_vect7d_int

  subroutine get_vect7d_double(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, dim6, dim7, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, dim7, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 7, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then 
          call C_F_POINTER(cptr, data, dsize(1:7))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
       dim6 = dsize(6)
       dim7 = dsize(7)
    end if
  end subroutine get_vect7d_double

  subroutine get_vect7d_complex(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, dim6, dim7, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, dim7, status
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = c_ual_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 7, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then 
          call C_F_POINTER(cptr, data, dsize(1:7))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
       dim6 = dsize(6)
       dim7 = dsize(7)
    end if
  end subroutine get_vect7d_complex

end module ual_low_level_wrap
