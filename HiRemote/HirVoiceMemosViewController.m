//
//  HirVoceViewController.m
//  HiRemote
//
//  Created by rick on 15/7/4.
//  Copyright (c) 2015年 hiremote. All rights reserved.
//

#import "HirVoiceMemosViewController.h"
#import "HirVoiceCell.h"
#import <AVFoundation/AVFoundation.h>
#import "HirDataManageCenter+DeviceRecord.h"
#import "HirActionTextField.h"
#import "HirAlertView.h"

@interface HirVoiceMemosViewController ()
<UISearchDisplayDelegate,
UITableViewDataSource,
UITableViewDelegate,
AVAudioRecorderDelegate,
UITextFieldDelegate>
{
    BOOL toggle;
    AVAudioPlayer *audioPlayer;
    AVAudioRecorder *audioRecorder;
    enum
    {
        ENC_AAC = 1,
        ENC_ALAC = 2,
        ENC_IMA4 = 3,
        ENC_ILBC = 4,
        ENC_ULAW = 5,
        ENC_PCM = 6,
    } encodingTypes;
    int recordEncoding;
    NSTimer *timerForPitch;
    float Pitch;

}
@property (nonatomic, strong)NSMutableArray *data;
@property (nonatomic, strong)NSArray *filterData;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *playVoiceRecordPanel;

@property (weak, nonatomic) IBOutlet UILabel *recordDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *recordTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *voicePlayBtn;
@property (weak, nonatomic) IBOutlet UILabel *voiceBeginTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *voiceEndTimeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *voiceProgressView;

@property (weak, nonatomic) IBOutlet UILabel *recordingLabel;

@property (nonatomic, strong)UISearchDisplayController *searchDisplayController;

@property (nonatomic, strong)DBDeviceRecord *currentDeviceRecord;
@property (nonatomic, strong)HirActionTextField *actionTextField;

@end

@implementation HirVoiceMemosViewController
@synthesize searchDisplayController;
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"VoiceMemos", nil);
    
    self.tableView.tableFooterView = [[UIView alloc]init];
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    searchBar.placeholder = NSLocalizedString(@"search", nil);
    
    // 添加 searchbar 到 headerview
    //    self.tableView.tableHeaderView = searchBar;
    
    // 用 searchbar 初始化 SearchDisplayController
    // 并把 searchDisplayController 和当前 controller 关联起来
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    // searchResultsDataSource 就是 UITableViewDataSource
    searchDisplayController.searchResultsDataSource = self;
    // searchResultsDelegate 就是 UITableViewDelegate
    searchDisplayController.searchResultsDelegate = self;
    searchDisplayController.delegate = self;
    
    self.tableView.tableHeaderView = searchBar;
    
    [self getDataAndRefreshTable];
    
    self.playVoiceRecordPanel.hidden = YES;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(getDataAndRefreshTable) name:DEVICE_RECORD_UPDATA_NOTIFICATION object:nil];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [HirUserInfo shareUserInfo].currentViewControllerType = CurrentViewControllerType_voice;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(recordVoiceNotification:) name:NEED_RECORD_VOICE object:nil];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(void)recordVoiceNotification:(NSNotification *)notification{
    static BOOL isRecord = NO;
    isRecord = !isRecord;
    
    if (isRecord) {
        [self startRecording];
        NSLog(@"收到录音信号");
    }
    else{
        [self stopRecording];
        NSLog(@"收到停止录音信号");
    }
}

