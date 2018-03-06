CMAKE_MINIMUM_REQUIRED(VERSION 3.0) #maybe it actually requires higher, but at most 3.5...

#this has to be before the project() command
set(CMAKE_BUILD_TYPE      "Release"           CACHE STRING "Build type (release/debug) by default and for all projects with an empty generator.")

project(MAKE_ALL_TOOLS)

if(WIN32)
  set(BUILD_CORK_DEFAULT_VALUE OFF)
  #in windows, it can be difficult to have a common environment/toolchain compatible with both perl and python.
  #by default we disable perl and enable python, but it could be very well the other way around
  set(BUILD_SLIC3RPERL_DEFAULT_VALUE OFF)
  set(BUILD_PYCLIPPER_DEFAULT_VALUE ON)
  #in windows, Slic3r perl seems to be configured to use static boost libs,
  #so unless you have them also dynamically linked in the same directory, you should link statically
  set(Boost_USE_STATIC_LIBS_DEFAULT_VALUE ON)
else()
  set(BUILD_CORK_DEFAULT_VALUE ON)
  set(BUILD_SLIC3RPERL_DEFAULT_VALUE ON)
  set(BUILD_PYCLIPPER_DEFAULT_VALUE ON)
  set(Boost_USE_STATIC_LIBS_DEFAULT_VALUE OFF)
endif()

