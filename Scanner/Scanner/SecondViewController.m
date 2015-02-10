//
//  SecondViewController.m
//  Scanner
//
//  Created by Ben on 15/2/9.
//  Copyright (c) 2015年 X-Team. All rights reserved.
//

#import "SecondViewController.h"
#import "QRImageManager.h"
#import "QRImage.h"

@interface QRImageCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation QRImageCell

- (void)awakeFromNib
{
    self.imageView.transform = CGAffineTransformMakeRotation(M_PI/2);
}

@end

@interface SecondViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *allImages;

@end

@implementation SecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.allImages = [[QRImageManager sharedInstance] allImages];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(qrImageChanged:)
                                                 name:QRImageDidSavedNotification
                                               object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)qrImageChanged:(NSNotification *)notification
{
    self.allImages = [[QRImageManager sharedInstance] allImages];
    [self.collectionView reloadData];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.allImages.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    QRImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell"
                                                                  forIndexPath:indexPath];
    
    QRImage *qrImage = self.allImages[indexPath.item];
    
    cell.titleLabel.text = qrImage.imageId;
    cell.imageView.image = [[QRImageManager sharedInstance] imageWithImageId:qrImage.imageId];
    return cell;
}

@end
