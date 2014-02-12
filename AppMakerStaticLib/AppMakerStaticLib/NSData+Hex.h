//
//  NSData+Hex.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 14/01/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Hex)

- (NSString *)hexRepresentationWithSpaces:(BOOL)spaces capitals:(BOOL)capitals;

@end