#put all binaries in a common directory (all projects)
set(ALL_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/../bin" CACHE PATH "common directory for the binaries and scripts generated from all the subprojects")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY                ${ALL_OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE        ${ALL_OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG          ${ALL_OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO ${ALL_OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL     ${ALL_OUTPUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY                ${ALL_OUTPUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE        ${ALL_OUTPUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG          ${ALL_OUTPUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${ALL_OUTPUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL     ${ALL_OUTPUT_DIR})

#subproject options and configuration
option(BUILD_MULTIRES    "build multiresolution project"         ON)
option(BUILD_SLIC3RTOOLS "build Slic3r-based command-line tools" ON)
option(BUILD_PYCLIPPER   "build pyclipper project"               ${BUILD_PYCLIPPER_DEFAULT_VALUE})
option(BUILD_CORK        "build custom cork command line tool"   ${BUILD_CORK_DEFAULT_VALUE})
option(SETUP_SLIC3RPERL  "setup slic3r (the perl application) to be compiled (but do not actually build it!)" ON)
option(BUILD_SLIC3RPERL  "build slic3r (the perl application) without sudo" ${BUILD_SLIC3RPERL_DEFAULT_VALUE})
set(SLIC3RBASE_DIR       "${ALL_OUTPUT_DIR}")
set(SLIC3RPERL_DIR       "${SLIC3RBASE_DIR}/Slic3r" CACHE PATH "directory where Slic3r will be built, if SETUP_SLIC3RPERL is specified")
set(SLIC3RPERL_TOUCHFILE slic3r_perl.built CACHE STRING "Perl Slic3r build process takes *FOREVER*, and is likely to require manual corrections. To avoid costly recompilations, if BUILD_SLIC3RPERL is specified, this file will be created after perl Slic3r is succesfully built (remove it to allow for recompilation)")
set(GENERATOR_MULTIRES    "" CACHE STRING "generator for the multiresolution subproject (in windows, works on MSVC and MINGW64)")
set(GENERATOR_SLIC3RTOOLS "" CACHE STRING "generator for the Slic3r command line tools subproject (in windows, works on MINGW64)")
set(GENERATOR_CORK_TOOL   "${CMAKE_GENERATOR}" CACHE STRING "generator for the cork command line tool subproject (in windows, works on MINGW64)")
set(BUILDTYPE_MULTIRES    ${CMAKE_BUILD_TYPE} CACHE STRING "Build type (release/debug) for multiresolution project")
set(BUILDTYPE_SLIC3RTOOLS ${CMAKE_BUILD_TYPE} CACHE STRING "Build type (release/debug) for slic3r-based command line tools")
set(BUILDTYPE_CORK        ${CMAKE_BUILD_TYPE} CACHE STRING "Build type (release/debug) for cork project")
set(REPOSITORY_MULTIRES  "https://github.com/jdfr/multiresolution.git" CACHE STRING "url of the repository for the multiresolution subproject")
set(REPOSITORY_DATATEST  "https://github.com/jdfr/data_test.git" CACHE STRING "url of the (hopefully) temporary repository for the test data")
set(REPOSITORY_CLIPPER   "https://github.com/jdfr/clipper.git"   CACHE STRING "url of the repository for the clipper subproject")
set(REPOSITORY_PYCLIPPER "https://github.com/jdfr/pyclipper.git" CACHE STRING "url of the repository for the pyclipper subproject")
set(REPOSITORY_SLIC3R    "https://github.com/jdfr/slic3r.git"    CACHE STRING "url of the repository for the slic3r subproject")
set(REPOSITORY_CORK      "https://github.com/jdfr/cork.git"      CACHE STRING "url of the repository for the cork subproject")
set(VERSION_MULTIRES  "master"     CACHE STRING "branch, tag, or commit hash to checkout from the multiresolution repository")
set(VERSION_CLIPPER   "optimized"  CACHE STRING "branch, tag, or commit hash to checkout from the clipper repository")
set(VERSION_PYCLIPPER "master"     CACHE STRING "branch, tag, or commit hash to checkout from the pyclipper repository")
set(VERSION_SLIC3R    "standalone" CACHE STRING "branch, tag, or commit hash to checkout from the slic3r repository")
set(VERSION_CORK      "master"     CACHE STRING "branch, tag, or commit hash to checkout from the cork repository")
set(VERSION_DATATEST  "master"     CACHE STRING "branch, tag, or commit hash to checkout from the test data repository")

#put this here to override the definitions on each project's config.cmake
option(Boost_USE_STATIC_LIBS "Use the static or the dynamic version of the Boost libraries" ${Boost_USE_STATIC_LIBS_DEFAULT_VALUE})

#IMPORTANT: CHECK THE INCLUDED FILES TO UNDERSTAND THE OPTIONS! SOME OPTIONS ARE DEFINED IN MORE THAN ONE SUBPROJECT
include(multiresolution/config.cmake)
include(         Slic3r/config.cmake)
include(      pyclipper/config.cmake)
include(           cork/config.cmake)

#build rules for the subprojects multiresolution and slicer
FUNCTION(BUILD_SUBPROJECT PROJECTNAME GENERATOR BUILD_TYPE ADDITIONAL_PARAMS)
  if (${GENERATOR} STREQUAL "")
    add_subdirectory(${PROJECTNAME})
  else()
    set(subdir ${CMAKE_CURRENT_BINARY_DIR}/${PROJECTNAME})
    if (NOT IS_DIRECTORY ${subdir})
      file(MAKE_DIRECTORY ${subdir})
    endif()
    execute_process(WORKING_DIRECTORY ${subdir}
                    COMMAND ${CMAKE_COMMAND} -G "${${GENERATOR}}"
      --no-warn-unused-cli #avoid warning about CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE when the generator is not MSVS
      #WE PASS LOTS OF VARIABLES TO THE SUBPROJECTS, BUT NOT ALL, BECAUSE SOME ARE GENERATOR-SPECIFIC
      #-D CMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER} 
      #-D CMAKE_OSX_ARCHITECTURES:STRING=${CMAKE_OSX_ARCHITECTURES} 
      #-D CMAKE_C_FLAGS:STRING=${CMAKE_C_FLAGS} 
      -D CMAKE_BUILD_TYPE:STRING="${${BUILD_TYPE}}"
      -D CMAKE_LIBRARY_OUTPUT_DIRECTORY=${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
      -D CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE=${CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE}
      -D CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG=${CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG}
      -D CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO=${CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO}
      -D CMAKE_LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL=${CMAKE_LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL}
      -D CMAKE_RUNTIME_OUTPUT_DIRECTORY=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
      -D CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE=${CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE}
      -D CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG=${CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG}
      -D CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO=${CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO}
      -D CMAKE_RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL=${CMAKE_RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL}
      -D BOOST_ROOT_PATH=${BOOST_ROOT_PATH}
      -D Boost_USE_STATIC_LIBS=${Boost_USE_STATIC_LIBS}
      -D ENABLE_SLICER_LOGGING:BOOL=${ENABLE_SLICER_LOGGING}
      -D CLIPPER_BASE_DIR=${CLIPPER_BASE_DIR}
      -D CLIPPER_USE_ARENA=${CLIPPER_USE_ARENA}
      -D INITIAL_ARENA_SIZE=${INITIAL_ARENA_SIZE}
      -D BIGCHUNK_ARENA_SIZE=${BIGCHUNK_ARENA_SIZE}
      ${${ADDITIONAL_PARAMS}}
      "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECTNAME}")
    add_custom_target(${PROJECTNAME} ALL 
                      COMMAND "${CMAKE_COMMAND}" --build . --config "${${BUILD_TYPE}}" #for MSVS
                      WORKING_DIRECTORY "${subdir}" VERBATIM)
  endif()
ENDFUNCTION(BUILD_SUBPROJECT)

find_program(GIT_FOUND git)

FUNCTION(PROCURE_SUBPROJECT GIT_REPOSITORY GIT_BRANCH FOLDER_NAME)
  if(NOT IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${FOLDER_NAME}")
    if(GIT_FOUND)
      execute_process(WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                      COMMAND git clone ${GIT_REPOSITORY} ${FOLDER_NAME}
                      COMMAND git checkout ${GIT_BRANCH})
    else()
      message(FATAL_ERROR "subproject in subdir ${CMAKE_CURRENT_SOURCE_DIR}/${FOLDER_NAME} not found. Also, git could not be found to clone it!")
    endif()
  endif()
ENDFUNCTION(PROCURE_SUBPROJECT)

PROCURE_SUBPROJECT(${REPOSITORY_CLIPPER} ${VERSION_CLIPPER} clipper)

if (BUILD_PYCLIPPER)
  PROCURE_SUBPROJECT(${REPOSITORY_PYCLIPPER} ${VERSION_PYCLIPPER} pyclipper)
  #as pyclipper is compiled in a Python environment, no need to fiddle with generators
  add_subdirectory(pyclipper)
endif()

if (BUILD_MULTIRES)
  if (GENERATE_TESTS)
    #these variables should be in multiresolution/config.cmake, but they cannot be set to adequate default values from an file that can be included at different levels, so they have to be defined twice: once here and once in multiresolution/CmakeLists.txt
    set(DATATEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/data_test" CACHE PATH "test STL files are fetched from this directory. It has to be an absolute path")
    set(TEST_DIR     "${ALL_OUTPUT_DIR}/test"      CACHE PATH "directory where test artifacts are output. It has to be an absolute path")
    set(TESTPREV_DIR "${ALL_OUTPUT_DIR}/testprev"  CACHE PATH "directory where test artifacts from a previous test run are preserved, to be compared with the ones created in TEST_DIR. It has to be an absolute path")
    enable_testing()
    PROCURE_SUBPROJECT(${REPOSITORY_DATATEST} ${VERSION_DATATEST} data_test)
  endif()
  PROCURE_SUBPROJECT(${REPOSITORY_MULTIRES} ${VERSION_MULTIRES} multiresolution)
  set(ADDITIONAL_PARAMS_MULTIRES
      -D COMPILE_PROGRAMOPTIONS=${COMPILE_PROGRAMOPTIONS}
      -D PYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}
      -D SHOW_RESULT_PARAMETERS=${SHOW_RESULT_PARAMETERS}
      -D INITIAL_MESH_FILE=${INITIAL_MESH_FILE}
      -D COMPILE_OPTIMIZATIONS:BOOL=${COMPILE_OPTIMIZATIONS}
      -D GENERATOR_MULTIRES_CS=${GENERATOR_MULTIRES_CS}
      -D AUTOCAD_PATH_PREFIX=${AUTOCAD_PATH_PREFIX}
      -D AUTOCAD_USECONSOLE=${AUTOCAD_USECONSOLE}
      -D DOTNET_VERSION=${DOTNET_VERSION}
      -D USE_PYTHON_VIEWER:BOOL=${USE_PYTHON_VIEWER}
      -D GENERATE_CONFIGURE_FILE:BOOL=${GENERATE_CONFIGURE_FILE}
      -D GENERATE_TESTS=${GENERATE_TESTS}
      -D DATATEST_DIR=${DATATEST_DIR}
      -D TEST_DIR=${TEST_DIR}
      -D TESTPREV_DIR=${TESTPREV_DIR}
      -D SLIC3RPERL_DIR=${SLIC3RPERL_DIR}
      -D SLIC3RPERL_TOUCHFILE=${SLIC3RPERL_TOUCHFILE}
      -D BUILD_SLIC3RPERL:BOOL=${BUILD_SLIC3RPERL}
      -D MAKEMR_LIBRARY:BOOL=${MAKEMR_LIBRARY}
      -D MAKEMR_EXECUTABLE:BOOL=${MAKEMR_EXECUTABLE}
      -D MAKEMR_CS_INTERFACE:BOOL=${MAKEMR_CS_INTERFACE}
      -D MAKEMR_CS_AUTOCAD:BOOL=${MAKEMR_CS_AUTOCAD}
      -D MAKEMR_SVGCONVERTER:BOOL=${MAKEMR_SVGCONVERTER}
      -D MAKEMR_DXFCONVERTER:BOOL=${MAKEMR_DXFCONVERTER}
      -D MAKEMR_NANOCONVERTER:BOOL=${MAKEMR_NANOCONVERTER}
      -D MAKEMR_XYZHANDLER:BOOL=${MAKEMR_XYZHANDLER}
      -D MAKEMR_TRANSFORMER:BOOL=${MAKEMR_TRANSFORMER}
      -D MAKEMR_FILEFILTER:BOOL=${MAKEMR_FILEFILTER}
      -D MAKEMR_FILEFILTERZ:BOOL=${MAKEMR_FILEFILTERZ}
      -D MAKEMR_FILESPLITTER:BOOL=${MAKEMR_FILESPLITTER}
      -D MAKEMR_FILEINFO:BOOL=${MAKEMR_FILEINFO}
      -D MAKEMR_FILEUNION:BOOL=${MAKEMR_FILEUNION}
      -D MAKEMR_FILETOUCH:BOOL=${MAKEMR_FILETOUCH})
  BUILD_SUBPROJECT(multiresolution GENERATOR_MULTIRES BUILDTYPE_MULTIRES ADDITIONAL_PARAMS_MULTIRES)
endif()

if (BUILD_SLIC3RTOOLS)
  PROCURE_SUBPROJECT(${REPOSITORY_SLIC3R} ${VERSION_SLIC3R} Slic3r)
  set(ADDITIONAL_PARAMS_SLIC3RTOOLS)
  BUILD_SUBPROJECT(Slic3r GENERATOR_SLIC3RTOOLS BUILDTYPE_SLIC3RTOOLS ADDITIONAL_PARAMS_SLIC3RTOOLS)
endif()

if (BUILD_CORK)
  PROCURE_SUBPROJECT(${REPOSITORY_CORK} ${VERSION_CORK} cork)
  #cork requires either clang or an up-to-date GCC (5.3.0 onwards). If you do not want cork, please disable BUILD_CUSTOM_CORK
  find_program(CLANG_FOUND clang)
  find_program(CLANGXX_FOUND clang++)
  set(ADDITIONAL_PARAMS_CORK_TOOL
    -D GMP_INCLUDE_DIR=${GMP_INCLUDE_DIR}
    -D GMP_LIBRARY_CXX=${GMP_LIBRARY_CXX}
    -D GMP_LIBRARY_C=${GMP_LIBRARY_C})
  if (CLANG_FOUND AND CLANGXX_FOUND)
    set(ADDITIONAL_PARAMS_CORK_TOOL ${ADDITIONAL_PARAMS_CORK_TOOL}
        -D CMAKE_C_COMPILER=${CLANG_FOUND}
        -D CMAKE_CXX_COMPILER=${CLANGXX_FOUND})
  else()
    message(WARNING "You do not have clang. Cork will be slower and use more memory!")
  endif()
  BUILD_SUBPROJECT(cork GENERATOR_CORK_TOOL BUILDTYPE_CORK ADDITIONAL_PARAMS_CORK_TOOL)
else()
  if(NOT BUILD_CUSTOM_CORK_DEFAULT_VALUE)
    if (WIN32)
      message(STATUS "FOR THIS PROJECT, CORK IS INTENDED TO BE USED ON VERY LARGE MESHES, BUT IT HAS BEEN TESTED ONLY IN LINUX, COMPILED WITH CLANG. ITS COMPILATION IS DISABLED BY DEFAULT IN WINDOWS. YOU CAN REVERT THIS DEFAULT BY SETTING EXPLICITLY BUILD_CUSTOM_CORK TO ON. HOWEVER, TO USE CORK IN WINDOWS, IT IS RECOMMENDED TO CROSS-COMPILE IT USING THE METHOD (AND THE PATCHES) DESCRIBED HERE: https://github.com/sogilis/cork/commit/b291e3dd9dffac95f14a7312e645357ccc1e5230#commitcomment-8948010 ")
    endif()
  endif()
endif()

if (SETUP_SLIC3RPERL)
  PROCURE_SUBPROJECT(${REPOSITORY_SLIC3R} ${VERSION_SLIC3R} Slic3r)
  if (NOT EXISTS "${SLIC3RPERL_DIR}")
    file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/Slic3r" DESTINATION "${SLIC3RBASE_DIR}")
    set(CLIPPER_PREFIX "${CMAKE_CURRENT_SOURCE_DIR}/clipper/clipper")
    file(COPY "${CLIPPER_PREFIX}/clipper.cpp" "${CLIPPER_PREFIX}/clipper.hpp" "${CLIPPER_PREFIX}/allocation_schemes.hpp" DESTINATION "${SLIC3RPERL_DIR}/xs/src")
    message(STATUS "Because Slic3r is built in-source, a modified copy has been placed in ${SLIC3RPERL_DIR}")
    message(STATUS "   - If you want cmake to copy it again, you'll have to remove it")
    message(STATUS "   - After compiling it, you can distribute it to other machines if")
    message(STATUS "     you package it, for example using pp:")
    message(STATUS "           pp slic3r.pl -c -o slic3r -M Method::Generate::BuildAll")
    message(STATUS "   - Slic3r requires quite a few third-party perl packages.")
    message(STATUS "     'perl Build.PL' will check if they are installed (and possibly")
    message(STATUS "     download them, even if it is not really necessary) and execute")
    message(STATUS "     all tests EVERY SINGLE TIME you try to build from a fresh copy.")
    message(STATUS "     From the Slic3r directory, you can use the following command to")
    message(STATUS "     recompile without reinstalling packages nor executing tests again:")
    message(STATUS "           cpanm -n --local-lib local-lib --reinstall --verbose ./xs")
    message(STATUS "   - Slic3r's build process may fail to install some packages, but these")
    message(STATUS "     can be easily installed by hand. For example, if the package ")
    message(STATUS "     ExtUtils::CppGuess is not successfully installed, you can install")
    message(STATUS "     it from the Slic3r directory with this command (add option --force")
    message(STATUS "     if it is safe and necessary):")
    message(STATUS "           cpanm --local-lib local-lib -i ExtUtils::CppGuess")
  endif()
  if (BUILD_SLIC3RPERL)
    find_program(PERL_EXECUTABLE_FOUND perl)
    if(PERL_EXECUTABLE_FOUND)
      add_custom_target(slic3r_perl ALL)
      add_custom_command(TARGET slic3r_perl
                         COMMAND ${CMAKE_COMMAND}
                                 -D SLIC3RPERL_DIR="${SLIC3RPERL_DIR}"
                                 -D touchfile=${SLIC3RPERL_TOUCHFILE}
                                 #-D additional_args="--xs"
                                 -D additional_args=""
                                 -P ${CMAKE_CURRENT_SOURCE_DIR}/make_slic3r_perl.cmake)
      message(STATUS "If you want to recompile Slic3r after a successfull attempt, remove the touchfile ${SLIC3RPERL_DIR}/${SLIC3RPERL_TOUCHFILE}.")
    else()
      message(WARNING "BUILD_SLIC3RPERL was ON, but no perl executable was found. Maybe you have a non-system-wide perl distro? Then, inside the proper environment (such as citrusterm.bat for CitrusPerl), you have to manually execute 'perl Build.PL' in directory ${SLIC3RPERL_DIR}")
    endif()
  else()
      message(STATUS "To build the patched version of slic3r, execute 'perl Build.PL' in the directory ${CMAKE_CURRENT_SOURCE_DIR}. You may need to manually install some dependencies")
  endif()
endif()
