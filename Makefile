include $(THEOS)/makefiles/common.mk

export TARGET = iphone:latest:14.0   # hilangkan warning arm64e

TWEAK_NAME = AzuriteExternal
AzuriteExternal_FILES = Tweak.mm
AzuriteExternal_FRAMEWORKS = UIKit Foundation
AzuriteExternal_CFLAGS = -fobjc-arc

THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e

include $(THEOS_MAKE_PATH)/tweak.mk
