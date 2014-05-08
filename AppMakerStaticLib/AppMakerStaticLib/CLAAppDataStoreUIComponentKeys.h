//
//  CLAAppDataStoreUIComponentKeys.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 21/02/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#ifndef AppMakerStaticLib_CLAAppDataStoreUIComponentKeys_h
#define AppMakerStaticLib_CLAAppDataStoreUIComponentKeys_h

#import <Foundation/Foundation.h>

typedef enum
{
	CLACellShadowMaskMainCell			= 1,
	CLACellShadowMaskHeaderCell			= 1 << 1,
	CLACellShadowMaskActionsCell		= 1 << 2,
	CLACellShadowMaskAddressCell		= 1 << 3,
	CLACellShadowMaskDescriptionCell	= 1 << 4
	
} CLACellShadowMask;

extern NSString *const CLAAppDataStoreUIDirectionsColorKey;
extern NSString *const CLAAppDataStoreUIDirectionsTextColorKey;
extern NSString *const CLAAppDataStoreUIDirectionsPolylineColorKey;

extern NSString *const CLAAppDataStoreUIBackgroundColorKey;
extern NSString *const CLAAppDataStoreUIForegroundColorKey;
extern NSString *const CLAAppDataStoreUISplashTintColorKey;
extern NSString *const CLAAppDataStoreUIStatusBarStyleKey;

extern NSString *const CLAAppDataStoreUICellShadowColorKey;
extern NSString *const CLAAppDataStoreUICellShadowBitMaskKey;

extern NSString *const CLAAppDataStoreUIFontNameKey;
extern NSString *const CLAAppDataStoreUIFontColorKey;

extern NSString *const CLAAppDataStoreUIBoxFontInterlineKey;
extern NSString *const CLAAppDataStoreUIBoxDescriptionColorKey;
extern NSString *const CLAAppDataStoreUIBoxTitleColorKey;

extern NSString *const CLAAppDataStoreUIBoxDescriptionFontColorKey;
extern NSString *const CLAAppDataStoreUIBoxTitleFontColorKey;

extern NSString *const CLAAppDataStoreUIBoxDescriptionFontKey;
extern NSString *const CLAAppDataStoreUIBoxDescriptionFontSizeKey;
extern NSString *const CLAAppDataStoreUIBoxTitleFontSizeKey;

extern NSString *const CLAAppDataStoreUIHeaderColorKey;
extern NSString *const CLAAppDataStoreUIHeaderFontColorKey;
extern NSString *const CLAAppDataStoreUIHeaderFontSizeKey;

extern NSString *const CLAAppDataStoreUIActionCellColorKey;
extern NSString *const CLAAppDataStoreUIActionCellTintColorKey;
extern NSString *const CLAAppDataStoreUIActionFontSizeKey;

extern NSString *const CLAAppDataStoreUIMenuFontColorKey;
extern NSString *const CLAAppDataStoreUIMenuFontSizeKey;
extern NSString *const CLAAppDataStoreUIMenuBackgroundColorKey;
extern NSString *const CLAAppDataStoreUIMenuSelectedColorKey;

extern NSString *const CLAAppDataStoreUIMapIconKey;
extern NSString *const CLAAppDataStoreUIMenuIconKey;

extern NSString *const CLAAppDataStoreUIMainListFontColorKey;
extern NSString *const CLAAppDataStoreUIMainListFontSizeKey;
extern NSString *const CLAAppDataStoreUIBackIconKey;
extern NSString *const CLAAppDataStoreUIListIconKey;
extern NSString *const CLAAppDataStoreUIShareIconKey;

extern NSString *const CLAAppDataStoreUIShowSearchBar;
extern NSString *const CLAAppDataStoreUIShowHomeCategory;

#endif
