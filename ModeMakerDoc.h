//
//  MyDocument.h
//  ModeMaker
//
//  Created by David Hirsch on 9/21/09.
//  Copyright Western Washington University 2009 . All rights reserved.
//

// NSDocument is a Model and a Controller!


#import <Cocoa/Cocoa.h>
#import "Phase.h"

#define kModeMakerDocumentType @"ModeMaker Document"
#define kModeMakerDocumentUTI @"com.davehirsch.modemaker.document"
#define kModeMakerExtension @"modemaker"

@class ModeImageView;

@interface ModeMakerDoc : NSDocument
{
	NSMutableArray			*phases;	// NSArray, although we know we'll only have a small number of phases; probably only 1 or 2 in general.
	IBOutlet
		NSArrayController	*phaseController;
	IBOutlet 
		NSProgressIndicator *progressIndicator;
	IBOutlet 
		NSDrawer			*settingsDrawer;
	IBOutlet
		NSButton			*drawerToggleButton;
	NSRect					storedWindowFrame;
	float					canvasSizeH, canvasSizeV;	// size of final canvas (in aribtrary float units).  Note that particles must be 
														// placed on an enlarged canvas, to avoid edge effects, and that there will need to
														// be tranformations applied to get this canvas drawn correctly into the view or
														// other graphics context
	NSColor					*backgroundColor;
	NSArray					*shapes;
	IBOutlet
		ModeImageView		*imageView;
	BOOL					imageCreated;
	BOOL					haveDisplayedOverlapWarning;
	BOOL					haveDisplayed90PercentWarning;
	IBOutlet
		NSTextField			*modeTargetField;
	IBOutlet
		NSTextField			*modeTargetErrorField;
	IBOutlet
		NSTextField			*sizeField;
	IBOutlet
		NSTextField			*sizeSDField;
	IBOutlet
		NSTextField			*aspectRatioField;
	IBOutlet
		NSTextField			*aspectRatioSDField;
	IBOutlet
		NSTextField			*complexityField;
	IBOutlet
		NSTextField			*complexitySDField;
	IBOutlet
		NSTextField			*fabricStrengthField;
	NSSize					lastCanvasSize;	// last-used canvas size (or the canvas size appropriate to the loaded document)
	BOOL					needToResizeForLoad;	// whether we have loaded in a document that requires the window to be in a new size
}

- (NSSize) getCanvasSize;
- (NSColor*) backgroundColor;
- (void) setBackgroundColor: (NSColor*)input;

- (IBAction) toggleDrawer: (id) sender;
- (IBAction) exportToPDF: (id) sender;
- (void) didEndSavePDFSheet: (NSSavePanel *) savePanel
				 returnCode: (int) returnCode 
				contextInfo: (void *) contextInfo;

- (IBAction) exportToPNG: (id) sender;
- (void) didEndSavePNGSheet: (NSSavePanel *) savePanel
				 returnCode: (int) returnCode 
				contextInfo: (void *) contextInfo;

- (IBAction)addPhase:(id)sender;
- (void) addThisPhase: (Phase *) inPhase  
		   atPosition: (short) inPos;
- (IBAction)removePhase:(id)sender;
- (void) removeThisPhase: (Phase *) inPhase;
- (IBAction)promotePhase:(id)sender;
- (IBAction)demotePhase:(id)sender;

- (BOOL) settingsAreValid;
- (IBAction)makePhases:(id)sender;
- (void)measureModesWithPoints: (long) inNumMonteCarloPoints upToPhase:(Phase *) inLimitPhase;
- (float) getRoughModeUpTo: (Phase *) inLimitPhase;
- (BOOL)areModesCorrect;
- (BOOL)adjustModesAtIteration: (int) iterationNum;
- (void)drawPhases;
- (void) closeIfEmptyAndClean;
// Accessors
- (NSArray *)phases;
- (void)setPhases:(NSMutableArray *)inPhases;
@end
