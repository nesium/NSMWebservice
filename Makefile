# Version 1.0.0

# To build a single framework use `make NSMSyncKit.framework` (`edit` property must not be true).

CONFIGURATION = Release

CURRENT_DIR = $(shell pwd)

SPM_CHECKOUT_PATH = .build/checkouts
SPM_EDITABLE_CHECKOUT_PATH = Packages
CARTHAGE_CHECKOUT_PATH = Carthage/Checkouts
DERIVED_DATA_PATH = Carthage/DerivedData
BUILD_PATH = Carthage/Build
BUILD_DIR = $(BUILD_PATH)/iOS

TOOLCHAIN = com.apple.dt.toolchain.Swift_4
XCRUN = /usr/bin/xcrun
XC_PRETTY = /usr/local/Cellar/gems/1.8/bin/xcpretty
JQ = /usr/local/bin/jq
SPM = /usr/bin/swift package
CARTHAGE = /usr/local/bin/carthage

DEPENDENCIES_CFG = Dependencies.json

BINARY_DEPENDENCIES = $(shell cat $(DEPENDENCIES_CFG) | $(JQ) -r '.[] | select(.edit != true) | [.name] | map(. + ".framework") | (.[0])')
SOURCE_DEPENDENCIES = $(shell cat $(DEPENDENCIES_CFG) | $(JQ) -r '.[] | select(.edit == true) | [.name] | map(. + ".source") | (.[0])')

NUM_SPM_DEPS = $(shell cat $(DEPENDENCIES_CFG) | jq -r 'map(select(.type == "spm")) | length')
NUM_CARTHAGE_DEPS = $(shell cat $(DEPENDENCIES_CFG) | jq -r 'map(select(.type == "carthage")) | length')

all: checkout build_frameworks

clean:
ifneq ($(NUM_SPM_DEPS),0)
	@$(SPM) reset
endif

	@[ -d "Packages" ] && rm -rf Packages/ || true
	@[ -d "Carthage" ] && rm -rf Carthage/ || true

test:
	@bundle exec fastlane test

build_frameworks: checkout $(BINARY_DEPENDENCIES) $(SOURCE_DEPENDENCIES)

checkout:
ifneq ($(NUM_SPM_DEPS),0)
	@$(SPM) update
endif

ifneq ($(NUM_CARTHAGE_DEPS),0)
	@$(CARTHAGE) update --no-build
endif

%.framework:
	$(eval lib = $(basename $*))
	$(eval schemes = $(shell cat $(DEPENDENCIES_CFG) | $(JQ) -r '.[] | select(.name == "$(lib)") | (.schemes[])')) \
	$(eval xcproj = $(shell cat $(DEPENDENCIES_CFG) | $(JQ) -r '.[] | select(.name == "$(lib)") | (.xcproj)')) \
	$(eval type = $(shell cat $(DEPENDENCIES_CFG) | $(JQ) -r '.[] | select(.name == "$(lib)") | (.type)')) 
	$(eval bitcode_disabled = $(shell res=$$(cat $(DEPENDENCIES_CFG) | $(JQ) -r '.[] | select(.name == "$(lib)") | (.bitcode)'); [ "$${res}" == "false" ] && echo "1" || echo ""))

	@if [ -z "$(schemes)" ]; then \
		echo "No Schemes defined in $(DEPENDENCIES_CFG) for target $(lib)."; \
		exit 1; \
	fi;

	@if [ -z "$(xcproj)" ]; then \
		echo "No xcproj defined in $(DEPENDENCIES_CFG) for target $(lib)."; \
		exit 1; \
	fi;

	@if [[ "$(type)" != "spm" && "$(type)" != "carthage" ]]; then \
		echo "Unknown type '$(type)' for target $(lib). Must be either 'spm' (Swift Package Manager) or 'carthage'."; \
		exit 1; \
	fi;

	$(eval subpath = $(shell $(call checkout_path_for_lib,$(lib),$(type))))
	$(call link_build_dir,$(subpath))
	$(foreach scheme,$(schemes),$(call build_fat_framework,$(subpath),$(xcproj),$(scheme),$(CONFIGURATION),$(bitcode_disabled)))

%.source:
	$(eval lib = $(basename $*))
	$(call make_lib_editable,$(lib))
	

.PHONY: checkout build_frameworks clean test

define build_fat_framework
	$(call build_device_framework,$(1),$(2),$(3),$(4),$(5))
	$(call build_simulator_framework,$(1),$(2),$(3),$(4),$(5))
	$(call merge_frameworks,$(1),$(2),$(3),$(4),$(5))
endef

define link_build_dir
	@if [[ -f "$(1)/$(DEPENDENCIES_CFG)" || -f "$(1)/Cartfile" ]]; then \
		[ -h "$(1)/Carthage/Build" ] && rm "$(1)/Carthage/Build" || true; \
		[ ! -d "$(1)/Carthage" ] && mkdir -p "$(1)/Carthage"; \
		ln -s "$(CURRENT_DIR)/$(BUILD_PATH)" "$(1)/Carthage"; \
	fi
