//
//  HirUserDefault.m
//  HiRemote
//
//  Created by rick on 15/7/5.
//  Copyright (c) 2015年 hiremote. All rights reserved.
//

#import "HirUserInfo.h"

@interface HirUserInfo()
@property (nonatomic, strong)NSUserDefaults *stateUserDef;
@end

@implementation HirUserInfo
static HirUserInfo *hirUserDefault;
+(HirUserInfo *)shareUserInfo{
    @synchronized(self){
        if (!hirUserDefault) {
            hirUserDefault = [[HirUserInfo alloc]init];
        }
    }
    return hirUserDefault;
}

-(instancetype)init{
    if(self = [super init]){
        self.stateUserDef = [NSUserDefaults standardUserDefaults];
        self.deviceInfoArray = [[NSMutableArray alloc]initWithCapacity:0];
    }
    return self;
}

-(NSString *)userId{
    NSString *userId = [self.stateUserDef objectForKey:@"userId"];
    if (!userId) {
        userId = @"";
    }
    return userId;
}

-(void)setUserId:(NSString *)userId{
    if (![userId isEqualToString:self.userId]) {
        [self.stateUserDef setObject:userId forKey:@""];
        [self.stateUserDef synchronize];
    }
}

-(void)setCurrentViewControllerType:(CurrentViewControllerType)currentViewControllerType{
    [self.stateUserDef setObject:@(currentViewControllerType) forKey:@"currentViewController"];
    [self.stateUserDef synchronize];
}

-(CurrentViewControllerType)currentViewControllerType{
    return [[self.stateUserDef objectForKey:@"currentViewController"]integerValue];
}

-(void)setCurrentPeripheraIndex:(NSInteger)currentPeripheraIndex{
    [self.stateUserDef setObject:@(currentPeripheraIndex) forKey:@"currentPeripheraIndex"];
    [self.stateUserDef synchronize];
}

-(NSInteger)currentPeripheraIndex{
    return [[self.stateUserDef objectForKey:@"currentPeripheraIndex"]integerValue];
}

-(void)setIsNotificationForVoiceMemo:(BOOL)isNotificationForVoiceMemo{
    [self.stateUserDef setObject:[NSNumber numberWithBool:isNotificationForVoiceMemo] forKey:@"isNotificationForVoiceMemo"];
    [[NSNotificationCenter defaultCenter]postNotificationName:NotificationVoiceOpen object:nil];
    [self.stateUserDef synchronize];
}

-(BOOL)isNotificationForVoiceMemo{
    return [[self.stateUserDef objectForKey:@"isNotificationForVoiceMemo"]boolValue];
}

-(void)setIsNotificationPlaySounds:(BOOL)isNotificationPlaySounds{
    [self.stateUserDef setObject:[NSNumber numberWithBool:isNotificationPlaySounds] forKey:@"isNotificationPlaySounds"];
    [self.stateUserDef synchronize];
}

-(BOOL)isNotificationPlaySounds{
    return [[self.stateUserDef objectForKey:@"isNotificationPlaySounds"]boolValue];
}

-(void)setIsNotificationMyWhenDeviceNoWithin:(BOOL)isNotificationMyWhenDeviceNoWithin{
    [self.stateUserDef setObject:[NSNumber numberWithBool:isNotificationMyWhenDeviceNoWithin] forKey:@"isNotificationMyWhenDeviceNoWithin"];
    [self.stateUserDef synchronize];
}

-(BOOL)isNotificationMyWhenDeviceNoWithin{
    return [[self.stateUserDef objectForKey:@"isNotificationMyWhenDeviceNoWithin"]boolValue];
}

-(DBPeripheral *)currentPeriphera{
    if ([self.deviceInfoArray count] > self.currentPeripheraIndex) {
        _currentPeriphera = [self.deviceInfoArray objectAtIndex:self.currentPeripheraIndex];
        return _currentPeriphera;
    }
    else{
//        NSAssert(0, @"数据非法");
        return nil;
    }
}

-(void)setDeviceInfoArray:(NSMutableArray *)deviceInfoArray{
    NSLog(@"set deviceInfoArray,deviceInfoArray.count = %d",deviceInfoArray.count);
    _deviceInfoArray = deviceInfoArray;
}
@end