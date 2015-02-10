//
//  QRScannerViewController.h
//  Scanner
//
//  Created by Ben on 15/2/9.
//  Copyright (c) 2015年 X-Team. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^QRResultBlock)(NSString *QRString, UIImage *image);
typedef void (^QRCancelBlock)(void);

@interface QRScannerViewController : UIViewController

@property (nonatomic, copy) QRResultBlock resultBlock;
@property (nonatomic, copy) QRCancelBlock cancelBlock;

+ (QRScannerViewController *)scannerController;

@end
