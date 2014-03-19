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
		if (argc < 2) {
			usage([[argv0 lastPathComponent] UTF8String] ?: "STGcov");
		}

        NSMutableArray * const baseURLs = [[NSMutableArray alloc] initWithCapacity:argc - 2];
		for (int i = 1; i < argc; ++i) {
			NSString * const path = [[NSString alloc] initWithUTF8String:argv[i]];
            NSURL * const url = [NSURL fileURLWithPath:path];
            [baseURLs addObject:url];
		}

        NSMutableArray *gcnoURLs = [[NSMutableArray alloc] init];
        for (NSURL *baseURL in baseURLs) {
            NSDirectoryEnumerator * const enumerator = [[NSFileManager defaultManager] enumeratorAtURL:baseURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
            for (NSURL *url in enumerator) {
                NSString * const extension = url.pathExtension;
                if ([@"gcno" isEqualToString:extension]) {
                    [gcnoURLs addObject:url];
                }
            }
        }

//        STGcovCoverageAccumulator * const accum = [[STGcovCoverageAccumulator alloc] init];

		for (NSURL *gcnoURL in gcnoURLs) {
            STGCNO * const gcno = [[STGCNO alloc] initWithContentsOfURL:gcnoURL];
            if (!gcno) {
                continue;
            }

            NSURL * const gcdaURL = [gcnoURL.URLByDeletingPathExtension URLByAppendingPathExtension:@"gcda"];
            STGCDA * const gcda = [[STGCDA alloc] initWithContentsOfURL:gcdaURL];

            STGcov * const cov = [[STGcov alloc] initWithGCNO:gcno];
            if ([cov addGCDA:gcda]) {
                NSLog(@"%@", cov.coverage);
            }
//            [accum addCoverage:cov.coverage];
		}

//        NSArray * const coveredFilenames = accum.filenames;
//
//		NSMutableDictionary *coverageJSONObject = [NSMutableDictionary dictionaryWithCapacity:coveredFilenames.count];
//        for (NSString * const filename in coveredFilenames) {
//            STGcovFileCoverage * const fileCoverage = [accum coverageForFile:filename];
//            NSIndexSet * const coveredLines = fileCoverage.coveredLines;
//            NSMutableDictionary * const coverageFileJSONObject = [NSMutableDictionary dictionaryWithCapacity:coveredLines.count];
//            [coveredLines enumerateIndexesUsingBlock:^(NSUInteger lineNumber, BOOL *stop) {
//                NSString * const lineNumberString = [NSString stringWithFormat:@"%lu", (unsigned long)lineNumber];
//                NSUInteger const lineCoverage = [fileCoverage coverageForLine:lineNumber];
//                if (lineCoverage) {
//                    coverageFileJSONObject[lineNumberString] = @(lineCoverage);
//                }
//            }];
//            coverageJSONObject[filename] = coverageFileJSONObject;
//        }
//
//		NSData *output = [NSJSONSerialization dataWithJSONObject:coverageJSONObject options:0 error:NULL];
//		[output writeToFile:@"/dev/stdout" options:0 error:NULL];
	}
    return 0;
}
