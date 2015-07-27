//
//  FlyProtocol.m
//  flyrpc
//
//  Created by 林 桂 on 7/16/15.
//  Copyright (c) 2015 林 桂. All rights reserved.
//

#import "FlyProtocol.h"
#import "GCDAsyncSocket.h"

#define DEFAULT_TIMEOUT     5


#define TAG_FLAG            1
#define TAG_SEQUENCE        2
#define TAG_CODE            3
#define TAG_LEN             4
#define TAG_PAYLOAD         5

#define SIZE_FLAG           1
#define SIZE_SEQUENCE       2

#define FLAG_RESPONSE       0x80
#define FLAG_WAIT_RESPONSE  0x40

@implementation FlyProtocol
{
    GCDAsyncSocket* asyncSocket;
    FlyPacket* currentPacket;
    uint16_t nextSeq;
    NSMutableDictionary * dictSeqToTag;
}

- (id) init {
    self = [super init];
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    dictSeqToTag = [NSMutableDictionary dictionary];
    return self;
}

- (void) connectToHost:(NSString *)host port:(int)port {
    NSLog(@"Connecting to %@ %d", host, port);
    _connected = true;
    NSError *err = nil;
    if (![asyncSocket connectToHost:host onPort:port error:&err])
    {
        NSLog(@"Error connecting: %@", err);
    }
}

- (void) readNextPacket:(GCDAsyncSocket *) sock {
    [sock readDataToLength:SIZE_FLAG withTimeout:-1 tag: TAG_FLAG];
}

- (void) disconnect {
    [asyncSocket disconnect];
}

- (void) request:(NSString *)code payload:(NSData *)payload {
    NSLog(@"not implement");
}

- (void) sendRequest:(NSString*)code payload:(NSData*)payload withTimeout:(NSTimeInterval)timeout tag:(long)tag{
    FlyPacket* packet = [[FlyPacket alloc] init];
    packet.flag = FLAG_WAIT_RESPONSE;
    packet.seq = ++nextSeq;
    packet.code = code;
    packet.payload = payload;
    [dictSeqToTag setObject:[NSNumber numberWithLong:tag] forKey:[NSNumber numberWithShort:packet.seq]];
    [self sendPacket:packet];
}

- (void) sendResponse:(uint16_t)seq code:(NSString*)code payload:(NSData*)payload {
    FlyPacket* packet = [[FlyPacket alloc] init];
    packet.flag = FLAG_RESPONSE;
    packet.seq = seq;
    packet.code = code;
    packet.payload = payload;
    [self sendPacket:packet];
}

- (void) sendMessage:(NSString *)code payload:(NSData *)payload {
    FlyPacket* packet = [[FlyPacket alloc] init];
    packet.flag = 0;
    packet.seq = ++nextSeq;
    packet.code = code;
    packet.payload = payload;
    [self sendPacket:packet];
}

- (void) sendPacket:(FlyPacket*) packet {
    // prepare packet
    if (packet.isResponse) {
        packet.flag |= FLAG_RESPONSE;
    }
    if (packet.waitResponse) {
        packet.flag |= FLAG_WAIT_RESPONSE;
    }
    if (packet.length == 0) {
        packet.length = packet.payload.length;
    }
    int bitsOfLen = 8;
    if (packet.length > 0xffffffff) {
        bitsOfLen = 64;
        packet.flag |= 3;
    } else if (packet.length > 0xffff) {
        bitsOfLen = 32;
        packet.flag |= 2;
    } else if (packet.length > 0xff) {
        bitsOfLen = 16;
        packet.flag |= 1;
    }
    // buffer to write
    NSMutableData* buff = [[NSMutableData alloc]init];
    // ------ header ----
    // flag
    uint8_t flag = packet.flag;
    [buff appendBytes:&flag length:1];
    // seq
    uint16_t seq = CFSwapInt16HostToBig(packet.seq);
    [buff appendBytes:&seq length:2];
    // code
    [buff appendData:[packet.code dataUsingEncoding:NSUTF8StringEncoding]];
    [buff appendData:[GCDAsyncSocket ZeroData]];
    // payload length
    if (bitsOfLen == 8) {
        uint8_t len = (uint8_t)packet.length;
        [buff appendBytes:&len length:1];
    } else if(bitsOfLen == 16) {
        uint16_t len = (uint16_t)packet.length;
        len = CFSwapInt16HostToBig(len);
        [buff appendBytes:&len length:2];
    } else if(bitsOfLen == 32) {
        uint32_t len = (uint32_t)packet.length;
        len = CFSwapInt32HostToBig(len);
        [buff appendBytes:&len length:4];
    } else if(bitsOfLen == 64) {
        uint64_t len = packet.length;
        len = CFSwapInt64HostToBig(len);
        [buff appendBytes:&len length:8];
    }
    // ----- end header ----
    // payload
    [buff appendData:packet.payload];
    // write to socket
    [asyncSocket writeData:buff withTimeout:DEFAULT_TIMEOUT tag:0];
}

