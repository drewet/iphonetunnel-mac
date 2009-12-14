//
//  Controller.m
//  iPhoneTunnel
//
//  Created by ito novi.mad@gmail.com on 平成 20/09/22.
//	Updated by phonique@gmail.com on 12/12/2009

#import "Controller.h"
#import "ITStatusBarView.h"
#import "MobileDevice.h"
#import <unistd.h>

static Controller* sharedController = nil;

@interface Controller(MobileDeviceInterface)

- (void)deviceConnected:(const char*)ids;
- (void)deviceDisconnected:(const char*)ids;

- (void)refreshDeviceMenuItem;
- (void)mobileDeviceRun:(id)sender;

- (void)stopWithConfirm:(BOOL)conf;
- (void)runInTerminal:(id)sender;

- (void)openSSHWithUser:(NSString*)user option:(NSString*)opt;
- (void)mountToFinderAs:(NSString*)user volumeName:(NSString*)vol;
@end
/*
NSString* AMDGetDeviceName(struct am_device* dev)
{
	int ret;
	struct am_device* target_device = dev;
	// ターゲットが準備完了
	// デバイスへ接続
	ret = AMDeviceConnect(target_device);
	if (ret != ERR_SUCCESS) {
		return nil;
	}
	
	ret = AMDeviceIsPaired(target_device);
	if (ret != 1) {
		return nil;
	}
	
	ret = AMDeviceValidatePairing(target_device);
	if (ret != ERR_SUCCESS) {
		return nil;
	}
	
	ret = AMDeviceStartSession(target_device);
	if (ret != ERR_SUCCESS) {
		return nil;
	}
	
	// サービスを開始
	// サービス名と接続されたハンドルの戻り値をhandleで指定
	int handle;
	ret = AMDeviceStartService(target_device, AMSVC_AFC, &handle, NULL);
	if (ret != ERR_SUCCESS) {
		return nil;
	}
	
	struct afc_connection* afc_con;
	// 接続を開く
	// これで接続が確立
	ret = AFCConnectionOpen(handle, 0, &afc_con);
	if (ret != MDERR_OK) {
		NSLog(@"dict error");
		return nil;
	}
	
	NSLog(@"prepared device");
	struct afc_dictionary* dict;
//	ret = AFCDeviceInfoOpen(afc_con, &dict);
	ret = AFCFileInfoOpen(afc_con, "/var/root/iphonelcd", &dict);
	afc_file_ref file;
//	ret = AFCFileRefOpen(afc_con, "/Library/Preferences/SystemConfiguration/preferences.plist", 3, &file);
	if (ret != ERR_SUCCESS) {
		NSLog(@"err %d", ret);
		return nil;
	}
	char* devname;
	char* key;
	
	int i;
	
	for (i = 0; i < 10; i++) {
		AFCKeyValueRead(dict, &key, &devname);
		
		NSLog(@"key %s, cont %s", key, devname) ;
		
	}
	
	AFCKeyValueClose(dict);
	
	return nil;
}
*/

void mobileDeviceNotification(struct am_device_notification_callback_info* info)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	if (info->msg == ADNCI_MSG_CONNECTED) {
		//AMDeviceCopyDeviceIdentifier(info->dev);
		//(@"%@", AMDeviceCopyValue(info->dev, 0, CFStringCreateWithCString(	NULL, "ActivationInfo",	kCFStringEncodingASCII)));
		//AMDGetDeviceName(info->dev);
//		NSLog(@"dev%@", AMDGetDeviceName(info->dev));
		[sharedController deviceConnected:info->dev->serial];
	} else {
		[sharedController deviceDisconnected:info->dev->serial];
	}
	[pool release];
}


@implementation Controller


