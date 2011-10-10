//
//  Phase.m
//  ModeMaker
//
//  Created by David Hirsch on 9/21/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import "Phase.h"
#import "Particle.h"
#import "ModeMakerDoc.h"
#import "OvalParticle.h"
#import "RectangleParticle.h"
#import "BlobParticle.h"
#import "PolygonParticle.h"
#import "constants.h"

@implementation Phase

- (id) initByNumber: (short) phaseNum {

    self = [super init];
    if (self) {
		[self setParticles: [NSArray array]];	// create empty array
		if (!particles)	{ // if array was not created
			[self release];
			return nil;
		}
		
		// Defaults for new phases:
		modeTargetError = 1;
		aspectRatio = 1;	// the target aspect ratio (for rectangles, blobs, and polygons)
		aspectRatioSD = 0;
		complexity = 5;		// target number of control points on the path (for blobs and polygons) - does not include bezier handles
		complexitySD = 2;
		allowReentrants = YES;	// whether a blob/polygon may be concave
		fabricStrength = 0;
		lastPosition = -1;
		
		switch (phaseNum) {
			case 0:
				[self setName: @"Phase A"];
				[self setColor: [NSColor blackColor]];
				size = 50;
				sizeSD = 10;
				allowReentrants = NO;	// whether a blob/polygon may be concave
				overlapping = NO;
				shape = 3; // Polygon, defined in ModeMakerDoc
				modeTarget = 20;
				break;
			case 1:
				[self setName: @"Phase B"];
				[self setColor: [NSColor redColor]];
				size = 20;
				sizeSD = 1;
				modeTarget = 10;
				overlapping = YES;
				aspectRatio = 1;	// the target aspect ratio (for rectangles, blobs, and polygons)
				aspectRatioSD = 0;
				shape = 1; // Rect, defined in ModeMakerDoc
				break;
			case 2:
				[self setName: @"Phase C"];
				[self setColor: [NSColor greenColor]];
				size = 7;
				sizeSD = 0.1;
				modeTarget = 10;
				overlapping = YES;
				shape = 1; // Rectangle, defined in ModeMakerDoc
				aspectRatio = 3;	// the target aspect ratio (for rectangles, blobs, and polygons)
				aspectRatioSD = 1;
				break;
			case 3:
				[self setName: @"Phase D"];
				[self setColor: [NSColor blueColor]];
				size = 80;
				sizeSD = 30;
				modeTarget = 10;
				overlapping = NO;
				aspectRatio = 1;	// the target aspect ratio (for rectangles, blobs, and polygons)
				aspectRatioSD = 0;
				shape = 0; // Oval, defined in ModeMakerDoc
				break;
			case 4:
				[self setName: @"Phase E"];
				[self setColor: [NSColor purpleColor]];
				size = 8;
				sizeSD = 1;
				modeTarget = 6;
				overlapping = YES;
				shape = 2; // Blob, defined in ModeMakerDoc
				break;
			default:
				break;
		}
	}
    return self;
}


