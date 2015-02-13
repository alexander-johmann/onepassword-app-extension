//
//  SignInViewController.m
//  1Password Extension Demo
//
//  Created by Rad on 2014-07-14.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "LoginViewController.h"
#import "OnePasswordExtension.h"
#import "LoginInformation.h"

@interface LoginViewController () <UITextFieldDelegate, UIActivityItemSource>

@property (weak, nonatomic) IBOutlet UIButton *onepasswordSigninButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (nonatomic) NSExtensionItem *onePasswordExtensionItem;

@end

@implementation LoginViewController

- (void)viewDidLoad {
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
	[self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"login-background.png"]]];
	[self.onepasswordSigninButton setHidden:![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
	return UIStatusBarStyleLightContent;
}

#pragma mark - Actions

- (IBAction)findLoginFrom1Password:(id)sender {
	OnePasswordExtension *onePasswordExtension = [OnePasswordExtension sharedExtension];

	// Create the 1Password extension item.
	self.onePasswordExtensionItem = [onePasswordExtension createExtensionItemToFindLoginForURLString:@"https://www.acme.com"];

	NSArray *activityItems = @[ self ]; // Add as many activity items as you please

	// Setting up the activity view controller
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems  applicationActivities:nil];

	if ([sender isKindOfClass:[UIBarButtonItem class]]) {
		self.popoverPresentationController.barButtonItem = sender;
	}
	else if ([sender isKindOfClass:[UIView class]]) {
		self.popoverPresentationController.sourceView = [sender superview];
		self.popoverPresentationController.sourceRect = [sender frame];
	}

	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError)
	{
		// Executed when the 1Password Extension is called
		if ([onePasswordExtension isOnePasswordExtensionActivityType:activityType]) {
			if (returnedItems.count > 0) {
				__weak typeof (self) miniMe = self;
				[onePasswordExtension processReturnedItems:returnedItems completion:^(NSDictionary *loginDict, NSError *error) {
					if (!loginDict) {
						if (error.code != AppExtensionErrorCodeCancelledByUser) {
							NSLog(@"Error invoking 1Password App Extension for find login: %@", error);
						}
						return;
					}

					__strong typeof(self) strongMe = miniMe;
					strongMe.usernameTextField.text = loginDict[AppExtensionUsernameKey];
					strongMe.passwordTextField.text = loginDict[AppExtensionPasswordKey];

					[LoginInformation sharedLoginInformation].username = loginDict[AppExtensionUsernameKey];
				}];
			}
		}
		else {
			// Code for other activity types
		}
	};

	[self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (textField == self.usernameTextField) {
		[LoginInformation sharedLoginInformation].username = textField.text;
	}
}


#pragma mark - UIActivityItemSource Protocol

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
	// Return the current URL as a placeholder
	return [NSURL URLWithString:@"https://www.acme.com"];
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
	if ([[OnePasswordExtension sharedExtension] isOnePasswordExtensionActivityType:activityType]) {
		// Return the 1Password extension item
		return self.onePasswordExtensionItem;
	}
	else {
		// Return the current URL
		return [NSURL URLWithString:@"https://www.acme.com"];
	}
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController dataTypeIdentifierForActivityType:(NSString *)activityType {
	// Because of our UTI declaration, this UTI now satisfies both the 1Password Extension and the usual NSURL for Share extensions.
	return @"org.appextension.find-login-action";
}

@end
