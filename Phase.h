//
//  Phase.h
//  ModeMaker
//
//  Created by David Hirsch on 9/21/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ModeMakerDoc;
@class Particle;

@interface Phase : NSObject <NSCoding> {
	// all these properties should be found via Key-Value Observing from the model (ModeMakerDoc)
	NSMutableString	*name;	// the name of the phase
	ModeMakerDoc	*doc;	// my document
	int			lastPosition;
	int			shape;	// uses ShapeType NSArray of ModeMakerDoc
	float		modeTarget;	// the user's desired mode for this phase.
	float		mode;	// this represents the best measured mode of the phase.  That might be different than the desired, or target mode.
	float		modeTargetError;	// the allowable error (±) for the measured mode to be accepted
	float		size;	// the target size of the phase particles, measured as sqrt(area) of the typical object.  Measured in canvas units.
	float		sizeSD;	// the standard deviation of the size
	float		aspectRatio;	// the target aspect ratio (for rectangles, blobs, and polygons)
	float		aspectRatioSD;
	short		complexity;		// target number of control points on the path (for blobs and polygons) - does not include bezier handles
	float		complexitySD;
	float		fabricStrength;	// 0= no fabric (full rotation), 1=perfect fabric (no rotation)
	BOOL		allowReentrants;	// whether a blob/polygon may be concave
	BOOL		overlapping;	// non-overlapping would be for sedimentary particles
	NSColor		*color;	// the color in which this phase should be drawn
	NSMutableArray		*particles;	// array of particles
	
	// record of last-used settings:
	int			l_shape;	// uses ShapeType NSArray of ModeMakerDoc
	float		l_modeTarget;	// the user's desired mode for this phase.
	float		l_mode;	// this represents the best measured mode of the phase.  That might be different than the desired, or target mode.
	float		l_modeTargetError;	// the allowable error (±) for the measured mode to be accepted
	float		l_size;	// the target size of the phase particles, measured as sqrt(area) of the typical object.  Measured in canvas units.
	float		l_sizeSD;	// the standard deviation of the size
	float		l_aspectRatio;	// the target aspect ratio (for rectangles, blobs, and polygons)
	float		l_aspectRatioSD;
	short		l_complexity;		// target number of control points on the path (for blobs and polygons) - does not include bezier handles
	float		l_complexitySD;
	float		l_fabricStrength;
	BOOL		l_allowReentrants;	// whether a blob/polygon may be concave
	BOOL		l_overlapping;	// non-overlapping would be for sedimentary particles
}


- (ModeMakerDoc *) doc;
- (void) setDoc: (ModeMakerDoc*)input;
- (NSString *) name;
- (void) setName: (NSString*)input;
- (NSColor*) color;
- (void) setColor: (NSColor*)input;
- (NSArray*) particles;
- (void) setParticles: (NSArray*)input; 
- (float) mode;
- (void) setMode: (float)input;
- (BOOL) overlapping;
- (void) setOverlapping: (BOOL)input;
- (int) shape;
- (void) setShape: (int) input;
- (float) modeTarget;
- (void) setModeTarget: (float)input;
- (float) modeTargetError;
- (void) setModeTargetError: (float) input;
- (float) size;
- (void) setPhaseSize: (float) input;
- (float) sizeSD;
- (void) setSizeSD: (float) input;
- (float) aspectRatio;
- (void) setPhaseAR: (float) input;
- (float) aspectRatioSD;
- (void) setAspectRatioSD: (float) input;
- (short) complexity;
- (void) setComplexity: (short) input;
- (float) complexitySD;
- (void) setComplexitySD: (float) input;
- (float) fabricStrength;
- (void) setFabricStrength: (float) input;
- (int) lastPosition;
- (void) setLastPosition: (int) input;

- (float) shapeFactor;
- (id) initByNumber: (short) phaseNum;

- (void) draw;
- (BOOL) settingsHaveChanged;
- (BOOL) isModeCorrect;
- (BOOL)adjustModeAtIteration: (int) iterationNum;
- (BOOL) noOverlapWithParticle: (Particle *) thisParticle; 
- (BOOL) containsPoint: (NSPoint) inPoint;
- (BOOL) makeParticles;
- (BOOL) couldPlaceOneParticleRandomlyWithin: (NSRect) boundsRect totalArea: (float) inTotalArea ;
@end
