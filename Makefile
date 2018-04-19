# Version 2.2.0

# To build a single framework use `make PROJECT/TARGET`, eg. `make NSMSyncKit/NSMSyncKit`

CONFIGURATION ?= Release
TOOLCHAIN = com.apple.dt.toolchain.Swift_4

XCRUN = /usr/bin/xcrun
XC_PRETTY = /usr/local/Cellar/gems/1.8/bin/xcpretty
JQ = /usr/local/bin/jq
SPM = /usr/bin/swift package
CARTHAGE = /usr/local/bin/carthage

SPM_CHECKOUT_PATH = .build/checkouts
SPM_EDITABLE_CHECKOUT_PATH = Packages
CARTHAGE_CHECKOUT_PATH = Carthage/Checkouts

DEPENDENCIES_CFG = Dependencies.json
DERIVED_DATA_PATH = Carthage/DerivedData
BUILD_PATH = Carthage/Build
BUILD_DIR = $(BUILD_PATH)/iOS

BITCODE_ARGS = BITCODE_GENERATION_MODE=bitcode ENABLE_BITCODE=YES
SHARED_XCODEBUILD_ARGS := \
	-configuration $(CONFIGURATION) \
	-derivedDataPath $(DERIVED_DATA_PATH) \
	-toolchain $(TOOLCHAIN) \
	CODE_SIGNING_REQUIRED=NO \
	CODE_SIGN_IDENTITY= \
	CARTHAGE=YES \
	ONLY_ACTIVE_ARCH=NO

XCODEBUILD_DEVICE_ARGS := $(SHARED_XCODEBUILD_ARGS) \
	CLANG_ENABLE_CODE_COVERAGE=NO \
	GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO \
	SKIP_INSTALL=YES \
	-sdk iphoneos \
	-archivePath "$(DERIVED_DATA_PATH)/BuiltArchives"

XCODEBUILD_SIMULATOR_ARGS := $(SHARED_XCODEBUILD_ARGS) -sdk iphonesimulator

ifneq ($(BITCODE_DISABLED),1)
	XCODEBUILD_DEVICE_ARGS += $(BITCODE_ARGS)
endif


# Temporary replacement for spaces in target names
SPACE_REPLACEMENT = @@20
LPAREN_REPLACEMENT = @@28
RPAREN_REPLACEMENT = @@29

EXPAND_SCHEMES = $(shell \
	SCHEMES=$$(cat $(DEPENDENCIES_CFG) | $(JQ) -r '.[] | select(.name == "$(1)") | (.schemes[])' | sed 's/ /$(SPACE_REPLACEMENT)/g' | sed 's/(/$(LPAREN_REPLACEMENT)/g' | sed 's/)/$(RPAREN_REPLACEMENT)/g'); \
	for SCHEME in $$SCHEMES; do \
		echo "$(1)/$${SCHEME}"; \
	done; \
)

READ_XCPROJ = $(shell cat $(DEPENDENCIES_CFG) | $(JQ) -r '.[] | select(.name == "$(1)") | (.xcproj)')
READ_TYPE = $(shell cat $(DEPENDENCIES_CFG) | $(JQ) -r '.[] | select(.name == "$(1)") | (.type)')
READ_BITCODE_DISABLED_FLAG = $(shell res=$$(cat $(DEPENDENCIES_CFG) | $(JQ) -r '.[] | select(.name == "$(1)") | (.bitcode)'); [ "$${res}" == "false" ] && echo "1" || echo "")

BINARY_DEPENDENCIES := $(shell cat $(DEPENDENCIES_CFG) | $(JQ) -r '.[] | select(.edit != true) | [.name] | (.[0])')
SOURCE_DEPENDENCIES := $(shell cat $(DEPENDENCIES_CFG) | $(JQ) -r '.[] | select(.edit == true) | [.name] | (.[0])')
BINARY_DEPENDENCY_SCHEMES := $(foreach dep,$(BINARY_DEPENDENCIES),$(call EXPAND_SCHEMES,$(dep)))
SYMLINKED_BUILD_PATHS := $(foreach dep,$(BINARY_DEPENDENCIES),$(dep)/$(BUILD_DIR)) $(foreach dep,$(SOURCE_DEPENDENCIES),$(dep)/$(BUILD_DIR))

