//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import <STGcov/STGcov.h>


typedef NS_ENUM(uint32_t, STGcovMagic) {
	STGcovMagicGCNO = 0x67636e6f,
	STGcovMagicGCDA = 0x67636461,
};

typedef NS_ENUM(uint32_t, STGcovVersion) {
	STGcovVersion402 = 0x3430322a,
	STGcovVersion404 = 0x3430342a,
};

typedef NS_ENUM(uint32_t, STGcovStamp) {
	STGcovStampLLVM = 0x4c4c564d,
};


typedef NS_ENUM(uint32_t, STGcovTag) {
	STGcovTagFunction = 0x01000000,
	STGcovTagBlocks   = 0x01410000,
	STGcovTagArcs     = 0x01430000,
	STGcovTagLines    = 0x01450000,
	STGcovTagCounter  = 0x01a10000,
	STGcovTagObject   = 0xa1000000,
	STGcovTagProgram  = 0xa3000000,
};
