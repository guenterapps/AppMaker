//
//  MockedImage.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 14/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLAModelProtocols.h"

@interface MockedImage : NSObject <CLAImage>

@property (nonatomic, strong) NSNumber *primary;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, strong) NSString *videoURL;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) id <CLAItem> item;

@end
