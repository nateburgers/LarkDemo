//
//  SDAppDelegate.m
//  SnarkDemo
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import "SDAppDelegate.h"
#import "SDREPLServer.h"
#import "SNExt.h"
#import "SNEval.h"
#import "SDFunViewController.h"
#import "SDFunView.h"

@implementation SDAppDelegate

- (void)loadScripts
{
    NSString *mainURL = [[NSBundle mainBundle] pathForResource:@"main" ofType:@"scm"];
    NSString *mainString = [NSString stringWithContentsOfFile:mainURL encoding:NSUTF8StringEncoding error:nil];
    SNParseResult *parseResult = [SNExt symbolicExpression]([SNExt stringToArray:mainString])[0];
    NSMutableDictionary *env = [[SNEval prelude] mutableCopy];
    [SNEval evaluate:[parseResult result] inContext:env];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

//    [self loadScripts];
    [self setViewController:[[SDFunViewController alloc] init]];
    [self.window setRootViewController:[self viewController]];
    [[self viewController] start];
    
    [self setRepl:[[SDREPLServer alloc] init]];
//    [[self repl] evaluateString:@"[[[UIApplication sharedApplication] delegate] viewController]"];
//    double delayInSeconds = 1.0;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [[self repl] evaluateString:@"(define viewController [[[UIApplication sharedApplication] delegate] viewController])"];
    [[self repl] evaluateString:@"[[UIApplication sharedApplication] delegate] window] setBackgroundColor: [UIColor yellowColor]]"];
//    });

    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
