//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import "STGCDA.h"

#import "STGcovConstants.h"
#import "STGcovStream.h"



@interface STGCDA ()
@property (nonatomic,assign,readonly) NSUInteger runCount;
@end

@interface STGCDAFunction ()
- (id)init __attribute__((unavailable));
- (id)initWithIdentifier:(NSUInteger)identifier checksum:(uint32_t)checksum name:(NSString *)name /*__attribute__((objc_designated_initializer))*/;
- (BOOL)addCountsFromData:(NSData *)data version:(STGcovVersion)version;
@end


@implementation STGCDAFunction

- (id)init { return [self doesNotRecognizeSelector:_cmd], nil; }
- (id)initWithIdentifier:(NSUInteger)identifier checksum:(uint32_t)checksum name:(NSString *)name {
    if ((self = [super init])) {
        _identifier = identifier;
        _checksum = checksum;
        _name = name.copy;
    }
    return self;
}

- (BOOL)addCountsFromData:(NSData *)data version:(STGcovVersion)version {
    size_t const dataLength = data.length;
    if (dataLength % sizeof(uint64_t)) {
        return NO;
    }
    size_t const numberOfCounts = dataLength / sizeof(uint64_t);
    uint64_t const * const dataCounts = data.bytes;

    if (_numberOfCounts == 0) {
        _numberOfCounts = numberOfCounts;

        _counts = calloc(numberOfCounts, sizeof(uint64_t));
        [data getBytes:_counts];
        
        return YES;
    }

    if (numberOfCounts != _numberOfCounts) {
        return NO;
    }

    for (NSUInteger i = 0; i < numberOfCounts; ++i) {
        _counts[i] += dataCounts[i];
    }
    return YES;
}

@end


@implementation STGCDA {
@private
    NSArray *_functions;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (id)init { return [self doesNotRecognizeSelector:_cmd], nil; }
#pragma clang diagnostic pop

- (id)initWithContentsOfFile:(NSString *)file {
    NSData * const data = [[NSData alloc] initWithContentsOfFile:file options:NSDataReadingMappedIfSafe error:NULL];
    return [self initWithData:data];
}
- (id)initWithContentsOfURL:(NSURL *)url {
    NSData * const data = [[NSData alloc] initWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:NULL];
    return [self initWithData:data];
}
- (id)initWithData:(NSData *)data {
	STGcovStream * const stream = [[STGcovStream alloc] initWithData:data];

	STGcovMagic magic = 0;
	STGcovVersion version = 0;
	uint32_t stamp = 0;
	if (![stream readUInt32:(uint32_t *)&magic] || ![stream readUInt32:(uint32_t *)&version] || ![stream readUInt32:&stamp]) {
		return nil;
	}

	BOOL validMagic = NO;
	switch (magic) {
		case STGcovMagicGCNO:
			break;
		case STGcovMagicGCDA:
			validMagic = YES;
			break;
	}
	if (!validMagic) {
		return nil;
	}

	BOOL knownVersion = NO;
	switch (version) {
		case STGcovVersion402:
			knownVersion = YES;
			break;
		case STGcovVersion404:
			break;
	}
	if (!knownVersion) {
		return nil;
	}

    uint32_t runCount = 0;

    NSMutableArray * const functions = [[NSMutableArray alloc] init];

	STGCDAFunction *function = nil;
	for (;;) {
		STGcovTag tag = 0;
		if (![stream readUInt32:&tag]) {
			break;
		}

		uint32_t tagLen = 0;
		if (![stream readUInt32:&tagLen]) {
			return NO;
		}
		if (tag == 0 && tagLen == 0) {
			break;
		}

		NSData *tagData = nil;
		if (![stream readDataLength:tagLen*4 data:&tagData]) {
			return NO;
		}

		switch (tag) {
			case STGcovTagFunction: {
				function = [self.class st_findOrCreateFunctionInFunctions:functions withData:tagData version:version];
			} break;
			case STGcovTagBlocks: {
				NSAssert(0, @"unexpected blocks tag in GCDA file");
			} break;
			case STGcovTagArcs: {
				NSAssert(0, @"unexpected arcs tag in GCDA file");
			} break;
			case STGcovTagLines: {
				NSAssert(0, @"unexpected lines tag in GCDA file");
			} break;
			case STGcovTagCounter: {
				if (![function addCountsFromData:tagData version:version]) {
					return NO;
				}
			} break;
            case STGcovTagObject: {
                STGcovStream * const s = [[STGcovStream alloc] initWithData:tagData];
                if (![s readUInt32:NULL]) { // checksum
                    continue;
                }
                if (![s readUInt32:NULL]) { // num
                    continue;
                }
                if (![s readUInt32:&runCount]) {
                    continue;
                }
            } break;
            case STGcovTagProgram: {
                STGcovStream * const s = [[STGcovStream alloc] initWithData:tagData];
                (void)s;

//                while (Buffer.readProgramTag()) {
//                    uint32_t Length;
//                    if (!Buffer.readInt(Length)) return false;
//                    Buffer.advanceCursor(Length);
//                    ++ProgramCount;
//                }
            } break;
			default: {
				NSAssert(0, @"unhandled tag");
			} break;
		}
	}

    [functions sortUsingComparator:^NSComparisonResult(STGCDAFunction * const a, STGCDAFunction * const b) {
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
        _runCount = runCount;
    }
	return self;
}

+ (STGCDAFunction *)st_findOrCreateFunctionInFunctions:(NSMutableArray *)functions withData:(NSData *)tagData version:(STGcovVersion)version {
	STGcovStream * const stream = [[STGcovStream alloc] initWithData:tagData];

	uint32_t functionIdentifier = 0;
	if (![stream readUInt32:&functionIdentifier]) {
		return nil;
	}

    uint32_t checksum = 0;
	if (![stream readUInt32:&checksum]) {
		return nil;
	}

	NSString *functionName = nil;
	if (![stream readString:&functionName]) {
		return nil;
	}

	for (STGCDAFunction *function in functions) {
		if (function.identifier == functionIdentifier) {
			if ([functionName length] && ![function.name isEqualToString:functionName]) {
				NSLog(@"warn: mismatching function name");
			}
			return function;
		}
	}
	STGCDAFunction *function = [[STGCDAFunction alloc] initWithIdentifier:functionIdentifier checksum:checksum name:functionName];
    if (function) {
        [functions addObject:function];
    }
    return function;
}

@end