- (ModeMakerDoc *) doc {return doc;}
- (void) setDoc: (ModeMakerDoc*)input {
	doc = input;	// don't retain this, since we don't really own the document
}
- (NSString *) name {return name;}
- (void) setName: (NSString*)input {
    if (input != name) {
		NSUndoManager *undoer = [doc undoManager];
        [undoer registerUndoWithTarget:self
								   selector:@selector(setName:)
									 object:name];
		[undoer setActionName: @"Name Change"];
	}
	[name autorelease];
	name = [input retain];
}
- (NSColor*) color {return color;}
- (void) setColor: (NSColor*)input {
    if (input != color) {
		NSUndoManager *undoer = [doc undoManager];
        [undoer registerUndoWithTarget:self
								   selector:@selector(setColor:)
									 object:color];
       [undoer setActionName: @"Phase Color Change"];
	}
	[color autorelease];
	color = [input retain];
}
- (NSArray*) particles {return particles;}
- (void) setParticles: (NSArray*)input {
	[particles autorelease];
	particles = [input retain];
}
- (float) modeTarget {return modeTarget;}
- (void) setModeTarget: (float)input {
    if (input != modeTarget) {
		NSUndoManager *undoer = [doc undoManager];
        [[undoer prepareWithInvocationTarget:self] setModeTarget:modeTarget];
        [undoer setActionName: @"Mode Target Change"];
		modeTarget = input;
	}
}
- (float) mode {return mode;}
- (void) setMode: (float)input {
    [self willChangeValueForKey:@"mode"];
	mode = input;
    [self didChangeValueForKey:@"mode"];
}
- (BOOL) overlapping {return overlapping;}
- (void) setOverlapping: (BOOL)input {
    if (input != overlapping) {
		NSUndoManager *undoer = [doc undoManager];
        [[undoer prepareWithInvocationTarget:self] setOverlapping:overlapping];
        [undoer setActionName: @"Overlap Setting Change"];
		overlapping = input;
	}
}

- (int) shape {return shape;}
- (void) setShape: (int) input {
    if (input != shape) {
		NSUndoManager *undoer = [doc undoManager];
        [[undoer prepareWithInvocationTarget:self] setShape:shape];
        [undoer setActionName: @"Phase Shape Change"];
		shape = input;
	}
}

- (float) modeTargetError {return modeTargetError;}
- (void) setModeTargetError: (float) input {
    if (input != modeTargetError) {
		NSUndoManager *undoer = [doc undoManager];
        [[undoer prepareWithInvocationTarget:self] setModeTargetError:modeTargetError];
        [undoer setActionName: @"Mode Target Error Change"];
		modeTargetError = input;
	}
}
- (float) size {return size;}
- (void) setPhaseSize: (float) input {
    if (input != size) {
		NSUndoManager *undoer = [doc undoManager];
        [[undoer prepareWithInvocationTarget:self] setPhaseSize:size];
        [undoer setActionName: @"Size Change"];
		size = input;
	}
}

- (float) sizeSD {return sizeSD;}
- (void) setSizeSD: (float) input {
    if (input != sizeSD) {
		NSUndoManager *undoer = [doc undoManager];
        [[undoer prepareWithInvocationTarget:self] setSizeSD:sizeSD];
        [undoer setActionName: @"Size Std. Dev. Change"];
		sizeSD = input;
	}
}	
	
- (float) aspectRatio {return aspectRatio;}
- (void) setPhaseAR: (float) input {
    if (input != aspectRatio) {
		NSUndoManager *undoer = [doc undoManager];
        [[undoer prepareWithInvocationTarget:self] setPhaseAR:aspectRatio];
        [undoer setActionName: @"Aspect Ratio Change"];
		aspectRatio = input;
	}
}

- (float) aspectRatioSD {return aspectRatioSD;}
- (void) setAspectRatioSD: (float) input {
    if (input != aspectRatioSD) {
		NSUndoManager *undoer = [doc undoManager];
        [[undoer prepareWithInvocationTarget:self] setAspectRatioSD:aspectRatioSD];
        [undoer setActionName: @"Aspect Ratio Std. Dev. Change"];
		aspectRatioSD = input;
	}
}

- (short) complexity {return complexity;}
- (void) setComplexity: (short) input {
    if (input != complexity) {
		NSUndoManager *undoer = [doc undoManager];
        [[undoer prepareWithInvocationTarget:self] setComplexity:complexity];
        [undoer setActionName: @"Complexity Change"];
		complexity = input;
	}
}

- (float) complexitySD {return complexitySD;}
- (void) setComplexitySD: (float) input {
    if (input != complexitySD) {
		NSUndoManager *undoer = [doc undoManager];
        [[undoer prepareWithInvocationTarget:self] setComplexitySD:complexitySD];
        [undoer setActionName: @"Complexity Std. Dev. Change"];
		complexitySD = input;
	}
}

