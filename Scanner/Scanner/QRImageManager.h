//
//  QRImageManager.h
//  Scanner
//
//  Created by Ben on 15/2/9.
//  Copyright (c) 2015年 X-Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const QRImageDidSavedNotification;
FOUNDATION_EXPORT NSString *const QRImageNotificationImageKey;

@class QRImage;

@interface QRImageManager : NSObject

+ (QRImageManager *)sharedInstance;

- (QRImage *)saveImage:(UIImage *)image withId:(NSString *)imageId;

- (NSArray *)allImages;

- (UIImage *)imageWithImageId:(NSString *)imageId;

@end
