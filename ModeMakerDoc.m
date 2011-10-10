//
//  MyDocument.m
//  ModeMaker
//
//  Created by David Hirsch on 9/21/09.
//  Copyright Western Washington University 2009 . All rights reserved.
//

#import "ModeMakerDoc.h"
#import "StepValueTranformer.h"
#import "constants.h"

@implementation ModeMakerDoc

- (id)init
{
    self = [super init];
    if (self) {
		phases = [NSMutableArray array];	// create empty array
		[phases retain];
		if (!phases)	{ // if array was not created
			[self release];
			return nil;
		}
		
		shapes = [NSArray arrayWithObjects: @"Oval", @"Rectangle", @"Blob", @"Polygon", nil];
		[shapes retain];
		backgroundColor = [NSColor whiteColor];
		canvasSizeH = 561;
		canvasSizeV = 333;
		lastCanvasSize = NSMakeSize(-1, -1);	// invalidate last-used size
		needToResizeForLoad = NO;

		imageCreated = NO;
		haveDisplayed90PercentWarning = NO;
		haveDisplayedOverlapWarning = NO;

		// register Value Transformer to ease enabling/disabling the plus button in the UI
		StepValueTranformer *stepAt5;
		
		// create an autoreleased instance of our value transformer
		stepAt5 = [[[StepValueTranformer alloc] initWithValue:5.0 inverted:NO] autorelease];
		
		// register it with the name that we refer to it with
		[NSValueTransformer setValueTransformer:stepAt5 forName:@"stepAt5Transformer"];
	}

    return self;
}

- (void) dealloc
{
	[phases release];
	[shapes release];
	[super dealloc];
}

- (void)drawerDidClose:(NSNotification *)notification {
	[drawerToggleButton setState:NSOnState];
}

- (NSSize) getCanvasSize {
	return NSMakeSize(canvasSizeH, canvasSizeV);
}

- (NSColor*) backgroundColor {return backgroundColor;}
- (void) setBackgroundColor: (NSColor*)input {
    if (input != backgroundColor) {
		NSUndoManager *undoer = [self undoManager];
        [undoer registerUndoWithTarget:self
							  selector:@selector(setBackgroundColor:)
								object:backgroundColor];
		[undoer setActionName: @"Background Color Change"];
	}
	[backgroundColor autorelease];
	backgroundColor = [input retain];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"ModeMakerDoc";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	if (needToResizeForLoad) {
		// resize window to make canvas size correct, if necessary
		NSWindow *myWindow = [ [ [ self windowControllers ] objectAtIndex:0 ] window ];
//		NSRect currentWindowFrame = [myWindow frame];
//		NSSize desiredWindowSize = NSMakeSize(canvasSizeH + kStartingWindowSizeH - kStartingCanvasSizeH, 
//											  canvasSizeV + kStartingWindowSizeV - kStartingCanvasSizeV);
//
//		NSRect newWindowFrame = NSMakeRect(currentWindowFrame.origin.x, currentWindowFrame.origin.y, desiredWindowSize.width, desiredWindowSize.height);
		[myWindow setFrame:storedWindowFrame display:YES animate:YES];
	}
	[imageView setNeedsDisplay:YES];
}

- (void) awakeFromNib {
	unsigned theTime = [[NSDate date] timeIntervalSince1970];
#ifdef DH_DEBUG
	theTime = 22;	// for debugging to reproduce some conditions
#else
	NSLog(@"ModeMaker: current random seed: @%", theTime);
#endif
	srand(theTime);	// put seed into random number generator	
}


#define phases_key @"phases"
#define phaseController_key @"phaseController"
#define progressIndicator_key @"progressIndicator";
#define settingsDrawer_key @"settingsDrawer"
#define drawerToggleButton_key @"drawerToggleButton"
#define backgroundColor_key @"backgroundColor"
#define shapes_key @"shapes"
#define imageView_key @"imageView"
#define imageCreated_key @"imageCreated"
#define haveDisplayedOverlapWarning_key @"haveDisplayedOverlapWarning"
#define haveDisplayed90PercentWarning_key @"haveDisplayed90PercentWarning"
#define windowFrameX_key @"windowFrameX"
#define windowFrameY_key @"windowFrameY"
#define windowFrameW_key @"windowFrameW"
#define windowFrameH_key @"windowFrameH"


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if ([typeName isEqualToString:kModeMakerDocumentType]) {
        NSData *data;
        NSMutableDictionary *doc = [NSMutableDictionary dictionary];
        NSString *errorString;
		NSWindow *myWindow = [ [ [ self windowControllers ] objectAtIndex:0 ] window ];
		NSRect frame = [myWindow frame];
        [doc setObject:[NSKeyedArchiver archivedDataWithRootObject:phases] forKey:phases_key];
		[doc setObject:[NSNumber numberWithFloat:frame.origin.x] forKey:windowFrameX_key];
		[doc setObject:[NSNumber numberWithFloat:frame.origin.y] forKey:windowFrameY_key];
		[doc setObject:[NSNumber numberWithFloat:frame.size.width] forKey:windowFrameW_key];
		[doc setObject:[NSNumber numberWithFloat:frame.size.height] forKey:windowFrameH_key];
		//[doc setObject:[NSNumber numberWithFloat:canvasSizeH] forKey:canvasSizeH_key];
		//[doc setObject:[NSNumber numberWithFloat:canvasSizeV] forKey:canvasSizeV_key];
		[doc setObject:[NSKeyedArchiver archivedDataWithRootObject:backgroundColor] forKey:backgroundColor_key];
		[doc setObject:[NSNumber numberWithBool:haveDisplayedOverlapWarning] forKey:haveDisplayedOverlapWarning_key];
		[doc setObject:[NSNumber numberWithBool:haveDisplayed90PercentWarning] forKey:haveDisplayed90PercentWarning_key];
       data = [NSPropertyListSerialization dataFromPropertyList:doc format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
        if (!data) {
            if (outError != NULL) {
                NSLog(@"dataFromPropertyList failed with %@", errorString);
            } else {
                NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"ModeMaker document couldn't be written", NSLocalizedDescriptionKey, (errorString ? errorString : @"An unknown error occured."), NSLocalizedFailureReasonErrorKey, nil];
				
                // In this simple example we know that no one's going to be paying attention to the domain and code that we use here.
                *outError = [NSError errorWithDomain:@"NSOSStatusErrorDomain" code:-1 userInfo:errorUserInfo];
            }
            [errorString release];
        }
        return data;
    } else {
        *outError = [NSError errorWithDomain:@"NSOSStatusErrorDomain" code:-1 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unsupported data type: %@", typeName] forKey:NSLocalizedFailureReasonErrorKey]];
    }
    return nil;
}