NUM_SPM_DEPS := $(shell cat $(DEPENDENCIES_CFG) | jq -r 'map(select(.type == "spm")) | length')
NUM_CARTHAGE_DEPS := $(shell cat $(DEPENDENCIES_CFG) | jq -r 'map(select(.type == "carthage")) | length')

SPM_DEPENDENCY_IS_EDITED = $$(cat .build/dependencies-state.json | $(JQ) -r '.object.dependencies[] | select(.packageRef.name == "$(1)") | (.state) | select(.name == "edited") | (.name)');

PRINT_STEP = @echo "\n\033[00;36m$(subst ",\",$(1))\033[0m\n"
CURRENT_DIR = $(shell pwd)

define LIBRARY_CHECKOUT_PATH
$$(if [ "$(2)" == "carthage" ]; then \
	echo "$(CARTHAGE_CHECKOUT_PATH)/$(1)"; \
else \
	SUBPATH=$$(cat .build/dependencies-state.json | $(JQ) -r '.object.dependencies[] | select(.packageRef.name == "$(1)") | (.subpath)'); \
	IS_EDITED=$(call SPM_DEPENDENCY_IS_EDITED,$(1)) \
	[ -z "$${IS_EDITED}" ] && echo "$(SPM_CHECKOUT_PATH)/$${SUBPATH}" || echo "$(SPM_EDITABLE_CHECKOUT_PATH)/$${SUBPATH}"; \
fi);
endef

all: checkout $(SOURCE_DEPENDENCIES) $(SYMLINKED_BUILD_PATHS) $(BINARY_DEPENDENCY_SCHEMES)

checkout:
ifneq ($(NUM_SPM_DEPS),0)
	@$(SPM) update
endif

ifneq ($(NUM_CARTHAGE_DEPS),0)
	@$(CARTHAGE) update --no-build
endif

clean:
ifneq ($(NUM_SPM_DEPS),0)
	@$(SPM) reset
endif

	@[ -d "Packages" ] && rm -rf Packages/ || true
	@[ -d "Carthage" ] && rm -rf Carthage/ || true

test:
	@bundle exec fastlane test

$(BINARY_DEPENDENCY_SCHEMES): $(SYMLINKED_BUILD_PATHS)
	@TYPE=$(call READ_TYPE,$(@D)); \
	CHECKOUT_PATH=$(call LIBRARY_CHECKOUT_PATH,$(@D),$(call READ_TYPE,$(@D))) \
	$(MAKE) build_target \
		PROJ="$(@D)" \
		SCHEME="$$(echo $(@F) | sed 's/$(SPACE_REPLACEMENT)/ /g' | sed 's/$(LPAREN_REPLACEMENT)/(/g' | sed 's/$(RPAREN_REPLACEMENT)/)/g')" \
		XCPROJ="$(call READ_XCPROJ,$(@D))" \
		TYPE="$${TYPE}" \
		BITCODE_DISABLED="$(call READ_BITCODE_DISABLED_FLAG,$(@D))" \
		CHECKOUT_PATH="$${CHECKOUT_PATH}"

$(SOURCE_DEPENDENCIES):
	@is_edited=$(call SPM_DEPENDENCY_IS_EDITED,$@) \
	[ -z "$${is_edited}" ] && $(SPM) edit $@ || true;

$(SYMLINKED_BUILD_PATHS): $(SOURCE_DEPENDENCIES)
	@CHECKOUT_PATH=$(call LIBRARY_CHECKOUT_PATH,$(firstword $(subst /, ,$(@D))),$(call READ_TYPE,$(firstword $(subst /, ,$(@D))))) \
	if [[ -f "$${CHECKOUT_PATH}/$(DEPENDENCIES_CFG)" || -f "$${CHECKOUT_PATH}/Cartfile" ]]; then \
		[ -h "$${CHECKOUT_PATH}/Carthage/Build" ] && rm "$${CHECKOUT_PATH}/Carthage/Build" || true; \
		[ ! -d "$${CHECKOUT_PATH}/Carthage" ] && mkdir -p "$${CHECKOUT_PATH}/Carthage"; \
		ln -s "$(CURRENT_DIR)/$(BUILD_PATH)" "$${CHECKOUT_PATH}/Carthage"; \
	fi

