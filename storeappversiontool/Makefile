TARGET := iphone:clang:latest:13.0
ARCHS = arm64 arm64e


include $(THEOS)/makefiles/common.mk

TOOL_NAME = storeappversiontool

storeappversiontool_FILES = main.m
storeappversiontool_CFLAGS = -fobjc-arc
storeappversiontool_LIBRARIES = rocketbootstrap
storeappversiontool_PRIVATE_FRAMEWORKS = AppSupport
storeappversiontool_CODESIGN_FLAGS = -Sentitlements.plist
storeappversiontool_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
