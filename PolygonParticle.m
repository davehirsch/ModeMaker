//
//  PolygonParticle.m
//  ModeMaker
//
//  Created by David Hirsch on 9/24/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import "PolygonParticle.h"
#import "constants.h"

@implementation PolygonParticle

- (id) initWithBoundsRect: (NSRect) boundsRect
					 size: (float) inSize 
				   sizeSD: (float) inSizeSD
			  aspectRatio: (float) inAspectRatio
			aspectRatioSD: (float) inAspectRatioSD
			   complexity: (short) inComplexity
			 complexitySD: (float) inComplexitySD
		   fabricStrength: (float) inFabricStrength
		  allowReentrants: (BOOL) inAllowReentrants

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
	pathIsAtCenter = NO;
	rotation = (pi * (1-inFabricStrength) * (float) rand() / (float) RAND_MAX) - (0.5 * pi * (1-inFabricStrength));

	[self adaptToSizeWithAspectRatio: inAspectRatio 
				   aspectRatioStdDev: inAspectRatioSD
						  complexity: inComplexity
						complexitySD: inComplexitySD
					 allowReentrants: inAllowReentrants];	// this is where we set the edge lengths
	return self;
}


- (BOOL) overlapsWith: (Particle *) inOtherParticle {
	// quick check to see if our bounding boxes intersect
	NSRect myBoundsRect = [myPath bounds];
	NSRect otherBoundsRect = [[inOtherParticle path] bounds];
	NSRect intersection = NSIntersectionRect(myBoundsRect, otherBoundsRect);
	if (intersection.size.width == 0 && intersection.size.height == 0)
		return NO;
	
	
	// Now see if any of my line segments intersect any of the other's line segments
	// First, extract the points into arrays for fast access:
	NSBezierPath *otherPath = [inOtherParticle path];
	NSPoint points[3];
	NSPoint myPts[kMaxNumPolygonPoints];
	NSPoint otherPts[kMaxNumPolygonPoints];
	short myNumPts = 0;
	short otherNumPts = 0;
	
	for (short i = 0; i < [myPath elementCount]; i++) {
		NSBezierPathElement element = [myPath elementAtIndex: i associatedPoints: points];
		if (element == NSLineToBezierPathElement) {
			myPts[myNumPts++] = points[0];
		}
	}

	for (short i = 0; i < [otherPath elementCount]; i++) {
		NSBezierPathElement element = [otherPath elementAtIndex: i associatedPoints: points];
		if (element == NSLineToBezierPathElement) {
			otherPts[otherNumPts++] = points[0];
		}
	}
	
	// Now we have the points extracted, so loop through both paths, comparing all line segments.  If any intersect, then we overlap
	for (short myPtNum = 0; myPtNum < myNumPts; myPtNum++) {
		NSPoint myCurPt = myPts[myPtNum];
		NSPoint myNextPt = myPts[(myPtNum < myNumPts-1) ? myPtNum+1 : 0];
		for (short otherPtNum = 0; otherPtNum < otherNumPts; otherPtNum++) {
			NSPoint otherCurPt = otherPts[otherPtNum];
			NSPoint otherNextPt = otherPts[(otherPtNum < otherNumPts-1) ? otherPtNum+1 : 0];
			
			// now we test for intersection.  Math from: http://local.wasp.uwa.edu.au/~pbourke/geometry/lineline2d/
			// Pts 1&2 are myCurPt and myNextPt; Pts 3&4 are otherCurPt and otherNextPt
			float denom = (otherNextPt.y - otherCurPt.y) * (myNextPt.x - myCurPt.x) - (otherNextPt.x - otherCurPt.x) * (myNextPt.y - myCurPt.y);
			if (denom == 0) {
				// then lines are parallel and do not intersect
				continue;
			} else {
				// lines intersect, but perhaps not these line segments.
				float ua = ((otherNextPt.x - otherCurPt.x) * (myCurPt.y - otherCurPt.y) - (otherNextPt.y - otherCurPt.y) * (myCurPt.x - otherCurPt.x)) / denom;
				float ub = ((myNextPt.x - myCurPt.x) * (myCurPt.y - otherCurPt.y) - (myNextPt.y - myCurPt.y) * (myCurPt.x - otherCurPt.x)) / denom;
				if (ua > 0 && ua < 1 && ub > 0 && ub < 1) {
					// then the line segments intersect!
					return YES;
				}
			}
		}
	}

	return NO;	// no overlap
}