build_target:
	@if [ -z "$(PROJ)" ]; then \
		echo "No project specified."; \
		exit 1; \
	fi;

	@if [ ! -d "$(CHECKOUT_PATH)" ]; then \
		echo "Invalid checkout path '$(CHECKOUT_PATH)' for library $(PROJ)"; \
		exit 1; \
	fi;

	@if [ -z "$(SCHEME)" ]; then \
		echo "No scheme specified for library $(PROJ)."; \
		exit 1; \
	fi;

	@if [ -z "$(XCPROJ)" ]; then \
		echo "No Xcode project defined in $(DEPENDENCIES_CFG) for library $(PROJ)."; \
		exit 1; \
	fi;

	@if [[ "$(TYPE)" != "spm" && "$(TYPE)" != "carthage" ]]; then \
		echo "Unknown type '$(TYPE)' for library $(PROJ). Must be either 'spm' (Swift Package Manager) or 'carthage'."; \
		exit 1; \
	fi;

	$(call PRINT_STEP,Building device framework for $(PROJ) ($(SCHEME))…)
	@$(XCRUN) xcodebuild -project "$(CHECKOUT_PATH)/$(XCPROJ)" -scheme "$(SCHEME)" $(XCODEBUILD_DEVICE_ARGS) archive | $(XC_PRETTY);

	$(call PRINT_STEP,Building simulator framework for $(PROJ) ($(SCHEME))…)
	@$(XCRUN) xcodebuild -project "$(CHECKOUT_PATH)/$(XCPROJ)" -scheme "$(SCHEME)" $(XCODEBUILD_SIMULATOR_ARGS) build | $(XC_PRETTY);

	$(call PRINT_STEP,Creating a universal framework for $(PROJ) ($(SCHEME))…)
	@XC_SETTINGS=$$($(XCRUN) xcodebuild \
		-project "$(CHECKOUT_PATH)/$(XCPROJ)" \
		-scheme "$(SCHEME)" \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		-showBuildSettings); \
	OBJROOT=$$(echo "$$XC_SETTINGS" | grep -m 1 OBJROOT | cut -d'=' -f2 | xargs); \
	TARGET_NAME=$$(echo "$$XC_SETTINGS" | grep -m 1 TARGET_NAME | cut -d'=' -f2 | xargs); \
	FULL_PRODUCT_NAME=$$(echo "$$XC_SETTINGS" | grep -m 1 FULL_PRODUCT_NAME | cut -d'=' -f2 | xargs); \
	EXECUTABLE_NAME=$$(echo "$$XC_SETTINGS" | grep -m 1 EXECUTABLE_NAME | cut -d'=' -f2 | xargs); \
	OS_SOURCE_PATH=$$(readlink "$${OBJROOT}/ArchiveIntermediates/$${TARGET_NAME}/BuildProductsPath/$(CONFIGURATION)-iphoneos/$${FULL_PRODUCT_NAME}"); \
	SIM_SOURCE_PATH="$(DERIVED_DATA_PATH)/Build/Products/$(CONFIGURATION)-iphonesimulator/$${FULL_PRODUCT_NAME}"; \
	TARGET_PATH="$(BUILD_DIR)/$${FULL_PRODUCT_NAME}"; \
	SWIFT_MODULE_PATH="$${SIM_SOURCE_PATH}/Modules/$${EXECUTABLE_NAME}.swiftmodule"; \
	[ -d "$${TARGET_PATH}" ] && rm -rf $${TARGET_PATH}; \
	[ ! -d "$${BUILD_DIR}" ] && mkdir -p "$(BUILD_DIR)"; \
	cp -r "$${OS_SOURCE_PATH}" "$${TARGET_PATH}"; \
	$(XCRUN) lipo -create "$${OS_SOURCE_PATH}/$${EXECUTABLE_NAME}" "$${SIM_SOURCE_PATH}/$${EXECUTABLE_NAME}" -output "$${TARGET_PATH}/$${EXECUTABLE_NAME}"; \
	if [ -d "$$SWIFT_MODULE_PATH" ]; then \
		cp -r "$${SWIFT_MODULE_PATH}/" "$${TARGET_PATH}/Modules/$${EXECUTABLE_NAME}.swiftmodule"; \
	fi;