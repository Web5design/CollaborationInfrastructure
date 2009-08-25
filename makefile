########################################################################
# Makefile for Vrui collaboration infrastructure.
# Copyright (c) 2009 Oliver Kreylos
#
# This file is part of the WhyTools Build Environment.
# 
# The WhyTools Build Environment is free software; you can redistribute
# it and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
# 
# The WhyTools Build Environment is distributed in the hope that it will
# be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with the WhyTools Build Environment; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307 USA
########################################################################

# Define the root of the toolkit source tree
PACKAGEROOT := $(shell pwd)

# Vrui package root directory.
# NOTE: This is not the Vrui installation directory, like in most other
# makefiles for Vrui-based applications, but the directory in which Vrui
# itself was built. This is because the collaboration infrastructure is
# an extension of Vrui itself.
VRUIPACKAGEROOT := $(HOME)/src/Vrui-1.0-063

# Set this to 0 to disable Emineo support (say, if you don't have the
# required Emineo package, for instance):
COLLABORATIONCLIENT_USE_EMINEO = 0

# Emineo package root directory.
EMINEOPACKAGEROOT := $(HOME)/src/Emineo

# Include definitions for the system environment
include $(VRUIPACKAGEROOT)/BuildRoot/SystemDefinitions
include $(VRUIPACKAGEROOT)/BuildRoot/Packages

# Root directory for the software installation
# NOTE: This must be the same directory into which Vrui itself was
# installed.
INSTALLDIR = $(HOME)/Vrui-1.0

# Set this to 1 if Vrui executables and shared libraries shall contain
# links to any shared libraries they link to. This will relieve a user
# from having to set up a dynamic library search path.
USE_RPATH = 1

# This setting must match the same setting in Vrui's makefile.
GLSUPPORT_USE_TLS = 0

########################################################################
# Everything below here should not have to be changed
########################################################################

# Specify version of created dynamic shared libraries
MAJORLIBVERSION = 1
MINORLIBVERSION = 1

# Specify default optimization/debug level
ifdef DEBUG
  DEFAULTDEBUGLEVEL = 3
  DEFAULTOPTLEVEL = 0
else
  DEFAULTDEBUGLEVEL = 0
  DEFAULTOPTLEVEL = 3
endif

# Set destination directory for libraries
ifdef DEBUG
  LIBDESTDIR = $(PACKAGEROOT)/$(LIBEXT)/debug
else
  LIBDESTDIR = $(PACKAGEROOT)/$(LIBEXT)
endif

# Directories for installation components
HEADERINSTALLDIR = $(INSTALLDIR)/$(INCLUDEEXT)
ifdef DEBUG
  LIBINSTALLDIR = $(INSTALLDIR)/$(LIBEXT)/debug
  EXECUTABLEINSTALLDIR = $(INSTALLDIR)/$(BINEXT)/debug
  PLUGININSTALLDIR = $(INSTALLDIR)/$(LIBEXT)/debug
else
  LIBINSTALLDIR = $(INSTALLDIR)/$(LIBEXT)
  EXECUTABLEINSTALLDIR = $(INSTALLDIR)/$(BINEXT)
  PLUGININSTALLDIR = $(INSTALLDIR)/$(LIBEXT)
endif
ETCINSTALLDIR = $(INSTALLDIR)/etc
SHAREINSTALLDIR = $(INSTALLDIR)/share

########################################################################
# Definitions for required software packages
########################################################################

# The SPEEX speech coding library:
SPEEX_BASEDIR = /usr
SPEEX_DEPENDS = 
SPEEX_INCLUDE = 
SPEEX_LIBDIR  = 
SPEEX_LIBS    = -lspeex

# The ogg multimedia container library:
OGG_BASEDIR = /usr
OGG_DEPENDS = 
OGG_INCLUDE = 
OGG_LIBDIR  = 
OGG_LIBS    = -logg

# The Theora video codec library:
THEORA_BASEDIR = /usr
THEORA_DEPENDS = OGG
THEORA_INCLUDE = 
THEORA_LIBDIR  = 
THEORA_LIBS    = -ltheora

# Package definition for Emineo rendering architecture:
EMINEO_BASEDIR = $(EMINEOPACKAGEROOT)
EMINEO_DEPENDS = MYVRUI
EMINEO_INCLUDE = -I$(EMINEOPACKAGEROOT)/include
EMINEO_LIBDIR  = -L$(EMINEOPACKAGEROOT)/build
EMINEO_LIBS    = -lEmineoRenderer.$(LDEXT)
EMINEO_LINKLIBFLAGS = -Wl,-rpath $(EMINEOPACKAGEROOT)/build

# Package definition for Vrui collaboration infrastructure:
MYCOLLABORATION_BASEDIR     = $(PACKAGEROOT)
MYCOLLABORATION_DEPENDS     = MYVRUI THEORA SPEEX
ifneq ($(COLLABORATIONCLIENT_USE_EMINEO),0)
  MYCOLLABORATION_DEPENDS  += EMINEO
