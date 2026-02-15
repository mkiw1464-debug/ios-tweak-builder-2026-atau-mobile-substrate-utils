include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AzuriteExternal
AzuriteExternal_FILES = Tweak.mm
AzuriteExternal_FRAMEWORKS = UIKit Foundation IOKit CoreGraphics
AzuriteExternal_CFLAGS = -fobjc-arc -std=c++17

# PreferenceLoader settings bundle
AzuriteExternal_PREFERENCES_BUNDLE_NAME = AzuritePrefs
AzuriteExternal_PREFERENCES_BUNDLE_FILES = Preferences/Root.plist

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk
