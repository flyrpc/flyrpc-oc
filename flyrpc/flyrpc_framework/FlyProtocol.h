//
//  FlyProtocol.h
//  flyrpc
//
//  Created by 林 桂 on 7/16/15.
//  Copyright (c) 2015 林 桂. All rights reserved.
//

#import "FlyPacket.h"
#import "FlyOutResponse.h"
#import "GCDAsyncSocket.h"
#import <Foundation/Foundation.h>

@class FlyProtocol;

@protocol FlyProtocolDelegate <NSObject>
@optional
- (void)fly:(FlyProtocol *)conn didConnectToHost:(NSString*)host port:(uint16_t)port;
- (void)flyDidDisconnect:(FlyProtocol *)conn withError:(NSError*)err;
// TODO: make it thread safe and concurrent.
// - (void)fly:(FlyProtocol *)conn didReadPacket:(FlyPacket *)packet;
- (void)fly:(FlyProtocol *)conn didReceiveMessage:(FlyPacket *)message;
- (void)fly:(FlyProtocol *)conn didReceiveRequest:(FlyPacket *)request response:(FlyOutResponse*)response;
- (void)fly:(FlyProtocol *)conn didReceiveResponse:(FlyPacket *)response withTag:(long)tag;
- (void)flyFailToRequest:(FlyProtocol *)conn withTag:(long)tag;
@end

@interface FlyProtocol : NSObject<GCDAsyncSocketDelegate>
@property (readonly) bool connected;
@property (atomic, weak) id<FlyProtocolDelegate> delegate;
- (void) connectToHost:(NSString*)host port:(int)port;
- (void) sendMessage:(NSString*)code payload:(NSData*)payload;
- (void) sendRequest:(NSString*)code payload:(NSData*)payload withTimeout:(NSTimeInterval)timeout tag:(long)tag;
- (void) sendResponse:(uint16_t)seq code:(NSString*)code payload:(NSData*)payload;
// - (void) sendPacket:(FlyPacket*) packet;
- (void) disconnect;
@end
