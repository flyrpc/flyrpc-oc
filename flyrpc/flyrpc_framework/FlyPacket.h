//
//  FlyPacket.h
//  flyrpc
//
//  Created by 林 桂 on 7/22/15.
//  Copyright (c) 2015 林 桂. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlyPacket : NSObject
@property(nonatomic, assign) uint64_t length;
@property(nonatomic, assign) uint8_t flag;
@property(nonatomic, retain) NSString* code;
@property(nonatomic, assign) int seq;
@property(nonatomic, assign) NSData* payload;
@end
