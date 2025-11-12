cmake_minimum_required(VERSION 3.5)

project(space2meta-speedcubing)

add_executable(space2meta-speedcubing space2meta-speedcubing.c)
target_compile_options(space2meta-speedcubing PRIVATE -Wall -Wextra -Werror)

install(TARGETS space2meta-speedcubing RUNTIME DESTINATION bin)
