PROGRAM test
	use comparator 
	use ids_schemas 
	use helper
	implicit none
	INTEGER :: idx;

	call init(idx);

	! --- IDS: actuator ---
	call actuator_put()
	call actuator_get()

	! --- IDS: atomic_data ---
	call atomic_data_put()
	call atomic_data_get()

	! --- IDS: controllers ---
	call controllers_put()
	call controllers_get()

	! --- IDS: core_profiles ---
	call core_profiles_put()
	call core_profiles_get()

	! --- IDS: core_sources ---
	call core_sources_put()
	call core_sources_get()

	! --- IDS: core_transport ---
	call core_transport_put()
	call core_transport_get()

	! --- IDS: em_coupling ---
	call em_coupling_put()
	call em_coupling_get()

	! --- IDS: equilibrium ---
	call equilibrium_put()
	call equilibrium_get()

	! --- IDS: magnetics ---
	call magnetics_put()
	call magnetics_get()

	! --- IDS: pf_active ---
	call pf_active_put()
	call pf_active_get()

	! --- IDS: pf_passive ---
	call pf_passive_put()
	call pf_passive_get()

	! --- IDS: schedule ---
	call schedule_put()
	call schedule_get()

	! --- IDS: sdn ---
	call sdn_put()
	call sdn_get()

	! --- IDS: simulation ---
	call simulation_put()
	call simulation_get()

	! --- IDS: temporary ---
	call temporary_put()
	call temporary_get()

	! --- IDS: tf ---
	call tf_put()
	call tf_get()
	call finish();
CONTAINS
!==================================================================
!		 PUT actuator 
!==================================================================
SUBROUTINE actuator_put
	CHARACTER (LEN = *), parameter :: idsName = "actuator"
	TYPE (ids_actuator) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on actuator"
	CALL srand(seed)
	do i = 0, 6 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!name : name : STR_0D
		allocate(ids%name(1)) 
			ids%name = getString()

		!!!channels : channels : STR_1D
		allocate(ids%channels(1)) 
			ids%channels = getString()

		!!!power : power : FLT_2D
		allocate(ids%power(DIM_SIZE, DIM_SIZE)) 
			ids%power = getDouble2DArray()

		!!!generic_dynamic : generic_dynamic : FLT_2D
		allocate(ids%generic_dynamic(DIM_SIZE, DIM_SIZE)) 
			ids%generic_dynamic = getDouble2DArray()

		!!!name : code/name : STR_0D
		allocate(ids%code%name(1)) 
			ids%code%name = getString()

		!!!version : code/version : STR_0D
		allocate(ids%code%version(1)) 
			ids%code%version = getString()

		!!!parameters : code/parameters : STR_0D
		allocate(ids%code%parameters(1)) 
			ids%code%parameters = getString()

		!!!output_flag : code/output_flag : INT_1D
		allocate(ids%code%output_flag(DIM_SIZE)) 
			ids%code%output_flag = getInteger1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE actuator_put 

