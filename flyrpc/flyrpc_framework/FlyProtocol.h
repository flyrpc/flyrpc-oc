//
//  FlyProtocol.h
//  flyrpc
//
//  Created by 林 桂 on 7/16/15.
//  Copyright (c) 2015 林 桂. All rights reserved.
//

#import "FlyPacket.h"
#import "GCDAsyncSocket.h"
#import <Foundation/Foundation.h>

@class FlyProtocol;

@protocol FlyProtocolDelegate
@optional
- (void)fly:(FlyProtocol *)conn didConnectToHost:(NSString*)host port:(uint16_t)port;
- (void)flyDidDisconnect:(FlyProtocol *)conn withError:(NSError*)err;
- (void)fly:(FlyProtocol *)conn didReadPacket:(FlyPacket *)packet;
- (void)fly:(FlyProtocol *)conn receiveRequest:(FlyPacket *)packet;
- (void)fly:(FlyProtocol *)conn receiveResponse:(FlyPacket *)packet;
@end

@interface FlyProtocol : NSObject<GCDAsyncSocketDelegate>
{
    GCDAsyncSocket* asyncSocket;
    FlyPacket* currentPacket;
    uint16_t nextSeq;
}
@property (atomic, weak, readwrite) id<FlyProtocolDelegate> delegate;
- (id)initWithDelegate:(id<FlyProtocolDelegate>)delegate;
- (void) connectToHost:(NSString*)host port:(int)port;
- (void) sendRequest:(NSString*)code payload:(NSData*)payload;
- (void) sendResponse:(uint16_t)seq code:(NSString*)code payload:(NSData*)payload;
- (void) sendPacket:(FlyPacket*) packet;
- (void) disconnect;
@end
