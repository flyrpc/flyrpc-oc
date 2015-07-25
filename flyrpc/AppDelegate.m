//
//  AppDelegate.m
//  flyrpc
//
//  Created by 林 桂 on 7/15/15.
//  Copyright (c) 2015 林 桂. All rights reserved.
//

#import "AppDelegate.h"
#import "execinfo.h"
#import "libkern/OSAtomic.h"

static void HandleException(NSException *exception) {
    NSLog(@"name = %@\nreason = %@\n\n%@", exception.name, exception.reason, exception.callStackSymbols);
}

volatile int32_t CrashCount = 0;
const int32_t CrashMaximum = 10;

NSArray* crashBacktrace() {
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (int i=0; i<10; i++) {
        if (strs[i] != NULL) {
            [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
        } else {
            [backtrace addObject:@""];
        }
    }
    
    free(strs);
    
    return backtrace;
}

static void SignalHandler(int signal) {
    int32_t exceptionCount = OSAtomicIncrement32(&CrashCount);
    if (exceptionCount > CrashMaximum) {
        return;
    }
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal] forKey:@"singnalType"];
    NSArray *callStack = crashBacktrace();
    [userInfo setObject:callStack forKey:@"stack"];
    NSLog(@"%@", userInfo);
}

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"didFinishLaunch");
    NSSetUncaughtExceptionHandler(&HandleException);
    
    signal(SIGABRT, &SignalHandler);
    signal(SIGILL, &SignalHandler);
    signal(SIGSEGV, &SignalHandler);
    signal(SIGFPE, &SignalHandler);
    signal(SIGBUS, &SignalHandler);
    signal(SIGPIPE, &SignalHandler);
    // make a crash
//    [self performSelector:@selector(debug) withObject:nil afterDelay:3];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
