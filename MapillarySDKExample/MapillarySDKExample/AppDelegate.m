//
//  AppDelegate.m
//  MapillarySDKExample
//
//  Created by Anders Mårtensson on 2017-10-30.
//  Copyright © 2017 com.mapillary.sdk.example. All rights reserved.
//

#import "AppDelegate.h"
#import <MapillarySDK/MapillarySDK.h>
#import <AWSS3/AWSS3.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return [MAPApplicationDelegate application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [MAPApplicationDelegate application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{    
    [AWSS3TransferUtility interceptApplication:application handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
}

@end
