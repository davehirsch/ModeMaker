//
//  ModeImageView.m
//  ModeMaker
//
//  Created by David Hirsch on 9/20/09.
//  Copyright 2009 Western Washington University. All rights reserved.
//

#import "ModeImageView.h"
#import "ModeMakerDoc.h"


@implementation ModeImageView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	ModeMakerDoc *doc = [[[self window] windowController] document];

	if (doc) {
		NSRect myBounds = [self bounds];
		[[doc backgroundColor] set];
		[NSBezierPath fillRect:myBounds];
		
	/* For Debugging
		NSBezierPath *gridPath = [NSBezierPath bezierPath];
		short i;
		for (i=100; i <= myBounds.size.height; i+=100) {
			[gridPath moveToPoint:NSMakePoint(myBounds.origin.x, myBounds.origin.y + i)];
			[gridPath lineToPoint:NSMakePoint(myBounds.origin.x + myBounds.size.width, myBounds.origin.y + i)];
		}
		for (i=100; i <= myBounds.size.width; i+=100) {
			[gridPath moveToPoint:NSMakePoint(myBounds.origin.x + i, myBounds.origin.y)];
			[gridPath lineToPoint:NSMakePoint(myBounds.origin.x + i, myBounds.size.height + myBounds.origin.y)];
		}
		[[NSColor grayColor] setStroke];
		[gridPath stroke];
	*/
		
		[doc drawPhases];
	}
}

- (BOOL) isOpaque {return YES;}

@end
