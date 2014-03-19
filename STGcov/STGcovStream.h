//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>


@interface STGcovStream : NSObject
- (id)init __attribute__((unavailable));
- (id)initWithData:(NSData *)data __attribute__((objc_designated_initializer));
- (BOOL)readUInt32:(uint32_t *)value;
- (BOOL)readString:(NSString * __autoreleasing *)value;
- (BOOL)readDataLength:(NSUInteger)length data:(NSData * __autoreleasing *)value;
- (BOOL)isSpent;
@end
