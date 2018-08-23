//
//  UIImageView+URL.h
//  ImageView Cache
//
//  Created by Roman Ganzh on 27.07.2018.
//  Copyright © 2018 ImageView Cache. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (URL)

- (instancetype)initWithUrl:(NSURL *)imageURL;

- (void)loadImageFrom:(NSURL *)imageURL;

@end
