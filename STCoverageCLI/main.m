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
			usage([[argv0 lastPathComponent] UTF8String] ?: "STCoverage");
		}

		NSString *gcnoFilename = [[NSString alloc] initWithUTF8String:argv[1]];
		NSData *gcnoData = [[NSData alloc] initWithContentsOfFile:gcnoFilename options:NSDataReadingMappedIfSafe error:NULL];
		if (!gcnoData) {
			return 1;
		}
		STGcov *cov = [[STGcov alloc] initWithGCNOData:gcnoData];
		if (!cov) {
			return 1;
		}

		for (int i = 2; i < argc; ++i) {
			NSString *gcdaFilename = [[NSString alloc] initWithUTF8String:argv[i]];
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
