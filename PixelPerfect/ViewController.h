//
//  ViewController.h
//  PixelPerfect
//
//  Created by Paul Rodrigues on 14/07/2014.
//  Copyright (c) 2014 Rodrigues Paul. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic) CIImage *rawImage;
@property (weak, nonatomic) IBOutlet UIImageView *resultImage;
@property (weak, nonatomic) IBOutlet UISlider *intensity;
@property (weak, nonatomic) IBOutlet UILabel *intensityValueLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *filterMethod;


- (IBAction)showCamera:(id)sender;
- (IBAction)showCameraRoll:(id)sender;
- (IBAction)setEffectIntensity:(id)sender;
- (IBAction)changeMethod:(id)sender;

@end
