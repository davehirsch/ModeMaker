//
//  Particle.h
//  ModeMaker
//
//  Created by David Hirsch on 9/21/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Particle : NSObject <NSCoding> {
	NSPoint		center;
	float		area;
	NSBezierPath	*myPath;
}
@end

@interface Particle (Abstract)

- (void) draw;
- (float) normalValueWithMean: (float) inMean
				  standardDev:(float) inSD;
- (BOOL) containsPoint: (NSPoint) inPoint;
- (id) initWithBoundsRect: (NSRect) boundsRect
					 size: (float) inSize 
				   sizeSD: (float) inSizeSD
			  aspectRatio: (float) inAspectRatio
			aspectRatioSD: (float) inAspectRatioSD
			   complexity: (short) inComplexity
			 complexitySD: (float) inComplexitySD
		   fabricStrength: (float) inFabricStrength
		  allowReentrants: (BOOL) inAllowReentrants;
- (BOOL) overlapsWith: (Particle *) inOtherParticle;

- (NSPoint) center;
- (void) setCenter: (NSPoint)input;
- (void) adjustAreaByFactor: (float) areaFactor;
- (void) adaptToSize;

- (NSBezierPath *) path;
@end