- (NSData *)dataRepresentationOfType:(NSString *)aType {
	// including this to allow running on pre 10.5 systems
	NSError *theError;
	return [self dataOfType:aType error:&theError];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	BOOL result = NO;
    // we only recognize one data type.  It is a programming error to call this method with any other typeName
    assert([typeName isEqualToString:kModeMakerDocumentType]); 
    
    NSString *errorString;
    NSDictionary *documentDictionary = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];
	
    if (documentDictionary) {                                           
        [self setPhases:[NSKeyedUnarchiver unarchiveObjectWithData:[documentDictionary objectForKey:phases_key]]];
		storedWindowFrame = NSMakeRect([[documentDictionary objectForKey:windowFrameX_key] floatValue],
										[[documentDictionary objectForKey:windowFrameY_key] floatValue],
										[[documentDictionary objectForKey:windowFrameW_key] floatValue],
									   [[documentDictionary objectForKey:windowFrameH_key] floatValue]);
        //canvasSizeH = [[documentDictionary objectForKey:canvasSizeH_key] floatValue];
        //canvasSizeV = [[documentDictionary objectForKey:canvasSizeV_key] floatValue];
		lastCanvasSize = [self getCanvasSize];
		needToResizeForLoad = YES;
		
		[self setBackgroundColor:[NSKeyedUnarchiver unarchiveObjectWithData:[documentDictionary objectForKey:backgroundColor_key]]];
		haveDisplayedOverlapWarning = [[documentDictionary objectForKey:haveDisplayedOverlapWarning_key] boolValue];
		haveDisplayed90PercentWarning = [[documentDictionary objectForKey:haveDisplayed90PercentWarning_key] boolValue];
		imageCreated = YES;
        [imageView setNeedsDisplay:YES];
        result = YES;
    } else {
        if (!outError) {
            NSLog(@"propertyListFromData failed with %@", errorString);
        } else {
            NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys: @"ModeMaker document couldn't be read", NSLocalizedDescriptionKey, (errorString ? errorString : @"An unknown error occured."), NSLocalizedFailureReasonErrorKey, nil];
			
            *outError = [NSError errorWithDomain:@"NSOSStatusErrorDomain" code:-1 userInfo:errorUserInfo];
        }
        [errorString release];
        result = NO;
    }
    // we don't want any of the operations involved in loading the new document to mark it as dirty, nor should they be undo-able, so clear the undo stack
    [[self undoManager] removeAllActions];

    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	
	// if there are existing empty non-dirty documents, they should be closed - we've probably runthe program then clicked open
	NSDocumentController *docCont = [NSDocumentController sharedDocumentController];
	NSArray *documents = [docCont documents];
	for (short i=0; i < [documents count]; i++) {
		ModeMakerDoc *thisDoc = (ModeMakerDoc *)[documents objectAtIndex:i];
		if (thisDoc != self) {
			[thisDoc closeIfEmptyAndClean];
		}
	}

    return result;
}

- (void) closeIfEmptyAndClean {
	if ([phases count] == 0 && [self isDocumentEdited] == NO) {
		[self close];
	}
}

- (IBAction) toggleDrawer: (id) sender {
	[settingsDrawer toggle: self];
}

- (IBAction) exportToPDF: (id) sender {
	NSSavePanel *spanel = [NSSavePanel savePanel];
	NSString *path = @"~/Documents";
	[spanel setDirectory:[path stringByExpandingTildeInPath]];
	[spanel setPrompt:NSLocalizedString(@"Export", nil)];
	[spanel setRequiredFileType:@"pdf"];
	NSWindow *myWindow = [ [ [ self windowControllers ] objectAtIndex:0 ] window ];
	[spanel beginSheetForDirectory:[path stringByExpandingTildeInPath]
                              file:nil
					modalForWindow:myWindow
					 modalDelegate:self
					didEndSelector:@selector(didEndSavePDFSheet:returnCode:contextInfo:)
					   contextInfo:NULL];
}

- (IBAction) exportToPNG: (id) sender {
	NSSavePanel *spanel = [NSSavePanel savePanel];
	NSString *path = @"~/Documents";
	[spanel setDirectory:[path stringByExpandingTildeInPath]];
	[spanel setPrompt:NSLocalizedString(@"Export", nil)];
	[spanel setRequiredFileType:@"png"];
	NSWindow *myWindow = [ [ [ self windowControllers ] objectAtIndex:0 ] window ];
	[spanel beginSheetForDirectory:[path stringByExpandingTildeInPath]
                              file:nil
					modalForWindow:myWindow
					 modalDelegate:self
					didEndSelector:@selector(didEndSavePNGSheet:returnCode:contextInfo:)
					   contextInfo:NULL];
}


