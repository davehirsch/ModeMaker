//
//  OvalParticle.h
//  ModeMaker
//
//  Created by David Hirsch on 9/21/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Particle.h"

@interface OvalParticle : Particle <NSCoding> {
	float		radius1;	// semi-major axis
	float		radius2;	// semi-minor axis
	float		rotation;	// value from 0-pi represents counter-clockwise rotation from orthogonal
}

- (float) radius1;
- (void) setRadius1: (float) input;
- (float) radius2;
- (void) setRadius2: (float) input;
- (void) adaptToSizeWithAspectRatio: (float) inAspectRatio
				  aspectRatioStdDev: (float) inAspectRatioStdDev;
- (float) rotation;
- (void) setRotation: (float) input;

@end
