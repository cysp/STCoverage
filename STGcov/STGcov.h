//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>


typedef NS_OPTIONS(NSUInteger, STGcovBlockFlags) {
	STGcovBlockFlagsNone = 0,
	STGcovBlockFlagUnexpected = 0x2,
};

typedef NS_OPTIONS(NSUInteger, STGcovArcFlags) {
	STGcovArcFlagsNone = 0,
	STGcovArcFlagComputedCount = 0x1,
	STGcovArcFlagFake = 0x2,
};


@class STGCNO;
@class STGCDA;


@interface STGcov : NSObject
- (id)init __attribute__((unavailable));
- (id)initWithGCNO:(STGCNO *)gcno __attribute__((objc_designated_initializer));
- (BOOL)addGCDA:(STGCDA *)gcda;
- (NSDictionary *)coverage;
@end


//@class STGcovCoverage;
//
//@interface STGcov : NSObject
//- (id)init __attribute__((unavailable));
//- (id)initWithGCNO:(STGCNO *)gcno __attribute__((objc_designated_initializer));
//- (BOOL)addGCDA:(STGCDA *)gcda;
//@property (nonatomic,copy,readonly) STGcovCoverage *coverage;
//@end
//
//
//@class STGcovFileCoverage;
//
//@interface STGcovCoverage : NSObject
//@property (nonatomic,copy,readonly) NSArray *filenames;
//- (STGcovFileCoverage *)coverageForFile:(NSString *)filename;
//@end
//
//
//@interface STGcovFileCoverage : NSObject
//@property (nonatomic,copy,readonly) NSString *filename;
//@property (nonatomic,copy,readonly) NSIndexSet *coveredLines;
//- (NSUInteger)coverageForLine:(NSUInteger)line;
//@end
//
//
//@interface STGcovCoverageAccumulator : NSObject
//- (void)addCoverage:(STGcovCoverage *)coverage;
//@property (nonatomic,copy,readonly) NSArray *filenames;
//- (STGcovFileCoverage *)coverageForFile:(NSString *)filename;
//@end


#import <STGcov/STGCNO.h>
#import <STGcov/STGCDA.h>
