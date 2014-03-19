//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import "STGcov.h"


@implementation STGcov {
@private
    STGCNO *_gcno;
    NSMutableArray *_gcdas;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (id)init { return [self doesNotRecognizeSelector:_cmd], nil; }
#pragma clang diagnostic pop

- (id)initWithGCNO:(STGCNO *)gcno {
    if ((self = [super init])) {
        _gcno = gcno;
        _gcdas = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)addGCDA:(STGCDA *)gcda {
    if (![self.class isGCNO:_gcno compatibleWithGCDA:gcda]) {
        return NO;
    }
    [_gcdas addObject:gcda];
    return YES;
}

+ (BOOL)isGCNO:(STGCNO *)gcno compatibleWithGCDA:(STGCDA *)gcda {
    NSArray * const gcnoFunctions = gcno.functions;
    NSArray * const gcdaFunctions = gcda.functions;

    if (gcnoFunctions.count != gcdaFunctions.count) {
        return NO;
    }

    for (NSUInteger i = 0; i < gcnoFunctions.count; ++i) {
        STGCNOFunction * const gcnoFunction = gcnoFunctions[i];
        STGCDAFunction * const gcdaFunction = gcdaFunctions[i];

        if (gcnoFunction.identifier != gcdaFunction.identifier) {
            return NO;
        }

        if (gcnoFunction.numberOfArcs != gcdaFunction.numberOfCounts) {
            return NO;
        }

        if (gcnoFunction.checksum != gcdaFunction.checksum) {
            return NO;
        }
    }
    
    return YES;
}


- (NSDictionary *)coverage {
    NSMutableDictionary *coverageCountsByFilename = [[NSMutableDictionary alloc] init];

    STGCNO * const gcno = _gcno;
    NSArray * const gcdas = _gcdas;

    for (STGCDA *gcda in gcdas) {
        [gcda.functions enumerateObjectsUsingBlock:^(STGCDAFunction * const gcdaFunction, NSUInteger const idx, BOOL *stop) {
            STGCNOFunction * const gcnoFunction = gcno.functions[idx];
            NSUInteger countsI = 0;
            for (STGCNOBlock *block in gcnoFunction.blocks) {
                STGCNOFilenameAndLineNumberCoverage * const blockCoverage = block.fileCoverage;

                uint64_t blockCount = 0;
                for (NSUInteger blockArcNumber = 0; blockArcNumber < block.arcs.count; ++blockArcNumber) {
                    blockCount += gcdaFunction.counts[blockArcNumber];
                    ++countsI;
                }

                for (NSString *filename in blockCoverage.filenames) {
                    NSMutableDictionary *coverageCounts = coverageCountsByFilename[filename];
                    if (!coverageCounts) {
                        coverageCounts = [[NSMutableDictionary alloc] init];
                        coverageCountsByFilename[filename] = coverageCounts;
                    }

                    [[blockCoverage coveredLinesForFilename:filename] enumerateIndexesUsingBlock:^(NSUInteger lineNumber, BOOL *stop) {
                        NSUInteger const lineCoverageCount = [blockCoverage coverageForFilename:filename lineNumber:lineNumber];
                        NSNumber *coverageCount = coverageCounts[@(lineNumber)];
                        coverageCounts[@(lineNumber)] = @([coverageCount unsignedIntegerValue] + lineCoverageCount);
                    }];
                }
            }
        }];
    }

    return coverageCountsByFilename;
}

//- (void)enumerateCoveredLinesWithBlock:(STGcovBlockCoverageEnumerator)block {
//	if (!block) {
//		return;
//	}
//	uint64_t count = 0;
//	for (STGcovArc *arc in _arcs) {
//		if (arc.flags & STGcovArcFlagComputedCount) {
//			NSAssert(0, @"computed counts not implemented");
//			continue;
//		}
//		count += arc.count;
//	}
//	[_coveredLinesByFile enumerateKeysAndObjectsUsingBlock:^(NSString *filename, NSCountedSet *lineNumbers, BOOL *stop) {
//		[lineNumbers enumerateObjectsUsingBlock:^(NSNumber *lineNumber, BOOL *stop) {
//			NSUInteger multiplier = [lineNumbers countForObject:lineNumber];
//			block(filename, [lineNumber unsignedIntegerValue], count * multiplier);
//		}];
//	}];
//}

@end

//static NSNumber *STEnsureNSNumber(id obj) {
//	if ([obj isKindOfClass:[NSNumber class]]) {
//		return obj;
//	}
//	return nil;
//}


//@interface STGcovFunction : NSObject
//@property (nonatomic,assign,readonly) NSUInteger identifier;
//@property (nonatomic,copy,readonly) NSString *name;
//@property (nonatomic,copy,readonly) NSString *filename;
//@property (nonatomic,assign,readonly) NSUInteger lineNumber;
//@property (nonatomic,strong,readonly) NSArray *blocks;
//- (id)initWithData:(NSData *)data version:(STGcovVersion)version;
//- (BOOL)addBlocksFromData:(NSData *)data version:(STGcovVersion)version;
//- (BOOL)addArcsFromData:(NSData *)data version:(STGcovVersion)version;
//- (BOOL)addLinesFromData:(NSData *)data version:(STGcovVersion)version;
//- (BOOL)addCountsFromData:(NSData *)data version:(STGcovVersion)version;
//@end
//
//
//typedef void(^STGcovBlockCoverageEnumerator)(NSString *filename, NSUInteger lineNumber, uint64_t count);
//@interface STGcovBlock : NSObject
//@property (nonatomic,assign,readonly) STGcovBlockFlags flags;
//@property (nonatomic,strong,readonly) NSArray *arcs;
//- (id)initWithFlags:(STGcovBlockFlags)flags;
//- (BOOL)addArcWithDestination:(NSUInteger)arcIdentifier flags:(STGcovArcFlags)arcFlags;
//- (BOOL)addFilename:(NSString *)filename lineNumber:(NSUInteger)lineNumber;
//- (void)enumerateCoveredLinesWithBlock:(STGcovBlockCoverageEnumerator)block;
//@end
//
//
//@interface STGcovArc : NSObject
//@property (nonatomic,assign,readonly) NSUInteger destination;
//@property (nonatomic,assign,readonly) STGcovArcFlags flags;
//@property (nonatomic,assign,readonly) uint64_t count;
//- (id)initWithDestination:(NSUInteger)destination flags:(STGcovArcFlags)flags;
//- (void)addCount:(uint64_t)count;
//@end



//@interface STGcovFunction ()
//@end
//@implementation STGcovFunction {
//@private
//	NSMutableArray *_blocks;
//}
//- (id)init {
//	return [self initWithIdentifier:0 name:nil filename:nil lineNumber:0];
//}
//- (id)initWithIdentifier:(NSUInteger)identifier name:(NSString *)name filename:(NSString *)filename lineNumber:(NSUInteger)lineNumber {
//	if ((self = [super init])) {
//		_identifier = identifier;
//		_name = [name copy];
//		_filename = [filename copy];
//		_lineNumber = lineNumber;
//		_blocks = [[NSMutableArray alloc] initWithCapacity:16];
//	}
//	return self;
//}
//- (id)initWithData:(NSData *)data version:(STGcovVersion)version {
//	STGcovStream * const stream = [[STGcovStream alloc] initWithData:data];
//
//	NSUInteger identifier = 0;
//	if (![stream readUInt32:&identifier]) {
//		return nil;
//	}
//
//	if (![stream readUInt32:NULL]) { // checksum #1
//		return nil;
//	}
//
//	NSString *name = nil;
//	if (![stream readString:&name]) {
//		return nil;
//	}
//	NSString *filename = nil;
//	if (![stream readString:&filename]) {
//		return nil;
//	}
//
//	NSUInteger lineNumber = 0;
//	if (![stream readUInt32:&lineNumber]) {
//		return nil;
//	}
//
//	if (![stream isSpent]) {
//		return nil;
//	}
//
//	if ((self = [self initWithIdentifier:identifier name:name filename:filename lineNumber:lineNumber])) {
//	}
//	return self;
//}
//
//- (BOOL)addBlocksFromData:(NSData *)data version:(STGcovVersion)version {
//	STGcovStream *stream = [[STGcovStream alloc] initWithData:data];
//
//	NSUInteger blockFlags = 0;
//	while ([stream readUInt32:&blockFlags]) {
//		STGcovBlock *block = [[STGcovBlock alloc] initWithFlags:blockFlags];
//		[_blocks addObject:block];
//	}
//
//	return [stream isSpent];
//}
//
//- (BOOL)addArcsFromData:(NSData *)data version:(STGcovVersion)version {
//	STGcovStream *stream = [[STGcovStream alloc] initWithData:data];
//
//	NSUInteger blockNumber = 0;
//	if (![stream readUInt32:&blockNumber]) {
//		return NO;
//	}
//	if (blockNumber >= [_blocks count]) {
//		return NO;
//	}
//	STGcovBlock *block = _blocks[blockNumber];
//
//	NSUInteger arcIdentifier = 0;
//	while ([stream readUInt32:&arcIdentifier]) {
//		NSUInteger arcFlags = 0;
//		if (![stream readUInt32:&arcFlags]) {
//			return NO;
//		}
//		[block addArcWithDestination:arcIdentifier flags:arcFlags];
//	}
//
//	return [stream isSpent];
//}
//
//- (BOOL)addLinesFromData:(NSData *)data version:(STGcovVersion)version {
//	STGcovStream *stream = [[STGcovStream alloc] initWithData:data];
//
//	NSUInteger blockNumber = 0;
//	if (![stream readUInt32:&blockNumber]) {
//		return NO;
//	}
//
//	if (blockNumber >= [_blocks count]) {
//		return NO;
//	}
//	STGcovBlock *block = _blocks[blockNumber];
//
////	if (![stream readUInt32:NULL]) { // flag
////		return NO;
////	}
//
//	NSString *filename = nil;
//	NSUInteger lineNumber = 0;
//	while ([stream readUInt32:&lineNumber]) {
//		if (lineNumber == 0) {
//			if (![stream readString:&filename]) {
//				break;
//			}
//		} else {
//			[block addFilename:filename lineNumber:lineNumber];
//		}
//	}
//	return [stream isSpent];
//}
//
//- (BOOL)addCountsFromData:(NSData *)data version:(STGcovVersion)version {
//	STGcovStream *stream = [[STGcovStream alloc] initWithData:data];
//
//	for (STGcovBlock *block in _blocks) {
//		for (STGcovArc *arc in block.arcs) {
//			if (arc.flags & STGcovArcFlagComputedCount) {
//				continue;
//			}
//			uint64_t count = 0;
//			if (![stream readUInt64:&count]) {
//				break;
//			}
//			[arc addCount:count];
//		}
//	}
//
//	return [stream isSpent];
//}
//
//@end


//@interface STGcovBlock ()
//@property (nonatomic,strong,readonly) NSMutableDictionary *coveredLinesByFile; // string -> countedset
//@end
//@implementation STGcovBlock {
//@private
//	NSMutableArray *_arcs;
//}
//- (id)initWithFlags:(STGcovBlockFlags)flags {
//	if ((self = [super init])) {
//		_flags = flags;
//		_arcs = [[NSMutableArray alloc] init];
//		_coveredLinesByFile = [[NSMutableDictionary alloc] init];
//	}
//	return self;
//}
//- (BOOL)addArcWithDestination:(NSUInteger)arcDestination flags:(STGcovArcFlags)arcFlags {
//	STGcovArc *arc = [[STGcovArc alloc] initWithDestination:arcDestination flags:arcFlags];
//	[_arcs addObject:arc];
//	return YES;
//}
//- (BOOL)addFilename:(NSString *)filename lineNumber:(NSUInteger)lineNumber {
//	NSCountedSet *lineNumbers = _coveredLinesByFile[filename];
//	if (!lineNumbers) {
//		lineNumbers = [[NSCountedSet alloc] init];
//		_coveredLinesByFile[filename] = lineNumbers;
//	}
//	[lineNumbers addObject:@(lineNumber)];
//	return YES;
//}
//- (void)enumerateCoveredLinesWithBlock:(STGcovBlockCoverageEnumerator)block {
//	if (!block) {
//		return;
//	}
//	uint64_t count = 0;
//	for (STGcovArc *arc in _arcs) {
//		if (arc.flags & STGcovArcFlagComputedCount) {
//			NSAssert(0, @"computed counts not implemented");
//			continue;
//		}
//		count += arc.count;
//	}
//	[_coveredLinesByFile enumerateKeysAndObjectsUsingBlock:^(NSString *filename, NSCountedSet *lineNumbers, BOOL *stop) {
//		[lineNumbers enumerateObjectsUsingBlock:^(NSNumber *lineNumber, BOOL *stop) {
//			NSUInteger multiplier = [lineNumbers countForObject:lineNumber];
//			block(filename, [lineNumber unsignedIntegerValue], count * multiplier);
//		}];
//	}];
//}
//@end


//@interface STGcovArc ()
//@end
//@implementation STGcovArc
//- (id)init {
//	return [self initWithDestination:0 flags:0];
//}
//- (id)initWithDestination:(NSUInteger)destination flags:(STGcovArcFlags)flags {
//	if ((self = [super init])) {
//		_destination = destination;
//		_flags = flags;
//	}
//	return self;
//}
//- (void)addCount:(uint64_t)count {
//	_count += count;
//}
//@end
