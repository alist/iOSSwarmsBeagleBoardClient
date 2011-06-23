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
	[_sendCommandThread cancel];
	[_sendCommandThread release];
	_sendCommandThread = nil;
	
	[_SWARMSFacilitator stopConnection];
	[_SWARMSFacilitator release];
	
	_SWARMSFacilitator = nil;
	
	[super dealloc];
}

-(BOOL)isConnected{
	return [_SWARMSFacilitator isConnected];
}
-(BOOL)connect{
	[_SWARMSFacilitator startConnection];
	
	return [_SWARMSFacilitator sendCommandString:@"start;"];
}

-(BOOL)autoUpdatesEnabled{
	return [_updateTimer isValid];
}

-(void)beginAutoUpdates{
	if ([self autoUpdatesEnabled])
		[self endAutoUpdates];

	_updateTimer = [[NSTimer timerWithTimeInterval:.1 target:self selector:@selector(performDriveUpdate) userInfo:nil repeats:YES] retain];
	[[NSRunLoop mainRunLoop] addTimer:_updateTimer forMode:NSRunLoopCommonModes];
}
-(void)endAutoUpdates{
	[_updateTimer invalidate];
	[_updateTimer release];
	_updateTimer = nil;
}

-(void)performDriveUpdate{
	
	NSString *commandString = [self _interpolatedDriveStringForNextAndLastDriveDirections];	
	
	if ([commandString length] > 0 && _sendCommandThread == nil){
		NSLog(@"Command from update manager: %@", commandString);
		
		_sendCommandThread = [[NSThread alloc] initWithTarget:self selector:@selector(_threadedSendCommand:) object:commandString];
		[_sendCommandThread start];
		lastSetDriveDir		= nextDriveDir;
		lastSetDriveSpeed	= nextDriveSpeed;
	}	
}

-(void)_threadedSendCommand:(NSString*)command{
	NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
	
	[_SWARMSFacilitator sendCommandString:command];
	
	
	if ([[NSThread currentThread] isCancelled] == NO)
		[self performSelectorOnMainThread:@selector(_threadFinishedWithResponse:) withObject:nil waitUntilDone:NO];
	[autoReleasePool release];
}

-(void)_threadFinishedWithResponse:(id)response{
	[_sendCommandThread release];
	_sendCommandThread = nil;
}

-(NSString*)_interpolatedDriveStringForNextAndLastDriveDirections{
	NSMutableString * interpolation = [NSMutableString string];
	//drive speed, as the rc car already has super-jurky steering interpolation is fairly annoying

	int minSteerInterpolationDistance = 10;
	int maxSteerInterpolationSteps	= 4;
	int steerInterpolationDistance	=  (nextDriveDir -lastSetDriveDir)/maxSteerInterpolationSteps;	
	if (abs(steerInterpolationDistance) < minSteerInterpolationDistance){
		if (steerInterpolationDistance < 0)
			steerInterpolationDistance	= minSteerInterpolationDistance *-1;
		if (steerInterpolationDistance > 0)
			steerInterpolationDistance = minSteerInterpolationDistance;
	}

	int steerInterpolationSteps		=  abs((nextDriveDir -lastSetDriveDir)/steerInterpolationDistance);

	//int steerInterpolationDistance	= (lastSetDriveDir - nextDriveDir) <=0? 10: -10;


//	int driveInterpolationSteps		= abs((lastSetDriveSpeed - nextDriveSpeed)/10);
//	int driveInterpolationDistance	= (lastSetDriveSpeed - nextDriveSpeed) <=0? 10: -10;
	if (lastSetDriveSpeed != nextDriveSpeed){
		[interpolation appendFormat:@"drive %i;", nextDriveSpeed];
	}
	
	
	for (int i = 0;/* i < driveInterpolationSteps || */ i <= steerInterpolationSteps; i++){
		
		if (i < steerInterpolationSteps){
			if (i = steerInterpolationSteps -1){
				[interpolation appendFormat:@"steer %i;", nextDriveDir];
			}else {
				[interpolation appendFormat:@"steer %i;", lastSetDriveDir + steerInterpolationDistance * i];
			}			
		}
//		if (i < driveInterpolationSteps)
//			[interpolation appendFormat:@"drive %i;", lastSetDriveSpeed + driveInterpolationDistance * i];
		
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

-(BOOL)setDriveSpeed:(int)speed withMinValue:(int)min maxValue:(int)max{
	int spectrum = max - min;
	double correlation = 200.0/(double)spectrum;
	int inputValue = MIN(MAX(speed, min), max);
	
	int scaleValue = inputValue * correlation;
	
	return [self setDriveSpeed:scaleValue];
}

-(BOOL)setDriveDirection:(int)direction withMinValue:(int)min maxValue:(int)max{
	int spectrum = max - min;
	double correlation = 200.0/(double)spectrum;
	int inputValue = MIN(MAX( direction, min), max);
	
	int scaleValue = inputValue * correlation;
	
	return [self setDriveDirection:scaleValue];
}
-(BOOL)setDriveSpeed:(int)speed{
	nextDriveSpeed =  MIN(MAX( speed, -100), 100);;
	
	if ([self autoUpdatesEnabled]){
		return TRUE;
	}
	
	
	return FALSE;

}
-(BOOL)setDriveDirection:(int)direction{
	nextDriveDir = MIN(MAX( direction, -100), 100);
	
	if ([self autoUpdatesEnabled]){
		return TRUE;
	}
	
	return FALSE;
}

@end