- (float) fabricStrength {return fabricStrength;}
- (void) setFabricStrength: (float) input {
    if (input != fabricStrength) {
		NSUndoManager *undoer = [doc undoManager];
        [[undoer prepareWithInvocationTarget:self] setFabricStrength:fabricStrength];
        [undoer setActionName: @"Fabric Strength Change"];
		fabricStrength = input;
	}
}

- (BOOL) allowReentrants {return allowReentrants;}
- (void) setAllowReentrants: (BOOL) input {
    if (input != allowReentrants) {
		NSUndoManager *undoer = [doc undoManager];
        [[undoer prepareWithInvocationTarget:self] setAllowReentrants:allowReentrants];
        [undoer setActionName: @"Reentrancy Change"];
		allowReentrants = input;
	}
}

- (int) lastPosition {return lastPosition;}
- (void) setLastPosition: (int) input {lastPosition = input;}



- (void) dealloc {
	[name release];
	[color release];
	[particles release];
	[super dealloc];
}

- (void) draw
{
	[color setFill];
	long numParticles = [particles count];
	for (long i=0; i < numParticles; i++) {
		Particle *thisParticle = [particles objectAtIndex:i];
		[thisParticle draw];
	}
}

- (BOOL) settingsHaveChanged {
	if ((shape != l_shape) || 
		(size != l_size) || 
		(overlapping != l_overlapping) || 
		(sizeSD != l_sizeSD) ||
		(l_aspectRatio != aspectRatio) ||
		(l_aspectRatioSD != aspectRatioSD) ||
		(l_complexity != complexity) ||
		(l_complexitySD != complexitySD) ||
		(l_fabricStrength != fabricStrength) ||
		(l_allowReentrants != allowReentrants))
			return YES;

	// check to see if the measured mode is still within acceptable bounds - if the user expanded the error, then nothing needs to be done, for example
	if (fabs(mode - modeTarget) > modeTargetError) return YES;
	
	return NO;
}

- (BOOL) makeParticles {
	NSSize canvasSize = [doc getCanvasSize];
	float marginFactor = 0.1;
	NSRect boundsRect = NSMakeRect(-(canvasSize.width) * marginFactor , -(canvasSize.height) * marginFactor, canvasSize.width * (1 + 2*marginFactor) , canvasSize.height * (1 + 2*marginFactor));
	float totalArea = boundsRect.size.width * boundsRect.size.height;
	[particles autorelease];
	float modeOccupied = [doc getRoughModeUpTo: self];
	int numberOfParticles = round(modeTarget * 0.01 * totalArea / ((size * size) * (1.0 - modeOccupied * 0.01)));
	particles = [NSMutableArray array];
	[particles retain];
	BOOL foundUnplaceable = YES;
	for (int loopNum = 0; (loopNum < kNumRetries) && foundUnplaceable; loopNum++) {
		foundUnplaceable = NO;
		for (int i=0; (i < numberOfParticles) && !foundUnplaceable; i++) {
			foundUnplaceable = ![self couldPlaceOneParticleRandomlyWithin: boundsRect totalArea: totalArea];
		}	// end for numberOfParticles
		if (foundUnplaceable) {
			// failed to place a particle, so try removing the first 10%, and adding them back in new random spots
			long numToRemove = floor([particles count] * 0.1);
			[particles removeObjectsInRange: NSMakeRange(0, numToRemove)];
			for (int i=0; i < numToRemove; i++) {
				[self couldPlaceOneParticleRandomlyWithin: boundsRect totalArea: totalArea];
			}	// end for numToRemove
		}
	}
	
	if (!foundUnplaceable) {
		// record settings used to make particles
		l_shape = shape;
		l_modeTarget = modeTarget;
		l_modeTargetError = modeTargetError;
		l_size = size;
		l_sizeSD = sizeSD;
		l_overlapping = overlapping;
		l_aspectRatio = aspectRatio;	
		l_aspectRatioSD = aspectRatioSD;
		l_complexity = complexity;		
		l_complexitySD = complexitySD;
		l_fabricStrength = fabricStrength;
		l_allowReentrants = allowReentrants;
	}
	return !foundUnplaceable;
}

