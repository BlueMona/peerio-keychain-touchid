#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import <LocalAuthentication/LocalAuthentication.h>

@interface PeerioTouchIdKeychain : CDVPlugin {}

@property (strong, nonatomic) LAContext* laContext;

- (void) isFeatureAvailable:(CDVInvokedUrlCommand*)command;
- (void) saveValue:(CDVInvokedUrlCommand*)command;
- (void) getValue:(CDVInvokedUrlCommand*)command;
- (void) deleteValue:(CDVInvokedUrlCommand*)command;

@end