-(void)didEndSavePDFSheet:(NSSavePanel *)savePanel
			   returnCode:(int)returnCode 
			  contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		NSRect r = [imageView bounds];
		NSData *data = [imageView dataWithPDFInsideRect:r];
		
		[data writeToFile:[savePanel filename] atomically:YES];
	} else {
        NSLog(@"Modemaker: Canceled Export to PDF.");
	}
}

-(void)didEndSavePNGSheet:(NSSavePanel *)savePanel
			   returnCode:(int)returnCode 
			  contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
			// Make the PNG Here
		[imageView lockFocus];
		NSBitmapImageRep *imageRep = [imageView bitmapImageRepForCachingDisplayInRect:[imageView visibleRect]];
		[imageView cacheDisplayInRect:[imageView visibleRect] toBitmapImageRep:imageRep];
		[imageView unlockFocus];
		NSData *data = [imageRep representationUsingType: NSPNGFileType
											  properties: nil];
		[data writeToFile:[savePanel filename] atomically:YES];
	} else {
        NSLog(@"Modemaker: Canceled Export to PDF.");
	}
}

- (NSSize) windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize
{
	// adjust canvas size fields, manually issuing notifications
    [self willChangeValueForKey:@"canvasSizeH"];
	canvasSizeH = ([imageView bounds]).size.width;
    [self didChangeValueForKey:@"canvasSizeH"];
	
    [self willChangeValueForKey:@"canvasSizeV"];
	canvasSizeV = ([imageView bounds]).size.height;
    [self didChangeValueForKey:@"canvasSizeV"];
	return proposedFrameSize;	// do not constrain resizing
}

- (IBAction)addPhase:(id)sender {
    [phaseController willChangeValueForKey:@"arrangedObjects"];
	Phase *newPhase = [[Phase alloc] initByNumber:[phases count]];
	[newPhase setDoc:self];
	[phases addObject: newPhase];
    [phaseController didChangeValueForKey:@"arrangedObjects"];

    [phaseController willChangeValueForKey:@"selectionIndex"];
	[phaseController setSelectionIndex:[phases count]-1];
    [phaseController didChangeValueForKey:@"selectionIndex"];
	[[self undoManager] registerUndoWithTarget:self
						  selector:@selector(removeThisPhase:)
							object:newPhase];
	[[self undoManager] setActionName: @"Add Phase"];
	
}

- (void) addThisPhase: (Phase *) inPhase  
		   atPosition: (short) inPos { // get here from redo
	[phaseController willChangeValueForKey:@"arrangedObjects"];
	[phases insertObject: inPhase atIndex:inPos];
    [phaseController didChangeValueForKey:@"arrangedObjects"];
	
	[phaseController willChangeValueForKey:@"selectionIndex"];
	[phaseController setSelectionIndex:inPos];	// we must have had the phase selected before we removed it, so reselect it now that weve inserted it
	[phaseController didChangeValueForKey:@"selectionIndex"];
	[[self undoManager] registerUndoWithTarget:self
							   selector:@selector(removeThisPhase:)
								 object:inPhase];
	if ([[self undoManager] isUndoing]) {
		// we are in the process of undoing a remove (by adding), so this is the text that will show on the Redo Menu Item
		[[self undoManager] setActionName: @"Remove Phase"];
	} else {
		[[self undoManager] setActionName: @"Add Phase"];
	}
}

- (void) removeThisPhase: (Phase *) inPhase {	// get here from undo stack
	int oldSelection = [phaseController selectionIndex];
	short phaseNumToKill = [phases indexOfObject:inPhase];
	[[[self undoManager] prepareWithInvocationTarget:self] addThisPhase:inPhase atPosition:phaseNumToKill];
	if ([[self undoManager] isUndoing]) {
		// we are in the process of undoing an add (by removign), so this is the text that will show on the Redo Menu Item
		[[self undoManager] setActionName: @"Add Phase"];
	} else {
		[[self undoManager] setActionName: @"Remove Phase"];
	}
    [phaseController willChangeValueForKey:@"arrangedObjects"];
	[phases removeObject: inPhase];
    [phaseController didChangeValueForKey:@"arrangedObjects"];
	
	if ([phases count] > 0) {
		if (phaseNumToKill <= oldSelection) {	// if we killed a later one, then the selection doesn't change
			int newSelection = (oldSelection - 1);
			if (newSelection < 0)
				newSelection = 0;
			
			[phaseController willChangeValueForKey:@"selectionIndex"];
			[phaseController setSelectionIndex: newSelection];
			[phaseController didChangeValueForKey:@"selectionIndex"];
		}
	}
}

- (IBAction)removePhase:(id)sender {
	int oldSelection = [phaseController selectionIndex];
	Phase *phaseToRemove = [phases objectAtIndex:oldSelection];
	[[[self undoManager] prepareWithInvocationTarget:self] addThisPhase:phaseToRemove atPosition:oldSelection];
	[[self undoManager] setActionName: @"Remove Phase"];

	[phaseController removeObject:phaseToRemove];

/*    [phaseController willChangeValueForKey:@"arrangedObjects"];
	[phases removeObjectAtIndex: oldSelection];
    [phaseController didChangeValueForKey:@"arrangedObjects"];

	if ([phases count] > 0) {
		int newSelection = (oldSelection - 1);
		if (newSelection < 0)
			newSelection = 0;

		[phaseController willChangeValueForKey:@"selectionIndex"];
		[phaseController setSelectionIndex: newSelection];
		[phaseController didChangeValueForKey:@"selectionIndex"];
 }
*/	
}