!==================================================================
!		 PUT atomic_data 
!==================================================================
SUBROUTINE atomic_data_put
	CHARACTER (LEN = *), parameter :: idsName = "atomic_data"
	TYPE (ids_atomic_data) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on atomic_data"
	CALL srand(seed)
	do i = 0, 2 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!z_n : z_n : FLT_0D
			ids%z_n = getDouble()

		!!!a : a : FLT_0D
			ids%a = getDouble()

		!!!process : process : struct_array
			allocate(ids%process (1))
 		allocate(ids%process(1)%label(1)) 
			ids%process(1)%label = getString()
			tmpInt = getInteger()
			ids%process(1)%table_dimension= tmpInt
			write(*,*) "ids%process(1)%table_dimension", tmpInt
			tmpInt = getInteger()
			ids%process(1)%coordinate_index= tmpInt
			write(*,*) "ids%process(1)%coordinate_index", tmpInt
		allocate(ids%process(1)%result_label(1)) 
			ids%process(1)%result_label = getString()
		allocate(ids%process(1)%result_units(1)) 
			ids%process(1)%result_units = getString()
			tmpInt = getInteger()
			ids%process(1)%result_transformation= tmpInt
			write(*,*) "ids%process(1)%result_transformation", tmpInt
			allocate(ids%process(1)%charge_state (1))
 		allocate(ids%process(1)%charge_state(1)%label(1)) 
			ids%process(1)%charge_state(1)%label = getString()
			ids%process(1)%charge_state(1)%z_min = getDouble()
			ids%process(1)%charge_state(1)%z_max = getDouble()
			ids%process(1)%charge_state(1)%table_0d = getDouble()
		allocate(ids%process(1)%charge_state(1)%table_1d(DIM_SIZE)) 
		ids%process(1)%charge_state(1)%table_1d = getDouble1DArray()
		allocate(ids%process(1)%charge_state(1)%table_2d(DIM_SIZE, DIM_SIZE)) 
			ids%process(1)%charge_state(1)%table_2d = getDouble2DArray()
		allocate(ids%process(1)%charge_state(1)%table_3d(DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%process(1)%charge_state(1)%table_3d = getDouble3DArray()
		allocate(ids%process(1)%charge_state(1)%table_4d(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%process(1)%charge_state(1)%table_4d = getDouble4DArray()
		allocate(ids%process(1)%charge_state(1)%table_5d(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%process(1)%charge_state(1)%table_5d = getDouble5DArray()
		allocate(ids%process(1)%charge_state(1)%table_6d(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%process(1)%charge_state(1)%table_6d = getDouble6DArray()

		!!!coordinate_system : coordinate_system : struct_array
			allocate(ids%coordinate_system (1))
 			allocate(ids%coordinate_system(1)%coordinate (1))
 		allocate(ids%coordinate_system(1)%coordinate(1)%label(1)) 
			ids%coordinate_system(1)%coordinate(1)%label = getString()
		allocate(ids%coordinate_system(1)%coordinate(1)%values(DIM_SIZE)) 
		ids%coordinate_system(1)%coordinate(1)%values = getDouble1DArray()
			tmpInt = getInteger()
			ids%coordinate_system(1)%coordinate(1)%interpolation_type= tmpInt
			write(*,*) "ids%coordinate_system(1)%coordinate(1)%interpolation_type", tmpInt
		allocate(ids%coordinate_system(1)%coordinate(1)%extrapolation_type(DIM_SIZE)) 
			ids%coordinate_system(1)%coordinate(1)%extrapolation_type = getInteger1DArray()
		allocate(ids%coordinate_system(1)%coordinate(1)%value_labels(1)) 
			ids%coordinate_system(1)%coordinate(1)%value_labels = getString()
		allocate(ids%coordinate_system(1)%coordinate(1)%units(1)) 
			ids%coordinate_system(1)%coordinate(1)%units = getString()
			tmpInt = getInteger()
			ids%coordinate_system(1)%coordinate(1)%transformation= tmpInt
			write(*,*) "ids%coordinate_system(1)%coordinate(1)%transformation", tmpInt
			tmpInt = getInteger()
			ids%coordinate_system(1)%coordinate(1)%spacing= tmpInt
			write(*,*) "ids%coordinate_system(1)%coordinate(1)%spacing", tmpInt

		!!!name : code/name : STR_0D
		allocate(ids%code%name(1)) 
			ids%code%name = getString()

		!!!version : code/version : STR_0D
		allocate(ids%code%version(1)) 
			ids%code%version = getString()

		!!!parameters : code/parameters : STR_0D
		allocate(ids%code%parameters(1)) 
			ids%code%parameters = getString()

		!!!output_flag : code/output_flag : INT_1D
		allocate(ids%code%output_flag(DIM_SIZE)) 
			ids%code%output_flag = getInteger1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE atomic_data_put 

!==================================================================
!		 PUT controllers 
!==================================================================
SUBROUTINE controllers_put
	CHARACTER (LEN = *), parameter :: idsName = "controllers"
	TYPE (ids_controllers) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on controllers"
	CALL srand(seed)
	do i = 0, 2 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!linear_controller : linear_controller : struct_array
			allocate(ids%linear_controller (1))
 		allocate(ids%linear_controller(1)%name(1)) 
			ids%linear_controller(1)%name = getString()
		allocate(ids%linear_controller(1)%description(1)) 
			ids%linear_controller(1)%description = getString()
		allocate(ids%linear_controller(1)%controller_class(1)) 
			ids%linear_controller(1)%controller_class = getString()
		allocate(ids%linear_controller(1)%input_names(1)) 
			ids%linear_controller(1)%input_names = getString()
		allocate(ids%linear_controller(1)%output_names(1)) 
			ids%linear_controller(1)%output_names = getString()
		allocate(ids%linear_controller(1)%statespace%state_names(1)) 
			ids%linear_controller(1)%statespace%state_names = getString()
		allocate(ids%linear_controller(1)%statespace%a%data(DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%linear_controller(1)%statespace%a%data = getDouble3DArray()
		allocate(ids%linear_controller(1)%statespace%a%time(DIM_SIZE)) 
		ids%linear_controller(1)%statespace%a%time = getDouble1DArray()
		allocate(ids%linear_controller(1)%statespace%b%data(DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%linear_controller(1)%statespace%b%data = getDouble3DArray()
		allocate(ids%linear_controller(1)%statespace%b%time(DIM_SIZE)) 
		ids%linear_controller(1)%statespace%b%time = getDouble1DArray()
		allocate(ids%linear_controller(1)%statespace%c%data(DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%linear_controller(1)%statespace%c%data = getDouble3DArray()
		allocate(ids%linear_controller(1)%statespace%c%time(DIM_SIZE)) 
		ids%linear_controller(1)%statespace%c%time = getDouble1DArray()
		allocate(ids%linear_controller(1)%statespace%d%data(DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%linear_controller(1)%statespace%d%data = getDouble3DArray()
		allocate(ids%linear_controller(1)%statespace%d%time(DIM_SIZE)) 
		ids%linear_controller(1)%statespace%d%time = getDouble1DArray()
		allocate(ids%linear_controller(1)%statespace%deltat%data(DIM_SIZE)) 
		ids%linear_controller(1)%statespace%deltat%data = getDouble1DArray()
		allocate(ids%linear_controller(1)%statespace%deltat%time(DIM_SIZE)) 
		ids%linear_controller(1)%statespace%deltat%time = getDouble1DArray()
		allocate(ids%linear_controller(1)%pid%p%data(DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%linear_controller(1)%pid%p%data = getDouble3DArray()
		allocate(ids%linear_controller(1)%pid%p%time(DIM_SIZE)) 
		ids%linear_controller(1)%pid%p%time = getDouble1DArray()
		allocate(ids%linear_controller(1)%pid%i%data(DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%linear_controller(1)%pid%i%data = getDouble3DArray()
		allocate(ids%linear_controller(1)%pid%i%time(DIM_SIZE)) 
		ids%linear_controller(1)%pid%i%time = getDouble1DArray()
		allocate(ids%linear_controller(1)%pid%d%data(DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%linear_controller(1)%pid%d%data = getDouble3DArray()
		allocate(ids%linear_controller(1)%pid%d%time(DIM_SIZE)) 
		ids%linear_controller(1)%pid%d%time = getDouble1DArray()
		allocate(ids%linear_controller(1)%pid%tau%data(DIM_SIZE)) 
		ids%linear_controller(1)%pid%tau%data = getDouble1DArray()
		allocate(ids%linear_controller(1)%pid%tau%time(DIM_SIZE)) 
		ids%linear_controller(1)%pid%tau%time = getDouble1DArray()
		allocate(ids%linear_controller(1)%inputs%data(DIM_SIZE, DIM_SIZE)) 
			ids%linear_controller(1)%inputs%data = getDouble2DArray()
		allocate(ids%linear_controller(1)%inputs%time(DIM_SIZE)) 
		ids%linear_controller(1)%inputs%time = getDouble1DArray()
		allocate(ids%linear_controller(1)%outputs%data(DIM_SIZE, DIM_SIZE)) 
			ids%linear_controller(1)%outputs%data = getDouble2DArray()
		allocate(ids%linear_controller(1)%outputs%time(DIM_SIZE)) 
		ids%linear_controller(1)%outputs%time = getDouble1DArray()

		!!!nonlinear_controller : nonlinear_controller : struct_array
			allocate(ids%nonlinear_controller (1))
 		allocate(ids%nonlinear_controller(1)%name(1)) 
			ids%nonlinear_controller(1)%name = getString()
		allocate(ids%nonlinear_controller(1)%description(1)) 
			ids%nonlinear_controller(1)%description = getString()
		allocate(ids%nonlinear_controller(1)%controller_class(1)) 
			ids%nonlinear_controller(1)%controller_class = getString()
		allocate(ids%nonlinear_controller(1)%input_names(1)) 
			ids%nonlinear_controller(1)%input_names = getString()
		allocate(ids%nonlinear_controller(1)%output_names(1)) 
			ids%nonlinear_controller(1)%output_names = getString()
		allocate(ids%nonlinear_controller(1)%function(1)) 
			ids%nonlinear_controller(1)%function = getString()
		allocate(ids%nonlinear_controller(1)%inputs%data(DIM_SIZE, DIM_SIZE)) 
			ids%nonlinear_controller(1)%inputs%data = getDouble2DArray()
		allocate(ids%nonlinear_controller(1)%inputs%time(DIM_SIZE)) 
		ids%nonlinear_controller(1)%inputs%time = getDouble1DArray()
		allocate(ids%nonlinear_controller(1)%outputs%data(DIM_SIZE, DIM_SIZE)) 
			ids%nonlinear_controller(1)%outputs%data = getDouble2DArray()
		allocate(ids%nonlinear_controller(1)%outputs%time(DIM_SIZE)) 
		ids%nonlinear_controller(1)%outputs%time = getDouble1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()

		!!!name : code/name : STR_0D
		allocate(ids%code%name(1)) 
			ids%code%name = getString()

		!!!version : code/version : STR_0D
		allocate(ids%code%version(1)) 
			ids%code%version = getString()

		!!!parameters : code/parameters : STR_0D
		allocate(ids%code%parameters(1)) 
			ids%code%parameters = getString()

		!!!output_flag : code/output_flag : INT_1D
		allocate(ids%code%output_flag(DIM_SIZE)) 
			ids%code%output_flag = getInteger1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE controllers_put 

!==================================================================
!		 PUT core_profiles 
!==================================================================
SUBROUTINE core_profiles_put
	CHARACTER (LEN = *), parameter :: idsName = "core_profiles"
	TYPE (ids_core_profiles) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on core_profiles"
	CALL srand(seed)
	do i = 0, 6 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!profiles_1d : profiles_1d : struct_array
			allocate(ids%profiles_1d (1))
 		allocate(ids%profiles_1d(1)%t_e(DIM_SIZE)) 
		ids%profiles_1d(1)%t_e = getDouble1DArray()
		allocate(ids%profiles_1d(1)%t_i_average(DIM_SIZE)) 
		ids%profiles_1d(1)%t_i_average = getDouble1DArray()
		allocate(ids%profiles_1d(1)%n_e(DIM_SIZE)) 
		ids%profiles_1d(1)%n_e = getDouble1DArray()
		allocate(ids%profiles_1d(1)%n_e_fast(DIM_SIZE)) 
		ids%profiles_1d(1)%n_e_fast = getDouble1DArray()
		allocate(ids%profiles_1d(1)%n_i_total_over_n_e(DIM_SIZE)) 
		ids%profiles_1d(1)%n_i_total_over_n_e = getDouble1DArray()
		allocate(ids%profiles_1d(1)%momentum_tor(DIM_SIZE)) 
		ids%profiles_1d(1)%momentum_tor = getDouble1DArray()
		allocate(ids%profiles_1d(1)%zeff(DIM_SIZE)) 
		ids%profiles_1d(1)%zeff = getDouble1DArray()
		allocate(ids%profiles_1d(1)%p_e(DIM_SIZE)) 
		ids%profiles_1d(1)%p_e = getDouble1DArray()
		allocate(ids%profiles_1d(1)%p_e_fast_perpendicular(DIM_SIZE)) 
		ids%profiles_1d(1)%p_e_fast_perpendicular = getDouble1DArray()
		allocate(ids%profiles_1d(1)%p_e_fast_parallel(DIM_SIZE)) 
		ids%profiles_1d(1)%p_e_fast_parallel = getDouble1DArray()
		allocate(ids%profiles_1d(1)%p_i_total(DIM_SIZE)) 
		ids%profiles_1d(1)%p_i_total = getDouble1DArray()
		allocate(ids%profiles_1d(1)%p_i_total_fast_perpendicular(DIM_SIZE)) 
		ids%profiles_1d(1)%p_i_total_fast_perpendicular = getDouble1DArray()
		allocate(ids%profiles_1d(1)%p_i_total_fast_parallel(DIM_SIZE)) 
		ids%profiles_1d(1)%p_i_total_fast_parallel = getDouble1DArray()
		allocate(ids%profiles_1d(1)%pressure_thermal(DIM_SIZE)) 
		ids%profiles_1d(1)%pressure_thermal = getDouble1DArray()
		allocate(ids%profiles_1d(1)%pressure_perpendicular(DIM_SIZE)) 
		ids%profiles_1d(1)%pressure_perpendicular = getDouble1DArray()
		allocate(ids%profiles_1d(1)%pressure_parallel(DIM_SIZE)) 
		ids%profiles_1d(1)%pressure_parallel = getDouble1DArray()
		allocate(ids%profiles_1d(1)%j_total(DIM_SIZE)) 
		ids%profiles_1d(1)%j_total = getDouble1DArray()
		allocate(ids%profiles_1d(1)%j_tor(DIM_SIZE)) 
		ids%profiles_1d(1)%j_tor = getDouble1DArray()
		allocate(ids%profiles_1d(1)%j_ohmic(DIM_SIZE)) 
		ids%profiles_1d(1)%j_ohmic = getDouble1DArray()
		allocate(ids%profiles_1d(1)%j_non_inductive(DIM_SIZE)) 
		ids%profiles_1d(1)%j_non_inductive = getDouble1DArray()
		allocate(ids%profiles_1d(1)%j_bootstrap(DIM_SIZE)) 
		ids%profiles_1d(1)%j_bootstrap = getDouble1DArray()
		allocate(ids%profiles_1d(1)%conductivity_parallel(DIM_SIZE)) 
		ids%profiles_1d(1)%conductivity_parallel = getDouble1DArray()
		allocate(ids%profiles_1d(1)%e_field_parallel(DIM_SIZE)) 
		ids%profiles_1d(1)%e_field_parallel = getDouble1DArray()
		allocate(ids%profiles_1d(1)%q(DIM_SIZE)) 
		ids%profiles_1d(1)%q = getDouble1DArray()
		allocate(ids%profiles_1d(1)%magnetic_shear(DIM_SIZE)) 
		ids%profiles_1d(1)%magnetic_shear = getDouble1DArray()
			ids%profiles_1d(1)%time = getDouble()
		allocate(ids%profiles_1d(1)%grid%rho_tor_norm(DIM_SIZE)) 
		ids%profiles_1d(1)%grid%rho_tor_norm = getDouble1DArray()
		allocate(ids%profiles_1d(1)%grid%rho_tor(DIM_SIZE)) 
		ids%profiles_1d(1)%grid%rho_tor = getDouble1DArray()
		allocate(ids%profiles_1d(1)%grid%psi(DIM_SIZE)) 
		ids%profiles_1d(1)%grid%psi = getDouble1DArray()
		allocate(ids%profiles_1d(1)%grid%volume(DIM_SIZE)) 
		ids%profiles_1d(1)%grid%volume = getDouble1DArray()
		allocate(ids%profiles_1d(1)%grid%area(DIM_SIZE)) 
		ids%profiles_1d(1)%grid%area = getDouble1DArray()
			allocate(ids%profiles_1d(1)%ion (1))
 			ids%profiles_1d(1)%ion(1)%a = getDouble()
			ids%profiles_1d(1)%ion(1)%z_ion = getDouble()
			ids%profiles_1d(1)%ion(1)%z_n = getDouble()
		allocate(ids%profiles_1d(1)%ion(1)%label(1)) 
			ids%profiles_1d(1)%ion(1)%label = getString()
		allocate(ids%profiles_1d(1)%ion(1)%n_i(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%n_i = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%n_i_fast(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%n_i_fast = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%t_i(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%t_i = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%p_i(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%p_i = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%p_i_fast_perpendicular(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%p_i_fast_perpendicular = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%p_i_fast_parallel(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%p_i_fast_parallel = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%v_tor_i(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%v_tor_i = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%v_pol_i(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%v_pol_i = getDouble1DArray()
			tmpInt = getInteger()
			ids%profiles_1d(1)%ion(1)%multiple_charge_states_flag= tmpInt
			write(*,*) "ids%profiles_1d(1)%ion(1)%multiple_charge_states_flag", tmpInt
			allocate(ids%profiles_1d(1)%ion(1)%charge_state (1))
 			ids%profiles_1d(1)%ion(1)%charge_state(1)%z_min = getDouble()
			ids%profiles_1d(1)%ion(1)%charge_state(1)%z_max = getDouble()
		allocate(ids%profiles_1d(1)%ion(1)%charge_state(1)%label(1)) 
			ids%profiles_1d(1)%ion(1)%charge_state(1)%label = getString()
		allocate(ids%profiles_1d(1)%ion(1)%charge_state(1)%n_z(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%charge_state(1)%n_z = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%charge_state(1)%n_z_fast(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%charge_state(1)%n_z_fast = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%charge_state(1)%t_z(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%charge_state(1)%t_z = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%charge_state(1)%p_z(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%charge_state(1)%p_z = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%charge_state(1)%p_z_fast_perpendicular(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%charge_state(1)%p_z_fast_perpendicular = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%charge_state(1)%p_z_fast_parallel(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%charge_state(1)%p_z_fast_parallel = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%charge_state(1)%v_tor_z(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%charge_state(1)%v_tor_z = getDouble1DArray()
		allocate(ids%profiles_1d(1)%ion(1)%charge_state(1)%v_pol_z(DIM_SIZE)) 
		ids%profiles_1d(1)%ion(1)%charge_state(1)%v_pol_z = getDouble1DArray()

		!!!ip : global_quantities/ip : FLT_1D
		allocate(ids%global_quantities%ip(DIM_SIZE)) 
		ids%global_quantities%ip = getDouble1DArray()

		!!!current_non_inductive : global_quantities/current_non_inductive : FLT_1D
		allocate(ids%global_quantities%current_non_inductive(DIM_SIZE)) 
		ids%global_quantities%current_non_inductive = getDouble1DArray()

		!!!current_bootstrap : global_quantities/current_bootstrap : FLT_1D
		allocate(ids%global_quantities%current_bootstrap(DIM_SIZE)) 
		ids%global_quantities%current_bootstrap = getDouble1DArray()

		!!!v_loop : global_quantities/v_loop : FLT_1D
		allocate(ids%global_quantities%v_loop(DIM_SIZE)) 
		ids%global_quantities%v_loop = getDouble1DArray()

		!!!li : global_quantities/li : FLT_1D
		allocate(ids%global_quantities%li(DIM_SIZE)) 
		ids%global_quantities%li = getDouble1DArray()

		!!!beta_tor : global_quantities/beta_tor : FLT_1D
		allocate(ids%global_quantities%beta_tor(DIM_SIZE)) 
		ids%global_quantities%beta_tor = getDouble1DArray()

		!!!beta_tor_norm : global_quantities/beta_tor_norm : FLT_1D
		allocate(ids%global_quantities%beta_tor_norm(DIM_SIZE)) 
		ids%global_quantities%beta_tor_norm = getDouble1DArray()

		!!!beta_pol : global_quantities/beta_pol : FLT_1D
		allocate(ids%global_quantities%beta_pol(DIM_SIZE)) 
		ids%global_quantities%beta_pol = getDouble1DArray()

		!!!energy_diamagnetic : global_quantities/energy_diamagnetic : FLT_1D
		allocate(ids%global_quantities%energy_diamagnetic(DIM_SIZE)) 
		ids%global_quantities%energy_diamagnetic = getDouble1DArray()

		!!!r0 : vacuum_toroidal_field/r0 : FLT_0D
			ids%vacuum_toroidal_field%r0 = getDouble()

		!!!b0 : vacuum_toroidal_field/b0 : FLT_1D
		allocate(ids%vacuum_toroidal_field%b0(DIM_SIZE)) 
		ids%vacuum_toroidal_field%b0 = getDouble1DArray()

		!!!name : code/name : STR_0D
		allocate(ids%code%name(1)) 
			ids%code%name = getString()

		!!!version : code/version : STR_0D
		allocate(ids%code%version(1)) 
			ids%code%version = getString()

		!!!parameters : code/parameters : STR_0D
		allocate(ids%code%parameters(1)) 
			ids%code%parameters = getString()

		!!!output_flag : code/output_flag : INT_1D
		allocate(ids%code%output_flag(DIM_SIZE)) 
			ids%code%output_flag = getInteger1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE core_profiles_put 

!==================================================================
!		 PUT core_sources 
!==================================================================
SUBROUTINE core_sources_put
	CHARACTER (LEN = *), parameter :: idsName = "core_sources"
	TYPE (ids_core_sources) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on core_sources"
	CALL srand(seed)
	do i = 0, 6 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!r0 : vacuum_toroidal_field/r0 : FLT_0D
			ids%vacuum_toroidal_field%r0 = getDouble()

		!!!b0 : vacuum_toroidal_field/b0 : FLT_1D
		allocate(ids%vacuum_toroidal_field%b0(DIM_SIZE)) 
		ids%vacuum_toroidal_field%b0 = getDouble1DArray()

		!!!source : source : struct_array
			allocate(ids%source (1))
 		allocate(ids%source(1)%name(1)) 
			ids%source(1)%name = getString()
			allocate(ids%source(1)%profiles (1))
 		allocate(ids%source(1)%profiles(1)%n_e_source(DIM_SIZE)) 
		ids%source(1)%profiles(1)%n_e_source = getDouble1DArray()
		allocate(ids%source(1)%profiles(1)%t_e_source(DIM_SIZE)) 
		ids%source(1)%profiles(1)%t_e_source = getDouble1DArray()
		allocate(ids%source(1)%profiles(1)%t_i_average_source(DIM_SIZE)) 
		ids%source(1)%profiles(1)%t_i_average_source = getDouble1DArray()
		allocate(ids%source(1)%profiles(1)%momentum_tor_source(DIM_SIZE)) 
		ids%source(1)%profiles(1)%momentum_tor_source = getDouble1DArray()
		allocate(ids%source(1)%profiles(1)%conductivity_parallel(DIM_SIZE)) 
		ids%source(1)%profiles(1)%conductivity_parallel = getDouble1DArray()
			ids%source(1)%profiles(1)%time = getDouble()
		allocate(ids%source(1)%profiles(1)%grid%rho_tor_norm(DIM_SIZE)) 
		ids%source(1)%profiles(1)%grid%rho_tor_norm = getDouble1DArray()
		allocate(ids%source(1)%profiles(1)%grid%rho_tor(DIM_SIZE)) 
		ids%source(1)%profiles(1)%grid%rho_tor = getDouble1DArray()
		allocate(ids%source(1)%profiles(1)%grid%psi(DIM_SIZE)) 
		ids%source(1)%profiles(1)%grid%psi = getDouble1DArray()
		allocate(ids%source(1)%profiles(1)%grid%volume(DIM_SIZE)) 
		ids%source(1)%profiles(1)%grid%volume = getDouble1DArray()
		allocate(ids%source(1)%profiles(1)%grid%area(DIM_SIZE)) 
		ids%source(1)%profiles(1)%grid%area = getDouble1DArray()
			allocate(ids%source(1)%profiles(1)%ion (1))
 			ids%source(1)%profiles(1)%ion(1)%a = getDouble()
			ids%source(1)%profiles(1)%ion(1)%z_ion = getDouble()
			ids%source(1)%profiles(1)%ion(1)%z_n = getDouble()
		allocate(ids%source(1)%profiles(1)%ion(1)%label(1)) 
			ids%source(1)%profiles(1)%ion(1)%label = getString()
		allocate(ids%source(1)%profiles(1)%ion(1)%n_i_source(DIM_SIZE)) 
		ids%source(1)%profiles(1)%ion(1)%n_i_source = getDouble1DArray()
		allocate(ids%source(1)%profiles(1)%ion(1)%t_i_source(DIM_SIZE)) 
		ids%source(1)%profiles(1)%ion(1)%t_i_source = getDouble1DArray()
			tmpInt = getInteger()
			ids%source(1)%profiles(1)%ion(1)%multiple_charge_states_flag= tmpInt
			write(*,*) "ids%source(1)%profiles(1)%ion(1)%multiple_charge_states_flag", tmpInt
			allocate(ids%source(1)%profiles(1)%ion(1)%charge_state (1))
 			ids%source(1)%profiles(1)%ion(1)%charge_state(1)%z_min = getDouble()
			ids%source(1)%profiles(1)%ion(1)%charge_state(1)%z_max = getDouble()
		allocate(ids%source(1)%profiles(1)%ion(1)%charge_state(1)%label(1)) 
			ids%source(1)%profiles(1)%ion(1)%charge_state(1)%label = getString()
		allocate(ids%source(1)%profiles(1)%ion(1)%charge_state(1)%n_z_source(DIM_SIZE)) 
		ids%source(1)%profiles(1)%ion(1)%charge_state(1)%n_z_source = getDouble1DArray()
		allocate(ids%source(1)%profiles(1)%ion(1)%charge_state(1)%t_z_source(DIM_SIZE)) 
		ids%source(1)%profiles(1)%ion(1)%charge_state(1)%t_z_source = getDouble1DArray()

		!!!name : code/name : STR_0D
		allocate(ids%code%name(1)) 
			ids%code%name = getString()

		!!!version : code/version : STR_0D
		allocate(ids%code%version(1)) 
			ids%code%version = getString()

		!!!parameters : code/parameters : STR_0D
		allocate(ids%code%parameters(1)) 
			ids%code%parameters = getString()

		!!!output_flag : code/output_flag : INT_1D
		allocate(ids%code%output_flag(DIM_SIZE)) 
			ids%code%output_flag = getInteger1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE core_sources_put 

!==================================================================
!		 PUT core_transport 
!==================================================================
SUBROUTINE core_transport_put
	CHARACTER (LEN = *), parameter :: idsName = "core_transport"
	TYPE (ids_core_transport) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on core_transport"
	CALL srand(seed)
	do i = 0, 6 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!r0 : vacuum_toroidal_field/r0 : FLT_0D
			ids%vacuum_toroidal_field%r0 = getDouble()

		!!!b0 : vacuum_toroidal_field/b0 : FLT_1D
		allocate(ids%vacuum_toroidal_field%b0(DIM_SIZE)) 
		ids%vacuum_toroidal_field%b0 = getDouble1DArray()

		!!!model : model : struct_array
			allocate(ids%model (1))
 		allocate(ids%model(1)%name(1)) 
			ids%model(1)%name = getString()
			ids%model(1)%flux_multiplier = getDouble()
			allocate(ids%model(1)%profiles (1))
 		allocate(ids%model(1)%profiles(1)%conductivity_parallel(DIM_SIZE)) 
		ids%model(1)%profiles(1)%conductivity_parallel = getDouble1DArray()
			ids%model(1)%profiles(1)%time = getDouble()
		allocate(ids%model(1)%profiles(1)%grid_d%rho_tor_norm(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_d%rho_tor_norm = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_d%rho_tor(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_d%rho_tor = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_d%psi(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_d%psi = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_d%volume(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_d%volume = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_d%area(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_d%area = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_v%rho_tor_norm(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_v%rho_tor_norm = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_v%rho_tor(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_v%rho_tor = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_v%psi(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_v%psi = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_v%volume(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_v%volume = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_v%area(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_v%area = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_flux%rho_tor_norm(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_flux%rho_tor_norm = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_flux%rho_tor(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_flux%rho_tor = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_flux%psi(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_flux%psi = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_flux%volume(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_flux%volume = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%grid_flux%area(DIM_SIZE)) 
		ids%model(1)%profiles(1)%grid_flux%area = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%n_e_transport%d(DIM_SIZE)) 
		ids%model(1)%profiles(1)%n_e_transport%d = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%n_e_transport%v(DIM_SIZE)) 
		ids%model(1)%profiles(1)%n_e_transport%v = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%n_e_transport%flux(DIM_SIZE)) 
		ids%model(1)%profiles(1)%n_e_transport%flux = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%t_e_transport%d(DIM_SIZE)) 
		ids%model(1)%profiles(1)%t_e_transport%d = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%t_e_transport%v(DIM_SIZE)) 
		ids%model(1)%profiles(1)%t_e_transport%v = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%t_e_transport%flux(DIM_SIZE)) 
		ids%model(1)%profiles(1)%t_e_transport%flux = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%t_i_average_transport%d(DIM_SIZE)) 
		ids%model(1)%profiles(1)%t_i_average_transport%d = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%t_i_average_transport%v(DIM_SIZE)) 
		ids%model(1)%profiles(1)%t_i_average_transport%v = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%t_i_average_transport%flux(DIM_SIZE)) 
		ids%model(1)%profiles(1)%t_i_average_transport%flux = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%momentum_tor_transport%d(DIM_SIZE)) 
		ids%model(1)%profiles(1)%momentum_tor_transport%d = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%momentum_tor_transport%v(DIM_SIZE)) 
		ids%model(1)%profiles(1)%momentum_tor_transport%v = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%momentum_tor_transport%flux(DIM_SIZE)) 
		ids%model(1)%profiles(1)%momentum_tor_transport%flux = getDouble1DArray()
			allocate(ids%model(1)%profiles(1)%ion (1))
 			ids%model(1)%profiles(1)%ion(1)%a = getDouble()
			ids%model(1)%profiles(1)%ion(1)%z_ion = getDouble()
			ids%model(1)%profiles(1)%ion(1)%z_n = getDouble()
		allocate(ids%model(1)%profiles(1)%ion(1)%label(1)) 
			ids%model(1)%profiles(1)%ion(1)%label = getString()
			tmpInt = getInteger()
			ids%model(1)%profiles(1)%ion(1)%multiple_charge_states_flag= tmpInt
			write(*,*) "ids%model(1)%profiles(1)%ion(1)%multiple_charge_states_flag", tmpInt
		allocate(ids%model(1)%profiles(1)%ion(1)%n_i_transport%d(DIM_SIZE)) 
		ids%model(1)%profiles(1)%ion(1)%n_i_transport%d = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%ion(1)%n_i_transport%v(DIM_SIZE)) 
		ids%model(1)%profiles(1)%ion(1)%n_i_transport%v = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%ion(1)%n_i_transport%flux(DIM_SIZE)) 
		ids%model(1)%profiles(1)%ion(1)%n_i_transport%flux = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%ion(1)%t_i_transport%d(DIM_SIZE)) 
		ids%model(1)%profiles(1)%ion(1)%t_i_transport%d = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%ion(1)%t_i_transport%v(DIM_SIZE)) 
		ids%model(1)%profiles(1)%ion(1)%t_i_transport%v = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%ion(1)%t_i_transport%flux(DIM_SIZE)) 
		ids%model(1)%profiles(1)%ion(1)%t_i_transport%flux = getDouble1DArray()
			allocate(ids%model(1)%profiles(1)%ion(1)%charge_state (1))
 			ids%model(1)%profiles(1)%ion(1)%charge_state(1)%z_min = getDouble()
			ids%model(1)%profiles(1)%ion(1)%charge_state(1)%z_max = getDouble()
		allocate(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%label(1)) 
			ids%model(1)%profiles(1)%ion(1)%charge_state(1)%label = getString()
		allocate(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%n_z_transport%d(DIM_SIZE)) 
		ids%model(1)%profiles(1)%ion(1)%charge_state(1)%n_z_transport%d = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%n_z_transport%v(DIM_SIZE)) 
		ids%model(1)%profiles(1)%ion(1)%charge_state(1)%n_z_transport%v = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%n_z_transport%flux(DIM_SIZE)) 
		ids%model(1)%profiles(1)%ion(1)%charge_state(1)%n_z_transport%flux = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%t_z_transport%d(DIM_SIZE)) 
		ids%model(1)%profiles(1)%ion(1)%charge_state(1)%t_z_transport%d = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%t_z_transport%v(DIM_SIZE)) 
		ids%model(1)%profiles(1)%ion(1)%charge_state(1)%t_z_transport%v = getDouble1DArray()
		allocate(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%t_z_transport%flux(DIM_SIZE)) 
		ids%model(1)%profiles(1)%ion(1)%charge_state(1)%t_z_transport%flux = getDouble1DArray()

		!!!name : code/name : STR_0D
		allocate(ids%code%name(1)) 
			ids%code%name = getString()

		!!!version : code/version : STR_0D
		allocate(ids%code%version(1)) 
			ids%code%version = getString()

		!!!parameters : code/parameters : STR_0D
		allocate(ids%code%parameters(1)) 
			ids%code%parameters = getString()

		!!!output_flag : code/output_flag : INT_1D
		allocate(ids%code%output_flag(DIM_SIZE)) 
			ids%code%output_flag = getInteger1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE core_transport_put 

!==================================================================
!		 PUT em_coupling 
!==================================================================
SUBROUTINE em_coupling_put
	CHARACTER (LEN = *), parameter :: idsName = "em_coupling"
	TYPE (ids_em_coupling) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on em_coupling"
	CALL srand(seed)
	do i = 0, 6 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!mutual_active_active : mutual_active_active : FLT_2D
		allocate(ids%mutual_active_active(DIM_SIZE, DIM_SIZE)) 
			ids%mutual_active_active = getDouble2DArray()

		!!!mutual_passive_active : mutual_passive_active : FLT_2D
		allocate(ids%mutual_passive_active(DIM_SIZE, DIM_SIZE)) 
			ids%mutual_passive_active = getDouble2DArray()

		!!!mutual_loops_active : mutual_loops_active : FLT_2D
		allocate(ids%mutual_loops_active(DIM_SIZE, DIM_SIZE)) 
			ids%mutual_loops_active = getDouble2DArray()

		!!!field_probes_active : field_probes_active : FLT_2D
		allocate(ids%field_probes_active(DIM_SIZE, DIM_SIZE)) 
			ids%field_probes_active = getDouble2DArray()

		!!!mutual_passive_passive : mutual_passive_passive : FLT_2D
		allocate(ids%mutual_passive_passive(DIM_SIZE, DIM_SIZE)) 
			ids%mutual_passive_passive = getDouble2DArray()

		!!!mutual_loops_passive : mutual_loops_passive : FLT_2D
		allocate(ids%mutual_loops_passive(DIM_SIZE, DIM_SIZE)) 
			ids%mutual_loops_passive = getDouble2DArray()

		!!!field_probes_passive : field_probes_passive : FLT_2D
		allocate(ids%field_probes_passive(DIM_SIZE, DIM_SIZE)) 
			ids%field_probes_passive = getDouble2DArray()

		!!!mutual_grid_grid : mutual_grid_grid : FLT_2D
		allocate(ids%mutual_grid_grid(DIM_SIZE, DIM_SIZE)) 
			ids%mutual_grid_grid = getDouble2DArray()

		!!!mutual_grid_active : mutual_grid_active : FLT_2D
		allocate(ids%mutual_grid_active(DIM_SIZE, DIM_SIZE)) 
			ids%mutual_grid_active = getDouble2DArray()

		!!!mutual_grid_passive : mutual_grid_passive : FLT_2D
		allocate(ids%mutual_grid_passive(DIM_SIZE, DIM_SIZE)) 
			ids%mutual_grid_passive = getDouble2DArray()

		!!!field_probes_grid : field_probes_grid : FLT_2D
		allocate(ids%field_probes_grid(DIM_SIZE, DIM_SIZE)) 
			ids%field_probes_grid = getDouble2DArray()

		!!!mutual_loops_grid : mutual_loops_grid : FLT_2D
		allocate(ids%mutual_loops_grid(DIM_SIZE, DIM_SIZE)) 
			ids%mutual_loops_grid = getDouble2DArray()

		!!!active_coils : active_coils : STR_1D
		allocate(ids%active_coils(1)) 
			ids%active_coils = getString()

		!!!passive_loops : passive_loops : STR_1D
		allocate(ids%passive_loops(1)) 
			ids%passive_loops = getString()

		!!!poloidal_probes : poloidal_probes : STR_1D
		allocate(ids%poloidal_probes(1)) 
			ids%poloidal_probes = getString()

		!!!flux_loops : flux_loops : STR_1D
		allocate(ids%flux_loops(1)) 
			ids%flux_loops = getString()

		!!!grid_points : grid_points : STR_1D
		allocate(ids%grid_points(1)) 
			ids%grid_points = getString()

		!!!name : code/name : STR_0D
		allocate(ids%code%name(1)) 
			ids%code%name = getString()

		!!!version : code/version : STR_0D
		allocate(ids%code%version(1)) 
			ids%code%version = getString()

		!!!parameters : code/parameters : STR_0D
		allocate(ids%code%parameters(1)) 
			ids%code%parameters = getString()

		!!!output_flag : code/output_flag : INT_1D
		allocate(ids%code%output_flag(DIM_SIZE)) 
			ids%code%output_flag = getInteger1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE em_coupling_put 

!==================================================================
!		 PUT equilibrium 
!==================================================================
SUBROUTINE equilibrium_put
	CHARACTER (LEN = *), parameter :: idsName = "equilibrium"
	TYPE (ids_equilibrium) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on equilibrium"
	CALL srand(seed)
	do i = 0, 6 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!r0 : vacuum_toroidal_field/r0 : FLT_0D
			ids%vacuum_toroidal_field%r0 = getDouble()

		!!!b0 : vacuum_toroidal_field/b0 : FLT_1D
		allocate(ids%vacuum_toroidal_field%b0(DIM_SIZE)) 
		ids%vacuum_toroidal_field%b0 = getDouble1DArray()

		!!!time_slice : time_slice : struct_array
			allocate(ids%time_slice (1))
 			ids%time_slice(1)%time = getDouble()
			tmpInt = getInteger()
			ids%time_slice(1)%boundary%type= tmpInt
			write(*,*) "ids%time_slice(1)%boundary%type", tmpInt
			ids%time_slice(1)%boundary%a_minor = getDouble()
			ids%time_slice(1)%boundary%elongation = getDouble()
			ids%time_slice(1)%boundary%elongation_upper = getDouble()
			ids%time_slice(1)%boundary%elongation_lower = getDouble()
			ids%time_slice(1)%boundary%triangularity = getDouble()
			ids%time_slice(1)%boundary%triangularity_upper = getDouble()
			ids%time_slice(1)%boundary%triangularity_lower = getDouble()
		allocate(ids%time_slice(1)%boundary%lcfs%r(DIM_SIZE)) 
		ids%time_slice(1)%boundary%lcfs%r = getDouble1DArray()
		allocate(ids%time_slice(1)%boundary%lcfs%z(DIM_SIZE)) 
		ids%time_slice(1)%boundary%lcfs%z = getDouble1DArray()
			ids%time_slice(1)%boundary%geometric_axis%r = getDouble()
			ids%time_slice(1)%boundary%geometric_axis%z = getDouble()
			ids%time_slice(1)%boundary%active_limiter_point%r = getDouble()
			ids%time_slice(1)%boundary%active_limiter_point%z = getDouble()
			allocate(ids%time_slice(1)%boundary%x_point (1))
 			ids%time_slice(1)%boundary%x_point(1)%r = getDouble()
			ids%time_slice(1)%boundary%x_point(1)%z = getDouble()
			allocate(ids%time_slice(1)%boundary%strike_point (1))
 			ids%time_slice(1)%boundary%strike_point(1)%r = getDouble()
			ids%time_slice(1)%boundary%strike_point(1)%z = getDouble()
			ids%time_slice(1)%global_quantities%beta_pol = getDouble()
			ids%time_slice(1)%global_quantities%beta_tor = getDouble()
			ids%time_slice(1)%global_quantities%beta_normal = getDouble()
			ids%time_slice(1)%global_quantities%ip = getDouble()
			ids%time_slice(1)%global_quantities%li_3 = getDouble()
			ids%time_slice(1)%global_quantities%volume = getDouble()
			ids%time_slice(1)%global_quantities%area = getDouble()
			ids%time_slice(1)%global_quantities%surface = getDouble()
			ids%time_slice(1)%global_quantities%length_pol = getDouble()
			ids%time_slice(1)%global_quantities%psi_axis = getDouble()
			ids%time_slice(1)%global_quantities%psi_boundary = getDouble()
			ids%time_slice(1)%global_quantities%q_axis = getDouble()
			ids%time_slice(1)%global_quantities%q_95 = getDouble()
			ids%time_slice(1)%global_quantities%w_mhd = getDouble()
			ids%time_slice(1)%global_quantities%magnetic_axis%r = getDouble()
			ids%time_slice(1)%global_quantities%magnetic_axis%z = getDouble()
			ids%time_slice(1)%global_quantities%magnetic_axis%b_tor = getDouble()
			ids%time_slice(1)%global_quantities%q_min%value = getDouble()
			ids%time_slice(1)%global_quantities%q_min%rho_tor_norm = getDouble()
		allocate(ids%time_slice(1)%profiles_1d%psi(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%psi = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%phi(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%phi = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%pressure(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%pressure = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%f(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%f = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%dpressure_dpsi(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%dpressure_dpsi = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%f_df_dpsi(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%f_df_dpsi = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%j_tor(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%j_tor = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%j_parallel(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%j_parallel = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%q(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%q = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%magnetic_shear(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%magnetic_shear = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%r_inboard(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%r_inboard = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%r_outboard(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%r_outboard = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%rho_tor(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%rho_tor = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%rho_tor_norm(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%rho_tor_norm = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%dpsi_drho_tor(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%dpsi_drho_tor = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%elongation(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%elongation = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%triangularity_upper(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%triangularity_upper = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%triangularity_lower(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%triangularity_lower = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%volume(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%volume = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%dvolume_dpsi(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%dvolume_dpsi = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%dvolume_drho_tor(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%dvolume_drho_tor = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%area(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%area = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%darea_dpsi(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%darea_dpsi = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%surface(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%surface = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%trapped_fraction(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%trapped_fraction = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%gm1(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%gm1 = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%gm2(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%gm2 = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%gm3(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%gm3 = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%gm4(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%gm4 = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%gm5(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%gm5 = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%gm6(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%gm6 = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%gm7(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%gm7 = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%gm8(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%gm8 = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%gm9(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%gm9 = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%b_average(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%b_average = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%b_min(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%b_min = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_1d%b_max(DIM_SIZE)) 
		ids%time_slice(1)%profiles_1d%b_max = getDouble1DArray()
		allocate(ids%time_slice(1)%coordinate_system%r(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%coordinate_system%r = getDouble2DArray()
		allocate(ids%time_slice(1)%coordinate_system%z(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%coordinate_system%z = getDouble2DArray()
		allocate(ids%time_slice(1)%coordinate_system%jacobian(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%coordinate_system%jacobian = getDouble2DArray()
		allocate(ids%time_slice(1)%coordinate_system%g_11(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%coordinate_system%g_11 = getDouble2DArray()
		allocate(ids%time_slice(1)%coordinate_system%g_12(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%coordinate_system%g_12 = getDouble2DArray()
		allocate(ids%time_slice(1)%coordinate_system%g_13(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%coordinate_system%g_13 = getDouble2DArray()
		allocate(ids%time_slice(1)%coordinate_system%g_22(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%coordinate_system%g_22 = getDouble2DArray()
		allocate(ids%time_slice(1)%coordinate_system%g_23(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%coordinate_system%g_23 = getDouble2DArray()
		allocate(ids%time_slice(1)%coordinate_system%g_33(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%coordinate_system%g_33 = getDouble2DArray()
		allocate(ids%time_slice(1)%coordinate_system%grid_type%name(1)) 
			ids%time_slice(1)%coordinate_system%grid_type%name = getString()
			tmpInt = getInteger()
			ids%time_slice(1)%coordinate_system%grid_type%index= tmpInt
			write(*,*) "ids%time_slice(1)%coordinate_system%grid_type%index", tmpInt
		allocate(ids%time_slice(1)%coordinate_system%grid_type%description(1)) 
			ids%time_slice(1)%coordinate_system%grid_type%description = getString()
		allocate(ids%time_slice(1)%coordinate_system%grid%dim1(DIM_SIZE)) 
		ids%time_slice(1)%coordinate_system%grid%dim1 = getDouble1DArray()
		allocate(ids%time_slice(1)%coordinate_system%grid%dim2(DIM_SIZE)) 
		ids%time_slice(1)%coordinate_system%grid%dim2 = getDouble1DArray()
			allocate(ids%time_slice(1)%profiles_2d (1))
 		allocate(ids%time_slice(1)%profiles_2d(1)%r(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%profiles_2d(1)%r = getDouble2DArray()
		allocate(ids%time_slice(1)%profiles_2d(1)%z(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%profiles_2d(1)%z = getDouble2DArray()
		allocate(ids%time_slice(1)%profiles_2d(1)%psi(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%profiles_2d(1)%psi = getDouble2DArray()
		allocate(ids%time_slice(1)%profiles_2d(1)%theta(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%profiles_2d(1)%theta = getDouble2DArray()
		allocate(ids%time_slice(1)%profiles_2d(1)%phi(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%profiles_2d(1)%phi = getDouble2DArray()
		allocate(ids%time_slice(1)%profiles_2d(1)%j_tor(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%profiles_2d(1)%j_tor = getDouble2DArray()
		allocate(ids%time_slice(1)%profiles_2d(1)%j_parallel(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%profiles_2d(1)%j_parallel = getDouble2DArray()
		allocate(ids%time_slice(1)%profiles_2d(1)%b_r(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%profiles_2d(1)%b_r = getDouble2DArray()
		allocate(ids%time_slice(1)%profiles_2d(1)%b_z(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%profiles_2d(1)%b_z = getDouble2DArray()
		allocate(ids%time_slice(1)%profiles_2d(1)%b_tor(DIM_SIZE, DIM_SIZE)) 
			ids%time_slice(1)%profiles_2d(1)%b_tor = getDouble2DArray()
		allocate(ids%time_slice(1)%profiles_2d(1)%grid_type%name(1)) 
			ids%time_slice(1)%profiles_2d(1)%grid_type%name = getString()
			tmpInt = getInteger()
			ids%time_slice(1)%profiles_2d(1)%grid_type%index= tmpInt
			write(*,*) "ids%time_slice(1)%profiles_2d(1)%grid_type%index", tmpInt
		allocate(ids%time_slice(1)%profiles_2d(1)%grid_type%description(1)) 
			ids%time_slice(1)%profiles_2d(1)%grid_type%description = getString()
		allocate(ids%time_slice(1)%profiles_2d(1)%grid%dim1(DIM_SIZE)) 
		ids%time_slice(1)%profiles_2d(1)%grid%dim1 = getDouble1DArray()
		allocate(ids%time_slice(1)%profiles_2d(1)%grid%dim2(DIM_SIZE)) 
		ids%time_slice(1)%profiles_2d(1)%grid%dim2 = getDouble1DArray()

		!!!name : code/name : STR_0D
		allocate(ids%code%name(1)) 
			ids%code%name = getString()

		!!!version : code/version : STR_0D
		allocate(ids%code%version(1)) 
			ids%code%version = getString()

		!!!parameters : code/parameters : STR_0D
		allocate(ids%code%parameters(1)) 
			ids%code%parameters = getString()

		!!!output_flag : code/output_flag : INT_1D
		allocate(ids%code%output_flag(DIM_SIZE)) 
			ids%code%output_flag = getInteger1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE equilibrium_put 

!==================================================================
!		 PUT magnetics 
!==================================================================
SUBROUTINE magnetics_put
	CHARACTER (LEN = *), parameter :: idsName = "magnetics"
	TYPE (ids_magnetics) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on magnetics"
	CALL srand(seed)
	do i = 0, 6 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!flux_loop : flux_loop : struct_array
			allocate(ids%flux_loop (1))
 		allocate(ids%flux_loop(1)%name(1)) 
			ids%flux_loop(1)%name = getString()
		allocate(ids%flux_loop(1)%identifier(1)) 
			ids%flux_loop(1)%identifier = getString()
		allocate(ids%flux_loop(1)%flux%data(DIM_SIZE)) 
		ids%flux_loop(1)%flux%data = getDouble1DArray()
		allocate(ids%flux_loop(1)%flux%time(DIM_SIZE)) 
		ids%flux_loop(1)%flux%time = getDouble1DArray()
			allocate(ids%flux_loop(1)%position (1))
 			ids%flux_loop(1)%position(1)%r = getDouble()
			ids%flux_loop(1)%position(1)%z = getDouble()
			ids%flux_loop(1)%position(1)%phi = getDouble()

		!!!bpol_probe : bpol_probe : struct_array
			allocate(ids%bpol_probe (1))
 		allocate(ids%bpol_probe(1)%name(1)) 
			ids%bpol_probe(1)%name = getString()
		allocate(ids%bpol_probe(1)%identifier(1)) 
			ids%bpol_probe(1)%identifier = getString()
			ids%bpol_probe(1)%poloidal_angle = getDouble()
			ids%bpol_probe(1)%toroidal_angle = getDouble()
			ids%bpol_probe(1)%area = getDouble()
			ids%bpol_probe(1)%length = getDouble()
			tmpInt = getInteger()
			ids%bpol_probe(1)%turns= tmpInt
			write(*,*) "ids%bpol_probe(1)%turns", tmpInt
			ids%bpol_probe(1)%position%r = getDouble()
			ids%bpol_probe(1)%position%z = getDouble()
			ids%bpol_probe(1)%position%phi = getDouble()
		allocate(ids%bpol_probe(1)%field%data(DIM_SIZE)) 
		ids%bpol_probe(1)%field%data = getDouble1DArray()
		allocate(ids%bpol_probe(1)%field%time(DIM_SIZE)) 
		ids%bpol_probe(1)%field%time = getDouble1DArray()

		!!!method : method : struct_array
			allocate(ids%method (1))
 		allocate(ids%method(1)%name(1)) 
			ids%method(1)%name = getString()
		allocate(ids%method(1)%ip%data(DIM_SIZE)) 
		ids%method(1)%ip%data = getDouble1DArray()
		allocate(ids%method(1)%ip%time(DIM_SIZE)) 
		ids%method(1)%ip%time = getDouble1DArray()
		allocate(ids%method(1)%diamagnetic_flux%data(DIM_SIZE)) 
		ids%method(1)%diamagnetic_flux%data = getDouble1DArray()
		allocate(ids%method(1)%diamagnetic_flux%time(DIM_SIZE)) 
		ids%method(1)%diamagnetic_flux%time = getDouble1DArray()

		!!!name : code/name : STR_0D
		allocate(ids%code%name(1)) 
			ids%code%name = getString()

		!!!version : code/version : STR_0D
		allocate(ids%code%version(1)) 
			ids%code%version = getString()

		!!!parameters : code/parameters : STR_0D
		allocate(ids%code%parameters(1)) 
			ids%code%parameters = getString()

		!!!output_flag : code/output_flag : INT_1D
		allocate(ids%code%output_flag(DIM_SIZE)) 
			ids%code%output_flag = getInteger1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE magnetics_put 

!==================================================================
!		 PUT pf_active 
!==================================================================
SUBROUTINE pf_active_put
	CHARACTER (LEN = *), parameter :: idsName = "pf_active"
	TYPE (ids_pf_active) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on pf_active"
	CALL srand(seed)
	do i = 0, 6 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!coil : coil : struct_array
			allocate(ids%coil (1))
 		allocate(ids%coil(1)%name(1)) 
			ids%coil(1)%name = getString()
		allocate(ids%coil(1)%identifier(1)) 
			ids%coil(1)%identifier = getString()
			ids%coil(1)%resistance = getDouble()
			ids%coil(1)%energy_limit_max = getDouble()
		allocate(ids%coil(1)%current%data(DIM_SIZE)) 
		ids%coil(1)%current%data = getDouble1DArray()
		allocate(ids%coil(1)%current%time(DIM_SIZE)) 
		ids%coil(1)%current%time = getDouble1DArray()
		allocate(ids%coil(1)%voltage%data(DIM_SIZE)) 
		ids%coil(1)%voltage%data = getDouble1DArray()
		allocate(ids%coil(1)%voltage%time(DIM_SIZE)) 
		ids%coil(1)%voltage%time = getDouble1DArray()
			allocate(ids%coil(1)%element (1))
 		allocate(ids%coil(1)%element(1)%name(1)) 
			ids%coil(1)%element(1)%name = getString()
		allocate(ids%coil(1)%element(1)%identifier(1)) 
			ids%coil(1)%element(1)%identifier = getString()
			tmpInt = getInteger()
			ids%coil(1)%element(1)%turns_with_sign= tmpInt
			write(*,*) "ids%coil(1)%element(1)%turns_with_sign", tmpInt
			ids%coil(1)%element(1)%area = getDouble()
			tmpInt = getInteger()
			ids%coil(1)%element(1)%geometry%geometry_type= tmpInt
			write(*,*) "ids%coil(1)%element(1)%geometry%geometry_type", tmpInt
		allocate(ids%coil(1)%element(1)%geometry%outline%r(DIM_SIZE)) 
		ids%coil(1)%element(1)%geometry%outline%r = getDouble1DArray()
		allocate(ids%coil(1)%element(1)%geometry%outline%z(DIM_SIZE)) 
		ids%coil(1)%element(1)%geometry%outline%z = getDouble1DArray()
			ids%coil(1)%element(1)%geometry%rectangle%r = getDouble()
			ids%coil(1)%element(1)%geometry%rectangle%z = getDouble()
			ids%coil(1)%element(1)%geometry%rectangle%width = getDouble()
			ids%coil(1)%element(1)%geometry%rectangle%height = getDouble()
			ids%coil(1)%element(1)%geometry%oblique%r = getDouble()
			ids%coil(1)%element(1)%geometry%oblique%z = getDouble()
			ids%coil(1)%element(1)%geometry%oblique%length = getDouble()
			ids%coil(1)%element(1)%geometry%oblique%thickness = getDouble()
			ids%coil(1)%element(1)%geometry%oblique%alpha = getDouble()
			ids%coil(1)%element(1)%geometry%oblique%beta = getDouble()

		!!!vertical_force : vertical_force : struct_array
			allocate(ids%vertical_force (1))
 		allocate(ids%vertical_force(1)%name(1)) 
			ids%vertical_force(1)%name = getString()
		allocate(ids%vertical_force(1)%combination(DIM_SIZE)) 
		ids%vertical_force(1)%combination = getDouble1DArray()
			ids%vertical_force(1)%limit_max = getDouble()
			ids%vertical_force(1)%limit_min = getDouble()
		allocate(ids%vertical_force(1)%force%data(DIM_SIZE)) 
		ids%vertical_force(1)%force%data = getDouble1DArray()
		allocate(ids%vertical_force(1)%force%time(DIM_SIZE)) 
		ids%vertical_force(1)%force%time = getDouble1DArray()

		!!!circuit : circuit : struct_array
			allocate(ids%circuit (1))
 		allocate(ids%circuit(1)%name(1)) 
			ids%circuit(1)%name = getString()
		allocate(ids%circuit(1)%identifier(1)) 
			ids%circuit(1)%identifier = getString()
		allocate(ids%circuit(1)%type(1)) 
			ids%circuit(1)%type = getString()
		allocate(ids%circuit(1)%connections(DIM_SIZE, DIM_SIZE)) 
			ids%circuit(1)%connections = getInteger2DArray()
		allocate(ids%circuit(1)%voltage%data(DIM_SIZE)) 
		ids%circuit(1)%voltage%data = getDouble1DArray()
		allocate(ids%circuit(1)%voltage%time(DIM_SIZE)) 
		ids%circuit(1)%voltage%time = getDouble1DArray()
		allocate(ids%circuit(1)%current%data(DIM_SIZE)) 
		ids%circuit(1)%current%data = getDouble1DArray()
		allocate(ids%circuit(1)%current%time(DIM_SIZE)) 
		ids%circuit(1)%current%time = getDouble1DArray()

		!!!supply : supply : struct_array
			allocate(ids%supply (1))
 		allocate(ids%supply(1)%name(1)) 
			ids%supply(1)%name = getString()
		allocate(ids%supply(1)%identifier(1)) 
			ids%supply(1)%identifier = getString()
			tmpInt = getInteger()
			ids%supply(1)%type= tmpInt
			write(*,*) "ids%supply(1)%type", tmpInt
			ids%supply(1)%resistance = getDouble()
			ids%supply(1)%delay = getDouble()
		allocate(ids%supply(1)%filter_numerator(DIM_SIZE)) 
		ids%supply(1)%filter_numerator = getDouble1DArray()
		allocate(ids%supply(1)%filter_denominator(DIM_SIZE)) 
		ids%supply(1)%filter_denominator = getDouble1DArray()
			ids%supply(1)%current_limit_max = getDouble()
			ids%supply(1)%current_limit_min = getDouble()
			ids%supply(1)%voltage_limit_max = getDouble()
			ids%supply(1)%voltage_limit_min = getDouble()
			ids%supply(1)%current_limiter_gain = getDouble()
			ids%supply(1)%energy_limit_max = getDouble()
		allocate(ids%supply(1)%nonlinear_model(1)) 
			ids%supply(1)%nonlinear_model = getString()
		allocate(ids%supply(1)%voltage%data(DIM_SIZE)) 
		ids%supply(1)%voltage%data = getDouble1DArray()
		allocate(ids%supply(1)%voltage%time(DIM_SIZE)) 
		ids%supply(1)%voltage%time = getDouble1DArray()
		allocate(ids%supply(1)%current%data(DIM_SIZE)) 
		ids%supply(1)%current%data = getDouble1DArray()
		allocate(ids%supply(1)%current%time(DIM_SIZE)) 
		ids%supply(1)%current%time = getDouble1DArray()

		!!!name : code/name : STR_0D
		allocate(ids%code%name(1)) 
			ids%code%name = getString()

		!!!version : code/version : STR_0D
		allocate(ids%code%version(1)) 
			ids%code%version = getString()

		!!!parameters : code/parameters : STR_0D
		allocate(ids%code%parameters(1)) 
			ids%code%parameters = getString()

		!!!output_flag : code/output_flag : INT_1D
		allocate(ids%code%output_flag(DIM_SIZE)) 
			ids%code%output_flag = getInteger1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE pf_active_put 

!==================================================================
!		 PUT pf_passive 
!==================================================================
SUBROUTINE pf_passive_put
	CHARACTER (LEN = *), parameter :: idsName = "pf_passive"
	TYPE (ids_pf_passive) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on pf_passive"
	CALL srand(seed)
	do i = 0, 6 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!loop : loop : struct_array
			allocate(ids%loop (1))
 		allocate(ids%loop(1)%name(1)) 
			ids%loop(1)%name = getString()
			ids%loop(1)%area = getDouble()
			ids%loop(1)%resistance = getDouble()
		allocate(ids%loop(1)%current(DIM_SIZE)) 
		ids%loop(1)%current = getDouble1DArray()
			tmpInt = getInteger()
			ids%loop(1)%geometry%geometry_type= tmpInt
			write(*,*) "ids%loop(1)%geometry%geometry_type", tmpInt
		allocate(ids%loop(1)%geometry%outline%r(DIM_SIZE)) 
		ids%loop(1)%geometry%outline%r = getDouble1DArray()
		allocate(ids%loop(1)%geometry%outline%z(DIM_SIZE)) 
		ids%loop(1)%geometry%outline%z = getDouble1DArray()
			ids%loop(1)%geometry%rectangle%r = getDouble()
			ids%loop(1)%geometry%rectangle%z = getDouble()
			ids%loop(1)%geometry%rectangle%width = getDouble()
			ids%loop(1)%geometry%rectangle%height = getDouble()
			ids%loop(1)%geometry%oblique%r = getDouble()
			ids%loop(1)%geometry%oblique%z = getDouble()
			ids%loop(1)%geometry%oblique%length = getDouble()
			ids%loop(1)%geometry%oblique%thickness = getDouble()
			ids%loop(1)%geometry%oblique%alpha = getDouble()
			ids%loop(1)%geometry%oblique%beta = getDouble()

		!!!name : code/name : STR_0D
		allocate(ids%code%name(1)) 
			ids%code%name = getString()

		!!!version : code/version : STR_0D
		allocate(ids%code%version(1)) 
			ids%code%version = getString()

		!!!parameters : code/parameters : STR_0D
		allocate(ids%code%parameters(1)) 
			ids%code%parameters = getString()

		!!!output_flag : code/output_flag : INT_1D
		allocate(ids%code%output_flag(DIM_SIZE)) 
			ids%code%output_flag = getInteger1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE pf_passive_put 

!==================================================================
!		 PUT schedule 
!==================================================================
SUBROUTINE schedule_put
	CHARACTER (LEN = *), parameter :: idsName = "schedule"
	TYPE (ids_schedule) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on schedule"
	CALL srand(seed)
	do i = 0, 1 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!waveform : waveform : struct_array
			allocate(ids%waveform (1))
 		allocate(ids%waveform(1)%name(1)) 
			ids%waveform(1)%name = getString()
		allocate(ids%waveform(1)%value%data(DIM_SIZE)) 
		ids%waveform(1)%value%data = getDouble1DArray()
		allocate(ids%waveform(1)%value%time(DIM_SIZE)) 
		ids%waveform(1)%value%time = getDouble1DArray()

		!!!name : code/name : STR_0D
		allocate(ids%code%name(1)) 
			ids%code%name = getString()

		!!!version : code/version : STR_0D
		allocate(ids%code%version(1)) 
			ids%code%version = getString()

		!!!parameters : code/parameters : STR_0D
		allocate(ids%code%parameters(1)) 
			ids%code%parameters = getString()

		!!!output_flag : code/output_flag : INT_1D
		allocate(ids%code%output_flag(DIM_SIZE)) 
			ids%code%output_flag = getInteger1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE schedule_put 

!==================================================================
!		 PUT sdn 
!==================================================================
SUBROUTINE sdn_put
	CHARACTER (LEN = *), parameter :: idsName = "sdn"
	TYPE (ids_sdn) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on sdn"
	CALL srand(seed)
	do i = 0, 6 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!signal : signal : struct_array
			allocate(ids%signal (1))
 		allocate(ids%signal(1)%name(1)) 
			ids%signal(1)%name = getString()
		allocate(ids%signal(1)%definition(1)) 
			ids%signal(1)%definition = getString()
			tmpInt = getInteger()
			ids%signal(1)%ip_normalise= tmpInt
			write(*,*) "ids%signal(1)%ip_normalise", tmpInt
			tmpInt = getInteger()
			ids%signal(1)%allocated_position= tmpInt
			write(*,*) "ids%signal(1)%allocated_position", tmpInt
		allocate(ids%signal(1)%value(DIM_SIZE)) 
		ids%signal(1)%value = getDouble1DArray()

		!!!topic_list : topic_list : struct_array
			allocate(ids%topic_list (1))
 		allocate(ids%topic_list(1)%names(1)) 
			ids%topic_list(1)%names = getString()
		allocate(ids%topic_list(1)%indices(DIM_SIZE)) 
			ids%topic_list(1)%indices = getInteger1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE sdn_put 

!==================================================================
!		 PUT simulation 
!==================================================================
SUBROUTINE simulation_put
	CHARACTER (LEN = *), parameter :: idsName = "simulation"
	TYPE (ids_simulation) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on simulation"
	CALL srand(seed)
	do i = 0, 1 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!comment_before : comment_before : STR_0D
		allocate(ids%comment_before(1)) 
			ids%comment_before = getString()

		!!!comment_after : comment_after : STR_0D
		allocate(ids%comment_after(1)) 
			ids%comment_after = getString()

		!!!time_begin : time_begin : FLT_0D
			ids%time_begin = getDouble()

		!!!time_step : time_step : FLT_0D
			ids%time_step = getDouble()

		!!!time_end : time_end : FLT_0D
			ids%time_end = getDouble()

		!!!time_restart : time_restart : FLT_0D
			ids%time_restart = getDouble()

		!!!time_begun : time_begun : STR_0D
		allocate(ids%time_begun(1)) 
			ids%time_begun = getString()

		!!!time_ended : time_ended : STR_0D
		allocate(ids%time_ended(1)) 
			ids%time_ended = getString()

		!!!iterations_max : iterations_max : INT_0D
			tmpInt = getInteger()
			ids%iterations_max= tmpInt
			write(*,*) "ids%iterations_max", tmpInt

		!!!iterations_used : iterations_used : INT_0D
			tmpInt = getInteger()
			ids%iterations_used= tmpInt
			write(*,*) "ids%iterations_used", tmpInt

		!!!termination_condition : termination_condition : STR_0D
		allocate(ids%termination_condition(1)) 
			ids%termination_condition = getString()

		!!!rate_plot_equilibrium : rate_plot_equilibrium : INT_0D
			tmpInt = getInteger()
			ids%rate_plot_equilibrium= tmpInt
			write(*,*) "ids%rate_plot_equilibrium", tmpInt

		!!!device_name : device_name : STR_0D
		allocate(ids%device_name(1)) 
			ids%device_name = getString()

		!!!restart_simulation : restart_simulation : STR_0D
		allocate(ids%restart_simulation(1)) 
			ids%restart_simulation = getString()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE simulation_put 

!==================================================================
!		 PUT temporary 
!==================================================================
SUBROUTINE temporary_put
	CHARACTER (LEN = *), parameter :: idsName = "temporary"
	TYPE (ids_temporary) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on temporary"
	CALL srand(seed)
	do i = 0, 6 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!constant_float0d : constant_float0d : struct_array
			allocate(ids%constant_float0d (1))
 			ids%constant_float0d(1)%value = getDouble()
		allocate(ids%constant_float0d(1)%identifier%name(1)) 
			ids%constant_float0d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%constant_float0d(1)%identifier%index= tmpInt
			write(*,*) "ids%constant_float0d(1)%identifier%index", tmpInt
		allocate(ids%constant_float0d(1)%identifier%description(1)) 
			ids%constant_float0d(1)%identifier%description = getString()

		!!!constant_integer0d : constant_integer0d : struct_array
			allocate(ids%constant_integer0d (1))
 			tmpInt = getInteger()
			ids%constant_integer0d(1)%value= tmpInt
			write(*,*) "ids%constant_integer0d(1)%value", tmpInt
		allocate(ids%constant_integer0d(1)%identifier%name(1)) 
			ids%constant_integer0d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%constant_integer0d(1)%identifier%index= tmpInt
			write(*,*) "ids%constant_integer0d(1)%identifier%index", tmpInt
		allocate(ids%constant_integer0d(1)%identifier%description(1)) 
			ids%constant_integer0d(1)%identifier%description = getString()

		!!!constant_string0d : constant_string0d : struct_array
			allocate(ids%constant_string0d (1))
 		allocate(ids%constant_string0d(1)%value(1)) 
			ids%constant_string0d(1)%value = getString()
		allocate(ids%constant_string0d(1)%identifier%name(1)) 
			ids%constant_string0d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%constant_string0d(1)%identifier%index= tmpInt
			write(*,*) "ids%constant_string0d(1)%identifier%index", tmpInt
		allocate(ids%constant_string0d(1)%identifier%description(1)) 
			ids%constant_string0d(1)%identifier%description = getString()

		!!!constant_integer1d : constant_integer1d : struct_array
			allocate(ids%constant_integer1d (1))
 		allocate(ids%constant_integer1d(1)%value(DIM_SIZE)) 
			ids%constant_integer1d(1)%value = getInteger1DArray()
		allocate(ids%constant_integer1d(1)%identifier%name(1)) 
			ids%constant_integer1d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%constant_integer1d(1)%identifier%index= tmpInt
			write(*,*) "ids%constant_integer1d(1)%identifier%index", tmpInt
		allocate(ids%constant_integer1d(1)%identifier%description(1)) 
			ids%constant_integer1d(1)%identifier%description = getString()

		!!!constant_string1d : constant_string1d : struct_array
			allocate(ids%constant_string1d (1))
 		allocate(ids%constant_string1d(1)%value(1)) 
			ids%constant_string1d(1)%value = getString()
		allocate(ids%constant_string1d(1)%identifier%name(1)) 
			ids%constant_string1d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%constant_string1d(1)%identifier%index= tmpInt
			write(*,*) "ids%constant_string1d(1)%identifier%index", tmpInt
		allocate(ids%constant_string1d(1)%identifier%description(1)) 
			ids%constant_string1d(1)%identifier%description = getString()

		!!!constant_float1d : constant_float1d : struct_array
			allocate(ids%constant_float1d (1))
 		allocate(ids%constant_float1d(1)%value(DIM_SIZE)) 
		ids%constant_float1d(1)%value = getDouble1DArray()
		allocate(ids%constant_float1d(1)%identifier%name(1)) 
			ids%constant_float1d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%constant_float1d(1)%identifier%index= tmpInt
			write(*,*) "ids%constant_float1d(1)%identifier%index", tmpInt
		allocate(ids%constant_float1d(1)%identifier%description(1)) 
			ids%constant_float1d(1)%identifier%description = getString()

		!!!dynamic_float1d : dynamic_float1d : struct_array
			allocate(ids%dynamic_float1d (1))
 		allocate(ids%dynamic_float1d(1)%value%data(DIM_SIZE)) 
		ids%dynamic_float1d(1)%value%data = getDouble1DArray()
		allocate(ids%dynamic_float1d(1)%value%time(DIM_SIZE)) 
		ids%dynamic_float1d(1)%value%time = getDouble1DArray()
		allocate(ids%dynamic_float1d(1)%identifier%name(1)) 
			ids%dynamic_float1d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%dynamic_float1d(1)%identifier%index= tmpInt
			write(*,*) "ids%dynamic_float1d(1)%identifier%index", tmpInt
		allocate(ids%dynamic_float1d(1)%identifier%description(1)) 
			ids%dynamic_float1d(1)%identifier%description = getString()

		!!!dynamic_string1d : dynamic_string1d : struct_array
			allocate(ids%dynamic_string1d (1))
 		allocate(ids%dynamic_string1d(1)%value%data(1)) 
			ids%dynamic_string1d(1)%value%data = getString()
		allocate(ids%dynamic_string1d(1)%value%time(DIM_SIZE)) 
		ids%dynamic_string1d(1)%value%time = getDouble1DArray()
		allocate(ids%dynamic_string1d(1)%identifier%name(1)) 
			ids%dynamic_string1d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%dynamic_string1d(1)%identifier%index= tmpInt
			write(*,*) "ids%dynamic_string1d(1)%identifier%index", tmpInt
		allocate(ids%dynamic_string1d(1)%identifier%description(1)) 
			ids%dynamic_string1d(1)%identifier%description = getString()

		!!!dynamic_integer1d : dynamic_integer1d : struct_array
			allocate(ids%dynamic_integer1d (1))
 		allocate(ids%dynamic_integer1d(1)%value%data(DIM_SIZE)) 
			ids%dynamic_integer1d(1)%value%data = getInteger1DArray()
		allocate(ids%dynamic_integer1d(1)%value%time(DIM_SIZE)) 
		ids%dynamic_integer1d(1)%value%time = getDouble1DArray()
		allocate(ids%dynamic_integer1d(1)%identifier%name(1)) 
			ids%dynamic_integer1d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%dynamic_integer1d(1)%identifier%index= tmpInt
			write(*,*) "ids%dynamic_integer1d(1)%identifier%index", tmpInt
		allocate(ids%dynamic_integer1d(1)%identifier%description(1)) 
			ids%dynamic_integer1d(1)%identifier%description = getString()

		!!!constant_float2d : constant_float2d : struct_array
			allocate(ids%constant_float2d (1))
 		allocate(ids%constant_float2d(1)%value(DIM_SIZE, DIM_SIZE)) 
			ids%constant_float2d(1)%value = getDouble2DArray()
		allocate(ids%constant_float2d(1)%identifier%name(1)) 
			ids%constant_float2d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%constant_float2d(1)%identifier%index= tmpInt
			write(*,*) "ids%constant_float2d(1)%identifier%index", tmpInt
		allocate(ids%constant_float2d(1)%identifier%description(1)) 
			ids%constant_float2d(1)%identifier%description = getString()

		!!!constant_integer2d : constant_integer2d : struct_array
			allocate(ids%constant_integer2d (1))
 		allocate(ids%constant_integer2d(1)%value(DIM_SIZE, DIM_SIZE)) 
			ids%constant_integer2d(1)%value = getInteger2DArray()
		allocate(ids%constant_integer2d(1)%identifier%name(1)) 
			ids%constant_integer2d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%constant_integer2d(1)%identifier%index= tmpInt
			write(*,*) "ids%constant_integer2d(1)%identifier%index", tmpInt
		allocate(ids%constant_integer2d(1)%identifier%description(1)) 
			ids%constant_integer2d(1)%identifier%description = getString()

		!!!dynamic_float2d : dynamic_float2d : struct_array
			allocate(ids%dynamic_float2d (1))
 		allocate(ids%dynamic_float2d(1)%value%data(DIM_SIZE, DIM_SIZE)) 
			ids%dynamic_float2d(1)%value%data = getDouble2DArray()
		allocate(ids%dynamic_float2d(1)%value%time(DIM_SIZE)) 
		ids%dynamic_float2d(1)%value%time = getDouble1DArray()
		allocate(ids%dynamic_float2d(1)%identifier%name(1)) 
			ids%dynamic_float2d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%dynamic_float2d(1)%identifier%index= tmpInt
			write(*,*) "ids%dynamic_float2d(1)%identifier%index", tmpInt
		allocate(ids%dynamic_float2d(1)%identifier%description(1)) 
			ids%dynamic_float2d(1)%identifier%description = getString()

		!!!dynamic_integer2d : dynamic_integer2d : struct_array
			allocate(ids%dynamic_integer2d (1))
 		allocate(ids%dynamic_integer2d(1)%value%data(DIM_SIZE, DIM_SIZE)) 
			ids%dynamic_integer2d(1)%value%data = getInteger2DArray()
		allocate(ids%dynamic_integer2d(1)%value%time(DIM_SIZE)) 
		ids%dynamic_integer2d(1)%value%time = getDouble1DArray()
		allocate(ids%dynamic_integer2d(1)%identifier%name(1)) 
			ids%dynamic_integer2d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%dynamic_integer2d(1)%identifier%index= tmpInt
			write(*,*) "ids%dynamic_integer2d(1)%identifier%index", tmpInt
		allocate(ids%dynamic_integer2d(1)%identifier%description(1)) 
			ids%dynamic_integer2d(1)%identifier%description = getString()

		!!!constant_float3d : constant_float3d : struct_array
			allocate(ids%constant_float3d (1))
 		allocate(ids%constant_float3d(1)%value(DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%constant_float3d(1)%value = getDouble3DArray()
		allocate(ids%constant_float3d(1)%identifier%name(1)) 
			ids%constant_float3d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%constant_float3d(1)%identifier%index= tmpInt
			write(*,*) "ids%constant_float3d(1)%identifier%index", tmpInt
		allocate(ids%constant_float3d(1)%identifier%description(1)) 
			ids%constant_float3d(1)%identifier%description = getString()

		!!!constant_integer3d : constant_integer3d : struct_array
			allocate(ids%constant_integer3d (1))
 		allocate(ids%constant_integer3d(1)%value(DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%constant_integer3d(1)%value = getInteger3DArray()
		allocate(ids%constant_integer3d(1)%identifier%name(1)) 
			ids%constant_integer3d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%constant_integer3d(1)%identifier%index= tmpInt
			write(*,*) "ids%constant_integer3d(1)%identifier%index", tmpInt
		allocate(ids%constant_integer3d(1)%identifier%description(1)) 
			ids%constant_integer3d(1)%identifier%description = getString()

		!!!dynamic_float3d : dynamic_float3d : struct_array
			allocate(ids%dynamic_float3d (1))
 		allocate(ids%dynamic_float3d(1)%value%data(DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%dynamic_float3d(1)%value%data = getDouble3DArray()
		allocate(ids%dynamic_float3d(1)%value%time(DIM_SIZE)) 
		ids%dynamic_float3d(1)%value%time = getDouble1DArray()
		allocate(ids%dynamic_float3d(1)%identifier%name(1)) 
			ids%dynamic_float3d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%dynamic_float3d(1)%identifier%index= tmpInt
			write(*,*) "ids%dynamic_float3d(1)%identifier%index", tmpInt
		allocate(ids%dynamic_float3d(1)%identifier%description(1)) 
			ids%dynamic_float3d(1)%identifier%description = getString()

		!!!dynamic_integer3d : dynamic_integer3d : struct_array
			allocate(ids%dynamic_integer3d (1))
 		allocate(ids%dynamic_integer3d(1)%value%data(DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%dynamic_integer3d(1)%value%data = getInteger3DArray()
		allocate(ids%dynamic_integer3d(1)%value%time(DIM_SIZE)) 
		ids%dynamic_integer3d(1)%value%time = getDouble1DArray()
		allocate(ids%dynamic_integer3d(1)%identifier%name(1)) 
			ids%dynamic_integer3d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%dynamic_integer3d(1)%identifier%index= tmpInt
			write(*,*) "ids%dynamic_integer3d(1)%identifier%index", tmpInt
		allocate(ids%dynamic_integer3d(1)%identifier%description(1)) 
			ids%dynamic_integer3d(1)%identifier%description = getString()

		!!!constant_float4d : constant_float4d : struct_array
			allocate(ids%constant_float4d (1))
 		allocate(ids%constant_float4d(1)%value(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%constant_float4d(1)%value = getDouble4DArray()
		allocate(ids%constant_float4d(1)%identifier%name(1)) 
			ids%constant_float4d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%constant_float4d(1)%identifier%index= tmpInt
			write(*,*) "ids%constant_float4d(1)%identifier%index", tmpInt
		allocate(ids%constant_float4d(1)%identifier%description(1)) 
			ids%constant_float4d(1)%identifier%description = getString()

		!!!dynamic_float4d : dynamic_float4d : struct_array
			allocate(ids%dynamic_float4d (1))
 		allocate(ids%dynamic_float4d(1)%value%data(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%dynamic_float4d(1)%value%data = getDouble4DArray()
		allocate(ids%dynamic_float4d(1)%value%time(DIM_SIZE)) 
		ids%dynamic_float4d(1)%value%time = getDouble1DArray()
		allocate(ids%dynamic_float4d(1)%identifier%name(1)) 
			ids%dynamic_float4d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%dynamic_float4d(1)%identifier%index= tmpInt
			write(*,*) "ids%dynamic_float4d(1)%identifier%index", tmpInt
		allocate(ids%dynamic_float4d(1)%identifier%description(1)) 
			ids%dynamic_float4d(1)%identifier%description = getString()

		!!!constant_float5d : constant_float5d : struct_array
			allocate(ids%constant_float5d (1))
 		allocate(ids%constant_float5d(1)%value(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%constant_float5d(1)%value = getDouble5DArray()
		allocate(ids%constant_float5d(1)%identifier%name(1)) 
			ids%constant_float5d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%constant_float5d(1)%identifier%index= tmpInt
			write(*,*) "ids%constant_float5d(1)%identifier%index", tmpInt
		allocate(ids%constant_float5d(1)%identifier%description(1)) 
			ids%constant_float5d(1)%identifier%description = getString()

		!!!dynamic_float5d : dynamic_float5d : struct_array
			allocate(ids%dynamic_float5d (1))
 		allocate(ids%dynamic_float5d(1)%value%data(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%dynamic_float5d(1)%value%data = getDouble5DArray()
		allocate(ids%dynamic_float5d(1)%value%time(DIM_SIZE)) 
		ids%dynamic_float5d(1)%value%time = getDouble1DArray()
		allocate(ids%dynamic_float5d(1)%identifier%name(1)) 
			ids%dynamic_float5d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%dynamic_float5d(1)%identifier%index= tmpInt
			write(*,*) "ids%dynamic_float5d(1)%identifier%index", tmpInt
		allocate(ids%dynamic_float5d(1)%identifier%description(1)) 
			ids%dynamic_float5d(1)%identifier%description = getString()

		!!!constant_float6d : constant_float6d : struct_array
			allocate(ids%constant_float6d (1))
 		allocate(ids%constant_float6d(1)%value(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%constant_float6d(1)%value = getDouble6DArray()
		allocate(ids%constant_float6d(1)%identifier%name(1)) 
			ids%constant_float6d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%constant_float6d(1)%identifier%index= tmpInt
			write(*,*) "ids%constant_float6d(1)%identifier%index", tmpInt
		allocate(ids%constant_float6d(1)%identifier%description(1)) 
			ids%constant_float6d(1)%identifier%description = getString()

		!!!dynamic_float6d : dynamic_float6d : struct_array
			allocate(ids%dynamic_float6d (1))
 		allocate(ids%dynamic_float6d(1)%value%data(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE)) 
			ids%dynamic_float6d(1)%value%data = getDouble6DArray()
		allocate(ids%dynamic_float6d(1)%value%time(DIM_SIZE)) 
		ids%dynamic_float6d(1)%value%time = getDouble1DArray()
		allocate(ids%dynamic_float6d(1)%identifier%name(1)) 
			ids%dynamic_float6d(1)%identifier%name = getString()
			tmpInt = getInteger()
			ids%dynamic_float6d(1)%identifier%index= tmpInt
			write(*,*) "ids%dynamic_float6d(1)%identifier%index", tmpInt
		allocate(ids%dynamic_float6d(1)%identifier%description(1)) 
			ids%dynamic_float6d(1)%identifier%description = getString()

		!!!name : code/name : STR_0D
		allocate(ids%code%name(1)) 
			ids%code%name = getString()

		!!!version : code/version : STR_0D
		allocate(ids%code%version(1)) 
			ids%code%version = getString()

		!!!parameters : code/parameters : STR_0D
		allocate(ids%code%parameters(1)) 
			ids%code%parameters = getString()

		!!!output_flag : code/output_flag : INT_1D
		allocate(ids%code%output_flag(DIM_SIZE)) 
			ids%code%output_flag = getInteger1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE temporary_put 

!==================================================================
!		 PUT tf 
!==================================================================
SUBROUTINE tf_put
	CHARACTER (LEN = *), parameter :: idsName = "tf"
	TYPE (ids_tf) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	INTEGER :: tmpInt = -1 
	WRITE(*,*) "Testing put() on tf"
	CALL srand(seed)
	do i = 0, 6 

		!!!comment : ids_properties/comment : STR_0D
		allocate(ids%ids_properties%comment(1)) 
			ids%ids_properties%comment = getString()

		!!!homogeneous_time : ids_properties/homogeneous_time : INT_0D
			ids%ids_properties%homogeneous_time= 1

		!!!cocos : ids_properties/cocos : INT_0D
			tmpInt = getInteger()
			ids%ids_properties%cocos= tmpInt
			write(*,*) "ids%ids_properties%cocos", tmpInt

		!!!coil : coil : struct_array
			allocate(ids%coil (1))
 			tmpInt = getInteger()
			ids%coil(1)%turns= tmpInt
			write(*,*) "ids%coil(1)%turns", tmpInt
		allocate(ids%coil(1)%current%data(DIM_SIZE)) 
		ids%coil(1)%current%data = getDouble1DArray()
		allocate(ids%coil(1)%current%time(DIM_SIZE)) 
		ids%coil(1)%current%time = getDouble1DArray()
		allocate(ids%coil(1)%voltage%data(DIM_SIZE)) 
		ids%coil(1)%voltage%data = getDouble1DArray()
		allocate(ids%coil(1)%voltage%time(DIM_SIZE)) 
		ids%coil(1)%voltage%time = getDouble1DArray()

		!!!data : b_tor_vacuum_r/data : FLT_1D
		allocate(ids%b_tor_vacuum_r%data(DIM_SIZE)) 
		ids%b_tor_vacuum_r%data = getDouble1DArray()

		!!!time : b_tor_vacuum_r/time : flt_1d_type
		allocate(ids%b_tor_vacuum_r%time(DIM_SIZE)) 
		ids%b_tor_vacuum_r%time = getDouble1DArray()

		!!!time : time : flt_1d_type
		allocate(ids%time(DIM_SIZE)) 
		ids%time = getDouble1DArray()
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_put(idx, idspath, ids);
	end do 

END SUBROUTINE tf_put 

!==================================================================
!		 GET actuator 
!==================================================================
SUBROUTINE actuator_get
	CHARACTER (LEN = *), parameter :: idsName = "actuator"
	TYPE (ids_actuator) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on actuator"
	CALL srand(seed)
	do i = 0, 6 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "actuator/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "actuator/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "actuator/ids_properties/cocos");

		!!!  name:name:STR_0D:static:
			 call assertField(ids%name, getString(), "actuator/name");

		!!!  channels:channels:STR_1D:static:
			 call assertField(ids%channels,  getString(), "actuator/channels");

		!!!  power:power:FLT_2D:dynamic:
			 call assertField(ids%power, getDouble2DArray(), "actuator/power");

		!!!  generic_dynamic:generic_dynamic:FLT_2D:dynamic:
			 call assertField(ids%generic_dynamic, getDouble2DArray(), "actuator/generic_dynamic");

		!!!  name:code/name:STR_0D:constant:
			 call assertField(ids%code%name, getString(), "actuator/code/name");

		!!!  version:code/version:STR_0D:constant:
			 call assertField(ids%code%version, getString(), "actuator/code/version");

		!!!  parameters:code/parameters:STR_0D:constant:
			 call assertField(ids%code%parameters, getString(), "actuator/code/parameters");

		!!!  output_flag:code/output_flag:INT_1D:dynamic:
			 call assertField(ids%code%output_flag, getInteger1DArray(), "actuator/code/output_flag");

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "actuator/time");
	end do 
	
END SUBROUTINE actuator_get

!==================================================================
!		 GET atomic_data 
!==================================================================
SUBROUTINE atomic_data_get
	CHARACTER (LEN = *), parameter :: idsName = "atomic_data"
	TYPE (ids_atomic_data) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on atomic_data"
	CALL srand(seed)
	do i = 0, 2 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "atomic_data/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "atomic_data/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "atomic_data/ids_properties/cocos");

		!!!  z_n:z_n:FLT_0D:static:
			 call assertField(ids%z_n, getDouble(), "atomic_data/z_n");

		!!!  a:a:FLT_0D:static:
			 call assertField(ids%a, getDouble(), "atomic_data/a");

		!!!  process:process:struct_array::
		if(.not. associated(ids%process)) then 
			write(*,*) "ERROR! IDS: atomic_data Field: process is not associated!"
 			else 

		!!!  label:process/label:STR_0D:static:
			call assertField(ids%process(1)%label, getString(), "atomic_data/process/label");

		!!!  table_dimension:process/table_dimension:INT_0D:static:
			call assertField(ids%process(1)%table_dimension, getInteger(), "atomic_data/process/table_dimension");

		!!!  coordinate_index:process/coordinate_index:INT_0D:static:
			call assertField(ids%process(1)%coordinate_index, getInteger(), "atomic_data/process/coordinate_index");

		!!!  result_label:process/result_label:STR_0D:static:
			call assertField(ids%process(1)%result_label, getString(), "atomic_data/process/result_label");

		!!!  result_units:process/result_units:STR_0D:static:
			call assertField(ids%process(1)%result_units, getString(), "atomic_data/process/result_units");

		!!!  result_transformation:process/result_transformation:INT_0D:static:
			call assertField(ids%process(1)%result_transformation, getInteger(), "atomic_data/process/result_transformation");

		!!!  charge_state:process/charge_state:struct_array::
		if(.not. associated(ids%process(1)%charge_state)) then 
			write(*,*) "ERROR! IDS: atomic_data Field: process(1)%charge_state(1) is not associated!"
 			else 

		!!!  label:process/charge_state/label:STR_0D:static:
			call assertField(ids%process(1)%charge_state(1)%label, getString(), "atomic_data/process/charge_state/label");

		!!!  z_min:process/charge_state/z_min:FLT_0D:static:
			call assertField(ids%process(1)%charge_state(1)%z_min, getDouble(), "atomic_data/process/charge_state/z_min");

		!!!  z_max:process/charge_state/z_max:FLT_0D:static:
			call assertField(ids%process(1)%charge_state(1)%z_max, getDouble(), "atomic_data/process/charge_state/z_max");

		!!!  table_0d:process/charge_state/table_0d:FLT_0D:static:
			call assertField(ids%process(1)%charge_state(1)%table_0d, getDouble(), "atomic_data/process/charge_state/table_0d");

		!!!  table_1d:process/charge_state/table_1d:FLT_1D:static:
			call assertField(ids%process(1)%charge_state(1)%table_1d, getDouble1DArray(), "atomic_data/process/charge_state/table_1d");

		!!!  table_2d:process/charge_state/table_2d:FLT_2D:static:
			call assertField(ids%process(1)%charge_state(1)%table_2d, getDouble2DArray(), "atomic_data/process/charge_state/table_2d");

		!!!  table_3d:process/charge_state/table_3d:FLT_3D:static:
			call assertField(ids%process(1)%charge_state(1)%table_3d, getDouble3DArray(), "atomic_data/process/charge_state/table_3d");

		!!!  table_4d:process/charge_state/table_4d:FLT_4D:static:
			call assertField(ids%process(1)%charge_state(1)%table_4d, getDouble4DArray(), "atomic_data/process/charge_state/table_4d");

		!!!  table_5d:process/charge_state/table_5d:FLT_5D:static:
			call assertField(ids%process(1)%charge_state(1)%table_5d, getDouble5DArray(), "atomic_data/process/charge_state/table_5d");

		!!!  table_6d:process/charge_state/table_6d:FLT_6D:static:
			call assertField(ids%process(1)%charge_state(1)%table_6d, getDouble6DArray(), "atomic_data/process/charge_state/table_6d");
		end if 
		end if 

		!!!  coordinate_system:coordinate_system:struct_array::
		if(.not. associated(ids%coordinate_system)) then 
			write(*,*) "ERROR! IDS: atomic_data Field: coordinate_system is not associated!"
 			else 

		!!!  coordinate:coordinate_system/coordinate:struct_array::
		if(.not. associated(ids%coordinate_system(1)%coordinate)) then 
			write(*,*) "ERROR! IDS: atomic_data Field: coordinate_system(1)%coordinate(1) is not associated!"
 			else 

		!!!  label:coordinate_system/coordinate/label:STR_0D:static:
			call assertField(ids%coordinate_system(1)%coordinate(1)%label, getString(), "atomic_data/coordinate_system/coordinate/label");

		!!!  values:coordinate_system/coordinate/values:FLT_1D:static:
			call assertField(ids%coordinate_system(1)%coordinate(1)%values, getDouble1DArray(), "atomic_data/coordinate_system/coordinate/values");

		!!!  interpolation_type:coordinate_system/coordinate/interpolation_type:INT_0D:static:
			call assertField(ids%coordinate_system(1)%coordinate(1)%interpolation_type, getInteger(), "atomic_data/coordinate_system/coordinate/interpolation_type");

		!!!  extrapolation_type:coordinate_system/coordinate/extrapolation_type:INT_1D:static:
			call assertField(ids%coordinate_system(1)%coordinate(1)%extrapolation_type, getInteger1DArray(), "atomic_data/coordinate_system/coordinate/extrapolation_type");

		!!!  value_labels:coordinate_system/coordinate/value_labels:STR_1D:static:
			call assertField(ids%coordinate_system(1)%coordinate(1)%value_labels,  getString(), "atomic_data/coordinate_system/coordinate/value_labels");

		!!!  units:coordinate_system/coordinate/units:STR_0D:static:
			call assertField(ids%coordinate_system(1)%coordinate(1)%units, getString(), "atomic_data/coordinate_system/coordinate/units");

		!!!  transformation:coordinate_system/coordinate/transformation:INT_0D:static:
			call assertField(ids%coordinate_system(1)%coordinate(1)%transformation, getInteger(), "atomic_data/coordinate_system/coordinate/transformation");

		!!!  spacing:coordinate_system/coordinate/spacing:INT_0D:static:
			call assertField(ids%coordinate_system(1)%coordinate(1)%spacing, getInteger(), "atomic_data/coordinate_system/coordinate/spacing");
		end if 
		end if 

		!!!  name:code/name:STR_0D:constant:
			 call assertField(ids%code%name, getString(), "atomic_data/code/name");

		!!!  version:code/version:STR_0D:constant:
			 call assertField(ids%code%version, getString(), "atomic_data/code/version");

		!!!  parameters:code/parameters:STR_0D:constant:
			 call assertField(ids%code%parameters, getString(), "atomic_data/code/parameters");

		!!!  output_flag:code/output_flag:INT_1D:dynamic:
			 call assertField(ids%code%output_flag, getInteger1DArray(), "atomic_data/code/output_flag");

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "atomic_data/time");
	end do 
	
END SUBROUTINE atomic_data_get

!==================================================================
!		 GET controllers 
!==================================================================
SUBROUTINE controllers_get
	CHARACTER (LEN = *), parameter :: idsName = "controllers"
	TYPE (ids_controllers) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on controllers"
	CALL srand(seed)
	do i = 0, 2 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "controllers/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "controllers/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "controllers/ids_properties/cocos");

		!!!  linear_controller:linear_controller:struct_array::
		if(.not. associated(ids%linear_controller)) then 
			write(*,*) "ERROR! IDS: controllers Field: linear_controller is not associated!"
 			else 

		!!!  name:linear_controller/name:STR_0D:constant:
			call assertField(ids%linear_controller(1)%name, getString(), "controllers/linear_controller/name");

		!!!  description:linear_controller/description:STR_0D:constant:
			call assertField(ids%linear_controller(1)%description, getString(), "controllers/linear_controller/description");

		!!!  controller_class:linear_controller/controller_class:STR_0D:constant:
			call assertField(ids%linear_controller(1)%controller_class, getString(), "controllers/linear_controller/controller_class");

		!!!  input_names:linear_controller/input_names:STR_1D:constant:
			call assertField(ids%linear_controller(1)%input_names,  getString(), "controllers/linear_controller/input_names");

		!!!  output_names:linear_controller/output_names:STR_1D:constant:
			call assertField(ids%linear_controller(1)%output_names,  getString(), "controllers/linear_controller/output_names");

		!!!  statespace:linear_controller/statespace:structure::

		!!!  state_names:linear_controller/statespace/state_names:STR_1D:constant:
			call assertField(ids%linear_controller(1)%statespace%state_names,  getString(), "controllers/linear_controller/statespace/state_names");

		!!!  a:linear_controller/statespace/a:structure::

		!!!  data:linear_controller/statespace/a/data:FLT_3D:dynamic:
			call assertField(ids%linear_controller(1)%statespace%a%data, getDouble3DArray(), "controllers/linear_controller/statespace/a/data");

		!!!  time:linear_controller/statespace/a/time:flt_1d_type:dynamic:
			call assertField(ids%linear_controller(1)%statespace%a%time, getDouble1DArray(), "controllers/linear_controller/statespace/a/time");

		!!!  b:linear_controller/statespace/b:structure::

		!!!  data:linear_controller/statespace/b/data:FLT_3D:dynamic:
			call assertField(ids%linear_controller(1)%statespace%b%data, getDouble3DArray(), "controllers/linear_controller/statespace/b/data");

		!!!  time:linear_controller/statespace/b/time:flt_1d_type:dynamic:
			call assertField(ids%linear_controller(1)%statespace%b%time, getDouble1DArray(), "controllers/linear_controller/statespace/b/time");

		!!!  c:linear_controller/statespace/c:structure::

		!!!  data:linear_controller/statespace/c/data:FLT_3D:dynamic:
			call assertField(ids%linear_controller(1)%statespace%c%data, getDouble3DArray(), "controllers/linear_controller/statespace/c/data");

		!!!  time:linear_controller/statespace/c/time:flt_1d_type:dynamic:
			call assertField(ids%linear_controller(1)%statespace%c%time, getDouble1DArray(), "controllers/linear_controller/statespace/c/time");

		!!!  d:linear_controller/statespace/d:structure::

		!!!  data:linear_controller/statespace/d/data:FLT_3D:dynamic:
			call assertField(ids%linear_controller(1)%statespace%d%data, getDouble3DArray(), "controllers/linear_controller/statespace/d/data");

		!!!  time:linear_controller/statespace/d/time:flt_1d_type:dynamic:
			call assertField(ids%linear_controller(1)%statespace%d%time, getDouble1DArray(), "controllers/linear_controller/statespace/d/time");

		!!!  deltat:linear_controller/statespace/deltat:structure::

		!!!  data:linear_controller/statespace/deltat/data:FLT_1D:dynamic:
			call assertField(ids%linear_controller(1)%statespace%deltat%data, getDouble1DArray(), "controllers/linear_controller/statespace/deltat/data");

		!!!  time:linear_controller/statespace/deltat/time:flt_1d_type:dynamic:
			call assertField(ids%linear_controller(1)%statespace%deltat%time, getDouble1DArray(), "controllers/linear_controller/statespace/deltat/time");

		!!!  pid:linear_controller/pid:structure::

		!!!  p:linear_controller/pid/p:structure::

		!!!  data:linear_controller/pid/p/data:FLT_3D:dynamic:
			call assertField(ids%linear_controller(1)%pid%p%data, getDouble3DArray(), "controllers/linear_controller/pid/p/data");

		!!!  time:linear_controller/pid/p/time:flt_1d_type:dynamic:
			call assertField(ids%linear_controller(1)%pid%p%time, getDouble1DArray(), "controllers/linear_controller/pid/p/time");

		!!!  i:linear_controller/pid/i:structure::

		!!!  data:linear_controller/pid/i/data:FLT_3D:dynamic:
			call assertField(ids%linear_controller(1)%pid%i%data, getDouble3DArray(), "controllers/linear_controller/pid/i/data");

		!!!  time:linear_controller/pid/i/time:flt_1d_type:dynamic:
			call assertField(ids%linear_controller(1)%pid%i%time, getDouble1DArray(), "controllers/linear_controller/pid/i/time");

		!!!  d:linear_controller/pid/d:structure::

		!!!  data:linear_controller/pid/d/data:FLT_3D:dynamic:
			call assertField(ids%linear_controller(1)%pid%d%data, getDouble3DArray(), "controllers/linear_controller/pid/d/data");

		!!!  time:linear_controller/pid/d/time:flt_1d_type:dynamic:
			call assertField(ids%linear_controller(1)%pid%d%time, getDouble1DArray(), "controllers/linear_controller/pid/d/time");

		!!!  tau:linear_controller/pid/tau:structure::

		!!!  data:linear_controller/pid/tau/data:FLT_1D:dynamic:
			call assertField(ids%linear_controller(1)%pid%tau%data, getDouble1DArray(), "controllers/linear_controller/pid/tau/data");

		!!!  time:linear_controller/pid/tau/time:flt_1d_type:dynamic:
			call assertField(ids%linear_controller(1)%pid%tau%time, getDouble1DArray(), "controllers/linear_controller/pid/tau/time");

		!!!  inputs:linear_controller/inputs:structure::

		!!!  data:linear_controller/inputs/data:FLT_2D:dynamic:
			call assertField(ids%linear_controller(1)%inputs%data, getDouble2DArray(), "controllers/linear_controller/inputs/data");

		!!!  time:linear_controller/inputs/time:flt_1d_type:dynamic:
			call assertField(ids%linear_controller(1)%inputs%time, getDouble1DArray(), "controllers/linear_controller/inputs/time");

		!!!  outputs:linear_controller/outputs:structure::

		!!!  data:linear_controller/outputs/data:FLT_2D:dynamic:
			call assertField(ids%linear_controller(1)%outputs%data, getDouble2DArray(), "controllers/linear_controller/outputs/data");

		!!!  time:linear_controller/outputs/time:flt_1d_type:dynamic:
			call assertField(ids%linear_controller(1)%outputs%time, getDouble1DArray(), "controllers/linear_controller/outputs/time");
		end if 

		!!!  nonlinear_controller:nonlinear_controller:struct_array::
		if(.not. associated(ids%nonlinear_controller)) then 
			write(*,*) "ERROR! IDS: controllers Field: nonlinear_controller is not associated!"
 			else 

		!!!  name:nonlinear_controller/name:STR_0D:constant:
			call assertField(ids%nonlinear_controller(1)%name, getString(), "controllers/nonlinear_controller/name");

		!!!  description:nonlinear_controller/description:STR_0D:constant:
			call assertField(ids%nonlinear_controller(1)%description, getString(), "controllers/nonlinear_controller/description");

		!!!  controller_class:nonlinear_controller/controller_class:STR_0D:constant:
			call assertField(ids%nonlinear_controller(1)%controller_class, getString(), "controllers/nonlinear_controller/controller_class");

		!!!  input_names:nonlinear_controller/input_names:STR_1D:constant:
			call assertField(ids%nonlinear_controller(1)%input_names,  getString(), "controllers/nonlinear_controller/input_names");

		!!!  output_names:nonlinear_controller/output_names:STR_1D:constant:
			call assertField(ids%nonlinear_controller(1)%output_names,  getString(), "controllers/nonlinear_controller/output_names");

		!!!  function:nonlinear_controller/function:STR_0D:constant:
			call assertField(ids%nonlinear_controller(1)%function, getString(), "controllers/nonlinear_controller/function");

		!!!  inputs:nonlinear_controller/inputs:structure::

		!!!  data:nonlinear_controller/inputs/data:FLT_2D:constant:
			call assertField(ids%nonlinear_controller(1)%inputs%data, getDouble2DArray(), "controllers/nonlinear_controller/inputs/data");

		!!!  time:nonlinear_controller/inputs/time:flt_1d_type:dynamic:
			call assertField(ids%nonlinear_controller(1)%inputs%time, getDouble1DArray(), "controllers/nonlinear_controller/inputs/time");

		!!!  outputs:nonlinear_controller/outputs:structure::

		!!!  data:nonlinear_controller/outputs/data:FLT_2D:dynamic:
			call assertField(ids%nonlinear_controller(1)%outputs%data, getDouble2DArray(), "controllers/nonlinear_controller/outputs/data");

		!!!  time:nonlinear_controller/outputs/time:flt_1d_type:dynamic:
			call assertField(ids%nonlinear_controller(1)%outputs%time, getDouble1DArray(), "controllers/nonlinear_controller/outputs/time");
		end if 

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "controllers/time");

		!!!  name:code/name:STR_0D:constant:
			 call assertField(ids%code%name, getString(), "controllers/code/name");

		!!!  version:code/version:STR_0D:constant:
			 call assertField(ids%code%version, getString(), "controllers/code/version");

		!!!  parameters:code/parameters:STR_0D:constant:
			 call assertField(ids%code%parameters, getString(), "controllers/code/parameters");

		!!!  output_flag:code/output_flag:INT_1D:dynamic:
			 call assertField(ids%code%output_flag, getInteger1DArray(), "controllers/code/output_flag");
	end do 
	
END SUBROUTINE controllers_get

!==================================================================
!		 GET core_profiles 
!==================================================================
SUBROUTINE core_profiles_get
	CHARACTER (LEN = *), parameter :: idsName = "core_profiles"
	TYPE (ids_core_profiles) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on core_profiles"
	CALL srand(seed)
	do i = 0, 6 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "core_profiles/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "core_profiles/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "core_profiles/ids_properties/cocos");

		!!!  profiles_1d:profiles_1d:struct_array:dynamic:
		if(.not. associated(ids%profiles_1d)) then 
			write(*,*) "ERROR! IDS: core_profiles Field: profiles_1d is not associated!"
 			else 

		!!!  t_e:profiles_1d/t_e:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%t_e, getDouble1DArray(), "core_profiles/profiles_1d/t_e");

		!!!  t_i_average:profiles_1d/t_i_average:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%t_i_average, getDouble1DArray(), "core_profiles/profiles_1d/t_i_average");

		!!!  n_e:profiles_1d/n_e:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%n_e, getDouble1DArray(), "core_profiles/profiles_1d/n_e");

		!!!  n_e_fast:profiles_1d/n_e_fast:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%n_e_fast, getDouble1DArray(), "core_profiles/profiles_1d/n_e_fast");

		!!!  n_i_total_over_n_e:profiles_1d/n_i_total_over_n_e:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%n_i_total_over_n_e, getDouble1DArray(), "core_profiles/profiles_1d/n_i_total_over_n_e");

		!!!  momentum_tor:profiles_1d/momentum_tor:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%momentum_tor, getDouble1DArray(), "core_profiles/profiles_1d/momentum_tor");

		!!!  zeff:profiles_1d/zeff:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%zeff, getDouble1DArray(), "core_profiles/profiles_1d/zeff");

		!!!  p_e:profiles_1d/p_e:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%p_e, getDouble1DArray(), "core_profiles/profiles_1d/p_e");

		!!!  p_e_fast_perpendicular:profiles_1d/p_e_fast_perpendicular:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%p_e_fast_perpendicular, getDouble1DArray(), "core_profiles/profiles_1d/p_e_fast_perpendicular");

		!!!  p_e_fast_parallel:profiles_1d/p_e_fast_parallel:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%p_e_fast_parallel, getDouble1DArray(), "core_profiles/profiles_1d/p_e_fast_parallel");

		!!!  p_i_total:profiles_1d/p_i_total:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%p_i_total, getDouble1DArray(), "core_profiles/profiles_1d/p_i_total");

		!!!  p_i_total_fast_perpendicular:profiles_1d/p_i_total_fast_perpendicular:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%p_i_total_fast_perpendicular, getDouble1DArray(), "core_profiles/profiles_1d/p_i_total_fast_perpendicular");

		!!!  p_i_total_fast_parallel:profiles_1d/p_i_total_fast_parallel:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%p_i_total_fast_parallel, getDouble1DArray(), "core_profiles/profiles_1d/p_i_total_fast_parallel");

		!!!  pressure_thermal:profiles_1d/pressure_thermal:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%pressure_thermal, getDouble1DArray(), "core_profiles/profiles_1d/pressure_thermal");

		!!!  pressure_perpendicular:profiles_1d/pressure_perpendicular:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%pressure_perpendicular, getDouble1DArray(), "core_profiles/profiles_1d/pressure_perpendicular");

		!!!  pressure_parallel:profiles_1d/pressure_parallel:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%pressure_parallel, getDouble1DArray(), "core_profiles/profiles_1d/pressure_parallel");

		!!!  j_total:profiles_1d/j_total:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%j_total, getDouble1DArray(), "core_profiles/profiles_1d/j_total");

		!!!  j_tor:profiles_1d/j_tor:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%j_tor, getDouble1DArray(), "core_profiles/profiles_1d/j_tor");

		!!!  j_ohmic:profiles_1d/j_ohmic:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%j_ohmic, getDouble1DArray(), "core_profiles/profiles_1d/j_ohmic");

		!!!  j_non_inductive:profiles_1d/j_non_inductive:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%j_non_inductive, getDouble1DArray(), "core_profiles/profiles_1d/j_non_inductive");

		!!!  j_bootstrap:profiles_1d/j_bootstrap:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%j_bootstrap, getDouble1DArray(), "core_profiles/profiles_1d/j_bootstrap");

		!!!  conductivity_parallel:profiles_1d/conductivity_parallel:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%conductivity_parallel, getDouble1DArray(), "core_profiles/profiles_1d/conductivity_parallel");

		!!!  e_field_parallel:profiles_1d/e_field_parallel:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%e_field_parallel, getDouble1DArray(), "core_profiles/profiles_1d/e_field_parallel");

		!!!  q:profiles_1d/q:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%q, getDouble1DArray(), "core_profiles/profiles_1d/q");

		!!!  magnetic_shear:profiles_1d/magnetic_shear:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%magnetic_shear, getDouble1DArray(), "core_profiles/profiles_1d/magnetic_shear");

		!!!  time:profiles_1d/time:flt_type:dynamic:
			call assertField(ids%profiles_1d(1)%time, getDouble(), "core_profiles/profiles_1d/time");

		!!!  grid:profiles_1d/grid:structure::

		!!!  rho_tor_norm:profiles_1d/grid/rho_tor_norm:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%grid%rho_tor_norm, getDouble1DArray(), "core_profiles/profiles_1d/grid/rho_tor_norm");

		!!!  rho_tor:profiles_1d/grid/rho_tor:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%grid%rho_tor, getDouble1DArray(), "core_profiles/profiles_1d/grid/rho_tor");

		!!!  psi:profiles_1d/grid/psi:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%grid%psi, getDouble1DArray(), "core_profiles/profiles_1d/grid/psi");

		!!!  volume:profiles_1d/grid/volume:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%grid%volume, getDouble1DArray(), "core_profiles/profiles_1d/grid/volume");

		!!!  area:profiles_1d/grid/area:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%grid%area, getDouble1DArray(), "core_profiles/profiles_1d/grid/area");

		!!!  ion:profiles_1d/ion:struct_array::
		if(.not. associated(ids%profiles_1d(1)%ion)) then 
			write(*,*) "ERROR! IDS: core_profiles Field: profiles_1d(1)%ion(1) is not associated!"
 			else 

		!!!  a:profiles_1d/ion/a:FLT_0D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%a, getDouble(), "core_profiles/profiles_1d/ion/a");

		!!!  z_ion:profiles_1d/ion/z_ion:FLT_0D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%z_ion, getDouble(), "core_profiles/profiles_1d/ion/z_ion");

		!!!  z_n:profiles_1d/ion/z_n:FLT_0D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%z_n, getDouble(), "core_profiles/profiles_1d/ion/z_n");

		!!!  label:profiles_1d/ion/label:STR_0D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%label, getString(), "core_profiles/profiles_1d/ion/label");

		!!!  n_i:profiles_1d/ion/n_i:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%n_i, getDouble1DArray(), "core_profiles/profiles_1d/ion/n_i");

		!!!  n_i_fast:profiles_1d/ion/n_i_fast:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%n_i_fast, getDouble1DArray(), "core_profiles/profiles_1d/ion/n_i_fast");

		!!!  t_i:profiles_1d/ion/t_i:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%t_i, getDouble1DArray(), "core_profiles/profiles_1d/ion/t_i");

		!!!  p_i:profiles_1d/ion/p_i:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%p_i, getDouble1DArray(), "core_profiles/profiles_1d/ion/p_i");

		!!!  p_i_fast_perpendicular:profiles_1d/ion/p_i_fast_perpendicular:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%p_i_fast_perpendicular, getDouble1DArray(), "core_profiles/profiles_1d/ion/p_i_fast_perpendicular");

		!!!  p_i_fast_parallel:profiles_1d/ion/p_i_fast_parallel:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%p_i_fast_parallel, getDouble1DArray(), "core_profiles/profiles_1d/ion/p_i_fast_parallel");

		!!!  v_tor_i:profiles_1d/ion/v_tor_i:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%v_tor_i, getDouble1DArray(), "core_profiles/profiles_1d/ion/v_tor_i");

		!!!  v_pol_i:profiles_1d/ion/v_pol_i:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%v_pol_i, getDouble1DArray(), "core_profiles/profiles_1d/ion/v_pol_i");

		!!!  multiple_charge_states_flag:profiles_1d/ion/multiple_charge_states_flag:INT_0D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%multiple_charge_states_flag, getInteger(), "core_profiles/profiles_1d/ion/multiple_charge_states_flag");

		!!!  charge_state:profiles_1d/ion/charge_state:struct_array::
		if(.not. associated(ids%profiles_1d(1)%ion(1)%charge_state)) then 
			write(*,*) "ERROR! IDS: core_profiles Field: profiles_1d(1)%ion(1)%charge_state(1) is not associated!"
 			else 

		!!!  z_min:profiles_1d/ion/charge_state/z_min:FLT_0D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%charge_state(1)%z_min, getDouble(), "core_profiles/profiles_1d/ion/charge_state/z_min");

		!!!  z_max:profiles_1d/ion/charge_state/z_max:FLT_0D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%charge_state(1)%z_max, getDouble(), "core_profiles/profiles_1d/ion/charge_state/z_max");

		!!!  label:profiles_1d/ion/charge_state/label:STR_0D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%charge_state(1)%label, getString(), "core_profiles/profiles_1d/ion/charge_state/label");

		!!!  n_z:profiles_1d/ion/charge_state/n_z:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%charge_state(1)%n_z, getDouble1DArray(), "core_profiles/profiles_1d/ion/charge_state/n_z");

		!!!  n_z_fast:profiles_1d/ion/charge_state/n_z_fast:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%charge_state(1)%n_z_fast, getDouble1DArray(), "core_profiles/profiles_1d/ion/charge_state/n_z_fast");

		!!!  t_z:profiles_1d/ion/charge_state/t_z:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%charge_state(1)%t_z, getDouble1DArray(), "core_profiles/profiles_1d/ion/charge_state/t_z");

		!!!  p_z:profiles_1d/ion/charge_state/p_z:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%charge_state(1)%p_z, getDouble1DArray(), "core_profiles/profiles_1d/ion/charge_state/p_z");

		!!!  p_z_fast_perpendicular:profiles_1d/ion/charge_state/p_z_fast_perpendicular:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%charge_state(1)%p_z_fast_perpendicular, getDouble1DArray(), "core_profiles/profiles_1d/ion/charge_state/p_z_fast_perpendicular");

		!!!  p_z_fast_parallel:profiles_1d/ion/charge_state/p_z_fast_parallel:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%charge_state(1)%p_z_fast_parallel, getDouble1DArray(), "core_profiles/profiles_1d/ion/charge_state/p_z_fast_parallel");

		!!!  v_tor_z:profiles_1d/ion/charge_state/v_tor_z:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%charge_state(1)%v_tor_z, getDouble1DArray(), "core_profiles/profiles_1d/ion/charge_state/v_tor_z");

		!!!  v_pol_z:profiles_1d/ion/charge_state/v_pol_z:FLT_1D:dynamic:
			call assertField(ids%profiles_1d(1)%ion(1)%charge_state(1)%v_pol_z, getDouble1DArray(), "core_profiles/profiles_1d/ion/charge_state/v_pol_z");
		end if 
		end if 
		end if 

		!!!  ip:global_quantities/ip:FLT_1D:dynamic:
			 call assertField(ids%global_quantities%ip, getDouble1DArray(), "core_profiles/global_quantities/ip");

		!!!  current_non_inductive:global_quantities/current_non_inductive:FLT_1D:dynamic:
			 call assertField(ids%global_quantities%current_non_inductive, getDouble1DArray(), "core_profiles/global_quantities/current_non_inductive");

		!!!  current_bootstrap:global_quantities/current_bootstrap:FLT_1D:dynamic:
			 call assertField(ids%global_quantities%current_bootstrap, getDouble1DArray(), "core_profiles/global_quantities/current_bootstrap");

		!!!  v_loop:global_quantities/v_loop:FLT_1D:dynamic:
			 call assertField(ids%global_quantities%v_loop, getDouble1DArray(), "core_profiles/global_quantities/v_loop");

		!!!  li:global_quantities/li:FLT_1D:dynamic:
			 call assertField(ids%global_quantities%li, getDouble1DArray(), "core_profiles/global_quantities/li");

		!!!  beta_tor:global_quantities/beta_tor:FLT_1D:dynamic:
			 call assertField(ids%global_quantities%beta_tor, getDouble1DArray(), "core_profiles/global_quantities/beta_tor");

		!!!  beta_tor_norm:global_quantities/beta_tor_norm:FLT_1D:dynamic:
			 call assertField(ids%global_quantities%beta_tor_norm, getDouble1DArray(), "core_profiles/global_quantities/beta_tor_norm");

		!!!  beta_pol:global_quantities/beta_pol:FLT_1D:dynamic:
			 call assertField(ids%global_quantities%beta_pol, getDouble1DArray(), "core_profiles/global_quantities/beta_pol");

		!!!  energy_diamagnetic:global_quantities/energy_diamagnetic:FLT_1D:dynamic:
			 call assertField(ids%global_quantities%energy_diamagnetic, getDouble1DArray(), "core_profiles/global_quantities/energy_diamagnetic");

		!!!  r0:vacuum_toroidal_field/r0:FLT_0D:constant:
			 call assertField(ids%vacuum_toroidal_field%r0, getDouble(), "core_profiles/vacuum_toroidal_field/r0");

		!!!  b0:vacuum_toroidal_field/b0:FLT_1D:dynamic:
			 call assertField(ids%vacuum_toroidal_field%b0, getDouble1DArray(), "core_profiles/vacuum_toroidal_field/b0");

		!!!  name:code/name:STR_0D:constant:
			 call assertField(ids%code%name, getString(), "core_profiles/code/name");

		!!!  version:code/version:STR_0D:constant:
			 call assertField(ids%code%version, getString(), "core_profiles/code/version");

		!!!  parameters:code/parameters:STR_0D:constant:
			 call assertField(ids%code%parameters, getString(), "core_profiles/code/parameters");

		!!!  output_flag:code/output_flag:INT_1D:dynamic:
			 call assertField(ids%code%output_flag, getInteger1DArray(), "core_profiles/code/output_flag");

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "core_profiles/time");
	end do 
	
END SUBROUTINE core_profiles_get

!==================================================================
!		 GET core_sources 
!==================================================================
SUBROUTINE core_sources_get
	CHARACTER (LEN = *), parameter :: idsName = "core_sources"
	TYPE (ids_core_sources) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on core_sources"
	CALL srand(seed)
	do i = 0, 6 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "core_sources/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "core_sources/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "core_sources/ids_properties/cocos");

		!!!  r0:vacuum_toroidal_field/r0:FLT_0D:constant:
			 call assertField(ids%vacuum_toroidal_field%r0, getDouble(), "core_sources/vacuum_toroidal_field/r0");

		!!!  b0:vacuum_toroidal_field/b0:FLT_1D:dynamic:
			 call assertField(ids%vacuum_toroidal_field%b0, getDouble1DArray(), "core_sources/vacuum_toroidal_field/b0");

		!!!  source:source:struct_array::
		if(.not. associated(ids%source)) then 
			write(*,*) "ERROR! IDS: core_sources Field: source is not associated!"
 			else 

		!!!  name:source/name:STR_0D:constant:
			call assertField(ids%source(1)%name, getString(), "core_sources/source/name");

		!!!  profiles:source/profiles:struct_array:dynamic:
		if(.not. associated(ids%source(1)%profiles)) then 
			write(*,*) "ERROR! IDS: core_sources Field: source(1)%profiles(1) is not associated!"
 			else 

		!!!  n_e_source:source/profiles/n_e_source:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%n_e_source, getDouble1DArray(), "core_sources/source/profiles/n_e_source");

		!!!  t_e_source:source/profiles/t_e_source:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%t_e_source, getDouble1DArray(), "core_sources/source/profiles/t_e_source");

		!!!  t_i_average_source:source/profiles/t_i_average_source:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%t_i_average_source, getDouble1DArray(), "core_sources/source/profiles/t_i_average_source");

		!!!  momentum_tor_source:source/profiles/momentum_tor_source:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%momentum_tor_source, getDouble1DArray(), "core_sources/source/profiles/momentum_tor_source");

		!!!  conductivity_parallel:source/profiles/conductivity_parallel:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%conductivity_parallel, getDouble1DArray(), "core_sources/source/profiles/conductivity_parallel");

		!!!  time:source/profiles/time:flt_type:dynamic:
			call assertField(ids%source(1)%profiles(1)%time, getDouble(), "core_sources/source/profiles/time");

		!!!  grid:source/profiles/grid:structure::

		!!!  rho_tor_norm:source/profiles/grid/rho_tor_norm:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%grid%rho_tor_norm, getDouble1DArray(), "core_sources/source/profiles/grid/rho_tor_norm");

		!!!  rho_tor:source/profiles/grid/rho_tor:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%grid%rho_tor, getDouble1DArray(), "core_sources/source/profiles/grid/rho_tor");

		!!!  psi:source/profiles/grid/psi:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%grid%psi, getDouble1DArray(), "core_sources/source/profiles/grid/psi");

		!!!  volume:source/profiles/grid/volume:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%grid%volume, getDouble1DArray(), "core_sources/source/profiles/grid/volume");

		!!!  area:source/profiles/grid/area:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%grid%area, getDouble1DArray(), "core_sources/source/profiles/grid/area");

		!!!  ion:source/profiles/ion:struct_array::
		if(.not. associated(ids%source(1)%profiles(1)%ion)) then 
			write(*,*) "ERROR! IDS: core_sources Field: source(1)%profiles(1)%ion(1) is not associated!"
 			else 

		!!!  a:source/profiles/ion/a:FLT_0D:constant:
			call assertField(ids%source(1)%profiles(1)%ion(1)%a, getDouble(), "core_sources/source/profiles/ion/a");

		!!!  z_ion:source/profiles/ion/z_ion:FLT_0D:constant:
			call assertField(ids%source(1)%profiles(1)%ion(1)%z_ion, getDouble(), "core_sources/source/profiles/ion/z_ion");

		!!!  z_n:source/profiles/ion/z_n:FLT_0D:constant:
			call assertField(ids%source(1)%profiles(1)%ion(1)%z_n, getDouble(), "core_sources/source/profiles/ion/z_n");

		!!!  label:source/profiles/ion/label:STR_0D:constant:
			call assertField(ids%source(1)%profiles(1)%ion(1)%label, getString(), "core_sources/source/profiles/ion/label");

		!!!  n_i_source:source/profiles/ion/n_i_source:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%ion(1)%n_i_source, getDouble1DArray(), "core_sources/source/profiles/ion/n_i_source");

		!!!  t_i_source:source/profiles/ion/t_i_source:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%ion(1)%t_i_source, getDouble1DArray(), "core_sources/source/profiles/ion/t_i_source");

		!!!  multiple_charge_states_flag:source/profiles/ion/multiple_charge_states_flag:INT_0D:constant:
			call assertField(ids%source(1)%profiles(1)%ion(1)%multiple_charge_states_flag, getInteger(), "core_sources/source/profiles/ion/multiple_charge_states_flag");

		!!!  charge_state:source/profiles/ion/charge_state:struct_array::
		if(.not. associated(ids%source(1)%profiles(1)%ion(1)%charge_state)) then 
			write(*,*) "ERROR! IDS: core_sources Field: source(1)%profiles(1)%ion(1)%charge_state(1) is not associated!"
 			else 

		!!!  z_min:source/profiles/ion/charge_state/z_min:FLT_0D:constant:
			call assertField(ids%source(1)%profiles(1)%ion(1)%charge_state(1)%z_min, getDouble(), "core_sources/source/profiles/ion/charge_state/z_min");

		!!!  z_max:source/profiles/ion/charge_state/z_max:FLT_0D:constant:
			call assertField(ids%source(1)%profiles(1)%ion(1)%charge_state(1)%z_max, getDouble(), "core_sources/source/profiles/ion/charge_state/z_max");

		!!!  label:source/profiles/ion/charge_state/label:STR_0D:constant:
			call assertField(ids%source(1)%profiles(1)%ion(1)%charge_state(1)%label, getString(), "core_sources/source/profiles/ion/charge_state/label");

		!!!  n_z_source:source/profiles/ion/charge_state/n_z_source:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%ion(1)%charge_state(1)%n_z_source, getDouble1DArray(), "core_sources/source/profiles/ion/charge_state/n_z_source");

		!!!  t_z_source:source/profiles/ion/charge_state/t_z_source:FLT_1D:dynamic:
			call assertField(ids%source(1)%profiles(1)%ion(1)%charge_state(1)%t_z_source, getDouble1DArray(), "core_sources/source/profiles/ion/charge_state/t_z_source");
		end if 
		end if 
		end if 
		end if 

		!!!  name:code/name:STR_0D:constant:
			 call assertField(ids%code%name, getString(), "core_sources/code/name");

		!!!  version:code/version:STR_0D:constant:
			 call assertField(ids%code%version, getString(), "core_sources/code/version");

		!!!  parameters:code/parameters:STR_0D:constant:
			 call assertField(ids%code%parameters, getString(), "core_sources/code/parameters");

		!!!  output_flag:code/output_flag:INT_1D:dynamic:
			 call assertField(ids%code%output_flag, getInteger1DArray(), "core_sources/code/output_flag");

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "core_sources/time");
	end do 
	
END SUBROUTINE core_sources_get

!==================================================================
!		 GET core_transport 
!==================================================================
SUBROUTINE core_transport_get
	CHARACTER (LEN = *), parameter :: idsName = "core_transport"
	TYPE (ids_core_transport) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on core_transport"
	CALL srand(seed)
	do i = 0, 6 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "core_transport/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "core_transport/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "core_transport/ids_properties/cocos");

		!!!  r0:vacuum_toroidal_field/r0:FLT_0D:constant:
			 call assertField(ids%vacuum_toroidal_field%r0, getDouble(), "core_transport/vacuum_toroidal_field/r0");

		!!!  b0:vacuum_toroidal_field/b0:FLT_1D:dynamic:
			 call assertField(ids%vacuum_toroidal_field%b0, getDouble1DArray(), "core_transport/vacuum_toroidal_field/b0");

		!!!  model:model:struct_array::
		if(.not. associated(ids%model)) then 
			write(*,*) "ERROR! IDS: core_transport Field: model is not associated!"
 			else 

		!!!  name:model/name:STR_0D:constant:
			call assertField(ids%model(1)%name, getString(), "core_transport/model/name");

		!!!  flux_multiplier:model/flux_multiplier:FLT_0D:constant:
			call assertField(ids%model(1)%flux_multiplier, getDouble(), "core_transport/model/flux_multiplier");

		!!!  profiles:model/profiles:struct_array:dynamic:
		if(.not. associated(ids%model(1)%profiles)) then 
			write(*,*) "ERROR! IDS: core_transport Field: model(1)%profiles(1) is not associated!"
 			else 

		!!!  conductivity_parallel:model/profiles/conductivity_parallel:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%conductivity_parallel, getDouble1DArray(), "core_transport/model/profiles/conductivity_parallel");

		!!!  time:model/profiles/time:flt_type:dynamic:
			call assertField(ids%model(1)%profiles(1)%time, getDouble(), "core_transport/model/profiles/time");

		!!!  grid_d:model/profiles/grid_d:structure::

		!!!  rho_tor_norm:model/profiles/grid_d/rho_tor_norm:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_d%rho_tor_norm, getDouble1DArray(), "core_transport/model/profiles/grid_d/rho_tor_norm");

		!!!  rho_tor:model/profiles/grid_d/rho_tor:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_d%rho_tor, getDouble1DArray(), "core_transport/model/profiles/grid_d/rho_tor");

		!!!  psi:model/profiles/grid_d/psi:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_d%psi, getDouble1DArray(), "core_transport/model/profiles/grid_d/psi");

		!!!  volume:model/profiles/grid_d/volume:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_d%volume, getDouble1DArray(), "core_transport/model/profiles/grid_d/volume");

		!!!  area:model/profiles/grid_d/area:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_d%area, getDouble1DArray(), "core_transport/model/profiles/grid_d/area");

		!!!  grid_v:model/profiles/grid_v:structure::

		!!!  rho_tor_norm:model/profiles/grid_v/rho_tor_norm:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_v%rho_tor_norm, getDouble1DArray(), "core_transport/model/profiles/grid_v/rho_tor_norm");

		!!!  rho_tor:model/profiles/grid_v/rho_tor:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_v%rho_tor, getDouble1DArray(), "core_transport/model/profiles/grid_v/rho_tor");

		!!!  psi:model/profiles/grid_v/psi:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_v%psi, getDouble1DArray(), "core_transport/model/profiles/grid_v/psi");

		!!!  volume:model/profiles/grid_v/volume:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_v%volume, getDouble1DArray(), "core_transport/model/profiles/grid_v/volume");

		!!!  area:model/profiles/grid_v/area:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_v%area, getDouble1DArray(), "core_transport/model/profiles/grid_v/area");

		!!!  grid_flux:model/profiles/grid_flux:structure::

		!!!  rho_tor_norm:model/profiles/grid_flux/rho_tor_norm:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_flux%rho_tor_norm, getDouble1DArray(), "core_transport/model/profiles/grid_flux/rho_tor_norm");

		!!!  rho_tor:model/profiles/grid_flux/rho_tor:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_flux%rho_tor, getDouble1DArray(), "core_transport/model/profiles/grid_flux/rho_tor");

		!!!  psi:model/profiles/grid_flux/psi:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_flux%psi, getDouble1DArray(), "core_transport/model/profiles/grid_flux/psi");

		!!!  volume:model/profiles/grid_flux/volume:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_flux%volume, getDouble1DArray(), "core_transport/model/profiles/grid_flux/volume");

		!!!  area:model/profiles/grid_flux/area:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%grid_flux%area, getDouble1DArray(), "core_transport/model/profiles/grid_flux/area");

		!!!  n_e_transport:model/profiles/n_e_transport:structure::

		!!!  d:model/profiles/n_e_transport/d:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%n_e_transport%d, getDouble1DArray(), "core_transport/model/profiles/n_e_transport/d");

		!!!  v:model/profiles/n_e_transport/v:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%n_e_transport%v, getDouble1DArray(), "core_transport/model/profiles/n_e_transport/v");

		!!!  flux:model/profiles/n_e_transport/flux:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%n_e_transport%flux, getDouble1DArray(), "core_transport/model/profiles/n_e_transport/flux");

		!!!  t_e_transport:model/profiles/t_e_transport:structure::

		!!!  d:model/profiles/t_e_transport/d:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%t_e_transport%d, getDouble1DArray(), "core_transport/model/profiles/t_e_transport/d");

		!!!  v:model/profiles/t_e_transport/v:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%t_e_transport%v, getDouble1DArray(), "core_transport/model/profiles/t_e_transport/v");

		!!!  flux:model/profiles/t_e_transport/flux:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%t_e_transport%flux, getDouble1DArray(), "core_transport/model/profiles/t_e_transport/flux");

		!!!  t_i_average_transport:model/profiles/t_i_average_transport:structure::

		!!!  d:model/profiles/t_i_average_transport/d:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%t_i_average_transport%d, getDouble1DArray(), "core_transport/model/profiles/t_i_average_transport/d");

		!!!  v:model/profiles/t_i_average_transport/v:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%t_i_average_transport%v, getDouble1DArray(), "core_transport/model/profiles/t_i_average_transport/v");

		!!!  flux:model/profiles/t_i_average_transport/flux:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%t_i_average_transport%flux, getDouble1DArray(), "core_transport/model/profiles/t_i_average_transport/flux");

		!!!  momentum_tor_transport:model/profiles/momentum_tor_transport:structure::

		!!!  d:model/profiles/momentum_tor_transport/d:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%momentum_tor_transport%d, getDouble1DArray(), "core_transport/model/profiles/momentum_tor_transport/d");

		!!!  v:model/profiles/momentum_tor_transport/v:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%momentum_tor_transport%v, getDouble1DArray(), "core_transport/model/profiles/momentum_tor_transport/v");

		!!!  flux:model/profiles/momentum_tor_transport/flux:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%momentum_tor_transport%flux, getDouble1DArray(), "core_transport/model/profiles/momentum_tor_transport/flux");

		!!!  ion:model/profiles/ion:struct_array::
		if(.not. associated(ids%model(1)%profiles(1)%ion)) then 
			write(*,*) "ERROR! IDS: core_transport Field: model(1)%profiles(1)%ion(1) is not associated!"
 			else 

		!!!  a:model/profiles/ion/a:FLT_0D:constant:
			call assertField(ids%model(1)%profiles(1)%ion(1)%a, getDouble(), "core_transport/model/profiles/ion/a");

		!!!  z_ion:model/profiles/ion/z_ion:FLT_0D:constant:
			call assertField(ids%model(1)%profiles(1)%ion(1)%z_ion, getDouble(), "core_transport/model/profiles/ion/z_ion");

		!!!  z_n:model/profiles/ion/z_n:FLT_0D:constant:
			call assertField(ids%model(1)%profiles(1)%ion(1)%z_n, getDouble(), "core_transport/model/profiles/ion/z_n");

		!!!  label:model/profiles/ion/label:STR_0D:constant:
			call assertField(ids%model(1)%profiles(1)%ion(1)%label, getString(), "core_transport/model/profiles/ion/label");

		!!!  multiple_charge_states_flag:model/profiles/ion/multiple_charge_states_flag:INT_0D:constant:
			call assertField(ids%model(1)%profiles(1)%ion(1)%multiple_charge_states_flag, getInteger(), "core_transport/model/profiles/ion/multiple_charge_states_flag");

		!!!  n_i_transport:model/profiles/ion/n_i_transport:structure::

		!!!  d:model/profiles/ion/n_i_transport/d:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%ion(1)%n_i_transport%d, getDouble1DArray(), "core_transport/model/profiles/ion/n_i_transport/d");

		!!!  v:model/profiles/ion/n_i_transport/v:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%ion(1)%n_i_transport%v, getDouble1DArray(), "core_transport/model/profiles/ion/n_i_transport/v");

		!!!  flux:model/profiles/ion/n_i_transport/flux:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%ion(1)%n_i_transport%flux, getDouble1DArray(), "core_transport/model/profiles/ion/n_i_transport/flux");

		!!!  t_i_transport:model/profiles/ion/t_i_transport:structure::

		!!!  d:model/profiles/ion/t_i_transport/d:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%ion(1)%t_i_transport%d, getDouble1DArray(), "core_transport/model/profiles/ion/t_i_transport/d");

		!!!  v:model/profiles/ion/t_i_transport/v:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%ion(1)%t_i_transport%v, getDouble1DArray(), "core_transport/model/profiles/ion/t_i_transport/v");

		!!!  flux:model/profiles/ion/t_i_transport/flux:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%ion(1)%t_i_transport%flux, getDouble1DArray(), "core_transport/model/profiles/ion/t_i_transport/flux");

		!!!  charge_state:model/profiles/ion/charge_state:struct_array::
		if(.not. associated(ids%model(1)%profiles(1)%ion(1)%charge_state)) then 
			write(*,*) "ERROR! IDS: core_transport Field: model(1)%profiles(1)%ion(1)%charge_state(1) is not associated!"
 			else 

		!!!  z_min:model/profiles/ion/charge_state/z_min:FLT_0D:constant:
			call assertField(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%z_min, getDouble(), "core_transport/model/profiles/ion/charge_state/z_min");

		!!!  z_max:model/profiles/ion/charge_state/z_max:FLT_0D:constant:
			call assertField(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%z_max, getDouble(), "core_transport/model/profiles/ion/charge_state/z_max");

		!!!  label:model/profiles/ion/charge_state/label:STR_0D:constant:
			call assertField(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%label, getString(), "core_transport/model/profiles/ion/charge_state/label");

		!!!  n_z_transport:model/profiles/ion/charge_state/n_z_transport:structure::

		!!!  d:model/profiles/ion/charge_state/n_z_transport/d:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%n_z_transport%d, getDouble1DArray(), "core_transport/model/profiles/ion/charge_state/n_z_transport/d");

		!!!  v:model/profiles/ion/charge_state/n_z_transport/v:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%n_z_transport%v, getDouble1DArray(), "core_transport/model/profiles/ion/charge_state/n_z_transport/v");

		!!!  flux:model/profiles/ion/charge_state/n_z_transport/flux:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%n_z_transport%flux, getDouble1DArray(), "core_transport/model/profiles/ion/charge_state/n_z_transport/flux");

		!!!  t_z_transport:model/profiles/ion/charge_state/t_z_transport:structure::

		!!!  d:model/profiles/ion/charge_state/t_z_transport/d:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%t_z_transport%d, getDouble1DArray(), "core_transport/model/profiles/ion/charge_state/t_z_transport/d");

		!!!  v:model/profiles/ion/charge_state/t_z_transport/v:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%t_z_transport%v, getDouble1DArray(), "core_transport/model/profiles/ion/charge_state/t_z_transport/v");

		!!!  flux:model/profiles/ion/charge_state/t_z_transport/flux:FLT_1D:dynamic:
			call assertField(ids%model(1)%profiles(1)%ion(1)%charge_state(1)%t_z_transport%flux, getDouble1DArray(), "core_transport/model/profiles/ion/charge_state/t_z_transport/flux");
		end if 
		end if 
		end if 
		end if 

		!!!  name:code/name:STR_0D:constant:
			 call assertField(ids%code%name, getString(), "core_transport/code/name");

		!!!  version:code/version:STR_0D:constant:
			 call assertField(ids%code%version, getString(), "core_transport/code/version");

		!!!  parameters:code/parameters:STR_0D:constant:
			 call assertField(ids%code%parameters, getString(), "core_transport/code/parameters");

		!!!  output_flag:code/output_flag:INT_1D:dynamic:
			 call assertField(ids%code%output_flag, getInteger1DArray(), "core_transport/code/output_flag");

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "core_transport/time");
	end do 
	
END SUBROUTINE core_transport_get

!==================================================================
!		 GET em_coupling 
!==================================================================
SUBROUTINE em_coupling_get
	CHARACTER (LEN = *), parameter :: idsName = "em_coupling"
	TYPE (ids_em_coupling) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on em_coupling"
	CALL srand(seed)
	do i = 0, 6 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "em_coupling/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "em_coupling/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "em_coupling/ids_properties/cocos");

		!!!  mutual_active_active:mutual_active_active:FLT_2D:static:
			 call assertField(ids%mutual_active_active, getDouble2DArray(), "em_coupling/mutual_active_active");

		!!!  mutual_passive_active:mutual_passive_active:FLT_2D:static:
			 call assertField(ids%mutual_passive_active, getDouble2DArray(), "em_coupling/mutual_passive_active");

		!!!  mutual_loops_active:mutual_loops_active:FLT_2D:static:
			 call assertField(ids%mutual_loops_active, getDouble2DArray(), "em_coupling/mutual_loops_active");

		!!!  field_probes_active:field_probes_active:FLT_2D:static:
			 call assertField(ids%field_probes_active, getDouble2DArray(), "em_coupling/field_probes_active");

		!!!  mutual_passive_passive:mutual_passive_passive:FLT_2D:static:
			 call assertField(ids%mutual_passive_passive, getDouble2DArray(), "em_coupling/mutual_passive_passive");

		!!!  mutual_loops_passive:mutual_loops_passive:FLT_2D:static:
			 call assertField(ids%mutual_loops_passive, getDouble2DArray(), "em_coupling/mutual_loops_passive");

		!!!  field_probes_passive:field_probes_passive:FLT_2D:static:
			 call assertField(ids%field_probes_passive, getDouble2DArray(), "em_coupling/field_probes_passive");

		!!!  mutual_grid_grid:mutual_grid_grid:FLT_2D:static:
			 call assertField(ids%mutual_grid_grid, getDouble2DArray(), "em_coupling/mutual_grid_grid");

		!!!  mutual_grid_active:mutual_grid_active:FLT_2D:static:
			 call assertField(ids%mutual_grid_active, getDouble2DArray(), "em_coupling/mutual_grid_active");

		!!!  mutual_grid_passive:mutual_grid_passive:FLT_2D:static:
			 call assertField(ids%mutual_grid_passive, getDouble2DArray(), "em_coupling/mutual_grid_passive");

		!!!  field_probes_grid:field_probes_grid:FLT_2D:static:
			 call assertField(ids%field_probes_grid, getDouble2DArray(), "em_coupling/field_probes_grid");

		!!!  mutual_loops_grid:mutual_loops_grid:FLT_2D:static:
			 call assertField(ids%mutual_loops_grid, getDouble2DArray(), "em_coupling/mutual_loops_grid");

		!!!  active_coils:active_coils:STR_1D:static:
			 call assertField(ids%active_coils,  getString(), "em_coupling/active_coils");

		!!!  passive_loops:passive_loops:STR_1D:static:
			 call assertField(ids%passive_loops,  getString(), "em_coupling/passive_loops");

		!!!  poloidal_probes:poloidal_probes:STR_1D:static:
			 call assertField(ids%poloidal_probes,  getString(), "em_coupling/poloidal_probes");

		!!!  flux_loops:flux_loops:STR_1D:static:
			 call assertField(ids%flux_loops,  getString(), "em_coupling/flux_loops");

		!!!  grid_points:grid_points:STR_1D:constant:
			 call assertField(ids%grid_points,  getString(), "em_coupling/grid_points");

		!!!  name:code/name:STR_0D:constant:
			 call assertField(ids%code%name, getString(), "em_coupling/code/name");

		!!!  version:code/version:STR_0D:constant:
			 call assertField(ids%code%version, getString(), "em_coupling/code/version");

		!!!  parameters:code/parameters:STR_0D:constant:
			 call assertField(ids%code%parameters, getString(), "em_coupling/code/parameters");

		!!!  output_flag:code/output_flag:INT_1D:dynamic:
			 call assertField(ids%code%output_flag, getInteger1DArray(), "em_coupling/code/output_flag");

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "em_coupling/time");
	end do 
	
END SUBROUTINE em_coupling_get

!==================================================================
!		 GET equilibrium 
!==================================================================
SUBROUTINE equilibrium_get
	CHARACTER (LEN = *), parameter :: idsName = "equilibrium"
	TYPE (ids_equilibrium) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on equilibrium"
	CALL srand(seed)
	do i = 0, 6 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "equilibrium/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "equilibrium/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "equilibrium/ids_properties/cocos");

		!!!  r0:vacuum_toroidal_field/r0:FLT_0D:constant:
			 call assertField(ids%vacuum_toroidal_field%r0, getDouble(), "equilibrium/vacuum_toroidal_field/r0");

		!!!  b0:vacuum_toroidal_field/b0:FLT_1D:dynamic:
			 call assertField(ids%vacuum_toroidal_field%b0, getDouble1DArray(), "equilibrium/vacuum_toroidal_field/b0");

		!!!  time_slice:time_slice:struct_array:dynamic:
		if(.not. associated(ids%time_slice)) then 
			write(*,*) "ERROR! IDS: equilibrium Field: time_slice is not associated!"
 			else 

		!!!  time:time_slice/time:flt_type:dynamic:
			call assertField(ids%time_slice(1)%time, getDouble(), "equilibrium/time_slice/time");

		!!!  boundary:time_slice/boundary:structure::

		!!!  type:time_slice/boundary/type:INT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%type, getInteger(), "equilibrium/time_slice/boundary/type");

		!!!  a_minor:time_slice/boundary/a_minor:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%a_minor, getDouble(), "equilibrium/time_slice/boundary/a_minor");

		!!!  elongation:time_slice/boundary/elongation:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%elongation, getDouble(), "equilibrium/time_slice/boundary/elongation");

		!!!  elongation_upper:time_slice/boundary/elongation_upper:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%elongation_upper, getDouble(), "equilibrium/time_slice/boundary/elongation_upper");

		!!!  elongation_lower:time_slice/boundary/elongation_lower:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%elongation_lower, getDouble(), "equilibrium/time_slice/boundary/elongation_lower");

		!!!  triangularity:time_slice/boundary/triangularity:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%triangularity, getDouble(), "equilibrium/time_slice/boundary/triangularity");

		!!!  triangularity_upper:time_slice/boundary/triangularity_upper:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%triangularity_upper, getDouble(), "equilibrium/time_slice/boundary/triangularity_upper");

		!!!  triangularity_lower:time_slice/boundary/triangularity_lower:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%triangularity_lower, getDouble(), "equilibrium/time_slice/boundary/triangularity_lower");

		!!!  lcfs:time_slice/boundary/lcfs:structure::

		!!!  r:time_slice/boundary/lcfs/r:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%boundary%lcfs%r, getDouble1DArray(), "equilibrium/time_slice/boundary/lcfs/r");

		!!!  z:time_slice/boundary/lcfs/z:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%boundary%lcfs%z, getDouble1DArray(), "equilibrium/time_slice/boundary/lcfs/z");

		!!!  geometric_axis:time_slice/boundary/geometric_axis:structure::

		!!!  r:time_slice/boundary/geometric_axis/r:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%geometric_axis%r, getDouble(), "equilibrium/time_slice/boundary/geometric_axis/r");

		!!!  z:time_slice/boundary/geometric_axis/z:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%geometric_axis%z, getDouble(), "equilibrium/time_slice/boundary/geometric_axis/z");

		!!!  active_limiter_point:time_slice/boundary/active_limiter_point:structure::

		!!!  r:time_slice/boundary/active_limiter_point/r:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%active_limiter_point%r, getDouble(), "equilibrium/time_slice/boundary/active_limiter_point/r");

		!!!  z:time_slice/boundary/active_limiter_point/z:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%active_limiter_point%z, getDouble(), "equilibrium/time_slice/boundary/active_limiter_point/z");

		!!!  x_point:time_slice/boundary/x_point:struct_array::
		if(.not. associated(ids%time_slice(1)%boundary%x_point)) then 
			write(*,*) "ERROR! IDS: equilibrium Field: time_slice(1)%boundary%x_point(1) is not associated!"
 			else 

		!!!  r:time_slice/boundary/x_point/r:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%x_point(1)%r, getDouble(), "equilibrium/time_slice/boundary/x_point/r");

		!!!  z:time_slice/boundary/x_point/z:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%x_point(1)%z, getDouble(), "equilibrium/time_slice/boundary/x_point/z");
		end if 

		!!!  strike_point:time_slice/boundary/strike_point:struct_array::
		if(.not. associated(ids%time_slice(1)%boundary%strike_point)) then 
			write(*,*) "ERROR! IDS: equilibrium Field: time_slice(1)%boundary%strike_point(1) is not associated!"
 			else 

		!!!  r:time_slice/boundary/strike_point/r:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%strike_point(1)%r, getDouble(), "equilibrium/time_slice/boundary/strike_point/r");

		!!!  z:time_slice/boundary/strike_point/z:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%boundary%strike_point(1)%z, getDouble(), "equilibrium/time_slice/boundary/strike_point/z");
		end if 

		!!!  global_quantities:time_slice/global_quantities:structure::

		!!!  beta_pol:time_slice/global_quantities/beta_pol:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%beta_pol, getDouble(), "equilibrium/time_slice/global_quantities/beta_pol");

		!!!  beta_tor:time_slice/global_quantities/beta_tor:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%beta_tor, getDouble(), "equilibrium/time_slice/global_quantities/beta_tor");

		!!!  beta_normal:time_slice/global_quantities/beta_normal:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%beta_normal, getDouble(), "equilibrium/time_slice/global_quantities/beta_normal");

		!!!  ip:time_slice/global_quantities/ip:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%ip, getDouble(), "equilibrium/time_slice/global_quantities/ip");

		!!!  li_3:time_slice/global_quantities/li_3:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%li_3, getDouble(), "equilibrium/time_slice/global_quantities/li_3");

		!!!  volume:time_slice/global_quantities/volume:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%volume, getDouble(), "equilibrium/time_slice/global_quantities/volume");

		!!!  area:time_slice/global_quantities/area:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%area, getDouble(), "equilibrium/time_slice/global_quantities/area");

		!!!  surface:time_slice/global_quantities/surface:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%surface, getDouble(), "equilibrium/time_slice/global_quantities/surface");

		!!!  length_pol:time_slice/global_quantities/length_pol:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%length_pol, getDouble(), "equilibrium/time_slice/global_quantities/length_pol");

		!!!  psi_axis:time_slice/global_quantities/psi_axis:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%psi_axis, getDouble(), "equilibrium/time_slice/global_quantities/psi_axis");

		!!!  psi_boundary:time_slice/global_quantities/psi_boundary:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%psi_boundary, getDouble(), "equilibrium/time_slice/global_quantities/psi_boundary");

		!!!  q_axis:time_slice/global_quantities/q_axis:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%q_axis, getDouble(), "equilibrium/time_slice/global_quantities/q_axis");

		!!!  q_95:time_slice/global_quantities/q_95:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%q_95, getDouble(), "equilibrium/time_slice/global_quantities/q_95");

		!!!  w_mhd:time_slice/global_quantities/w_mhd:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%w_mhd, getDouble(), "equilibrium/time_slice/global_quantities/w_mhd");

		!!!  magnetic_axis:time_slice/global_quantities/magnetic_axis:structure::

		!!!  r:time_slice/global_quantities/magnetic_axis/r:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%magnetic_axis%r, getDouble(), "equilibrium/time_slice/global_quantities/magnetic_axis/r");

		!!!  z:time_slice/global_quantities/magnetic_axis/z:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%magnetic_axis%z, getDouble(), "equilibrium/time_slice/global_quantities/magnetic_axis/z");

		!!!  b_tor:time_slice/global_quantities/magnetic_axis/b_tor:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%magnetic_axis%b_tor, getDouble(), "equilibrium/time_slice/global_quantities/magnetic_axis/b_tor");

		!!!  q_min:time_slice/global_quantities/q_min:structure::

		!!!  value:time_slice/global_quantities/q_min/value:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%q_min%value, getDouble(), "equilibrium/time_slice/global_quantities/q_min/value");

		!!!  rho_tor_norm:time_slice/global_quantities/q_min/rho_tor_norm:FLT_0D:dynamic:
			call assertField(ids%time_slice(1)%global_quantities%q_min%rho_tor_norm, getDouble(), "equilibrium/time_slice/global_quantities/q_min/rho_tor_norm");

		!!!  profiles_1d:time_slice/profiles_1d:structure::

		!!!  psi:time_slice/profiles_1d/psi:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%psi, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/psi");

		!!!  phi:time_slice/profiles_1d/phi:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%phi, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/phi");

		!!!  pressure:time_slice/profiles_1d/pressure:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%pressure, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/pressure");

		!!!  f:time_slice/profiles_1d/f:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%f, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/f");

		!!!  dpressure_dpsi:time_slice/profiles_1d/dpressure_dpsi:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%dpressure_dpsi, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/dpressure_dpsi");

		!!!  f_df_dpsi:time_slice/profiles_1d/f_df_dpsi:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%f_df_dpsi, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/f_df_dpsi");

		!!!  j_tor:time_slice/profiles_1d/j_tor:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%j_tor, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/j_tor");

		!!!  j_parallel:time_slice/profiles_1d/j_parallel:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%j_parallel, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/j_parallel");

		!!!  q:time_slice/profiles_1d/q:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%q, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/q");

		!!!  magnetic_shear:time_slice/profiles_1d/magnetic_shear:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%magnetic_shear, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/magnetic_shear");

		!!!  r_inboard:time_slice/profiles_1d/r_inboard:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%r_inboard, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/r_inboard");

		!!!  r_outboard:time_slice/profiles_1d/r_outboard:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%r_outboard, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/r_outboard");

		!!!  rho_tor:time_slice/profiles_1d/rho_tor:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%rho_tor, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/rho_tor");

		!!!  rho_tor_norm:time_slice/profiles_1d/rho_tor_norm:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%rho_tor_norm, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/rho_tor_norm");

		!!!  dpsi_drho_tor:time_slice/profiles_1d/dpsi_drho_tor:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%dpsi_drho_tor, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/dpsi_drho_tor");

		!!!  elongation:time_slice/profiles_1d/elongation:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%elongation, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/elongation");

		!!!  triangularity_upper:time_slice/profiles_1d/triangularity_upper:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%triangularity_upper, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/triangularity_upper");

		!!!  triangularity_lower:time_slice/profiles_1d/triangularity_lower:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%triangularity_lower, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/triangularity_lower");

		!!!  volume:time_slice/profiles_1d/volume:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%volume, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/volume");

		!!!  dvolume_dpsi:time_slice/profiles_1d/dvolume_dpsi:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%dvolume_dpsi, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/dvolume_dpsi");

		!!!  dvolume_drho_tor:time_slice/profiles_1d/dvolume_drho_tor:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%dvolume_drho_tor, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/dvolume_drho_tor");

		!!!  area:time_slice/profiles_1d/area:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%area, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/area");

		!!!  darea_dpsi:time_slice/profiles_1d/darea_dpsi:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%darea_dpsi, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/darea_dpsi");

		!!!  surface:time_slice/profiles_1d/surface:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%surface, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/surface");

		!!!  trapped_fraction:time_slice/profiles_1d/trapped_fraction:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%trapped_fraction, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/trapped_fraction");

		!!!  gm1:time_slice/profiles_1d/gm1:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%gm1, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/gm1");

		!!!  gm2:time_slice/profiles_1d/gm2:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%gm2, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/gm2");

		!!!  gm3:time_slice/profiles_1d/gm3:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%gm3, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/gm3");

		!!!  gm4:time_slice/profiles_1d/gm4:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%gm4, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/gm4");

		!!!  gm5:time_slice/profiles_1d/gm5:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%gm5, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/gm5");

		!!!  gm6:time_slice/profiles_1d/gm6:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%gm6, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/gm6");

		!!!  gm7:time_slice/profiles_1d/gm7:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%gm7, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/gm7");

		!!!  gm8:time_slice/profiles_1d/gm8:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%gm8, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/gm8");

		!!!  gm9:time_slice/profiles_1d/gm9:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%gm9, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/gm9");

		!!!  b_average:time_slice/profiles_1d/b_average:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%b_average, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/b_average");

		!!!  b_min:time_slice/profiles_1d/b_min:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%b_min, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/b_min");

		!!!  b_max:time_slice/profiles_1d/b_max:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_1d%b_max, getDouble1DArray(), "equilibrium/time_slice/profiles_1d/b_max");

		!!!  coordinate_system:time_slice/coordinate_system:structure::

		!!!  r:time_slice/coordinate_system/r:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%coordinate_system%r, getDouble2DArray(), "equilibrium/time_slice/coordinate_system/r");

		!!!  z:time_slice/coordinate_system/z:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%coordinate_system%z, getDouble2DArray(), "equilibrium/time_slice/coordinate_system/z");

		!!!  jacobian:time_slice/coordinate_system/jacobian:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%coordinate_system%jacobian, getDouble2DArray(), "equilibrium/time_slice/coordinate_system/jacobian");

		!!!  g_11:time_slice/coordinate_system/g_11:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%coordinate_system%g_11, getDouble2DArray(), "equilibrium/time_slice/coordinate_system/g_11");

		!!!  g_12:time_slice/coordinate_system/g_12:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%coordinate_system%g_12, getDouble2DArray(), "equilibrium/time_slice/coordinate_system/g_12");

		!!!  g_13:time_slice/coordinate_system/g_13:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%coordinate_system%g_13, getDouble2DArray(), "equilibrium/time_slice/coordinate_system/g_13");

		!!!  g_22:time_slice/coordinate_system/g_22:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%coordinate_system%g_22, getDouble2DArray(), "equilibrium/time_slice/coordinate_system/g_22");

		!!!  g_23:time_slice/coordinate_system/g_23:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%coordinate_system%g_23, getDouble2DArray(), "equilibrium/time_slice/coordinate_system/g_23");

		!!!  g_33:time_slice/coordinate_system/g_33:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%coordinate_system%g_33, getDouble2DArray(), "equilibrium/time_slice/coordinate_system/g_33");

		!!!  grid_type:time_slice/coordinate_system/grid_type:structure::

		!!!  name:time_slice/coordinate_system/grid_type/name:STR_0D:constant:
			call assertField(ids%time_slice(1)%coordinate_system%grid_type%name, getString(), "equilibrium/time_slice/coordinate_system/grid_type/name");

		!!!  index:time_slice/coordinate_system/grid_type/index:INT_0D:constant:
			call assertField(ids%time_slice(1)%coordinate_system%grid_type%index, getInteger(), "equilibrium/time_slice/coordinate_system/grid_type/index");

		!!!  description:time_slice/coordinate_system/grid_type/description:STR_0D:constant:
			call assertField(ids%time_slice(1)%coordinate_system%grid_type%description, getString(), "equilibrium/time_slice/coordinate_system/grid_type/description");

		!!!  grid:time_slice/coordinate_system/grid:structure::

		!!!  dim1:time_slice/coordinate_system/grid/dim1:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%coordinate_system%grid%dim1, getDouble1DArray(), "equilibrium/time_slice/coordinate_system/grid/dim1");

		!!!  dim2:time_slice/coordinate_system/grid/dim2:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%coordinate_system%grid%dim2, getDouble1DArray(), "equilibrium/time_slice/coordinate_system/grid/dim2");

		!!!  profiles_2d:time_slice/profiles_2d:struct_array::
		if(.not. associated(ids%time_slice(1)%profiles_2d)) then 
			write(*,*) "ERROR! IDS: equilibrium Field: time_slice(1)%profiles_2d(1) is not associated!"
 			else 

		!!!  r:time_slice/profiles_2d/r:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%profiles_2d(1)%r, getDouble2DArray(), "equilibrium/time_slice/profiles_2d/r");

		!!!  z:time_slice/profiles_2d/z:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%profiles_2d(1)%z, getDouble2DArray(), "equilibrium/time_slice/profiles_2d/z");

		!!!  psi:time_slice/profiles_2d/psi:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%profiles_2d(1)%psi, getDouble2DArray(), "equilibrium/time_slice/profiles_2d/psi");

		!!!  theta:time_slice/profiles_2d/theta:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%profiles_2d(1)%theta, getDouble2DArray(), "equilibrium/time_slice/profiles_2d/theta");

		!!!  phi:time_slice/profiles_2d/phi:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%profiles_2d(1)%phi, getDouble2DArray(), "equilibrium/time_slice/profiles_2d/phi");

		!!!  j_tor:time_slice/profiles_2d/j_tor:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%profiles_2d(1)%j_tor, getDouble2DArray(), "equilibrium/time_slice/profiles_2d/j_tor");

		!!!  j_parallel:time_slice/profiles_2d/j_parallel:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%profiles_2d(1)%j_parallel, getDouble2DArray(), "equilibrium/time_slice/profiles_2d/j_parallel");

		!!!  b_r:time_slice/profiles_2d/b_r:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%profiles_2d(1)%b_r, getDouble2DArray(), "equilibrium/time_slice/profiles_2d/b_r");

		!!!  b_z:time_slice/profiles_2d/b_z:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%profiles_2d(1)%b_z, getDouble2DArray(), "equilibrium/time_slice/profiles_2d/b_z");

		!!!  b_tor:time_slice/profiles_2d/b_tor:FLT_2D:dynamic:
			call assertField(ids%time_slice(1)%profiles_2d(1)%b_tor, getDouble2DArray(), "equilibrium/time_slice/profiles_2d/b_tor");

		!!!  grid_type:time_slice/profiles_2d/grid_type:structure::

		!!!  name:time_slice/profiles_2d/grid_type/name:STR_0D:constant:
			call assertField(ids%time_slice(1)%profiles_2d(1)%grid_type%name, getString(), "equilibrium/time_slice/profiles_2d/grid_type/name");

		!!!  index:time_slice/profiles_2d/grid_type/index:INT_0D:constant:
			call assertField(ids%time_slice(1)%profiles_2d(1)%grid_type%index, getInteger(), "equilibrium/time_slice/profiles_2d/grid_type/index");

		!!!  description:time_slice/profiles_2d/grid_type/description:STR_0D:constant:
			call assertField(ids%time_slice(1)%profiles_2d(1)%grid_type%description, getString(), "equilibrium/time_slice/profiles_2d/grid_type/description");

		!!!  grid:time_slice/profiles_2d/grid:structure::

		!!!  dim1:time_slice/profiles_2d/grid/dim1:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_2d(1)%grid%dim1, getDouble1DArray(), "equilibrium/time_slice/profiles_2d/grid/dim1");

		!!!  dim2:time_slice/profiles_2d/grid/dim2:FLT_1D:dynamic:
			call assertField(ids%time_slice(1)%profiles_2d(1)%grid%dim2, getDouble1DArray(), "equilibrium/time_slice/profiles_2d/grid/dim2");
		end if 
		end if 

		!!!  name:code/name:STR_0D:constant:
			 call assertField(ids%code%name, getString(), "equilibrium/code/name");

		!!!  version:code/version:STR_0D:constant:
			 call assertField(ids%code%version, getString(), "equilibrium/code/version");

		!!!  parameters:code/parameters:STR_0D:constant:
			 call assertField(ids%code%parameters, getString(), "equilibrium/code/parameters");

		!!!  output_flag:code/output_flag:INT_1D:dynamic:
			 call assertField(ids%code%output_flag, getInteger1DArray(), "equilibrium/code/output_flag");

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "equilibrium/time");
	end do 
	
