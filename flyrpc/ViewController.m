//
//  ViewController.m
//  flyrpc
//
//  Created by 林 桂 on 7/15/15.
//  Copyright (c) 2015 林 桂. All rights reserved.
//

#import "ViewController.h"
#import "FlyRPC.h"
#import "GCDAsyncSocket.h"

@interface ViewController ()

@end

@implementation ViewController
{
    long mytag;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    flyrpc = [[FlyRPC alloc] init];
    flyrpc.delegate = self;
    [flyrpc connectToHost:@"localhost" port:3456];
    [self sayHello];
    
/*
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
    
    NSString *host = @"localhost";
    uint16_t port = 12345;
    
    NSLog(@"Connecting to \"%@\" on port %hu...", host, port);
    
    NSError *error = nil;
    if (![asyncSocket connectToHost:host onPort:port error:&error])
    {
        NSLog(@"Error connecting: %@", error);
    }
    
    [asyncSocket readDataToLength:5 withTimeout:-1 tag:1];
 */
}

- (void) sayHello {
    mytag += 100;
    [flyrpc sendRequest:@"timeout" payload:[@"Hello World.Hello World.Hello World.Hello World.Hello World.Hello World.Hello World.Hello World.Hello World.Hello World.Hello.Hello World.Hello World.Hello World.Hello World.Hello World.Hello World.Hello World.Hello World.Hello World.Hello World. 12345" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:[NSString stringWithFormat:@"%lu", mytag]];
    [self performSelector:@selector(sayHello) withObject:nil afterDelay:3];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) rpc:(FlyRPC *)conn didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"did connect to host");
}

- (void) rpc:(FlyRPC *)conn receiveRequest:(FlyPacket *)packet {
    NSLog(@"did receiveRequest %@", packet.code);
}

- (void) rpc:(FlyRPC *)conn didReceiveResponse:(FlyPacket *)response withTag:(NSString*)tag {
    NSString* s = [[NSString alloc]initWithData:response.payload encoding:NSUTF8StringEncoding];
    NSLog(@"did receiveResponse %@ %@", s, tag);
}

- (void) rpc:(FlyRPC *)conn didReadPacket:(FlyPacket *)packet {
    NSLog(@"did receive packet %@ %@", packet.code, packet.payload);
}

- (void) rpcRequestTimeout:(FlyRPC *)conn withTag:(NSString *)tag {
    NSLog(@"fly did fail to request %@", tag);
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Socket Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"socket:%p didConnectToHost:%@ port:%hu", sock, host, port);
    
    //	NSLog(@"localHost :%@ port:%hu", [sock localHost], [sock localPort]);
    
#if USE_SECURE_CONNECTION
    {
        // Connected to secure server (HTTPS)
        
#if ENABLE_BACKGROUNDING && !TARGET_IPHONE_SIMULATOR
        {
            // Backgrounding doesn't seem to be supported on the simulator yet
            
            [sock performBlock:^{
                if ([sock enableBackgroundingOnSocket])
                    NSLog(@"Enabled backgrounding on socket");
                else
                    DDLogWarn(@"Enabling backgrounding failed!");
            }];
        }
#endif
        
        // Configure SSL/TLS settings
        NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:3];
        
        // If you simply want to ensure that the remote host's certificate is valid,
        // then you can use an empty dictionary.
        
        // If you know the name of the remote host, then you should specify the name here.
        //
        // NOTE:
        // You should understand the security implications if you do not specify the peer name.
        // Please see the documentation for the startTLS method in GCDAsyncSocket.h for a full discussion.
        
        [settings setObject:host
                     forKey:(NSString *)kCFStreamSSLPeerName];
        
        // To connect to a test server, with a self-signed certificate, use settings similar to this:
        
        //	// Allow expired certificates
        //	[settings setObject:[NSNumber numberWithBool:YES]
        //				 forKey:(NSString *)kCFStreamSSLAllowsExpiredCertificates];
        //
        //	// Allow self-signed certificates
        //	[settings setObject:[NSNumber numberWithBool:YES]
        //				 forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
        //
        //	// In fact, don't even validate the certificate chain
        //	[settings setObject:[NSNumber numberWithBool:NO]
        //				 forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
        
        NSLog(@"Starting TLS with settings:\n%@", settings);
        
        [sock startTLS:settings];
        
        // You can also pass nil to the startTLS method, which is the same as passing an empty dictionary.
        // Again, you should understand the security implications of doing so.
        // Please see the documentation for the startTLS method in GCDAsyncSocket.h for a full discussion.
        
    }
#else
    {
        // Connected to normal server (HTTP)
        
#if ENABLE_BACKGROUNDING && !TARGET_IPHONE_SIMULATOR
        {
            // Backgrounding doesn't seem to be supported on the simulator yet
            
            [sock performBlock:^{
                if ([sock enableBackgroundingOnSocket])
                    NSLog(@"Enabled backgrounding on socket");
                else
                    DDLogWarn(@"Enabling backgrounding failed!");
            }];
        }
#endif
    }
#endif
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    NSLog(@"socketDidSecure:%p", sock);
    
    NSString *requestStr = [NSString stringWithFormat:@"GET / HTTP/1.1\r\nHost: %@\r\n\r\n", @"www.baidu.com"];
    NSData *requestData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [sock writeData:requestData withTimeout:-1 tag:0];
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"socket:%p didReadData:withTag:%ld", sock, tag);
    
    NSString *httpResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"HTTP Response:\n%@", httpResponse);
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"socketDidDisconnect:%p withError: %@", sock, err);
}


@end
