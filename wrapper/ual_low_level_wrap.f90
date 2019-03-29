! F90 interfaces and subroutine wrappers for C low level functions defined in ual_low_level.h/.c
module ual_low_level_wrap
  use ual_defs
  integer, parameter :: STRMAXLEN = 100000

  ! C functions interface
  ! use iso_c_binding: only C_INT, C_CHAR, etc...
  interface
     !function check_status(status, file, line)

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
       type(C_PTR), intent(inout) :: size
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

!!$     function c_ual_put_in_arraystruct(ctx, fieldname, timebasename, idx, data, datatype, dim, size) bind(C,name="ual_put_in_arraystruct")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_ual_put_in_arraystruct
!!$       integer(C_INT), value, intent(in) :: ctx, idx, datatype, dim
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldname, timebasename
!!$       type(C_PTR), value, intent(in) :: data
!!$       type(C_PTR), value, intent(in) :: size
!!$     end function c_ual_put_in_arraystruct
!!$
!!$     function c_ual_get_from_arraystruct(ctx, fieldname, timebasename, idx, data, datatype, dim, size) bind(C,name="ual_get_from_arraystruct")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_ual_get_from_arraystruct
!!$       integer(C_INT), value, intent(in) :: ctx, idx, datatype, dim
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldname, timebasename
!!$       type(C_PTR), intent(out) :: data
!!$       type(C_PTR), intent(inout) :: size
!!$     end function c_ual_get_from_arraystruct




     !!!!! wrappers to old API !!!!!
     function c_ual_create(name, shot, run, refShot, refRun, pulseCtx) bind(C,name="ual_create")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_create
       character(C_CHAR), dimension(*), intent(in) :: name
       integer(C_INT), value, intent(in) :: shot, run, refShot, refRun
       integer(C_INT), intent(out) :: pulseCtx
     end function c_ual_create

     function c_ual_open(name, shot, run, pulseCtx) bind(C,name="ual_open")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_open
       character(C_CHAR), dimension(*), intent(in) :: name
       integer(C_INT), value, intent(in) :: shot, run
       integer(C_INT), intent(out) :: pulseCtx
     end function c_ual_open

     function c_ual_close(pulseCtx) bind(C,name="ual_close")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_close
       integer(C_INT), value, intent(in) :: pulseCtx
     end function c_ual_close

     function c_ual_create_env(name, shot, run, refShot, refRun, pulseCtx, user, tokamak, version) bind(C,name="ual_create_env")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_create_env
       character(C_CHAR), dimension(*), intent(in) :: name, user, tokamak, version
       integer(C_INT), value, intent(in) :: shot, run, refShot, refRun
       integer(C_INT), intent(out) :: pulseCtx   
     end function c_ual_create_env

     function c_ual_open_env(name, shot, run, pulseCtx, user, tokamak, version) bind(C,name="ual_open_env")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_open_env
       character(C_CHAR), dimension(*), intent(in) :: name, user, tokamak, version
       integer(C_INT), value, intent(in) :: shot, run
       integer(C_INT), intent(out) :: pulseCtx   
     end function c_ual_open_env

     function c_beginDataobjectGet(pulseCtx, path) bind(C,name="beginDataobjectGet")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_beginDataobjectGet
       integer(C_INT), value, intent(in) :: pulseCtx
       character(C_CHAR), dimension(*), intent(in) :: path
     end function c_beginDataobjectGet

     function c_endDataobjectGet(opCtx) bind(C,name="endDataobjectGet")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_endDataobjectGet
       integer(C_INT), value, intent(in) :: opCtx
     end function c_endDataobjectGet

     function c_beginDataobjectGetSlice(pulseCtx, path, time, interpMode) bind(C,name="beginDataobjectGetSlice")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_beginDataobjectGetSlice
       integer(C_INT), value, intent(in) :: pulseCtx, interpMode
       character(C_CHAR), dimension(*), intent(in) :: path
       real(C_DOUBLE), value, intent(in) :: time
     end function c_beginDataobjectGetSlice

     function c_endDataobjectGetSlice(opCtx) bind(C,name="endDataobjectGetSlice")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_endDataobjectGetSlice
       integer(C_INT), value, intent(in) :: opCtx
     end function c_endDataobjectGetSlice

     function c_beginDataobjectPutTimed(pulseCtx, path) bind(C,name="beginDataobjectPutTimed")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_beginDataobjectPutTimed
       integer(C_INT), value, intent(in) :: pulseCtx
       character(C_CHAR), dimension(*), intent(in) :: path
     end function c_beginDataobjectPutTimed

     function c_endDataobjectPutTimed(opCtx) bind(C,name="endDataobjectPutTimed")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_endDataobjectPutTimed
       integer(C_INT), value, intent(in) :: opCtx
     end function c_endDataobjectPutTimed

     function c_beginDataobjectPutNonTimed(pulseCtx, path) bind(C,name="beginDataobjectPutNonTimed")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_beginDataobjectPutNonTimed
       integer(C_INT), value, intent(in) :: pulseCtx
       character(C_CHAR), dimension(*), intent(in) :: path
     end function c_beginDataobjectPutNonTimed

     function c_endDataobjectPutNonTimed(opCtx) bind(C,name="endDataobjectPutNonTimed")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_endDataobjectPutNonTimed
       integer(C_INT), value, intent(in) :: opCtx
     end function c_endDataobjectPutNonTimed

     function c_beginDataobjectPutSlice(pulseCtx, path, time) bind(C,name="beginDataobjectPutSlice")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_beginDataobjectPutSlice
       integer(C_INT), value, intent(in) :: pulseCtx
       character(C_CHAR), intent(in) :: path
       real(C_DOUBLE), value, intent(in) :: time
     end function c_beginDataobjectPutSlice

     function c_endDataobjectPutSlice(opCtx) bind(C,name="endDataobjectPutSlice")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_endDataobjectPutSlice
       integer(C_INT), value, intent(in) :: opCtx
     end function c_endDataobjectPutSlice

     function c_deleteData(opCtx, fieldPath) bind(C,name="deleteData")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_deleteData
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath
     end function c_deleteData

     function c_ual_flush_dataobject_mem_cache(pulseCtx, path) bind(C,name="ual_flush_dataobject_mem_cache")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_ual_flush_dataobject_mem_cache
       integer(C_INT), value, intent(in) :: pulseCtx
       character(C_CHAR), dimension(*), intent(in) :: path
     end function c_ual_flush_dataobject_mem_cache

     function c_ual_discard_dataobject_mem_cache(pulseCtx, path) bind(C,name="ual_discard_dataobject_mem_cache")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_euitm_discard_dataobject_mem_cache
       integer(C_INT), value, intent(in) :: pulseCtx
       character(C_CHAR), dimension(*), intent(in) :: path
     end function c_ual_discard_dataobject_mem_cache



     function c_putChar(opCtx, fieldPath, timebasePath, cdata) BIND(C, name="putChar")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putChar
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       character(C_CHAR), intent(in) :: cdata
     end function c_putChar

     function c_putInt(opCtx, fieldPath, timebasePath, cdata) bind(C,name="putInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putInt
       integer(C_INT), value, intent(in) :: opCtx, cdata
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
     end function c_putInt

     function c_putDouble(opCtx, fieldPath, timebasePath, cdata) bind(C,name="putDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putDouble
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       real(C_DOUBLE), value, intent(in) :: cdata
     end function c_putDouble

     function c_putComplex(opCtx, fieldPath, timebasePath, cdata) bind(C,name="putComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putComplex
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       complex(C_DOUBLE_COMPLEX), value, intent(in) :: cdata
     end function c_putComplex

     function c_putVect1DChar(opCtx, fieldPath, timebasePath, cdata, dim1) BIND(C, name="putVect1DChar")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect1DChar
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       integer(C_INT), value, intent(in) :: dim1
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect1DChar
     
     function c_putVect1DInt(opCtx, fieldPath, timebasePath, cdata, dim1) bind(C,name="putVect1DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect1DInt
       integer(C_INT), value, intent(in) :: opCtx, dim1
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect1DInt

     function c_putVect1DDouble(opCtx, fieldPath, timebasePath, cdata, dim1) bind(C,name="putVect1DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect1DDouble
       integer(C_INT), value, intent(in) :: opCtx, dim1
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect1DDouble

     function c_putVect1DComplex(opCtx, fieldPath, timebasePath, cdata, dim1) bind(C,name="putVect1DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect1DComplex
       integer(C_INT), value, intent(in) :: opCtx, dim1
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect1DComplex
     
     function c_putVect2DChar(opCtx, fieldPath, timebasePath, cdata, dim1, dim2) BIND(C, name="putVect2DChar")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect2DChar
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       integer(C_INT), value, intent(in) :: dim1, dim2
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect2DChar

     function c_putVect2DInt(opCtx, fieldPath, timebasePath, cdata, dim1, dim2) bind(C,name="putVect2DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect2DInt
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect2DInt

     function c_putVect2DDouble(opCtx, fieldPath, timebasePath, cdata, dim1, dim2) bind(C,name="putVect2DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect2DDouble
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect2DDouble

     function c_putVect2DComplex(opCtx, fieldPath, timebasePath, cdata, dim1, dim2) bind(C,name="putVect2DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect2DComplex
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect2DComplex

     function c_putVect3DInt(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3) bind(C,name="putVect3DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect3DInt
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect3DInt

     function c_putVect3DDouble(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3) bind(C,name="putVect3DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect3DDouble
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect3DDouble

     function c_putVect3DComplex(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3) bind(C,name="putVect3DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect3DComplex
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect3DComplex

     function c_putVect4DInt(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4) bind(C,name="putVect4DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect4DInt
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3, dim4
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect4DInt

     function c_putVect4DDouble(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4) bind(C,name="putVect4DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect4DDouble
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3, dim4
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect4DDouble

     function c_putVect4DComplex(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4) bind(C,name="putVect4DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect4DComplex
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3, dim4
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect4DComplex

     function c_putVect5DInt(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5) bind(C,name="putVect5DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect5DInt
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect5DInt

     function c_putVect5DDouble(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5) bind(C,name="putVect5DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect5DDouble
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect5DDouble

     function c_putVect5DComplex(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5) bind(C,name="putVect5DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect5DComplex
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect5DComplex

     function c_putVect6DInt(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5, dim6) bind(C,name="putVect6DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect6DInt
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect6DInt

     function c_putVect6DDouble(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5, dim6) bind(C,name="putVect6DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect6DDouble
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect6DDouble

     function c_putVect6DComplex(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5, dim6) bind(C,name="putVect6DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect6DComplex
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect6DComplex

     function c_putVect7DInt(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5, dim6, dim7) bind(C,name="putVect7DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect7DInt
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6, dim7
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect7DInt

     function c_putVect7DDouble(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5, dim6, dim7) bind(C,name="putVect7DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect7DDouble
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6, dim7
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect7DDouble

     function c_putVect7DComplex(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5, dim6, dim7) bind(C,name="putVect7DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_putVect7DComplex
       integer(C_INT), value, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6, dim7
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), value, intent(in) :: cdata
     end function c_putVect7DComplex

     function c_getChar(opCtx, fieldPath, timebasePath, cdata) BIND(C, name="getChar")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getChar
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       character(C_CHAR), intent(out) :: cdata
     end function c_getChar

     function c_getInt(opCtx, fieldPath, timebasePath, cdata) bind(C,name="getInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getInt
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       integer(C_INT), intent(out) :: cdata
     end function c_getInt

     function c_getDouble(opCtx, fieldPath, timebasePath, cdata) bind(C,name="getDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getDouble
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       real(C_DOUBLE), intent(out) :: cdata
     end function c_getDouble

     function c_getComplex(opCtx, fieldPath, timebasePath, cdata) bind(C,name="getComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getComplex
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       complex(C_DOUBLE_COMPLEX), intent(out) :: cdata
     end function c_getComplex

     !TODO getting vect1D strings to be checked!!! 
     !function c_getVect1DString(opCtx, fieldPath, timebasePath, cdata, dim) bind(C,name="getVect1DString")
     !use, intrinsic :: ISO_C_BINDING
     !integer(C_INT) :: c_getVect1DString
     !integer(C_INT), value, intent(in) :: opCtx
     !character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
     !integer(C_INT), intent(out) :: dim
     !end function c_getVect1DString

     function c_getVect1DChar(opCtx, fieldPath, timebasePath, cdata, dim1) BIND(C, name="getVect1DChar")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect1DChar
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1
     end function c_getVect1DChar

     function c_getVect1DInt(opCtx, fieldPath, timebasePath, cdata, dim) bind(C,name="getVect1DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect1DInt
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim
     end function c_getVect1DInt

     function c_getVect1DDouble(opCtx, fieldPath, timebasePath, cdata, dim) bind(C,name="getVect1DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect1DDouble
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim
     end function c_getVect1DDouble

     function c_getVect1DComplex(opCtx, fieldPath, timebasePath, cdata, dim) bind(C,name="getVect1DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect1DComplex
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim
     end function c_getVect1DComplex

     function c_getVect2DChar(opCtx, fieldPath, timebasePath, cdata, dim1, dim2) BIND(C, name="getVect2DChar")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect2DChar
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2
     end function c_getVect2DChar

     function c_getVect2DInt(opCtx, fieldPath, timebasePath, cdata, dim1, dim2) bind(C,name="getVect2DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect2DInt
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2
     end function c_getVect2DInt

     function c_getVect2DDouble(opCtx, fieldPath, timebasePath, cdata, dim1, dim2) bind(C,name="getVect2DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect2DDouble
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2
     end function c_getVect2DDouble

     function c_getVect2DComplex(opCtx, fieldPath, timebasePath, cdata, dim1, dim2) bind(C,name="getVect2DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect2DComplex
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2
     end function c_getVect2DComplex

     function c_getVect3DInt(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3) bind(C,name="getVect3DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect3DInt
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3
     end function c_getVect3DInt

     function c_getVect3DDouble(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3) bind(C,name="getVect3DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect3DDouble
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3
     end function c_getVect3DDouble

     function c_getVect3DComplex(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3) bind(C,name="getVect3DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect3DComplex
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3
     end function c_getVect3DComplex

     function c_getVect4DInt(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4) bind(C,name="getVect4DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect4DInt
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4
     end function c_getVect4DInt

     function c_getVect4DDouble(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4) bind(C,name="getVect4DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect4DDouble
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4
     end function c_getVect4DDouble

     function c_getVect4DComplex(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4) bind(C,name="getVect4DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect4DComplex
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4
     end function c_getVect4DComplex

     function c_getVect5DInt(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5) bind(C,name="getVect5DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect5DInt
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5
     end function c_getVect5DInt

     function c_getVect5DDouble(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5) bind(C,name="getVect5DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect5DDouble
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5
     end function c_getVect5DDouble

     function c_getVect5DComplex(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5) bind(C,name="getVect5DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect5DComplex
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5
     end function c_getVect5DComplex

     function c_getVect6DInt(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5, dim6) bind(C,name="getVect6DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect6DInt
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6
     end function c_getVect6DInt

     function c_getVect6DDouble(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5, dim6) bind(C,name="getVect6DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect6DDouble
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6
     end function c_getVect6DDouble

     function c_getVect6DComplex(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5, dim6) bind(C,name="getVect6DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect6DComplex
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6
     end function c_getVect6DComplex

     function c_getVect7DInt(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5, dim6, dim7) bind(C,name="getVect7DInt")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect7DInt
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, dim7
     end function c_getVect7DInt

     function c_getVect7DDouble(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5, dim6, dim7) bind(C,name="getVect7DDouble")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect7DDouble
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, dim7
     end function c_getVect7DDouble

     function c_getVect7DComplex(opCtx, fieldPath, timebasePath, cdata, dim1, dim2, dim3, dim4, dim5, dim6, dim7) bind(C,name="getVect7DComplex")
       use, intrinsic :: ISO_C_BINDING
       integer(C_INT) :: c_getVect7DComplex
       integer(C_INT), value, intent(in) :: opCtx
       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
       type(C_PTR), intent(out) :: cdata
       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, dim7
     end function c_getVect7DComplex

!!$     function c_beginObject(ctx, index, fieldPath, timebasePath, size) bind(C,name="beginObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_beginObject
!!$       integer(C_INT), value, intent(in) :: ctx, index, size
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$     end function c_beginObject
!!$
!!$     function c_releaseObject(aosCtx) bind(C,name="releaseObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_releaseObject
!!$       integer(C_INT), value, intent(in) :: aosCtx
!!$     end function c_releaseObject
!!$
!!$     function c_getObject(opCtx, fieldPath, timebasePath, size) bind(C,name="getObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getObject
!!$       integer(C_INT), value, intent(in) :: opCtx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       integer(C_INT), intent(out) :: size
!!$     end function c_getObject
!!$
!!$     function c_getObjectFromObject(aosCtx, fieldPath, timebasePath, idx, size) bind(C,name="getObjectFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getObjectFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       integer(C_INT), intent(out) :: size
!!$     end function c_getObjectFromObject
!!$
!!$     function c_putCharInObject(aosCtx, fieldPath, timebasePath, idx, cdata) BIND(C, name="putCharInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putCharInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       character(C_CHAR), intent(in) :: cdata
!!$     end function c_putCharInObject
!!$
!!$     function c_putIntInObject(aosCtx, fieldPath, timebasePath, idx, cdata) bind(C,name="putIntInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putIntInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, cdata
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$     end function c_putIntInObject
!!$
!!$     function c_putDoubleInObject(aosCtx, fieldPath, timebasePath, idx, cdata) bind(C,name="putDoubleInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putDoubleInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       real(C_DOUBLE), value, intent(in) :: cdata
!!$     end function c_putDoubleInObject
!!$
!!$     function c_putComplexInObject(aosCtx, fieldPath, timebasePath, idx, cdata) bind(C,name="putComplexInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putComplexInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       complex(C_DOUBLE_COMPLEX), value, intent(in) :: cdata
!!$     end function c_putComplexInObject
!!$
!!$     !TODO vect1D of string to be checked
!!$     !function c_putVect1DStringInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1) bind(C,name="putVect1DStringInObject")
!!$     !use, intrinsic :: ISO_C_BINDING
!!$     !integer(C_INT) :: c_putVect1DStringInObject
!!$     !integer(C_INT), value, intent(in) :: aosCtx, idx, dim1
!!$     !character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$     !end function c_putVect1DStringInObject
!!$
!!$     function c_putVect1DCharInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1) BIND(C, name="putVect1DCharInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect1DCharInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect1DCharInObject
!!$     
!!$     function c_putVect1DIntInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1) bind(C,name="putVect1DIntInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect1DIntInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect1DIntInObject
!!$
!!$     function c_putVect1DDoubleInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1) bind(C,name="putVect1DDoubleInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect1DDoubleInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect1DDoubleInObject
!!$
!!$     function c_putVect1DComplexInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1) bind(C,name="putVect1DComplexInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect1DComplexInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect1DComplexInObject
!!$
!!$     function c_putVect2DCharInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2) BIND(C, name="putVect2DCharInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect2DCharInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect2DCharInObject
!!$
!!$     function c_putVect2DIntInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2) bind(C,name="putVect2DIntInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect2DIntInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect2DIntInObject
!!$
!!$     function c_putVect2DDoubleInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2) bind(C,name="putVect2DDoubleInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect2DDoubleInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect2DDoubleInObject
!!$
!!$     function c_putVect2DComplexInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2) bind(C,name="putVect2DComplexInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect2DComplexInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect2DComplexInObject
!!$
!!$     function c_putVect3DIntInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3) bind(C,name="putVect3DIntInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect3DIntInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2, dim3
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect3DIntInObject
!!$
!!$     function c_putVect3DDoubleInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3) bind(C,name="putVect3DDoubleInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect3DDoubleInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2, dim3
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect3DDoubleInObject
!!$
!!$     function c_putVect3DComplexInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3) bind(C,name="putVect3DComplexInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect3DComplexInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2, dim3
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect3DComplexInObject
!!$
!!$     function c_putVect4DIntInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4) bind(C,name="putVect4DIntInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect4DIntInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect4DIntInObject
!!$
!!$     function c_putVect4DDoubleInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4) bind(C,name="putVect4DDoubleInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect4DDoubleInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect4DDoubleInObject
!!$
!!$     function c_putVect4DComplexInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4) bind(C,name="putVect4DComplexInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect4DComplexInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect4DComplexInObject
!!$
!!$     function c_putVect5DIntInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4, dim5) bind(C,name="putVect5DIntInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect5DIntInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4, dim5
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect5DIntInObject
!!$
!!$     function c_putVect5DDoubleInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4, dim5) bind(C,name="putVect5DDoubleInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect5DDoubleInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4, dim5
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect5DDoubleInObject
!!$
!!$     function c_putVect5DComplexInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4, dim5) bind(C,name="putVect5DComplexInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect5DComplexInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4, dim5
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect5DComplexInObject
!!$
!!$     function c_putVect6DIntInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4, dim5, dim6) bind(C,name="putVect6DIntInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect6DIntInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4, dim5, dim6
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect6DIntInObject
!!$
!!$     function c_putVect6DDoubleInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4, dim5, dim6) bind(C,name="putVect6DDoubleInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect6DDoubleInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4, dim5, dim6
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect6DDoubleInObject
!!$
!!$     function c_putVect6DComplexInObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4, dim5, dim6) bind(C,name="putVect6DComplexInObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_putVect6DComplexInObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4, dim5, dim6
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), value, intent(in) :: cdata
!!$     end function c_putVect6DComplexInObject
!!$
!!$
!!$     function c_getCharFromObject(aosCtx, fieldPath, timebasePath, idx, cdata) BIND(C, name="getCharFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getCharFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       character(C_CHAR), intent(out) :: cdata
!!$     end function c_getCharFromObject
!!$
!!$     function c_getIntFromObject(aosCtx, fieldPath, timebasePath, idx, cdata) bind(C,name="getIntFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getIntFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       integer(C_INT), intent(out) :: cdata
!!$     end function c_getIntFromObject
!!$
!!$     function c_getDoubleFromObject(aosCtx, fieldPath, timebasePath, idx, cdata) bind(C,name="getDoubleFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getDoubleFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       real(C_DOUBLE), intent(out) :: cdata
!!$     end function c_getDoubleFromObject
!!$
!!$     function c_getComplexFromObject(aosCtx, fieldPath, timebasePath, idx, cdata) bind(C,name="getComplexFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getComplexFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       complex(C_DOUBLE_COMPLEX), intent(out) :: cdata
!!$     end function c_getComplexFromObject
!!$
!!$     !TODO vect1D of string to be checked
!!$     !function c_getVect1DStringFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1) bind(C,name="getVect1DStringFromObject")
!!$     !use, intrinsic :: ISO_C_BINDING
!!$     !integer(C_INT) :: c_getVect1DStringFromObject
!!$     !integer(C_INT), value, intent(in) :: aosCtx, idx
!!$     !character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$     !end function c_getVect1DStringFromObject
!!$
!!$     function c_getVect1DCharFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1) BIND(C, name="getVect1DCharFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect1DCharFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1
!!$     end function c_getVect1DCharFromObject
!!$
!!$     function c_getVect1DIntFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1) bind(C,name="getVect1DIntFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect1DIntFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1
!!$     end function c_getVect1DIntFromObject
!!$
!!$     function c_getVect1DDoubleFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1) bind(C,name="getVect1DDoubleFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect1DDoubleFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1
!!$     end function c_getVect1DDoubleFromObject
!!$
!!$     function c_getVect1DComplexFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1) bind(C,name="getVect1DComplexFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect1DComplexFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1
!!$     end function c_getVect1DComplexFromObject
!!$
!!$     function c_getVect2DCharFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2) BIND(C, name="getVect2DCharFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect2DCharFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2
!!$     end function c_getVect2DCharFromObject
!!$
!!$     function c_getVect2DIntFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2) bind(C,name="getVect2DIntFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect2DIntFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2
!!$     end function c_getVect2DIntFromObject
!!$
!!$     function c_getVect2DDoubleFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2) bind(C,name="getVect2DDoubleFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect2DDoubleFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2
!!$     end function c_getVect2DDoubleFromObject
!!$
!!$     function c_getVect2DComplexFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2) bind(C,name="getVect2DComplexFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect2DComplexFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2
!!$     end function c_getVect2DComplexFromObject
!!$
!!$     function c_getVect3DIntFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3) bind(C,name="getVect3DIntFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect3DIntFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2, dim3
!!$     end function c_getVect3DIntFromObject
!!$
!!$     function c_getVect3DDoubleFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3) bind(C,name="getVect3DDoubleFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect3DDoubleFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2, dim3
!!$     end function c_getVect3DDoubleFromObject
!!$
!!$     function c_getVect3DComplexFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3) bind(C,name="getVect3DComplexFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect3DComplexFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2, dim3
!!$     end function c_getVect3DComplexFromObject
!!$
!!$     function c_getVect4DIntFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4) bind(C,name="getVect4DIntFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect4DIntFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4
!!$     end function c_getVect4DIntFromObject
!!$
!!$     function c_getVect4DDoubleFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4) bind(C,name="getVect4DDoubleFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect4DDoubleFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4
!!$     end function c_getVect4DDoubleFromObject
!!$
!!$     function c_getVect4DComplexFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4) bind(C,name="getVect4DComplexFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect4DComplexFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4
!!$     end function c_getVect4DComplexFromObject
!!$
!!$     function c_getVect5DIntFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4, dim5) bind(C,name="getVect5DIntFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect5DIntFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5
!!$     end function c_getVect5DIntFromObject
!!$
!!$     function c_getVect5DDoubleFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4, dim5) bind(C,name="getVect5DDoubleFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect5DDoubleFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5
!!$     end function c_getVect5DDoubleFromObject
!!$
!!$     function c_getVect5DComplexFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4, dim5) bind(C,name="getVect5DComplexFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect5DComplexFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5
!!$     end function c_getVect5DComplexFromObject
!!$
!!$     function c_getVect6DIntFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4, dim5, dim6) bind(C,name="getVect6DIntFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect6DIntFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6
!!$     end function c_getVect6DIntFromObject
!!$
!!$     function c_getVect6DDoubleFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4, dim5, dim6) bind(C,name="getVect6DDoubleFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect6DDoubleFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6
!!$     end function c_getVect6DDoubleFromObject
!!$
!!$     function c_getVect6DComplexFromObject(aosCtx, fieldPath, timebasePath, idx, cdata, dim1, dim2, dim3, dim4, dim5, dim6) bind(C,name="getVect6DComplexFromObject")
!!$       use, intrinsic :: ISO_C_BINDING
!!$       integer(C_INT) :: c_getVect6DComplexFromObject
!!$       integer(C_INT), value, intent(in) :: aosCtx, idx
!!$       character(C_CHAR), dimension(*), intent(in) :: fieldPath, timebasePath
!!$       type(C_PTR), intent(out) :: cdata
!!$       integer(C_INT), intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6
!!$     end function c_getVect6DComplexFromObject

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

!!$  subroutine ual_begin_write_arraystruct(ctx, idx, path, timebase, size, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: ctx, idx, size
!!$    character(*), intent(in) :: path, timebase
!!$    integer, intent(out) :: status
!!$    status = c_ual_begin_write_arraystruct(ctx, idx, trim(path)//C_NULL_CHAR, trim(timebase)//C_NULL_CHAR, size)
!!$  end subroutine ual_begin_write_arraystruct
!!$
!!$  subroutine ual_begin_read_arraystruct(ctx, idx, path, timebase, size, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: ctx, idx
!!$    character(*), intent(in) :: path, timebase
!!$    integer, intent(out) :: size, status
!!$    integer(C_INT) :: csize
!!$    status = c_ual_begin_read_arraystruct(ctx, idx, trim(path)//C_NULL_CHAR, trim(timebase)//C_NULL_CHAR, csize)
!!$    if (status.eq.0) then
!!$       size = csize
!!$    end if
!!$  end subroutine ual_begin_read_arraystruct


  !WHAT TO DO WHEN EXPECTING VOID TYPE TO BE PASSED IN FORTRAN???
  !subroutine ual_put_in_structarray(ctx, fieldname, idx, data, datatype, dim, size)
  !subroutine ual_get_from_structarray(ctx, fieldname, idx, data, datatype, dim, size)



  !!! old API !!!

  subroutine imas_create(name, shot, run, refShot, refRun, pulseCtx)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    character(*), intent(in) :: name
    integer, intent(in) :: shot, run, refShot, refRun
    integer, intent(out) :: pulseCtx
    integer :: status
    
    status = c_ual_create(trim(name)//C_NULL_CHAR, shot, run, refShot, &
         refRun, pulseCtx)
  end subroutine imas_create

  subroutine imas_open(name, shot, run, pulseCtx)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    character(*), intent(in) :: name
    integer, intent(in) :: shot, run
    integer, intent(out) :: pulseCtx
    integer :: status
    status = c_ual_open(trim(name)//C_NULL_CHAR, shot, run, pulseCtx)
  end subroutine imas_open

  subroutine imas_create_env(name, shot, run, refShot, refRun, pulseCtx, user, tokamak, version)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    character(*), intent(in) :: name, user, tokamak, version
    integer, intent(in) :: shot, run, refShot, refRun
    integer, intent(out) :: pulseCtx
    integer :: status
    status = c_ual_create_env(trim(name)//C_NULL_CHAR, shot, run, refShot, refRun, pulseCtx, trim(user)//C_NULL_CHAR, trim(tokamak)//C_NULL_CHAR, trim(version)//C_NULL_CHAR)
  end subroutine imas_create_env

  subroutine imas_open_env(name, shot, run, pulseCtx, user, tokamak, version)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    character(*), intent(in) :: name, user, tokamak, version
    integer, intent(in) :: shot, run
    integer, intent(out) :: pulseCtx
    integer :: status
    status = c_ual_open_env(trim(name)//C_NULL_CHAR, shot, run, pulseCtx, trim(user)//C_NULL_CHAR, trim(tokamak)//C_NULL_CHAR, trim(version)//C_NULL_CHAR)
  end subroutine imas_open_env

  subroutine imas_close(pulseCtx)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pulseCtx
    integer :: status
    status = c_ual_close(pulseCtx)
  end subroutine imas_close

  subroutine begin_ids_get(pulseCtx, path, opCtx)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pulseCtx
    character(*), intent(in) :: path
    integer, intent(out) :: opCtx
    opCtx = c_beginDataobjectGet(pulseCtx, trim(path)//C_NULL_CHAR)
  end subroutine begin_ids_get

  subroutine end_ids_get(opCtx, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    integer, intent(out) :: status
    status = c_endDataobjectGet(opCtx)
  end subroutine end_ids_get

  subroutine begin_ids_get_slice(pulseCtx, path, time, interpMode, opCtx)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pulseCtx, interpMode
    character(*), intent(in) :: path
    real(8), intent(in) :: time
    integer, intent(out) :: opCtx
    opCtx = c_beginDataobjectGetSlice(pulseCtx, trim(path)//C_NULL_CHAR, time, interpMode)
  end subroutine begin_ids_get_slice

  subroutine end_ids_get_slice(opCtx, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    integer, intent(out) :: status
    status = c_endDataobjectGetSlice(opCtx)
  end subroutine end_ids_get_slice
  
  subroutine begin_ids_put_timed(pulseCtx, path, opCtx)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pulseCtx
    character(*), intent(in) :: path
    integer, intent(out) :: opCtx
    opCtx = c_beginDataobjectPutTimed(pulseCtx, trim(path)//C_NULL_CHAR)
  end subroutine begin_ids_put_timed

  subroutine end_ids_put_timed(opCtx, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    integer, intent(out) :: status
    status = c_endDataobjectPutTimed(opCtx)
  end subroutine end_ids_put_timed

  subroutine begin_ids_put_non_timed(pulseCtx, path, opCtx)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pulseCtx
    character(*), intent(in) :: path
    integer, intent(out) :: opCtx
    opCtx = c_beginDataobjectPutNonTimed(pulseCtx, trim(path)//C_NULL_CHAR)
  end subroutine begin_ids_put_non_timed

  subroutine end_ids_put_non_timed(opCtx, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    integer, intent(out) :: status
    status = c_endDataobjectPutNonTimed(opCtx)
  end subroutine end_ids_put_non_timed

  subroutine begin_ids_put_slice(pulseCtx, path, time, opCtx)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pulseCtx
    character(*), intent(in) :: path
    real(8), intent(in) :: time
    integer, intent(out) :: opCtx
    opCtx = c_beginDataobjectPutSlice(pulseCtx, trim(path)//C_NULL_CHAR, time)
  end subroutine begin_ids_put_slice

  subroutine end_ids_put_slice(opCtx, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opctx
    integer, intent(out) :: status
    status = c_endDataobjectPutSlice(opCtx)
  end subroutine end_ids_put_slice

  subroutine delete_data(opCtx, fieldPath, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath
    integer, intent(out) :: status
    status = c_deleteData(opCtx, trim(fieldPath)//C_NULL_CHAR)
  end subroutine delete_data
  
!!$  subroutine imas_flush_ids_mem_cache(pulseCtx, path, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: pulseCtx
!!$    character(*), intent(in) :: path
!!$    integer, intent(out) :: status
!!$    status = c_ual_flush_dataobject_mem_cache(pulseCtx, trim(path)//C_NULL_CHAR)
!!$  end subroutine imas_flush_ids_mem_cache
!!$
!!$  subroutine imas_discard_ids_mem_cache(pulseCtx, path, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: pulseCtx
!!$    character(*), intent(in) :: path
!!$    integer, intent(out) :: status
!!$    status = c_ual_discard_dataobject_mem_cache(pulseCtx, trim(path)//C_NULL_CHAR)
!!$  end subroutine imas_discard_ids_mem_cache


  subroutine put_char(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character, intent(in) :: data
    integer, intent(out) :: status
    status = c_putChar(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, data)
  end subroutine put_char

  subroutine put_int(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, data
    character(*), intent(in) :: fieldPath, timebasePath
    integer, intent(out) :: status
    status = c_putInt(opctx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, data)
  end subroutine put_int
  
  subroutine put_double(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), intent(in) :: data
    integer, intent(out) :: status
    status = c_putDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, data)
  end subroutine put_double

  subroutine put_complex(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), intent(in) :: data
    integer, intent(out) :: status
    status = c_putComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, data)
  end subroutine put_complex

  !TODO vect1DString cases to be clarified!!! 
  !subroutine put_vect1_string(opCtx, fieldPath, data, dim1, status)
  !use, intrinsic :: ISO_C_BINDING
  !implicit none
  !integer, intent(in) :: opCtx, dim1
  !character(*), intent(in) :: fieldPath
  !integer, intent(out) :: status
  !end subroutine put_vect1d_string

  subroutine put_string(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath, data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    character(C_CHAR), dimension(:), pointer :: cdata
    integer(C_INT) :: csize
    integer :: i
    csize = len_trim(data)
    allocate(cdata(csize))
    do i=1,csize
       cdata(i) = data(i:i)
    end do
    cptr = C_LOC(cdata(1))
    status = c_putVect1DChar(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, csize)
    deallocate(cdata)
  end subroutine put_string

  subroutine put_vect1d_int(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1))
    status = c_putVect1DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1)
  end subroutine put_vect1d_int

  subroutine put_vect1d_double(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1))
    status = c_putVect1DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1)
  end subroutine put_vect1d_double

  subroutine put_vect1d_complex(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1))
    status = c_putVect1DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1)
  end subroutine put_vect1d_complex

  subroutine put_vect1d_string(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none 
    integer, intent(in) :: opCtx, dim1
    character(*), intent(in) :: fieldPath, timebasePath
    character(132), dimension(:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    character(C_CHAR), dimension(:,:), pointer :: cdata
    integer(C_INT) :: csize1, csize2
    integer :: i,j
    csize1 = dim1
    csize2 = MAXVAL(len_trim(data(1:dim1)))
    allocate(cdata(csize1, csize2))
    do i=1,csize1
       do j=1,csize2
          cdata(i,j) = data(i)(j:j)
       end do
    end do
    cptr = C_LOC(cdata(1,1))
    status = c_putVect2DChar(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, csize1, csize2)    
    deallocate(cdata)
  end subroutine put_vect1d_string

  subroutine put_vect2d_int(opCtx, fieldPath, timebasePath, data, dim1, dim2, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1))
    status = c_putVect2DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2)
  end subroutine put_vect2d_int

  subroutine put_vect2d_double(opCtx, fieldPath, timebasePath, data, dim1, dim2, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1))
    status = c_putVect2DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2)
  end subroutine put_vect2d_double

  subroutine put_vect2d_complex(opCtx, fieldPath, timebasePath, data, dim1, dim2, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1))
    status = c_putVect2DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2)
  end subroutine put_vect2d_complex
  
  subroutine put_vect3d_int(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1))
    status = c_putVect3DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3)
  end subroutine put_vect3d_int

  subroutine put_vect3d_double(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1))
    status = c_putVect3DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3)
  end subroutine put_vect3d_double

  subroutine put_vect3d_complex(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1))
    status = c_putVect3DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3)
  end subroutine put_vect3d_complex
  
  subroutine put_vect4d_int(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1,1))
    status = c_putVect4DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3, dim4)
  end subroutine put_vect4d_int

  subroutine put_vect4d_double(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1,1))
    status = c_putVect4DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3, dim4)
  end subroutine put_vect4d_double

  subroutine put_vect4d_complex(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1,1))
    status = c_putVect4DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3, dim4)
  end subroutine put_vect4d_complex
  
  subroutine put_vect5d_int(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1,1,1))
    status = c_putVect5DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3, dim4, dim5)
  end subroutine put_vect5d_int

  subroutine put_vect5d_double(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1,1,1))
    status = c_putVect5DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3, dim4, dim5)
  end subroutine put_vect5d_double

  subroutine put_vect5d_complex(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1,1,1))
    status = c_putVect5DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3, dim4, dim5)
  end subroutine put_vect5d_complex
  
  subroutine put_vect6d_int(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, dim6, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1,1,1,1))
    status = c_putVect6DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3, dim4, dim5, dim6)
  end subroutine put_vect6d_int

  subroutine put_vect6d_double(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, dim6, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1,1,1,1))
    status = c_putVect6DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3, dim4, dim5, dim6)
  end subroutine put_vect6d_double

  subroutine put_vect6d_complex(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, dim6, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1,1,1,1))
    status = c_putVect6DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3, dim4, dim5, dim6)
  end subroutine put_vect6d_complex
  
  subroutine put_vect7d_int(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, dim6, dim7, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6, dim7
    character(*), intent(in) :: fieldPath, timebasePath
    integer, dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1,1,1,1,1))
    status = c_putVect7DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3, dim4, dim5, dim6, dim7)
  end subroutine put_vect7d_int

  subroutine put_vect7d_double(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, dim6, dim7, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6, dim7
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1,1,1,1,1))
    status = c_putVect7DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3, dim4, dim5, dim6, dim7)
  end subroutine put_vect7d_double

  subroutine put_vect7d_complex(opCtx, fieldPath, timebasePath, data, dim1, dim2, dim3, dim4, dim5, dim6, dim7, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx, dim1, dim2, dim3, dim4, dim5, dim6, dim7
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:,:,:,:,:,:,:), pointer :: data
    integer, intent(out) :: status
    type(C_PTR) :: cptr
    cptr = C_LOC(data(1,1,1,1,1,1,1))
    status = c_putVect7DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, cptr, dim1, dim2, dim3, dim4, dim5, dim6, dim7)
  end subroutine put_vect7d_complex
  

  subroutine get_char(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character(1), intent(inout) :: data
    integer, intent(out) :: status
    character(C_CHAR) :: cdata
    status = c_getChar(opCtx, trim(fieldPath)//C_NULL_CHAR,&
         trim(timebasePath)//C_NULL_CHAR, cdata)
    if (status.eq.0) data = cdata
  end subroutine get_char

  subroutine get_int(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    integer, intent(inout) :: data
    integer, intent(out) :: status
    integer(C_INT) :: cdata
    status = c_getInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cdata)
    if (status.eq.0) data = cdata
  end subroutine get_int

  subroutine get_double(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), intent(inout) :: data
    integer, intent(out) :: status
    real(C_DOUBLE) :: cdata
    status = c_getDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cdata)
    if (status.eq.0) data = cdata
  end subroutine get_double

  subroutine get_complex(opCtx, fieldPath, timebasePath, data, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), intent(inout) :: data
    integer, intent(out) :: status
    complex(C_DOUBLE_COMPLEX) :: cdata
    status = c_getComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cdata)
    if (status.eq.0) data = cdata
  end subroutine get_complex

  !TODO strings to be checked !
  !subroutine get_vect1d_string(opCtx, fieldPath, timebasePath, data, dim1, status)
  !use, intrinsic :: ISO_C_BINDING
  !implicit none
  !integer, intent(in) :: opCtx
  !character(*), intent(in) :: fieldPath, timebasePath
  !end subroutine get_vect1d_string

  subroutine get_vect1D_char(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    character, dimension(:), pointer :: data
    integer, intent(out) :: dim1, status
    type(C_PTR) :: cptr
    integer(C_INT) :: csize
    status = c_getVect1DChar(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, csize)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize/))
       dim1 = csize
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1
    status = c_getVect1DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, csize1)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1/))
       dim1 = csize1
    end if
  end subroutine get_vect1d_int

  subroutine get_vect1d_double(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    real(8), dimension(:), pointer :: data
    integer, intent(out) :: dim1, status
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1
    status = c_getVect1DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, csize1)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1/))
       dim1 = csize1
    end if
  end subroutine get_vect1d_double

  subroutine get_vect1d_complex(opCtx, fieldPath, timebasePath, data, dim1, status)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: opCtx
    character(*), intent(in) :: fieldPath, timebasePath
    complex(8), dimension(:), pointer :: data
    integer, intent(out) :: dim1, status
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1
    status = c_getVect1DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, csize1)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1/))
       dim1 = csize1
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2
    status = c_getVect2DChar(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2/))
       dim1 = csize1
       dim2 = csize2
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
       allocate(data(size1))
       do i=1,size1
          tmpstr = ' '
          do j=1,size2
             tmpstr(j:j) = tmpdata(i,j)
          end do
          data(i) = trim(tmpstr)
       end do
       dim1 = size1
       if (size1.gt.0) then
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2
    status = c_getVect2DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2/))
       dim1 = csize1
       dim2 = csize2
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2
    status = c_getVect2DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2/))
       dim1 = csize1
       dim2 = csize2
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2
    status = c_getVect2DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2/))
       dim1 = csize1
       dim2 = csize2
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3
    status = c_getVect3DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3
    status = c_getVect3DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3
    status = c_getVect3DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3, csize4
    status = c_getVect4DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
       dim4 = csize4
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3, csize4
    status = c_getVect4DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
       dim4 = csize4
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3, csize4
    status = c_getVect4DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
       dim4 = csize4
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5
    status = c_getVect5DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
       dim4 = csize4
       dim5 = csize5
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5
    status = c_getVect5DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
       dim4 = csize4
       dim5 = csize5
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5
    status = c_getVect5DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
       dim4 = csize4
       dim5 = csize5
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5, csize6
    status = c_getVect6DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5, csize6)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5,csize6/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
       dim4 = csize4
       dim5 = csize5
       dim6 = csize6
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5, csize6
    status = c_getVect6DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5, csize6)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5,csize6/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
       dim4 = csize4
       dim5 = csize5
       dim6 = csize6
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5, csize6
    status = c_getVect6DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5, csize6)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5,csize6/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
       dim4 = csize4
       dim5 = csize5
       dim6 = csize6
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5, csize6, csize7
    status = c_getVect7DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5, csize6, csize7)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5,csize6,csize7/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
       dim4 = csize4
       dim5 = csize5
       dim6 = csize6
       dim7 = csize7
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5, csize6, csize7
    status = c_getVect7DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5, csize6, csize7)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5,csize6,csize7/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
       dim4 = csize4
       dim5 = csize5
       dim6 = csize6
       dim7 = csize7
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5, csize6, csize7
    status = c_getVect7DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5, csize6, csize7)
    if (status.eq.0) then
       call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5,csize6,csize7/))
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
       dim4 = csize4
       dim5 = csize5
       dim6 = csize6
       dim7 = csize7
    end if
  end subroutine get_vect7d_complex


  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! array of structures !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!$  subroutine begin_object(ctx, index, fieldPath, timebasePath, size, aosCtx)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: ctx, index, size
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, intent(out) :: aosCtx
!!$    aosCtx = c_beginObject(ctx, index-1, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, size)
!!$  end subroutine begin_object
!!$
!!$  subroutine release_object(aosCtx, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx
!!$    integer, intent(out) :: status
!!$    status = c_releaseObject(aosCtx)
!!$  end subroutine release_object
!!$
!!$  subroutine get_object(opCtx, fieldPath, timebasePath, size, aosCtx)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: opCtx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, intent(out) :: size, aosCtx
!!$    integer(C_INT) :: csize
!!$    aosCtx = c_getObject(opCtx, trim(fieldPath)//C_NULL_CHAR, &
!!$         trim(timebasePath)//C_NULL_CHAR, csize)
!!$    if (aosCtx.ge.0) size = csize
!!$  end subroutine get_object
!!$
!!$  subroutine get_object_from_object(aosCtx, fieldPath, timebasePath, idx, size, subAosCtx)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, intent(out) :: size, subAosCtx
!!$    integer(C_INT) :: csize
!!$    subAosCtx = c_getObjectFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, csize)
!!$    if (subAosCtx.ge.0) size = csize
!!$  end subroutine get_object_from_object
!!$
!!$  subroutine put_string_in_object(aosCtx, fieldPath, idx, data, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, data
!!$    integer, intent(out) :: status
!!$    status = c_putStringInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, idx, trim(data)//C_NULL_CHAR)
!!$  end subroutine put_string_in_object
!!$
!!$  subroutine put_char_in_object(aosCtx, fieldPath, timebasePath, idx, data, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    character, intent(in) :: data
!!$    integer, intent(out) :: status
!!$    status = c_putCharInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, data)
!!$  end subroutine put_char_in_object
!!$
!!$  subroutine put_int_in_object(aosCtx, fieldPath, timebasePath, idx, data, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx, data
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, intent(out) :: status
!!$    status = c_putIntInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, data)
!!$  end subroutine put_int_in_object
!!$
!!$  subroutine put_double_in_object(aosCtx, fieldPath, timebasePath, idx, data, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), intent(in) :: data
!!$    integer, intent(out) :: status
!!$    status = c_putDoubleInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, data)
!!$  end subroutine put_double_in_object
!!$
!!$  subroutine put_complex_in_object(aosCtx, fieldPath, timebasePath, idx, data, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), intent(in) :: data
!!$    integer, intent(out) :: status
!!$    status = c_putComplexInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, data)
!!$  end subroutine put_complex_in_object
!!$
!!$  subroutine put_string_in_object(aosCtx, fieldPath, timebasePath, idx, data, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx 
!!$    character(*), intent(in) :: fieldPath, timebasePath, data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    character(C_CHAR), dimension(:), pointer :: cdata
!!$    integer(C_INT) :: csize
!!$    integer :: i
!!$    csize = len_trim(data)
!!$    allocate(cdata(csize))
!!$    do i=1,csize
!!$       cdata(i) = data(i:i)
!!$    end do
!!$    cptr = C_LOC(cdata(1))
!!$    status = c_putVect1DCharInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize)
!!$    deallocate(cdata)
!!$  end subroutine put_string_in_object
!!$
!!$  !TODO vect1D of string???
!!$  !subroutine put_vect1d_string_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, status)
!!$  !use, intrinsic :: ISO_C_BINDING
!!$  !implicit none
!!$  !integer, intent(in) :: aosCtx, idx, dim1
!!$  !end subroutine put_vect1d_string_in_object
!!$
!!$  subroutine put_vect1d_int_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx, dim1
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, dimension(:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1))
!!$    status = c_putVect1DIntInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NuLL_CHAR, idx-1, cptr, dim1)
!!$  end subroutine put_vect1d_int_in_object
!!$
!!$  subroutine put_vect1d_double_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx, dim1
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), dimension(:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1))
!!$    status = c_putVect1DDoubleInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, dim1)
!!$  end subroutine put_vect1d_double_in_object
!!$
!!$  subroutine put_vect1d_complex_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none 
!!$    integer, intent(in) :: aosCtx, idx, dim1
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), dimension(:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1))
!!$    status = c_putVect1DComplexInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, dim1)
!!$  end subroutine put_vect1d_complex_in_object
!!$
!!$  subroutine put_vect1d_string_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none 
!!$    integer, intent(in) :: aosCtx, idx, dim1
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    character(132), dimension(:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    character(C_CHAR), dimension(:,:), pointer :: cdata
!!$    integer(C_INT) :: csize1, csize2
!!$    integer :: i,j
!!$    csize1 = dim1
!!$    csize2 = MAXVAL(len_trim(data(1:dim1)))
!!$    allocate(cdata(csize1, csize2))
!!$    do i=1,csize1
!!$       do j=1,csize2
!!$          cdata(i,j) = data(i)(j:j)
!!$       end do
!!$    end do
!!$    cptr = C_LOC(cdata(1,1))
!!$    status = c_putVect2DCharInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2)    
!!$    deallocate(cdata)
!!$  end subroutine put_vect1d_string_in_object
!!$
!!$  subroutine put_vect2d_int_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, dimension(:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1))
!!$    status = c_putVect2DIntInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NuLL_CHAR, idx-1, cptr, dim1, dim2)
!!$  end subroutine put_vect2d_int_in_object
!!$
!!$  subroutine put_vect2d_double_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), dimension(:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1))
!!$    status = c_putVect2DDoubleInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, dim1, dim2)
!!$  end subroutine put_vect2d_double_in_object
!!$
!!$  subroutine put_vect2d_complex_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none 
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), dimension(:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1))
!!$    status = c_putVect2DComplexInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, dim1, dim2)
!!$  end subroutine put_vect2d_complex_in_object
!!$
!!$  subroutine put_vect3d_int_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2, dim3
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, dimension(:,:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1,1))
!!$    status = c_putVect3DIntInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NuLL_CHAR, idx-1, cptr, dim1, dim2, dim3)
!!$  end subroutine put_vect3d_int_in_object
!!$
!!$  subroutine put_vect3d_double_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2, dim3
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), dimension(:,:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1,1))
!!$    status = c_putVect3DDoubleInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, dim1, dim2, dim3)
!!$  end subroutine put_vect3d_double_in_object
!!$
!!$  subroutine put_vect3d_complex_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none 
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2, dim3
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), dimension(:,:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1,1))
!!$    status = c_putVect3DComplexInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, dim1, dim2, dim3)
!!$  end subroutine put_vect3d_complex_in_object
!!$
!!$  subroutine put_vect4d_int_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, dimension(:,:,:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1,1,1))
!!$    status = c_putVect4DIntInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NuLL_CHAR, idx-1, cptr, dim1, dim2, dim3, dim4)
!!$  end subroutine put_vect4d_int_in_object
!!$
!!$  subroutine put_vect4d_double_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), dimension(:,:,:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1,1,1))
!!$    status = c_putVect4DDoubleInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, dim1, dim2, dim3, dim4)
!!$  end subroutine put_vect4d_double_in_object
!!$
!!$  subroutine put_vect4d_complex_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none 
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), dimension(:,:,:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1,1,1))
!!$    status = c_putVect4DComplexInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, dim1, dim2, dim3, dim4)
!!$  end subroutine put_vect4d_complex_in_object
!!$
!!$  subroutine put_vect5d_int_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, dim5, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4, dim5
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, dimension(:,:,:,:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1,1,1,1))
!!$    status = c_putVect5DIntInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NuLL_CHAR, idx-1, cptr, dim1, dim2, dim3, dim4, dim5)
!!$  end subroutine put_vect5d_int_in_object
!!$
!!$  subroutine put_vect5d_double_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, dim5, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4, dim5
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), dimension(:,:,:,:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1,1,1,1))
!!$    status = c_putVect5DDoubleInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, dim1, dim2, dim3, dim4, dim5)
!!$  end subroutine put_vect5d_double_in_object
!!$
!!$  subroutine put_vect5d_complex_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, dim5, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none 
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4, dim5
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), dimension(:,:,:,:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1,1,1,1))
!!$    status = c_putVect5DComplexInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, dim1, dim2, dim3, dim4, dim5)
!!$  end subroutine put_vect5d_complex_in_object
!!$
!!$  subroutine put_vect6d_int_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, dim5, dim6, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4, dim5, dim6
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, dimension(:,:,:,:,:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1,1,1,1,1))
!!$    status = c_putVect6DIntInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NuLL_CHAR, idx-1, cptr, dim1, dim2, dim3, dim4, dim5, dim6)
!!$  end subroutine put_vect6d_int_in_object
!!$
!!$  subroutine put_vect6d_double_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, dim5, dim6, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4, dim5, dim6
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), dimension(:,:,:,:,:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1,1,1,1,1))
!!$    status = c_putVect6DDoubleInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, dim1, dim2, dim3, dim4, dim5, dim6)
!!$  end subroutine put_vect6d_double_in_object
!!$
!!$  subroutine put_vect6d_complex_in_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, dim5, dim6, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none 
!!$    integer, intent(in) :: aosCtx, idx, dim1, dim2, dim3, dim4, dim5, dim6
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), dimension(:,:,:,:,:,:), pointer :: data
!!$    integer, intent(out) :: status
!!$    type(C_PTR) :: cptr
!!$    cptr = C_LOC(data(1,1,1,1,1,1))
!!$    status = c_putVect6DComplexInObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, dim1, dim2, dim3, dim4, dim5, dim6)
!!$  end subroutine put_vect6d_complex_in_object
!!$
!!$  subroutine get_string_from_object(aosCtx, fieldPath, idx, data, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath
!!$    character(STRMAXLEN), intent(out) :: data
!!$    integer, intent(out) :: status
!!$    integer :: i
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize
!!$    character, dimension(:), pointer :: tmpdata
!!$    status = c_getStringFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, idx, cptr, csize)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, tmpdata, (/csize/))
!!$       data = ' '
!!$       do i=1,csize
!!$          data(i:i) = tmpdata(i)
!!$       end do
!!$       deallocate(tmpdata)
!!$    end if
!!$  end subroutine get_string_from_object
!!$
!!$  subroutine get_char_from_object(aosCtx, fieldPath, timebasePath, idx, data, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    character(1), intent(out) :: data
!!$    integer, intent(out) :: status
!!$    character(C_CHAR) :: cdata
!!$    status = c_getCharFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cdata)
!!$    if (status.eq.0) data = cdata
!!$  end subroutine get_char_from_object
!!$    
!!$  subroutine get_int_from_object(aosCtx, fieldPath, timebasePath, idx, data, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, intent(out) :: data, status
!!$    integer(C_INT) :: cdata
!!$    status = c_getIntFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cdata)
!!$    if (status.eq.0) data = cdata
!!$  end subroutine get_int_from_object
!!$
!!$  subroutine get_double_from_object(aosCtx, fieldPath, timebasePath, idx, data, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none 
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), intent(out) :: data
!!$    integer, intent(out) :: status
!!$    real(C_DOUBLE) :: cdata
!!$    status = c_getDoubleFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cdata)
!!$    if (status.eq.0) data = cdata
!!$  end subroutine get_double_from_object
!!$  
!!$  subroutine get_complex_from_object(aosCtx, fieldPath, timebasePath, idx, data, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none 
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), intent(out) :: data
!!$    integer, intent(out) :: status
!!$    complex(C_DOUBLE_COMPLEX) :: cdata
!!$    status = c_getComplexFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cdata)
!!$    if (status.eq.0) data = cdata
!!$  end subroutine get_complex_from_object
!!$
!!$  !TODO vect1D of string???
!!$  !subroutine get_vect1d_string_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, status)
!!$  !use, intrinsic :: ISO_C_BINDING
!!$  !implicit none
!!$  !integer, intent(in) :: aosCtx, idx
!!$  !character(*), intent(in) :: fieldPath, timebasePath
!!$  !end subroutine get_vect1d_string_from_object
!!$
!!$  subroutine get_vect1d_char_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    character, dimension(:), pointer :: data
!!$    integer, intent(out) :: dim1, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize
!!$    status = c_getVect1DCharFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize/))
!!$       dim1 = csize
!!$    end if
!!$  end subroutine get_vect1d_char_from_object
!!$
!!$  subroutine get_string_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    character(STRMAXLEN), intent(out) :: data
!!$    integer, intent(out) :: dim1, status
!!$    character, dimension(:), pointer :: tmpdata
!!$    integer :: size,i
!!$    call get_vect1D_char_from_object(aosCtx, fieldPath, timebasePath, idx, tmpdata, size, status)
!!$    data = ' '
!!$    if (status.eq.0) then
!!$       do i=1,size
!!$          data(i:i) = tmpdata(i)
!!$       end do
!!$       call c_free(C_LOC(tmpdata))
!!$       nullify(tmpdata)
!!$       dim1 = size
!!$    end if
!!$  end subroutine get_string_from_object
!!$
!!$  subroutine get_vect1d_int_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, dimension(:), pointer :: data
!!$    integer, intent(out) :: dim1, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1
!!$    status = c_getVect1DIntFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1/))
!!$       dim1 = csize1
!!$    end if
!!$  end subroutine get_vect1d_int_from_object
!!$
!!$  subroutine get_vect1d_double_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), dimension(:), pointer :: data
!!$    integer, intent(out) :: dim1, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1
!!$    status = c_getVect1DDoubleFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1/))
!!$       dim1 = csize1
!!$    end if
!!$  end subroutine get_vect1d_double_from_object
!!$
!!$  subroutine get_vect1d_complex_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), dimension(:), pointer :: data
!!$    integer, intent(out) :: dim1, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1
!!$    status = c_getVect1DComplexFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1/))
!!$       dim1 = csize1
!!$    end if
!!$  end subroutine get_vect1d_complex_from_object
!!$
!!$  subroutine get_vect2D_char_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    character, dimension(:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2
!!$    status = c_getVect2DCharFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$    end if
!!$  end subroutine get_vect2D_char_from_object
!!$
!!$  subroutine get_vect1D_string_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    character(132), dimension(:), pointer :: data
!!$    integer, intent(out) :: dim1, status
!!$    character, dimension(:,:), pointer :: tmpdata
!!$    character(132) :: tmpstr
!!$    integer :: size1, size2, i, j
!!$    call get_vect2D_char_from_object(aosCtx, fieldPath, timebasePath, idx, tmpdata, size1, size2, status)
!!$    if (status.eq.0) then
!!$       allocate(data(size1))
!!$       do i=1,size1
!!$          tmpstr = ' '
!!$          do j=1,size2
!!$             tmpstr(j:j) = tmpdata(i,j)
!!$          end do
!!$          data(i) = trim(tmpstr)
!!$       end do
!!$       dim1 = size1
!!$       call c_free(C_LOC(tmpdata))
!!$       nullify(tmpdata)
!!$    end if
!!$  end subroutine get_vect1D_string_from_object
!!$
!!$  subroutine get_vect2d_int_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, dimension(:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2
!!$    status = c_getVect2DIntFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$    end if
!!$  end subroutine get_vect2d_int_from_object
!!$
!!$  subroutine get_vect2d_double_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), dimension(:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2
!!$    status = c_getVect2DDoubleFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$    end if
!!$  end subroutine get_vect2d_double_from_object
!!$
!!$  subroutine get_vect2d_complex_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), dimension(:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2
!!$    status = c_getVect2DComplexFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$    end if
!!$  end subroutine get_vect2d_complex_from_object
!!$
!!$  subroutine get_vect3d_int_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, dimension(:,:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, dim3, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2, csize3
!!$    status = c_getVect3DIntFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2, csize3)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2, csize3/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$       dim3 = csize3
!!$    end if
!!$  end subroutine get_vect3d_int_from_object
!!$
!!$  subroutine get_vect3d_double_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), dimension(:,:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, dim3, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2, csize3
!!$    status = c_getVect3DDoubleFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2, csize3)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2, csize3/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$       dim3 = csize3
!!$    end if
!!$  end subroutine get_vect3d_double_from_object
!!$
!!$  subroutine get_vect3d_complex_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), dimension(:,:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, dim3, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2, csize3
!!$    status = c_getVect3DComplexFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2, csize3)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2, csize3/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$       dim3 = csize3
!!$    end if
!!$  end subroutine get_vect3d_complex_from_object
!!$
!!$  subroutine get_vect4d_int_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, dimension(:,:,:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, dim3, dim4, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2, csize3, csize4
!!$    status = c_getVect4DIntFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2, csize3, csize4)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2, csize3, csize4/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$       dim3 = csize3
!!$       dim4 = csize4
!!$    end if
!!$  end subroutine get_vect4d_int_from_object
!!$
!!$  subroutine get_vect4d_double_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), dimension(:,:,:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, dim3, dim4, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2, csize3, csize4
!!$    status = c_getVect4DDoubleFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2, csize3, csize4)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2, csize3, csize4/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$       dim3 = csize3
!!$       dim4 = csize4
!!$    end if
!!$  end subroutine get_vect4d_double_from_object
!!$
!!$  subroutine get_vect4d_complex_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), dimension(:,:,:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, dim3, dim4, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2, csize3, csize4
!!$    status = c_getVect4DComplexFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2, csize3, csize4)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2, csize3, csize4/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$       dim3 = csize3
!!$       dim4 = csize4
!!$    end if
!!$  end subroutine get_vect4d_complex_from_object
!!$
!!$  subroutine get_vect5d_int_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, dim5, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, dimension(:,:,:,:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5
!!$    status = c_getVect5DIntFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2, csize3, csize4, csize5)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2, csize3, csize4, csize5/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$       dim3 = csize3
!!$       dim4 = csize4
!!$       dim5 = csize5
!!$    end if
!!$  end subroutine get_vect5d_int_from_object
!!$
!!$  subroutine get_vect5d_double_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, dim5, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), dimension(:,:,:,:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5
!!$    status = c_getVect5DDoubleFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2, csize3, csize4, csize5)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2, csize3, csize4, csize5/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$       dim3 = csize3
!!$       dim4 = csize4
!!$       dim5 = csize5
!!$    end if
!!$  end subroutine get_vect5d_double_from_object
!!$
!!$  subroutine get_vect5d_complex_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, dim5, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), dimension(:,:,:,:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5
!!$    status = c_getVect5DComplexFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2, csize3, csize4, csize5)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2, csize3, csize4, csize5/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$       dim3 = csize3
!!$       dim4 = csize4
!!$       dim5 = csize5
!!$    end if
!!$  end subroutine get_vect5d_complex_from_object
!!$
!!$  subroutine get_vect6d_int_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, dim5, dim6, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    integer, dimension(:,:,:,:,:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5, csize6
!!$    status = c_getVect6DIntFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2, csize3, csize4, csize5, csize6)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2, csize3, csize4, csize5, csize6/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$       dim3 = csize3
!!$       dim4 = csize4
!!$       dim5 = csize5
!!$       dim6 = csize6
!!$    end if
!!$  end subroutine get_vect6d_int_from_object
!!$
!!$  subroutine get_vect6d_double_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, dim5, dim6, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    real(8), dimension(:,:,:,:,:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5, csize6
!!$    status = c_getVect6DDoubleFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2, csize3, csize4, csize5, csize6)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2, csize3, csize4, csize5, csize6/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$       dim3 = csize3
!!$       dim4 = csize4
!!$       dim5 = csize5
!!$       dim6 = csize6
!!$    end if
!!$  end subroutine get_vect6d_double_from_object
!!$
!!$  subroutine get_vect6d_complex_from_object(aosCtx, fieldPath, timebasePath, idx, data, dim1, dim2, dim3, dim4, dim5, dim6, status)
!!$    use, intrinsic :: ISO_C_BINDING
!!$    implicit none
!!$    integer, intent(in) :: aosCtx, idx
!!$    character(*), intent(in) :: fieldPath, timebasePath
!!$    complex(8), dimension(:,:,:,:,:,:), pointer :: data
!!$    integer, intent(out) :: dim1, dim2, dim3, dim4, dim5, dim6, status
!!$    type(C_PTR) :: cptr
!!$    integer(C_INT) :: csize1, csize2, csize3, csize4, csize5, csize6
!!$    status = c_getVect6DComplexFromObject(aosCtx, trim(fieldPath)//C_NULL_CHAR, trim(timebasePath)//C_NULL_CHAR, idx-1, cptr, csize1, csize2, csize3, csize4, csize5, csize6)
!!$    if (status.eq.0) then
!!$       call C_F_POINTER(cptr, data, (/csize1, csize2, csize3, csize4, csize5, csize6/))
!!$       dim1 = csize1
!!$       dim2 = csize2
!!$       dim3 = csize3
!!$       dim4 = csize4
!!$       dim5 = csize5
!!$       dim6 = csize6
!!$    end if
!!$  end subroutine get_vect6d_complex_from_object

end module ual_low_level_wrap
