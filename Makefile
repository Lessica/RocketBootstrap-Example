TARGET := iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = AppStore SpringBoard
ARCHS = arm64 arm64e


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = StoreAppVersionTweak

StoreAppVersionTweak_FILES = Tweak.x
StoreAppVersionTweak_CFLAGS = -fobjc-arc
StoreAppVersionTweak_LIBRARIES = rocketbootstrap
StoreAppVersionTweak_PRIVATE_FRAMEWORKS = AppSupport
include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS = storeappversiontool
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard; killall -9 appstored; killall -9 itunesstored"
