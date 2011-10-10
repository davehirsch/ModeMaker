//
//  StepValueTranformer.m
//  ModeMaker
//
//  Created by David Hirsch on 9/21/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import "StepValueTranformer.h"


@implementation StepValueTranformer

+ (Class)transformedValueClass
{
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;	
}

- (id)init
{
    self = [super init];
	stepPoint = 0;
	inverted = NO;
    return self;
}

- (id)initWithValue:(float) inValue
		   inverted: (BOOL) inInverted;
{
    self = [super init];
	stepPoint = inValue;
	inverted = inInverted;
    return self;
}

- (id)transformedValue:(id)value
{
    float inputValue;
    float outputValue;
	
    if (value == nil) return nil;
	
    // Attempt to get a reasonable value from the
    // value object.
    if ([value respondsToSelector: @selector(floatValue)]) {
		// handles NSString and NSNumber
        inputValue = [value floatValue];
    } else {
		[NSException raise: NSInternalInconsistencyException 
					format: @"Value (%@) does not respond to -floatValue.",
					[value class]];
    }
	
    // calculate output value
	if (inputValue >= stepPoint)
		outputValue = 0;
	else
		outputValue = 1;
	
	if (inverted)
		outputValue = !(outputValue);

    return [NSNumber numberWithFloat: outputValue];
}

@end
