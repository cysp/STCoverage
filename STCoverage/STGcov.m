//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import "STGcov.h"


static NSNumber *STEnsureNSNumber(id obj) {
	if ([obj isKindOfClass:[NSNumber class]]) {
		return obj;
	}
	return nil;
}


@interface STGcovStream : NSObject
- (id)initWithData:(NSData *)data;
- (BOOL)readUInt32:(NSUInteger *)value;
- (BOOL)readString:(NSString * __autoreleasing *)value;
- (BOOL)readDataLength:(NSUInteger)length data:(NSData * __autoreleasing *)value;
- (BOOL)isSpent;
@end

@implementation STGcovStream {
@private
	NSData *_data;
	NSUInteger _length;
	NSUInteger _cursor;
}

- (id)init {
	return [self initWithData:nil];
}
- (id)initWithData:(NSData *)data {
	if ((self = [super init])) {
		_data = data;
		_length = [_data length];
	}
	return self;
}

- (BOOL)readUInt32:(NSUInteger *)out {
	if ((_length - _cursor) < 4) {
		return NO;
	}

	char const * const bytes = [_data bytes];

	NSUInteger value = 0;
	value |= (bytes[_cursor+0] & 0xff);
	value |= (bytes[_cursor+1] & 0xff) << 8;
	value |= (bytes[_cursor+2] & 0xff) << 16;
	value |= (bytes[_cursor+3] & 0xff) << 24;

	_cursor += 4;

	if (out) {
		*out = value;
	}
	return YES;
}

- (BOOL)readUInt64:(uint64_t *)out {
	if ((_length - _cursor) < 8) {
		return NO;
	}

	char const * const bytes = [_data bytes];

	uint64_t value = 0;
	value |= (uint64_t)(bytes[_cursor+0] & 0xff);
	value |= (uint64_t)(bytes[_cursor+1] & 0xff) << 8;
	value |= (uint64_t)(bytes[_cursor+2] & 0xff) << 16;
	value |= (uint64_t)(bytes[_cursor+3] & 0xff) << 24;
	value |= (uint64_t)(bytes[_cursor+4] & 0xff) << 32;
	value |= (uint64_t)(bytes[_cursor+5] & 0xff) << 40;
	value |= (uint64_t)(bytes[_cursor+6] & 0xff) << 48;
	value |= (uint64_t)(bytes[_cursor+7] & 0xff) << 56;

	_cursor += 8;

	if (out) {
		*out = value;
	}
	return YES;
}

- (BOOL)readString:(NSString *__autoreleasing *)out {
	NSUInteger length = 0;
	if (![self readUInt32:&length]) {
		return NO;
	}
	length *= 4;

	if ((_length - _cursor) < length) {
		_cursor -= 4; // undo the -readUInt32 above
		return NO;
	}

	char const * const bytes = [_data bytes];

	NSString *value = [[NSString alloc] initWithBytes:&bytes[_cursor] length:length encoding:NSUTF8StringEncoding];
	value = [value stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithRange:(NSRange){ .location = 0, .length = 1 }]];
	_cursor += length;

	if (out) {
		*out = value;
	}
	return YES;
}

- (BOOL)readDataLength:(NSUInteger)length data:(NSData * __autoreleasing *)out {
	if ((_length - _cursor) < length) {
		return NO;
	}

	NSData *value = [_data subdataWithRange:(NSRange){ .location = _cursor, .length = length }];

	_cursor += length;

	if (out) {
		*out = value;
	}
	return YES;
}

- (BOOL)isSpent {
	return _cursor == _length;
}

@end


typedef NS_ENUM(NSUInteger, STGcovMagic) {
	STGcovMagicGCNO = 0x67636e6f,
	STGcovMagicGCDA = 0x67636461,
};
typedef NS_ENUM(NSUInteger, STGcovVersion) {
	STGcovVersion402 = 0x3430322a,
	STGcovVersion404 = 0x3430342a,
};


typedef NS_ENUM(NSUInteger, STGcovTag) {
	STGcovTagFunction = 0x01000000,
	STGcovTagBlocks   = 0x01410000,
	STGcovTagArcs     = 0x01430000,
	STGcovTagLines    = 0x01450000,
	STGcovTagCounter  = 0x01a10000,
};


