//
//  FirstViewController.m
//  Scanner
//
//  Created by Ben on 15/2/9.
//  Copyright (c) 2015年 X-Team. All rights reserved.
//

#import "FirstViewController.h"
#import "QRScannerViewController.h"
#import "QRImageManager.h"
#import "NSString+Useful.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)scanButtonPressed:(id)sender
{
    QRScannerViewController *controller = [QRScannerViewController scannerController];
    controller.cancelBlock = ^{
        [self dismissViewControllerAnimated:YES completion:NULL];
    };
    controller.resultBlock = ^(NSString *stringValue, UIImage *image){
        [[QRImageManager sharedInstance] saveImage:image withId:[stringValue md5String]];
    };
    [self presentViewController:controller animated:YES completion:NULL];
}

@end
