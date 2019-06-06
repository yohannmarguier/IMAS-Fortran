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



     !!!!! wrappers to old API !!!!!

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
    status = c_ual_create_env(trim(name)//C_NULL_CHAR, shot, run, refShot, refRun, pulseCtx, trim(user)//C_NULL_CHAR, trim(tokamak)//C_NULL_CHAR, trim(version)//C_NULL_CHAR)
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
    status = c_ual_open_env(trim(name)//C_NULL_CHAR, shot, run, pulseCtx, trim(user)//C_NULL_CHAR, trim(tokamak)//C_NULL_CHAR, trim(version)//C_NULL_CHAR)
    if (present(retstatus)) retstatus = status
  end subroutine imas_open_env

  subroutine imas_close(pulseCtx, retstatus)
    use, intrinsic :: ISO_C_BINDING
    implicit none
    integer, intent(in) :: pulseCtx
    integer, optional, intent(out) :: retstatus
    integer :: status
    status = c_ual_close(pulseCtx)
    if (present(retstatus)) retstatus = status
  end subroutine imas_close
  
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
    cptr = C_NULL_PTR
    status = c_getVect1DChar(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, csize)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect1DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, csize1)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect1DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, csize1)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect1DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, csize1)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect2DChar(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2/))
       end if
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
    type(C_PTR) :: cptr
    integer(C_INT) :: csize1, csize2
    cptr = C_NULL_PTR
    status = c_getVect2DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect2DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect2DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect3DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect3DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect3DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect4DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect4DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect4DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect5DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect5DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect5DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect6DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5, csize6)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5,csize6/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect6DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5, csize6)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5,csize6/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect6DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5, csize6)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5,csize6/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect7DInt(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5, csize6, csize7)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5,csize6,csize7/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect7DDouble(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5, csize6, csize7)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then 
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5,csize6,csize7/))
       end if
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
    cptr = C_NULL_PTR
    status = c_getVect7DComplex(opCtx, trim(fieldPath)//C_NULL_CHAR, &
         trim(timebasePath)//C_NULL_CHAR, cptr, &
         csize1, csize2, csize3, csize4, csize5, csize6, csize7)
    if (status.eq.0) then
       if (C_ASSOCIATED(cptr)) then 
          call C_F_POINTER(cptr, data, (/csize1,csize2,csize3,csize4,csize5,csize6,csize7/))
       end if
       dim1 = csize1
       dim2 = csize2
       dim3 = csize3
       dim4 = csize4
       dim5 = csize5
       dim6 = csize6
       dim7 = csize7
    end if
  end subroutine get_vect7d_complex

end module ual_low_level_wrap
