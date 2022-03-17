! F90 wrappers for C lowlevel functions defined in ual_lowlevel.h
! and subroutines (non-overloaded at this stage) for translating typed
! data to void C pointers
module ual_low_level_wrap
  use ual_defs
  use iso_c_binding
  use ids_schemas

  type, bind(C) :: c_al_status_t
     integer(C_INT) :: code
     character(C_CHAR) :: message(MAX_ERR_MSG_LEN)
  end type c_al_status_t

  type :: al_status
     integer :: code
     character(MAX_ERR_MSG_LEN) :: message
  end type al_status

  integer, parameter :: STRMAXLEN = 100000

  ! C functions interface
  interface

!!! standard functions !!!
     subroutine c_free(ptr) &
          bind(C,name="free")
       use, intrinsic :: ISO_C_BINDING
       type(C_PTR), value, intent(in) :: ptr
     end subroutine c_free

     pure function c_strlen(str) &
          bind(C,name="strlen")
       use, intrinsic :: ISO_C_BINDING
       integer(C_SIZE_T) :: c_strlen
       type(C_PTR), value, intent(in) :: str
     end function c_strlen


!!!!! direct wrappers to new API !!!!!
     function c_ual_context_info(ctx, info) &
          bind(C,name="ual_context_info")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_ual_context_info
       integer(C_INT), value, intent(in) :: ctx
       type(C_PTR), intent(out) :: info
     end function c_ual_context_info

     function c_ual_get_backendID(ctx, beid) &
          bind(C,name="ual_get_backendID")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_ual_get_backendID
       integer(C_INT), value, intent(in) :: ctx
       integer(C_INT), intent(out) :: beid
     end function c_ual_get_backendID

     function c_ual_begin_pulse_action(beid, shot, run, usr, tok, ver, pctx) &
          bind(C,name="ual_begin_pulse_action")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_ual_begin_pulse_action
       integer(C_INT), value, intent(in) :: beid, shot, run
       character(C_CHAR), dimension(*), intent(in) :: usr, tok, ver
       integer(C_INT), intent(out) :: pctx
     end function c_ual_begin_pulse_action

     function c_ual_open_pulse(pctx, mode, opt) &
          bind(C,name="ual_open_pulse")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_ual_open_pulse
       integer(C_INT), value, intent(in) :: pctx, mode
       character(C_CHAR), dimension(*), intent(in) :: opt
     end function c_ual_open_pulse

     function c_ual_close_pulse(pctx, mode, opt) &
          bind(C,name="ual_close_pulse")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_ual_close_pulse
       integer(C_INT), value, intent(in) :: pctx, mode
       character(C_CHAR), dimension(*), intent(in) :: opt
     end function c_ual_close_pulse

     function c_ual_begin_global_action(pctx, dataobjectname, rwmode, opctx) &
          bind(C,name="ual_begin_global_action")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_ual_begin_global_action
       integer(C_INT), value, intent(in) :: pctx, rwmode
       character(C_CHAR), dimension(*), intent(in) :: dataobjectname
       integer(C_INT), intent(out) :: opctx
     end function c_ual_begin_global_action

     function c_ual_begin_slice_action(pctx, dataobjectname, rwmode, time, interpmode, opctx) &
          bind(C,name="ual_begin_slice_action")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_ual_begin_slice_action
       integer(C_INT), value, intent(in) :: pctx, rwmode, interpmode
       real(C_DOUBLE), value, intent(in) :: time
       character(C_CHAR), dimension(*), intent(in) :: dataobjectname
       integer(C_INT), intent(out) :: opctx
     end function c_ual_begin_slice_action

     function c_ual_end_action(ctx) &
          bind(C,name="ual_end_action")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_ual_end_action
       integer(C_INT), value, intent(in) :: ctx
     end function c_ual_end_action

     function c_ual_write_data(ctx, fieldname, timebasename, data, datatype, dim, size) &
          bind(C,name="ual_write_data")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_ual_write_data
       integer(C_INT), value, intent(in) :: ctx, datatype, dim
       character(C_CHAR), dimension(*), intent(in) :: fieldname, timebasename
       type(C_PTR), value, intent(in) :: data
       type(C_PTR), value, intent(in) :: size
     end function c_ual_write_data

     function c_ual_read_data(ctx, fieldname, timebase, data, datatype, dim, size) &
          bind(C,name="ual_read_data")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_ual_read_data
       integer(C_INT), value, intent(in) :: ctx, datatype, dim
       character(C_CHAR), dimension(*), intent(in) :: fieldname, timebase
       type(C_PTR), intent(out) :: data
       type(C_PTR), value, intent(in) :: size
     end function c_ual_read_data

     function c_ual_delete_data(ctx, path) &
          bind(C,name="ual_delete_data")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_ual_delete_data
       integer(C_INT), value, intent(in) :: ctx
       character(C_CHAR), dimension(*), intent(in) :: path
     end function c_ual_delete_data

     function c_ual_begin_arraystruct_action(ctx, path, timebase, size, aosctx) &
          bind(C,name="ual_begin_arraystruct_action")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_ual_begin_arraystruct_action
       integer(C_INT), value, intent(in) :: ctx
       integer(C_INT), intent(inout) :: size
       character(C_CHAR), dimension(*), intent(in) :: path, timebase
       integer(C_INT), intent(out) :: aosctx
     end function c_ual_begin_arraystruct_action

     function c_ual_iterate_over_arraystruct(aosctx, step) &
          bind(C,name="ual_iterate_over_arraystruct")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_ual_iterate_over_arraystruct
       integer(C_INT), value, intent(in) :: aosctx, step
     end function c_ual_iterate_over_arraystruct
     
     function c_hli_read_data(ctx, fieldname, timebase, data, datatype, dim, size) &
          bind(C,name="hli_read_data")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_hli_read_data
       integer(C_INT), value, intent(in) :: ctx, datatype, dim
       character(C_CHAR), dimension(*), intent(in) :: fieldname, timebase
       type(C_PTR), intent(out) :: data
       type(C_PTR), value, intent(in) :: size
     end function c_hli_read_data
     
     function c_hli_write_data(ctx, fieldname, timebasename, data, datatype, dim, size) &
          bind(C,name="hli_write_data")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_hli_write_data
       integer(C_INT), value, intent(in) :: ctx, datatype, dim
       character(C_CHAR), dimension(*), intent(in) :: fieldname, timebasename
       type(C_PTR), value, intent(in) :: data
       type(C_PTR), value, intent(in) :: size
     end function c_hli_write_data
     
     function c_hli_begin_global_action(pctx, dataobjectname, rwmode, opctx) &
          bind(C,name="hli_begin_global_action")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_hli_begin_global_action
       integer(C_INT), value, intent(in) :: pctx, rwmode
       character(C_CHAR), dimension(*), intent(in) :: dataobjectname
       integer(C_INT), intent(out) :: opctx
     end function c_hli_begin_global_action
     
     function c_hli_begin_slice_action(pctx, dataobjectname, rwmode, time, interpmode, opctx) &
          bind(C,name="hli_begin_slice_action")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_hli_begin_slice_action
       integer(C_INT), value, intent(in) :: pctx, rwmode, interpmode
       real(C_DOUBLE), value, intent(in) :: time
       character(C_CHAR), dimension(*), intent(in) :: dataobjectname
       integer(C_INT), intent(out) :: opctx
     end function c_hli_begin_slice_action
     
     function c_hli_begin_arraystruct_action(ctx, path, timebase, size, aosctx) &
          bind(C,name="hli_begin_arraystruct_action")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_hli_begin_arraystruct_action
       integer(C_INT), value, intent(in) :: ctx
       integer(C_INT), intent(inout) :: size
       character(C_CHAR), dimension(*), intent(in) :: path, timebase
       integer(C_INT), intent(out) :: aosctx
     end function c_hli_begin_arraystruct_action
     
     function c_hli_register_plugin(plugin_name) &
          bind(C,name="hli_register_plugin")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_hli_register_plugin
       character(C_CHAR), dimension(*), intent(in) :: plugin_name
     end function c_hli_register_plugin
     
     function c_hli_unregister_plugin(plugin_name) &
          bind(C,name="hli_unregister_plugin")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_hli_unregister_plugin
       character(C_CHAR), dimension(*), intent(in) :: plugin_name
     end function c_hli_unregister_plugin
     
     function c_hli_bind_plugin(path, plugin_name) &
          bind(C,name="hli_bind_plugin")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_hli_bind_plugin
       character(C_CHAR), dimension(*), intent(in) :: path, plugin_name
     end function c_hli_bind_plugin
     
     function c_hli_unbind_plugin(path, plugin_name) &
          bind(C,name="hli_unbind_plugin")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_hli_unbind_plugin
       character(C_CHAR), dimension(*), intent(in) :: path, plugin_name
     end function c_hli_unbind_plugin

    function c_hli_setvalue_int_scalar_parameter_plugin(parameter_name, parameter_value, plugin_name) &
          bind(C,name="hli_setvalue_int_scalar_parameter_plugin")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_hli_setvalue_int_scalar_parameter_plugin
       integer(C_INT), value, intent(in) :: parameter_value
       character(C_CHAR), dimension(*), intent(in) :: parameter_name, plugin_name
     end function c_hli_setvalue_int_scalar_parameter_plugin
     
     function c_hli_setvalue_double_scalar_parameter_plugin(parameter_name, parameter_value, plugin_name) &
          bind(C,name="hli_setvalue_double_scalar_parameter_plugin")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_hli_setvalue_double_scalar_parameter_plugin
       real(C_DOUBLE), value, intent(in) :: parameter_value
       character(C_CHAR), dimension(*), intent(in) :: parameter_name, plugin_name
     end function c_hli_setvalue_double_scalar_parameter_plugin
     
     function c_hli_setvalue_parameter_plugin(parameter_name, datatype, dim, size, parameter_data, plugin_name) &
          bind(C,name="hli_setvalue_parameter_plugin")
       use, intrinsic :: ISO_C_BINDING
       import c_al_status_t
       type(c_al_status_t) :: c_hli_setvalue_parameter_plugin
       character(C_CHAR), dimension(*), intent(in) :: parameter_name, plugin_name
       integer(C_INT), value, intent(in) :: datatype, dim
       type(C_PTR), value, intent(in) :: size
       type(C_PTR), intent(in) :: parameter_data
     end function c_hli_setvalue_parameter_plugin

  end interface

