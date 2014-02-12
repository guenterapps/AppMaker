//
//  UITextView+Utilities.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 01/01/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import "UITextView+Utilities.h"

@implementation UITextView (Utilities)

- (CGFloat)heightForTextView;
{
	CGFloat height;
	
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
	{
		UITextView *tempTextView = [[UITextView alloc] initWithFrame:self.bounds];
		tempTextView.text = self.text;
		tempTextView.font = self.font;
		tempTextView.textContainerInset = self.textContainerInset;
		
		[tempTextView.layoutManager ensureLayoutForTextContainer:tempTextView.textContainer];
		[tempTextView layoutIfNeeded];
		CGRect textBounds = [tempTextView.layoutManager usedRectForTextContainer:tempTextView.textContainer];
		height = (CGFloat)ceil(textBounds.size.height + tempTextView.textContainerInset.top + tempTextView.textContainerInset.bottom);
		
	//	NSLog(@"%@ %@", self, self.font);
	}
	else
	{
		height = self.contentSize.height;
	}

	return height;
}

@end
