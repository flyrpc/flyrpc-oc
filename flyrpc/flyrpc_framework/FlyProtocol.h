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

@protocol FlyProtocolDelegate<GCDAsyncSocketDelegate>
@required
- (void)socket:(GCDAsyncSocket *)sock didRequest:(FlyPacket *)packet;
@optional
- (void)socket:(GCDAsyncSocket *)sock didReadPacket:(FlyPacket *)packet;
- (void)socket:(GCDAsyncSocket *)sock didResponse:(FlyPacket *)packet;
@end

@interface FlyProtocol : NSObject<FlyProtocolDelegate>
{
//    NSInputStream *inputStream;
//    NSOutputStream *outputStream;
    GCDAsyncSocket* asyncSocket;
    FlyPacket* currentPacket;
    uint16_t nextSeq;
}

- (id) init;
- (void)setup:(NSString*)host port:(int)port;

@property (strong) NSString *test;


@end
