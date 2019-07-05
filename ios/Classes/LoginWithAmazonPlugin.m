#import "LoginWithAmazonPlugin.h"


#import <LoginWithAmazon/LoginWithAmazon.h>

@interface LoginWithAmazonPlugin ()
@property (nonatomic) FlutterEventSink userStreamEventSink;
@end

@implementation LoginWithAmazonPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    LoginWithAmazonPlugin* instance = [[LoginWithAmazonPlugin alloc] init];

    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"com.github.ened/login_with_amazon"
                                     binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterEventChannel *userChannel = [FlutterEventChannel
                                        eventChannelWithName:@"com.github.ened/login_with_amazon/user"
                                        binaryMessenger:[registrar messenger]];
    [userChannel setStreamHandler:instance];
    
    [registrar addApplicationDelegate:instance];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return [AMZNAuthorizationManager
            handleOpenURL:url
            sourceApplication: options[UIApplicationOpenURLOptionsSourceApplicationKey]];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if([@"version" isEqualToString:call.method]) {
        result(AMZNLWASDKInfo.sdkVersion);
    } else if ([@"login" isEqualToString:call.method]) {
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
                                                        NSDictionary *map = [self userToMap:amznResult.user];
                                                        
                                                        if (self.userStreamEventSink != nil) {
                                                            self.userStreamEventSink(map);
                                                        }

                                                        result(map);
                                                    }
                                                }];
    } else if ([@"signOut" isEqualToString:call.method]) {
        [[AMZNAuthorizationManager sharedManager] signOut:^(NSError * _Nullable error) {
            if (error) {
                result([FlutterError errorWithCode:@"signOut" message:@"error" details:nil]);
            } else {
                if (self.userStreamEventSink != nil) {
                    self.userStreamEventSink(nil);
                }

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

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self.userStreamEventSink = events;
    
    [AMZNUser fetch:^(AMZNUser * _Nullable user, NSError * _Nullable error) {
        if (user != nil) {
            self.userStreamEventSink([self userToMap:user]);
        } else {
            self.userStreamEventSink(nil);
        }
    }];
  
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    self.userStreamEventSink = nil;
    
    return  nil;
}

- (NSDictionary*) userToMap:(AMZNUser*)user {
    return @{
             @"email": user.email,
             @"userId": user.userID,
             };
}

@end
