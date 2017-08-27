//
//  GBFilter.h
//  PixelPerfect
//
//  Created by Paul Rodrigues on 10/11/2014.
//  Copyright (c) 2014 Rodrigues Paul. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GBFILTER_WORKING_DIMENSION 100

@interface GBFilter : NSObject

@property (nonatomic) CIImage *rawImage;
@property (nonatomic) float pixelateValue;

- (instancetype)initWithImage:(CIImage *)image;
- (instancetype)initWithContentOfURL:(NSURL *)url;
- (CIImage *)getFilteredImageUsingMethod:(NSString *)method;


@end