+ (void)initialize;
{
    NSDictionary* defaults;
    NSString* path;
	
    [super initialize];
    path = [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"];
    defaults = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
	
}



- (void)awakeFromNib
{
	[_connections setTitle:NSLocalizedString(@"Connections: -", nil)];
	
	//[self mobileDeviceRun:self];
	//[NSThread detachNewThreadSelector:@selector(mobileDeviceRun:) toTarget:self withObject:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	
	// Create and set up status bar
	NSStatusBar* bar = [NSStatusBar systemStatusBar];
	NSStatusItem* mainItem = [bar statusItemWithLength:30];
	[mainItem setHighlightMode:YES];
	[mainItem retain];
	//_barItem = mainItem;
	
	_barView = [[ITStatusBarView alloc] initWithFrame:NSMakeRect(0, 0, 30, [bar thickness]) statusItem:mainItem menu:_barMenu];
	[mainItem setView:_barView];
	
	_tunnelIsOn = NO;
	[_barView setImageGray:YES];
	
	sharedController = self;
	_devices = [[NSMutableArray alloc] init];
	//[self refreshDeviceMenuItem];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[self stop:nil];
}

#pragma mark Device menu item

- (void)mobileDeviceRun:(id)sender
{
	//while (1)
	//{
	int ret;
	// デバイスのコールバックを登録
	struct am_device_notification *notif; 
	ret = AMDeviceNotificationSubscribe(mobileDeviceNotification, 0, 0, 0, &notif);
	if (ret != ERR_SUCCESS) {
		printf("AMDeviceNotificationSubscribe = %i\n", ret);
	}
	
	//	CFRunLoopRun();
	//	printf("RUN LOOP EXIT\n");
	//	sleep(1);
	//}
}
//phonique - python integration - disable device update, because of crash when iPhone is connected
//disabled "Target Device" in Interface Builder
/*
- (void)deviceConnected:(const char*)ids
{
	NSString* idObj = [NSString stringWithCString:ids encoding:NSUTF8StringEncoding];
	size_t i;
	
	// Add device id to array
	for (i = 0; i < [_devices count]; i++) {
		// If already added
		if ([[_devices objectAtIndex:i] isEqualToString:idObj]) {
			return;
		}
	}
	[_devices addObject:idObj];
	[self refreshDeviceMenuItem];
	
}
 */

- (void)deviceDisconnected:(const char*)ids
{
	NSString* idObj = [NSString stringWithCString:ids encoding:NSUTF8StringEncoding];
	size_t i;
	
	// Remove device id from array
	for (i = 0; i < [_devices count]; i++) {
		if ([[_devices objectAtIndex:i] isEqualToString:idObj]) {
			[_devices removeObjectAtIndex:i];
			// If disconnected current device
			if ([_currentDevice isEqualToString:idObj]) {
				// Set to any device
				_currentDevice = nil;
			}
			[self refreshDeviceMenuItem];
			break;
		}
	}		
}


- (void)deviceMenuClicked:(id)sender
{
	NSString* newDevice;
	if ([sender tag] == -1) {
		// Selected any device
		newDevice = nil;
	} else {
		// Specify device
		newDevice = [[sender title] copy];		
	}
	
	// Changed current device
	if (_currentDevice != newDevice) {
		if (![_currentDevice isEqualToString:newDevice]) {
			
			// Set menu item on
			size_t i;
			NSArray* items = [[_menuDevices submenu] itemArray];
			for (i = 0; i < [items count]; i++) {
				[[items objectAtIndex:i] setState:NSOffState];
			}
			[sender setState:NSOnState];
			_currentDevice = newDevice;
			
			if (_tunnelIsOn == NO) {
				return;
			}
			if ([[_tunnelTask arguments] count] == 3 && _currentDevice == nil) {
				return;
			}
			if (_currentDevice || ![[[_tunnelTask arguments] lastObject] isEqualToString:_currentDevice]) {
				NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedString(@"To change target device, Tunnel must be restarted.", nil)
												 defaultButton: NSLocalizedString(@"OK", nil) 
											   alternateButton: nil
												   otherButton: nil
									 informativeTextWithFormat: @""];
				[alert setAlertStyle:NSInformationalAlertStyle];
				[alert runModal];
			}
			
		}
	}
	
}

- (void)refreshDeviceMenuItem
{
	size_t i;
	NSMenu* subMenu = [[NSMenu alloc] initWithTitle:@""];
	[_menuDevices setSubmenu:subMenu];
	[subMenu release];
	
	NSMenuItem* item = [[NSMenuItem alloc] init];
	[item setTitle:NSLocalizedString(@"Any Device", nil)];
	[item setTag:-1];
	[item setTarget:self];
	// If current device is any device
	if (!_currentDevice) {
		[item setState:NSOnState];
	}	
	[item setAction:@selector(deviceMenuClicked:)];
	[[_menuDevices submenu] addItem:item];
	[item release];
	
	//NSLog(@"all devices %@", [_devices description]);
	for (i = 0; i < [_devices count]; i++) {
		item = [[NSMenuItem alloc] init];
		//[item setTag:-1];
		[item setTarget:self];
		// If current device is equal to item
		if ([[_devices objectAtIndex:i] isEqualToString:_currentDevice]) {
			[item setState:NSOnState];
		}
		[item setAction:@selector(deviceMenuClicked:)];
		[item setTitle:[_devices objectAtIndex:i]];
		[[_menuDevices submenu] addItem:item];
		[item release];
		
	}
}


