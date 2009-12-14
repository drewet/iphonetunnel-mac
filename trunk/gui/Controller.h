//
//  Controller.h
//  iPhoneTunnel
//
//  Created by ito on 平成 20/09/22.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import "TaskWrapper.h"

@class ITStatusBarView;

@interface Controller : NSObject <TaskWrapperController> {

	IBOutlet NSMenuItem*	_menuDevices;
	IBOutlet NSMenuItem*	_connections;
	IBOutlet NSMenuItem*	_tunnelOnOff;
	IBOutlet NSButton*	_barButton;
	IBOutlet NSMenu*	_barMenu;
	
	IBOutlet NSWindow*	_prefWindow;
	IBOutlet NSTextField* _localPort;
	IBOutlet NSTextField* _tetheringPort;
	IBOutlet NSTextField* _devicePort;
	
	IBOutlet NSTextField* _sshOptionUser;
	IBOutlet NSTextField* _sshOptionRoot;
	
	IBOutlet NSTextField* _volNameUser;
	IBOutlet NSTextField* _volNameRoot;
	
	IBOutlet NSButton* _logging;
	
	ITStatusBarView*	_barView;
	BOOL				_tunnelIsOn;
	
	TaskWrapper*		_tunnelTask;
	
	NSMutableArray*		_devices;
	NSString*			_currentDevice;
}

- (IBAction)statusBarAnimation:(id)sender;
- (IBAction)toggleOnOff:(id)sender;

- (IBAction)run:(id)sender;
- (IBAction)stop:(id)sender;
//- (void)kill;


- (IBAction)openNetworkSettings:(id)sender;
- (IBAction)openPreferences:(id)sender;

- (IBAction)toolSSH:(id)sender;
- (IBAction)toolSSHWithRoot:(id)sender;
- (IBAction)toolMountAsUser:(id)sender;
- (IBAction)toolMountAsRoot:(id)sender;
- (IBAction)toolSFTP:(id)sender;
- (IBAction)toolSFTPAsRoot:(id)sender;
- (IBAction)toolTethering:(id)sender;
@end