endif
MYCOLLABORATION_INCLUDE     = -I$(MYCOLLABORATION_BASEDIR)
MYCOLLABORATION_LIBDIR      = -L$(MYCOLLABORATION_BASEDIR)/$(MYLIBEXT)
MYCOLLABORATION_LIBS        = -lCollaboration.$(LDEXT)

########################################################################
# Specify additional compiler and linker flags
########################################################################

# Set flags to distinguish between static and shared libraries
ifdef STATIC_LINK
  LIBRARYNAME = $(LIBDESTDIR)/$(1).$(LDEXT).a
  OBJDIREXT = Static
else
  CFLAGS += $(CDSOFLAGS)
  LIBRARYNAME=$(LIBDESTDIR)/$(call FULLDSONAME,$(1))
endif

########################################################################
# List packages used by this project
# (Supported packages can be found in ./BuildRoot/Packages)
########################################################################

PACKAGES = 

########################################################################
# Specify all final targets
########################################################################

LIBRARIES = 
EXECUTABLES = 

#
# The only installed library:
#

LIBRARY_NAMES = libCollaboration

LIBRARIES += $(LIBRARY_NAMES:%=$(call LIBRARYNAME,%))

#
# The collaboration server test program:
#

EXECUTABLES += $(EXEDIR)/CollaborationServer

#
# The collaboration client test program:
#

EXECUTABLES += $(EXEDIR)/CollaborationClientTest

#
# The Emineo test program:
#

ifneq ($(COLLABORATIONCLIENT_USE_EMINEO),0)
  EXECUTABLES += $(EXEDIR)/EmineoTest
endif

ALL = $(LIBRARIES) $(EXECUTABLES) $(MAKEFILEFRAGMENT)

.PHONY: all
all: config $(ALL)

########################################################################
# Pseudo-target to print configuration options
########################################################################

.PHONY: config
config:
	@echo "---- Configured Vrui collaboration infrastructure options: ----"
	@echo "Vrui package root directory: $(VRUIPACKAGEROOT)"
ifneq ($(COLLABORATIONCLIENT_USE_EMINEO),0)
	@echo "3D video support (Emineo) enabled"
	@echo "Emineo package root directory: $(EMINEOPACKAGEROOT)"
else
	@echo "3D video support (Emineo) disabled"
endif
ifneq ($(GLSUPPORT_USE_TLS),0)
	@echo "Multithreaded rendering enabled"
else
	@echo "Multithreaded rendering disabled"
endif
	@echo "Installation directory: $(INSTALLDIR)"
	@echo "--------"

########################################################################
# Specify other actions to be performed on a `make clean'
########################################################################

.PHONY: extraclean
extraclean:
	-rm -f $(LIBRARY_NAMES:%=$(LIBDESTDIR)/$(call DSONAME,%))
	-rm -f $(LIBRARY_NAMES:%=$(LIBDESTDIR)/$(call LINKDSONAME,%))

.PHONY: extrasqueakyclean
extrasqueakyclean:
	-rm -f $(ALL)
	-rm -rf $(PACKAGEROOT)/$(LIBEXT)

# Include basic makefile
include $(VRUIPACKAGEROOT)/BuildRoot/BasicMakefile

########################################################################
# Specify build rules for dynamic shared objects
########################################################################

#
# Function to get the build dependencies of a package
#

DEPENDENCIES = $(patsubst -l%.$(LDEXT),$(call LIBRARYNAME,lib%),$(foreach PACKAGENAME,$(filter MY%,$($(1)_DEPENDS)),$($(PACKAGENAME)_LIBS)))

#
# The Vrui collaboration infrastructure
#

COLLABORATION_HEADERS = Collaboration/CollaborationPipe.h \
                        Collaboration/CollaborationServer.h \
                        Collaboration/CollaborationClient.h \
                        Collaboration/ProtocolServer.h \
                        Collaboration/ProtocolClient.h \
                        Collaboration/FooServer.h \
                        Collaboration/FooClient.h \
                        Collaboration/AgoraPipe.h \
                        Collaboration/AgoraServer.h \
                        Collaboration/SpeexEncoder.h \
                        Collaboration/SpeexDecoder.h \
                        Collaboration/V4L2VideoDevice.h \
                        Collaboration/TheoraWrappers.h \
                        Collaboration/AgoraClient.h \
                        Collaboration/GrapheinPipe.h \
                        Collaboration/GrapheinServer.h \
                        Collaboration/GrapheinClient.h \
                        Collaboration/EmineoPipe.h \
                        Collaboration/EmineoServer.h
ifneq ($(COLLABORATIONCLIENT_USE_EMINEO),0)
  COLLABORATION_HEADERS += Collaboration/EmineoClient.h
endif

