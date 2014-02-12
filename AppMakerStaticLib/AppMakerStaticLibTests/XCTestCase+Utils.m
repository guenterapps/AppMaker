//
//  XCTestCase+Utils.m
//  newsgroups
//
//  Created by Christian Lao on 23/09/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "XCTestCase+Utils.h"
#import <objc/runtime.h>

@implementation XCTestCase (Utils)

-(void)exchangeImplementationForClass:(Class)class sel1:(SEL)sel1 sel2:(SEL)sel2;
{
	Method m1 = class_getInstanceMethod(class, sel1);
	Method m2 = class_getInstanceMethod(class, sel2);
	
	method_exchangeImplementations(m1, m2);
}

-(void)exchangeClassImplementationForClass:(Class)class sel1:(SEL)sel1 sel2:(SEL)sel2
{
	Method m1 = class_getClassMethod(class, sel1);
	Method m2 = class_getClassMethod(class, sel2);
	
	method_exchangeImplementations(m1, m2);
}

-(void)evaluateCalledKey:(const char *)key onObject:(id)object
{
	NSNumber *called = objc_getAssociatedObject(object, key);
	
	XCTAssertTrue([called boolValue], "method for key %s not called!", key);
}

-(void)evaluateNotCalledKey:(const char *)key onObject:(id)object
{
	NSNumber *called = objc_getAssociatedObject(object, key);
	
	XCTAssertFalse([called boolValue], "method for key %s not called!", key);
}

@end
