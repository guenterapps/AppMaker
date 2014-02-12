//
//  CLAProgressManager.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 04/01/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import "CLAProgressManager.h"


@interface CLAProgressManager ()
{
	NSInteger	_progress;
	NSInteger	_target;
	NSTimer*	_timer;
}

-(void)updateCounter:(NSTimer *)timer;

@end

@implementation CLAProgressManager

-(void)resetCounter
{
	_progress			= 0;
	_target				= 0;
}

-(id)initWithMessage:(NSString *)message
{
	if (self = [super init])
	{
		self.progressMessage = message;
	}
	
	return self;
}

-(void)setProgressLabel:(UILabel *)progressLabel
{
	_progressLabel = progressLabel;
	self.progressLabel.text = [NSString stringWithFormat:@"%@ 0%%", self.progressMessage];
	
}

-(void)countToDelta:(NSInteger)delta withInterval:(NSTimeInterval)interval
{
	NSParameterAssert(delta > 0 && delta <= 100);
	NSParameterAssert(interval > 0);
	NSAssert(self.progressLabel, @"Must be set progressLabel first!");
	NSAssert(self.progressMessage, @"Must be set progressMessage first");
	
	[_timer invalidate];
	
	_target = delta;
	
	if (ABS(_target - _progress) == 0)
		return;
	
	NSTimeInterval timerDelta = interval/(NSTimeInterval)ABS(_target - _progress);
	
	_timer = [NSTimer scheduledTimerWithTimeInterval:timerDelta
											  target:self
											selector:@selector(updateCounter:)
											userInfo:nil
											 repeats:YES];
	
}

-(void)updateCounter:(NSTimer *)timer
{
	_progress++;
	
	if (_progress > _target)
	{
		[timer invalidate];
		return;
	}
	
	self.progressLabel.text = [NSString stringWithFormat:@"%@ %i%%", self.progressMessage, _progress];
}

@end