@interface STGcovFunction : NSObject
@property (nonatomic,assign,readonly) NSUInteger identifier;
@property (nonatomic,copy,readonly) NSString *name;
@property (nonatomic,copy,readonly) NSString *filename;
@property (nonatomic,assign,readonly) NSUInteger lineNumber;
@property (nonatomic,strong,readonly) NSArray *blocks;
- (id)initWithData:(NSData *)data version:(STGcovVersion)version;
- (BOOL)addBlocksFromData:(NSData *)data version:(STGcovVersion)version;
- (BOOL)addArcsFromData:(NSData *)data version:(STGcovVersion)version;
- (BOOL)addLinesFromData:(NSData *)data version:(STGcovVersion)version;
- (BOOL)addCountsFromData:(NSData *)data version:(STGcovVersion)version;
@end
typedef void(^STGcovBlockCoverageEnumerator)(NSString *filename, NSUInteger lineNumber, uint64_t count);
@interface STGcovBlock : NSObject
@property (nonatomic,assign,readonly) NSUInteger flags;
@property (nonatomic,assign,readonly) uint64_t count;
- (id)initWithFlags:(NSUInteger)flags;
- (BOOL)addArcWithIdentifier:(NSUInteger)arcIdentifier flags:(NSUInteger)arcFlags;
- (BOOL)addFilename:(NSString *)filename lineNumber:(NSUInteger)lineNumber;
- (void)addCount:(uint64_t)count;
- (void)enumerateCoveredLinesWithBlock:(STGcovBlockCoverageEnumerator)block;
@end
@interface STGcovArc : NSObject
@property (nonatomic,assign,readonly) NSUInteger identifier;
@property (nonatomic,assign,readonly) NSUInteger flags;
- (id)initWithIdentifier:(NSUInteger)identifier flags:(NSUInteger)flags;
@end


@interface STGcov ()
@property (nonatomic,strong,readonly) NSMutableArray *functions;
@end
@implementation STGcov

- (id)init {
	return [self initWithGCNOData:nil];
}
- (id)initWithGCNOData:(NSData *)gcno {
	STGcovStream *stream = [[STGcovStream alloc] initWithData:gcno];

	STGcovMagic magic = 0;
	STGcovVersion version = 0;
	NSUInteger stamp = 0;
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

	if ((self = [super init])) {
		_functions = [[NSMutableArray alloc] init];

		for (;;) {
			STGcovTag tag = 0;
			if (![stream readUInt32:&tag]) {
				break;
			}

			NSUInteger tagLen = 0;
			if (![stream readUInt32:&tagLen]) {
				break;
			}

			NSData *tagData = nil;
			if (![stream readDataLength:tagLen*4 data:&tagData]) {
				break;
			}

			switch (tag) {
				case STGcovTagFunction: {
					STGcovFunction *function = [[STGcovFunction alloc] initWithData:tagData version:version];
					if (function) {
						[_functions addObject:function];
					}
				} break;
				case STGcovTagBlocks: {
					STGcovFunction *function = [_functions lastObject];
					[function addBlocksFromData:tagData version:version];
				} break;
				case STGcovTagArcs: {
					STGcovFunction *function = [_functions lastObject];
					[function addArcsFromData:tagData version:version];
				} break;
				case STGcovTagLines: {
					STGcovFunction *function = [_functions lastObject];
					[function addLinesFromData:tagData version:version];
				} break;
				case STGcovTagCounter: {
					NSAssert(0, @"unexpected counter tag in GCNO file");
				} break;
			}
		}
	}
	return self;
}

- (BOOL)addGCDAData:(NSData *)gcda {
	STGcovStream *stream = [[STGcovStream alloc] initWithData:gcda];

	STGcovMagic magic = 0;
	STGcovVersion version = 0;
	NSUInteger stamp = 0;
	if (![stream readUInt32:&magic] || ![stream readUInt32:&version] || ![stream readUInt32:&stamp]) {
		return NO;
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
		return NO;
	}

	BOOL knownVersion = NO;
	switch (version) {
		case STGcovVersion402:
		case STGcovVersion404:
			knownVersion = YES;
			break;
	}
	if (!knownVersion) {
		return NO;
	}

	STGcovFunction *function = nil;
	for (;;) {
		STGcovTag tag = 0;
		if (![stream readUInt32:&tag]) {
			break;
		}

		NSUInteger tagLen = 0;
		if (![stream readUInt32:&tagLen]) {
			break;
		}

		NSData *tagData = nil;
		if (![stream readDataLength:tagLen*4 data:&tagData]) {
			break;
		}

		switch (tag) {
			case STGcovTagFunction: {
				function = [self st_existingFunctionWithData:tagData version:version];
			} break;
			case STGcovTagBlocks: {
				NSAssert(0, @"unexpected blocks tag in GCNO file");
			} break;
			case STGcovTagArcs: {
				NSAssert(0, @"unexpected arcs tag in GCNO file");
			} break;
			case STGcovTagLines: {
				NSAssert(0, @"unexpected lines tag in GCNO file");
			} break;
			case STGcovTagCounter: {
				[function addCountsFromData:tagData version:version];
			} break;
		}
	}
	return YES;
}

