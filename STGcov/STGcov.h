//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>


@interface STGcov : NSObject

- (id)initWithGCNOData:(NSData *)gcno;

- (BOOL)addGCDAData:(NSData *)gcda;

- (NSArray *)sourceLineCoverageCounts;

@end
