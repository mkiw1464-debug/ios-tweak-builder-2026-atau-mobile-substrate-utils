include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AzuriteExternal
AzuriteExternal_FILES = Tweak.mm
AzuriteExternal_FRAMEWORKS = UIKit Foundation IOKit
AzuriteExternal_CFLAGS = -fobjc-arc -std=c++17

include $(THEOS_MAKE_PATH)/tweak.mk
