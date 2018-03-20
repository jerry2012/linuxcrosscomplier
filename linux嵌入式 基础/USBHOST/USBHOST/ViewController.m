//
//  ViewController.m
//  USBHOST
//
//  Created by admindyn on 2018/3/20.
//  Copyright © 2018年 admindyn. All rights reserved.
//

#import "USBHID.h"
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOTypes.h>
#include <IOKit/IOReturn.h>
#include <IOKit/hid/IOHIDLib.h>

#import "ViewController.h"

@interface ViewController() <UsbHIDDelegate>

@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
  
   
    
    NSButton* loginButton =[[NSButton alloc]init];
    [loginButton setFrame:NSMakeRect(30, 100, 100, 35)];
    [loginButton setTitle:@"登录"];
    [loginButton setAction:@selector(loginButtonClicked:)];
    
    [self.view addSubview:loginButton];
    
    
    
    
}
#pragma mark delegate-usb

-(void)usbhidDidMatch
{
    
}
-(void)usbhidDidRemove
{
    
}
-(void)usbhidDidRecvData:(uint8_t *)recvData length:(CFIndex)reportLength
{
    
    NSLog(@"USB delegate get data");
    
}

-(void)loginButtonClicked:(NSButton* )sender
{
    
    USBHID* manager= [USBHID sharedManager];
    
    manager.delegate =self;
    
    [manager connectHID];
}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
