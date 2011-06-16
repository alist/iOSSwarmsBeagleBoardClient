//
//  swarmsSocketFacilitator.h
//  swarmsBBDriver
//
//  Created by Alexander List on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#include <CFNetwork/CFNetwork.h>
#include <CoreFoundation/CFSocket.h>
#include <sys/socket.h>
#include <netinet/in.h>
#import <arpa/inet.h>


@class swarmsSocketFacilitator;
@protocol swarmsSocketFacilitatorDelegate<NSObject>

@end


static NSString * const remoteDriveIP	= @"192.168.1.100";
static NSString * const remoteDrivePort	= @"7337";

@interface swarmsSocketFacilitator : NSObject {
	CFSocketRef _driveSocket;
	
	id<swarmsSocketFacilitatorDelegate> _delegate;
}

static void socketCallBack (CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info);
- (BOOL)startConnection;
- (BOOL)stopConnection;
-(id)initWithDelegate:(id<swarmsSocketFacilitatorDelegate>)delegate;

-(void) testSWARMSDrive;
-(BOOL)sendCommandString:(NSString*)commands;

-(BOOL)isConnected;

@end