- (IBAction)promotePhase:(id)sender
{
    [phaseController willChangeValueForKey:@"selectionIndex"];
	int selected = [phaseController selectionIndex];
	[phases exchangeObjectAtIndex:selected
				withObjectAtIndex:(selected-1)];
	[phaseController setSelectionIndex: selected-1];
    [phaseController didChangeValueForKey:@"selectionIndex"];
	[[self undoManager] registerUndoWithTarget:self
									  selector:@selector(demotePhase:)
										object:self];
	if ([[self undoManager] isUndoing]) {
		[[self undoManager] setActionName: @"Demote Phase"];
	} else {
		[[self undoManager] setActionName: @"Promote Phase"];
	}
}

- (IBAction)demotePhase:(id)sender
{
    [phaseController willChangeValueForKey:@"selectionIndex"];
	int selected = [phaseController selectionIndex];
	[phases exchangeObjectAtIndex:selected
				withObjectAtIndex:(selected+1)];
	[phaseController setSelectionIndex: selected+1];
    [phaseController didChangeValueForKey:@"selectionIndex"];
	[[self undoManager] registerUndoWithTarget:self
									  selector:@selector(promotePhase:)
										object:self];
	if ([[self undoManager] isUndoing]) {
		[[self undoManager] setActionName: @"Promote Phase"];
	} else {
		[[self undoManager] setActionName: @"Demote Phase"];
	}
}

- (BOOL)validateUserInterfaceItem:(NSMenuItem *)item {
	int selected = [phaseController selectionIndex];
	if ([item action] == @selector(addPhase:) &&
		([phases count] >= 5)) {
        return NO;
    }

	if ([item action] == @selector(removePhase:) &&
		([phases count] == 0)) {
        return NO;
    }
	
    if ([item action] == @selector(promotePhase:) &&
		(selected == NSNotFound || selected == 0 || [phases count] == 1)) {
        return NO;
    }
	
    if ([item action] == @selector(demotePhase:) &&
		(selected == NSNotFound || selected == [phases count]-1 || [phases count] == 1)) {
        return NO;
    }

	if ([item action] == @selector(makePhases:) &&
		([phases count] == 0)) {
        return NO;
    }

	if ([item action] == @selector(exportToPDF:) &&
		(!imageCreated)) {
        return NO;
    }

	if ([item action] == @selector(exportToPNG:) &&
		(!imageCreated)) {
        return NO;
    }
						
    return YES;
}

- (BOOL) settingsAreValid {
	// check to see if target modes exceed 99%
	float modeTotal = 0;
	for (short i=0; i < [phases count]; i++) {
		Phase *thisPhase = [phases objectAtIndex:i];
		modeTotal += [thisPhase modeTarget];
		if (![thisPhase overlapping] && [thisPhase modeTarget]>60) {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setInformativeText:@"You have specified non-overlapping for a phase with a mode target exceeding 60%.  Such specifications typically fail; please reduce the mode in order to proceed."];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert beginSheetModalForWindow:[ [ [ self windowControllers ] objectAtIndex:0 ] window ]
							  modalDelegate:self 
							 didEndSelector:nil
								contextInfo:nil];
			return NO;
		}
		if (modeTotal > 90 && !haveDisplayed90PercentWarning) {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setInformativeText:@"You have specified mode targets that collectively exceed 90%. Note that calculation may be slow in such cases; slower closer to 100%. (1-time warning per document)"];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert beginSheetModalForWindow:[ [ [ self windowControllers ] objectAtIndex:0 ] window ]
							  modalDelegate:self 
							 didEndSelector:nil
								contextInfo:nil];
			haveDisplayed90PercentWarning = YES;
			return YES;	// not invalid, just slow
		}
		if ([thisPhase modeTargetError] < 0.01) {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setInformativeText:@"You have specified a mode target error less than 0.01.  That will take too long to calculate."];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert beginSheetModalForWindow:[ [ [ self windowControllers ] objectAtIndex:0 ] window ]
							  modalDelegate:self 
							 didEndSelector:nil
								contextInfo:nil];
			return NO;
		}
		if ([thisPhase modeTargetError] < 0.1) {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setInformativeText:@"You have specified a mode target error less than 0.1.  That may take a long time to calculate; do you really need such precision?"];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert beginSheetModalForWindow:[ [ [ self windowControllers ] objectAtIndex:0 ] window ]
							  modalDelegate:self 
							 didEndSelector:nil
								contextInfo:nil];
			return YES;
		}
	}
	if (modeTotal > 99) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert setInformativeText:@"You have specified mode targets that collectively exceed 99%. Please reduce the cumulative mode in order to proceed."];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:[ [ [ self windowControllers ] objectAtIndex:0 ] window ]
						  modalDelegate:self 
						 didEndSelector:nil
							contextInfo:nil];
		return NO;
	}
	if (modeTotal > 90 && !haveDisplayed90PercentWarning) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert setInformativeText:@"You have specified mode targets that collectively exceed 90%. Note that calculation may be slow in such cases; slower closer to 100%. (1-time warning per document)"];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:[ [ [ self windowControllers ] objectAtIndex:0 ] window ]
						  modalDelegate:self 
						 didEndSelector:nil
							contextInfo:nil];
		haveDisplayed90PercentWarning = YES;
		return YES;	// not invalid, just slow
	}
	
	// check to see if any non-overlapping phase exceeds 50% (need to create a better rule of thumb - this will vary with size and SD of sizes)
	return YES;
}

