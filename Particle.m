//
//  Particle.m
//  ModeMaker
//
//  Created by David Hirsch on 9/21/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import "Particle.h"
#import "constants.h"

@implementation Particle

- (id) initWithBoundsRect: (NSRect) boundsRect
					 size: (float) inSize 
				   sizeSD: (float) inSizeSD
			  aspectRatio: (float) inAspectRatio
			aspectRatioSD: (float) inAspectRatioSD
			   complexity: (short) inComplexity
			 complexitySD: (float) inComplexitySD
		   fabricStrength: (float) inFabricStrength
		  allowReentrants: (BOOL) inAllowReentrants;
{
	self = [super init];
	// initialize with random location within Bounds Rect - this rect should be expanded from the canvas specified in the UI to avoid edge effects
	float randX = (boundsRect.size.width * (float) rand() / (float) RAND_MAX) + boundsRect.origin.x;
	float randY = (boundsRect.size.height * (float) rand() / (float) RAND_MAX) + boundsRect.origin.y;
	center = NSMakePoint(randX, randY);
	float normalSizeValue = [self normalValueWithMean: inSize standardDev: inSizeSD];	// this is not the area, but sqrt(area)
	area = (kSmallestParticleArea < normalSizeValue) ? (normalSizeValue * normalSizeValue) : kSmallestParticleArea;
	myPath = [NSBezierPath bezierPath ];	// create a new path - will be filled in by inheritor class
	[myPath retain];
	return self;
}

- (void) dealloc {
	[myPath release];
	[super dealloc];
}

- (void) draw {
	[myPath fill];
/* For Debugging:
	[[NSColor greenColor] setStroke];
	[myPath stroke];
	[NSBezierPath fillRect:NSMakeRect(center.x-2, center.y-2, 4, 4)];
*/
}

- (void) adjustAreaByFactor: (float) areaFactor {
	area *= areaFactor;
	float scaleFactor = sqrt(areaFactor);
	NSAffineTransform *transform = [NSAffineTransform transform];
	// need to translate the path to the origin, then shrink/expand it, then translate it back.  Otherwise, expanding the COORDINATE SYSTEM
	// will cause the path to move, I think
	[transform translateXBy: -center.x yBy:-center.y];
	[transform scaleXBy:scaleFactor yBy:scaleFactor];
	[myPath transformUsingAffineTransform: transform];
	
	transform = [NSAffineTransform transform];	// get a new empty transform; avoids worrying about combinatory surprises
	[transform translateXBy: center.x yBy:center.y];
	[myPath transformUsingAffineTransform: transform];
}

- (void) adaptToSize {
	NSLog(@"Particle is Abstract - flow should not have arrived here.");
}
	
- (float) normalValueWithMean: (float) inMean
				  standardDev:(float) inSD
{
	float U1 = (float) rand() / (float) RAND_MAX;
	float U2 = (float) rand() / (float) RAND_MAX;
	float z1 = sqrt(-2 * log(U1)) * sin(2 * pi * U2);
	return (inMean + z1 * inSD);
}

- (BOOL) containsPoint: (NSPoint) inPoint {
	return [myPath containsPoint:inPoint];
}

- (BOOL) overlapsWith: (Particle *) inOtherParticle {
	NSLog (@"Particle is Abstract - flow should not have arrived here.");
	return YES;
}

- (NSPoint) center {return center;}
- (void) setCenter: (NSPoint)input {center = input;}

- (NSBezierPath *) path {return myPath;}

#define centerX_key @"centerX"
#define centerY_key @"centerY"
#define area_key @"area"
#define myPath_key @"myPath"
- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeFloat:center.x forKey:centerX_key];
	[coder encodeFloat:center.y forKey:centerY_key];
	[coder encodeFloat:area forKey:area_key];
	[coder encodeObject:myPath forKey:myPath_key];
}

- (id)initWithCoder:(NSCoder *)decoder {
	//self = [super initWithCoder:decoder];
	center.x = [decoder decodeFloatForKey:centerX_key];
	center.y = [decoder decodeFloatForKey:centerY_key];
	area = [decoder decodeFloatForKey:area_key];
	myPath = [[decoder decodeObjectForKey:myPath_key] retain];
	return self;
}	


@end