- (STGcovFunction *)st_existingFunctionWithData:(NSData *)tagData version:(STGcovVersion)version {
	STGcovStream *stream = [[STGcovStream alloc] initWithData:tagData];
	NSUInteger functionIdentifier = 0;
	if (![stream readUInt32:&functionIdentifier]) {
		return nil;
	}

	if (![stream readUInt32:NULL]) { // checksum #1
		return nil;
	}
//	if (version != STGcovVersion402) {
//		if (![stream readUInt32:NULL]) { // checksum #2
//			return nil;
//		}
//	}

	NSString *functionName = nil;
	if (![stream readString:&functionName]) {
		return nil;
	}

	for (STGcovFunction *function in _functions) {
		if (function.identifier == functionIdentifier) {
			if ([functionName length] && ![function.name isEqualToString:functionName]) {
				NSLog(@"warn: mismatching function name");
			}
			return function;
		}
	}
	return nil;
}


- (NSDictionary *)sourceLineCoverageCounts {
	NSMutableDictionary *largestLineNumbersByFilename = [[NSMutableDictionary alloc] init];
	for (STGcovFunction *function in self.functions) {
		for (STGcovBlock *block in function.blocks) {
			[block enumerateCoveredLinesWithBlock:^(NSString *filename, NSUInteger lineNumber, uint64_t count) {
				NSUInteger largestLineNumber = [largestLineNumbersByFilename[filename] unsignedIntegerValue];
				if (lineNumber > largestLineNumber) {
					largestLineNumbersByFilename[filename] = @(lineNumber);
				}
			}];
		}
	}

	NSMutableDictionary *coverageCountsByFilename = [[NSMutableDictionary alloc] init];
	[largestLineNumbersByFilename enumerateKeysAndObjectsUsingBlock:^(NSString *filename, NSNumber *largestLineNumber, BOOL *stop) {
		NSMutableArray *lineCounts = [[NSMutableArray alloc] initWithCapacity:[largestLineNumber unsignedIntegerValue]];
		for (NSUInteger i = 0; i < [largestLineNumber unsignedIntegerValue]; ++i) {
			lineCounts[i] = [NSNull null];
		}
		coverageCountsByFilename[filename] = lineCounts;
	}];
	for (STGcovFunction *function in self.functions) {
		for (STGcovBlock *block in function.blocks) {
			[block enumerateCoveredLinesWithBlock:^(NSString *filename, NSUInteger lineNumber, uint64_t count) {
				NSMutableArray *coverageCounts = coverageCountsByFilename[filename];
				if (!coverageCounts) {
					coverageCounts = [[NSMutableArray alloc] init];
					coverageCountsByFilename[filename] = coverageCounts;
				}
				NSNumber *coverageCount = STEnsureNSNumber(coverageCounts[lineNumber-1]);
				coverageCounts[lineNumber-1] = @([coverageCount unsignedIntegerValue] + count);
			}];
		}
	}
	return coverageCountsByFilename;
}

@end

@interface STGcovFunction ()
@end
@implementation STGcovFunction {
@private
	NSMutableArray *_blocks;
}
- (id)init {
	return [self initWithIdentifier:0 name:nil filename:nil lineNumber:0];
}
- (id)initWithIdentifier:(NSUInteger)identifier name:(NSString *)name filename:(NSString *)filename lineNumber:(NSUInteger)lineNumber {
	if ((self = [super init])) {
		_identifier = identifier;
		_name = [name copy];
		_filename = [filename copy];
		_lineNumber = lineNumber;
		_blocks = [[NSMutableArray alloc] initWithCapacity:16];
	}
	return self;
}
- (id)initWithData:(NSData *)data version:(STGcovVersion)version {
	STGcovStream * const stream = [[STGcovStream alloc] initWithData:data];

	NSUInteger identifier = 0;
	if (![stream readUInt32:&identifier]) {
		return nil;
	}

	if (![stream readUInt32:NULL]) { // checksum #1
		return nil;
	}
//	if (version != STGcovVersion402) {
//		if (![stream readUInt32:NULL]) { // checksum #2
//			return nil;
//		}
//	}

	NSString *name = nil;
	if (![stream readString:&name]) {
		return nil;
	}
	NSString *filename = nil;
	if (![stream readString:&filename]) {
		return nil;
	}

	NSUInteger lineNumber = 0;
	if (![stream readUInt32:&lineNumber]) {
		return nil;
	}

	if (![stream isSpent]) {
		return nil;
	}

	if ((self = [self initWithIdentifier:identifier name:name filename:filename lineNumber:lineNumber])) {
	}
	return self;
}

