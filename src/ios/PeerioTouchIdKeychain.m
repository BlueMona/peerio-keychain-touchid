#import "PeerioTouchIdKeychain.h"
#include <sys/types.h>
#include <sys/sysctl.h>


@implementation PeerioTouchIdKeychain

- (void)isFeatureAvailable: (CDVInvokedUrlCommand*)command {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.laContext = [[LAContext alloc] init];
            BOOL touchIDAvailable = [self.laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
            CDVPluginResult* pluginResult =
            [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:touchIDAvailable];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    });
}

- (void)saveValue: (CDVInvokedUrlCommand*)command {
    CFErrorRef error = NULL;
    NSString* key = (NSString*)[command.arguments objectAtIndex:0];
    NSString* value = (NSString*)[command.arguments objectAtIndex:1];
	
    // Should be the secret invalidated when passcode is removed? If not then use kSecAttrAccessibleWhenUnlocked
    SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                kSecAccessControlTouchIDAny, &error);
    if (sacObject == NULL || error != NULL) {
        NSString *errorString = [NSString stringWithFormat:@"SecItemAdd can't create sacObject: %@", error];
        CDVPluginResult* pluginResult = 
            [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: errorString];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }

    /*
        We want the operation to fail if there is an item which needs authentication so we will use
        `kSecUseNoAuthenticationUI`.
    */
    NSData *secretPasswordTextData = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *attributes = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: key,
        (__bridge id)kSecValueData: secretPasswordTextData,
        (__bridge id)kSecUseNoAuthenticationUI: @YES,
        (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
    };

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			OSStatus status = SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
			NSString *message = [NSString stringWithFormat:@"SecItemAdd status: %@", [self keychainErrorToString:status]];

            if (status == errSecSuccess) {
			    CDVPluginResult* pluginResult = 
                [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: message];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            } else {
                CDVPluginResult* pluginResult = 
                [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: message];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
    });
}

- (void)getValue: (CDVInvokedUrlCommand*)command {
    NSString* key = (NSString*)[command.arguments objectAtIndex:0];

    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: key,
        (__bridge id)kSecReturnData: @YES,
    };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFTypeRef dataTypeRef = NULL;
        NSString *message;
        
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &dataTypeRef);
        if (status == errSecSuccess) {
            NSData *resultData = (__bridge_transfer NSData *)dataTypeRef;

            NSString *result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
        
			CDVPluginResult* pluginResult = 
			[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: result];
			[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            message = [NSString stringWithFormat:@"SecItemCopyMatching status: %@", [self keychainErrorToString:status]];
            CDVPluginResult* pluginResult = 
            [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: message];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    });
}

- (void)deleteValue: (CDVInvokedUrlCommand*)command {
    NSString* key = (NSString*)[command.arguments objectAtIndex:0];
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: key
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
        NSString *errorString = [self keychainErrorToString:status];
        NSString *message = [NSString stringWithFormat:@"SecItemDelete status: %@", errorString];

        if (status == errSecSuccess) {
			CDVPluginResult* pluginResult = 
			[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: message];
			[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            CDVPluginResult* pluginResult = 
            [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: message];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    });

}

- (NSString *)keychainErrorToString:(OSStatus)error {
    NSString *message = [NSString stringWithFormat:@"%ld", (long)error];
    
    switch (error) {
        case errSecSuccess:
            message = @"success";
            break;

        case errSecDuplicateItem:
            message = @"error item already exists";
            break;
        
        case errSecItemNotFound :
            message = @"error item not found";
            break;
        
        case errSecAuthFailed:
            message = @"error item authentication failed";
            break;

        default:
            break;
    }
    
    return message;
}

@end
