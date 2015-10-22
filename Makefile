

ifeq ($(OS),Windows_NT)

# for Windows
include Makefile.windows

else

UNAME=${shell uname}

ifeq ($(UNAME),Linux)

# for Linux
include Makefile.linux

endif

ifeq ($(UNAME),Darwin)

# for Linux
include Makefile.darwin

endif

endif
