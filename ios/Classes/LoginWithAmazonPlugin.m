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
        
        NSDictionary *arguments = call.arguments;
        
        NSDictionary *passedScopes = arguments[@"scopes"];
        
        NSMutableArray<AMZNScope>* scopeArray = [NSMutableArray<AMZNScope> new];
        for (NSString* key in passedScopes.allKeys) {
            if (passedScopes[@"key"] == [NSNull null]) {
                [scopeArray addObject:[AMZNScopeFactory scopeWithName:key]];
            } else {
                NSDictionary *scopeParameters = passedScopes[@"key"];
                [scopeArray addObject:[AMZNScopeFactory scopeWithName:key data:scopeParameters]];
            }
        }
        
        request.scopes = scopeArray;
        
        request.grantType = [arguments[@"grantType"] isEqualToString:@"access_token"] ? AMZNAuthorizationGrantTypeToken : AMZNAuthorizationGrantTypeCode;
        
        if (request.grantType == AMZNAuthorizationGrantTypeCode) {
            request.codeChallenge = arguments[@"codeChallenge"];
            request.codeChallengeMethod = arguments[@"codeChallengeMethod"];
        }
        
        [[AMZNAuthorizationManager sharedManager] authorize:request
                                                withHandler:^(AMZNAuthorizeResult *amznResult, BOOL
                                                              userDidCancel, NSError *error) {
                                                    if (error) {
                                                        result([FlutterError errorWithCode:@"login" message:error.localizedDescription details:error.userInfo]);
                                                    } else if (userDidCancel) {
                                                        result(nil);
                                                    } else {
                                                        NSDictionary *map = [self authorizationToMap:amznResult];
                                                        
                                                        if (self.userStreamEventSink != nil) {
                                                            self.userStreamEventSink(map[@"user"]);
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

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self.userStreamEventSink = events;
    
    [AMZNUser fetch:^(AMZNUser * _Nullable user, NSError * _Nullable error) {
        if (self.userStreamEventSink != nil) {
            if (user != nil) {
                self.userStreamEventSink([self userToMap:user]);
            } else {
                self.userStreamEventSink(nil);
            }
        }
    }];
  
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    self.userStreamEventSink = nil;
    
    return  nil;
}

- (NSDictionary*) authorizationToMap:(AMZNAuthorizeResult*)authorization {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    
    if (authorization.token) {
        [dictionary setValue:authorization.token forKey:@"accessToken"];
    }
    if (authorization.authorizationCode) {
        [dictionary setValue:authorization.authorizationCode forKey:@"authorizationCode"];
    }
    if (authorization.clientId) {
        [dictionary setValue:authorization.clientId forKey:@"clientId"];
    }
    if (authorization.redirectUri) {
        [dictionary setValue:authorization.redirectUri forKey:@"redirectURI"];
    }

    [dictionary setValue:[self userToMap:authorization.user] forKey:@"user"];

    return dictionary;
}

- (NSDictionary*) userToMap:(AMZNUser*)user {
    if (!user) {
        return @{ };
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    if (user.email) {
        [dictionary setValue:user.email forKey:@"email"];
    }
    if (user.name) {
        [dictionary setValue:user.name forKey:@"name"];
    }
    if (user.postalCode) {
        [dictionary setValue:user.postalCode forKey:@"postalCode"];
    }
    if (user.userID) {
        [dictionary setValue:user.userID forKey:@"userId"];
    }
    
    return dictionary;
}

@end
