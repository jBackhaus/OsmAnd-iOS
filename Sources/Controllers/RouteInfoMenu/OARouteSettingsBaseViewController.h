//
//  OARouteSettingsBaseViewController.h
//  OsmAnd
//
//  Created by Paul on 10/30/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "OsmAndApp.h"

@class OAApplicationMode;
@class OALocalRoutingParameter;
@class OAAppSettings;
@class OARoutingHelper;

@protocol OARouteSettingsBaseViewControllerDelegate <NSObject>

@optional

- (void) reloadUI;

@end

@interface OARouteSettingsBaseViewController : OACompoundViewController

@property (nonatomic, weak) id<OARouteSettingsBaseViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (nonatomic, readonly) OAAppSettings *settings;
@property (nonatomic, readonly) OsmAndAppInstance app;
@property (nonatomic, readonly) OARoutingHelper *routingHelper;

- (void) generateData;
- (void) setCancelButtonAsImage;

- (NSArray<OALocalRoutingParameter *> *) getAvoidRoutingParameters:(OAApplicationMode *) am;
- (NSDictionary *) getRoutingParameters:(OAApplicationMode *) am;
- (NSArray<OALocalRoutingParameter *> *) getRoutingParametersGpx:(OAApplicationMode *) am;

- (void) doneButtonPressed;

@end
