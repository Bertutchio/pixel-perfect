//
//  ViewController.m
//  PixelPerfect
//
//  Created by Paul Rodrigues on 14/07/2014.
//  Copyright (c) 2014 Rodrigues Paul. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "ViewController.h"
#import "GBFilter.h"


@interface ViewController()

@property(nonatomic) UIImagePickerController *picker;
@property(nonatomic) float currentSliderValue;
@property(copy) void (^applyFilter)(void);
@property(nonatomic) GBFilter *filter;

-(void)initPicker;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //Load image
    NSString *filePath     = [[NSBundle mainBundle] pathForResource:@"sunset" ofType:@"jpg"];
    NSURL *fileNameAndPath = [NSURL fileURLWithPath:filePath];
    _rawImage              = [CIImage imageWithContentsOfURL:fileNameAndPath];
    
    //Display Image
    _resultImage.image = [UIImage imageWithCIImage:_rawImage];
    _currentSliderValue = _intensity.value;
    
    //block
    _filter = [[GBFilter alloc] init];
    [_filter setPixelateValue:_currentSliderValue];
    [_filter setRawImage:_rawImage];
    
    
    
    
    ViewController * __weak weakSelf = self;
    _applyFilter = ^{
     
        NSString *method;
        
        if(weakSelf.filterMethod.selectedSegmentIndex == 1)
            method = @"color";
        else
            method = @"grey";
        
        CFTimeInterval startTime = CACurrentMediaTime();
        
        weakSelf.resultImage.image = [UIImage imageWithCIImage:[weakSelf.filter getFilteredImageUsingMethod:method]];
    
        CFTimeInterval endTime = CACurrentMediaTime();
        NSLog(@"Total Runtime %g sec for %@", endTime - startTime, method);

    };
}


-(void)initPicker
{
    //init picker controler

    if(!_picker)
    {
        _picker = [[UIImagePickerController alloc] init];
        _picker.allowsEditing = NO;
        _picker.delegate      = self;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)showCamera:(id)sender {
    
    [self initPicker];
    
    [_picker setSourceType: UIImagePickerControllerSourceTypeCamera];
    [self presentViewController:_picker animated:YES completion:NULL];
    
}


- (IBAction)showCameraRoll:(id)sender {
    
    [self initPicker];
    
    [_picker setSourceType: UIImagePickerControllerSourceTypePhotoLibrary];
    [self presentViewController:_picker animated:YES completion:NULL];
    
}

- (IBAction)setEffectIntensity:(id)sender {

    float stepedIntensity = (int)(_intensity.value * 2) * 0.5;
    
    if(stepedIntensity != _currentSliderValue)
    {
        _currentSliderValue = stepedIntensity;
        _intensityValueLabel.text = [NSString stringWithFormat:@"%0.1f", _currentSliderValue];
        
        [_filter setPixelateValue:_currentSliderValue];
        
        _applyFilter();
    }
}

- (IBAction)changeMethod:(id)sender {
    
    _applyFilter();
    
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *photo = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    _resultImage.image = photo;
    
    _rawImage = [[CIImage alloc] initWithImage:photo];
    
    [_filter setRawImage:_rawImage];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end


