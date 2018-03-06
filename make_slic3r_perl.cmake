#this script builds slic3r (the perl command-line application, patched to accept contour files as input). If Slic3r was correctly built, this script touches a file to signal that the build was successful.
#CAVEAT: if a system-wide version of slic3r is installed, make sure that this does not run as root!!!! It may mess your system royally!!!!
set(tfile "${SLIC3RPERL_DIR}/${touchfile}")
if(NOT EXISTS ${tfile})
  execute_process(COMMAND perl Build.PL ${additional_args}
                WORKING_DIRECTORY "${SLIC3RPERL_DIR}"
                RESULT_VARIABLE res_var)
  if("${res_var}" STREQUAL "0")
    execute_process(COMMAND ${CMAKE_COMMAND} -E touch ${tfile})
  else()
    message(FATAL_ERROR "Error while trying to build Slic3r in Perl!!!!")
  endif()
else()
  message(STATUS "slic3r_perl seems to be already built; this file is already created: ${tfile}")
endif()
