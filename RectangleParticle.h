//
//  RectangleParticle.h
//  ModeMaker
//
//  Created by David Hirsch on 9/24/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Particle.h"


@interface RectangleParticle : Particle <NSCoding> {
	float		edge1Length;	// vertical edge before rotation
	float		edge2Length;	// horizontal edge before rotation
	float		rotation;	// value from 0-pi represents counter-clockwise rotation from orthogonal
}


- (void) adaptToSizeWithAspectRatio: (float) inAspectRatio
				  aspectRatioStdDev: (float) inAspectRatioStdDev;

- (float) edge1Length;
- (void) setEdge1Length: (float) input;
- (float) edge2Length;
- (void) setEdge2Length: (float) input;
- (float) maxDistance;

- (float) rotation;
- (void) setRotation: (float) input;

@end
