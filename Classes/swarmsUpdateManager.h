//
//  swarmsUpdateManager.h
//  swarmsBBDriver
//
//  Created by Alexander List on 6/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swarmsSocketFacilitator.h"

@interface swarmsUpdateManager : NSObject <swarmsSocketFacilitatorDelegate> {
	int lastSetDriveDir;
	int lastSetDriveSpeed;

	int nextDriveDir;
	int nextDriveSpeed;
	
	swarmsSocketFacilitator *	_SWARMSFacilitator;
			
	NSTimer*					_updateTimer;
	
	NSThread *					_sendCommandThread;
}

@property (nonatomic, readonly)int lastSetSpeed;
@property (nonatomic, readonly)int lastSetDirection;

-(id)init;
-(BOOL)isConnected;
-(BOOL)connect;

-(BOOL)autoUpdatesEnabled;
-(void)beginAutoUpdates;
-(void)endAutoUpdates;

-(BOOL)setDriveSpeed:(int)speed;
-(BOOL)setDriveDirection:(int)direction;

-(BOOL)setDriveSpeed:(int)speed withMinValue:(int)min maxValue:(int)max;
-(BOOL)setDriveDirection:(int)direction withMinValue:(int)min maxValue:(int)max;

-(NSString*)_interpolatedDriveStringForNextAndLastDriveDirections;
-(NSString *)_interpolatedSteerStringBetweenCurrentSteerPoint:(int)currentSteerPoint andEndSteerPoint:(int)endPoint;
-(NSString *)_interpolatedDriveStringBetweenCurrentDrivePoint:(int)currentDrivePoint andEndDrivePoint:(int)endPoint;
@end