-(void) didReadPacket:(FlyPacket*)packet {
    if (packet.isResponse) {
        if (_delegate && [_delegate respondsToSelector:@selector(fly:didReceiveResponse:withTag:)]) {
            NSNumber* seq = [NSNumber numberWithShort:packet.seq];
            NSNumber* tagNum = [dictSeqToTag objectForKey:seq];
            [dictSeqToTag removeObjectForKey:seq];
            [_delegate fly:self didReceiveResponse:packet withTag:[tagNum longValue]];
        }
    } else if(packet.waitResponse){
        if (_delegate && [_delegate respondsToSelector:@selector(fly:didReceiveRequest:response:)]) {
            FlyOutResponse* response = [[FlyOutResponse alloc]initWithRequest:packet fly:self];
            [_delegate fly:self didReceiveRequest:packet response:response];
        }
    } else {
        if (_delegate != nil && [_delegate respondsToSelector:@selector(fly:didReceiveMessage:)]) {
            [_delegate fly:self didReceiveMessage:packet];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Socket Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"Connected to host");
    if (_delegate != nil || [_delegate respondsToSelector:@selector(fly:didConnectToHost:port:)]) {
        [_delegate fly:self didConnectToHost:host port:port];
    }
    [self readNextPacket:sock];
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    // NSLog(@"Read data %ld - %@", tag, data);
    if(tag == TAG_FLAG) {
        // 初始化packet
        currentPacket = [[FlyPacket alloc]init];
        currentPacket.flag = *(uint8_t *)data.bytes;
        currentPacket.isResponse = (currentPacket.flag & FLAG_RESPONSE) != 0;
        currentPacket.isRequest = !currentPacket.isResponse;
        currentPacket.waitResponse = (currentPacket.flag & FLAG_WAIT_RESPONSE) != 0;
        [sock readDataToLength:SIZE_SEQUENCE withTimeout:DEFAULT_TIMEOUT tag:TAG_SEQUENCE];
    } else if(tag == TAG_SEQUENCE) {
        currentPacket.seq = CFSwapInt16BigToHost(*(uint16_t*)data.bytes);
        [sock readDataToData:[GCDAsyncSocket ZeroData] withTimeout:DEFAULT_TIMEOUT tag:TAG_CODE];
    } else if(tag == TAG_CODE) {
        NSString* code = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        currentPacket.code = [code substringToIndex:code.length - 1];
        // powOfLen, 0=> 1byte, 1=> 2byte, 2=> 4byte, 3=> 8byte
        uint8_t powOfLen = currentPacket.flag & 0x03;
        int lenSize = 1 << powOfLen;
        NSLog(@"code:%@ %d %d", currentPacket.code, powOfLen, lenSize);
        [sock readDataToLength:lenSize withTimeout:DEFAULT_TIMEOUT tag:TAG_LEN];
    } else if (tag == TAG_LEN) {
        // 读取 length
        uint64_t length = 0;
        switch (data.length) {
            case 1:
                length = *(uint8_t *) data.bytes;
                break;
                
            case 2:
                length = CFSwapInt16BigToHost(*(uint16_t *) data.bytes);
                break;
                
            case 4:
                length = CFSwapInt32BigToHost(*(uint32_t *) data.bytes);
                break;
                
            case  8:
                length = CFSwapInt64BigToHost(*(uint64_t *) data.bytes);
                break;
                
            default:
                NSLog(@"Wrong size of length, must 1,2,4,8, actual %lu", (unsigned long)data.length);
                break;
        }
        currentPacket.length = length;
        // 等待获取 Flag
        [sock readDataToLength:length withTimeout:DEFAULT_TIMEOUT tag:TAG_PAYLOAD];
    } else if(tag == TAG_PAYLOAD) {
        currentPacket.payload = data;
        [self didReadPacket:currentPacket];
        NSLog(@"ReadPacket %@ %lu", currentPacket.code, (unsigned long)data.length);
        [self readNextPacket:sock];
                // TODO CRC??
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"Did disconnect %@", err);
    if (_connected) {
        _connected = false;
        if (_delegate != nil && [_delegate respondsToSelector:@selector(flyDidDisconnect:withError:)]) {
            [_delegate flyDidDisconnect:self withError:err];
        }
    }
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    if (_connected) {
        _connected = false;
        if (_delegate != nil && [_delegate respondsToSelector:@selector(flyDidDisconnect:withError:)]) {
            [_delegate flyDidDisconnect:self withError:nil];
        }
    }
}

@end