END SUBROUTINE equilibrium_get

!==================================================================
!		 GET magnetics 
!==================================================================
SUBROUTINE magnetics_get
	CHARACTER (LEN = *), parameter :: idsName = "magnetics"
	TYPE (ids_magnetics) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on magnetics"
	CALL srand(seed)
	do i = 0, 6 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "magnetics/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "magnetics/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "magnetics/ids_properties/cocos");

		!!!  flux_loop:flux_loop:struct_array::
		if(.not. associated(ids%flux_loop)) then 
			write(*,*) "ERROR! IDS: magnetics Field: flux_loop is not associated!"
 			else 

		!!!  name:flux_loop/name:STR_0D:static:
			call assertField(ids%flux_loop(1)%name, getString(), "magnetics/flux_loop/name");

		!!!  identifier:flux_loop/identifier:STR_0D:static:
			call assertField(ids%flux_loop(1)%identifier, getString(), "magnetics/flux_loop/identifier");

		!!!  flux:flux_loop/flux:structure::

		!!!  data:flux_loop/flux/data:FLT_1D:dynamic:
			call assertField(ids%flux_loop(1)%flux%data, getDouble1DArray(), "magnetics/flux_loop/flux/data");

		!!!  time:flux_loop/flux/time:flt_1d_type:dynamic:
			call assertField(ids%flux_loop(1)%flux%time, getDouble1DArray(), "magnetics/flux_loop/flux/time");

		!!!  position:flux_loop/position:struct_array:static:
		if(.not. associated(ids%flux_loop(1)%position)) then 
			write(*,*) "ERROR! IDS: magnetics Field: flux_loop(1)%position(1) is not associated!"
 			else 

		!!!  r:flux_loop/position/r:FLT_0D:static:
			call assertField(ids%flux_loop(1)%position(1)%r, getDouble(), "magnetics/flux_loop/position/r");

		!!!  z:flux_loop/position/z:FLT_0D:static:
			call assertField(ids%flux_loop(1)%position(1)%z, getDouble(), "magnetics/flux_loop/position/z");

		!!!  phi:flux_loop/position/phi:FLT_0D:static:
			call assertField(ids%flux_loop(1)%position(1)%phi, getDouble(), "magnetics/flux_loop/position/phi");
		end if 
		end if 

		!!!  bpol_probe:bpol_probe:struct_array::
		if(.not. associated(ids%bpol_probe)) then 
			write(*,*) "ERROR! IDS: magnetics Field: bpol_probe is not associated!"
 			else 

		!!!  name:bpol_probe/name:STR_0D:static:
			call assertField(ids%bpol_probe(1)%name, getString(), "magnetics/bpol_probe/name");

		!!!  identifier:bpol_probe/identifier:STR_0D:static:
			call assertField(ids%bpol_probe(1)%identifier, getString(), "magnetics/bpol_probe/identifier");

		!!!  poloidal_angle:bpol_probe/poloidal_angle:FLT_0D:static:
			call assertField(ids%bpol_probe(1)%poloidal_angle, getDouble(), "magnetics/bpol_probe/poloidal_angle");

		!!!  toroidal_angle:bpol_probe/toroidal_angle:FLT_0D:static:
			call assertField(ids%bpol_probe(1)%toroidal_angle, getDouble(), "magnetics/bpol_probe/toroidal_angle");

		!!!  area:bpol_probe/area:FLT_0D:static:
			call assertField(ids%bpol_probe(1)%area, getDouble(), "magnetics/bpol_probe/area");

		!!!  length:bpol_probe/length:FLT_0D:static:
			call assertField(ids%bpol_probe(1)%length, getDouble(), "magnetics/bpol_probe/length");

		!!!  turns:bpol_probe/turns:INT_0D:static:
			call assertField(ids%bpol_probe(1)%turns, getInteger(), "magnetics/bpol_probe/turns");

		!!!  position:bpol_probe/position:structure::

		!!!  r:bpol_probe/position/r:FLT_0D:static:
			call assertField(ids%bpol_probe(1)%position%r, getDouble(), "magnetics/bpol_probe/position/r");

		!!!  z:bpol_probe/position/z:FLT_0D:static:
			call assertField(ids%bpol_probe(1)%position%z, getDouble(), "magnetics/bpol_probe/position/z");

		!!!  phi:bpol_probe/position/phi:FLT_0D:static:
			call assertField(ids%bpol_probe(1)%position%phi, getDouble(), "magnetics/bpol_probe/position/phi");

		!!!  field:bpol_probe/field:structure::

		!!!  data:bpol_probe/field/data:FLT_1D:dynamic:
			call assertField(ids%bpol_probe(1)%field%data, getDouble1DArray(), "magnetics/bpol_probe/field/data");

		!!!  time:bpol_probe/field/time:flt_1d_type:dynamic:
			call assertField(ids%bpol_probe(1)%field%time, getDouble1DArray(), "magnetics/bpol_probe/field/time");
		end if 

		!!!  method:method:struct_array::
		if(.not. associated(ids%method)) then 
			write(*,*) "ERROR! IDS: magnetics Field: method is not associated!"
 			else 

		!!!  name:method/name:STR_0D:static:
			call assertField(ids%method(1)%name, getString(), "magnetics/method/name");

		!!!  ip:method/ip:structure::

		!!!  data:method/ip/data:FLT_1D:dynamic:
			call assertField(ids%method(1)%ip%data, getDouble1DArray(), "magnetics/method/ip/data");

		!!!  time:method/ip/time:flt_1d_type:dynamic:
			call assertField(ids%method(1)%ip%time, getDouble1DArray(), "magnetics/method/ip/time");

		!!!  diamagnetic_flux:method/diamagnetic_flux:structure::

		!!!  data:method/diamagnetic_flux/data:FLT_1D:dynamic:
			call assertField(ids%method(1)%diamagnetic_flux%data, getDouble1DArray(), "magnetics/method/diamagnetic_flux/data");

		!!!  time:method/diamagnetic_flux/time:flt_1d_type:dynamic:
			call assertField(ids%method(1)%diamagnetic_flux%time, getDouble1DArray(), "magnetics/method/diamagnetic_flux/time");
		end if 

		!!!  name:code/name:STR_0D:constant:
			 call assertField(ids%code%name, getString(), "magnetics/code/name");

		!!!  version:code/version:STR_0D:constant:
			 call assertField(ids%code%version, getString(), "magnetics/code/version");

		!!!  parameters:code/parameters:STR_0D:constant:
			 call assertField(ids%code%parameters, getString(), "magnetics/code/parameters");

		!!!  output_flag:code/output_flag:INT_1D:dynamic:
			 call assertField(ids%code%output_flag, getInteger1DArray(), "magnetics/code/output_flag");

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "magnetics/time");
	end do 
	