#pragma mark Main interface

- (IBAction)statusBarAnimation:(id)sender
{
	if ([sender state] == NSOnState) {
		[_barView setImageAnimation:YES];
	} else {
		[_barView setImageAnimation:NO];
	}
	
}

- (IBAction)toggleOnOff:(id)sender
{
	if (_tunnelIsOn) {
		// turn off
		_tunnelIsOn = NO;
		[self stop:nil];
	} else {
		// turn on
		//[self kill];
		[_tunnelTask stopProcess];
		
		if ([_logging state] == NSOnState) {
			[self runInTerminal:self];
		}else {
			[self run:nil];
			_tunnelIsOn = YES;
		}
		
	}
	
	
}


#pragma mark Create Task

- (void)run:(id)sender
{
	[_barView setImageGray:NO];
	[_barView setImageAnimation:YES];
	
	[_tunnelOnOff setTitle:NSLocalizedString(@"Turn off tunnel", nil)];
	/*
	//[self kill];
	NSDictionary* env = [NSDictionary dictionaryWithObjectsAndKeys:@"./md_hook.dylib", @"DYLD_INSERT_LIBRARIES", @"YES", @"DYLD_FORCE_FLAT_NAMESPACE", nil];
	NSString* tunnelExec = [[NSBundle mainBundle] pathForResource:@"itnl" ofType:nil];
	[_tunnelTask release];
	NSArray* args;
	if (_currentDevice) {
		args = [NSArray arrayWithObjects:tunnelExec, [_devicePort stringValue], [_localPort stringValue], _currentDevice, nil];
	} else {
		args = [NSArray arrayWithObjects:tunnelExec, [_devicePort stringValue], [_localPort stringValue], nil];
	}
	//NSLog(@"args: %@", [args description]);
	_tunnelTask = [[TaskWrapper alloc] initWithController:self arguments:args];
	[_tunnelTask setEnvironment:env];
	 
	 */
	
	
	//NSDictionary* env = [NSDictionary dictionaryWithObjectsAndKeys:@"./md_hook.dylib", @"DYLD_INSERT_LIBRARIES", @"YES", @"DYLD_FORCE_FLAT_NAMESPACE", nil];
	//NSString* tunnelExec = [[NSBundle mainBundle] pathForResource:@"itnl" ofType:nil];
	[_tunnelTask release];
	NSArray* args = nil;
	NSString* tcprelayPath = [[NSBundle mainBundle] pathForResource:@"tcprelay" ofType:@"py"];
	NSString* pythonPath = @"/usr/bin/python";
	NSString* tcprelayArgs = [NSString stringWithFormat:@"%d:%d", [_devicePort intValue], [_localPort intValue]];
	
	if (_currentDevice) {
		args = [NSArray arrayWithObjects:pythonPath, tcprelayPath, @"-t", tcprelayArgs, nil];
	} else {
		args = [NSArray arrayWithObjects:pythonPath, tcprelayPath, @"-t", tcprelayArgs, nil];
	}
	//NSLog(@"args: %@", [args description]);
	_tunnelTask = [[TaskWrapper alloc] initWithController:self arguments:args];
	//[_tunnelTask setEnvironment:env];
	
	[_tunnelTask startProcessWaitUntilExit:NO useStdout:NO];
//	[_tunnelTask startProcessWaitUntilExit:NO useStdout:YES];

}

