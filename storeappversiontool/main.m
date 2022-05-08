#include <stdio.h>
#import <notify.h>

#import <Foundation/Foundation.h>
#import <rocketbootstrap/rocketbootstrap.h>


static CFMessagePortRef _serverPort = nil;

// client
static void ExecutorDidPutResponse(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    // get response from server
    const char *message = "GetResponse";
    CFDataRef reqData, respData = NULL;
    reqData = CFDataCreate(NULL, (const UInt8 *)message, strlen(message) + 1);
    
    SInt32 reqStatus =
        CFMessagePortSendRequest(
            _serverPort,
            0x1114   /* client get response */,
            reqData  /* request data */,
            1.0      /* send timeout */,
            1.0      /* recv timeout */,
            kCFRunLoopDefaultMode /* indicate a two-way message */,
            &respData             /* response data */
        );
    
    if (reqStatus == kCFMessagePortSuccess) {

        NSDictionary *responseDict = [NSPropertyListSerialization propertyListWithData:(__bridge NSData *)respData options:kNilOptions format:nil error:nil];
        printf("%s\n", [responseDict[@"reply"] UTF8String]);

        CFRelease(respData);
    }

    CFRelease(reqData);

    // one-time client, terminate
    CFRelease(_serverPort);
    exit(0);
}

int main(int argc, char *argv[], char *envp[]) {

    if (argc != 2) {
        fprintf(stderr, "usage: %s your-name\n", argv[0]);
        return 1;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _serverPort = rocketbootstrap_cfmessageportcreateremote(nil, CFSTR("com.darwindev.savt.port"));
    });

    if (!_serverPort) {
        fprintf(stderr, "no server found\n");
        return 1;
    }
    
    CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(darwin, NULL, ExecutorDidPutResponse, CFSTR("com.darwindev.savt.notify.executor_put_response"), NULL, CFNotificationSuspensionBehaviorCoalesce);

    // put arguments to server
    NSString *yourName = [NSString stringWithUTF8String:argv[1]];
    NSDictionary *argumentDict = @{@"name": yourName};

    CFDataRef argumentData = (__bridge CFDataRef)[NSPropertyListSerialization dataWithPropertyList:argumentDict format:NSPropertyListBinaryFormat_v1_0 options:kNilOptions error:nil];
    SInt32 respStatus =
        CFMessagePortSendRequest(
            _serverPort,
            0x1111   /* client put arguments */,
            argumentData,
            1.0,
            1.0,
            kCFRunLoopDefaultMode /* wait for reply */,
            NULL                  /* no return value */
        );
    
    if (respStatus != kCFMessagePortSuccess) {
        fprintf(stderr, "CFMessagePortSendRequest %d\n", respStatus);
        CFRelease(_serverPort);
        return 1;
    }

    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10.0, true);
    fprintf(stderr, "timeout\n");
    return 0;
}
