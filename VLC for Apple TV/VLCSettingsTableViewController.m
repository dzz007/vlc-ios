/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSettingsTableViewController.h"
#import "IASKSettingsReader.h"
#import "IASKSpecifier.h"

#define SettingsReUseIdentifier @"SettingsReUseIdentifier"
#define SettingsHeaderReUseIdentifier @"SettingsHeaderReUseIdentifier"

@interface VLCSettingsTableViewController ()
{
    NSUserDefaults *_userDefaults;
    IASKSettingsReader *_settingsReader;
}
@end

@implementation VLCSettingsTableViewController

- (void)loadView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:SettingsReUseIdentifier];
    [tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:SettingsHeaderReUseIdentifier];
    self.view = tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    _settingsReader = [[IASKSettingsReader alloc] init];
}

- (NSString *)title
{
    return NSLocalizedString(@"Settings", nil);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _settingsReader.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_settingsReader numberOfRowsForSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SettingsReUseIdentifier forIndexPath:indexPath];

    IASKSpecifier *specifier = [_settingsReader specifierForIndexPath:indexPath];
    cell.textLabel.text = [specifier title];
 	cell.detailTextLabel.text = [specifier subtitle];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_settingsReader titleForSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    IASKSpecifier *specifier = [_settingsReader specifierForIndexPath:indexPath];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:specifier.title
                                                                             message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSString *specifierType = specifier.type;
    if ([specifierType isEqualToString:kIASKPSMultiValueSpecifier]) {
        NSUInteger count = [specifier multipleValuesCount];
        NSArray *titles = [specifier multipleTitles];
        NSUInteger indexOfPreferredAction = [[specifier multipleValues] indexOfObject:[_userDefaults objectForKey:[specifier key]]]; // FIXME: lookup correct value
        for (NSUInteger i = 0; i < count; i++) {
            id value = [[specifier multipleValues][i] copy];
            UIAlertAction *action = [UIAlertAction actionWithTitle:[_settingsReader titleForStringId:titles[i]]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  [_userDefaults setObject:value forKey:[specifier key]];
                                                                  [_userDefaults synchronize];
                                                                  [self.tableView reloadData];
                                                              }];
            [alertController addAction:action];
            if (i == indexOfPreferredAction)
                [alertController setPreferredAction:action];
        }
    } else if ([specifierType isEqualToString:kIASKPSToggleSwitchSpecifier]) {
        UIAlertAction *onAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"On", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [_userDefaults setBool:YES forKey:[specifier key]];
                                                              [_userDefaults synchronize];
                                                              [self.tableView reloadData];
                                                          }];
        UIAlertAction *offAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Off", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [_userDefaults setBool:NO forKey:[specifier key]];
                                                              [_userDefaults synchronize];
                                                              [self.tableView reloadData];
                                                          }];
        [alertController addAction:onAction];
        [alertController addAction:offAction];
        [alertController setPreferredAction:[_userDefaults boolForKey:[specifier key]] ? onAction : offAction];
    }

    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

@end