-(IBAction) startRecording
{
    // kSeconds = 150.0;
    NSLog(@"startRecording");
    audioRecorder = nil;
    NSError *erro;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionDefaultToSpeaker error:&erro];
    
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] initWithCapacity:10];
    if(recordEncoding == ENC_PCM)
    {
        [recordSettings setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey: AVFormatIDKey];
        [recordSettings setObject:[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];
        [recordSettings setObject:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
        [recordSettings setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        [recordSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
        [recordSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    }
    else
    {
        NSNumber *formatObject;
        
        switch (recordEncoding) {
            case (ENC_AAC):
                formatObject = [NSNumber numberWithInt: kAudioFormatMPEG4AAC];
                break;
            case (ENC_ALAC):
                formatObject = [NSNumber numberWithInt: kAudioFormatAppleLossless];
                break;
            case (ENC_IMA4):
                formatObject = [NSNumber numberWithInt: kAudioFormatAppleIMA4];
                break;
            case (ENC_ILBC):
                formatObject = [NSNumber numberWithInt: kAudioFormatiLBC];
                break;
            case (ENC_ULAW):
                formatObject = [NSNumber numberWithInt: kAudioFormatULaw];
                break;
            default:
                formatObject = [NSNumber numberWithInt: kAudioFormatAppleIMA4];
        }
        
        [recordSettings setObject:formatObject forKey: AVFormatIDKey];
        [recordSettings setObject:[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];
        [recordSettings setObject:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
        [recordSettings setObject:[NSNumber numberWithInt:12800] forKey:AVEncoderBitRateKey];
        [recordSettings setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        [recordSettings setObject:[NSNumber numberWithInt: AVAudioQualityHigh] forKey: AVEncoderAudioQualityKey];
    }
    
    //    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/recordTest.caf", [[NSBundle mainBundle] resourcePath]]];
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(
                                                            NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    
    NSString *mediaPath = [NSString stringWithFormat:@"%lld.caf",(long long)[[NSDate date] timeIntervalSince1970]];
   // NSString *mediaPath = [NSString stringWithFormat:@"%lld.caf",(long long)[[NSDate date]timeIntervalSinceReferenceDate]*1000000];
    NSString *soundFilePath = [docsDir
                               stringByAppendingPathComponent:mediaPath];
    
    NSURL *url = [NSURL fileURLWithPath:soundFilePath];
    
    NSError *error = nil;
    audioRecorder = [[ AVAudioRecorder alloc] initWithURL:url settings:recordSettings error:&error];
    audioRecorder.meteringEnabled = YES;
    if ([audioRecorder prepareToRecord] == YES){
        audioRecorder.meteringEnabled = YES;
        [audioRecorder record];
        timerForPitch =[NSTimer scheduledTimerWithTimeInterval: 0.01 target: self selector: @selector(levelTimerCallback:) userInfo: nil repeats: YES];
    }else {
        
        int errorCode = CFSwapInt32HostToBig ([error code]);
        NSLog(@"Error: %@ [%4.4s])" , [error localizedDescription], (char*)&errorCode);
        
    }
    
}

- (void)levelTimerCallback:(NSTimer *)timer {
    [audioRecorder updateMeters];
    NSLog(@"Average input: %f Peak input: %f", [audioRecorder averagePowerForChannel:0], [audioRecorder peakPowerForChannel:0]);
    
    float linear = pow (10, [audioRecorder peakPowerForChannel:0] / 20);
    NSLog(@"linear===%f",linear);
    float linear1 = pow (10, [audioRecorder averagePowerForChannel:0] / 20);
    NSLog(@"linear1===%f",linear1);
    if (linear1>0.03) {
        
        Pitch = linear1+.20;//pow (10, [audioRecorder averagePowerForChannel:0] / 20);//[audioRecorder peakPowerForChannel:0];
    }
    else {
        
        Pitch = 0.0;
    }
    //Pitch =linear1;
    NSLog(@"Pitch==%f",Pitch);
//    _customRangeBar.value = Pitch;//linear1+.30;
    [_voiceProgressView setProgress:Pitch];
    float minutes = floor(audioRecorder.currentTime/60);
    float seconds = audioRecorder.currentTime - (minutes * 60);
    
    NSString *time = [NSString stringWithFormat:@"%0.0f.%0.0f",minutes, seconds];
    [self.recordTimeLabel setText:[NSString stringWithFormat:@"%@ sec", time]];
    NSLog(@"recording");
    
}

-(IBAction) stopRecording
{
    NSLog(@"stopRecording");
    // kSeconds = 0.0;
    [audioRecorder stop];
    NSLog(@"stopped");
    [timerForPitch invalidate];
    timerForPitch = nil;
    
    NSLog(@"url=%@",audioRecorder.url);
    
    NSString *mediaPath = [audioRecorder.url.path lastPathComponent];
    
    NSLog(@"mmmm:%@",mediaPath);
    NSRange range = [mediaPath rangeOfString:@"."];
    NSString *recoderTimestamp;
    if (range.location != NSNotFound) {
        recoderTimestamp = [mediaPath substringToIndex:range.location];
        NSLog(@"tttt:%@",recoderTimestamp);
    }
    
    double beginRecordTime = recoderTimestamp.doubleValue;
    
    double voiceTime = [[NSDate date]timeIntervalSinceReferenceDate] - beginRecordTime;
    
    [HirDataManageCenter insertVoicePath:mediaPath peripheraUUID:[HirUserInfo shareUserInfo].currentPeriphera.uuid recoderTimestamp:[NSNumber numberWithDouble:beginRecordTime] title:NSLocalizedString(@"newRecording", nil) voiceTime:[NSNumber numberWithDouble:voiceTime]];
}

-(IBAction) playRecording
{
    NSLog(@"playRecording");
    // Init audio with playback capability
    NSError *erro;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
//    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionDefaultToSpeaker error:&erro];
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(
                                                            NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    
    NSString *soundFilePath = [docsDir
                               stringByAppendingPathComponent:self.currentDeviceRecord.voicePath];
    
    NSURL *url = [NSURL fileURLWithPath:soundFilePath];
    
    // NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/recordTest.caf", [[NSBundle mainBundle] resourcePath]]];
    NSError *error;
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    audioPlayer.numberOfLoops = 0;
    [audioPlayer play];
    NSLog(@"playing");
}

-(IBAction) stopPlaying
{
    NSLog(@"stopPlaying");
    [audioPlayer stop];
    NSLog(@"stopped");
    
}

#pragma mark -- UITextFeild delegater methods
-(void)textFieldDidBeginEditing:(UITextField *)textField{
    if (textField == self.actionTextField) {
        [self.actionTextField drawBorderColorWith:COLOR_THEME];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.actionTextField) {
        [self.actionTextField drawBorderColorWith:[UIColor clearColor]];
    }
}

- (IBAction)playBtnPressed:(id)sender {
    static BOOL isPlaying = NO;
    isPlaying = !isPlaying;

    if (isPlaying) {
        [self playRecording];
    }
    else{
        [self stopPlaying];
    }
    
}

-(void)getDataAndRefreshTable{
    self.data = [HirDataManageCenter findAllRecord];
    
    [self.tableView reloadData];
    [self refreshPlayVoiceRecordPannelViewWithModel:self.currentDeviceRecord];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

/*
 * 如果原 TableView 和 SearchDisplayController 中的 TableView 的 delete 指向同一个对象
 * 需要在回调中区分出当前是哪个 TableView
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        return self.data.count;
    }else{
        // 谓词搜索
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self contains [cd] %@",self.searchDisplayController.searchBar.text];
        self.filterData =  [[NSArray alloc] initWithArray:[self.data filteredArrayUsingPredicate:predicate]];
        return self.filterData.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *cellIdentifier = @"Cell";
    
    HirVoiceCell *cell = (HirVoiceCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[HirVoiceCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    DBDeviceRecord *deviceRecord;
    if (tableView == self.tableView) {
        deviceRecord = self.data[indexPath.row];
    }else{
        deviceRecord = self.filterData[indexPath.row];
    }
    cell.titleLabel.text = deviceRecord.title;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"MM/dd/yy"];
    //用[NSDate date]可以获取系统当前时间
    cell.dateLabel.text = [dateFormatter stringFromDate:[[NSDate alloc]initWithTimeIntervalSinceReferenceDate:deviceRecord.recoderTimestamp.doubleValue]];//@"15/10/15:10:50";
    
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    cell.voiceRecodeTimeLabel.text = [dateFormatter stringFromDate:[[NSDate alloc]initWithTimeIntervalSinceReferenceDate:deviceRecord.recoderTimestamp.doubleValue]];//@"15/10/15:10:50";
    cell.titleLabel.font = FONT_TABLE_CELL_TITLE;
    cell.dateLabel.font = FONT_TABLE_CELL_CONTENT;
    cell.voiceRecodeTimeLabel.font = FONT_TABLE_CELL_CONTENT;
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [HirVoiceCell heightOfCellWithData:nil];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(tableView == self.tableView){
        [self playVoiceModel:self.data[indexPath.row]];
    }
    else{
        [self playVoiceModel:self.filterData[indexPath.row]];
    }
    [self.playVoiceRecordPanel setHidden:NO];
    
}

//-(void)setVoicePlandHided:(BOOL)isHided{
//    if (isHided) {
//        [UIView animateWithDuration:.3 animations:^{
//            self.playVoiceRecordPanel.alpha =
//        }completion:^(BOOL finished){
//            
//        }];
//    }
//}

-(void)refreshPlayVoiceRecordPannelViewWithModel:(DBDeviceRecord *)deviceRecord{
    self.recordingLabel.text = deviceRecord.title;
    self.voiceEndTimeLabel.text = [NSString stringWithFormat:@"%@",deviceRecord.voiceTime];
    self.currentDeviceRecord = deviceRecord;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"MM/dd/yy"];
    //用[NSDate date]可以获取系统当前时间
    self.recordDateLabel.text = [dateFormatter stringFromDate:[[NSDate alloc]initWithTimeIntervalSinceReferenceDate:deviceRecord.recoderTimestamp.doubleValue]];//@"15/10/15:10:50";
    
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    self.recordTimeLabel.text = [dateFormatter stringFromDate:[[NSDate alloc]initWithTimeIntervalSinceReferenceDate:deviceRecord.recoderTimestamp.doubleValue]];//@"15/10/15:10:50";
}

-(void)playVoiceModel:(DBDeviceRecord *)deviceRecord{
    [self refreshPlayVoiceRecordPannelViewWithModel:deviceRecord];
    [self.playVoiceRecordPanel setHidden:NO];
    
    [self.view bringSubviewToFront:self.playVoiceRecordPanel];
}

- (IBAction)hidePlayVoceRecordPanel:(id)sender {
    [self.playVoiceRecordPanel setHidden:YES];
}

- (IBAction)editVoiceBtnPressed:(id)sender {
    NSLog(@"editVoiceBtnPressed");
    
    self.actionTextField = [[HirActionTextField alloc]initWithFrame:CGRectMake(10, 10, 200, 30)];
    self.actionTextField.delegate = self;
    
    HirAlertView *hirAlertView = [[HirAlertView alloc]initWithTitle:NSLocalizedString(@"changeName", nil) contenView:self.actionTextField clickBlock:^(NSInteger index){
        self.currentDeviceRecord.title = self.actionTextField.text;
        [HirDataManageCenter saveDeviceRecordByModel:self.currentDeviceRecord];
        [self.tableView reloadData];
    }cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) otherButtonTitles:NSLocalizedString(@"CONFIRM", nil), nil];
    [hirAlertView showWithAnimation:YES];
}

- (IBAction)trashBtnPressed:(id)sender {
    NSLog(@"trashBtnPressed");
}

//- (IBAction)transhpondBtnPressed:(id)sender {
//    NSLog(@"transhpondBtnPressed");
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag;
{
    
}
/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error;
{
    
}

/* AVAudioRecorder INTERRUPTION NOTIFICATIONS ARE DEPRECATED - Use AVAudioSession instead. */

/* audioRecorderBeginInterruption: is called when the audio session has been interrupted while the recorder was recording. The recorded file will be closed. */
- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder NS_DEPRECATED_IOS(2_2, 8_0);
{
    
}
/* audioRecorderEndInterruption:withOptions: is called when the audio session interruption has ended and this recorder had been interrupted while recording. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags NS_DEPRECATED_IOS(6_0, 8_0);
{
    
}
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withFlags:(NSUInteger)flags NS_DEPRECATED_IOS(4_0, 6_0);
{
    
}
/* audioRecorderEndInterruption: is called when the preferred method, audioRecorderEndInterruption:withFlags:, is not implemented. */
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder NS_DEPRECATED_IOS(2_2, 6_0);
{
    
}
@end