- (void) adaptToSizeWithAspectRatio: (float) inAspectRatio
				  aspectRatioStdDev: (float) inAspectRatioStdDev
						 complexity: (short) inComplexity
					   complexitySD: (float) inComplexitySD
					allowReentrants: (BOOL) inAllowReentrants {
	float myAR = [self normalValueWithMean: inAspectRatio standardDev: inAspectRatioStdDev];
	myAR = (myAR < kSmallestAspectRatio) ? kSmallestAspectRatio : myAR;
	short myNumPoints = round( [self normalValueWithMean: inComplexity standardDev: inComplexitySD]);
 	myNumPoints = (myNumPoints < 3) ? 3 : myNumPoints;	// must have at least 3 points in polygon
	myNumPoints = (myNumPoints > kMaxNumPolygonPoints) ? kMaxNumPolygonPoints : myNumPoints;

	// Note that the NumberFormatter restricts ARs to the range [1,100]
	// need to make the rough polygon by dividing space into myNumPoints points around the center, then randomly 
	// creating vertices radially along complexity evenly-spaced lines (or perhaps not-so-evenly: use mean /SD to  get some variation)
	// then check for reentrants and move points outwards as needed
	// then resize to achieve aspect ratio
	// then resize to achieve correct area
	
	float idealAngularDivision = 2 * pi / (float)myNumPoints;
	float initialOffset = (pi * (float) rand() / (float) RAND_MAX);	// offset so that we don't have a point at zero degrees in all polygons
	float angleSD = idealAngularDivision * 0.1;
	float defaultRadius = 10;	// this is arbitrary, but the value doesn't really matter since we'll be shrinking/growing the shape to make its
								// area be correct, anyway.
	float radiusSD = 2;
	
	PolarPoint polarPoints[kMaxNumPolygonPoints];	
	for (short thisPointNum = 0; thisPointNum < myNumPoints; thisPointNum++) { // for each point
		// figure out the angle
		polarPoints[thisPointNum].angle = fmod(initialOffset + (thisPointNum * idealAngularDivision) + [self normalValueWithMean: (idealAngularDivision)
																	standardDev: angleSD], 2.0*pi);
		// figure out the radius
		polarPoints[thisPointNum].radius = [self normalValueWithMean: defaultRadius 
													standardDev: radiusSD];
		polarPoints[thisPointNum].radius = (polarPoints[thisPointNum].radius < 1) ? 1 : polarPoints[thisPointNum].radius;	// radius mst be at least 1
	}
	
	PolarPoint thisPoint, prevPoint, nextPoint;
	// Now we have a shape.  We need to fix reentrants, if they are not allowed
	if (!inAllowReentrants && myNumPoints > 3) {	// can't have reentrants in a triangle
		for (short thisPointNum = 0; thisPointNum < myNumPoints; thisPointNum++) { // for each point
			thisPoint = polarPoints[thisPointNum];
			prevPoint = polarPoints[(thisPointNum+myNumPoints-1) % myNumPoints];
			nextPoint = polarPoints[(thisPointNum+1) % myNumPoints];

			if (!(thisPoint.radius > prevPoint.radius && thisPoint.radius > nextPoint.radius)) { //  do a quick check to see if we are clearly not reentrant
				// we are not obviously safe, so calculate the minimum radius that is not reentrant
				
				// this is inscrutable trig stuff, but I think it's correct:
				float angleBefore = thisPoint.angle - prevPoint.angle;
				float angleAfter = nextPoint.angle - thisPoint.angle;
				float totalAngle = angleBefore + angleAfter;	// this is the angle made by (the line from the center to the previous point)
																// and (the line from the center to the next point)
				
				if (totalAngle < pi) {
					// can't have reentrants if the total angle is greater than 180°

/*  this doesn't seem to work; I think I derived it wrong
				// angleB is the angle made by (the line from the center to the previous point) and (the line from the previous
				// point to the next point)
				float angleB = asin(nextPoint.radius * sin(totalAngle) / prevPoint.radius);
				
				float rMin = (prevPoint.radius * cos(angleB)) / (1.0 - (0.5 * sin(2 * totalAngle) / sin(angleB)));
				
				if (thisPoint.radius < (rMin)) {
					// we have a reentrant.  If we just made r=rMin, then it would be as if this point did not exist.  
					// So, we'll select randomly within a safe interval (up to lesser of the two adjacent radii)
					// Any greater, and we might have a chance of causing an adjacent point to BECOME reentrant
					float maxSafeRadius = (prevPoint.radius < nextPoint.radius) ? prevPoint.radius : nextPoint.radius; 
					thisPoint.radius = ((maxSafeRadius - rMin) * (float) rand() / (float) RAND_MAX) + rMin;
				}
 */
					// new method:
					
					// h is the cartesian distance from prevPoint to nextPoint.  Uses Law of Cosines.  Could translate into Cartesian and get vector distance, but this is probably faster 
					float h = sqrt(nextPoint.radius * nextPoint.radius + prevPoint.radius * prevPoint.radius - 2.0 * nextPoint.radius * prevPoint.radius * cos(totalAngle));
					// delta is the angle made by (the line from the center to the previous point) and (the line from the previous
					// point to the next point)
					float delta = asin(nextPoint.radius * sin(totalAngle) / h);
					// epsilon is the angle made by (the line from the center to the next point) and (the line from the previous
					// point to the next point)
					float epsilon = pi - angleBefore - delta;
					float rMin = prevPoint.radius * sin(delta) / sin(epsilon);
					if (thisPoint.radius < (rMin)) {
						// we have a reentrant.  If we just made r=rMin, then it would be as if this point did not exist.  
						// So, we'll select randomly within a safe interval (up to lesser of the two adjacent radii)
						// Any greater, and we might have a chance of causing an adjacent point to BECOME reentrant
						float maxSafeRadius = (prevPoint.radius < nextPoint.radius) ? prevPoint.radius : nextPoint.radius; 
						thisPoint.radius = ((maxSafeRadius - rMin) * (float) rand() / (float) RAND_MAX) + rMin;
						polarPoints[thisPointNum] = thisPoint;
					}
				}
			}
		}
	}
	
	// We now have a good shape that, if desired, is not reentrant

	// make the cartesian path from the polar points
	[myPath removeAllPoints];
	NSPoint curPoint;
	NSPoint firstPoint;
	for (short thisPoint = 0; thisPoint < myNumPoints; thisPoint++) { // for each point
		curPoint.x = polarPoints[thisPoint].radius * cos(polarPoints[thisPoint].angle);
		curPoint.y = polarPoints[thisPoint].radius * sin(polarPoints[thisPoint].angle);
		
		if (thisPoint==0) {
			[myPath moveToPoint: curPoint];
			firstPoint = curPoint;
		} else {
			[myPath lineToPoint: curPoint];
		}
	}
	[myPath lineToPoint:firstPoint];
	[myPath closePath];
	
	NSAffineTransform *transform = [NSAffineTransform transform];
	// The current aspect ratio should be close to 1; stretch the shape
	[transform scaleXBy:myAR yBy:1];
	[myPath transformUsingAffineTransform: transform];
	
	transform = [NSAffineTransform transform];	// get a new empty transform; avoids worrying about combinatory surprises
	float currentArea = [self pathArea];
	float scaleFactor = sqrt(area / currentArea);	// need the square root since we are scaling in two directions
	[transform scaleXBy:scaleFactor yBy:scaleFactor];
	[myPath transformUsingAffineTransform: transform];	
	
	transform = [NSAffineTransform transform];	// get a new empty transform; avoids worrying about combinatory surprises
	[transform translateXBy: center.x yBy:center.y];
	[transform rotateByRadians:rotation]; // counterclockwise rotation
	[myPath transformUsingAffineTransform: transform];
	pathIsAtCenter = YES;
}

