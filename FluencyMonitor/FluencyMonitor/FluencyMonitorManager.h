//
//  FluencyMonitorManager.h
//  FluencyMonitor
//
//  Created by hh on 17/4/7.
//  Copyright © 2017年 DLY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluencyMonitorManager : NSObject

+ (instancetype)shareFluencyMonitor;

-(void)startMonitor;

-(void)endMonitor;

@end
