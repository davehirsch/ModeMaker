//
//  SquareParticle.m
//  ModeMaker
//
//  Created by David Hirsch on 9/24/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import "SquareParticle.h"


@implementation SquareParticle

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
	// Particle superclass deals with most parameters
	rotation = pi * 0.5 * (float) rand() / (float) RAND_MAX;
	[self adaptToSize];
	return self;
}

- (BOOL) overlapsWith: (Particle *) inOtherParticle {
	float distance = sqrt((center.x - [inOtherParticle center].x) * (center.x - [inOtherParticle center].x) +
						  (center.y - [inOtherParticle center].y) * (center.y - [inOtherParticle center].y));
	float sqrt2 = sqrt(2.0);
	if (distance > (edgeLength / sqrt2 + [(SquareParticle *)inOtherParticle edgeLength] / sqrt2)) {
		// quick check to see if they are way too far apart to overlap
		return NO;
	} else {
		// see if I contain any of the vertices of the other, then
		NSBezierPath *otherPath = [inOtherParticle path];
		NSPoint points[3];
		for (short i = 0; i < [otherPath elementCount]; i++) {
			[otherPath elementAtIndex: i associatedPoints: points];
			if ([myPath containsPoint: points[0]]) {
				return YES;
			}
		}
		// see if the other contains any of my vertices
		for (short i = 0; i < [otherPath elementCount]; i++) {
			[myPath elementAtIndex: i associatedPoints: points];
			if ([otherPath containsPoint:points[0]]) {
				return YES;
			}
		}
	}
	
	return NO;
}

- (void) adaptToSize {
	[myPath removeAllPoints];
	edgeLength = sqrt(area);
	NSRect particleRect = NSMakeRect(-edgeLength * 0.5, -edgeLength * 0.5, edgeLength, edgeLength);
	NSAffineTransform *transform = [NSAffineTransform transform];
	[myPath appendBezierPathWithRect:particleRect];	// path is now a square centered on the origin
	[transform translateXBy: center.x yBy:center.y];
	[transform rotateByRadians:rotation]; // counterclockwise rotation
	[myPath transformUsingAffineTransform: transform];
}

- (BOOL) containsPoint: (NSPoint) inPoint {
	return [myPath containsPoint:inPoint];
}

- (float) edgeLength {return edgeLength;}
- (void) setEdgeLength: (float) input {edgeLength = input;}
- (float) rotation {return rotation;}
- (void) setRotation: (float) input {rotation = input;}

#define rotation_key @"rotation"
#define edgeLength_key @"edgeLength"
- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeFloat:edgeLength forKey:edgeLength_key];
	[coder encodeFloat:rotation forKey:rotation_key];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	edgeLength = [decoder decodeFloatForKey:edgeLength_key];
	rotation = [decoder decodeFloatForKey:rotation_key];
	return self;
}
@end
