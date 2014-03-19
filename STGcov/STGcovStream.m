//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import "STGcovStream.h"


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

- (BOOL)readUInt32:(uint32_t *)out {
	if ((_length - _cursor) < 4) {
		return NO;
	}

	char const * const bytes = [_data bytes];

	uint32_t value = 0;
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
	uint32_t length = 0;
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
