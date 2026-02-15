include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AzuriteExternal
AzuriteExternal_FILES = Tweak.mm
AzuriteExternal_FRAMEWORKS = UIKit Foundation CoreGraphics
AzuriteExternal_CFLAGS = -fobjc-arc -std=c++17

THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e

# Komen dulu preference bundle supaya tak error
# AzuriteExternal_PREFERENCES_BUNDLE_NAME = AzuritePrefs
# AzuriteExternal_PREFERENCES_BUNDLE_FILES = Preferences/Root.plist

include $(THEOS_MAKE_PATH)/tweak.mk
