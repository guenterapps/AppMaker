//
//  CLACreditsViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 29/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLACreditsViewController.h"
#import "CLADescriptionDetailCell.h"
#import "UIColor-Expanded.h"
#import "UITextView+Utilities.h"

static NSString *const cellIdentifier		= @"CLADescriptionDetailCell";
static NSString *const CLATitleKey			= @"CLATitleKey";
static NSString *const CLADescriptionKey	= @"CLADescriptionKey";

@interface CLACreditsViewController ()

@property (nonatomic) NSArray	*textData;
@property (nonatomic) NSMutableArray *cellHeights;

-(void)setupTableViewCells;

@end

@implementation CLACreditsViewController

-(UITableView *)tableView
{
	return (UITableView *)self.view;
}

-(void)loadView
{
	self.view = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor clearColor];
	
	[self setupTitleView];

	[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	
	[self setupTableView:self.tableView withCellIdentifier:cellIdentifier];
	
	[(UILabel *)self.navigationItem.titleView setText:@"Credits"];
	
	self.textData		= [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"credits" ofType:@"plist"]];
	
	NSAssert(self.textData, @"Should load the credits file!");

	self.cellHeights	= [NSMutableArray array];
	
	[self setupTableViewCells];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CLADescriptionDetailCell *cell = (CLADescriptionDetailCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	CGFloat fontInterline		= [[self.store userInterface][CLAAppDataStoreUIBoxFontInterlineKey] floatValue];
	
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	[paragraphStyle setLineSpacing:fontInterline];
	
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.textData[indexPath.row][CLADescriptionKey]];
	
	[attributedString addAttribute:NSParagraphStyleAttributeName
							 value:paragraphStyle
							 range:NSMakeRange(0, attributedString.length)];
	
	cell.detailTextView.attributedText	= attributedString;
	
	cell.frame = CGRectMake(0.0, 0.0, cell.frame.size.width, 300.0);
	
	UIColor *backgroundColor	= [self.store userInterface][CLAAppDataStoreUIBoxDescriptionColorKey];
	CGFloat fontSize			= [[self.store userInterface][CLAAppDataStoreUIBoxFontSizeKey] floatValue];
	
	cell.detailTextView.backgroundColor = backgroundColor;
	cell.detailTextView.font			= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIBoxDescriptionFontKey] size:fontSize];
	cell.detailTextView.textColor		= [self.store userInterface][CLAAppDataStoreUIBoxDescriptionFontColorKey];

	cell.titleTextView.backgroundColor	= [self.store userInterface][CLAAppDataStoreUIBoxTitleColorKey];
	
	NSUInteger shadowMask = (NSUInteger)[[self.store userInterface][CLAAppDataStoreUICellShadowBitMaskKey] integerValue];
	
	if (shadowMask & CLACellShadowMaskDescriptionCell)
		[cell setShadowColor:(UIColor *)[self.store userInterface][CLAAppDataStoreUICellShadowColorKey]];
	
	UIFont *font			= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIFontNameKey] size:fontSize];
	
	attributedString = [[NSMutableAttributedString alloc] initWithString:self.textData[indexPath.row][CLATitleKey]];
		
	[attributedString addAttribute:NSForegroundColorAttributeName
							 value:[self.store userInterface][CLAAppDataStoreUIBoxTitleFontColorKey]
							 range:NSMakeRange(0, [attributedString length])];
	
	[attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [attributedString length])];
	
	[attributedString addAttribute:NSParagraphStyleAttributeName
							 value:paragraphStyle
							 range:NSMakeRange(0, attributedString.length)];
	
	if (indexPath.row == 1)
	{
		UIColor *redColor = [UIColor colorWithRed:1.0 green:(66./255.) blue:0. alpha:1.];
		[attributedString addAttribute:NSForegroundColorAttributeName value:redColor range:NSMakeRange(14, 1)];
	}
		
	cell.titleTextView.attributedText = attributedString;
	
	
	return cell;
}

#pragma mark - UITableViewDelegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [self.cellHeights[indexPath.row] floatValue];
}


#pragma mark - Private Methods

-(void)setupTableViewCells
{
	UINib *nib					= [UINib nibWithNibName:cellIdentifier bundle:nil];
	UITableView *cell			= [nib instantiateWithOwner:nil options:nil][0];
	
	CGFloat cellHeightFromNib	= CGRectGetHeight(cell.frame);

	CLADescriptionDetailCell *descCell = (CLADescriptionDetailCell *)cell;
		
	CGFloat textViewHeight			= CGRectGetHeight(descCell.detailTextView.frame);
	CGFloat margin					= (cellHeightFromNib - textViewHeight - descCell.titleTextView.contentSize.height) / 2.0;
	
	CGFloat fontSize				= [[self.store userInterface][CLAAppDataStoreUIBoxFontSizeKey] floatValue];
	CGFloat fontInterline		= [[self.store userInterface][CLAAppDataStoreUIBoxFontInterlineKey] floatValue];
	
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	[paragraphStyle setLineSpacing:fontInterline];
		
	for (int i = 0; i < 2; ++i)
	{
		NSMutableAttributedString *textString = [[NSMutableAttributedString alloc] initWithString:self.textData[i][CLADescriptionKey]];
	
		[textString addAttribute:NSParagraphStyleAttributeName
						   value:paragraphStyle
						   range:NSMakeRange(0, textString.length)];
		
		descCell.detailTextView.attributedText = textString;
		descCell.detailTextView.font	= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIBoxDescriptionFontKey] size:fontSize];
	
		
		textString = [[NSMutableAttributedString alloc] initWithString:self.textData[i][CLATitleKey]];
		
		[textString addAttribute:NSParagraphStyleAttributeName
						   value:paragraphStyle
						   range:NSMakeRange(0, textString.length)];
		
		descCell.titleTextView.attributedText = textString;
		descCell.titleTextView.font		= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIFontNameKey] size:fontSize];

		
		cellHeightFromNib = 2 * margin + [descCell.detailTextView heightForTextView] + [descCell.titleTextView heightForTextView];
		
		[self.cellHeights addObject:@(cellHeightFromNib)];
	}

}


@end
