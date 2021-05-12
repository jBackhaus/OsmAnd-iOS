//
//  OASelectTrackFolderViewController.m
//  OsmAnd
//
//  Created by nnngrach on 05.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASelectTrackFolderViewController.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OASettingsTableViewCell.h"
#import "OATitleRightIconCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OAAddTrackFolderViewController.h"
#import "OsmAndApp.h"
#import "OALoadGpxTask.h"
#import "OATableViewCustomHeaderView.h"

#define kCellTypeAction @"OATitleRightIconCell"
#define kHeaderId @"TableViewSectionHeader"
#define kAddNewFolderSection 0
#define kFoldersListSection 1

@interface OASelectTrackFolderViewController() <UITableViewDelegate, UITableViewDataSource, OAAddTrackFolderDelegate>

@end

@implementation OASelectTrackFolderViewController
{
    OAGPX *_gpx;
    NSString *_selectedFolderName;
    NSArray<NSArray<NSDictionary *> *> *_data;
}

- (instancetype) initWithGPX:(OAGPX *)gpx
{
    self = [super initWithNibName:@"OABaseTableViewController" bundle:nil];
    if (self)
    {
        _selectedFolderName = [[gpx.gpxFilePath  stringByDeletingLastPathComponent] lastPathComponent];
        if ([_selectedFolderName isEqualToString:@""])
            _selectedFolderName = OALocalizedString(@"tracks");
        [self reloadData];
    }
    return self;
}

- (instancetype) initWithSelectedFolderName:(NSString *)selectedFolderName;
{
    self = [super initWithNibName:@"OABaseTableViewController" bundle:nil];
    if (self)
    {
        _selectedFolderName = selectedFolderName;
        [self reloadData];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:kHeaderId];
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"plan_route_select_folder");
}

- (void) generateData:(NSMutableArray<NSString *> *)allFolderNames foldersData:(NSMutableDictionary *)foldersData
{
    NSMutableArray *data = [NSMutableArray new];
    [data addObject:@[
        @{
            @"type" : kCellTypeAction,
            @"title" : OALocalizedString(@"add_folder"),
            @"img" : @"ic_custom_add",
        },
    ]];
    
    NSMutableArray *cellFoldersData = [NSMutableArray new];
    for (NSString *folderName in allFolderNames)
    {
        NSArray *folderItems = foldersData[folderName];
        int tracksCount = folderItems ? folderItems.count : 0;
        [cellFoldersData addObject:@{
            @"type" : [OAMultiIconTextDescCell getCellIdentifier],
            @"header" : OALocalizedString(@"plan_route_folder"),
            @"title" : folderName,
            @"description" : [NSString stringWithFormat:@"%i", tracksCount],
            @"isSelected" : [NSNumber numberWithBool:[folderName isEqualToString: _selectedFolderName]],
            @"img" : @"ic_custom_folder"
        }];
    }
    
    [data addObject: [NSArray arrayWithArray:cellFoldersData]];
    _data = data;
}

- (void) reloadData
{
    NSArray<NSString *> *allFoldersNames = [OAUtilities getGpxFoldersListSorted:YES shouldAddTracksFolder:YES];
        
    OALoadGpxTask *task = [[OALoadGpxTask alloc] init];
    [task execute:^(NSDictionary<NSString *, NSArray<OAGpxInfo *> *>* gpxFolders) {
        [self generateData:allFoldersNames foldersData:gpxFolders];
        [self.tableView reloadData];
    }];
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    
    if ([cellType isEqualToString:kCellTypeAction])
    {
        static NSString* const identifierCell = kCellTypeAction;
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kCellTypeAction owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        return cell;
    }
   
    else if ([cellType isEqualToString:[OAMultiIconTextDescCell getCellIdentifier]])
    {
        OAMultiIconTextDescCell* cell = (OAMultiIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:[OAMultiIconTextDescCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textView.numberOfLines = 3;
            cell.textView.lineBreakMode = NSLineBreakByTruncatingTail;
        }
        if (cell)
        {
            [cell.textView setText:item[@"title"]];
            [cell.descView setText:item[@"description"]];
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
            cell.separatorInset = UIEdgeInsetsMake(0, cell.textView.frame.origin.x, 0, 0);
            
            if ([item[@"isSelected"] boolValue])
            {
                [cell setOverflowVisibility:NO];
                [cell.overflowButton setImage:[[UIImage imageNamed:@"ic_checmark_default"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            }
            else
            {
                [cell setOverflowVisibility:YES];
            }
            
            [cell updateConstraintsIfNeeded];
        }
        return cell;
    }
    
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *item = _data[section].firstObject;
    return item[@"header"] ? item[@"header"] : @" ";
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderId];
    vw.label.text = [title upperCase];
    vw.label.textColor = UIColorFromRGB(color_text_footer);
    return vw;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kAddNewFolderSection)
    {
        OAAddTrackFolderViewController * addFolderVC = [[OAAddTrackFolderViewController alloc] init];
        addFolderVC.delegate = self;
        [self presentViewController:addFolderVC animated:YES completion:nil];
        
    }
    else if (indexPath.section == kFoldersListSection)
    {
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        if (![item[@"isSelected"] boolValue] && _delegate)
            [_delegate onFolderSelected:item[@"title"]];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        NSString *cellType = item[@"type"];
        if ([cellType isEqualToString:[OAMultiIconTextDescCell getCellIdentifier]])
            return 60;
        else
            return UITableViewAutomaticDimension;
}

#pragma mark - OAAddTrackFolderDelegate

- (void) onTrackFolderAdded:(NSString *)folderName
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:^{
            [_delegate onFolderAdded:folderName];
        }];
    });
}

@end
