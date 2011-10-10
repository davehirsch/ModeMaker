#define kNumPointsForModeMeasurement 10000
#define kNumParticlePlacingAttempts 5000
#define kPhaseNotYetFound -1
#define kMaxNumPhases 5	// in addition to the background
#define kNumRetries 10	// number of times to back up, delete some particles, and re-place 
						// them in order to fit in all the desired non-overlapping ones
#define kMaxParticlesToAddAtOnce 750
#define kMaxNumAdjustmentIterations 50

#define kSmallestParticleArea 3
#define kSmallestAspectRatio 0.1
#define kMaxNumPolygonPoints 12	// this is also limited by the NumberFormatter set up in Interface Builder
#define kNumPointsForBlobAreaMeasurement 50

#define kStartingCanvasSizeH 561
#define kStartingCanvasSizeV 333
#define kStartingWindowSizeH 600
#define kStartingWindowSizeV 537

typedef struct PolarPoint {
    float angle;
    float radius;
} PolarPoint;