END SUBROUTINE magnetics_get

!==================================================================
!		 GET pf_active 
!==================================================================
SUBROUTINE pf_active_get
	CHARACTER (LEN = *), parameter :: idsName = "pf_active"
	TYPE (ids_pf_active) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on pf_active"
	CALL srand(seed)
	do i = 0, 6 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "pf_active/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "pf_active/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "pf_active/ids_properties/cocos");

		!!!  coil:coil:struct_array::
		if(.not. associated(ids%coil)) then 
			write(*,*) "ERROR! IDS: pf_active Field: coil is not associated!"
 			else 

		!!!  name:coil/name:STR_0D:static:
			call assertField(ids%coil(1)%name, getString(), "pf_active/coil/name");

		!!!  identifier:coil/identifier:STR_0D:static:
			call assertField(ids%coil(1)%identifier, getString(), "pf_active/coil/identifier");

		!!!  resistance:coil/resistance:FLT_0D:static:
			call assertField(ids%coil(1)%resistance, getDouble(), "pf_active/coil/resistance");

		!!!  energy_limit_max:coil/energy_limit_max:FLT_0D:static:
			call assertField(ids%coil(1)%energy_limit_max, getDouble(), "pf_active/coil/energy_limit_max");

		!!!  current:coil/current:structure::

		!!!  data:coil/current/data:FLT_1D:dynamic:
			call assertField(ids%coil(1)%current%data, getDouble1DArray(), "pf_active/coil/current/data");

		!!!  time:coil/current/time:flt_1d_type:dynamic:
			call assertField(ids%coil(1)%current%time, getDouble1DArray(), "pf_active/coil/current/time");

		!!!  voltage:coil/voltage:structure::

		!!!  data:coil/voltage/data:FLT_1D:dynamic:
			call assertField(ids%coil(1)%voltage%data, getDouble1DArray(), "pf_active/coil/voltage/data");

		!!!  time:coil/voltage/time:flt_1d_type:dynamic:
			call assertField(ids%coil(1)%voltage%time, getDouble1DArray(), "pf_active/coil/voltage/time");

		!!!  element:coil/element:struct_array::
		if(.not. associated(ids%coil(1)%element)) then 
			write(*,*) "ERROR! IDS: pf_active Field: coil(1)%element(1) is not associated!"
 			else 

		!!!  name:coil/element/name:STR_0D:static:
			call assertField(ids%coil(1)%element(1)%name, getString(), "pf_active/coil/element/name");

		!!!  identifier:coil/element/identifier:STR_0D:static:
			call assertField(ids%coil(1)%element(1)%identifier, getString(), "pf_active/coil/element/identifier");

		!!!  turns_with_sign:coil/element/turns_with_sign:INT_0D:static:
			call assertField(ids%coil(1)%element(1)%turns_with_sign, getInteger(), "pf_active/coil/element/turns_with_sign");

		!!!  area:coil/element/area:FLT_0D:static:
			call assertField(ids%coil(1)%element(1)%area, getDouble(), "pf_active/coil/element/area");

		!!!  geometry:coil/element/geometry:structure::

		!!!  geometry_type:coil/element/geometry/geometry_type:INT_0D:static:
			call assertField(ids%coil(1)%element(1)%geometry%geometry_type, getInteger(), "pf_active/coil/element/geometry/geometry_type");

		!!!  outline:coil/element/geometry/outline:structure::

		!!!  r:coil/element/geometry/outline/r:FLT_1D:static:
			call assertField(ids%coil(1)%element(1)%geometry%outline%r, getDouble1DArray(), "pf_active/coil/element/geometry/outline/r");

		!!!  z:coil/element/geometry/outline/z:FLT_1D:static:
			call assertField(ids%coil(1)%element(1)%geometry%outline%z, getDouble1DArray(), "pf_active/coil/element/geometry/outline/z");

		!!!  rectangle:coil/element/geometry/rectangle:structure::

		!!!  r:coil/element/geometry/rectangle/r:FLT_0D:static:
			call assertField(ids%coil(1)%element(1)%geometry%rectangle%r, getDouble(), "pf_active/coil/element/geometry/rectangle/r");

		!!!  z:coil/element/geometry/rectangle/z:FLT_0D:static:
			call assertField(ids%coil(1)%element(1)%geometry%rectangle%z, getDouble(), "pf_active/coil/element/geometry/rectangle/z");

		!!!  width:coil/element/geometry/rectangle/width:FLT_0D:static:
			call assertField(ids%coil(1)%element(1)%geometry%rectangle%width, getDouble(), "pf_active/coil/element/geometry/rectangle/width");

		!!!  height:coil/element/geometry/rectangle/height:FLT_0D:static:
			call assertField(ids%coil(1)%element(1)%geometry%rectangle%height, getDouble(), "pf_active/coil/element/geometry/rectangle/height");

		!!!  oblique:coil/element/geometry/oblique:structure::

		!!!  r:coil/element/geometry/oblique/r:FLT_0D:static:
			call assertField(ids%coil(1)%element(1)%geometry%oblique%r, getDouble(), "pf_active/coil/element/geometry/oblique/r");

		!!!  z:coil/element/geometry/oblique/z:FLT_0D:static:
			call assertField(ids%coil(1)%element(1)%geometry%oblique%z, getDouble(), "pf_active/coil/element/geometry/oblique/z");

		!!!  length:coil/element/geometry/oblique/length:FLT_0D:static:
			call assertField(ids%coil(1)%element(1)%geometry%oblique%length, getDouble(), "pf_active/coil/element/geometry/oblique/length");

		!!!  thickness:coil/element/geometry/oblique/thickness:FLT_0D:static:
			call assertField(ids%coil(1)%element(1)%geometry%oblique%thickness, getDouble(), "pf_active/coil/element/geometry/oblique/thickness");

		!!!  alpha:coil/element/geometry/oblique/alpha:FLT_0D:static:
			call assertField(ids%coil(1)%element(1)%geometry%oblique%alpha, getDouble(), "pf_active/coil/element/geometry/oblique/alpha");

		!!!  beta:coil/element/geometry/oblique/beta:FLT_0D:static:
			call assertField(ids%coil(1)%element(1)%geometry%oblique%beta, getDouble(), "pf_active/coil/element/geometry/oblique/beta");
		end if 
		end if 

		!!!  vertical_force:vertical_force:struct_array::
		if(.not. associated(ids%vertical_force)) then 
			write(*,*) "ERROR! IDS: pf_active Field: vertical_force is not associated!"
 			else 

		!!!  name:vertical_force/name:STR_0D:static:
			call assertField(ids%vertical_force(1)%name, getString(), "pf_active/vertical_force/name");

		!!!  combination:vertical_force/combination:FLT_1D:static:
			call assertField(ids%vertical_force(1)%combination, getDouble1DArray(), "pf_active/vertical_force/combination");

		!!!  limit_max:vertical_force/limit_max:FLT_0D:static:
			call assertField(ids%vertical_force(1)%limit_max, getDouble(), "pf_active/vertical_force/limit_max");

		!!!  limit_min:vertical_force/limit_min:FLT_0D:static:
			call assertField(ids%vertical_force(1)%limit_min, getDouble(), "pf_active/vertical_force/limit_min");

		!!!  force:vertical_force/force:structure::

		!!!  data:vertical_force/force/data:FLT_1D:dynamic:
			call assertField(ids%vertical_force(1)%force%data, getDouble1DArray(), "pf_active/vertical_force/force/data");

		!!!  time:vertical_force/force/time:flt_1d_type:dynamic:
			call assertField(ids%vertical_force(1)%force%time, getDouble1DArray(), "pf_active/vertical_force/force/time");
		end if 

		!!!  circuit:circuit:struct_array::
		if(.not. associated(ids%circuit)) then 
			write(*,*) "ERROR! IDS: pf_active Field: circuit is not associated!"
 			else 

		!!!  name:circuit/name:STR_0D:static:
			call assertField(ids%circuit(1)%name, getString(), "pf_active/circuit/name");

		!!!  identifier:circuit/identifier:STR_0D:static:
			call assertField(ids%circuit(1)%identifier, getString(), "pf_active/circuit/identifier");

		!!!  type:circuit/type:STR_0D:static:
			call assertField(ids%circuit(1)%type, getString(), "pf_active/circuit/type");

		!!!  connections:circuit/connections:INT_2D:static:
			call assertField(ids%circuit(1)%connections, getInteger2DArray(), "pf_active/circuit/connections");

		!!!  voltage:circuit/voltage:structure::

		!!!  data:circuit/voltage/data:FLT_1D:dynamic:
			call assertField(ids%circuit(1)%voltage%data, getDouble1DArray(), "pf_active/circuit/voltage/data");

		!!!  time:circuit/voltage/time:flt_1d_type:dynamic:
			call assertField(ids%circuit(1)%voltage%time, getDouble1DArray(), "pf_active/circuit/voltage/time");

		!!!  current:circuit/current:structure::

		!!!  data:circuit/current/data:FLT_1D:dynamic:
			call assertField(ids%circuit(1)%current%data, getDouble1DArray(), "pf_active/circuit/current/data");

		!!!  time:circuit/current/time:flt_1d_type:dynamic:
			call assertField(ids%circuit(1)%current%time, getDouble1DArray(), "pf_active/circuit/current/time");
		end if 

		!!!  supply:supply:struct_array::
		if(.not. associated(ids%supply)) then 
			write(*,*) "ERROR! IDS: pf_active Field: supply is not associated!"
 			else 

		!!!  name:supply/name:STR_0D:static:
			call assertField(ids%supply(1)%name, getString(), "pf_active/supply/name");

		!!!  identifier:supply/identifier:STR_0D:static:
			call assertField(ids%supply(1)%identifier, getString(), "pf_active/supply/identifier");

		!!!  type:supply/type:INT_0D:static:
			call assertField(ids%supply(1)%type, getInteger(), "pf_active/supply/type");

		!!!  resistance:supply/resistance:FLT_0D:static:
			call assertField(ids%supply(1)%resistance, getDouble(), "pf_active/supply/resistance");

		!!!  delay:supply/delay:FLT_0D:static:
			call assertField(ids%supply(1)%delay, getDouble(), "pf_active/supply/delay");

		!!!  filter_numerator:supply/filter_numerator:FLT_1D:static:
			call assertField(ids%supply(1)%filter_numerator, getDouble1DArray(), "pf_active/supply/filter_numerator");

		!!!  filter_denominator:supply/filter_denominator:FLT_1D:static:
			call assertField(ids%supply(1)%filter_denominator, getDouble1DArray(), "pf_active/supply/filter_denominator");

		!!!  current_limit_max:supply/current_limit_max:FLT_0D:static:
			call assertField(ids%supply(1)%current_limit_max, getDouble(), "pf_active/supply/current_limit_max");

		!!!  current_limit_min:supply/current_limit_min:FLT_0D:static:
			call assertField(ids%supply(1)%current_limit_min, getDouble(), "pf_active/supply/current_limit_min");

		!!!  voltage_limit_max:supply/voltage_limit_max:FLT_0D:static:
			call assertField(ids%supply(1)%voltage_limit_max, getDouble(), "pf_active/supply/voltage_limit_max");

		!!!  voltage_limit_min:supply/voltage_limit_min:FLT_0D:static:
			call assertField(ids%supply(1)%voltage_limit_min, getDouble(), "pf_active/supply/voltage_limit_min");

		!!!  current_limiter_gain:supply/current_limiter_gain:FLT_0D:static:
			call assertField(ids%supply(1)%current_limiter_gain, getDouble(), "pf_active/supply/current_limiter_gain");

		!!!  energy_limit_max:supply/energy_limit_max:FLT_0D:static:
			call assertField(ids%supply(1)%energy_limit_max, getDouble(), "pf_active/supply/energy_limit_max");

		!!!  nonlinear_model:supply/nonlinear_model:STR_0D:static:
			call assertField(ids%supply(1)%nonlinear_model, getString(), "pf_active/supply/nonlinear_model");

		!!!  voltage:supply/voltage:structure::

		!!!  data:supply/voltage/data:FLT_1D:dynamic:
			call assertField(ids%supply(1)%voltage%data, getDouble1DArray(), "pf_active/supply/voltage/data");

		!!!  time:supply/voltage/time:flt_1d_type:dynamic:
			call assertField(ids%supply(1)%voltage%time, getDouble1DArray(), "pf_active/supply/voltage/time");

		!!!  current:supply/current:structure::

		!!!  data:supply/current/data:FLT_1D:dynamic:
			call assertField(ids%supply(1)%current%data, getDouble1DArray(), "pf_active/supply/current/data");

		!!!  time:supply/current/time:flt_1d_type:dynamic:
			call assertField(ids%supply(1)%current%time, getDouble1DArray(), "pf_active/supply/current/time");
		end if 

		!!!  name:code/name:STR_0D:constant:
			 call assertField(ids%code%name, getString(), "pf_active/code/name");

		!!!  version:code/version:STR_0D:constant:
			 call assertField(ids%code%version, getString(), "pf_active/code/version");

		!!!  parameters:code/parameters:STR_0D:constant:
			 call assertField(ids%code%parameters, getString(), "pf_active/code/parameters");

		!!!  output_flag:code/output_flag:INT_1D:dynamic:
			 call assertField(ids%code%output_flag, getInteger1DArray(), "pf_active/code/output_flag");

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "pf_active/time");
	end do 
	
