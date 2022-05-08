#import <stdio.h>
#import <notify.h>

#import <Foundation/Foundation.h>
#import <rocketbootstrap/rocketbootstrap.h>


static CFMessagePortRef _serverPort = nil;
static CFDataRef _arguments = nil;
static CFDataRef _response = nil;

static CFDataRef ServerCallback(
    CFMessagePortRef port,
    SInt32 messageID,
    CFDataRef data,
    void *info
) {

    // client put arguments
    if (messageID == 0x1111) {
        if (_arguments) {
            CFRelease(_arguments);
            _arguments = nil;
        }
        
        _arguments = CFDataCreateCopy(kCFAllocatorDefault, data);
        notify_post("com.darwindev.savt.notify.client_put_arguments");
        return nil;
    }

    // executor get arguments
    else if (messageID == 0x1112) {
        if (!_arguments)
            return nil;

        CFDataRef arguments = CFDataCreateCopy(kCFAllocatorDefault, _arguments);
        CFRelease(_arguments);
        _arguments = nil;
        return arguments;  // released by system
    }

    // executor put response
    else if (messageID == 0x1113) {
        if (_response) {
            CFRelease(_response);
            _response = nil;
        }

        _response = CFDataCreateCopy(kCFAllocatorDefault, data);
        notify_post("com.darwindev.savt.notify.executor_put_response");
        return nil;
    }

    // client get response
    else if (messageID == 0x1114) {
        if (!_response)
            return nil;

        CFDataRef response = CFDataCreateCopy(kCFAllocatorDefault, _response);
        CFRelease(_response);
        _response = nil;
        return response;  // released by system
    }

    return nil;
}

// executor
static void ClientDidPutArguments(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    // get arguments from server
    CFDataRef respData = NULL;
    SInt32 reqStatus =
        CFMessagePortSendRequest(
            _serverPort,
            0x1112   /* executor get arguments */,
            NULL     /* no request data */,
            1.0      /* send timeout */,
            1.0      /* recv timeout */,
            kCFRunLoopDefaultMode /* indicate a two-way message */,
            &respData             /* response data */
        );
    
    if (reqStatus == kCFMessagePortSuccess) {

        NSDictionary *argumentDict = [NSPropertyListSerialization propertyListWithData:(__bridge NSData *)respData options:kNilOptions format:nil error:nil];
        CFRelease(respData);
        
        NSDictionary *resultDict = nil;

        // do main stuff in executor
        resultDict = @{@"reply": [NSString stringWithFormat: @"Hello %@, I am %@.", argumentDict[@"name"], [[NSBundle mainBundle] bundleIdentifier]]};

        CFDataRef resultData = (__bridge CFDataRef)[NSPropertyListSerialization dataWithPropertyList:resultDict format:NSPropertyListBinaryFormat_v1_0 options:kNilOptions error:nil];
        SInt32 respStatus =
            CFMessagePortSendRequest(
                _serverPort,
                0x1113   /* executor put response */,
                resultData,
                1.0,
                1.0,
                kCFRunLoopDefaultMode /* wait for reply */,
                NULL                  /* no return value */
            );
        
        if (respStatus != kCFMessagePortSuccess) {
            fprintf(stderr, "CFMessagePortSendRequest %d\n", respStatus);
        }
    }
}

%ctor {
    
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleIdentifier isEqualToString:@"com.apple.springboard"]) {

        rocketbootstrap_unlock("com.darwindev.savt.port");

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _serverPort = CFMessagePortCreateLocal(
                nil,
                CFSTR("com.darwindev.savt.port"),
                ServerCallback,
                nil,
                nil
            );
        });

        CFRunLoopSourceRef runLoopSource =
            CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, _serverPort, 0);

        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            runLoopSource,
            kCFRunLoopCommonModes
        );

        rocketbootstrap_cfmessageportexposelocal(_serverPort);
    } else {

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _serverPort = rocketbootstrap_cfmessageportcreateremote(nil, CFSTR("com.darwindev.savt.port"));
        });
        // assert(_serverPort);

        if (_serverPort) {
            CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
            CFNotificationCenterAddObserver(darwin, NULL, ClientDidPutArguments, CFSTR("com.darwindev.savt.notify.client_put_arguments"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        }
    }
}
