//
//  UIImageView+URL.m
//  ImageView Cache
//
//  Created by Roman Ganzh on 27.07.2018.
//  Copyright © 2018 ImageView Cache. All rights reserved.
//

#import "UIImageView+URL.h"
#import <Foundation/NSURLResponse.h>


#import "UIImageView+URL.h"
#import <Foundation/NSURLResponse.h>

@implementation UIImage (Additions)

- (UIImage *)imageWithTint:(UIColor *)tintColor {
    CGRect aRect = CGRectMake(0.f, 0.f, self.size.width, self.size.height);
    CGImageRef alphaMask;
    {
        UIGraphicsBeginImageContext(aRect.size);
        CGContextRef c = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(c, 0, aRect.size.height);
        CGContextScaleCTM(c, 1.0, -1.0);
        [self drawInRect: aRect];
        alphaMask = CGBitmapContextCreateImage(c);
        UIGraphicsEndImageContext();
    }
    UIGraphicsBeginImageContext(aRect.size);
    CGContextRef c = UIGraphicsGetCurrentContext();
    [self drawInRect:aRect];
    CGContextClipToMask(c, aRect, alphaMask);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextSetFillColorSpace(c, colorSpace);
    CGContextSetFillColorWithColor(c, tintColor.CGColor);
    UIRectFillUsingBlendMode(aRect, kCGBlendModeNormal);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(alphaMask);
    return img;
}

@end

@interface CacheManager: NSObject

+ (CacheManager *)shared;

@property (nonatomic, strong) NSCache *cache;
@property (nonatomic, assign, getter=isNeedToClear) BOOL automaticallyСlearСache;

@end

@implementation CacheManager

+ (CacheManager *)shared {
    static CacheManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (NSCache *)cache {
    if (_cache == nil) {
        _cache = [[NSCache alloc] init];
    }
    return  _cache;
}

- (void)dealloc {
    if (self.isNeedToClear) {
        [self.cache removeAllObjects];
    }
}

@end

@implementation UIImageView (URL)

- (instancetype)initWithUrl:(NSURL *)imageURL {
    self = [[UIImageView alloc] init];
    [self loadImageFrom:imageURL];
    return self;
}

- (void)loadImageFrom:(NSURL *)imageURL {
    NSOperationQueue *queue = [NSOperationQueue new];

    NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                        initWithTarget:self
                                        selector:@selector(requestRemoteImage:)
                                        object:imageURL];
    [queue addOperation:operation];

}

- (void)requestRemoteImage:(NSURL *)imageURL {
    __weak __typeof(self) weakSelf = self;
    UIImage *cachedImage = [CacheManager.shared.cache objectForKey:imageURL];
    if (cachedImage != nil) {
        [self performSelectorOnMainThread:@selector(placeImageInUI:) withObject:cachedImage waitUntilDone:YES];
    } else {
        [self downloadImageFromURL:imageURL completion:^(UIImage * _Nullable image) {
            UIImage *whiteIcon = [image imageWithTint:UIColor.whiteColor];

            [CacheManager.shared.cache setObject:whiteIcon forKey:imageURL];
            [weakSelf performSelectorOnMainThread:@selector(placeImageInUI:) withObject:whiteIcon waitUntilDone:YES];
        }];
    }
}

- (void)placeImageInUI:(UIImage *)image {
    [self setImage:image];
}

- (void)getDataFromUrl:(NSURL *)url completion:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completion {
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:completion] resume];
}

- (void)downloadImageFromURL:(NSURL *)imageURL completion:(void (^)(UIImage * _Nullable image))completion {
    [self getDataFromUrl:imageURL completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data != nil && error == nil) {
            UIImage *image = [UIImage imageWithData:data];
            if (image != nil) {
                if(completion) {
                    completion(image);
                }
            }
        }
    }];
}

@end
