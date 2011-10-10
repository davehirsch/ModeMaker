//
//  OvalParticle.m
//  ModeMaker
//
//  Created by David Hirsch on 9/21/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import "OvalParticle.h"
#import "constants.h"

@implementation OvalParticle


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
	[super initWithBoundsRect:boundsRect
						 size: inSize
					   sizeSD: inSizeSD
				  aspectRatio: inAspectRatio
				aspectRatioSD: inAspectRatioSD
				  complexity : inComplexity
				complexitySD : inComplexitySD
			   fabricStrength: inFabricStrength
			 allowReentrants : inAllowReentrants ];
	rotation = (pi * (1-inFabricStrength) * (float) rand() / (float) RAND_MAX) - (0.5 * pi * (1-inFabricStrength));
	[self adaptToSizeWithAspectRatio: (float) inAspectRatio
				   aspectRatioStdDev: (float) inAspectRatioSD];
	return self;
}

- (BOOL) overlapsWith: (Particle *) inOtherParticle {
	float distance = sqrt((center.x - [inOtherParticle center].x) * (center.x - [inOtherParticle center].x) +
						  (center.y - [inOtherParticle center].y) * (center.y - [inOtherParticle center].y));
	OvalParticle * otherEllipse = (OvalParticle *) inOtherParticle;
	
	if (distance > (radius1 + [otherEllipse radius1])) {
		// quick check to see if they are way too far apart to overlap
		return NO;
	} else {
		// see if I contain any of the other
		// calculate a number of points on the edge of the other ellipse, and see if they are inside me
		short steps = 24;
		float sinRot = sin([otherEllipse rotation]);
		float cosRot = cos([otherEllipse rotation]);
		NSPoint otherCtr = [otherEllipse center];
		float semimajor = [otherEllipse radius1];
		float semiminor = [otherEllipse radius2];
		NSPoint thisPt;
		
		for (short i = 0; i < 360; i += 360 / steps) 
		{
			float alpha = i * (pi / 180) ;
			float sinalpha = sin(alpha);
			float cosalpha = cos(alpha);
			
			thisPt.x = otherCtr.x + (semimajor * cosalpha * cosRot - semiminor * sinalpha * sinRot);
			thisPt.y = otherCtr.y + (semimajor * cosalpha * sinRot + semiminor * sinalpha * cosRot);
			
			if ([self containsPoint:thisPt]) {
				return YES;
			}
		}
	}
	return NO;
}

- (BOOL) containsPoint: (NSPoint) inPoint {
	return [myPath containsPoint:inPoint];
}

- (void) adaptToSizeWithAspectRatio: (float) inAspectRatio
				  aspectRatioStdDev: (float) inAspectRatioStdDev {
	[myPath removeAllPoints];
	float myAR = [self normalValueWithMean: inAspectRatio standardDev: inAspectRatioStdDev];
	// Note that the NumberFormatter restricts ARs to the range [1,100]
	
	myAR = (myAR < kSmallestAspectRatio) ? kSmallestAspectRatio : myAR;
	
	radius1 = sqrt(myAR * area / pi);
	radius2 = sqrt(area / myAR / pi);
	
	NSRect particleRect = NSMakeRect(-radius1, -radius2, 2*radius1, 2*radius2);
	NSAffineTransform *transform = [NSAffineTransform transform];
	[myPath appendBezierPathWithOvalInRect:particleRect];	// path is now a rectangle centered on the origin
	[transform translateXBy: center.x yBy:center.y];
	[transform rotateByRadians:rotation]; // counterclockwise rotation
	[myPath transformUsingAffineTransform: transform];
}


- (float) radius1 {return radius1;}
- (void) setRadius1: (float) input {radius1 = input;}
- (float) radius2 {return radius2;}
- (void) setRadius2: (float) input {radius2 = input;}
- (float) rotation {return rotation;}
- (void) setRotation: (float) input {rotation = input;}

#define radius1_key @"radius1"
#define radius2_key @"radius2"
#define rotation_key @"rotation"
- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeFloat:radius1 forKey:radius1_key];
	[coder encodeFloat:radius2 forKey:radius2_key];
	[coder encodeFloat:rotation forKey:rotation_key];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	radius1 = [decoder decodeFloatForKey:radius1_key];
	radius2 = [decoder decodeFloatForKey:radius2_key];
	rotation = [decoder decodeFloatForKey:rotation_key];
	return self;
}
@end
