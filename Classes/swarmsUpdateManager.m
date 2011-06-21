//
//  swarmsUpdateManager.m
//  swarmsBBDriver
//
//  Created by Alexander List on 6/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "swarmsUpdateManager.h"


@implementation swarmsUpdateManager
@synthesize lastSetSpeed = lastSetSpeed, lastSetDirection = lastSetDriveDir;


-(id)init{
	if (self = [super init]){
		_SWARMSFacilitator = [[swarmsSocketFacilitator alloc] initWithDelegate:self];
	}
	
	return self;
}

-(void)dealloc{
	[_SWARMSFacilitator stopConnection];
	[_SWARMSFacilitator release];
	
	_SWARMSFacilitator = nil;
	
	[super dealloc];
}

-(bool)isConnected{
	return [_SWARMSFacilitator isConnected];
}
-(bool)connect{
	[_SWARMSFacilitator startConnection];
	
	return [_SWARMSFacilitator sendCommandString:@"start;"];
}

-(bool)autoUpdatesEnabled{
	return [_updateTimer isValid];
}

-(void)beginAutoUpdates{
	if ([self autoUpdatesEnabled])
		[self endAutoUpdates];

	_updateTimer = [[NSTimer timerWithTimeInterval:.5 target:self selector:@selector(performDriveUpdate) userInfo:nil repeats:YES] retain];
	[[NSRunLoop mainRunLoop] addTimer:_updateTimer forMode:NSRunLoopCommonModes];
}
-(void)endAutoUpdates{
	[_updateTimer invalidate];
	[_updateTimer release];
	_updateTimer = nil;
}

-(void)performDriveUpdate{
	
	NSString *commandString = [self _interpolatedDriveStringForNextAndLastDriveDirections];	
	
	NSLog(@"Command from update manager: %@", commandString);
	
	[_SWARMSFacilitator sendCommandString:commandString];
	
	lastSetDriveDir		= nextDriveDir;
	lastSetDriveSpeed	= nextDriveSpeed;
	
}
		
-(NSString*)_interpolatedDriveStringForNextAndLastDriveDirections{
	NSMutableString * interpolation = [NSMutableString string];
	

	int steerInterpolationSteps		= abs((lastSetDriveDir - nextDriveDir)/10);
	int steerInterpolationDistance	= (lastSetDriveDir - nextDriveDir) >=0? 10: -10;

	int driveInterpolationSteps		= abs((lastSetDriveSpeed - nextDriveSpeed)/10);
	int driveInterpolationDistance	= (lastSetDriveSpeed - nextDriveSpeed) >=0? 10: -10;

	
	for (int i = 0; i < driveInterpolationSteps || i < steerInterpolationSteps; i++){
		
		if (i < steerInterpolationSteps)
			[interpolation appendFormat:@"steer %i;", lastSetDriveDir + steerInterpolationDistance * i];
		if (i < driveInterpolationSteps)
			[interpolation appendFormat:@"drive %i;", lastSetDriveSpeed + driveInterpolationDistance * i];
		
		[interpolation appendString:@"pause;"];
	}
	
	
	return interpolation;
}
			

-(NSString *)_interpolatedSteerStringBetweenCurrentSteerPoint:(int)currentSteerPoint andEndSteerPoint:(int)endPoint{
	NSMutableString * interpolation = [NSMutableString string];
	
	int interpolationSteps		= abs((currentSteerPoint - endPoint)/10);
	int interpolationDistance	= (currentSteerPoint - endPoint) >=0? 10: -10;
	
	for (int i = 0; i < interpolationSteps; i++){
		[interpolation appendFormat:@"steer %i; pause;", currentSteerPoint + interpolationDistance * i];
	}
	
	return interpolation;
}

-(NSString *)_interpolatedDriveStringBetweenCurrentDrivePoint:(int)currentDrivePoint andEndDrivePoint:(int)endPoint{
	NSMutableString * interpolation = [NSMutableString string];
	
	int interpolationSteps		= abs((currentDrivePoint - endPoint)/10);
	int interpolationDistance	= (currentDrivePoint - endPoint) >=0? 10: -10;
	
	for (int i = 0; i < interpolationSteps; i++){
		[interpolation appendFormat:@"drive %i; pause;", currentDrivePoint + interpolationDistance * i];
	}
	
	return interpolation;
}


-(bool)setDriveSpeed:(int)speed{
	nextDriveSpeed =  MIN(MAX( speed, -100), 100);;
	
	if ([self autoUpdatesEnabled]){
		return TRUE;
	}
	
	
	return FALSE;

}
-(bool)setDriveDirection:(int)direction{
	nextDriveDir = MIN(MAX( direction, -100), 100);
	
	if ([self autoUpdatesEnabled]){
		return TRUE;
	}
	
	return FALSE;
}

@end
