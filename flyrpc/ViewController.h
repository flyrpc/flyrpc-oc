//
//  ViewController.h
//  flyrpc
//
//  Created by 林 桂 on 7/15/15.
//  Copyright (c) 2015 林 桂. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlyRPC.h"

@class GCDAsyncSocket;
@class FlyRPC;

@interface ViewController : UIViewController<FlyRPCDelegate>
{
    FlyRPC* flyrpc;
//    GCDAsyncSocket* asyncSocket;
}


@end

