//
//  SquareParticle.h
//  ModeMaker
//
//  Created by David Hirsch on 9/24/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Particle.h"


@interface SquareParticle : Particle <NSCoding> {
	float		edgeLength;
	float		rotation;	// value from 0-pi/2 represents counter-clockwise rotation from orthogonal
}

- (float) edgeLength;
- (void) setEdgeLength: (float) input;

- (float) rotation;
- (void) setRotation: (float) input;

@end
