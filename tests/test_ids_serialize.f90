program test_ids_serialize

use ids_routines

type(ids_workflow) :: workflow
character(len=1), dimension(:), allocatable :: output

write(*,*) 'before'
allocate(workflow%ids_properties%comment(1))
workflow%ids_properties%comment(1) = 'hello world'
workflow%ids_properties%homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS
allocate(workflow%time(1))
workflow%time(1) = 3.14

write(*,*) 'serializing'
call ids_serialize(workflow, DEFAULT_SERIALIZER_PROTOCOL, output)

write(*,*) 'serialized'
call ids_deallocate(workflow)

write(*,*) output


write(*,*) 'deserializing'


end program