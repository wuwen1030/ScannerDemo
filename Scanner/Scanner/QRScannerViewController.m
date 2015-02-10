//
//  QRScannerViewController.m
//  Scanner
//
//  Created by Ben on 15/2/9.
//  Copyright (c) 2015年 X-Team. All rights reserved.
//

#import "QRScannerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIView+Positioning.h"

const CGFloat topMargin = 108.0f;
const CGFloat scanWidth = 250.0f;
const CGFloat scanHeight = 250.0f;


@interface QRScannerViewController () <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureMetadataOutput *output;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIButton *toggleTorchButton;
@property (nonatomic, strong) UIImageView *gridView;
@property (nonatomic, strong) UIImageView *scannerBar;
@property (nonatomic, strong) dispatch_queue_t imageProcessingQueue;
@property (nonatomic, strong) UIImage *videoImage;

@end

@implementation QRScannerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

    if(status == AVAuthorizationStatusAuthorized)
    {
        [self setupUI];
        [self setupScanner];
        [self startScanning];
    }
    else if (status == AVAuthorizationStatusDenied)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                            message:@"请在设置中打开应用的相机使用权限"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    else if (status == AVAuthorizationStatusNotDetermined)
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
         {
            if(granted)
            {
                [self setupUI];
                [self setupScanner];
                [self startScanning];
            }
            else
            {
                
            }
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.preview.frame = self.view.bounds;
    
    self.output.rectOfInterest = CGRectMake(topMargin/self.view.height, ((self.view.width-scanWidth)/2)/self.view.width, scanWidth/self.view.height, scanWidth/self.view.width);
    
    [self maskBackgroundView];
}

- (void)maskBackgroundView
{
    if (self.backgroundView.layer.mask)
    {
        return;
    }
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = self.backgroundView.bounds;
    
    CAShapeLayer *top = [CAShapeLayer layer];
    top.frame = CGRectMake(0, 0, self.backgroundView.width, topMargin);
    top.fillColor = [UIColor grayColor].CGColor;
    top.path = [UIBezierPath bezierPathWithRect:top.bounds].CGPath;
    [layer addSublayer:top];
    
    CAShapeLayer *left = [CAShapeLayer layer];
    left.frame = CGRectMake(0, 108.0f, (self.backgroundView.width-scanWidth)/2, scanHeight);
    left.fillColor = [UIColor grayColor].CGColor;
    left.path = [UIBezierPath bezierPathWithRect:left.bounds].CGPath;
    [layer addSublayer:left];
    
    CAShapeLayer *right = [CAShapeLayer layer];
    right.frame = CGRectMake(self.backgroundView.width - (self.backgroundView.width-scanWidth)/2,
                             108.0f, (self.backgroundView.width-scanWidth)/2, scanHeight);
    right.fillColor = [UIColor grayColor].CGColor;
    right.path = [UIBezierPath bezierPathWithRect:right.bounds].CGPath;
    [layer addSublayer:right];
    
    CAShapeLayer *bottom = [CAShapeLayer layer];
    bottom.frame = CGRectMake(0, 358.0f, self.backgroundView.width, self.backgroundView.height - scanHeight - topMargin);
    bottom.fillColor = [UIColor grayColor].CGColor;
    bottom.path = [UIBezierPath bezierPathWithRect:bottom.bounds].CGPath;
    [layer addSublayer:bottom];
    
    self.backgroundView.layer.mask = layer;
}

#pragma mark - Init scanner

- (void)setupScanner
{
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    self.output = [[AVCaptureMetadataOutput alloc] init];
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    self.session = [[AVCaptureSession alloc] init];
    [self.session addInput:self.input];
    // Have to add the output before setting metadata types
    [self.session addOutput:self.output];
    [self.session addOutput:output];
    [self.session setSessionPreset:AVCaptureSessionPresetMedium];
    
    self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    output.alwaysDiscardsLateVideoFrames = YES;
    self.imageProcessingQueue = dispatch_queue_create("com.xt.scanner.imageprocessing", NULL);
    [output setSampleBufferDelegate:self queue:self.imageProcessingQueue];
    [output setVideoSettings:@{(__bridge id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)}];
    
    self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame = self.view.bounds;
    
    [self.view.layer insertSublayer:self.preview atIndex:0];
}

- (void)setupUI
{
//    self.gridView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, scanWidth, scanHeight)];
//    self.gridView.image = [UIImage imageNamed:@"common_scanner_grid"];
//    self.gridView.autoresizingMask = UIViewAutoresizingNone;
//    self.gridView.contentMode = UIViewContentModeTop;
//    self.gridView.clipsToBounds = YES;
//    self.gridView.layer.anchorPoint = CGPointMake(0.5, 0.0);
//    self.gridView.layer.position = CGPointMake(self.view.width/2.0f, topMargin);
//    [self.view addSubview:self.gridView];
//    
//    self.scannerBar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"common_scanner_bar"]];
//    self.scannerBar.bottom = 0;
//    [self.gridView addSubview:self.scannerBar];
//    

//    if (![self.device hasTorch])
//    {
//        self.toggleTorchButton.enabled = NO;
//    }
//    else
//    {
        AVCaptureTorchMode torchMode = [self.device torchMode];
        self.toggleTorchButton.selected = (torchMode == AVCaptureTorchModeOn);
//    }
}

#pragma mark - Scanner control

- (void)startScanning
{
    [self.session startRunning];
}

- (void)stopScanning
{
    [self.session stopRunning];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    [self stopScanning];
    
    AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects firstObject];
    if (metadataObject)
    {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        if (self.resultBlock)
        {
            self.resultBlock(metadataObject.stringValue, self.videoImage);
        }
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool
    {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        /*Get information about the image*/
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        /*Create a CGImageRef from the CVImageBufferRef*/
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        
        /*We release some components*/
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        self.videoImage = [[UIImage alloc] initWithCGImage:newImage];
        
        CGImageRelease(newImage);
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    }
}

#pragma mark - UI events

- (IBAction)toggleTorchButtonPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    button.selected = !button.selected;
    
    [self.device lockForConfiguration:nil];
    if (button.selected)
    {
        [self.device setTorchMode:AVCaptureTorchModeOn];
    }
    else
    {
        [self.device setTorchMode:AVCaptureTorchModeOff];
    }
    
    [self.device unlockForConfiguration];

}

- (IBAction)closeButtonPressed:(id)sender
{
    if (self.cancelBlock)
    {
        self.cancelBlock();
    }
}

#pragma mark - Factory

+ (QRScannerViewController *)scannerController
{
    QRScannerViewController *controller = [[self alloc] initWithNibName:NSStringFromClass([self class])
                                                                 bundle:nil];
    return controller;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


@end
