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
- (void)fly:(FlyProtocol *)conn receiveMessage:(FlyPacket *)message;
- (void)fly:(FlyProtocol *)conn receiveRequest:(FlyPacket *)request response:(FlyOutResponse*)response;
- (void)fly:(FlyProtocol *)conn receiveResponse:(FlyPacket *)response;
@end

@protocol FlyResponseDelegate <NSObject>
- (void)fly:(FlyProtocol *)conn receiveResponse:(FlyPacket *)response ofRequest:(FlyPacket*)request;
@end

@interface FlyProtocol : NSObject<GCDAsyncSocketDelegate>
@property (atomic, weak, readwrite) id<FlyProtocolDelegate> delegate;
- (id)initWithDelegate:(id<FlyProtocolDelegate>)delegate;
- (void) connectToHost:(NSString*)host port:(int)port;
- (void) request:(NSString*)code payload:(NSData*)payload responseDelegate:(id<FlyResponseDelegate>)delegate;
- (void) sendMessage:(NSString*)code payload:(NSData*)payload;
- (void) sendRequest:(NSString*)code payload:(NSData*)payload;
- (void) sendResponse:(uint16_t)seq code:(NSString*)code payload:(NSData*)payload;
// - (void) sendPacket:(FlyPacket*) packet;
- (void) disconnect;
@end