- (IBAction)makePhases:(id)sender
{
	int selection = [phaseController selectionIndex];
	[(Phase *)[phases objectAtIndex: selection] setModeTarget: [modeTargetField floatValue]];
	[(Phase *)[phases objectAtIndex: selection] setModeTargetError: [modeTargetErrorField floatValue]];
	[(Phase *)[phases objectAtIndex: selection] setPhaseSize: [sizeField floatValue]];
	[(Phase *)[phases objectAtIndex: selection] setSizeSD: [sizeSDField floatValue]];
	[(Phase *)[phases objectAtIndex: selection] setPhaseAR: [aspectRatioField floatValue]];
	[(Phase *)[phases objectAtIndex: selection] setAspectRatioSD: [aspectRatioSDField floatValue]];
	[(Phase *)[phases objectAtIndex: selection] setComplexity: [complexityField intValue]];
	[(Phase *)[phases objectAtIndex: selection] setComplexitySD: [complexitySDField floatValue]];
	[(Phase *)[phases objectAtIndex: selection] setFabricStrength: [fabricStrengthField floatValue]];

//	unsigned theTime = [[NSDate date] timeIntervalSince1970];
//	theTime = 16;	// for debugging to reproduce some conditions
//	srand(theTime);	// put seed into random number generator

	if ([self settingsAreValid]) {
		
		[progressIndicator startAnimation:self];
		
		BOOL couldAdjustModes = YES;
		BOOL settingsHaveChanged = NO;
		// looks through the list and starts redoing phases once the settings for any phase above that phase have changed
		for (short i=0; i < [phases count] && couldAdjustModes; i++) {
			Phase *thisPhase = [phases objectAtIndex:i];
			[thisPhase setDoc: self];
			if ([thisPhase lastPosition] != i) {
				settingsHaveChanged = YES;
			}
			BOOL sizeChanged = !(canvasSizeH == lastCanvasSize.width && canvasSizeV == lastCanvasSize.height);
			settingsHaveChanged = (settingsHaveChanged || [thisPhase settingsHaveChanged]);
			if (sizeChanged || settingsHaveChanged) {
				// only make new particles if the settings have changed
				BOOL result = [thisPhase makeParticles];
				if (!result) {
					NSLog(@"ModeQuiz: Problem with making particles; will try to adjust.");
					// bugged out of makeParticles: will try to fix in Adjustment, below.  If that fails
					// we'll use it's failure mechanism to fail gracefully
				}
				BOOL goodMode = NO;
				BOOL couldAdjustMode = YES;
				[self measureModesWithPoints: kNumPointsForModeMeasurement
								   upToPhase: nil];
				goodMode = [thisPhase isModeCorrect];
				BOOL doneAdjusting = NO;
				int iterationNum = 1;
				while (!doneAdjusting) {
					long numPointsToUse = floorf(kNumPointsForModeMeasurement * (0.5 * erff((iterationNum - 5)/5.0) + 0.5));	// this function starts out small and get to close to kNumPointsForModeMeasurement within about 8 iterations.  The goal is to have very rapid checks early on.
					couldAdjustMode = [thisPhase adjustModeAtIteration: iterationNum];
					[self measureModesWithPoints: numPointsToUse
									   upToPhase: nil ];	// this measures all the phases, but we don't examine the results for those phases below us.  Could optimize performance here by making another meaure version
					goodMode = [thisPhase isModeCorrect];
					if (goodMode && iterationNum < 10) {
						iterationNum += 3;	// if the modes are correct with a rough measurement, let's refine the measurement quickly
						goodMode = NO;
					}
					[progressIndicator displayIfNeeded];
					doneAdjusting = goodMode && (numPointsToUse > 0.9 * kNumPointsForModeMeasurement);	// we want to ensure that we don't get lucky with a bad mode measurement
					if (!couldAdjustMode) {
						couldAdjustModes = NO;
						doneAdjusting = YES;
					}
					if (iterationNum > kMaxNumAdjustmentIterations) {
						couldAdjustMode = NO;
						doneAdjusting = YES;
					}
					iterationNum++;
				}
			}
		}
		
#ifdef DH_DEBUG		
// Set of measurements to determine precision of measurement at this value of kNumPointsForModeMeasurement
		NSLog(@"Beginning precision test");
		for (short n = 0; n < 100; n++) {
			[self measureModesWithPoints: kNumPointsForModeMeasurement
							   upToPhase: nil ];	// this measures all the phases, but we don't examine the results for those phases below us.  Could optimize performance here by making another meaure version
		}
#endif
		[progressIndicator stopAnimation:self];
		
		if (couldAdjustModes) {
			imageCreated = YES;
			
			[imageView setNeedsDisplayInRect: [imageView bounds]];
			lastCanvasSize = [self getCanvasSize];
		} else {
			// failed to adjust modes - try re-randomizing phase settings
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setInformativeText:@"Despite substantial effort, placing of the desired particles failed.  This typically occurs with non-overlapping particles at a high mode (near 50%)."];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert beginSheetModalForWindow:[ [ [ self windowControllers ] objectAtIndex:0 ] window ]
							  modalDelegate:self 
							 didEndSelector:nil
								contextInfo:nil];
 
		}
	}
	for (short i=0; i < [phases count]; i++) {
		Phase *thisPhase = [phases objectAtIndex:i];
		[thisPhase setLastPosition:i];
	}


	/* Old Method: tackle all phases at once.  This worked well when we were measuring modes the old way, but now it's less optimal

	 if ([self settingsAreValid]) {
		
		[progressIndicator startAnimation:self];
		[redrawButton setHidden:YES];
		
		for (short i=0; i < [phases count]; i++) {
			Phase *thisPhase = [phases objectAtIndex:i];
			[thisPhase setDoc: self];
			BOOL sizeChanged = !(canvasSizeH == lastCanvasSize.width && canvasSizeV == lastCanvasSize.height);
			if (sizeChanged || [thisPhase settingsHaveChanged]) {
				// only make new particles if the settings have changed
				BOOL result = [thisPhase makeParticles];
				if (!result)
					NSLog(@"Problem with making particles!");
			}
		}
		// Now need to check the resulting modes to see how well they match the target modes
		BOOL goodModes = NO;
		BOOL couldAdjustModes = YES;
		[self measureModesWithPoints: kNumPointsForModeMeasurement
						   upToPhase: nil];
		goodModes = [self areModesCorrect];
		BOOL doneAdjusting = NO;
		int iterationNum = 1;
		while (!doneAdjusting) {
			//			long numPointsToUse = kNumPointsForModeMeasurement * 2 * atan(iterationNum / 2.0) / pi;	// uses fewer points in earlier iterations, converging towards kNumPointsForModeMeasurement
			long numPointsToUse = floorf(kNumPointsForModeMeasurement * (0.5 * erff((iterationNum - 5)/5.0) + 0.5));	// this function starts out small and get to close to kNumPointsForModeMeasurement within about 8 iterations.  The goal is to have very rapid checks early on.
			couldAdjustModes = [self adjustModesAtIteration: iterationNum];
			[self measureModesWithPoints: numPointsToUse
							   upToPhase: nil ];
			goodModes = [self areModesCorrect];
			if (goodModes && iterationNum < 10) {
				iterationNum += 3;	// if the modes are correct with a rough measurement, let's refine the measurement quickly
			[progressIndicator displayIfNeeded];
			doneAdjusting = couldAdjustModes && goodModes && (numPointsToUse > 0.9 * kNumPointsForModeMeasurement);	// we want to ensure that we don't get lucky with a bad mode measurement
			iterationNum++;
		}
		[progressIndicator stopAnimation:self];
	
		if (couldAdjustModes) {
			imageCreated = YES;
			
			[imageView setNeedsDisplayInRect: [imageView bounds]];
			lastCanvasSize = [self getCanvasSize];
		} else {
			// failed to adjust modes - post an alert
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setInformativeText:@"Despite substantial effort, placing of the desired particles failed.  This typically occurs with non-overlapping particles at a high mode (near 50%)."];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert beginSheetModalForWindow:[ [ [ self windowControllers ] objectAtIndex:0 ] window ]
							  modalDelegate:self 
							 didEndSelector:nil
								contextInfo:nil];
		}
	}
	*/
	[phaseController didChangeValueForKey:@"arrangedObjects"];
}

