function(add_mfront_behaviour_sources lib  file)
  set(mfront_file   "${CMAKE_CURRENT_SOURCE_DIR}/${file}.mfront")
  set(mfront_output1 "src/${file}.cxx")
  set(mfront_output2 "src/${file}-generic.cxx")
  if(DEFINED CONAN_LIB_DIRS_TFEL)
    # Correctly find tfel shared libs during mfront run when using a tfel
    # Conan package
    if(UNIX)
        if(APPLE)
            set(LIBRARY_PATH_ENV_VAR DYLD_LIBRARY_PATH)
        else()
            set(LIBRARY_PATH_ENV_VAR LD_LIBRARY_PATH)
        endif()
    else()
        # TODO Win eventually
    endif()
    set(CONAN_ENV_CMD ${CMAKE_COMMAND} -E env ${LIBRARY_PATH_ENV_VAR}=${CONAN_LIB_DIRS_TFEL})
  endif()
  add_custom_command(
    OUTPUT  "${mfront_output1}"
    OUTPUT  "${mfront_output2}"
    COMMAND ${CONAN_ENV_CMD} "${MFRONT}"
    ARGS    "--interface=generic"
    ARGS    "--@GenericInterfaceGenerateMTestFileOnFailure=true"
    ARGS     "${mfront_file}"
    DEPENDS "${mfront_file}"
    COMMENT "mfront source ${mfront_file}")
  set(${lib}_SOURCES ${mfront_output1} ${mfront_output2}
    ${${lib}_SOURCES} PARENT_SCOPE)
endfunction(add_mfront_behaviour_sources)

function(mfront_behaviours_check_library name)
  unset(SOURCES)    # Potentially set on the caller side.
  set ( _CMD SOURCES )
  set ( _SOURCES )
  set ( _DEPENDENCIES )
  if((TFEL_CXX_STANDARD GREATER 17) OR (TFEL_CXX_STANDARD EQUAL 17))
    set(TFEL_MFRONT_LIBRARIES
      "${TFELException};${TFELUtilities};${TFELMath};${TFELMaterial}")
  else((TFEL_CXX_STANDARD GREATER 17) OR (TFEL_CXX_STANDARD EQUAL 17))
    set(TFEL_MFRONT_LIBRARIES
      "${TFELException};${TFELUtilities};${TFELMath};${TFELMaterial};${TFELPhysicalConstants}")
  endif((TFEL_CXX_STANDARD GREATER 17) OR (TFEL_CXX_STANDARD EQUAL 17))
  foreach ( _ARG ${ARGN})
    if ( ${_ARG} MATCHES SOURCES )
      set ( _CMD SOURCES )
    elseif ( ${_ARG} MATCHES DEPENDENCIES )
      set ( _CMD DEPENDENCIES )
    else ()
      if ( ${_CMD} MATCHES SOURCES )
        list ( APPEND _SOURCES "${_ARG}" )
      elseif ( ${_CMD} MATCHES DEPENDENCIES )
        list ( APPEND _DEPENDENCIES "${_ARG}" )
      endif ()
    endif ()
  endforeach ()
  list(LENGTH _SOURCES _SOURCES_LENGTH )
  if(${_SOURCES_LENGTH} LESS 1)
    message(FATAL_ERROR "mfront_behaviours_check_library : no source specified")
  endif(${_SOURCES_LENGTH} LESS 1)
  # treating dependencies
  foreach(dep ${_DEPENDENCIES})
    add_mfront_dependency(${name} ${dep})
  endforeach(dep ${_DEPENDENCIES})
  include_directories("${TFEL_INCLUDE_PATH}")
  foreach(source ${_SOURCES})
    add_mfront_behaviour_sources(${name} ${source})
  endforeach(source ${_SOURCES})
  if(${name}_dependencies_SOURCES)
    message("dependencies : ${${name}_dependencies_SOURCES}")
  endif(${name}_dependencies_SOURCES)
  foreach(deps ${${name}_dependencies_SOURCES})
    set(${name}_SOURCES ${deps} ${${name}_SOURCES})
  endforeach(deps ${${name}_dependencies_SOURCES})
  list(LENGTH ${name}_SOURCES nb_sources)
  if(nb_sources GREATER 0)
    message(STATUS "Adding library : ${name} (${${name}_SOURCES})")
    add_library(${name} SHARED EXCLUDE_FROM_ALL ${${name}_SOURCES})
    add_dependencies(check ${name})
    target_include_directories(${name}
      PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/${interface}/include"
      PRIVATE "${TFEL_INCLUDE_PATH}")
    if(WIN32)
      if(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
	set_target_properties(${name}
	  PROPERTIES LINK_FLAGS "-Wl,--kill-at -Wl,--no-undefined")
      endif(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
    endif(WIN32)
    target_link_libraries(${name}
      PUBLIC ${TFEL_MFRONT_LIBRARIES} MTestFileGenerator)
  else(nb_sources GREATER 0)
    message(STATUS "No sources selected for library ${name}")
  endif(nb_sources GREATER 0)
endfunction(mfront_behaviours_check_library)
