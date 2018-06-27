#!/bin/bash

TESTDIR="bin"
compiler=""
ids=""
globalResult=0

#========================================================================#
#                          PARSING ARGUMENTS
#========================================================================#

# read the options
TEMP=`getopt --options c:i: --long compiler:,ids: -- "$@"`
#exit on error
if (( "$?" > 0 ))  
then
	exit $?
fi

eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -c|--compiler)
		compiler="$2" ; shift 2 ;;
        -i|--ids)
            ids=$2 ; shift 2;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

#========================================================================#
#                          ENVIRONMENT
#========================================================================#
if [ "${IMAS_INSTALL_DIR}" = "" ] 
then
	echo Please supply a variable IMAS_INSTALL_DIR that is the prefix of your IMAS installation.
	exit 1
fi

export LD_LIBRARY_PATH=${IMAS_INSTALL_DIR}/lib:${LD_LIBRARY_PATH}
export ids_path="${PWD}/tmp;${IMAS_INSTALL_DIR}/models/mdsplus"

mkdir -p tmp
rm -rf ${PWD}/tmp/*



#========================================================================#
#                          RUNNING TESTS
#========================================================================#
for dir in ${TESTDIR}/*/
do
    
	dirName="$(basename $dir)"

	if [ "${compiler}" = "" ] || [ "${compiler}" = "${dirName}" ]
	then
     		echo =========  ${dirName}  ================

		for idsTestPath in ${dir}*_get_test.exe
		do
    
     			idsTest="$(basename ${idsTestPath} _get_test.exe)"
			if [ "${ids}" = "" ] || [ "${ids}" = "${idsTest}" ]
			then
				echo Testing: ${idsTest}

				${idsTestPath} 
				result=$?

				if (( "${result}" > 0 ))  
				then
   					echo  ERROR: ${idsTestPath}
   					globalResult="${result}"
				fi
			fi
		done
	fi
done

exit  ${globalResult}
