################################################################################
# \file CY8CKIT-064S0S2-4343W.mk
#
# \brief
# Define the CY8CKIT-064S0S2-4343W target.
#
################################################################################
# \copyright
# Copyright 2018-2021 Cypress Semiconductor Corporation
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

ifeq ($(WHICHFILE),true)
$(info Processing $(lastword $(MAKEFILE_LIST)))
endif

# Set the default build recipe for this board if not set by the user
include $(dir $(lastword $(MAKEFILE_LIST)))/locate_recipe.mk

# MCU device selection
#    Changing the device should be done using “make bsp” or “make update_bsp” with the “DEVICE_GEN”
#    variable set to the new MCU. If you change the device manually here you must also update the
#    design.modus file and re-run the device configurator.
DEVICE:=CYS0644ABZI-S2D44
# Additional devices on the board
#    If you change the additional device here you must also update the design.modus file and re-run
#    the device configurator. You may also need to update the COMPONENT variable to include the
#    correct Wi-Fi and Bluetooth firmware.
ADDITIONAL_DEVICES:=CYW4343WKUBG
# Default target core to CM4 if not already set
CORE?=CM4
# Basic architecture specific components
COMPONENTS+=$(TARGET) CAT1 CAT1A
# Define default type of bootloading method [single, dual]
# single -> CM4 only, multi -> CM0 and CM4
SECURE_BOOT_STAGE?=single

# Python path definition
CY_PYTHON_REQUIREMENT=true

# This only needs to run in the second stage where the CY_PYTHON_PATH gets defined
ifneq ($(CY_PYTHON_PATH),)
CY_SECURE_TOOLS_MAJOR_VERSION=$(word 1, $(subst ., ,$(filter-out , \
							  $(subst cysecuretools==, , \
							  $(shell $(CY_PYTHON_PATH) -m pip freeze | grep cysecuretools)))))
endif

ifeq ($(CORE),CM4)
# Additional components supported by the target
COMPONENTS+=BSP_DESIGN_MODUS PSOC6HAL 4343W WLBGA
#Add secure CM0P image in single stage
ifeq ($(SECURE_BOOT_STAGE), single)
COMPONENTS+=CM0P_SECURE
endif

# Use CyHAL
DEFINES+=CY_USING_HAL

ifeq ($(SECURE_BOOT_STAGE),single)
CY_LINKERSCRIPT_SUFFIX=cm4_dual
else
CY_LINKERSCRIPT_SUFFIX=cm4
endif

# If cysecuretools is less than 3.0.0
ifneq ($(strip $(filter 2 1 0,$(CY_SECURE_TOOLS_MAJOR_VERSION))),)
ifeq ($(SECURE_BOOT_STAGE),single)
CY_SECURE_POLICY_NAME?=policy_single_CM0_CM4
else
CY_SECURE_POLICY_NAME?=policy_multi_CM0_CM4
endif
else
ifeq ($(SECURE_BOOT_STAGE),single)
CY_SECURE_POLICY_NAME?=policy_single_CM0_CM4_swap
else
CY_SECURE_POLICY_NAME?=policy_multi_CM0_CM4_swap
endif
endif

# CM0p
else

ifneq ($(strip $(filter 2 1 0,$(CY_SECURE_TOOLS_MAJOR_VERSION))),)
CY_SECURE_POLICY_NAME?=policy_multi_CM0_CM4
else
CY_SECURE_POLICY_NAME?=policy_multi_CM0_CM4_swap
endif

endif

#Define the toolchain path
ifeq ($(TOOLCHAIN),ARM)
TOOLCHAIN_PATH=$(CY_COMPILER_ARM_DIR)
else
TOOLCHAIN_PATH=$(CY_COMPILER_GCC_ARM_DIR)
endif

# Check if CM0P Library exists
POST_BUILD_CM0_LIB_PATH=$(call CY_MACRO_FINDLIB,psoc6cm0p)
ifeq ($(POST_BUILD_CM0_LIB_PATH), NotPresent)
# Backward compatibility, try hard-coded paths instead
POST_BUILD_CM0_LIB_PATH=$(CY_INTERNAL_APPLOC)/libs/psoc6cm0p/COMPONENT_CM0P_SECURE
endif

# Check if Target BSP Library exists
POST_BUILD_BSP_LIB_PATH_INTERNAL=$(call CY_MACRO_FINDLIB,TARGET_CY8CKIT-064S0S2-4343W)
ifeq ($(POST_BUILD_BSP_LIB_PATH_INTERNAL), NotPresent)
# Backward compatibility, try hard-coded paths instead
POST_BUILD_BSP_LIB_PATH_INTERNAL=$(CY_TARGET_DIR)
endif

ifeq ($(OS),Windows_NT)
ifneq ($(CY_WHICH_CYGPATH),)
POST_BUILD_BSP_LIB_PATH=$(shell cygpath -m --absolute $(POST_BUILD_BSP_LIB_PATH_INTERNAL))
else
POST_BUILD_BSP_LIB_PATH=$(abspath $(POST_BUILD_BSP_LIB_PATH_INTERNAL))
endif
else
POST_BUILD_BSP_LIB_PATH=$(abspath $(POST_BUILD_BSP_LIB_PATH_INTERNAL))
endif

# BSP-specific post-build action
CY_BSP_POSTBUILD=$(CY_PYTHON_PATH) $(POST_BUILD_BSP_LIB_PATH)/psoc64_postbuild.py \
				--core $(CORE) \
				--secure-boot-stage $(SECURE_BOOT_STAGE) \
				--policy $(CY_SECURE_POLICY_NAME) \
				--target cys06xxa \
				--toolchain-path $(TOOLCHAIN_PATH) \
				--toolchain $(TOOLCHAIN) \
				--build-dir $(CY_CONFIG_DIR) \
				--app-name $(APPNAME) \
				--cm0-app-path $(POST_BUILD_CM0_LIB_PATH) \
				--cm0-app-name psoc6_02_cm0p_secure
