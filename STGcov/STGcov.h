//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>


@interface STGcov : NSObject

- (BOOL)addGCNOData:(NSData *)gcno;

- (BOOL)addGCDAData:(NSData *)gcda;

- (NSDictionary *)sourceLineCoverageCounts;

@end