COLLABORATION_SOURCES = Collaboration/CollaborationPipe.cpp \
                        Collaboration/CollaborationServer.cpp \
                        Collaboration/CollaborationClient.cpp \
                        Collaboration/ProtocolServer.cpp \
                        Collaboration/ProtocolClient.cpp \
                        Collaboration/FooServer.cpp \
                        Collaboration/FooClient.cpp \
                        Collaboration/AgoraPipe.cpp \
                        Collaboration/AgoraServer.cpp \
                        Collaboration/SpeexEncoder.cpp \
                        Collaboration/SpeexDecoder.cpp \
                        Collaboration/V4L2VideoDevice.cpp \
                        Collaboration/AgoraClient.cpp \
                        Collaboration/GrapheinPipe.cpp \
                        Collaboration/GrapheinServer.cpp \
                        Collaboration/GrapheinClient.cpp \
                        Collaboration/EmineoPipe.cpp \
                        Collaboration/EmineoServer.cpp
ifneq ($(COLLABORATIONCLIENT_USE_EMINEO),0)
  COLLABORATION_SOURCES += Collaboration/EmineoClient.cpp
endif

$(OBJDIR)/Collaboration/CollaborationClient.o: CFLAGS += -DCOLLABORATIONCLIENT_CONFIG_FILE='"$(ETCINSTALLDIR)/CollaborationClient.cfg"'

$(call LIBRARYNAME,libCollaboration): PACKAGES += $(MYCOLLABORATION_DEPENDS)
$(call LIBRARYNAME,libCollaboration): EXTRACINCLUDEFLAGS += $(MYCOLLABORATION_INCLUDE)
$(call LIBRARYNAME,libCollaboration): $(COLLABORATION_SOURCES:%.cpp=$(OBJDIR)/%.o)
.PHONY: libCollaboration
libCollaboration: $(call LIBRARYNAME,libCollaboration)

#
# The collaboration server test program:
#

$(EXEDIR)/CollaborationServer: PACKAGES += MYCOLLABORATION
$(EXEDIR)/CollaborationServer: $(call LIBRARYNAME,libCollaboration)
$(EXEDIR)/CollaborationServer: $(OBJDIR)/CollaborationServerMain.o
.PHONY: CollaborationServer
CollaborationServer: $(EXEDIR)/CollaborationServer

#
# The collaboration client test program:
#

ifneq ($(COLLABORATIONCLIENT_USE_EMINEO),0)
  $(OBJDIR)/CollaborationClientTest.o: CFLAGS += -DCOLLABORATIONCLIENT_USE_EMINEO
endif

$(EXEDIR)/CollaborationClientTest: PACKAGES += MYCOLLABORATION
$(EXEDIR)/CollaborationClientTest: $(call LIBRARYNAME,libCollaboration)
$(EXEDIR)/CollaborationClientTest: $(OBJDIR)/CollaborationClientTest.o
.PHONY: CollaborationClientTest
CollaborationClientTest: $(EXEDIR)/CollaborationClientTest

#
# The Emineo test program:
#

$(EXEDIR)/EmineoTest: PACKAGES += EMINEO
$(EXEDIR)/EmineoTest: $(OBJDIR)/EmineoTest.o
.PHONY: EmineoTest
EmineoTest: $(EXEDIR)/EmineoTest

########################################################################
# Specify installation rules for header files, libraries, executables,
# configuration files, and shared files.
########################################################################

# Sequence to create symlinks for dynamic libraries:
# First argument: library name
define CREATE_SYMLINK
@-rm -f $(LIBINSTALLDIR)/$(call DSONAME,$(1)) $(LIBINSTALLDIR)/$(call LINKDSONAME,$(1))
@cd $(LIBINSTALLDIR) ; ln -s $(call FULLDSONAME,$(1)) $(call DSONAME,$(1))
@cd $(LIBINSTALLDIR) ; ln -s $(call FULLDSONAME,$(1)) $(call LINKDSONAME,$(1))

endef

install: all
# Install all header files in HEADERINSTALLDIR:
	@echo Installing header files...
	@install -d $(HEADERINSTALLDIR)/Collaboration
	@install -m u=rw,go=r $(COLLABORATION_HEADERS) $(HEADERINSTALLDIR)/Collaboration
# Install all library files in LIBINSTALLDIR:
	@echo Installing libraries...
	@install -d $(LIBINSTALLDIR)
	@install $(LIBRARIES) $(LIBINSTALLDIR)
	@echo Configuring run-time linker...
	$(foreach LIBNAME,$(LIBRARY_NAMES),$(call CREATE_SYMLINK,$(LIBNAME)))
# Install all binaries in EXECUTABLEINSTALLDIR:
	@echo Installing executables...
	@install -d $(EXECUTABLEINSTALLDIR)
	@install $(EXECUTABLES) $(EXECUTABLEINSTALLDIR)
# Install all configuration files in ETCINSTALLDIR:
	@echo Installing configuration files...
	@install -d $(ETCINSTALLDIR)
	@install -m u=rw,go=r share/* $(ETCINSTALLDIR)
