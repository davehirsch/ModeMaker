//
//  StepValueTranformer.h
//  ModeMaker
//
//  Created by David Hirsch on 9/21/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//
// This is used to enable controls based upon binding to values other than zero/one
//	Any value greater than or equal to the step value is transformed to 0 and any value less than the step value is transformed to 1

#import <Cocoa/Cocoa.h>

@interface StepValueTranformer : NSValueTransformer {
	float	stepPoint;
	BOOL	inverted;	// if inverted, returns YES if value is greater than the step
}

- (id)initWithValue:(float) inValue
		   inverted: (BOOL) inInverted;

@end
