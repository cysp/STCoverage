//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>


@interface STGcov : NSObject

- (id)initWithSourceFile:(NSData *)source GCNOData:(NSData *)gcno;

- (void)addGCDAData:(NSData *)gcda;

- (NSArray *)sourceLines;
- (NSArray *)sourceLineCoverageCounts;

@end