END SUBROUTINE pf_active_get

!==================================================================
!		 GET pf_passive 
!==================================================================
SUBROUTINE pf_passive_get
	CHARACTER (LEN = *), parameter :: idsName = "pf_passive"
	TYPE (ids_pf_passive) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on pf_passive"
	CALL srand(seed)
	do i = 0, 6 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "pf_passive/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "pf_passive/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "pf_passive/ids_properties/cocos");

		!!!  loop:loop:struct_array::
		if(.not. associated(ids%loop)) then 
			write(*,*) "ERROR! IDS: pf_passive Field: loop is not associated!"
 			else 

		!!!  name:loop/name:STR_0D:static:
			call assertField(ids%loop(1)%name, getString(), "pf_passive/loop/name");

		!!!  area:loop/area:FLT_0D:static:
			call assertField(ids%loop(1)%area, getDouble(), "pf_passive/loop/area");

		!!!  resistance:loop/resistance:FLT_0D:static:
			call assertField(ids%loop(1)%resistance, getDouble(), "pf_passive/loop/resistance");

		!!!  current:loop/current:FLT_1D:dynamic:
			call assertField(ids%loop(1)%current, getDouble1DArray(), "pf_passive/loop/current");

		!!!  geometry:loop/geometry:structure::

		!!!  geometry_type:loop/geometry/geometry_type:INT_0D:static:
			call assertField(ids%loop(1)%geometry%geometry_type, getInteger(), "pf_passive/loop/geometry/geometry_type");

		!!!  outline:loop/geometry/outline:structure::

		!!!  r:loop/geometry/outline/r:FLT_1D:static:
			call assertField(ids%loop(1)%geometry%outline%r, getDouble1DArray(), "pf_passive/loop/geometry/outline/r");

		!!!  z:loop/geometry/outline/z:FLT_1D:static:
			call assertField(ids%loop(1)%geometry%outline%z, getDouble1DArray(), "pf_passive/loop/geometry/outline/z");

		!!!  rectangle:loop/geometry/rectangle:structure::

		!!!  r:loop/geometry/rectangle/r:FLT_0D:static:
			call assertField(ids%loop(1)%geometry%rectangle%r, getDouble(), "pf_passive/loop/geometry/rectangle/r");

		!!!  z:loop/geometry/rectangle/z:FLT_0D:static:
			call assertField(ids%loop(1)%geometry%rectangle%z, getDouble(), "pf_passive/loop/geometry/rectangle/z");

		!!!  width:loop/geometry/rectangle/width:FLT_0D:static:
			call assertField(ids%loop(1)%geometry%rectangle%width, getDouble(), "pf_passive/loop/geometry/rectangle/width");

		!!!  height:loop/geometry/rectangle/height:FLT_0D:static:
			call assertField(ids%loop(1)%geometry%rectangle%height, getDouble(), "pf_passive/loop/geometry/rectangle/height");

		!!!  oblique:loop/geometry/oblique:structure::

		!!!  r:loop/geometry/oblique/r:FLT_0D:static:
			call assertField(ids%loop(1)%geometry%oblique%r, getDouble(), "pf_passive/loop/geometry/oblique/r");

		!!!  z:loop/geometry/oblique/z:FLT_0D:static:
			call assertField(ids%loop(1)%geometry%oblique%z, getDouble(), "pf_passive/loop/geometry/oblique/z");

		!!!  length:loop/geometry/oblique/length:FLT_0D:static:
			call assertField(ids%loop(1)%geometry%oblique%length, getDouble(), "pf_passive/loop/geometry/oblique/length");

		!!!  thickness:loop/geometry/oblique/thickness:FLT_0D:static:
			call assertField(ids%loop(1)%geometry%oblique%thickness, getDouble(), "pf_passive/loop/geometry/oblique/thickness");

		!!!  alpha:loop/geometry/oblique/alpha:FLT_0D:static:
			call assertField(ids%loop(1)%geometry%oblique%alpha, getDouble(), "pf_passive/loop/geometry/oblique/alpha");

		!!!  beta:loop/geometry/oblique/beta:FLT_0D:static:
			call assertField(ids%loop(1)%geometry%oblique%beta, getDouble(), "pf_passive/loop/geometry/oblique/beta");
		end if 

		!!!  name:code/name:STR_0D:constant:
			 call assertField(ids%code%name, getString(), "pf_passive/code/name");

		!!!  version:code/version:STR_0D:constant:
			 call assertField(ids%code%version, getString(), "pf_passive/code/version");

		!!!  parameters:code/parameters:STR_0D:constant:
			 call assertField(ids%code%parameters, getString(), "pf_passive/code/parameters");

		!!!  output_flag:code/output_flag:INT_1D:dynamic:
			 call assertField(ids%code%output_flag, getInteger1DArray(), "pf_passive/code/output_flag");

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "pf_passive/time");
	end do 
	
