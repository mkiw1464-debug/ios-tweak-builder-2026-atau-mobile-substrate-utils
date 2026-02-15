include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AzuriteExternal
AzuriteExternal_FILES = Tweak.mm
AzuriteExternal_FRAMEWORKS = UIKit Foundation
AzuriteExternal_CFLAGS = -fobjc-arc

THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e

include $(THEOS_MAKE_PATH)/tweak.mk
