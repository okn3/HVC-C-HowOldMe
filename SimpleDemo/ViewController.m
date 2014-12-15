/*
 * Copyright (C) 2014 OMRON Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
//  ViewController.m
//  SimpleDemo
//

#import "ViewController.h"

@interface ViewController ()
{
    int Status;
    HVC_FUNCTION ExecuteFlag;
}
@property HVC_BLE *HvcBLE;

@end

@implementation ViewController

@synthesize HvcBLE = _HvcBLE;

- (void)viewDidLoad {
    Status = 0;
    ExecuteFlag = 0;
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.HvcBLE = [[HVC_BLE alloc] init];
    self.HvcBLE.delegateHVC = self;
    
    _ResultTextView.text = @"";
    
    //状況画像を非表示
    self.infomation.hidden = YES;
    self.wave.hidden = YES;
    
    //BGMの準備
    CFBundleRef mainBundle;
    mainBundle = CFBundleGetMainBundle ();
    soundURL  = CFBundleCopyResourceURL (mainBundle,CFSTR ("pi"),CFSTR ("mp3"),NULL);
    AudioServicesCreateSystemSoundID (soundURL, &soundID);
     CFRelease (soundURL);
    
    soundURL2  = CFBundleCopyResourceURL (mainBundle,CFSTR ("start"),CFSTR ("mp3"),NULL);
    AudioServicesCreateSystemSoundID (soundURL2, &soundID2);
    CFRelease (soundURL2);
   
    soundURL3  = CFBundleCopyResourceURL (mainBundle,CFSTR ("result"),CFSTR ("mp3"),NULL);
    AudioServicesCreateSystemSoundID (soundURL3, &soundID3);
    CFRelease (soundURL3);

//    CFRelease (soundURL);
//    AudioServicesPlaySystemSound (soundID);
    

  }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)pushButton:(UIButton *)sender {
    // 効果音再生
    AudioServicesPlaySystemSound (soundID);
    switch ( Status )
    {
        case 0:
            // disconnect -> connect
            [self.HvcBLE deviceSearch];
            [self.pushbutton setTitle:@"disconnect" forState:UIControlStateNormal ];
            Status = 1;
            break;
        case 1:
            // connect -> disconnect
            [self.HvcBLE disconnect];
            [self.pushbutton setTitle:@"connect" forState:UIControlStateNormal];
            Status = 0;
            return;
        case 2:
            self.wave.hidden = NO;
            self.infomation.hidden = NO;
            self.infomation.text = @"Let's Start";
            return;
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for (int i=0; i<3; i++) { //デフォルトは10
            sleep(1);
        }
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    //dispatch_release(semaphore);
    
    //バイブレーション
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    // アラートを作る
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"デバイス接続"
                                              message:@"選択してください"
                                              delegate:self
                                              cancelButtonTitle:@"cancel"
                                              otherButtonTitles:nil];
    
    NSMutableArray *deviseList = [self.HvcBLE getDevices];
    for( int i = 0; i < deviseList.count; i++ )
    {
        NSString *name = ((CBPeripheral *)deviseList[i]).name;
        [alert addButtonWithTitle:name];
    }
    
    // アラートを表示する
    [alert show];
}

// アラートの処理（デリゲートメソッド）
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //結果アラートの処理
    if (alertView.tag == 1){
        //初期化
        count = 0;
        age_sum = 0;
        gender_sum = 0;
//        switch (buttonIndex) {
//            case 0:
//                //もう一度
//                Status = 2;
//                [self.btnExecution setTitle:@"stop" forState:UIControlStateNormal];
//                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); //バイブレーション
//                self.infomation.text = @"Scanning";
//                AudioServicesPlaySystemSound (soundID2); // 効果音再生
//                break;
//            case 1:
//                //やめる
                [self.btnExecution setTitle:@"start" forState:UIControlStateNormal];
                self.infomation.text = @"wait";
                Status = 1;
//                break;
//        }

    }else{
    // 効果音再生
//    AudioServicesPlaySystemSound (soundID);
    
    if (buttonIndex == 0) {
        // キャンセルボタン
        NSLog(@"キャンセルされました");
        [self.pushbutton setTitle:@"connect" forState:UIControlStateNormal];
        Status = 0;
    } else {
        NSMutableArray *deviseList = [self.HvcBLE getDevices];
        [self.HvcBLE connect:deviseList[buttonIndex-1]];
        [self.pushbutton setTitle:@"disconnect" forState:UIControlStateNormal];
        Status = 1;
    }
    }
}


// 実行ボタンを押したら
- (IBAction)btnExecute_click:(UIButton *)sender {

    switch ( Status )
    {
        case 0:
            return;
        case 1:
            [self.btnExecution setTitle:@"stop" forState:UIControlStateNormal];
            Status = 2;
            self.infomation.text = @"Scanning";
            // 効果音再生
            AudioServicesPlaySystemSound (soundID2);
            break;
        case 2:
            [self.btnExecution setTitle:@"start" forState:UIControlStateNormal];
            Status = 1;
            return;
    }
    
    HVC_PRM *param = [[HVC_PRM alloc] init];
    param.face.MinSize = 60;
    param.face.MaxSize = 480;
    
    [self.HvcBLE setParam:param];
}

- (void)onConnected
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connected" message:nil
                                                   delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
    //画像を表示
    self.wave.hidden = NO;
    self.infomation.hidden = NO;
    self.infomation.text = @"wait";
    
}
- (void)onDisconnected
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Disconnected" message:nil
                                                   delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
    //画像を非表示
    self.wave.hidden = YES;
    self.infomation.hidden = YES;
}
- (void)onPostGetDeviceName:(NSData *)value
{
    
}

- (void)onPostSetParam:(HVC_ERRORCODE)err status:(unsigned char)outStatus
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // 各フラグ参照
        ExecuteFlag = HVC_ACTIV_BODY_DETECTION | HVC_ACTIV_HAND_DETECTION | HVC_ACTIV_FACE_DETECTION
                        | HVC_ACTIV_FACE_DIRECTION | HVC_ACTIV_AGE_ESTIMATION | HVC_ACTIV_GENDER_ESTIMATION
                        | HVC_ACTIV_GAZE_ESTIMATION | HVC_ACTIV_BLINK_ESTIMATION | HVC_ACTIV_EXPRESSION_ESTIMATION;
        
        HVC_RES *res = [[HVC_RES alloc] init];
        [self.HvcBLE Execute:ExecuteFlag result:res];
    });
}
- (void)onPostGetParam:(HVC_PRM *)param errcode:(HVC_ERRORCODE)err status:(unsigned char)outStatus
{
    
}
- (void)onPostGetVersion:(HVC_VER *)ver errcode:(HVC_ERRORCODE)err status:(unsigned char)outStatus
{
    
}



//変数宣言
int count = 0;
int age_sum = 0;
int age_ave;
int gender_sum;
int gender_cal;
NSString *result_gender;
int cof_sum;
NSString *niteruhito;

//表示する芸能人orキャラを設定
NSString *convert_man[] = {
            @"??",@"??",@"??",@"フグ田タラオ",@"??",@"野原しんのすけ",@"??",@"江戸川コナン",@"??",@"サトシ(ポケモン)", //0-9
            @"野比のび太",@"磯野カツオ",@"??",@"越前リョーマ(テニスの王子様)",@"碇シンジ(エヴァンゲリオン)",@"手塚国光(テニスの王子様)",@"桜木花道(スラムダンク)",@"武藤遊戯(遊戯王)",@"夜神月(デスノート)",@"ゾロ(ワンピース)", //10-19
            @"羽生結弦",@"福士蒼汰",@"鬼塚英吉(GTO)",@"石川 遼",@"三浦春馬",@"錦織圭",@"斎藤佑樹",@"手越祐也（NEWS）",@"本田圭佑",@"山下智久", //20-29
            @"水嶋 ヒロ",@"松本 潤(嵐)",@"狩野 英孝",@"杉浦 太陽",@"ロナウジーニョ",@"堂本 光一",@"DAIGO",@" 猫 ひろし",@"オダギリジョー",@"さかなクン", //30-39
            @"反町 隆史",@"GACKT",@"木村 拓哉",@"西島 秀俊",@"西川 貴教(T.M.R)",@"福山雅治",@"織田 裕二",@"松岡 修造",@"長嶋 一茂",@"稲葉浩志", //40-49
            @"堤 真一",@"リリー・フランキー",@"布袋 寅泰",@" 哀川 翔",@"真田 広之",@"京本 政樹",@"陣内 孝則",@"孫 正義",@"桑田 佳祐",@"郷 ひろみ", //50-59
            @"??",@"??",@"??",@"??",@"??",@"??",@"??",@"??",@"??",@"??", //60-69
                          };

NSString *convert_woman[] = {
            @"??",@"??",@"??",@"??",@"??",@"??",@"??",@"アルプスの少女ハイジ",@"??",@"磯野ワカメ", //0-9
            @"荻野千尋(千と千尋の神隠し)",@"キキ(魔女の宅急便)",@"??",@"??",@"綾波レイ",@"大橋 のぞみ",@"初音ミク",@"松井珠理奈",@"佐々木彩夏（ももいろクローバーZ）",@"玉井詩織（ももいろクローバーZ)", //10-19
            @"渡辺麻友",@"きゃりーぱみゅぱみゅ",@"トリンドル玲奈",@"北乃きい",@"ローラ",@"桐谷美玲",@"佐々木希",@"井上真央",@"レディー・ガガ",@"宮崎あおい", //20-29
            @"皆藤 愛子",@"小倉 優子",@"深田 恭子",@"柴咲 コウ",@"竹内 結子",@"蛯原 友里",@"釈 由美子",@"滝川 クリステル",@"観月 ありさ",@"谷 亮子", //30-39
            @"華原 朋美",@" はしの えみ",@"高橋 尚子",@"藤原 紀香",@"工藤 静香",@"大黒 摩季",@"菊池 桃子",@"江角 マキコ",@"村上 里佳子",@"中森 明菜", //40-49
            @"??",@"??",@"??",@"??",@"黒木 瞳",@"山口 百恵",@"久本 雅美",@"天童 よしみ",@"浅田 美代子",@"アグネス・チャン", //50-59
            @"??",@"??",@"??",@"??",@"??",@"??",@"??",@"??",@"??",@"??", //60-69
};






-(void) onPostExecute:(HVC_RES *)result errcode:(HVC_ERRORCODE)err status:(unsigned char)outStatus
{
    // 実行結果の受け取り
    NSString *resStr = @"";
    
//    if((err == HVC_NORMAL) && (outStatus == 0)){
        // 人体検出
//        resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"Body Detect = %d\n", result.sizeBody]];
        int i;
    
//        for(i = 0; i < result.sizeBody; i++){
//            DetectionResult *dt = [result body:i];
//            resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Body Detection] : size = %d, ", dt.size]];
//            resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"x = %d, y = %d, ", dt.posX, dt.posY]];
//            resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"conf = %d\n", dt.confidence]];
//        }
        
        // 手検出
//        resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"Hand Detect = %d\n", result.sizeHand]];
//        for(i = 0; i < result.sizeHand; i++){
//            DetectionResult *dt = [result hand:i];
//            resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Hand Detection] : size = %d, ", dt.size]];
//            resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"x = %d, y = %d, ", dt.posX, dt.posY]];
//            resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"conf = %d\n", dt.confidence]];
//        }
        
        // 顔検出と各種推定
//        resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"Face Detect = %d\n", result.sizeFace]];
    
        for(i = 0; i < result.sizeFace; i++){
            FaceResult *fd = [result face:i];

//            // 顔検出
//            if((result.executedFunc & HVC_ACTIV_FACE_DETECTION) != 0){
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Face Detection] : size = %d, ", fd.size]];
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"x = %d, y = %d, ", fd.posX, fd.posY]];
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"conf = %d\n", fd.confidence]];
//            }
            
            // 顔向き推定
//            if((result.executedFunc & HVC_ACTIV_FACE_DIRECTION) != 0){
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Face Direction] : "]];
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"yaw = %d, ", fd.dir.yaw]];
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"pitch = %d, ", fd.dir.pitch]];
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"roll = %d, ", fd.dir.roll]];
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"conf = %d\n", fd.dir.confidence]];
//            }
            
            // 年齢推定
            if((result.executedFunc & HVC_ACTIV_AGE_ESTIMATION) != 0){
                
                //検出途中過程の表示
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [年齢] : "]];
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"%d, 信頼度: %d%%\n", fd.age.age, fd.age.confidence/10]];
                NSLog(@"age,%d" ,fd.age.age);

                //合計
                age_sum += fd.age.age;
            }
            
        
            // 性別推定
            if((result.executedFunc & HVC_ACTIV_GENDER_ESTIMATION) != 0){
                //検出途中過程の表示
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [性別] : "]];
                
                NSString *gender;
                if(fd.gen.gender == HVC_GEN_MALE){
                    gender = @"♂";
                    gender_sum += 1;
                }
                else{
                    gender = @"♀";
                    gender_sum -= 1;
                }
//                //検出途中過程の表示
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"%@, 信頼度: %d%%\n", gender, fd.gen.confidence/10]];
            }
            
            count +=1;

            NSLog(@"detect count : %d",count);
            
            if (count % 2 == 1) {
                 self.infomation.text = @"Scanning.";
            }else{
                 self.infomation.text = @"Scanning..";
            }

            
            //結果出力
            if (count == 3) {
                //平均の算出
                age_ave = age_sum/count;
                gender_cal = abs(gender_sum)*20;
                
                if (gender_sum > 0) {
                    result_gender = @"男性";
                    niteruhito = convert_man[age_ave];
                }else{
                    result_gender = @"女";
                    niteruhito = convert_woman[age_ave];
                }
                
                NSLog(@"===============================END==============================");
                NSLog(@"===============================END==============================");
                NSLog(@"平均年齢 : %d",age_ave );
                NSLog(@"性別 : %d",gender_sum );
                NSLog(@"似ている人物 : %@", niteruhito);
                NSLog(@"===============================END==============================");
                NSLog(@"===============================END==============================");

                self.infomation.text = @"Complate";
                
                NSString *msg_age = [NSString stringWithFormat:@"あなたは%@と同じ年齢に見えます。",niteruhito]; //計算が適当
                
                // アラートビューを作成
                // キャンセルボタンを表示しない場合はcancelButtonTitleにnilを指定
                UIAlertView *alert_result = [[UIAlertView alloc]
                                             initWithTitle:@"診断結果"
                                             message:msg_age
                                             delegate:self
                                             cancelButtonTitle:nil
                                             otherButtonTitles:@"OK", nil];
                alert_result.tag = 1;
                [alert_result show];
                //バイブレーション
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                // 効果音再生
                AudioServicesPlaySystemSound (soundID3);
                

                //データ初期化
                Status = 1;
            }
        }
    
    
            // 視線推定
//            if((result.executedFunc & HVC_ACTIV_GAZE_ESTIMATION) != 0){
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Gaze Estimation] : "]];
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"LR = %d, UD = %d\n", fd.gaze.gazeLR, fd.gaze.gazeUD]];
//            }
            
            // 目つむり推定
//            if((result.executedFunc & HVC_ACTIV_BLINK_ESTIMATION) != 0){
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Blink Estimation] : "]];
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"ratioL = %d, ratioR = %d\n", fd.blink.ratioL, fd.blink.ratioR]];
//            }
            
            // 表情推定
//            if((result.executedFunc & HVC_ACTIV_EXPRESSION_ESTIMATION) != 0){
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Expression Estimation] : "]];
//                
//                NSString *expression;
//                switch(fd.exp.expression){
//                    case HVC_EX_NEUTRAL:
//                        expression = @"Neutral";
//                        break;
//                    case HVC_EX_HAPPINESS:
//                        expression = @"Happiness";
//                        break;
//                    case HVC_EX_SURPRISE:
//                        expression = @"Surprise";
//                        break;
//                    case HVC_EX_ANGER:
//                        expression = @"Anger";
//                        break;
//                    case HVC_EX_SADNESS:
//                        expression = @"Sadness";
//                        break;
//                }
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"expression = %@, ", expression]];
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"score = %d, ", fd.exp.score]];
//                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"degree = %d\n", fd.exp.degree]];
//            }
//        }
//    }
      _ResultTextView.text = resStr;

    if ( Status == 2 ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.HvcBLE Execute:ExecuteFlag result:result];
        });
    }
    
    
    
}
@end