END SUBROUTINE pf_passive_get

!==================================================================
!		 GET schedule 
!==================================================================
SUBROUTINE schedule_get
	CHARACTER (LEN = *), parameter :: idsName = "schedule"
	TYPE (ids_schedule) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on schedule"
	CALL srand(seed)
	do i = 0, 1 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "schedule/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "schedule/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "schedule/ids_properties/cocos");

		!!!  waveform:waveform:struct_array::
		if(.not. associated(ids%waveform)) then 
			write(*,*) "ERROR! IDS: schedule Field: waveform is not associated!"
 			else 

		!!!  name:waveform/name:STR_0D:constant:
			call assertField(ids%waveform(1)%name, getString(), "schedule/waveform/name");

		!!!  value:waveform/value:structure::

		!!!  data:waveform/value/data:FLT_1D:dynamic:
			call assertField(ids%waveform(1)%value%data, getDouble1DArray(), "schedule/waveform/value/data");

		!!!  time:waveform/value/time:flt_1d_type:dynamic:
			call assertField(ids%waveform(1)%value%time, getDouble1DArray(), "schedule/waveform/value/time");
		end if 

		!!!  name:code/name:STR_0D:constant:
			 call assertField(ids%code%name, getString(), "schedule/code/name");

		!!!  version:code/version:STR_0D:constant:
			 call assertField(ids%code%version, getString(), "schedule/code/version");

		!!!  parameters:code/parameters:STR_0D:constant:
			 call assertField(ids%code%parameters, getString(), "schedule/code/parameters");

		!!!  output_flag:code/output_flag:INT_1D:dynamic:
			 call assertField(ids%code%output_flag, getInteger1DArray(), "schedule/code/output_flag");

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "schedule/time");
	end do 
	
