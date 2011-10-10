//
//  BlobParticle.m
//  ModeMaker
//
//  Created by David Hirsch on 9/24/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import "BlobParticle.h"
#import "constants.h"

@implementation BlobParticle

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
		if (element == NSCurveToBezierPathElement) {
			myPts[myNumPts++] = points[2];
		}
	}
	
	for (short i = 0; i < [otherPath elementCount]; i++) {
		NSBezierPathElement element = [otherPath elementAtIndex: i associatedPoints: points];
		if (element == NSCurveToBezierPathElement) {
			otherPts[otherNumPts++] = points[2];
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
	for (short thisPointNum = 0; thisPointNum < myNumPoints; thisPointNum++) { // for each point
		curPoint.x = polarPoints[thisPointNum].radius * cos(polarPoints[thisPointNum].angle);
		curPoint.y = polarPoints[thisPointNum].radius * sin(polarPoints[thisPointNum].angle);
		
		if (thisPointNum==0) {
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
	
	[self blobFromPolygon];

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

- (void) blobFromPolygon {
	// takes the path and pakes a curved surface that uses all the same vertices
	short myNumPoints = 0;
	NSPoint polygonPoints[kMaxNumPolygonPoints+3];
	NSPoint points[3];
	for (short i = 0; i < [myPath elementCount] - 1; i++) {	// last element is same as first, for closed path, which this is
		NSBezierPathElement element = [myPath elementAtIndex: i associatedPoints: points];
		if (element == NSMoveToBezierPathElement || element == NSLineToBezierPathElement) {
			polygonPoints[myNumPoints++] = points[0];
		}
	}
	
	// Using the algorithm above, it's possible to get the same point duplicated at the beginning and the end
	if (polygonPoints[myNumPoints-1].x == polygonPoints[0].x && polygonPoints[myNumPoints-1].y == polygonPoints[0].y) {
		myNumPoints--;
	}
	
	// Now loop through the points and make a new path with curves instead of lines
	NSBezierPath *newPath = [NSBezierPath bezierPath];
	NSPointArray controlPoints;
	NSPoint prevVertex, thisVertex, nextVertex, nextAfterNextVertex;
	short prevNum, nextNum, nextAfterNextNum;
	
	[newPath moveToPoint: polygonPoints[0]];

	for (short pointNum = 0; pointNum < myNumPoints; pointNum++) {
		prevNum = (pointNum - 1 + myNumPoints) % myNumPoints;
		nextNum = (pointNum + 1 + myNumPoints) % myNumPoints;
		nextAfterNextNum = (pointNum + 2 + myNumPoints) % myNumPoints;
		
		prevVertex = polygonPoints[prevNum];
		thisVertex = polygonPoints[pointNum];
		nextVertex = polygonPoints[nextNum];
		nextAfterNextVertex = polygonPoints[nextAfterNextNum];
		controlPoints = [self getControlPointsForCurrentVertex: thisVertex
													nextVertex: nextVertex
												pointAfterNext: nextAfterNextVertex
													prevVertex:prevVertex];
		[newPath curveToPoint:nextVertex
				controlPoint1:controlPoints[0]
				controlPoint2:controlPoints[1]];
	}
	
	[newPath retain];
	[myPath release];	// release the old path
	myPath = newPath;	// adopt the new path
}

- (NSPointArray) getControlPointsForCurrentVertex: (NSPoint) pt1
									   nextVertex: (NSPoint) pt2
								   pointAfterNext: (NSPoint) pt3
									   prevVertex: (NSPoint) pt0 {
// From http://www.antigrain.com/research/bezier_interpolation/
// Assume we need to calculate the control
// points between (x1,y1) and (x2,y2).
// Then x0,y0 - the previous vertex,
//      x3,y3 - the next one.
	NSPoint c1 = {(pt0.x + pt1.x) / 2.0, (pt0.y + pt1.y) / 2.0};
	NSPoint c2 = {(pt2.x + pt1.x) / 2.0, (pt2.y + pt1.y) / 2.0};
	NSPoint c3 = {(pt2.x + pt3.x) / 2.0, (pt2.y + pt3.y) / 2.0};

	double len1 = sqrt((pt1.x-pt0.x) * (pt1.x-pt0.x) + (pt1.y-pt0.y) * (pt1.y-pt0.y));
	double len2 = sqrt((pt2.x-pt1.x) * (pt2.x-pt1.x) + (pt2.y-pt1.y) * (pt2.y-pt1.y));
	double len3 = sqrt((pt3.x-pt2.x) * (pt3.x-pt2.x) + (pt3.y-pt2.y) * (pt3.y-pt2.y));

	double k1 = len1 / (len1 + len2);
	double k2 = len2 / (len2 + len3);

	NSPoint m1 = {c1.x + (c2.x - c1.x) * k1 , c1.y + (c2.y - c1.y) * k1};
	NSPoint m2 = {c2.x + (c3.x - c2.x) * k2 , c2.y + (c3.y - c2.y) * k2};
	 
	 // Resulting control points. Here smooth_value is mentioned
	 // above coefficient K whose value should be in range [0...1].
	static NSPoint controlPoints[2];
	float smooth_value = 1;
	NSPoint controlPoint1 = {m1.x + (c2.x - m1.x) * smooth_value + pt1.x - m1.x, 
						m1.y + (c2.y - m1.y) * smooth_value + pt1.y - m1.y};
	NSPoint controlPoint2 = {m2.x + (c2.x - m2.x) * smooth_value + pt2.x - m2.x, 
						m2.y + (c2.y - m2.y) * smooth_value + pt2.y - m2.y};
	controlPoints[0] = controlPoint1;
	controlPoints[1] = controlPoint2;
	return controlPoints;
}

- (BOOL) containsPoint: (NSPoint) inPoint {
	return [myPath containsPoint:inPoint];
}

- (float) pathArea {	// this assumes that the path has not 
	// this way is slow, but I don't know any better way:
	// make a bounds rect, shoot a bunch of points and see what fraction make it in the path.
	NSRect myBoundsRect = [myPath bounds];
	NSPoint randPt;
	int pointsInPath = 0;
	for (int i=0; i < kNumPointsForBlobAreaMeasurement; i++) {
		randPt = NSMakePoint((myBoundsRect.size.width * (float) rand() / (float) RAND_MAX) + myBoundsRect.origin.x,
							 (myBoundsRect.size.height * (float) rand() / (float) RAND_MAX) + myBoundsRect.origin.y);
		if ([myPath containsPoint:randPt])
			pointsInPath++;
	}
	return (myBoundsRect.size.width * myBoundsRect.size.height * pointsInPath / kNumPointsForBlobAreaMeasurement);
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