- (void)runInTerminal:(id)sender
{
	/*
	NSString* tunnelExec = [[NSBundle mainBundle] pathForResource:@"itnl" ofType:nil];
	NSString* scriptBase = @"tell application \"Terminal\"\n\
	do script (\"cd \\\"%@\\\"\\nsh iphone_tunnel %@ %@ %@\")\n\
	end tell";
	
	 NSString* script;
	 if (_currentDevice) {
	 script = [NSString stringWithFormat:scriptBase, [tunnelExec stringByDeletingLastPathComponent], [_devicePort stringValue], [_localPort stringValue], _currentDevice];
	 } else {
	 script = [NSString stringWithFormat:scriptBase, [tunnelExec stringByDeletingLastPathComponent], [_devicePort stringValue], [_localPort stringValue], @""];
	 }
	*/
	
	//phonique python mod
	NSString* tunnelExec = [[NSBundle mainBundle] pathForResource:@"tcprelay.py" ofType:nil];
	NSString* scriptBase = @"tell application \"Terminal\"\n\
	do script (\"cd \\\"%@\\\"\\npython tcprelay.py -t %@:%@\")\n\
	end tell";
	
	NSString* script;
	//no _currentDevice with python implementation (yet)
	script = [NSString stringWithFormat:scriptBase, [tunnelExec stringByDeletingLastPathComponent], [_devicePort stringValue], [_localPort stringValue], @""];


	//NSLog(@"runscript %@", script);
	
	NSAppleScript* appleScript = [[NSAppleScript alloc] initWithSource:script];
	[appleScript executeAndReturnError:nil];
	[appleScript release];

}

- (void)stop:(id)sender
{
	[_barView setImageGray:YES];
	[_barView setImageAnimation:NO];
	[_tunnelOnOff setTitle:NSLocalizedString(@"Turn on tunnel", nil)];
	
	[_tunnelTask stopProcess];
}

/*
- (void)kill
{
	
	//TaskWrapper* killall = [[TaskWrapper alloc] initWithController:nil arguments:[NSArray arrayWithObjects:@"/usr/bin/killall", @"-INT", @"itnl", nil]];
	//[killall startProcessWaitUntilExit:YES];
	//[killall release];
}

*/

#pragma mark TaskWrapper delegate

- (void)appendOutput:(NSString *)output
{
	NSLog(@"tunnel log: %@", output);
	
	NSRange bindErrorRange = [output rangeOfString:@"bind error!" options:NSBackwardsSearch];
	NSRange hookErrorRange = [output rangeOfString:@"hook error!" options:NSBackwardsSearch];
	
	if (bindErrorRange.location != NSNotFound) {
		NSLog(@"BIND ERROR");
		_tunnelIsOn = YES;
		[self toggleOnOff:self];
		[_connections setTitle:NSLocalizedString(@"Connections: Bind Error", nil)];
		//[self kill];
		return;
	}
	if (hookErrorRange.location != NSNotFound) {
		NSLog(@"HOOK ERROR");
		_tunnelIsOn = YES;
		[self toggleOnOff:self];
	//	[self kill];
		NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedString(@"Hook failure.", nil)
										 defaultButton: NSLocalizedString(@"OK", nil) 
									   alternateButton: nil
										   otherButton: nil
							 informativeTextWithFormat: @""];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert runModal];
		//		[alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:nil contextInfo:nil];
		[NSApp terminate:self];
		return;
	}
	
	//NSLog(@"len %d",[output length]);
	NSRange threadRange = [output rangeOfString:@"threadcount=" options:NSBackwardsSearch];
	
	if (threadRange.location == NSNotFound) {
		return;
	}
	NSRange threadCountRange = [output rangeOfString:@"\n" 
											 options:NSLiteralSearch 
											   range:NSMakeRange(threadRange.location+threadRange.length, [output length] - (threadRange.location+threadRange.length))];
	NSString* prefix = [output substringWithRange:NSMakeRange(threadRange.location, threadCountRange.location - threadRange.location)];
	NSRange countRange = NSMakeRange(12, ([prefix length]) - 12);
	NSString* threadCountPlane = [prefix substringWithRange:countRange];
	[_connections setTitle:[NSString stringWithFormat:NSLocalizedString(@"Connections: %@", nil), threadCountPlane]];	
}

- (void)processStarted
{
	NSLog(@"Started");
	[_connections setTitle:NSLocalizedString(@"Connections: 0", nil)];
}

- (void)processFinished
{
	[_connections setTitle:NSLocalizedString(@"Connections: -", nil)];
	NSLog(@"Finishied");
	//_tunnelIsOn = YES;
	//[self toggleOnOff:self];
}


