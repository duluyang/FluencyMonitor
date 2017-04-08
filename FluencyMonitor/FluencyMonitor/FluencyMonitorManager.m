//
//  FluencyMonitorManager.m
//  FluencyMonitor
//
//  Created by hh on 17/4/7.
//  Copyright © 2017年 DLY. All rights reserved.
//

#import "FluencyMonitorManager.h"
#import <CrashReporter/CrashReporter.h>

#define Fluencymanager [FluencyMonitorManager shareFluencyMonitor]
#define timevalue 100*1000

@interface FluencyMonitorManager ()

@property(nonatomic,strong)dispatch_semaphore_t semaphore;
@property(nonatomic,assign)BOOL isMonitoring;
@property(nonatomic,assign)int timeOut;


@property (nonatomic, assign) CFRunLoopObserverRef observer;
@property (nonatomic, assign) CFRunLoopActivity currentActivity;

@end

@implementation FluencyMonitorManager


+ (instancetype)shareFluencyMonitor
{
    static FluencyMonitorManager *shareFluency;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shareFluency = [[super alloc] init];
    });
    return shareFluency;
}


static void runloopOberverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void * info) {
    Fluencymanager.currentActivity = activity;
};


-(void)startMonitor
{
    if (_isMonitoring) {
        return;
    }
    _semaphore = dispatch_semaphore_create(0);
    _isMonitoring = YES;
    
    CFRunLoopObserverContext context = {
        0,
        (__bridge void *)self,
        NULL,
        NULL
    };
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runloopOberverCallBack, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (_isMonitoring) {
            switch (Fluencymanager.currentActivity) {
                case kCFRunLoopAfterWaiting:
                case kCFRunLoopBeforeWaiting:
                case kCFRunLoopBeforeSources: {
                    __block BOOL timeOut = YES;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        timeOut = NO;
                        dispatch_semaphore_signal(Fluencymanager.semaphore);
                    });
                    
                    usleep(timevalue);
                    
                    if (timeOut) {
                        NSLog(@"卡顿");
                        PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeBSD
                                                                                           symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll];
                        PLCrashReporter *crashReporter = [[PLCrashReporter alloc] initWithConfiguration:config];
                        
                        NSData *data = [crashReporter generateLiveReport];
                        PLCrashReport *reporter = [[PLCrashReport alloc] initWithData:data error:NULL];
                        NSString *report = [PLCrashReportTextFormatter stringValueForCrashReport:reporter
                                                                                  withTextFormat:PLCrashReportTextFormatiOS];
                        NSLog(@"------------\n%@\n------------", report);
                    }
                    dispatch_semaphore_wait(Fluencymanager.semaphore, DISPATCH_TIME_FOREVER);
                } break;
                    
                default:
                    break;
            }
        }
    });
}


-(void)endMonitor
{
    if (!_isMonitoring) {
        return;
    }
    _isMonitoring = NO;
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = nil;
}
@end
