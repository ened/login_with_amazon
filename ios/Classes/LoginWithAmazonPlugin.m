#import "LoginWithAmazonPlugin.h"

#import <LoginWithAmazon/LoginWithAmazon.h>

@implementation LoginWithAmazonPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"login_with_amazon"
                                     binaryMessenger:[registrar messenger]];
    LoginWithAmazonPlugin* instance = [[LoginWithAmazonPlugin alloc] init];
    [registrar addApplicationDelegate:instance];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return [AMZNAuthorizationManager
            handleOpenURL:url
            sourceApplication: options[UIApplicationOpenURLOptionsSourceApplicationKey]];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"login" isEqualToString:call.method]) {
        AMZNAuthorizeRequest *request = [[AMZNAuthorizeRequest alloc] init];
        request.scopes = [NSArray arrayWithObjects:
                          [AMZNProfileScope userID],
                          [AMZNProfileScope profile],
                          nil
                          ];
        
        [[AMZNAuthorizationManager sharedManager] authorize:request
                                                withHandler:^(AMZNAuthorizeResult *amznResult, BOOL
                                                              userDidCancel, NSError *error) {
                                                    if (error) {
                                                        result([FlutterError errorWithCode:@"login" message:@"error" details:nil]);
                                                    } else if (userDidCancel) {
                                                        result(nil);
                                                    } else {
                                                        // NSString *accessToken = amznResult.token;
                                                        AMZNUser *user = amznResult.user;

                                                        result(@{
                                                                 @"email": user.email,
                                                                 @"userId": user.userID,
                                                                 });
                                                    }
                                                }];
    } else if ([@"signOut" isEqualToString:call.method]) {
        [[AMZNAuthorizationManager sharedManager] signOut:^(NSError * _Nullable error) {
            if (error) {
                result([FlutterError errorWithCode:@"signOut" message:@"error" details:nil]);
            } else {
                result(nil);
            }
        }];
//    } else if ([@"sdkVersion" isEqualToString:call.method]) {
//        result([self sdkVersion]);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

// Currently dead code as LoginWithAmazon framework does not contain info dictionary or version information.
//- (NSString*) sdkVersion {
//    NSDictionary *infoDictionary = [[NSBundle bundleForClass: [AMZNUser class]] infoDictionary];
//
//    NSString *name = [infoDictionary valueForKey:(__bridge NSString*)kCFBundleNameKey];
//    NSString *version = [infoDictionary valueForKey:(__bridge NSString*)kCFBundleVersionKey];
//
//    return [NSString stringWithFormat:@"%@ version %@", name, version];
//}

@end
