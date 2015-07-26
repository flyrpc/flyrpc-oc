//
//  FlyOutResponse.m
//  flyrpc
//
//  Created by 林 桂 on 7/26/15.
//  Copyright (c) 2015 林 桂. All rights reserved.
//

#import "FlyOutResponse.h"
#import "FlyProtocol.h"

@implementation FlyOutResponse

-(id) initWithRequest:(FlyPacket *)request fly:(FlyProtocol *)conn {
    self = [super init];
    _conn = conn;
    _request = request;
    return self;
}

-(void) send:(NSString *)code payload:(NSData *)payload {
    if (_sent) {
        NSLog(@"Already sent, can't sent again");
    }
    _sent = true;
    [_conn sendResponse:_request.seq code:code payload:payload];
}

@end
