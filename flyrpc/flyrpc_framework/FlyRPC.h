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

@class FlyRPC;

@protocol FlyRPCDelegate <NSObject>
@optional
- (void)rpc:(FlyRPC *)rpc didConnectToHost:(NSString*)host port:(uint16_t)port;
- (void)rpcDidDisconnect:(FlyRPC *)conn withError:(NSError*)err;
- (void)rpc:(FlyRPC *)rpc didReceiveMessage:(FlyPacket *)message;
- (void)rpc:(FlyRPC *)rpc didReceiveRequest:(FlyPacket *)request response:(FlyOutResponse*)response;
- (void)rpc:(FlyRPC *)rpc didReceiveResponse:(FlyPacket *)response withTag:(NSString*)tag;
- (void)rpcRequestTimeout:(FlyRPC *)conn withTag:(NSString*)tag;
@end

@interface FlyRPC : NSObject<GCDAsyncSocketDelegate>
@property (readonly) bool connected;
@property (atomic, weak) id<FlyRPCDelegate> delegate;
- (void) connectToHost:(NSString*)host port:(int)port;
- (void) sendMessage:(NSString*)code payload:(NSData*)payload;
- (void) sendRequest:(NSString*)code payload:(NSData*)payload withTimeout:(NSTimeInterval)timeout tag:(NSString*)tag;
- (void) sendResponse:(uint16_t)seq code:(NSString*)code payload:(NSData*)payload;
- (void) disconnect;
@end