#pragma mark Tools Method

- (void)openSSHWithUser:(NSString*)user option:(NSString*)opt
{
	NSString* scriptBase = @"tell application \"Terminal\"\n\
	do script (\"ssh -l %@ -p %d %@ 127.0.0.1\")\n\
	end tell";
	NSString* script = [NSString stringWithFormat:scriptBase, user, [_localPort intValue], opt];
	
	NSAppleScript* appleScript = [[NSAppleScript alloc] initWithSource:script];
	[appleScript executeAndReturnError:nil];
	[appleScript release];
}

- (IBAction)toolMountAsUser:(id)sender
{
	[self mountToFinderAs:@"mobile" volumeName:[_volNameUser stringValue]];
}

- (IBAction)toolMountAsRoot:(id)sender
{
	[self mountToFinderAs:@"root" volumeName:[_volNameRoot stringValue]];
}


- (void)mountToFinderAs:(NSString*)user volumeName:(NSString*)vol
{
	if ([user length] == 0 || [vol length] == 0) {
		NSLog(@"Error username or volume name is null");
		return;
	}
	
	//NSLog(@"ver %@", [[NSProcessInfo processInfo] operatingSystemVersionString]);
	NSString* sshfsExec;
	NSRange osVer = [[[NSProcessInfo processInfo] operatingSystemVersionString] rangeOfString:@"10.4"];
	if (osVer.location != NSNotFound) {
		sshfsExec = [[NSBundle mainBundle] pathForResource:@"sshfs-static-tiger" ofType:nil];
	} else {
		sshfsExec = [[NSBundle mainBundle] pathForResource:@"sshfs-static-leopard" ofType:nil];
	}
	
	NSString* mountPoint = [vol lastPathComponent];
	[[NSFileManager defaultManager] createDirectoryAtPath:[@"/tmp/" stringByAppendingPathComponent:mountPoint] attributes:nil];
	
	NSString* terminalScript = [NSString stringWithFormat:@"%@ %@@127.0.0.1: \\\"%@\\\" -p %@ -o reconnect,volname=\\\"%@\\\"", 
								sshfsExec, user, [@"/tmp/" stringByAppendingPathComponent:mountPoint], [_localPort stringValue], mountPoint];
	
	NSString* scriptBase = @"tell application \"Terminal\"\n\
	do script (\"%@\")\n\
	end tell";
	NSString* script = [NSString stringWithFormat:scriptBase, terminalScript];
	
	NSAppleScript* appleScript = [[NSAppleScript alloc] initWithSource:script];
	[appleScript executeAndReturnError:nil];
	[appleScript release];
	
}

- (IBAction)openNetworkSettings:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Network.prefPane/"];
}

- (IBAction)toolSSHWithRoot:(id)sender
{
	[self openSSHWithUser:@"root" option:[_sshOptionRoot stringValue]];
}

- (IBAction)toolSSH:(id)sender
{
	[self openSSHWithUser:@"mobile" option:[_sshOptionUser stringValue]];
}

- (IBAction)toolSFTP:(id)sender
{
	int port = [_localPort intValue];
	NSURL* sshURL = [NSURL URLWithString:[NSString stringWithFormat:@"sftp://mobile@127.0.0.1:%d/", port]];
	[[NSWorkspace sharedWorkspace] openURL:sshURL];
}

- (IBAction)toolSFTPAsRoot:(id)sender
{
	int port = [_localPort intValue];
	NSURL* sshURL = [NSURL URLWithString:[NSString stringWithFormat:@"sftp://root@127.0.0.1:%d/", port]];
	[[NSWorkspace sharedWorkspace] openURL:sshURL];
}

- (IBAction)toolTethering:(id)sender
{
	NSString* scriptBase = @"tell application \"Terminal\"\n\
	do script (\"ssh -ND %d -p %d mobile@127.0.0.1\")\n\
	end tell";
	NSString* script = [NSString stringWithFormat:scriptBase, [_tetheringPort intValue], [_localPort intValue]];
	
	NSAppleScript* appleScript = [[NSAppleScript alloc] initWithSource:script];
	[appleScript executeAndReturnError:nil];
	[appleScript release];
}

- (IBAction)openPreferences:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[_prefWindow makeKeyAndOrderFront:nil];
}

@end