END SUBROUTINE schedule_get

!==================================================================
!		 GET sdn 
!==================================================================
SUBROUTINE sdn_get
	CHARACTER (LEN = *), parameter :: idsName = "sdn"
	TYPE (ids_sdn) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on sdn"
	CALL srand(seed)
	do i = 0, 6 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "sdn/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "sdn/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "sdn/ids_properties/cocos");

		!!!  signal:signal:struct_array::
		if(.not. associated(ids%signal)) then 
			write(*,*) "ERROR! IDS: sdn Field: signal is not associated!"
 			else 

		!!!  name:signal/name:STR_0D:static:
			call assertField(ids%signal(1)%name, getString(), "sdn/signal/name");

		!!!  definition:signal/definition:STR_0D:static:
			call assertField(ids%signal(1)%definition, getString(), "sdn/signal/definition");

		!!!  ip_normalise:signal/ip_normalise:INT_0D:static:
			call assertField(ids%signal(1)%ip_normalise, getInteger(), "sdn/signal/ip_normalise");

		!!!  allocated_position:signal/allocated_position:INT_0D:constant:
			call assertField(ids%signal(1)%allocated_position, getInteger(), "sdn/signal/allocated_position");

		!!!  value:signal/value:FLT_1D:dynamic:
			call assertField(ids%signal(1)%value, getDouble1DArray(), "sdn/signal/value");
		end if 

		!!!  topic_list:topic_list:struct_array::
		if(.not. associated(ids%topic_list)) then 
			write(*,*) "ERROR! IDS: sdn Field: topic_list is not associated!"
 			else 

		!!!  names:topic_list/names:STR_1D:static:
			call assertField(ids%topic_list(1)%names,  getString(), "sdn/topic_list/names");

		!!!  indices:topic_list/indices:INT_1D:static:
			call assertField(ids%topic_list(1)%indices, getInteger1DArray(), "sdn/topic_list/indices");
		end if 

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "sdn/time");
	end do 
	
END SUBROUTINE sdn_get

!==================================================================
!		 GET simulation 
!==================================================================
SUBROUTINE simulation_get
	CHARACTER (LEN = *), parameter :: idsName = "simulation"
	TYPE (ids_simulation) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on simulation"
	CALL srand(seed)
	do i = 0, 1 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "simulation/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "simulation/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "simulation/ids_properties/cocos");

		!!!  comment_before:comment_before:STR_0D:constant:
			 call assertField(ids%comment_before, getString(), "simulation/comment_before");

		!!!  comment_after:comment_after:STR_0D:constant:
			 call assertField(ids%comment_after, getString(), "simulation/comment_after");

		!!!  time_begin:time_begin:FLT_0D:constant:
			 call assertField(ids%time_begin, getDouble(), "simulation/time_begin");

		!!!  time_step:time_step:FLT_0D:constant:
			 call assertField(ids%time_step, getDouble(), "simulation/time_step");

		!!!  time_end:time_end:FLT_0D:constant:
			 call assertField(ids%time_end, getDouble(), "simulation/time_end");

		!!!  time_restart:time_restart:FLT_0D:constant:
			 call assertField(ids%time_restart, getDouble(), "simulation/time_restart");

		!!!  time_begun:time_begun:STR_0D:constant:
			 call assertField(ids%time_begun, getString(), "simulation/time_begun");

		!!!  time_ended:time_ended:STR_0D:constant:
			 call assertField(ids%time_ended, getString(), "simulation/time_ended");

		!!!  iterations_max:iterations_max:INT_0D:constant:
			 call assertField(ids%iterations_max, getInteger(), "simulation/iterations_max");

		!!!  iterations_used:iterations_used:INT_0D:constant:
			 call assertField(ids%iterations_used, getInteger(), "simulation/iterations_used");

		!!!  termination_condition:termination_condition:STR_0D:constant:
			 call assertField(ids%termination_condition, getString(), "simulation/termination_condition");

		!!!  rate_plot_equilibrium:rate_plot_equilibrium:INT_0D:constant:
			 call assertField(ids%rate_plot_equilibrium, getInteger(), "simulation/rate_plot_equilibrium");

		!!!  device_name:device_name:STR_0D:constant:
			 call assertField(ids%device_name, getString(), "simulation/device_name");

		!!!  restart_simulation:restart_simulation:STR_0D:constant:
			 call assertField(ids%restart_simulation, getString(), "simulation/restart_simulation");
	end do 
	
END SUBROUTINE simulation_get

