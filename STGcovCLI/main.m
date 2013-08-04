//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import <Foundation/Foundation.h>

#import "STGcov.h"


void __attribute__((noreturn)) usage(char const * const argv0) {
	fprintf(stderr, "Usage: %s <file.gcno> <file.gcda>...", argv0);
	exit(1);
}

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		NSString *argv0 = [[NSString alloc] initWithUTF8String:argv[0]];
		if (argc < 3) {
			usage([[argv0 lastPathComponent] UTF8String] ?: "STGcov");
		}

		NSMutableArray *gcnoFilenames = [[NSMutableArray alloc] init];
		NSMutableArray *gcdaFilenames = [[NSMutableArray alloc] init];
		NSMutableArray *otherFilenames = [[NSMutableArray alloc] init];

		for (int i = 1; i < argc; ++i) {
			NSString *filename = [[NSString alloc] initWithUTF8String:argv[i]];
			if ([filename hasSuffix:@".gcno"]) {
				[gcnoFilenames addObject:filename];
			} else if ([filename hasSuffix:@".gcda"]) {
				[gcdaFilenames addObject:filename];
			} else {
				[otherFilenames addObject:filename];
			}
		}

		STGcov *cov = [[STGcov alloc] init];

		for (NSString *gcnoFilename in gcnoFilenames) {
			NSData *gcnoData = [[NSData alloc] initWithContentsOfFile:gcnoFilename options:NSDataReadingMappedIfSafe error:NULL];
			if (!gcnoData) {
				return 1;
			}
			if (![cov addGCNOData:gcnoData]) {
				return 1;
			}
		}

		for (NSString *gcdaFilename in gcdaFilenames) {
			NSData *gcdaData = [[NSData alloc] initWithContentsOfFile:gcdaFilename options:NSDataReadingMappedIfSafe error:NULL];
			if (!gcdaData) {
				return 1;
			}
			if (![cov addGCDAData:gcdaData]) {
				return 1;
			}
		}

		NSDictionary *coverage = [cov sourceLineCoverageCounts];
		NSData *output = [NSJSONSerialization dataWithJSONObject:coverage options:0 error:NULL];
		[output writeToFile:@"/dev/stdout" options:0 error:NULL];
	}
    return 0;
}
