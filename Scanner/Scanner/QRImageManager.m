//
//  QRImageManager.m
//  Scanner
//
//  Created by Ben on 15/2/9.
//  Copyright (c) 2015年 X-Team. All rights reserved.
//

#import "QRImageManager.h"
#import "QRImage.h"

NSString *DocPath()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths firstObject];
}

NSString *const QRImageDidSavedNotification = @"QRImageDidSavedNotification";
NSString *const QRImageNotificationImageKey = @"QRImageNotificationImageKey";

@interface QRImageManager ()

@property (nonatomic, strong) dispatch_queue_t fileProcessingQueue;
@property (nonatomic, copy) NSString *imageFolderPath;
@property (nonatomic, strong) NSMutableDictionary *imageCache;

@end

@implementation QRImageManager

static QRImageManager *_sharedInstance= nil;

+ (QRImageManager *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[super allocWithZone:NULL] init];
    });
    return _sharedInstance;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [self sharedInstance];
}

+ (id)copyWithZone:(struct _NSZone *)zone
{
    return [self sharedInstance];
}

- (instancetype)init
{
    if (self = [super init])
    {
        _fileProcessingQueue = dispatch_queue_create("com.scanner.qrimage.fileprocessing", NULL);
        _imageCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)imageFolderPath
{
    if (!_imageFolderPath)
    {
        _imageFolderPath = [DocPath() stringByAppendingPathComponent:@"QRImage"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_imageFolderPath isDirectory:nil])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:_imageFolderPath
                                      withIntermediateDirectories:NO
                                                       attributes:nil
                                                            error:nil];
        }
    }
    return _imageFolderPath;
}

- (QRImage *)saveImage:(UIImage *)image withId:(NSString *)imageId
{
    NSString *filePath = [self.imageFolderPath stringByAppendingPathComponent:imageId];
    QRImage *qrImage = [[QRImage alloc] init];
    qrImage.imageId = imageId;
    qrImage.path = filePath;
    dispatch_sync(self.fileProcessingQueue, ^{
        NSData *imageData = UIImagePNGRepresentation(image);
        [imageData writeToFile:filePath atomically:YES];
        
    });
    self.imageCache[imageId] = image;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:QRImageDidSavedNotification
                                                            object:nil
                                                          userInfo:@{QRImageNotificationImageKey:qrImage}];
    });
    return qrImage;
}

- (NSArray *)allImages
{
    NSArray *allFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.imageFolderPath
                                                                            error:nil];
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (NSString *path in allFiles)
    {
        QRImage *image = [[QRImage alloc] init];
        image.path = path;
        image.imageId = path.lastPathComponent;
        [array addObject:image];
    }
    return array;
}

- (UIImage *)imageWithImageId:(NSString *)imageId
{
    UIImage *image = self.imageCache[imageId];
    if (image != nil)
    {
        return image;
    }
    
    image = [[UIImage alloc] initWithContentsOfFile:[self.imageFolderPath stringByAppendingPathComponent:imageId]];
    
    [self.imageCache setValue:image forKey:imageId];
    
    return image;
}

@end