!==================================================================
!		 GET temporary 
!==================================================================
SUBROUTINE temporary_get
	CHARACTER (LEN = *), parameter :: idsName = "temporary"
	TYPE (ids_temporary) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on temporary"
	CALL srand(seed)
	do i = 0, 6 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "temporary/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "temporary/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "temporary/ids_properties/cocos");

		!!!  constant_float0d:constant_float0d:struct_array::
		if(.not. associated(ids%constant_float0d)) then 
			write(*,*) "ERROR! IDS: temporary Field: constant_float0d is not associated!"
 			else 

		!!!  value:constant_float0d/value:FLT_0D:constant:
			call assertField(ids%constant_float0d(1)%value, getDouble(), "temporary/constant_float0d/value");

		!!!  identifier:constant_float0d/identifier:structure::

		!!!  name:constant_float0d/identifier/name:STR_0D:constant:
			call assertField(ids%constant_float0d(1)%identifier%name, getString(), "temporary/constant_float0d/identifier/name");

		!!!  index:constant_float0d/identifier/index:INT_0D:constant:
			call assertField(ids%constant_float0d(1)%identifier%index, getInteger(), "temporary/constant_float0d/identifier/index");

		!!!  description:constant_float0d/identifier/description:STR_0D:constant:
			call assertField(ids%constant_float0d(1)%identifier%description, getString(), "temporary/constant_float0d/identifier/description");
		end if 

		!!!  constant_integer0d:constant_integer0d:struct_array::
		if(.not. associated(ids%constant_integer0d)) then 
			write(*,*) "ERROR! IDS: temporary Field: constant_integer0d is not associated!"
 			else 

		!!!  value:constant_integer0d/value:INT_0D:constant:
			call assertField(ids%constant_integer0d(1)%value, getInteger(), "temporary/constant_integer0d/value");

		!!!  identifier:constant_integer0d/identifier:structure::

		!!!  name:constant_integer0d/identifier/name:STR_0D:constant:
			call assertField(ids%constant_integer0d(1)%identifier%name, getString(), "temporary/constant_integer0d/identifier/name");

		!!!  index:constant_integer0d/identifier/index:INT_0D:constant:
			call assertField(ids%constant_integer0d(1)%identifier%index, getInteger(), "temporary/constant_integer0d/identifier/index");

		!!!  description:constant_integer0d/identifier/description:STR_0D:constant:
			call assertField(ids%constant_integer0d(1)%identifier%description, getString(), "temporary/constant_integer0d/identifier/description");
		end if 

		!!!  constant_string0d:constant_string0d:struct_array::
		if(.not. associated(ids%constant_string0d)) then 
			write(*,*) "ERROR! IDS: temporary Field: constant_string0d is not associated!"
 			else 

		!!!  value:constant_string0d/value:STR_0D:constant:
			call assertField(ids%constant_string0d(1)%value, getString(), "temporary/constant_string0d/value");

		!!!  identifier:constant_string0d/identifier:structure::

		!!!  name:constant_string0d/identifier/name:STR_0D:constant:
			call assertField(ids%constant_string0d(1)%identifier%name, getString(), "temporary/constant_string0d/identifier/name");

		!!!  index:constant_string0d/identifier/index:INT_0D:constant:
			call assertField(ids%constant_string0d(1)%identifier%index, getInteger(), "temporary/constant_string0d/identifier/index");

		!!!  description:constant_string0d/identifier/description:STR_0D:constant:
			call assertField(ids%constant_string0d(1)%identifier%description, getString(), "temporary/constant_string0d/identifier/description");
		end if 

		!!!  constant_integer1d:constant_integer1d:struct_array::
		if(.not. associated(ids%constant_integer1d)) then 
			write(*,*) "ERROR! IDS: temporary Field: constant_integer1d is not associated!"
 			else 

		!!!  value:constant_integer1d/value:INT_1D:constant:
			call assertField(ids%constant_integer1d(1)%value, getInteger1DArray(), "temporary/constant_integer1d/value");

		!!!  identifier:constant_integer1d/identifier:structure::

		!!!  name:constant_integer1d/identifier/name:STR_0D:constant:
			call assertField(ids%constant_integer1d(1)%identifier%name, getString(), "temporary/constant_integer1d/identifier/name");

		!!!  index:constant_integer1d/identifier/index:INT_0D:constant:
			call assertField(ids%constant_integer1d(1)%identifier%index, getInteger(), "temporary/constant_integer1d/identifier/index");

		!!!  description:constant_integer1d/identifier/description:STR_0D:constant:
			call assertField(ids%constant_integer1d(1)%identifier%description, getString(), "temporary/constant_integer1d/identifier/description");
		end if 

		!!!  constant_string1d:constant_string1d:struct_array::
		if(.not. associated(ids%constant_string1d)) then 
			write(*,*) "ERROR! IDS: temporary Field: constant_string1d is not associated!"
 			else 

		!!!  value:constant_string1d/value:STR_1D:constant:
			call assertField(ids%constant_string1d(1)%value,  getString(), "temporary/constant_string1d/value");

		!!!  identifier:constant_string1d/identifier:structure::

		!!!  name:constant_string1d/identifier/name:STR_0D:constant:
			call assertField(ids%constant_string1d(1)%identifier%name, getString(), "temporary/constant_string1d/identifier/name");

		!!!  index:constant_string1d/identifier/index:INT_0D:constant:
			call assertField(ids%constant_string1d(1)%identifier%index, getInteger(), "temporary/constant_string1d/identifier/index");

		!!!  description:constant_string1d/identifier/description:STR_0D:constant:
			call assertField(ids%constant_string1d(1)%identifier%description, getString(), "temporary/constant_string1d/identifier/description");
		end if 

		!!!  constant_float1d:constant_float1d:struct_array::
		if(.not. associated(ids%constant_float1d)) then 
			write(*,*) "ERROR! IDS: temporary Field: constant_float1d is not associated!"
 			else 

		!!!  value:constant_float1d/value:FLT_1D:constant:
			call assertField(ids%constant_float1d(1)%value, getDouble1DArray(), "temporary/constant_float1d/value");

		!!!  identifier:constant_float1d/identifier:structure::

		!!!  name:constant_float1d/identifier/name:STR_0D:constant:
			call assertField(ids%constant_float1d(1)%identifier%name, getString(), "temporary/constant_float1d/identifier/name");

		!!!  index:constant_float1d/identifier/index:INT_0D:constant:
			call assertField(ids%constant_float1d(1)%identifier%index, getInteger(), "temporary/constant_float1d/identifier/index");

		!!!  description:constant_float1d/identifier/description:STR_0D:constant:
			call assertField(ids%constant_float1d(1)%identifier%description, getString(), "temporary/constant_float1d/identifier/description");
		end if 

		!!!  dynamic_float1d:dynamic_float1d:struct_array::
		if(.not. associated(ids%dynamic_float1d)) then 
			write(*,*) "ERROR! IDS: temporary Field: dynamic_float1d is not associated!"
 			else 

		!!!  value:dynamic_float1d/value:structure::

		!!!  data:dynamic_float1d/value/data:FLT_1D:dynamic:
			call assertField(ids%dynamic_float1d(1)%value%data, getDouble1DArray(), "temporary/dynamic_float1d/value/data");

		!!!  time:dynamic_float1d/value/time:flt_1d_type:dynamic:
			call assertField(ids%dynamic_float1d(1)%value%time, getDouble1DArray(), "temporary/dynamic_float1d/value/time");

		!!!  identifier:dynamic_float1d/identifier:structure::

		!!!  name:dynamic_float1d/identifier/name:STR_0D:constant:
			call assertField(ids%dynamic_float1d(1)%identifier%name, getString(), "temporary/dynamic_float1d/identifier/name");

		!!!  index:dynamic_float1d/identifier/index:INT_0D:constant:
			call assertField(ids%dynamic_float1d(1)%identifier%index, getInteger(), "temporary/dynamic_float1d/identifier/index");

		!!!  description:dynamic_float1d/identifier/description:STR_0D:constant:
			call assertField(ids%dynamic_float1d(1)%identifier%description, getString(), "temporary/dynamic_float1d/identifier/description");
		end if 

		!!!  dynamic_string1d:dynamic_string1d:struct_array::
		if(.not. associated(ids%dynamic_string1d)) then 
			write(*,*) "ERROR! IDS: temporary Field: dynamic_string1d is not associated!"
 			else 

		!!!  value:dynamic_string1d/value:structure::

		!!!  data:dynamic_string1d/value/data:STR_1D:dynamic:
			call assertField(ids%dynamic_string1d(1)%value%data,  getString(), "temporary/dynamic_string1d/value/data");

		!!!  time:dynamic_string1d/value/time:flt_1d_type:dynamic:
			call assertField(ids%dynamic_string1d(1)%value%time, getDouble1DArray(), "temporary/dynamic_string1d/value/time");

		!!!  identifier:dynamic_string1d/identifier:structure::

		!!!  name:dynamic_string1d/identifier/name:STR_0D:constant:
			call assertField(ids%dynamic_string1d(1)%identifier%name, getString(), "temporary/dynamic_string1d/identifier/name");

		!!!  index:dynamic_string1d/identifier/index:INT_0D:constant:
			call assertField(ids%dynamic_string1d(1)%identifier%index, getInteger(), "temporary/dynamic_string1d/identifier/index");

		!!!  description:dynamic_string1d/identifier/description:STR_0D:constant:
			call assertField(ids%dynamic_string1d(1)%identifier%description, getString(), "temporary/dynamic_string1d/identifier/description");
		end if 

		!!!  dynamic_integer1d:dynamic_integer1d:struct_array::
		if(.not. associated(ids%dynamic_integer1d)) then 
			write(*,*) "ERROR! IDS: temporary Field: dynamic_integer1d is not associated!"
 			else 

		!!!  value:dynamic_integer1d/value:structure::

		!!!  data:dynamic_integer1d/value/data:INT_1D:dynamic:
			call assertField(ids%dynamic_integer1d(1)%value%data, getInteger1DArray(), "temporary/dynamic_integer1d/value/data");

		!!!  time:dynamic_integer1d/value/time:flt_1d_type:dynamic:
			call assertField(ids%dynamic_integer1d(1)%value%time, getDouble1DArray(), "temporary/dynamic_integer1d/value/time");

		!!!  identifier:dynamic_integer1d/identifier:structure::

		!!!  name:dynamic_integer1d/identifier/name:STR_0D:constant:
			call assertField(ids%dynamic_integer1d(1)%identifier%name, getString(), "temporary/dynamic_integer1d/identifier/name");

		!!!  index:dynamic_integer1d/identifier/index:INT_0D:constant:
			call assertField(ids%dynamic_integer1d(1)%identifier%index, getInteger(), "temporary/dynamic_integer1d/identifier/index");

		!!!  description:dynamic_integer1d/identifier/description:STR_0D:constant:
			call assertField(ids%dynamic_integer1d(1)%identifier%description, getString(), "temporary/dynamic_integer1d/identifier/description");
		end if 

		!!!  constant_float2d:constant_float2d:struct_array::
		if(.not. associated(ids%constant_float2d)) then 
			write(*,*) "ERROR! IDS: temporary Field: constant_float2d is not associated!"
 			else 

		!!!  value:constant_float2d/value:FLT_2D:constant:
			call assertField(ids%constant_float2d(1)%value, getDouble2DArray(), "temporary/constant_float2d/value");

		!!!  identifier:constant_float2d/identifier:structure::

		!!!  name:constant_float2d/identifier/name:STR_0D:constant:
			call assertField(ids%constant_float2d(1)%identifier%name, getString(), "temporary/constant_float2d/identifier/name");

		!!!  index:constant_float2d/identifier/index:INT_0D:constant:
			call assertField(ids%constant_float2d(1)%identifier%index, getInteger(), "temporary/constant_float2d/identifier/index");

		!!!  description:constant_float2d/identifier/description:STR_0D:constant:
			call assertField(ids%constant_float2d(1)%identifier%description, getString(), "temporary/constant_float2d/identifier/description");
		end if 

		!!!  constant_integer2d:constant_integer2d:struct_array::
		if(.not. associated(ids%constant_integer2d)) then 
			write(*,*) "ERROR! IDS: temporary Field: constant_integer2d is not associated!"
 			else 

		!!!  value:constant_integer2d/value:INT_2D:constant:
			call assertField(ids%constant_integer2d(1)%value, getInteger2DArray(), "temporary/constant_integer2d/value");

		!!!  identifier:constant_integer2d/identifier:structure::

		!!!  name:constant_integer2d/identifier/name:STR_0D:constant:
			call assertField(ids%constant_integer2d(1)%identifier%name, getString(), "temporary/constant_integer2d/identifier/name");

		!!!  index:constant_integer2d/identifier/index:INT_0D:constant:
			call assertField(ids%constant_integer2d(1)%identifier%index, getInteger(), "temporary/constant_integer2d/identifier/index");

		!!!  description:constant_integer2d/identifier/description:STR_0D:constant:
			call assertField(ids%constant_integer2d(1)%identifier%description, getString(), "temporary/constant_integer2d/identifier/description");
		end if 

		!!!  dynamic_float2d:dynamic_float2d:struct_array::
		if(.not. associated(ids%dynamic_float2d)) then 
			write(*,*) "ERROR! IDS: temporary Field: dynamic_float2d is not associated!"
 			else 

		!!!  value:dynamic_float2d/value:structure::

		!!!  data:dynamic_float2d/value/data:FLT_2D:dynamic:
			call assertField(ids%dynamic_float2d(1)%value%data, getDouble2DArray(), "temporary/dynamic_float2d/value/data");

		!!!  time:dynamic_float2d/value/time:flt_1d_type:dynamic:
			call assertField(ids%dynamic_float2d(1)%value%time, getDouble1DArray(), "temporary/dynamic_float2d/value/time");

		!!!  identifier:dynamic_float2d/identifier:structure::

		!!!  name:dynamic_float2d/identifier/name:STR_0D:constant:
			call assertField(ids%dynamic_float2d(1)%identifier%name, getString(), "temporary/dynamic_float2d/identifier/name");

		!!!  index:dynamic_float2d/identifier/index:INT_0D:constant:
			call assertField(ids%dynamic_float2d(1)%identifier%index, getInteger(), "temporary/dynamic_float2d/identifier/index");

		!!!  description:dynamic_float2d/identifier/description:STR_0D:constant:
			call assertField(ids%dynamic_float2d(1)%identifier%description, getString(), "temporary/dynamic_float2d/identifier/description");
		end if 

		!!!  dynamic_integer2d:dynamic_integer2d:struct_array::
		if(.not. associated(ids%dynamic_integer2d)) then 
			write(*,*) "ERROR! IDS: temporary Field: dynamic_integer2d is not associated!"
 			else 

		!!!  value:dynamic_integer2d/value:structure::

		!!!  data:dynamic_integer2d/value/data:INT_2D:dynamic:
			call assertField(ids%dynamic_integer2d(1)%value%data, getInteger2DArray(), "temporary/dynamic_integer2d/value/data");

		!!!  time:dynamic_integer2d/value/time:flt_1d_type:dynamic:
			call assertField(ids%dynamic_integer2d(1)%value%time, getDouble1DArray(), "temporary/dynamic_integer2d/value/time");

		!!!  identifier:dynamic_integer2d/identifier:structure::

		!!!  name:dynamic_integer2d/identifier/name:STR_0D:constant:
			call assertField(ids%dynamic_integer2d(1)%identifier%name, getString(), "temporary/dynamic_integer2d/identifier/name");

		!!!  index:dynamic_integer2d/identifier/index:INT_0D:constant:
			call assertField(ids%dynamic_integer2d(1)%identifier%index, getInteger(), "temporary/dynamic_integer2d/identifier/index");

		!!!  description:dynamic_integer2d/identifier/description:STR_0D:constant:
			call assertField(ids%dynamic_integer2d(1)%identifier%description, getString(), "temporary/dynamic_integer2d/identifier/description");
		end if 

		!!!  constant_float3d:constant_float3d:struct_array::
		if(.not. associated(ids%constant_float3d)) then 
			write(*,*) "ERROR! IDS: temporary Field: constant_float3d is not associated!"
 			else 

		!!!  value:constant_float3d/value:FLT_3D:constant:
			call assertField(ids%constant_float3d(1)%value, getDouble3DArray(), "temporary/constant_float3d/value");

		!!!  identifier:constant_float3d/identifier:structure::

		!!!  name:constant_float3d/identifier/name:STR_0D:constant:
			call assertField(ids%constant_float3d(1)%identifier%name, getString(), "temporary/constant_float3d/identifier/name");

		!!!  index:constant_float3d/identifier/index:INT_0D:constant:
			call assertField(ids%constant_float3d(1)%identifier%index, getInteger(), "temporary/constant_float3d/identifier/index");

		!!!  description:constant_float3d/identifier/description:STR_0D:constant:
			call assertField(ids%constant_float3d(1)%identifier%description, getString(), "temporary/constant_float3d/identifier/description");
		end if 

		!!!  constant_integer3d:constant_integer3d:struct_array::
		if(.not. associated(ids%constant_integer3d)) then 
			write(*,*) "ERROR! IDS: temporary Field: constant_integer3d is not associated!"
 			else 

		!!!  value:constant_integer3d/value:INT_3D:constant:
			call assertField(ids%constant_integer3d(1)%value, getInteger3DArray(), "temporary/constant_integer3d/value");

		!!!  identifier:constant_integer3d/identifier:structure::

		!!!  name:constant_integer3d/identifier/name:STR_0D:constant:
			call assertField(ids%constant_integer3d(1)%identifier%name, getString(), "temporary/constant_integer3d/identifier/name");

		!!!  index:constant_integer3d/identifier/index:INT_0D:constant:
			call assertField(ids%constant_integer3d(1)%identifier%index, getInteger(), "temporary/constant_integer3d/identifier/index");

		!!!  description:constant_integer3d/identifier/description:STR_0D:constant:
			call assertField(ids%constant_integer3d(1)%identifier%description, getString(), "temporary/constant_integer3d/identifier/description");
		end if 

		!!!  dynamic_float3d:dynamic_float3d:struct_array::
		if(.not. associated(ids%dynamic_float3d)) then 
			write(*,*) "ERROR! IDS: temporary Field: dynamic_float3d is not associated!"
 			else 

		!!!  value:dynamic_float3d/value:structure::

		!!!  data:dynamic_float3d/value/data:FLT_3D:dynamic:
			call assertField(ids%dynamic_float3d(1)%value%data, getDouble3DArray(), "temporary/dynamic_float3d/value/data");

		!!!  time:dynamic_float3d/value/time:flt_1d_type:dynamic:
			call assertField(ids%dynamic_float3d(1)%value%time, getDouble1DArray(), "temporary/dynamic_float3d/value/time");

		!!!  identifier:dynamic_float3d/identifier:structure::

		!!!  name:dynamic_float3d/identifier/name:STR_0D:constant:
			call assertField(ids%dynamic_float3d(1)%identifier%name, getString(), "temporary/dynamic_float3d/identifier/name");

		!!!  index:dynamic_float3d/identifier/index:INT_0D:constant:
			call assertField(ids%dynamic_float3d(1)%identifier%index, getInteger(), "temporary/dynamic_float3d/identifier/index");

		!!!  description:dynamic_float3d/identifier/description:STR_0D:constant:
			call assertField(ids%dynamic_float3d(1)%identifier%description, getString(), "temporary/dynamic_float3d/identifier/description");
		end if 

		!!!  dynamic_integer3d:dynamic_integer3d:struct_array::
		if(.not. associated(ids%dynamic_integer3d)) then 
			write(*,*) "ERROR! IDS: temporary Field: dynamic_integer3d is not associated!"
 			else 

		!!!  value:dynamic_integer3d/value:structure::

		!!!  data:dynamic_integer3d/value/data:INT_3D:dynamic:
			call assertField(ids%dynamic_integer3d(1)%value%data, getInteger3DArray(), "temporary/dynamic_integer3d/value/data");

		!!!  time:dynamic_integer3d/value/time:flt_1d_type:dynamic:
			call assertField(ids%dynamic_integer3d(1)%value%time, getDouble1DArray(), "temporary/dynamic_integer3d/value/time");

		!!!  identifier:dynamic_integer3d/identifier:structure::

		!!!  name:dynamic_integer3d/identifier/name:STR_0D:constant:
			call assertField(ids%dynamic_integer3d(1)%identifier%name, getString(), "temporary/dynamic_integer3d/identifier/name");

		!!!  index:dynamic_integer3d/identifier/index:INT_0D:constant:
			call assertField(ids%dynamic_integer3d(1)%identifier%index, getInteger(), "temporary/dynamic_integer3d/identifier/index");

		!!!  description:dynamic_integer3d/identifier/description:STR_0D:constant:
			call assertField(ids%dynamic_integer3d(1)%identifier%description, getString(), "temporary/dynamic_integer3d/identifier/description");
		end if 

		!!!  constant_float4d:constant_float4d:struct_array::
		if(.not. associated(ids%constant_float4d)) then 
			write(*,*) "ERROR! IDS: temporary Field: constant_float4d is not associated!"
 			else 

		!!!  value:constant_float4d/value:FLT_4D:constant:
			call assertField(ids%constant_float4d(1)%value, getDouble4DArray(), "temporary/constant_float4d/value");

		!!!  identifier:constant_float4d/identifier:structure::

		!!!  name:constant_float4d/identifier/name:STR_0D:constant:
			call assertField(ids%constant_float4d(1)%identifier%name, getString(), "temporary/constant_float4d/identifier/name");

		!!!  index:constant_float4d/identifier/index:INT_0D:constant:
			call assertField(ids%constant_float4d(1)%identifier%index, getInteger(), "temporary/constant_float4d/identifier/index");

		!!!  description:constant_float4d/identifier/description:STR_0D:constant:
			call assertField(ids%constant_float4d(1)%identifier%description, getString(), "temporary/constant_float4d/identifier/description");
		end if 

		!!!  dynamic_float4d:dynamic_float4d:struct_array::
		if(.not. associated(ids%dynamic_float4d)) then 
			write(*,*) "ERROR! IDS: temporary Field: dynamic_float4d is not associated!"
 			else 

		!!!  value:dynamic_float4d/value:structure::

		!!!  data:dynamic_float4d/value/data:FLT_4D:dynamic:
			call assertField(ids%dynamic_float4d(1)%value%data, getDouble4DArray(), "temporary/dynamic_float4d/value/data");

		!!!  time:dynamic_float4d/value/time:flt_1d_type:dynamic:
			call assertField(ids%dynamic_float4d(1)%value%time, getDouble1DArray(), "temporary/dynamic_float4d/value/time");

		!!!  identifier:dynamic_float4d/identifier:structure::

		!!!  name:dynamic_float4d/identifier/name:STR_0D:constant:
			call assertField(ids%dynamic_float4d(1)%identifier%name, getString(), "temporary/dynamic_float4d/identifier/name");

		!!!  index:dynamic_float4d/identifier/index:INT_0D:constant:
			call assertField(ids%dynamic_float4d(1)%identifier%index, getInteger(), "temporary/dynamic_float4d/identifier/index");

		!!!  description:dynamic_float4d/identifier/description:STR_0D:constant:
			call assertField(ids%dynamic_float4d(1)%identifier%description, getString(), "temporary/dynamic_float4d/identifier/description");
		end if 

		!!!  constant_float5d:constant_float5d:struct_array::
		if(.not. associated(ids%constant_float5d)) then 
			write(*,*) "ERROR! IDS: temporary Field: constant_float5d is not associated!"
 			else 

		!!!  value:constant_float5d/value:FLT_5D:constant:
			call assertField(ids%constant_float5d(1)%value, getDouble5DArray(), "temporary/constant_float5d/value");

		!!!  identifier:constant_float5d/identifier:structure::

		!!!  name:constant_float5d/identifier/name:STR_0D:constant:
			call assertField(ids%constant_float5d(1)%identifier%name, getString(), "temporary/constant_float5d/identifier/name");

		!!!  index:constant_float5d/identifier/index:INT_0D:constant:
			call assertField(ids%constant_float5d(1)%identifier%index, getInteger(), "temporary/constant_float5d/identifier/index");

		!!!  description:constant_float5d/identifier/description:STR_0D:constant:
			call assertField(ids%constant_float5d(1)%identifier%description, getString(), "temporary/constant_float5d/identifier/description");
		end if 

		!!!  dynamic_float5d:dynamic_float5d:struct_array::
		if(.not. associated(ids%dynamic_float5d)) then 
			write(*,*) "ERROR! IDS: temporary Field: dynamic_float5d is not associated!"
 			else 

		!!!  value:dynamic_float5d/value:structure::

		!!!  data:dynamic_float5d/value/data:FLT_5D:dynamic:
			call assertField(ids%dynamic_float5d(1)%value%data, getDouble5DArray(), "temporary/dynamic_float5d/value/data");

		!!!  time:dynamic_float5d/value/time:flt_1d_type:dynamic:
			call assertField(ids%dynamic_float5d(1)%value%time, getDouble1DArray(), "temporary/dynamic_float5d/value/time");

		!!!  identifier:dynamic_float5d/identifier:structure::

		!!!  name:dynamic_float5d/identifier/name:STR_0D:constant:
			call assertField(ids%dynamic_float5d(1)%identifier%name, getString(), "temporary/dynamic_float5d/identifier/name");

		!!!  index:dynamic_float5d/identifier/index:INT_0D:constant:
			call assertField(ids%dynamic_float5d(1)%identifier%index, getInteger(), "temporary/dynamic_float5d/identifier/index");

		!!!  description:dynamic_float5d/identifier/description:STR_0D:constant:
			call assertField(ids%dynamic_float5d(1)%identifier%description, getString(), "temporary/dynamic_float5d/identifier/description");
		end if 

		!!!  constant_float6d:constant_float6d:struct_array::
		if(.not. associated(ids%constant_float6d)) then 
			write(*,*) "ERROR! IDS: temporary Field: constant_float6d is not associated!"
 			else 

		!!!  value:constant_float6d/value:FLT_6D:constant:
			call assertField(ids%constant_float6d(1)%value, getDouble6DArray(), "temporary/constant_float6d/value");

		!!!  identifier:constant_float6d/identifier:structure::

		!!!  name:constant_float6d/identifier/name:STR_0D:constant:
			call assertField(ids%constant_float6d(1)%identifier%name, getString(), "temporary/constant_float6d/identifier/name");

		!!!  index:constant_float6d/identifier/index:INT_0D:constant:
			call assertField(ids%constant_float6d(1)%identifier%index, getInteger(), "temporary/constant_float6d/identifier/index");

		!!!  description:constant_float6d/identifier/description:STR_0D:constant:
			call assertField(ids%constant_float6d(1)%identifier%description, getString(), "temporary/constant_float6d/identifier/description");
		end if 

		!!!  dynamic_float6d:dynamic_float6d:struct_array::
		if(.not. associated(ids%dynamic_float6d)) then 
			write(*,*) "ERROR! IDS: temporary Field: dynamic_float6d is not associated!"
 			else 

		!!!  value:dynamic_float6d/value:structure::

		!!!  data:dynamic_float6d/value/data:FLT_6D:dynamic:
			call assertField(ids%dynamic_float6d(1)%value%data, getDouble6DArray(), "temporary/dynamic_float6d/value/data");

		!!!  time:dynamic_float6d/value/time:flt_1d_type:dynamic:
			call assertField(ids%dynamic_float6d(1)%value%time, getDouble1DArray(), "temporary/dynamic_float6d/value/time");

		!!!  identifier:dynamic_float6d/identifier:structure::

		!!!  name:dynamic_float6d/identifier/name:STR_0D:constant:
			call assertField(ids%dynamic_float6d(1)%identifier%name, getString(), "temporary/dynamic_float6d/identifier/name");

		!!!  index:dynamic_float6d/identifier/index:INT_0D:constant:
			call assertField(ids%dynamic_float6d(1)%identifier%index, getInteger(), "temporary/dynamic_float6d/identifier/index");

		!!!  description:dynamic_float6d/identifier/description:STR_0D:constant:
			call assertField(ids%dynamic_float6d(1)%identifier%description, getString(), "temporary/dynamic_float6d/identifier/description");
		end if 

		!!!  name:code/name:STR_0D:constant:
			 call assertField(ids%code%name, getString(), "temporary/code/name");

		!!!  version:code/version:STR_0D:constant:
			 call assertField(ids%code%version, getString(), "temporary/code/version");

		!!!  parameters:code/parameters:STR_0D:constant:
			 call assertField(ids%code%parameters, getString(), "temporary/code/parameters");

		!!!  output_flag:code/output_flag:INT_1D:dynamic:
			 call assertField(ids%code%output_flag, getInteger1DArray(), "temporary/code/output_flag");

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "temporary/time");
	end do 
	
END SUBROUTINE temporary_get

!==================================================================
!		 GET tf 
!==================================================================
SUBROUTINE tf_get
	CHARACTER (LEN = *), parameter :: idsName = "tf"
	TYPE (ids_tf) :: ids 
	CHARACTER (LEN=20) :: idspath 
	CHARACTER (LEN=2) :: occurence = "" 
	INTEGER :: i 
	WRITE(*,*) "Testing get() on tf"
	CALL srand(seed)
	do i = 0, 6 
		!------------
		if (i == 0) then 
			idspath = idsName  
		else
			WRITE( occurence, '(i2)' )  i 
			idspath = idsName//'/'//ADJUSTL(occurence)
		end if 
  
		call ids_get(idx, idspath, ids);

		!!!  comment:ids_properties/comment:STR_0D:constant:
			 call assertField(ids%ids_properties%comment, getString(), "tf/ids_properties/comment");

		!!!  homogeneous_time:ids_properties/homogeneous_time:INT_0D:constant:
			 call assertField(ids%ids_properties%homogeneous_time, 1, "tf/ids_properties/homogeneous_time");

		!!!  cocos:ids_properties/cocos:INT_0D:constant:
			 call assertField(ids%ids_properties%cocos, getInteger(), "tf/ids_properties/cocos");

		!!!  coil:coil:struct_array:static:
		if(.not. associated(ids%coil)) then 
			write(*,*) "ERROR! IDS: tf Field: coil is not associated!"
 			else 

		!!!  turns:coil/turns:INT_0D:static:
			call assertField(ids%coil(1)%turns, getInteger(), "tf/coil/turns");

		!!!  current:coil/current:structure::

		!!!  data:coil/current/data:FLT_1D:dynamic:
			call assertField(ids%coil(1)%current%data, getDouble1DArray(), "tf/coil/current/data");

		!!!  time:coil/current/time:flt_1d_type:dynamic:
			call assertField(ids%coil(1)%current%time, getDouble1DArray(), "tf/coil/current/time");

		!!!  voltage:coil/voltage:structure::

		!!!  data:coil/voltage/data:FLT_1D:dynamic:
			call assertField(ids%coil(1)%voltage%data, getDouble1DArray(), "tf/coil/voltage/data");

		!!!  time:coil/voltage/time:flt_1d_type:dynamic:
			call assertField(ids%coil(1)%voltage%time, getDouble1DArray(), "tf/coil/voltage/time");
		end if 

		!!!  data:b_tor_vacuum_r/data:FLT_1D:dynamic:
			 call assertField(ids%b_tor_vacuum_r%data, getDouble1DArray(), "tf/b_tor_vacuum_r/data");

		!!!  time:b_tor_vacuum_r/time:flt_1d_type:dynamic:
			 call assertField(ids%b_tor_vacuum_r%time, getDouble1DArray(), "tf/b_tor_vacuum_r/time");

		!!!  time:time:flt_1d_type:dynamic:
			 call assertField(ids%time, getDouble1DArray(), "tf/time");
	end do 
	
END SUBROUTINE tf_get

END PROGRAM test

