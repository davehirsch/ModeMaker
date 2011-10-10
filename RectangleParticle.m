//
//  RectangleParticle.m
//  ModeMaker
//
//  Created by David Hirsch on 9/24/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import "RectangleParticle.h"
#import "constants.h"

@implementation RectangleParticle

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
	rotation = (pi * (1-inFabricStrength) * (float) rand() / (float) RAND_MAX) - (0.5 * pi * (1-inFabricStrength));
	[self adaptToSizeWithAspectRatio: inAspectRatio aspectRatioStdDev: inAspectRatioSD];	// this is where we set the edge lengths
	return self;
}

- (float) maxDistance {
	return sqrt(edge1Length * edge1Length * 0.25 + edge2Length * edge2Length * 0.25);
}

- (BOOL) overlapsWith: (Particle *) inOtherParticle {

	float distance = sqrt((center.x - [inOtherParticle center].x) * (center.x - [inOtherParticle center].x) +
						  (center.y - [inOtherParticle center].y) * (center.y - [inOtherParticle center].y));
	if (distance > ([self maxDistance] + [(RectangleParticle *)inOtherParticle maxDistance])) {
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

- (void) adaptToSizeWithAspectRatio: (float) inAspectRatio
				  aspectRatioStdDev: (float) inAspectRatioStdDev {
	[myPath removeAllPoints];
	float myAR = [self normalValueWithMean: inAspectRatio standardDev: inAspectRatioStdDev];
		// Note that the NumberFormatter restricts ARs to the range [1,100]
	
	myAR = (myAR < kSmallestAspectRatio) ? kSmallestAspectRatio : myAR;
	
	edge1Length = sqrt(myAR * area);
	edge2Length = sqrt(area / myAR);
	
	NSRect particleRect = NSMakeRect(-edge1Length * 0.5, -edge2Length * 0.5, edge1Length, edge2Length);
	NSAffineTransform *transform = [NSAffineTransform transform];
	[myPath appendBezierPathWithRect:particleRect];	// path is now a rectangle centered on the origin
	[transform translateXBy: center.x yBy:center.y];
	[transform rotateByRadians:rotation]; // counterclockwise rotation
	[myPath transformUsingAffineTransform: transform];
}

- (BOOL) containsPoint: (NSPoint) inPoint {
	return [myPath containsPoint:inPoint];
}

- (float) edge1Length {return edge1Length;}
- (void) setEdge1Length: (float) input {edge1Length = input;}
- (float) edge2Length {return edge2Length;}
- (void) setEdge2Length: (float) input {edge2Length = input;}
- (float) rotation {return rotation;}
- (void) setRotation: (float) input {rotation = input;}

#define edge1Length_key @"edge1Length"
#define edge2Length_key @"edge2Length"
#define rotation_key @"rotation"
- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeFloat:edge1Length forKey:edge1Length_key];
	[coder encodeFloat:edge2Length forKey:edge2Length_key];
	[coder encodeFloat:rotation forKey:rotation_key];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	edge1Length = [decoder decodeFloatForKey:edge1Length_key];
	edge2Length = [decoder decodeFloatForKey:edge2Length_key];
	rotation = [decoder decodeFloatForKey:rotation_key];
	return self;
}
@end
