//
//  ViewController.h
//  flyrpc
//
//  Created by 林 桂 on 7/15/15.
//  Copyright (c) 2015 林 桂. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GCDAsyncSocket;
@class FlyProtocol;

@interface ViewController : UIViewController
{
    FlyProtocol* flyProtocol;
    GCDAsyncSocket* asyncSocket;
}


@end

