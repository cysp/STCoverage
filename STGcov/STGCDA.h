//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import <STGcov/STGcov.h>


@interface STGCDA : NSObject
- (id)init __attribute__((unavailable));
- (id)initWithContentsOfFile:(NSString *)file;
- (id)initWithContentsOfURL:(NSURL *)url;
- (id)initWithData:(NSData *)data __attribute__((objc_designated_initializer));
@property (nonatomic,copy,readonly) NSArray *functions;
@end

@interface STGCDAFunction : NSObject
@property (nonatomic,assign,readonly) NSUInteger identifier;
@property (nonatomic,assign,readonly) uint32_t checksum;
@property (nonatomic,copy,readonly) NSString *name;
@property (nonatomic,assign,readonly) NSUInteger numberOfCounts;
@property (nonatomic,assign,readonly) uint64_t *counts;
@end