- (BOOL) couldPlaceOneParticleRandomlyWithin: (NSRect) boundsRect totalArea: (float) inTotalArea {
	Particle *thisParticle;
	switch (shape) {
		case 0: {	// Oval
			thisParticle = [[OvalParticle alloc] initWithBoundsRect:boundsRect
																 size:(size)
															   sizeSD:(sizeSD)
														  aspectRatio: aspectRatio
														aspectRatioSD: aspectRatioSD
														  complexity : complexity
														complexitySD : complexitySD
													   fabricStrength: fabricStrength
													 allowReentrants : allowReentrants];
		} break;
		case 1: {	// Rectangle
			thisParticle = [[RectangleParticle alloc] initWithBoundsRect:boundsRect
																	size:(size)
																  sizeSD:(sizeSD)
															 aspectRatio: aspectRatio
														   aspectRatioSD: aspectRatioSD
															 complexity : complexity
														   complexitySD : complexitySD
														  fabricStrength: fabricStrength
														allowReentrants : allowReentrants ];
		} break;
		case 2: {	// Blob
			thisParticle = [[BlobParticle alloc] initWithBoundsRect:boundsRect
															   size:(size)
															 sizeSD:(sizeSD)
														aspectRatio: aspectRatio
													  aspectRatioSD: aspectRatioSD
														complexity : complexity
													  complexitySD : complexitySD
													 fabricStrength: fabricStrength
												   allowReentrants : allowReentrants ];
		} break;
		case 3: {	// Polygon
			thisParticle = [[PolygonParticle alloc] initWithBoundsRect:boundsRect
																  size:(size)
																sizeSD:(sizeSD)
														   aspectRatio: aspectRatio
														 aspectRatioSD: aspectRatioSD
														   complexity : complexity
														 complexitySD : complexitySD
														fabricStrength: fabricStrength
													  allowReentrants : allowReentrants ];
		} break;
	}
	if (!overlapping) {	// no overlaps allowed
		bool goodPlacing = false;
		for (long j=0; (j < kNumParticlePlacingAttempts) && (!goodPlacing); j++) {
			[thisParticle initWithBoundsRect:boundsRect
										size:(size)
									  sizeSD:(sizeSD)
								 aspectRatio: aspectRatio
							   aspectRatioSD: aspectRatioSD
								 complexity : complexity
							   complexitySD : complexitySD
							  fabricStrength: fabricStrength
							allowReentrants : allowReentrants ];
			goodPlacing = [self noOverlapWithParticle: thisParticle]; 
		}
		if (!goodPlacing) {
			// failure to place particle - clean up
			[particles removeAllObjects];	//TODO Check this - perhaps just report up the chain, but don't remove all particles?
			return NO;
		}
	}
	[particles addObject:thisParticle];
	return YES;
}

- (BOOL) isModeCorrect {
	return (fabs(mode - modeTarget) <= modeTargetError);
}

- (float) shapeFactor {
	switch (shape) {
		case 1: // Rectangle
			return 1.0;
			break;
		case 0: // Oval
		case 2: // Blob
		case 3: // Polygon
			return pi / 4;	// the area of one of these is not size^2, but less
	}
	return -1;	// should never get here
}

