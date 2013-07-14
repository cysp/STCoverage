//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import "STGcov.h"


typedef NS_ENUM(NSUInteger, STGcovFormat) {
	STGcovFormatGCNO402 = 0x0102,
	STGcovFormatGCNO404 = 0x0104,
	STGcovFormatGCDA402 = 0x0202,
	STGcovFormatGCDA404 = 0x0204,
};
static STGcovFormat STGcovFormatFromData(NSData *data) {
	char buf[12] = { };
	[data getBytes:buf length:12];
	if (!memcmp(buf, "oncg*402MVLL", 12)) {
		return STGcovFormatGCNO402;
	}
	if (!memcmp(buf, "oncg*404MVLL", 12)) {
		return STGcovFormatGCNO404;
	}
	if (!memcmp(buf, "adcg*402MVLL", 12)) {
		return STGcovFormatGCDA402;
	}
	if (!memcmp(buf, "adcg*404MVLL", 12)) {
		return STGcovFormatGCDA404;
	}
	return 0;
}


@interface STGcovFunction : NSObject
@end
@interface STGcovFunction ()
+ (instancetype)functionFromData:(NSData *)data format:(STGcovFormat)format bytesRead:(NSUInteger *)bytesRead;
- (id)initWithIdentifier:(NSUInteger)identifier name:(NSString *)name filename:(NSString *)filename lineNumber:(NSUInteger)lineNumber;
@property (nonatomic,assign,readonly) NSUInteger identifier;
@property (nonatomic,copy,readonly) NSString *name;
@property (nonatomic,copy,readonly) NSString *filename;
@property (nonatomic,assign,readonly) NSUInteger lineNumber;
@property (nonatomic,strong,readonly) NSMutableArray *blocks;
@end
@implementation STGcovFunction
+ (instancetype)functionFromData:(NSData *)data format:(STGcovFormat)format bytesRead:(NSUInteger *)bytesRead {
	if (bytesRead) {
		*bytesRead = 0;
	}
	return nil;
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
@end


@interface STGcov ()
@property (nonatomic,strong,readonly) NSMutableArray *functions;
@end

@implementation STGcov

- (id)init {
	return [self initWithGCNOData:nil];
}
- (id)initWithGCNOData:(NSData *)gcno {
	STGcovFormat const format = STGcovFormatFromData(gcno);
	if (format == 0) {
		return nil;
	}

	NSUInteger const gcnoLength = [gcno length];
	if ((self = [super init])) {
		_functions = [[NSMutableArray alloc] init];

		NSUInteger cursor = 12; // file magic length
		for (;;) {
			NSUInteger bytesRead = 0;
			STGcovFunction *function = [STGcovFunction functionFromData:[gcno subdataWithRange:(NSRange){ .location = cursor, .length = gcnoLength - cursor }] format:format bytesRead:&bytesRead];
			if (!function) {
				break;
			}
			cursor += bytesRead;
			[_functions addObject:function];
		}
	}
	return self;
}

- (BOOL)addGCDAData:(NSData *)gcda {
	return NO;
}

- (NSArray *)sourceLineCoverageCounts {
	return @[ ];
}

@end
