#import "LoginWithAmazonPlugin.h"

#import <LoginWithAmazon/LoginWithAmazon.h>

@implementation LoginWithAmazonPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"login_with_amazon"
            binaryMessenger:[registrar messenger]];
  LoginWithAmazonPlugin* instance = [[LoginWithAmazonPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
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
//                                                      NSString *accessToken = amznResult.token;
                                                      AMZNUser *user = amznResult.user;
//                                                      NSString *userID = user.userID;
                                                      
                                                      result(user.email);
                                                  }
                                              }];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