- (BOOL) containsPoint: (NSPoint) inPoint {
	return [myPath containsPoint:inPoint];
}

- (float) pathArea {	// this assumes that the path has not 
	NSPoint pathCenter = {0,0};
	if (pathIsAtCenter) {
		pathCenter = center;
	}
	// calculate the total area
	float totalArea = 0;
	PolarPoint polarPts[kMaxNumPolygonPoints];
	short myNumPoints = 0;
	NSPoint points[3];
	for (short i = 0; i < [myPath elementCount] - 1; i++) {	// last element is same as first, for closed path, which this is
		NSBezierPathElement element = [myPath elementAtIndex: i associatedPoints: points];
		if (element == NSMoveToBezierPathElement || element == NSLineToBezierPathElement) {
			NSPoint offset = {points[0].x - pathCenter.x, points[0].y - pathCenter.y};
			polarPts[myNumPoints].radius = sqrt(offset.x * offset.x + offset.y * offset.y);
			polarPts[myNumPoints].angle = atan(offset.y / offset.x);
			if (offset.x < 0) 
				polarPts[myNumPoints].angle += pi;	// the atan(y/x) gives identical answers for (2/3) and (-2/-3), 
														// but the latter is 180° away from the former.  This fixes that.
			myNumPoints++;
		}
	}
	
	PolarPoint thisPoint, nextPoint;
	for (short thisPointNum = 0; thisPointNum < myNumPoints; thisPointNum++) { // for each point
		thisPoint = polarPts[thisPointNum];
		if (thisPointNum == myNumPoints-1) {
			nextPoint = polarPts[0];
		} else {
			nextPoint = polarPts[thisPointNum+1];
		}
		float angleAfter = nextPoint.angle - thisPoint.angle;
		totalArea += thisPoint.radius * nextPoint.radius * sin(angleAfter) * 0.5;
	}
	
	return totalArea;
}

#define rotation_key @"rotation"
- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeFloat:rotation forKey:rotation_key];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	rotation = [decoder decodeFloatForKey:rotation_key];
	pathIsAtCenter = YES;
	return self;
}
@end
