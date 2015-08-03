//
//  FlyOutResponse.h
//  flyrpc
//
//  Created by 林 桂 on 7/26/15.
//  Copyright (c) 2015 林 桂. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlyPacket.h"

@class FlyRPC;

@interface FlyOutResponse : NSObject
@property bool sent;
@property (nonatomic, readonly) FlyRPC* conn;
@property (nonatomic, readonly) FlyPacket* request;
- (id) initWithRequest:(FlyPacket*)request fly:(FlyRPC*)conn;
- (void) send:(NSString*)code payload:(NSData*)payload;
@end