- (void)measureModesWithPoints: (long) inNumMonteCarloPoints 
					 upToPhase:(Phase *) inLimitPhase
{
	// New method: Create a bitmap graphics context, draw all the phases into it, then poll a bunch of points in the bitmap to see what color they are.
	// This requires each phase to have a different color.  We will save the existing phase colors, assign our own, known colors to each in order,
	//	then restore the original colors at the end.
	
	NSBitmapImageRep* offscreenRep = nil;
	offscreenRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
														   pixelsWide:canvasSizeH
														   pixelsHigh:canvasSizeV
														bitsPerSample:8
													  samplesPerPixel:4
															 hasAlpha:YES
															 isPlanar:NO
													   colorSpaceName:NSCalibratedRGBColorSpace
														 bitmapFormat:0
														  bytesPerRow:0
														 bitsPerPixel:0];
//	[offscreenRep retain];
	
	/*
	 offscreenRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
	 pixelsWide:canvasSizeH
	 pixelsHigh:canvasSizeV
	 bitsPerSample:8
	 samplesPerPixel:2
	 hasAlpha:YES
	 isPlanar:NO
	 colorSpaceName:NSCalibratedWhiteColorSpace
	 bitmapFormat:0
	 bytesPerRow:0
	 bitsPerPixel:0];
	 */	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:offscreenRep]];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	
	//Debugging:
	/*	
	 offscreenRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
	 pixelsWide:500
	 pixelsHigh:300
	 bitsPerSample:8
	 samplesPerPixel:4
	 hasAlpha:YES
	 isPlanar:NO
	 colorSpaceName:NSCalibratedRGBColorSpace
	 bitmapFormat:0
	 bytesPerRow:0
	 bitsPerPixel:0];
	 [offscreenRep retain];
	 [NSGraphicsContext saveGraphicsState];
	 [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:offscreenRep]];
	 [[NSGraphicsContext currentContext] setShouldAntialias:NO];
	 [[NSColor colorWithCalibratedRed:0.5 green:0 blue:0 alpha:1.0] set];
	 [NSBezierPath fillRect:NSMakeRect(0, 0, 41, 259)];
	 NSLog(@"%@", [offscreenRep colorAtX:40  y:40]);
	 [NSBezierPath fillRect:NSMakeRect(0, 0, 41, 261)];
	 NSLog(@"%@", [offscreenRep colorAtX:40  y:40]);
	 BOOL flipped = 	[[NSGraphicsContext currentContext] isFlipped];
	 [[NSGraphicsContext currentContext] flushGraphics];
	 //	[NSBezierPath fillRect:NSMakeRect(0, 0, canvasSizeH, canvasSizeV)];
	 [NSGraphicsContext restoreGraphicsState];
	 NSData* TiffData = [offscreenRep TIFFRepresentation];
	 [TiffData writeToFile:@"/Users/dave/Desktop/temp.tiff" atomically:YES];
	 NSColor *pixelColor = [offscreenRep colorAtX:40  y:40];
	 float r,g,b,a;
	 NSLog(@"%@", pixelColor);
	 [pixelColor getRed:&r green:&g blue:&b alpha:&a];
	 
	 
	 
	 TiffData = [NSData dataWithContentsOfFile: @"/Users/dave/Desktop/temp.tiff"];
	 NSBitmapImageRep *newRep = [NSBitmapImageRep imageRepWithData:TiffData];
	 NSColor *newPixelColor = [newRep colorAtX:40  y:40];
	 NSLog(@"%@", newPixelColor);
	 [newPixelColor getRed:&r green:&g blue:&b alpha:&a];
	 
	 
	 
	 [[NSColor colorWithCalibratedRed:0.5 green:0 blue:0 alpha:1.0] set];
	 [NSBezierPath fillRect:NSMakeRect(10, 10, 100, 100)];
	 NSData* TiffData = [offscreenRep TIFFRepresentation];
	 [TiffData writeToFile:@"/Users/dave/Desktop/temp.tiff" atomically:YES];
	 NSColor *pixelColor = [offscreenRep colorAtX:40 
	 y:40];
	 if (pixelColor) {	// null pixelColor indicates the non-drawn background - do not record anything for those pixels
	 float r,g,b,a;
	 [pixelColor getRed:&r green:&g blue:&b alpha:&a];
	 }
	 */
	
	
	short lastPhaseToCheck;
	if (inLimitPhase != nil) {
		lastPhaseToCheck = [phases indexOfObject:inLimitPhase] - 1;
	} else {
		lastPhaseToCheck = [phases count]-1;	// check all phases
	}
	
	if (lastPhaseToCheck > -1) {	// only do this if we were instructed to actually measure any phases

		// Save phase colors & canvas background color & set the new colors
		NSMutableArray *oldColors = [NSMutableArray array];
		for (short phaseNum = 0; phaseNum <= lastPhaseToCheck; phaseNum++) {
			Phase * thisPhase = [phases objectAtIndex:phaseNum];
			[oldColors addObject: [thisPhase color]];
			NSColor *phaseColor = [[NSColor colorWithCalibratedRed:(phaseNum  / 10.0) green:0 blue: 0 alpha:1.0] retain];	// this restricts the value of kMaxNumPhases to 20, which should be way more than we'd ever want
			[thisPhase setColor: phaseColor];
		}

		// Draw the phases in reverse order so the earlier ones are on top
		for (short phaseNum = lastPhaseToCheck; phaseNum >= 0; phaseNum--) {
			Phase * thisPhase = [phases objectAtIndex:phaseNum];
			[thisPhase draw];
		}
		[[NSGraphicsContext currentContext] flushGraphics];

#ifdef DH_DEBUG		
// Debugging:		
//		NSData* TiffData = [offscreenRep TIFFRepresentation];
//		[TiffData writeToFile:@"/Users/dave/Desktop/temp.tiff" atomically:YES];
#endif
		// Examine the image to determine the modes:
		
		// make a temporary array to hold the point totals
		long pointTotals[kMaxNumPhases];
		for (short j=0; j < [phases count]; j++) {
			pointTotals[j] = 0;
		}
		
		for (long i=0; i < inNumMonteCarloPoints; i++) {
			// for each point, check the lower-index phases first, and allocate the point to the first phase that the point is inside
			int randX = floor((canvasSizeH * (float) rand() / (float) RAND_MAX));
			int randY = floor((canvasSizeV * (float) rand() / (float) RAND_MAX));
			
			NSColor *pixelColor = [offscreenRep colorAtX:randX 
													   y:randY];
			float red,green,blue,alpha;
			[pixelColor getRed:&red green:&green blue:&blue alpha:&alpha];
			if (alpha>0) {	// null alpha indicates the non-drawn background - do not record anything for those pixels
//				float redColor = [pixelColor redComponent];
				//float whiteColor = [pixelColor whiteComponent];
				//float whitepart, alphapart;
				//[pixelColor getWhite: &whitepart alpha:&alphapart];
				int phaseNum = (roundf(red * 10.0));
				// if the point landed in a phase, then increment the mode counter for that phase (these values will be normalized into percentages
				// after the loop is done.
				pointTotals[phaseNum]++;
			}
		}
		
		// record the measured modes
		for (short phaseNum = 0; phaseNum <= lastPhaseToCheck; phaseNum++) {
			Phase *thisPhase = [phases objectAtIndex:phaseNum];
			[thisPhase setMode:(100.0 * pointTotals[phaseNum] / inNumMonteCarloPoints)];
#ifdef DH_DEBUG	
			NSLog(@"Phase: %@ - Mode: %f", [thisPhase name], (100.0 * pointTotals[phaseNum] / inNumMonteCarloPoints));
#endif
		}
		
		
		// restore phase colors & canvas background color
		for (short phaseNum = 0; phaseNum <= lastPhaseToCheck; phaseNum++) {
			[(Phase *)[phases objectAtIndex:phaseNum] setColor: [oldColors objectAtIndex:phaseNum]];
		}
	}
	
	[NSGraphicsContext restoreGraphicsState];
	[offscreenRep release];
	
	/* Old Method: Make a bunch of points and ask each particle of each phase if the point is inside it.  Slow with many particles (e.g., if size is small)
	 // randomly place a lot of points in the canvas (not the expanded canvas in which the Particle centers are located, though)
	 // keep track of which phase they land in (being sure to test the phases in the order they are displayed: phase 0 is covered by phase 1, etc.
	 
	 // make a temporary array to hold the point totals
	 long pointTotals[kMaxNumPhases];
	 for (short j=0; j < [phases count]; j++) {
	 pointTotals[j] = 0;
	 }
	 
	 short lastPhaseToCheck;
	 if (inLimitPhase != nil) {
	 lastPhaseToCheck = [phases indexOfObject:inLimitPhase] - 1;
	 } else {
	 lastPhaseToCheck = [phases count]-1;
	 }
	 
	 for (long i=0; i < inNumMonteCarloPoints; i++) {
	 // for each point, check the lower-index phases first, and allocate the point to the first phase that the point is inside
	 float randX = (canvasSizeV * (float) rand() / (float) RAND_MAX);
	 float randY = (canvasSizeH * (float) rand() / (float) RAND_MAX);
	 NSPoint randPoint = NSMakePoint(randX, randY);
	 
	 short phaseFound = kPhaseNotYetFound;
	 for (short phaseNum = 0; (phaseNum <= lastPhaseToCheck) && (phaseFound == kPhaseNotYetFound); phaseNum++) {
	 Phase *thisPhase = [phases objectAtIndex:phaseNum];
	 if ([thisPhase containsPoint:randPoint])
	 phaseFound = phaseNum;
	 }
	 
	 // if the point landed in a phase, then increment the mode counter for that phase (these values will be normalized into percentages
	 // after the loop is done.
	 pointTotals[phaseFound]++;
	 }
	 
	 // record the measured modes
	 for (short phaseNum = 0; phaseNum <= lastPhaseToCheck; phaseNum++) {
	 Phase *thisPhase = [phases objectAtIndex:phaseNum];
	 [thisPhase setMode:(100.0 * pointTotals[phaseNum] / inNumMonteCarloPoints)];
	 }
	 */
}

