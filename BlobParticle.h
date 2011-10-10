//
//  BlobParticle.h
//  ModeMaker
//
//  Created by David Hirsch on 9/24/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Particle.h"



@interface BlobParticle : Particle <NSCoding> {
	float		rotation;	// value from 0-pi represents counter-clockwise rotation from orthogonal
	BOOL		pathIsAtCenter;	// whether the path has already been moved to its recorded center or not.
}


- (void) adaptToSizeWithAspectRatio: (float) inAspectRatio
				  aspectRatioStdDev: (float) inAspectRatioStdDev
						 complexity: (short) inComplexity
					   complexitySD: (float) inComplexitySD
					allowReentrants: (BOOL) inAllowReentrants;

- (float) pathArea;
- (void) blobFromPolygon;
- (NSPointArray) getControlPointsForCurrentVertex: (NSPoint) pt1
									   nextVertex: (NSPoint) pt2
								   pointAfterNext: (NSPoint) pt3
									   prevVertex: (NSPoint) pt0;	
@end
