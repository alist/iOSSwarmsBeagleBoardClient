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
}

@property (nonatomic, readonly)int lastSetSpeed;
@property (nonatomic, readonly)int lastSetDirection;

-(id)init;
-(bool)isConnected;
-(bool)connect;

-(bool)autoUpdatesEnabled;
-(void)beginAutoUpdates;
-(void)endAutoUpdates;

-(bool)setDriveSpeed:(int)speed;
-(bool)setDriveDirection:(int)direction;


-(NSString*)_interpolatedDriveStringForNextAndLastDriveDirections;
-(NSString *)_interpolatedSteerStringBetweenCurrentSteerPoint:(int)currentSteerPoint andEndSteerPoint:(int)endPoint;
-(NSString *)_interpolatedDriveStringBetweenCurrentDrivePoint:(int)currentDrivePoint andEndDrivePoint:(int)endPoint;
@end
