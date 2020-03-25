MODULE test_defs
    USE ids_routines
    IMPLICIT NONE

    LOGICAL, PARAMETER :: debugMode = .FALSE.
    INTEGER :: dim1, dim2, dim3, dim4, dim5, dim6

    INTEGER, PARAMETER :: TEST_SHOT = 9998
    INTEGER, PARAMETER :: TEST_RUN = 9998
    
    ! All backends (/ASCII_BACKEND, MDSPLUS_BACKEND, HDF5_BACKEND,  MEMORY_BACKEND, UDA_BACKEND/)
    INTEGER, dimension(3), PARAMETER   :: ARRAY_ALL_BACKENDS = (/MDSPLUS_BACKEND,  MEMORY_BACKEND, ASCII_BACKEND/)
    INTEGER, dimension(3), PARAMETER   :: ARRAY_ALL_TIME_MODES = (/IDS_TIME_MODE_HOMOGENEOUS, IDS_TIME_MODE_HETEROGENEOUS, IDS_TIME_MODE_INDEPENDENT/)
    
    !INTEGER, DIMENSION(:),allocatable :: SEED
    
    CHARACTER (LEN=*), PARAMETER ::PRINTABLE = '0123456789abcdef'
    !CHARACTER(LEN=*), PARAMETER :: PRINTABLE = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\\"#$%&amp;\'()*+,-./:;&lt;=&gt;?@[\\]^_`{|}~\t\n\r"
    
    TYPE settings_type
        INTEGER, dimension(3) :: backendIDArray = ARRAY_ALL_BACKENDS
        INTEGER, dimension(3) :: idsTimeModeArray = ARRAY_ALL_TIME_MODES
        INTEGER               :: slicesToTest = 3
        INTEGER               :: dataSize = 3
        INTEGER               :: occToTest = 2
        LOGICAL :: useExistingPulseFile = .FALSE.
    END TYPE settings_type


END MODULE test_defs