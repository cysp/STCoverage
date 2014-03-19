//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import "STGCNO.h"

#import "STGcovConstants.h"
#import "STGcovStream.h"


@interface STGCNOFunction ()
- (id)initWithData:(NSData *)data version:(STGcovVersion)version;
- (BOOL)addBlocksFromData:(NSData *)data version:(STGcovVersion)version;
- (BOOL)addArcsFromData:(NSData *)data version:(STGcovVersion)version;
- (BOOL)addLinesFromData:(NSData *)data version:(STGcovVersion)version;
@end

@interface STGCNOBlock ()
- (id)initWithFlags:(STGcovBlockFlags)flags;
- (BOOL)addArcWithDestination:(NSUInteger)arcIdentifier flags:(STGcovArcFlags)arcFlags;
- (BOOL)addFilename:(NSString *)filename lineNumber:(NSUInteger)lineNumber;
@end

@interface STGCNOArc ()
- (id)initWithDestination:(NSUInteger)destination flags:(STGcovArcFlags)flags;
@end

@interface STGCNOFilenameAndLineNumberCoverage ()
- (BOOL)addFilename:(NSString *)filename lineNumber:(NSUInteger)lineNumber;
@end


@implementation STGCNOFunction {
@private
    NSMutableArray *_blocks;
}

