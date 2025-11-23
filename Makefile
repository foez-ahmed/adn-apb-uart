
####################################################################################################
# Directory Setup
####################################################################################################

ROOT_DIR  := ${CURDIR}
BUILD_DIR := ${ROOT_DIR}/build
LOG_DIR   := ${ROOT_DIR}/log
INC_DIR   := ${ROOT_DIR}/inc
PKG_DIR   := ${ROOT_DIR}/pkg
RTL_DIR   := ${ROOT_DIR}/rtl
TB_DIR    := ${ROOT_DIR}/tb

####################################################################################################
# Tool Setup
####################################################################################################

MAKE	?= make

XVLOG ?= xvlog
XVHDL ?= xvhdl
XELAB ?= xelab
XSIM  ?= xsim

#####################################################################################################
# Targets
#####################################################################################################

${BUILD_DIR}:
	@echo "Creating build directory at ${BUILD_DIR}"
	@mkdir -p ${BUILD_DIR}
	@echo "*" > ${BUILD_DIR}/.gitignore

${LOG_DIR}:
	@echo "Creating log directory at ${LOG_DIR}"
	@mkdir -p ${LOG_DIR}
	@echo "*" > ${LOG_DIR}/.gitignore

.PHONY: clean
clean:
	@echo "Cleaning build directory at ${BUILD_DIR}"
	@rm -rf ${BUILD_DIR}

.PHONY: clean_full
clean_full:
	@${MAKE} -s clean
	@echo "Cleaning log directory at ${LOG_DIR}"
	@rm -rf ${LOG_DIR}

.PHONY: simulate
simulate:
	@${MAKE} -s ${BUILD_DIR}
	@${MAKE} -s ${LOG_DIR}
	@$(eval TIME := $(shell date +%Y%m%d_%H%M%S))
	@cd ${BUILD_DIR} && ${XVLOG} -sv ${FILE_LIST} --log ${LOG_DIR}/vlog_$(TIME).log
	@cd ${BUILD_DIR} && ${XELAB} ${TOP_MODULE} -s ${TOP_MODULE} --log ${LOG_DIR}/xelab_$(TIME).log
	@cd ${BUILD_DIR} && ${XSIM} ${TOP_MODULE} -runall --log ${LOG_DIR}/xsim_$(TIME).log
