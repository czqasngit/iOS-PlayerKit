//
//  LabradorViewController.h
//  Labrador
//
//  Created by czqasngit on 08/27/2018.
//  Copyright (c) 2018 czqasngit. All rights reserved.
//

@import UIKit;

@interface LabradorViewController : UIViewController

@property (nonatomic, strong)IBOutlet UISlider *slider ;

- (IBAction)play:(id)sender ;
- (IBAction)pause:(id)sender ;
- (IBAction)resume:(id)sender ;
- (IBAction)sliderValueChanged:(UISlider *)slider ;
- (IBAction)stop:(id)sender;

@end