- (BOOL)addBlocksFromData:(NSData *)data version:(STGcovVersion)version {
	STGcovStream *stream = [[STGcovStream alloc] initWithData:data];

	NSUInteger blockFlags = 0;
	while ([stream readUInt32:&blockFlags]) {
		STGcovBlock *block = [[STGcovBlock alloc] initWithFlags:blockFlags];
		[_blocks addObject:block];
	}

	return [stream isSpent];
}

- (BOOL)addArcsFromData:(NSData *)data version:(STGcovVersion)version {
	STGcovStream *stream = [[STGcovStream alloc] initWithData:data];

	NSUInteger blockNumber = 0;
	if (![stream readUInt32:&blockNumber]) {
		return NO;
	}
	if (blockNumber >= [_blocks count]) {
		return NO;
	}
	STGcovBlock *block = _blocks[blockNumber];

	NSUInteger arcIdentifier = 0;
	while ([stream readUInt32:&arcIdentifier]) {
		NSUInteger arcFlags = 0;
		if (![stream readUInt32:&arcFlags]) {
			return NO;
		}
		[block addArcWithIdentifier:arcIdentifier flags:arcFlags];
	}

	return [stream isSpent];
}

- (BOOL)addLinesFromData:(NSData *)data version:(STGcovVersion)version {
	STGcovStream *stream = [[STGcovStream alloc] initWithData:data];

	NSUInteger blockNumber = 0;
	if (![stream readUInt32:&blockNumber]) {
		return NO;
	}

	if (blockNumber >= [_blocks count]) {
		return NO;
	}
	STGcovBlock *block = _blocks[blockNumber];

//	if (![stream readUInt32:NULL]) { // flag
//		return NO;
//	}

	NSString *filename = nil;
	NSUInteger lineNumber = 0;
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

- (BOOL)addCountsFromData:(NSData *)data version:(STGcovVersion)version {
	STGcovStream *stream = [[STGcovStream alloc] initWithData:data];

	for (NSUInteger blockNumber = 0; ; ++blockNumber) {
		uint64_t count = 0;
		if (![stream readUInt64:&count]) {
			break;
		}
		if (blockNumber >= [_blocks count]) {
			return NO;
		}
		STGcovBlock *block = _blocks[blockNumber];
		[block addCount:count];
	}

	return [stream isSpent];
}

@end


@interface STGcovBlock ()
@property (nonatomic,strong,readonly) NSMutableDictionary *arcsByIdentifier;
@property (nonatomic,strong,readonly) NSMutableDictionary *coveredLinesByFile; // string -> countedset
@end
@implementation STGcovBlock
- (id)initWithFlags:(NSUInteger)flags {
	if ((self = [super init])) {
		_flags = flags;
		_arcsByIdentifier = [[NSMutableDictionary alloc] init];
		_coveredLinesByFile = [[NSMutableDictionary alloc] init];
	}
	return self;
}
- (BOOL)addArcWithIdentifier:(NSUInteger)arcIdentifier flags:(NSUInteger)arcFlags {
	id<NSCopying> key = @(arcIdentifier);
	if (_arcsByIdentifier[key]) {
		return NO;
	}
	_arcsByIdentifier[key] = [[STGcovArc alloc] initWithIdentifier:arcIdentifier flags:arcFlags];
	return YES;
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
- (void)addCount:(uint64_t)count {
	_count += count;
}
- (void)enumerateCoveredLinesWithBlock:(STGcovBlockCoverageEnumerator)block {
	if (!block) {
		return;
	}
	[_coveredLinesByFile enumerateKeysAndObjectsUsingBlock:^(NSString *filename, NSCountedSet *lineNumbers, BOOL *stop) {
		[lineNumbers enumerateObjectsUsingBlock:^(NSNumber *lineNumber, BOOL *stop) {
			NSUInteger multiplier = [lineNumbers countForObject:lineNumber];
			block(filename, [lineNumber unsignedIntegerValue], _count * multiplier);
		}];
	}];
}
@end


@interface STGcovArc ()
@end
@implementation STGcovArc
- (id)init {
	return [self initWithIdentifier:0 flags:0];
}
- (id)initWithIdentifier:(NSUInteger)identifier flags:(NSUInteger)flags {
	if ((self = [super init])) {
		_identifier = identifier;
		_flags = flags;
	}
	return self;
}
@end