contains 

  pure function fstatus(cstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    type(al_status) :: fstatus
    type(c_al_status_t), intent(in) :: cstatus
    integer :: i
    fstatus%code = cstatus%code
    fstatus%message = ' '
    if (cstatus%code .lt. 0) then
       i = 1
       do while (cstatus%message(i).ne.C_NULL_CHAR)
          fstatus%message(i:i) = cstatus%message(i)
          i = i+1
       end do
    end if
  end function fstatus

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

  subroutine ual_context_info(ctx, info, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: ctx
    character(STRMAXLEN), intent(out) :: info
    integer, optional, intent(out) :: retstatus
    type(al_status) :: status
    type(C_PTR) :: cptr
    character, dimension(:), pointer :: chars
    integer :: s,i
    status = fstatus(c_ual_context_info(ctx, cptr))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    else
       if (C_ASSOCIATED(cptr)) then
          s = c_strlen(cptr)
          call C_F_POINTER(cptr, chars, (/ s /))
          info = ' '
          do i=1,s
             info(i:i) = chars(i)
          end do
          call c_free(cptr)
       end if
    end if
    if (present(retstatus)) retstatus = status%code
  end subroutine ual_context_info

  subroutine ual_get_backendID(ctx, beID, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: ctx
    integer, intent(out) :: beID
    integer, optional, intent(out) :: retstatus
    integer(C_INT) :: cdata
    type(al_status) :: status
    status = fstatus(c_ual_get_backendID(ctx,cdata))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    else
       beID = cdata
    end if
    if (present(retstatus)) retstatus = status%code
  end subroutine ual_get_backendID

  subroutine ual_begin_pulse_action(beid, shot, run, usr, tok, ver, pctx, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: beid, shot, run
    character(*), intent(in) :: usr, tok, ver
    integer, intent(out) :: pctx
    integer, optional, intent(out) :: retstatus
    integer(C_INT) :: cid
    type(al_status) :: status
    status = fstatus(c_ual_begin_pulse_action(beid, shot, run, trim(usr)//C_NULL_CHAR, &
         trim(tok)//C_NULL_CHAR, trim(ver)//C_NULL_CHAR, cid))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
       pctx = 0
    else
       pctx = cid
    end if
    if (present(retstatus)) retstatus = status%code
  end subroutine ual_begin_pulse_action

  subroutine ual_open_pulse(pctx, mode, opt, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pctx, mode
    character(*), intent(in) :: opt
    integer, optional, intent(out) :: retstatus
    type(al_status) :: status
    status = fstatus(c_ual_open_pulse(pctx, mode, trim(opt)//C_NULL_CHAR))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    else
       retstatus = status%code
    end if
    if (present(retstatus)) retstatus = status%code
  end subroutine ual_open_pulse

  subroutine ual_close_pulse(pctx, mode, opt, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pctx, mode
    character(*), intent(in) :: opt
    integer, optional, intent(out) :: retstatus
    type(al_status) :: status
    status = fstatus(c_ual_close_pulse(pctx, mode, trim(opt)//C_NULL_CHAR))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    else
       retstatus = status%code
    end if
    if (present(retstatus)) retstatus = status%code
  end subroutine ual_close_pulse

  subroutine ual_begin_global_action(pctx, cponame, rwmode, octx, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pctx, rwmode
    character(*), intent(in) :: cponame
    integer, intent(out) :: octx
    integer, intent(out) :: retstatus
    integer(C_INT) :: cctx
    type(al_status) :: status
    status = fstatus(c_ual_begin_global_action(pctx, trim(cponame)//C_NULL_CHAR, rwmode, cctx))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    else
       octx = cctx
    end if
    retstatus = status%code
  end subroutine ual_begin_global_action

  subroutine ual_begin_slice_action(pctx, cponame, rwmode, time, interpmode, octx, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pctx, rwmode, interpmode
    real(8), intent(in) :: time
    character(*), intent(in) :: cponame
    integer, intent(out) :: octx
    integer, intent(out) :: retstatus
    integer(C_INT) :: cctx
    type(al_status) :: status
    status = fstatus(c_ual_begin_slice_action(pctx, trim(cponame)//C_NULL_CHAR, rwmode, time, interpmode, cctx))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    else
       octx = cctx
    end if
    retstatus = status%code
  end subroutine ual_begin_slice_action

  subroutine ual_end_action(ctx, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: ctx
    integer, intent(out) :: retstatus
    type(al_status) :: status
    status = fstatus(c_ual_end_action(ctx))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine ual_end_action

  subroutine ual_delete_data(ctx, path, retstatus) 
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: ctx
    character(*), intent(in) :: path
    integer, intent(out) :: retstatus
    type(al_status) :: status
    status = fstatus(c_ual_delete_data(ctx, trim(path)//C_NULL_CHAR))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine ual_delete_data

  subroutine ual_begin_arraystruct_action(ctx, path, timebase, size, aosctx, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: ctx
    integer(C_INT) :: csize
    integer, intent(inout) :: size
    character(*), intent(in) :: path, timebase
    integer, intent(out) :: aosctx, retstatus
    type(al_status) :: status
    csize = size
    status = fstatus(c_ual_begin_arraystruct_action(ctx, trim(path)//C_NULL_CHAR, trim(timebase)//C_NULL_CHAR, csize, aosctx))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    else
       size = csize
    end if
    retstatus = status%code
  end subroutine ual_begin_arraystruct_action

  subroutine ual_iterate_over_arraystruct(aosctx, step, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: aosctx, step
    integer, intent(out) :: retstatus
    type(al_status) :: status
    status = fstatus(c_ual_iterate_over_arraystruct(aosctx, step))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine ual_iterate_over_arraystruct
  
  subroutine hli_begin_global_action(pctx, cponame, rwmode, octx, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pctx, rwmode
    character(*), intent(in) :: cponame
    integer, intent(out) :: octx
    integer, intent(out) :: retstatus
    integer(C_INT) :: cctx
    type(al_status) :: status
    status = fstatus(c_hli_begin_global_action(pctx, trim(cponame)//C_NULL_CHAR, rwmode, cctx))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    else
       octx = cctx
    end if
    retstatus = status%code
  end subroutine hli_begin_global_action
  
  subroutine hli_begin_slice_action(pctx, cponame, rwmode, time, interpmode, octx, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pctx, rwmode, interpmode
    real(8), intent(in) :: time
    character(*), intent(in) :: cponame
    integer, intent(out) :: octx
    integer, intent(out) :: retstatus
    integer(C_INT) :: cctx
    type(al_status) :: status
    status = fstatus(c_hli_begin_slice_action(pctx, trim(cponame)//C_NULL_CHAR, rwmode, time, interpmode, cctx))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    else
       octx = cctx
    end if
    retstatus = status%code
  end subroutine hli_begin_slice_action
  
  subroutine hli_begin_arraystruct_action(ctx, path, timebase, size, aosctx, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: ctx
    integer(C_INT) :: csize
    integer, intent(inout) :: size
    character(*), intent(in) :: path, timebase
    integer, intent(out) :: aosctx, retstatus
    type(al_status) :: status
    csize = size
    status = fstatus(c_hli_begin_arraystruct_action(ctx, trim(path)//C_NULL_CHAR, trim(timebase)//C_NULL_CHAR, csize, aosctx))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    else
       size = csize
    end if
    retstatus = status%code
  end subroutine hli_begin_arraystruct_action
  
  subroutine hli_register_plugin(plugin_name, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(out) :: retstatus
    character(*), intent(in) :: plugin_name
    type(al_status) :: status
    status = fstatus(c_hli_register_plugin(trim(plugin_name)//C_NULL_CHAR))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine hli_register_plugin
  
  subroutine hli_unregister_plugin(plugin_name, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(out) :: retstatus
    character(*), intent(in) :: plugin_name
    type(al_status) :: status
    status = fstatus(c_hli_unregister_plugin(trim(plugin_name)//C_NULL_CHAR))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine hli_unregister_plugin
  
   subroutine hli_bind_plugin(path, plugin_name, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(out) :: retstatus
    character(*), intent(in) :: path, plugin_name
    type(al_status) :: status
    status = fstatus(c_hli_bind_plugin(trim(path)//C_NULL_CHAR, trim(plugin_name)//C_NULL_CHAR))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine hli_bind_plugin
  
  subroutine hli_unbind_plugin(path, plugin_name, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(out) :: retstatus
    character(*), intent(in) :: path, plugin_name
    type(al_status) :: status
    status = fstatus(c_hli_unbind_plugin(trim(path)//C_NULL_CHAR, trim(plugin_name)//C_NULL_CHAR))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine hli_unbind_plugin
  
  subroutine hli_setvalue_int_scalar_parameter_plugin(parameter_name, parameter_value, plugin_name, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(out) :: retstatus
    character(*), intent(in) :: parameter_name, plugin_name
    integer(C_INT), value, intent(in) :: parameter_value
    type(al_status) :: status
    status = fstatus(c_hli_setvalue_int_scalar_parameter_plugin(trim(parameter_name)//C_NULL_CHAR, parameter_value, trim(plugin_name)//C_NULL_CHAR))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine hli_setvalue_int_scalar_parameter_plugin
  
  subroutine hli_setvalue_double_scalar_parameter_plugin(parameter_name, parameter_value, plugin_name, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(out) :: retstatus
    character(*), intent(in) :: parameter_name, plugin_name
    real(C_DOUBLE), value, intent(in) :: parameter_value
    type(al_status) :: status
    status = fstatus(c_hli_setvalue_double_scalar_parameter_plugin(trim(parameter_name)//C_NULL_CHAR, parameter_value, trim(plugin_name)//C_NULL_CHAR))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine hli_setvalue_double_scalar_parameter_plugin
  
  subroutine hli_setvalue_parameter_plugin(parameter_name, datatype, dim, size, parameter_data, plugin_name, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(out) :: retstatus
    character(*), intent(in) :: parameter_name, plugin_name
    integer(C_INT), value, intent(in) :: datatype, dim
    type(C_PTR), value, intent(in) :: size
    type(C_PTR), intent(in) :: parameter_data
    type(al_status) :: status
    status = fstatus(c_hli_setvalue_parameter_plugin(trim(parameter_name)//C_NULL_CHAR, datatype, dim, size, parameter_data, trim(plugin_name)//C_NULL_CHAR))
    if (status%code.ne.0) then
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine hli_setvalue_parameter_plugin


!!! old API !!!

  subroutine imas_create_env(name, shot, run, refShot, refRun, pulseCtx, user, tokamak, version, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    character(*), intent(in) :: name, user, tokamak, version
    integer, intent(in) :: shot, run, refShot, refRun
    integer, intent(out) :: pulseCtx
    integer, intent(out), optional :: retstatus
    integer :: status
    call ual_begin_pulse_action(MDSPLUS_BACKEND, shot, run, user, tokamak, version, pulseCtx, status)
    if (status.eq.0) then 
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
    call ual_begin_pulse_action(MDSPLUS_BACKEND, shot, run, user, tokamak, version, pulseCtx, status)
    if (status.eq.0) then 
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
    if (status.eq.0) then
       call ual_end_action(pulseCtx, status)
    endif
    if (present(retstatus)) retstatus = status
  end subroutine imas_close

  subroutine warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    character(*), intent(in) :: idsName, fieldPath, lifeCycleStatus
    if (lifeCycleStatus.eq.'obsolescent') then
     write(*,*) "Warning : while putting IDS "//trim(idsName)//", the written IDS has non-empty obsolescent node "//trim(fieldPath)//". Please consider updating the code to avoid using obsolescent nodes."
    endif
  end subroutine warningWritingObsolescentNode

  subroutine put_char(opCtx, idsName, fieldPath, timebasePath, data, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    character, intent(in), target :: data
    integer, intent(out) :: retstatus
    type(C_PTR) :: pdata
    type(al_status) :: status
	pdata = C_LOC(data)
	call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
	status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, pdata, CHAR_DATA, 0, C_NULL_PTR))
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_char

  subroutine put_int(opCtx, idsName, fieldPath, timebasePath, data, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    integer, intent(in), target :: data
    integer, intent(out) :: retstatus
    type(C_PTR) :: pdata
    type(al_status) :: status
    if (data.NE.ids_int_invalid) then
       call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
    end if
	pdata = C_LOC(data)
	call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
	status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, pdata, INTEGER_DATA, 0, C_NULL_PTR))
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_int

  subroutine put_double(opCtx, idsName, fieldPath, timebasePath, data, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    real(8), intent(in), target :: data
    integer, intent(out) :: retstatus
    type(C_PTR) :: pdata
    type(al_status) :: status
    if (data.NE.ids_real_invalid) then
       call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
    end if
	pdata = C_LOC(data)
	status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, pdata, DOUBLE_DATA, 0, C_NULL_PTR))
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_double

  subroutine put_complex(opCtx, idsName, fieldPath, timebasePath, data, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    complex(8), intent(in), target :: data
    integer, intent(out) :: retstatus
    type(C_PTR) :: pdata
    type(al_status) :: status
    if (data.NE.ids_complex_invalid) then
       call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
    end if
	pdata = C_LOC(data)
	status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, pdata, COMPLEX_DATA, 0, C_NULL_PTR))
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_complex

  subroutine put_string(opCtx, idsName, fieldPath, timebasePath, data, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus, data
    integer, intent(out) :: retstatus
    type(C_PTR) :: cptr, csize
    character(C_CHAR), dimension(:), pointer :: cdata
    integer(C_INT), target :: dsize(1)
    integer :: i
    type(al_status) :: status
    dsize = (/ len_trim(data) /)
    allocate(cdata(dsize(1)))
    do i=1,dsize(1)
       cdata(i) = data(i:i)
    end do
    cptr = C_LOC(cdata(1))
    csize = C_LOC(dsize(1))
    call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
    status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, CHAR_DATA, 1, csize))
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
    deallocate(cdata)
  end subroutine put_string
  
  subroutine put_empty_string(opCtx, idsName, fieldPath, timebasePath, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    integer, intent(out) :: retstatus
    type(al_status) :: status
    status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, CHAR_DATA, 1, C_NULL_PTR))
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_empty_string

  subroutine put_vect1d_int(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    integer, dimension(:), pointer :: data
    integer, intent(out) :: retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(1)
    integer :: dim1
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
        status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, INTEGER_DATA, rank, C_NULL_PTR))
    else 
        dim1 = size(data, 1)   
		dsize = (/ dim1 /)
		cptr = C_LOC(data(1))    
		csize = C_LOC(dsize)
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, rank, csize))
    end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
		retstatus = status%code
  end subroutine put_vect1d_int

  subroutine put_vect1d_double(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    real(8), dimension(:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(1)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, DOUBLE_DATA, rank, C_NULL_PTR))
    else
        dim1 = size(data, 1)
		dsize = (/ dim1 /)
		cptr = C_LOC(data(1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect1d_double

  subroutine put_vect1d_complex(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    complex(8), dimension(:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(1)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
        status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, COMPLEX_DATA, rank, C_NULL_PTR))
    else
        dim1 = size(data, 1)
		dsize = (/ dim1 /)
		cptr = C_LOC(data(1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect1d_complex

  subroutine put_vect1d_string(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none 
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    character(132), dimension(:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1
    type(C_PTR) :: cptr, csize
    character(C_CHAR), dimension(:,:), pointer :: cdata
    integer(C_INT) :: csize1, csize2
    integer :: i,j
    integer(C_INT), target :: dsize(2)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
        status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, CHAR_DATA, rank + 1, C_NULL_PTR))
    else
        dim1 = size(data, 1)
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
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, CHAR_DATA, rank + 1, csize))
		deallocate(cdata)
   end if
   if (status%code.ne.0) write(*,*) TRIM(status%message)
		retstatus = status%code
  end subroutine put_vect1d_string

  subroutine put_vect2d_int(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    integer, dimension(:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(2)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
        status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, INTEGER_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dsize = (/ dim1, dim2 /)
		cptr = C_LOC(data(1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect2d_int

  subroutine put_vect2d_double(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    real(8), dimension(:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(2)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
        status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, DOUBLE_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dsize = (/ dim1, dim2 /)
		cptr = C_LOC(data(1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect2d_double

  subroutine put_vect2d_complex(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    complex(8), dimension(:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(2)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
        status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, COMPLEX_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dsize = (/ dim1, dim2 /)
		cptr = C_LOC(data(1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, rank, csize))
    end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect2d_complex

  subroutine put_vect3d_int(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    integer, dimension(:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(3)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, INTEGER_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dsize = (/ dim1, dim2, dim3 /)
		cptr = C_LOC(data(1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, rank, csize))
    end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect3d_int

  subroutine put_vect3d_double(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    real(8), dimension(:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(3)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
        status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, DOUBLE_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dsize = (/ dim1, dim2, dim3 /)
		cptr = C_LOC(data(1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect3d_double

  subroutine put_vect3d_complex(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    complex(8), dimension(:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(3)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
        status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, COMPLEX_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dsize = (/ dim1, dim2, dim3 /)
		cptr = C_LOC(data(1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect3d_complex

  subroutine put_vect4d_int(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    integer, dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3, dim4
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(4)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
        status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, INTEGER_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dim4 = size(data, 4)
		dsize = (/ dim1, dim2, dim3, dim4 /)
		cptr = C_LOC(data(1,1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect4d_int

  subroutine put_vect4d_double(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    real(8), dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3, dim4
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(4)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, DOUBLE_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dim4 = size(data, 4)
		dsize = (/ dim1, dim2, dim3, dim4 /)
		cptr = C_LOC(data(1,1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, rank, csize))
    end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect4d_double

  subroutine put_vect4d_complex(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    complex(8), dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3, dim4
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(4)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, COMPLEX_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dim4 = size(data, 4)
		dsize = (/ dim1, dim2, dim3, dim4 /)
		cptr = C_LOC(data(1,1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect4d_complex

  subroutine put_vect5d_int(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    integer, dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3, dim4, dim5
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(5)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, INTEGER_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dim4 = size(data, 4)
		dim5 = size(data, 5)
		dsize = (/ dim1, dim2, dim3, dim4, dim5 /)
		cptr = C_LOC(data(1,1,1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect5d_int

  subroutine put_vect5d_double(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    real(8), dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3, dim4, dim5
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(5)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, DOUBLE_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dim4 = size(data, 4)
		dim5 = size(data, 5)
		dsize = (/ dim1, dim2, dim3, dim4, dim5 /)
		cptr = C_LOC(data(1,1,1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect5d_double

  subroutine put_vect5d_complex(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    complex(8), dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3, dim4, dim5
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(5)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, COMPLEX_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dim4 = size(data, 4)
		dim5 = size(data, 5)
		dsize = (/ dim1, dim2, dim3, dim4, dim5 /)
		cptr = C_LOC(data(1,1,1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, rank, csize))
    end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect5d_complex

  subroutine put_vect6d_int(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    integer, dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3, dim4, dim5, dim6
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(6)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, INTEGER_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dim4 = size(data, 4)
		dim5 = size(data, 5)
		dim6 = size(data, 6)
		dsize = (/ dim1, dim2, dim3, dim4, dim5, dim6 /)
		cptr = C_LOC(data(1,1,1,1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect6d_int

  subroutine put_vect6d_double(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    real(8), dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3, dim4, dim5, dim6
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(6)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
        status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, DOUBLE_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dim4 = size(data, 4)
		dim5 = size(data, 5)
		dim6 = size(data, 6)
		dsize = (/ dim1, dim2, dim3, dim4, dim5, dim6 /)
		cptr = C_LOC(data(1,1,1,1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect6d_double

  subroutine put_vect6d_complex(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    complex(8), dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3, dim4, dim5, dim6
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(6)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, rank, csize))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dim4 = size(data, 4)
		dim5 = size(data, 5)
		dim6 = size(data, 6)
		dsize = (/ dim1, dim2, dim3, dim4, dim5, dim6 /)
		cptr = C_LOC(data(1,1,1,1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, COMPLEX_DATA, rank, C_NULL_PTR))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect6d_complex

  subroutine put_vect7d_int(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    integer, dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3, dim4, dim5, dim6, dim7
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(7)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, INTEGER_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dim4 = size(data, 4)
		dim5 = size(data, 5)
		dim6 = size(data, 6)
		dim7 = size(data, 7)
		dsize = (/ dim1, dim2, dim3, dim4, dim5, dim6, dim7 /)
		cptr = C_LOC(data(1,1,1,1,1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect7d_int

  subroutine put_vect7d_double(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    real(8), dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3, dim4, dim5, dim6, dim7
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(7)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, DOUBLE_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dim4 = size(data, 4)
		dim5 = size(data, 5)
		dim6 = size(data, 6)
		dim7 = size(data, 7)
		dsize = (/ dim1, dim2, dim3, dim4, dim5, dim6, dim7 /)
		cptr = C_LOC(data(1,1,1,1,1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect7d_double

  subroutine put_vect7d_complex(opCtx, idsName, fieldPath, timebasePath, data, rank, lifeCycleStatus, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, rank
    character(*), intent(in) :: idsName, fieldPath, timebasePath, lifeCycleStatus
    complex(8), dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: retstatus
    integer :: dim1, dim2, dim3, dim4, dim5, dim6, dim7
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(7)
    type(al_status) :: status
    if (associated(data) .eqv. .false.) then
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, C_NULL_PTR, COMPLEX_DATA, rank, C_NULL_PTR))
    else
		dim1 = size(data, 1)
		dim2 = size(data, 2)
		dim3 = size(data, 3)
		dim4 = size(data, 4)
		dim5 = size(data, 5)
		dim6 = size(data, 6)
		dim7 = size(data, 7)
		dsize = (/ dim1, dim2, dim3, dim4, dim5, dim6, dim7 /)
		cptr = C_LOC(data(1,1,1,1,1,1,1))
		csize = C_LOC(dsize(1))
		call warningWritingObsolescentNode(idsName, fieldPath, lifeCycleStatus)
		status = fstatus(c_hli_write_data(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, rank, csize))
	end if
    if (status%code.ne.0) write(*,*) TRIM(status%message)
    retstatus = status%code
  end subroutine put_vect7d_complex


  subroutine get_char(opCtx, fieldPath, timebasePath, data, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character(1), intent(inout) :: data
    integer, intent(out) :: retstatus
    character(C_CHAR), target :: cdata
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize)
    cptr = C_LOC(cdata)
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, CHAR_DATA, 0, csize))
    if (status%code.eq.0) then 
       data = cdata
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_char

  subroutine get_int(opCtx, fieldPath, timebasePath, data, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, intent(inout) :: data
    integer, intent(out) :: retstatus
    integer(C_INT), target :: cdata
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize)
    cptr = C_LOC(cdata)
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 0, csize))
    if (status%code.eq.0) then 
       data = cdata
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_int

  subroutine get_double(opCtx, fieldPath, timebasePath, data, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), intent(inout) :: data
    integer, intent(out) :: retstatus
    real(C_DOUBLE), target :: cdata
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize)
    cptr = C_LOC(cdata)
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 0, csize))
    if (status%code.eq.0) then 
       data = cdata
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_double

  subroutine get_complex(opCtx, fieldPath, timebasePath, data, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), intent(inout) :: data
    integer, intent(out) :: retstatus
    complex(C_DOUBLE_COMPLEX), target :: cdata
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize)
    cptr = C_LOC(cdata)
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 0, csize))
    if (status%code.eq.0) then 
       data = cdata
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_complex

  subroutine get_vect1D_char(opCtx, fieldPath, timebasePath, data, dim1, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character, dimension(:), pointer :: data
    integer, intent(out) :: dim1, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, CHAR_DATA, 1, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:1))
       end if
       dim1 = dsize(1)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect1D_char

  subroutine get_string(opCtx, fieldPath, timebasePath, data, dim1, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character(STRMAXLEN), intent(inout) :: data
    integer, intent(out) :: dim1, retstatus
    character, dimension(:), pointer :: tmpdata
    integer :: size,i
    call get_vect1D_char(opCtx, fieldPath, timebasePath, &
         tmpdata, size, retstatus)
    data = ' '
    if (retstatus.eq.0) then
       do i=1,size
          data(i:i) = tmpdata(i)
       end do
       if (size.gt.0) then
          call c_free(C_LOC(tmpdata(1)))
          nullify(tmpdata)
       endif
       dim1 = size
    end if
  end subroutine get_string

  subroutine get_vect1d_int(opCtx, fieldPath, timebasePath, data, dim1, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:), pointer :: data
    integer, intent(out) :: dim1, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 1, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:1))
       end if
       dim1 = dsize(1)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect1d_int

  subroutine get_vect1d_double(opCtx, fieldPath, timebasePath, data, dim1, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:), pointer :: data
    integer, intent(out) :: dim1, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 1, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:1))
       end if
       dim1 = dsize(1)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect1d_double

  subroutine get_vect1d_complex(opCtx, fieldPath, timebasePath, data, dim1, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:), pointer :: data
    integer, intent(out) :: dim1, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 1, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:1))
       end if
       dim1 = dsize(1)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect1d_complex

  subroutine get_vect2d_char(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character, dimension(:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, CHAR_DATA, 2, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:2))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect2D_char

  subroutine get_vect1D_string(opCtx, fieldPath, timebasePath, data, dim1, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character(132), dimension(:), pointer :: data
    integer, intent(out) :: dim1, retstatus
    character, dimension(:,:), pointer :: tmpdata
    character(132) :: tmpstr
    integer :: size1, size2, i, j
    call get_vect2D_char(opCtx, fieldPath, timebasePath, &
         tmpdata, size1, size2, retstatus)
    if (retstatus.eq.0) then
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
          call c_free(C_LOC(tmpdata(1,1)))
          nullify(tmpdata)
       end if
    end if
  end subroutine get_vect1D_string

  subroutine get_vect2d_int(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 2, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:2))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect2d_int

  subroutine get_vect2d_double(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 2, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:2))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect2d_double

  subroutine get_vect2d_complex(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 2, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:2))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect2d_complex

  subroutine get_vect3d_int(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 3, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:3))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect3d_int

  subroutine get_vect3d_double(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 3, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:3))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect3d_double

  subroutine get_vect3d_complex(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 3, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:3))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect3d_complex

  subroutine get_vect4d_int(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 4, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:4))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect4d_int

  subroutine get_vect4d_double(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 4, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:4))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect4d_double

  subroutine get_vect4d_complex(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 4, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:4))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect4d_complex

  subroutine get_vect5d_int(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 5, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:5))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect5d_int

  subroutine get_vect5d_double(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 5, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:5))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect5d_double

  subroutine get_vect5d_complex(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 5, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:5))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect5d_complex

  subroutine get_vect6d_int(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, dim6, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 6, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:6))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
       dim6 = dsize(6)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect6d_int

  subroutine get_vect6d_double(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, dim6, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 6, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:6))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
       dim6 = dsize(6)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect6d_double

  subroutine get_vect6d_complex(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, dim6, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 6, csize))
    if (status%code.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, dsize(1:6))
       end if
       dim1 = dsize(1)
       dim2 = dsize(2)
       dim3 = dsize(3)
       dim4 = dsize(4)
       dim5 = dsize(5)
       dim6 = dsize(6)
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect6d_complex

  subroutine get_vect7d_int(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, dim6, dim7, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, dim7, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, INTEGER_DATA, 7, csize))
    if (status%code.eq.0) then
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
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect7d_int

  subroutine get_vect7d_double(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, dim6, dim7, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, dim7, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, DOUBLE_DATA, 7, csize))
    if (status%code.eq.0) then
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
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect7d_double

  subroutine get_vect7d_complex(opCtx, fieldPath, timebasePath, data, &
       dim1, dim2, dim3, dim4, dim5, dim6, dim7, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, dim7, retstatus
    type(C_PTR) :: cptr, csize
    integer(C_INT), target :: dsize(MAXDIM)
    type(al_status) :: status
    csize = C_LOC(dsize(1))
    cptr = C_NULL_PTR
    status = fstatus(c_hli_read_data(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cptr, COMPLEX_DATA, 7, csize))
    if (status%code.eq.0) then
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
    else
       write(*,*) TRIM(status%message)
    end if
    retstatus = status%code
  end subroutine get_vect7d_complex

end module ual_low_level_wrap
