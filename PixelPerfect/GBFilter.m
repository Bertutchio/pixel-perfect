//
//  GBFilter.m
//  PixelPerfect
//
//  Created by Paul Rodrigues on 10/11/2014.
//  Copyright (c) 2014 Rodrigues Paul. All rights reserved.
//

#import "GBFilter.h"

#define GBF_BYTES_PER_PIXEL 4
#define GBF_BITS_PER_COMPONENT 8
#define GBF_PIXELATE_DEFAULT_VALUE 5

#define getGreyscaleForValue(v) (v < 85 ? 0 : ( v < 170 ? 85 : ( v < 255 ? 170 : 255 ) ) )
#define getMatrixFactorFromMatrixValue(v, mSize) ((1.0+v)/(1.0+mSize))

//Formula : (1 + Mij) / (1 + m x n)

@interface GBFilter()

//image
@property(nonatomic) unsigned char *imageData;
@property(nonatomic) size_t width;
@property(nonatomic) size_t height;
@property(nonatomic) BOOL imageHasChanged;
@property(nonatomic) unsigned long currentAllocatedMemory;

//matrix
@property(nonatomic) unsigned int *matrix;
@property(nonatomic) unsigned int matrixSize;

//draw
@property(nonatomic) CGContextRef drawContext;
@property(nonatomic) Byte *filteredImageData;

- (void)initMatrix;
- (void)filterWitherGrey;
- (void)filterWitherColor;

@end



@implementation GBFilter

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        [self initMatrix];
    }
    
    return self;
}



- (instancetype)initWithContentOfURL:(NSURL *)url
{
    self = [self init];
    
    if(self)
    {
        [self setRawImage:[CIImage imageWithContentsOfURL:url]];
    }
    
    return self;
}


- (instancetype)initWithImage:(CIImage *)image
{
    self = [super init];
    
    if(self)
    {
        [self setRawImage:image];
    }
    
    return self;
}


- (void)setRawImage:(CIImage *)rawImage
{
    _rawImage = rawImage;
    _imageHasChanged = YES;
}


- (void)initMatrix
{
     /*
     { 0, 48, 12, 60, 3, 51, 15, 63,
     32, 16, 44, 28, 35, 19, 47, 31,
     8, 56, 4, 52, 11, 59, 7, 55,
     40, 24, 36, 20, 43, 27, 39, 23,
     2, 50, 14, 62, 1, 49, 13, 61,
     34, 18, 46, 30, 33, 17, 45, 29,
     10, 58, 6, 54, 9, 57, 5, 53,
     42, 26, 38, 22, 41, 25, 37, 21 };
      */
    
    _matrix = malloc(sizeof(int) * 64);

    _matrix[0] = 0;
    _matrix[1] = 48;
    _matrix[2] = 12;
    _matrix[3] = 60;
    _matrix[4] = 3;
    _matrix[5] = 51;
    _matrix[6] = 15;
    _matrix[7] = 63;
    
    _matrix[8] = 32;
    _matrix[9] = 16;
    _matrix[10] = 44;
    _matrix[11] = 28;
    _matrix[12] = 35;
    _matrix[13] = 19;
    _matrix[14] = 47;
    _matrix[15] = 31;
    
    _matrix[16] = 8;
    _matrix[17] = 56;
    _matrix[18] = 4;
    _matrix[19] = 52;
    _matrix[20] = 11;
    _matrix[21] = 59;
    _matrix[22] = 7;
    _matrix[23] = 55;
    
    _matrix[24] = 40;
    _matrix[25] = 24;
    _matrix[26] = 36;
    _matrix[27] = 20;
    _matrix[28] = 43;
    _matrix[29] = 27;
    _matrix[30] = 39;
    _matrix[31] = 23;
    
    _matrix[32] = 2;
    _matrix[33] = 50;
    _matrix[34] = 14;
    _matrix[35] = 62;
    _matrix[36] = 1;
    _matrix[37] = 49;
    _matrix[38] = 13;
    _matrix[39] = 61;
    
    _matrix[40] = 34;
    _matrix[41] = 18;
    _matrix[42] = 46;
    _matrix[43] = 30;
    _matrix[44] = 33;
    _matrix[45] = 17;
    _matrix[46] = 45;
    _matrix[47] = 29;
    
    _matrix[48] = 10;
    _matrix[49] = 58;
    _matrix[50] = 6;
    _matrix[51] = 54;
    _matrix[52] = 9;
    _matrix[53] = 57;
    _matrix[54] = 5;
    _matrix[55] = 53;
    
    _matrix[56] = 42;
    _matrix[57] = 26;
    _matrix[58] = 38;
    _matrix[59] = 22;
    _matrix[60] = 41;
    _matrix[61] = 25;
    _matrix[62] = 37;
    _matrix[63] = 21;
    
    _matrixSize = 64;
}


