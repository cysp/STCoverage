//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import <STGcov/STGcov.h>


@class STGCDA;

@class STGCNOFunction;
@class STGCNOBlock;
@class STGCNOFilenameAndLineNumberCoverage;
@class STGCNOArc;

@interface STGCNO : NSObject
- (id)init __attribute__((unavailable));
- (id)initWithContentsOfFile:(NSString *)file;
- (id)initWithContentsOfURL:(NSURL *)url;
- (id)initWithData:(NSData *)data __attribute__((objc_designated_initializer));
@property (nonatomic,copy,readonly) NSArray *functions;
@end

@interface STGCNOFunction : NSObject
@property (nonatomic,assign,readonly) NSUInteger identifier;
@property (nonatomic,assign,readonly) uint32_t checksum;
@property (nonatomic,copy,readonly) NSString *name;
@property (nonatomic,copy,readonly) NSString *filename;
@property (nonatomic,assign,readonly) NSUInteger lineNumber;
@property (nonatomic,strong,readonly) NSArray *blocks;
- (NSUInteger)numberOfArcs;
@end

@interface STGCNOBlock : NSObject
@property (nonatomic,assign,readonly) STGcovBlockFlags flags;
@property (nonatomic,copy,readonly) NSArray *arcs;
@property (nonatomic,strong,readonly) STGCNOFilenameAndLineNumberCoverage *fileCoverage;
@end

@interface STGCNOArc : NSObject
@property (nonatomic,assign,readonly) NSUInteger destination;
@property (nonatomic,assign,readonly) STGcovArcFlags flags;
@end

@interface STGCNOFilenameAndLineNumberCoverage : NSObject
@property (nonatomic,copy,readonly) NSArray *filenames;
- (NSIndexSet *)coveredLinesForFilename:(NSString *)filename;
- (NSUInteger)coverageForFilename:(NSString *)filename lineNumber:(NSUInteger)lineNumber;
@end
