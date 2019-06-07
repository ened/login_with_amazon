#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

#include <LoginWithAmazon/LoginWithAmazon.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}


-(BOOL)application:(UIApplication *)app
           openURL:(NSURL *)url
           options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return [AMZNAuthorizationManager
            handleOpenURL:url
            sourceApplication: options[UIApplicationOpenURLOptionsSourceApplicationKey]] ||
    [super application:app openURL:url options:options];
}

@end