- (id)init { return [self doesNotRecognizeSelector:_cmd], nil; }
- (id)initWithData:(NSData *)data version:(STGcovVersion)version {
    STGcovStream * const stream = [[STGcovStream alloc] initWithData:data];

    uint32_t identifier = 0;
    if (![stream readUInt32:&identifier]) {
        return nil;
    }

    uint32_t checksum = 0;
    if (![stream readUInt32:&checksum]) { // checksum #1
        return nil;
    }

    NSString *name = nil;
    if (![stream readString:&name]) {
        return nil;
    }
    NSString *filename = nil;
    if (![stream readString:&filename]) {
        return nil;
    }

    uint32_t lineNumber = 0;
    if (![stream readUInt32:&lineNumber]) {
        return nil;
    }

    if (![stream isSpent]) {
        return nil;
    }

    if ((self = [super init])) {
        _identifier = identifier;
        _checksum = checksum;
        _name = name.copy;
        _filename = filename.copy;
        _lineNumber = lineNumber;
        _blocks = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)addBlocksFromData:(NSData *)data version:(STGcovVersion)version {
    STGcovStream * const stream = [[STGcovStream alloc] initWithData:data];

    STGcovBlockFlags blockFlags = 0;
    while ([stream readUInt32:(uint32_t *)&blockFlags]) {
        STGCNOBlock *block = [[STGCNOBlock alloc] initWithFlags:blockFlags];
        [_blocks addObject:block];
    }

    return [stream isSpent];
}

- (BOOL)addArcsFromData:(NSData *)data version:(STGcovVersion)version {
    STGcovStream * const stream = [[STGcovStream alloc] initWithData:data];

    uint32_t blockNumber = 0;
    if (![stream readUInt32:&blockNumber]) {
        return NO;
    }
    if (blockNumber >= [_blocks count]) {
        return NO;
    }
    STGCNOBlock * const block = _blocks[blockNumber];

    uint32_t arcIdentifier = 0;
    while ([stream readUInt32:&arcIdentifier]) {
        STGcovArcFlags arcFlags = 0;
        if (![stream readUInt32:(uint32_t *)&arcFlags]) {
            return NO;
        }
        [block addArcWithDestination:arcIdentifier flags:arcFlags];
    }

    return [stream isSpent];
}

- (BOOL)addLinesFromData:(NSData *)data version:(STGcovVersion)version {
    STGcovStream * const stream = [[STGcovStream alloc] initWithData:data];

    uint32_t blockNumber = 0;
    if (![stream readUInt32:&blockNumber]) {
        return NO;
    }

    if (blockNumber >= [_blocks count]) {
        return NO;
    }
    STGCNOBlock * const block = _blocks[blockNumber];

//	if (![stream readUInt32:NULL]) { // flag
//		return NO;
//	}

    NSString *filename = nil;
    uint32_t lineNumber = 0;
    while ([stream readUInt32:&lineNumber]) {
        if (lineNumber == 0) {
            if (![stream readString:&filename]) {
                break;
            }
        } else {
            [block addFilename:filename lineNumber:lineNumber];
        }
    }
    return [stream isSpent];
}

- (NSUInteger)numberOfArcs {
    NSUInteger numberOfArcs = 0;
    for (STGCNOBlock *block in _blocks) {
        numberOfArcs += [block.arcs count];
    }
    return numberOfArcs;
}

@end

@implementation STGCNOBlock {
@private
    NSMutableArray *_arcs;
}

- (id)init { return [self doesNotRecognizeSelector:_cmd], nil; }
- (id)initWithFlags:(STGcovBlockFlags)flags {
    if ((self = [super init])) {
        _flags = flags;
        _arcs = [[NSMutableArray alloc] init];
        _fileCoverage = [[STGCNOFilenameAndLineNumberCoverage alloc] init];
    }
    return self;
}
- (BOOL)addArcWithDestination:(NSUInteger)arcDestination flags:(STGcovArcFlags)arcFlags {
    STGCNOArc *arc = [[STGCNOArc alloc] initWithDestination:arcDestination flags:arcFlags];
    [_arcs addObject:arc];
    return YES;
}
- (BOOL)addFilename:(NSString *)filename lineNumber:(NSUInteger)lineNumber {
    return [_fileCoverage addFilename:filename lineNumber:lineNumber];
    return YES;
}

@end

@implementation STGCNOArc

- (id)init { return [self doesNotRecognizeSelector:_cmd], nil; }
- (id)initWithDestination:(NSUInteger)destination flags:(STGcovArcFlags)flags {
    if ((self = [super init])) {
        _destination = destination;
        _flags = flags;
    }
    return self;
}

@end

@implementation STGCNOFilenameAndLineNumberCoverage {
@private
    NSMutableDictionary *_coveredLinesByFile;
}

- (id)init {
    if ((self = [super init])) {
        _coveredLinesByFile = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BOOL)addFilename:(NSString *)filename lineNumber:(NSUInteger)lineNumber {
    NSCountedSet *lineNumbers = _coveredLinesByFile[filename];
    if (!lineNumbers) {
        lineNumbers = [[NSCountedSet alloc] init];
        _coveredLinesByFile[filename] = lineNumbers;
    }
    [lineNumbers addObject:@(lineNumber)];
    return YES;
}

- (NSArray *)filenames {
    return [_coveredLinesByFile.allKeys sortedArrayUsingSelector:@selector(compare:)];
}

- (NSIndexSet *)coveredLinesForFilename:(NSString *)filename {
    NSMutableIndexSet * const coveredLines = [[NSMutableIndexSet alloc] init];
    NSCountedSet * const lineNumbers = _coveredLinesByFile[filename];
    for (NSNumber *lineNumber in lineNumbers) {
        [coveredLines addIndex:lineNumber.unsignedIntegerValue];
    }
    return coveredLines;
}

- (NSUInteger)coverageForFilename:(NSString *)filename lineNumber:(NSUInteger)lineNumber {
    NSCountedSet *lineNumbers = _coveredLinesByFile[filename];
    return [lineNumbers countForObject:@(lineNumber)];
}

@end


@implementation STGCNO {
@private
    NSArray *_functions;
}

- (id)init {
    return [self initWithData:nil];
}
- (id)initWithContentsOfFile:(NSString *)file {
    NSData * const data = [[NSData alloc] initWithContentsOfFile:file options:NSDataReadingMappedIfSafe error:NULL];
    return [self initWithData:data];
}
- (id)initWithContentsOfURL:(NSURL *)url {
    NSData * const data = [[NSData alloc] initWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:NULL];
    return [self initWithData:data];
}
- (id)initWithData:(NSData *)data {
    STGcovStream *stream = [[STGcovStream alloc] initWithData:data];

    STGcovMagic magic = 0;
    STGcovVersion version = 0;
    STGcovStamp stamp = 0;
    if (![stream readUInt32:&magic] || ![stream readUInt32:&version] || ![stream readUInt32:&stamp]) {
        return nil;
    }

    BOOL validMagic = NO;
    switch (magic) {
        case STGcovMagicGCNO:
            validMagic = YES;
            break;
        case STGcovMagicGCDA:
            break;
    }
    if (!validMagic) {
        return nil;
    }

    BOOL knownVersion = NO;
    switch (version) {
        case STGcovVersion402:
        case STGcovVersion404:
            knownVersion = YES;
            break;
    }
    if (!knownVersion) {
        return nil;
    }

    BOOL knownStamp = NO;
    switch (stamp) {
        case STGcovStampLLVM:
            knownStamp = YES;
            break;
    }
    if (!knownStamp) {
//        this is a hash now :-|
//        return nil;
    }

    NSMutableArray *functions = [[NSMutableArray alloc] init];
    STGCNOFunction *lastFunction = nil;

    STGcovTag tag = 0;
    while ([stream readUInt32:&tag]) {
        uint32_t tagLen = 0;
        if (![stream readUInt32:&tagLen]) {
            return nil;
        }
        if (tag == 0 && tagLen == 0) {
            break;
        }

        NSData *tagData = nil;
        if (![stream readDataLength:tagLen*4 data:&tagData]) {
            return nil;
        }

        switch (tag) {
            case STGcovTagFunction: {
                STGCNOFunction *function = [[STGCNOFunction alloc] initWithData:tagData version:version];
                if (!function) {
                    return nil;
                }
                [functions addObject:function];
                lastFunction = function;
            } break;
            case STGcovTagBlocks: {
                if (![lastFunction addBlocksFromData:tagData version:version]) {
                    return nil;
                }
            } break;
            case STGcovTagArcs: {
                if (![lastFunction addArcsFromData:tagData version:version]) {
                    return nil;
                }
            } break;
            case STGcovTagLines: {
                if (![lastFunction addLinesFromData:tagData version:version]) {
                    return nil;
                }
            } break;
            case STGcovTagCounter: {
                NSAssert(0, @"unexpected counter tag in GCNO file");
            } break;
            case STGcovTagObject: {
                NSAssert(0, @"unexpected object tag in GCNO file");
            } break;
            case STGcovTagProgram: {
                NSAssert(0, @"unexpected program tag in GCNO file");
            } break;
            default: {
                NSAssert(0, @"unhandled tag");
            } break;
        }
    }

    [functions sortUsingComparator:^NSComparisonResult(STGCNOFunction * const a, STGCNOFunction * const b) {
        NSUInteger const aIdentifier = a.identifier;
        NSUInteger const bIdentifier = b.identifier;
        if (aIdentifier < bIdentifier) {
            return NSOrderedAscending;
        }
        if (aIdentifier > bIdentifier) {
            return NSOrderedDescending;
        }
        return [a.name compare:b.name];
    }];

    if ((self = [super init])) {
        _functions = functions.copy;
    }
    return self;
}

@end