- (void)initFilter
{
    if(_imageHasChanged)
    {
        CIContext *context = [CIContext contextWithOptions:nil];
        CGRect rect        = [_rawImage extent];
        
        CGImageRef imageRef = [context createCGImage:_rawImage fromRect:rect];
        
        _width  = CGImageGetWidth(imageRef);
        _height = CGImageGetHeight(imageRef);
        
        _currentAllocatedMemory = _height * _width * GBF_BYTES_PER_PIXEL;
        
        //alloc or realloc
        if(_imageData == nil)
        {
            _imageData         = malloc(_currentAllocatedMemory);
            _filteredImageData = malloc(_currentAllocatedMemory);
        }
        else
        {
            _imageData = realloc(_imageData, _currentAllocatedMemory);
            _filteredImageData = realloc(_filteredImageData, _currentAllocatedMemory);
        }
        
        CGColorSpaceRef colorSpace  = CGColorSpaceCreateDeviceRGB();
        
        //fill omage data array
        CGContextRef cgContext  = CGBitmapContextCreate(_imageData, _width, _height, GBF_BITS_PER_COMPONENT, (GBF_BYTES_PER_PIXEL * _width), colorSpace, (CGBitmapInfo) kCGImageAlphaPremultipliedLast);
        
        CGContextDrawImage(cgContext, CGRectMake(0, 0, _width, _height), imageRef);
        
        
        //reset context if already used
        if(_drawContext != nil)
            CGContextRelease(_drawContext);
        
        //copie structure
        memcpy(_filteredImageData, _imageData, _currentAllocatedMemory);
        
        //associate context with filtered data array
        _drawContext = CGBitmapContextCreate(_filteredImageData, _width, _height, GBF_BITS_PER_COMPONENT, (GBF_BYTES_PER_PIXEL * _width), colorSpace, (CGBitmapInfo) kCGImageAlphaPremultipliedLast);
        
            
        //clean
        CGColorSpaceRelease(colorSpace);
        CGImageRelease(imageRef);
        CGContextRelease(cgContext);

        context = nil;
        
        _imageHasChanged = NO;
    }
}



- (void)filterWitherGrey
{
    [self initFilter];
    
    CFTimeInterval startTime = CACurrentMediaTime();
    
    unsigned long lastIndex       = _currentAllocatedMemory-1;
    unsigned long lastPixelOfLine = _width - 1;

    unsigned int y = 0;
    unsigned int x = 0;
    
    float currentFactor;
    unsigned int currentGrey;
    unsigned int color;
    
    for (unsigned int index = 0; index < lastIndex; index += GBF_BYTES_PER_PIXEL) {
        
        currentFactor = getMatrixFactorFromMatrixValue(_matrix[(x & 7) + ((y & 7) << 3)], _matrixSize);
        currentGrey   = (_imageData[index] + _imageData[index+1] + _imageData[index+2]) * 0.33333;
        
        color = getGreyscaleForValue(currentGrey + currentFactor * 64);
        
        _filteredImageData[index]   = color;
        _filteredImageData[index+1] = color;
        _filteredImageData[index+2] = color;
        
        if(x == lastPixelOfLine)
        {
            y++;
            x=0;
        }
        else
            x++;
    }

    CFTimeInterval endTime = CACurrentMediaTime();
    NSLog(@"Applied grey halftone in %g sec", endTime - startTime);
}



- (void)filterWitherColor
{
    [self initFilter];

    CFTimeInterval startTime = CACurrentMediaTime();
    
    unsigned long lastIndex       = _currentAllocatedMemory-1;
    unsigned long lastPixelOfLine = _width - 1;
    
    unsigned int y = 0;
    unsigned int x = 0;
    
    float currentFactor;
    
    for (unsigned long index = 0; index < lastIndex; index += GBF_BYTES_PER_PIXEL) {

        currentFactor = getMatrixFactorFromMatrixValue(_matrix[(x & 7) + ((y & 7) << 3)], _matrixSize);
        
        _filteredImageData[index]   = getGreyscaleForValue(_imageData[index]   + currentFactor * 64);
        _filteredImageData[index+1] = getGreyscaleForValue(_imageData[index+1] + currentFactor * 64);
        _filteredImageData[index+2] = getGreyscaleForValue(_imageData[index+2] + currentFactor * 64);
        
        if(x == lastPixelOfLine)
        {
            y++;
            x = 0;
        }
        else
            x++;
    }
    
    CFTimeInterval endTime = CACurrentMediaTime();
    NSLog(@"Applied color halftone in %g sec", endTime - startTime);
}


- (CIImage *)getFilteredImageUsingMethod:(NSString *)method
{
    if([method isEqualToString:@"color"])
       [self filterWitherColor];
    else
       [self filterWitherGrey];
    
    CGImageRef bitmap = CGBitmapContextCreateImage(_drawContext);
    
    CIFilter *pixelate = [CIFilter filterWithName:@"CIPixellate"];
    [pixelate setValue:[CIImage imageWithCGImage:bitmap] forKey:kCIInputImageKey];
    [pixelate setValue:[NSNumber numberWithFloat:_pixelateValue] forKey:kCIInputScaleKey];
    
    //clean
    CGImageRelease(bitmap);
    
    return [pixelate outputImage];
}



- (void)dealloc {

    CGContextRelease(_drawContext);
    free(_imageData);
    free(_filteredImageData);
    free(_matrix);

}

@end