endef

define make_lib_editable
	@is_edited=$$(cat .build/dependencies-state.json | $(JQ) -r '.object.dependencies[] | select(.name == "$(1)") | (.state) | select(.name == "edited") | (.name)'); \
	[ -z "$${is_edited}" ] && $(SPM) edit $(lib) || true;
endef

define checkout_path_for_lib
	if [ "$(2)" == "carthage" ]; then \
		echo "$(CARTHAGE_CHECKOUT_PATH)/$(1)"; \
	else \
		subpath=$$(cat .build/dependencies-state.json | $(JQ) -r '.object.dependencies[] | select(.name == "$(1)") | (.subpath)'); \
		is_edited=$$(cat $(DEPENDENCIES_CFG) | $(JQ) -r '.[] | select(.name == "$(lib)") | select(.edit == true) | (.edit)'); \
		[ -z "$${is_edited}" ] && echo "$(SPM_CHECKOUT_PATH)/$${subpath}" || echo "$(SPM_EDITABLE_CHECKOUT_PATH)/$${subpath}"; \
	fi
endef

define merge_frameworks
	@echo "Creating a universal framework for $(2) ($3)…";

	@xcsettings=$$($(XCRUN) xcodebuild \
		-project "$(1)/$(2)" \
		-scheme "$(3)" \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		-showBuildSettings); \
	OBJROOT=$$(echo "$$xcsettings" | grep -m 1 OBJROOT | cut -d'=' -f2 | xargs); \
	TARGET_NAME=$$(echo "$$xcsettings" | grep -m 1 TARGET_NAME | cut -d'=' -f2 | xargs); \
	FULL_PRODUCT_NAME=$$(echo "$$xcsettings" | grep -m 1 FULL_PRODUCT_NAME | cut -d'=' -f2 | xargs); \
	EXECUTABLE_NAME=$$(echo "$$xcsettings" | grep -m 1 EXECUTABLE_NAME | cut -d'=' -f2 | xargs); \
	OS_SOURCE_PATH=$$(readlink "$${OBJROOT}/ArchiveIntermediates/$${TARGET_NAME}/BuildProductsPath/$(4)-iphoneos/$${FULL_PRODUCT_NAME}"); \
	SIM_SOURCE_PATH="$(DERIVED_DATA_PATH)/Build/Products/$(4)-iphonesimulator/$${FULL_PRODUCT_NAME}"; \
	TARGET_PATH="$(BUILD_DIR)/$${FULL_PRODUCT_NAME}"; \
	SWIFT_MODULE_PATH="$${SIM_SOURCE_PATH}/Modules/$${EXECUTABLE_NAME}.swiftmodule"; \
	[ -d "$${TARGET_PATH}" ] && rm -rf $${TARGET_PATH}; \
	[ ! -d "$${BUILD_DIR}" ] && mkdir -p "$(BUILD_DIR)"; \
	echo "Copying $${OS_SOURCE_PATH} to $${TARGET_PATH}"; \
	cp -r "$${OS_SOURCE_PATH}" "$${TARGET_PATH}"; \
	$(XCRUN) lipo -create "$${OS_SOURCE_PATH}/$${EXECUTABLE_NAME}" "$${SIM_SOURCE_PATH}/$${EXECUTABLE_NAME}" -output "$${TARGET_PATH}/$${EXECUTABLE_NAME}"; \
	if [ -d "$$SWIFT_MODULE_PATH" ]; then \
		cp -r "$${SWIFT_MODULE_PATH}/" "$${TARGET_PATH}/Modules/$${EXECUTABLE_NAME}.swiftmodule"; \
	fi;

endef

define build_device_framework
	@echo "Building device framework for $(2) ($3)…";

	@params="-project $(1)/$(2) \
		-scheme $(3) \
		-configuration $(4) \
		-sdk iphoneos \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		-toolchain $(TOOLCHAIN) \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGN_IDENTITY= \
		CARTHAGE=YES \
		ONLY_ACTIVE_ARCH=NO \
		CLANG_ENABLE_CODE_COVERAGE=NO \
		GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO \
		SKIP_INSTALL=YES \
		-archivePath $(DERIVED_DATA_PATH)/BuiltArchives"; \
	[ -z "$(5)" ] && params="$${params} BITCODE_GENERATION_MODE=bitcode ENABLE_BITCODE=YES"; \
	$(XCRUN) xcodebuild $$params archive | $(XC_PRETTY);

endef

define build_simulator_framework
	@echo "Building simulator framework for $(2) ($3)…";

	@$(XCRUN) xcodebuild \
		-project "$(1)/$(2)" \
		-scheme "$(3)" \
		-configuration "$(4)" \
		-sdk iphonesimulator \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		-toolchain $(TOOLCHAIN) \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGN_IDENTITY= \
		CARTHAGE=YES \
		ONLY_ACTIVE_ARCH=NO \
		build \
		| $(XC_PRETTY);

endef