//
//  XCTestCase+Utils.h
//  newsgroups
//
//  Created by Christian Lao on 23/09/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface XCTestCase (Utils)

-(void)exchangeImplementationForClass:(Class)class sel1:(SEL)sel1 sel2:(SEL)sel2;
-(void)exchangeClassImplementationForClass:(Class)class sel1:(SEL)sel1 sel2:(SEL)sel2;

-(void)evaluateCalledKey:(const char *)key onObject:(id)object;
-(void)evaluateNotCalledKey:(const char *)key onObject:(id)object;

@end
