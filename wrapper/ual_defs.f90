module ual_defs
  
  integer, parameter :: MAXDIM             = 7

  integer, parameter :: OP_INTERP_0        = 0
  integer, parameter :: BACKEND_ID_0       = 10
  integer, parameter :: OP_RANGE_0         = 20
  integer, parameter :: OP_ACCESS_0        = 30
  integer, parameter :: ACCESS_PULSE_0     = 40
  integer, parameter :: DATA_TYPE_0        = 50
  integer, parameter :: ERR_0              = -1
  
  integer, parameter :: NO_BACKEND         = BACKEND_ID_0
  integer, parameter :: ASCII_BACKEND      = BACKEND_ID_0+1
  integer, parameter :: MDSPLUS_BACKEND    = BACKEND_ID_0+2
  integer, parameter :: HDF5_BACKEND       = BACKEND_ID_0+3
  integer, parameter :: MEMORY_BACKEND     = BACKEND_ID_0+4
  integer, parameter :: UDA_BACKEND        = BACKEND_ID_0+5

  integer, parameter :: TIMED              = 1
  integer, parameter :: NON_TIMED          = 0
  
  integer, parameter :: GLOBAL_OP          = OP_RANGE_0
  integer, parameter :: SLICE_OP           = OP_RANGE_0+1
  
  integer, parameter :: READ_OP            = OP_ACCESS_0
  integer, parameter :: WRITE_OP           = OP_ACCESS_0+1
  integer, parameter :: REPLACE_OP         = OP_ACCESS_0+2
  
  integer, parameter :: UNDEFINED_INTERP   = OP_INTERP_0
  integer, parameter :: CLOSEST_INTERP     = OP_INTERP_0+1
  integer, parameter :: PREVIOUS_INTERP    = OP_INTERP_0+2
  integer, parameter :: LINEAR_INTERP      = OP_INTERP_0+3
  
  real(8), parameter :: UNDEFINED_TIME     = -999.
  
  integer, parameter :: OPEN_PULSE         = ACCESS_PULSE_0
  integer, parameter :: FORCE_OPEN_PULSE   = ACCESS_PULSE_0+1
  integer, parameter :: CREATE_PULSE       = ACCESS_PULSE_0+2
  integer, parameter :: FORCE_CREATE_PULSE = ACCESS_PULSE_0+3
  integer, parameter :: CLOSE_PULSE        = ACCESS_PULSE_0+4
  integer, parameter :: ERASE_PULSE        = ACCESS_PULSE_0+5
  
  integer, parameter :: CHAR_DATA          = DATA_TYPE_0
  integer, parameter :: INTEGER_DATA       = DATA_TYPE_0+1
  integer, parameter :: DOUBLE_DATA        = DATA_TYPE_0+2
  integer, parameter :: COMPLEX_DATA       = DATA_TYPE_0+3
  
  integer, parameter :: UNKNOWN_ERR        = ERR_0
  integer, parameter :: CONTEXT_ERR        = ERR_0-1
  integer, parameter :: BACKEND_ERR        = ERR_0-2
  integer, parameter :: LOWLEVEL_ERR       = ERR_0-3

  integer, parameter :: IDS_TIME_MODE_UNKNOWN = -999999999
  integer, parameter :: IDS_TIME_MODE_HETEROGENEOUS = 0
  integer, parameter :: IDS_TIME_MODE_HOMOGENEOUS = 1
  integer, parameter :: IDS_TIME_MODE_INDEPENDENT = 2

end module ual_defs



