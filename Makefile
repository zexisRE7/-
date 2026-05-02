export THEOS_DEVICE_IP    ?= localhost
export THEOS_DEVICE_PORT  ?= 2222

ARCHS     = arm64 arm64e
TARGET    = iphone:clang:16.5:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CheatMenu

CheatMenu_FILES        = tweak.xm menu.m
CheatMenu_CFLAGS       = -fobjc-arc
CheatMenu_FRAMEWORKS   = UIKit CoreGraphics QuartzCore Foundation
CheatMenu_PRIVATE_FRAMEWORKS =
CheatMenu_LIBRARIES    =

# Filter to the game bundle — change to your target app bundle ID
BUNDLE_FILTER = com.activision.codm

after-install::
	install.exec "killall -9 SpringBoard"

include $(THEOS)/makefiles/tweak.mk