- (float) getRoughModeUpTo: (Phase *) inLimitPhase {
	// New method: look to see if the modes are already recorded.  Use those, if so.  If not, then use the full measureModesWithPoints (now quite fast).
	short lastPhaseToCheck = [phases indexOfObject:inLimitPhase] - 1;
	if (lastPhaseToCheck == -1) {
		return 0;	// the inLimitPhase was the first phase
	}
	
	float modeTotal = 0;
	BOOL foundZeroMode = NO;
	for (short phaseNum = 0; !foundZeroMode && phaseNum <= lastPhaseToCheck; phaseNum++) {
		Phase *thisPhase = [phases objectAtIndex:phaseNum];
		if ([thisPhase mode] == 0) {
			foundZeroMode = YES;
		} else {
			modeTotal += [thisPhase mode];
		}
	}

	if (foundZeroMode) {
		// then we need to calculate the modes
		[self measureModesWithPoints: kNumPointsForModeMeasurement
						   upToPhase: inLimitPhase];
		
		// then calculate the modes
		modeTotal = 0;
		for (short phaseNum = 0; phaseNum <= lastPhaseToCheck; phaseNum++) {
			Phase *thisPhase = [phases objectAtIndex:phaseNum];
			modeTotal += [thisPhase mode];
		}
	}
	
	return modeTotal;

	/* Old method: call measureModesWithPoints with a small number of points.  Too complex, and the modes might be recorded already
	// Store the current modes - the measureModesWithPoints routine will put new values in
	float oldModes[kMaxNumPhases];
	for (short i = 0; i < [phases count]; i++) {
		oldModes[i]  = [(Phase *) [phases objectAtIndex:i] mode];
	}
	
	short lastPhaseToCheck = [phases indexOfObject:inLimitPhase] - 1;
	if (lastPhaseToCheck == -1) {
		return 0;	// the inLimitPhase was the first phase
	}
	[self measureModesWithPoints: 200
					   upToPhase: inLimitPhase];
	float modeTotal = 0;
	for (short phaseNum = 0; phaseNum <= lastPhaseToCheck; phaseNum++) {
		Phase *thisPhase = [phases objectAtIndex:phaseNum];
		modeTotal += [thisPhase mode];
	}
	// Restore the original modes - the measureModesWithPoints routine will put new values in
	for (short i = 0; i < [phases count]; i++) {
		[(Phase *)[phases objectAtIndex:i] setMode: oldModes[i]];
	}
	
	return modeTotal;
 */
}

