//
//  swarmsSocketFacilitator.m
//  swarmsBBDriver
//
//  Created by Alexander List on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "swarmsSocketFacilitator.h"

static u_int32_t remoteIP = 0xC0A80164; //0x728A86CC;
static u_int32_t remotePort = 7337;

@implementation swarmsSocketFacilitator

-(BOOL)startConnection{
	
	if ( [self isConnected])
		return TRUE;
	
	struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(remotePort);
    addr4.sin_addr.s_addr = htonl(remoteIP);
    NSData *address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
	
	CFSocketSignature remoteSignature;
	remoteSignature.address			= (CFDataRef)address4;
	remoteSignature.protocolFamily	= PF_INET;
	remoteSignature.protocol		= IPPROTO_TCP;
	remoteSignature.socketType		= SOCK_STREAM;
	
	_driveSocket = CFSocketCreateConnectedToSocketSignature(kCFAllocatorDefault, &remoteSignature, kCFSocketDataCallBack, (CFSocketCallBack)&socketCallBack, NULL, 3);
//	_driveSocket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketDataCallBack, (CFSocketCallBack)&socketCallBack, NULL);	
    if (_driveSocket == NULL) {
		NSLog(@"Could not connect to remote server at %@ port %i", [NSString stringWithUTF8String:inet_ntoa(addr4.sin_addr)], remotePort);
        return NO;
    }else {
		NSLog(@"Connected to remote server at %@ port %i", [NSString stringWithUTF8String:inet_ntoa(addr4.sin_addr)], remotePort);
	}

	
	CFRunLoopRef cfrl = CFRunLoopGetCurrent();
    CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _driveSocket, 0);
    CFRunLoopAddSource(cfrl, source4, kCFRunLoopCommonModes);
    CFRelease(source4);
	
	
	return TRUE;
}

- (BOOL)stopConnection {
	if (![self isConnected])
		return YES;
	
	CFSocketInvalidate(_driveSocket);
	CFRelease(_driveSocket);
	_driveSocket = NULL;
	return YES;
}


-(void) testSWARMSDrive{
	NSString * sendTestString = @"steer 40; pause; steer 50; pause; steer 70;";
	
	
	[self sendCommandString:sendTestString];
}

-(BOOL)isConnected{
	if (_driveSocket == NULL)
		return FALSE; 
	
	return CFSocketIsValid(_driveSocket);
}

-(BOOL)sendCommandString:(NSString*)commands{
	if (! [self startConnection]){
			return FALSE;
	}
	
	CFDataRef commandDataRef = CFDataCreate(kCFAllocatorDefault,(UInt8*) [commands cStringUsingEncoding:NSUTF8StringEncoding], [commands length]);
	
	if (CFSocketSendData(_driveSocket, NULL, commandDataRef, 3) != kCFSocketSuccess){
		return NO;
	}
	
	CFRelease(commandDataRef);
	
	commandDataRef = NULL;
	
[self stopConnection];

	return YES;
}

-(id)initWithDelegate:(id<swarmsSocketFacilitatorDelegate>)delegate{
	if (self = [super init]){
		_delegate = delegate;
	}
	return self;
}

-(void)dealloc{
	[self stopConnection];
	_delegate = nil;
	
	[super dealloc];
}


static void socketCallBack (CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info){
	if (callbackType == 	kCFSocketDataCallBack){
		NSData * receivedData = [NSData dataWithBytes:CFDataGetBytePtr(data) length:CFDataGetLength(data)];
		if ([receivedData length] > 0){
			NSString * dataString = [NSString stringWithCString:[receivedData bytes] encoding:NSUTF8StringEncoding];
			NSLog(@"Received cstring: %@",dataString);
		}
	}
}

@end