- (BOOL)adjustModeAtIteration: (int) iterationNum {
	// based on the difference between the (measured) mode and the target
	// mode, either add or remove particles
	float additionalModeNeeded = modeTarget - mode;

	NSSize canvasSize = [doc getCanvasSize];
	NSRect boundsRect = NSMakeRect(-(canvasSize.width) * 0.1 , -(canvasSize.height) * 0.1 , canvasSize.width * 1.2 , canvasSize.height * 1.2);
	float boundsArea = boundsRect.size.width * boundsRect.size.height;
	float modeOccupied = [doc getRoughModeUpTo: self];
	float additionalAreaNeeded = additionalModeNeeded * boundsArea / 100.0;
	additionalAreaNeeded *= 3.8 - (3 * erff((iterationNum - 5.0) / 3.0));	// this factor makes things change faster earlier in the iterations, and slower later (converges to ~0.8 factor after iteration 10 or so)
	float oneParticleArea = size * size * [self shapeFactor];
	oneParticleArea *= (100.0 - modeOccupied) / 100.0;	// the modeOccupied fraction of each particle will be covered, and will not contribute to the particle's final mode
	short additionalParticlesNeeded = floor(additionalAreaNeeded / oneParticleArea);	// this assumes that the shape is a square
	additionalParticlesNeeded = (additionalParticlesNeeded > kMaxParticlesToAddAtOnce) ? kMaxParticlesToAddAtOnce : additionalParticlesNeeded;
	if ([particles count] == 0 && additionalParticlesNeeded == 0) {
		// if the particles are big and the modeTarget is small, then we might get here.  We can't use the size changing branch below, since there
		// are no existing particles whose size we can alter
		additionalParticlesNeeded = 1;
	}

	if (additionalParticlesNeeded > 0) {
		BOOL foundUnplaceable = YES;
		// loop kNumRetries times as long as there was a problem; If foundUnplaceable is NO, then we've succeeded
		for (int loopNum = 0; (loopNum < kNumRetries) && foundUnplaceable; loopNum++) {
			NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
			foundUnplaceable = NO;
			for (int i=0; (i < additionalParticlesNeeded) && !foundUnplaceable; i++) {
				foundUnplaceable = ![self couldPlaceOneParticleRandomlyWithin: boundsRect totalArea: boundsArea];
			}	// end for numberOfParticles
			if (foundUnplaceable) {
				// failed to place a particle, so try removing the first 10%, and adding them back in new random spots
				long numToRemove = floor([particles count] * 0.1);
				[particles removeObjectsInRange: NSMakeRange(0, numToRemove)];
				for (int i=0; i < numToRemove; i++) {
					[self couldPlaceOneParticleRandomlyWithin: boundsRect totalArea: boundsArea];
				}	// end for numToRemove
			}
			[subPool release]; 
		}
		if (foundUnplaceable) {
			// we were unable to place all needed particles, even with looping kNumRetries times - doc will post an alert
			return NO;
		}
	} else if (additionalParticlesNeeded < 0) {
		if (-additionalParticlesNeeded > [particles count] / 2.0) {	// if we are trying to remove more than half of the existing number of particles
			additionalParticlesNeeded = -([particles count]/2.0);
		}
		if (additionalParticlesNeeded == 0)	// there was only a single (big) particle, and the previous statement said we could only remove half of that one.  Just remove it here.
			additionalParticlesNeeded = -1;
		for (int i = 0; i < -additionalParticlesNeeded; i++) {
			[particles removeLastObject];
		}
	} else {
		// fewer than 1 additional Particles needed - try adjusting sizes of particles
		float areaAdjustment = additionalAreaNeeded / [particles count];
		
		// algorithm was exploding here I think; this should calm things down
		float currentArea = (size*size);
		if (areaAdjustment < -(currentArea))
			areaAdjustment = -(currentArea)/2.0;
		if (areaAdjustment > (currentArea))
			areaAdjustment = (currentArea)/2.0;
		float areaFactor = (currentArea + areaAdjustment) / currentArea;
		for (int i=0; i < [particles count]; i++) {
			[(Particle *)[particles objectAtIndex:i] adjustAreaByFactor: areaFactor];
		}
	}
	return YES;
}

- (BOOL) containsPoint: (NSPoint) inPoint {
	for (int i=0; i < [particles count]; i++) {
		if ([(Particle *)[particles objectAtIndex:i] containsPoint: inPoint])
			return true;
	}
	return false;
}