- (BOOL)areModesCorrect
{
	for (short phaseNum = 0; phaseNum < [phases count]; phaseNum++) {
		if (![(Phase *)[phases objectAtIndex:phaseNum] isModeCorrect])
			return NO;
	}
	return YES;
}

- (BOOL)adjustModesAtIteration: (int) iterationNum
{
	for (short phaseNum = 0; phaseNum < [phases count]; phaseNum++) {
		if (![(Phase *)[phases objectAtIndex:phaseNum] isModeCorrect]) {
			if (![(Phase *)[phases objectAtIndex:phaseNum] adjustModeAtIteration: iterationNum]) {
				return NO;	// failed to be able to adjust the mode - report failure up the chain
			}
		}
	}
	return YES;
}

- (void)drawPhases
{
	NSGraphicsContext* theContext = [NSGraphicsContext currentContext];
	[theContext saveGraphicsState];
	
	if (phases) {
		short numPhases = [phases count];
		for (short i = numPhases - 1; i >= 0; i--) {	
			// we traverse the list in opposite order, so that the highest-listed phase will be drawn on top of the lower-listed 
			// phase(s).  This conforms with what a user would expewct from the UI.
			Phase *thisPhase = [phases objectAtIndex:i];
			[thisPhase draw];
		}
	}
	[theContext restoreGraphicsState];
}

// transaction accessors

- (NSArray *)phases {
    // always return an array.   Create an empty one if need be, since it is incorrect to return nil from a collection accessor.
    if (!phases) {
        phases = [[NSMutableArray alloc] init];
    }
    return [[phases retain] autorelease];
}

- (void)setPhases:(NSMutableArray *)inPhases
{
    if (phases != inPhases)
    {
        [phases release];
        phases = [inPhases mutableCopy];
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
	canvasSizeH = ([imageView bounds]).size.width;
	canvasSizeV = ([imageView bounds]).size.height;
}



@end