- (BOOL) noOverlapWithParticle: (Particle *) thisParticle {
	for (int i=0; i < [particles count]; i++) {
		if ([(Particle *)[particles objectAtIndex:i] overlapsWith: thisParticle])
			return false;
	}
	return true;
}

#define name_key @"name"
#define doc_key @"doc"
#define shape_key @"shape"
#define modeTarget_key @"modeTarget"
#define mode_key @"mode"
#define modeTargetError_key @"modeTargetError"
#define size_key @"size"
#define sizeSD_key @"sizeSD"
#define aspectRatio_key @"aspectRatio"
#define aspectRatioSD_key @"aspectRatioSD"
#define complexity_key @"complexity"
#define complexitySD_key @"complexitySD"
#define allowReentrants_key @"allowReentrants"
#define overlapping_key @"overlapping"
#define color_key @"color"
#define particles_key @"particles"
#define fabricStrength_key @"fabricStrength"

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:name forKey:name_key];
	[coder encodeConditionalObject:doc forKey:doc_key];
	[coder encodeInt:shape forKey:shape_key];
	[coder encodeFloat:modeTarget forKey:modeTarget_key];
	[coder encodeFloat:mode forKey:mode_key];
	[coder encodeFloat:modeTargetError forKey:modeTargetError_key];
	[coder encodeFloat:size forKey:size_key];
	[coder encodeFloat:sizeSD forKey:sizeSD_key];
	[coder encodeFloat:aspectRatio forKey:aspectRatio_key];
	[coder encodeFloat:aspectRatioSD forKey:aspectRatioSD_key];
	[coder encodeInt:complexity forKey:complexity_key];
	[coder encodeFloat:complexitySD forKey:complexitySD_key];
	[coder encodeFloat:fabricStrength forKey:fabricStrength_key];
	[coder encodeBool:allowReentrants forKey:allowReentrants_key];
	[coder encodeBool:overlapping forKey:overlapping_key];
	[coder encodeObject:color forKey:color_key];
	[coder encodeObject:particles forKey:particles_key];
	// don't need to encode the l_ variables - they don't need to be saved
}

- (id)initWithCoder:(NSCoder *)decoder {
	//self = [super initWithCoder:decoder];
	name = [[decoder decodeObjectForKey:name_key] retain];
	doc = [decoder decodeObjectForKey:doc_key];
	shape = [decoder decodeIntForKey:shape_key];
	modeTarget = [decoder decodeFloatForKey:modeTarget_key];
	mode = [decoder decodeFloatForKey:mode_key];
	modeTargetError = [decoder decodeFloatForKey:modeTargetError_key];
	size = [decoder decodeFloatForKey:size_key];
	sizeSD = [decoder decodeFloatForKey:sizeSD_key];
	aspectRatio = [decoder decodeFloatForKey:aspectRatio_key];
	aspectRatioSD = [decoder decodeFloatForKey:aspectRatioSD_key];
	complexity = [decoder decodeIntForKey:complexity_key];
	complexitySD = [decoder decodeFloatForKey:complexitySD_key];
	fabricStrength = [decoder decodeFloatForKey:fabricStrength_key];
	allowReentrants = [decoder decodeBoolForKey:allowReentrants_key];
	overlapping = [decoder decodeBoolForKey:overlapping_key];
	color = [[decoder decodeObjectForKey:color_key] retain];
	particles = [[decoder decodeObjectForKey:particles_key] retain];
	
	// set the last-used parameters to the loaded parameters
	l_shape = shape;
	l_modeTarget = modeTarget;
	l_mode = mode;
	l_modeTargetError = modeTargetError;
	l_size = size;
	l_sizeSD = sizeSD;
	l_aspectRatio = aspectRatio;
	l_aspectRatioSD = aspectRatioSD;
	l_complexity = complexity;
	l_complexitySD = complexitySD;
	l_allowReentrants = allowReentrants;
	l_overlapping = overlapping;
	l_fabricStrength = fabricStrength;
	
	return self;
}	

@end
