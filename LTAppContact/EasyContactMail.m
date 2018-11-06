//
//  EasyContactMail.m
//  EasyContact
//
//  Created by Ofir Malachi on 29/10/2018.
//  Copyright © 2018 www.LegoTechApps.com. All rights reserved.
//

#import "EasyContactMail.h"
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>


//#ifndef EasyContactLocalizedString
//#define EasyContactLocalizedString(key) \
//NSLocalizedStringFromTableInBundle(key, @"Root", [NSBundle bundleWithURL:[[EasyContactMail frameworkBundle] URLForResource:@"EasyContact" withExtension:@"bundle"]], nil)
//#endif
//Root to EasyContact
#ifndef EasyContactLocalizedString
#define EasyContactLocalizedString(key) \
NSLocalizedStringFromTableInBundle(key,@"Root", [NSBundle bundleWithPath:[[[EasyContactMail frameworkBundle] resourcePath] stringByAppendingPathComponent:@"EasyContact.bundle"]], nil)
#endif

/* was
 #ifndef NSDateTimeAgoLocalizedStrings
 #define NSDateTimeAgoLocalizedStrings(key) \
 NSLocalizedStringFromTableInBundle(key, @"NSDateTimeAgo", [NSBundle bundleWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"NSDateTimeAgo.bundle"]], nil)
 #endif
 */

//#ifndef NSDateTimeAgoLocalizedStrings
//#define NSDateTimeAgoLocalizedStrings(key) \
//NSLocalizedStringFromTableInBundle(key, @"NSDateTimeAgo", [NSBundle bundleWithPath:[[[LTClient frameworkBundle] resourcePath] stringByAppendingPathComponent:@"NSDateTimeAgo.bundle"]], nil)
//#endif


//NSLocalizedStringFromTableInBundle(key, @"Root", [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"EasyContact" withExtension:@"bundle"]], nil)

typedef enum : NSUInteger {
    EasyContactTypeReportABug,
    EasyContactTypeFeedback,
    EasyContactTypeContact,
} EasyContactType;

typedef enum : NSUInteger {
    EasyContactAlertTypeNon,
    EasyContactAlertTypeCannotSendEMail,
    //EasyContactAlertType,
} EasyContactAlertType;

static EasyContactMail *easy = nil;
@interface EasyContactMail () <MFMailComposeViewControllerDelegate,MFMessageComposeViewControllerDelegate,UINavigationControllerDelegate>
@property (strong) NSMutableSet * types;
@property (strong) NSString* reportEmailAddress;
@property (strong) NSString* feedbackEmailAddress;
@property (strong) NSString* otherEmailAddress;
@property (strong) id sender;
@property (strong) NSString* messageBody;

@end

@implementation EasyContactMail

+ (NSBundle *)frameworkBundle   {
    static NSBundle* frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        frameworkBundle = [NSBundle bundleForClass:[self class]];
    });
    
    //NSLog(@"frameworkBundle %@",frameworkBundle);
    return frameworkBundle;
}
//NSBundle* bundle = [NSBundle bundleWithURL:[[LTClient LTCLientBundle] URLForResource:@"Resources" withExtension:@"bundle"]];


+(instancetype)shared {
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        easy = [[self alloc] init];
        easy.types = [[NSMutableSet alloc]init];
    });
    return easy;
}

+(void)setReport:(NSString* _Nullable)reportEmailAddress
Feedback:(NSString* _Nullable)feedbackEmailAddress
other:(NSString* _Nullable)contactEmailAddress{
    [EasyContactMail shared];
    easy.reportEmailAddress = reportEmailAddress;
    easy.feedbackEmailAddress = feedbackEmailAddress;
    easy.otherEmailAddress = contactEmailAddress;
    if(easy.reportEmailAddress) [easy.types addObject:[NSNumber numberWithInteger:EasyContactTypeReportABug]];
    else [easy.types removeObject:[NSNumber numberWithInteger:EasyContactTypeReportABug]];
    if(easy.feedbackEmailAddress) [easy.types addObject:[NSNumber numberWithInteger:EasyContactTypeFeedback]];
    else [easy.types removeObject:[NSNumber numberWithInteger:EasyContactTypeFeedback]];
    if(easy.otherEmailAddress) [easy.types addObject:[NSNumber numberWithInteger:EasyContactTypeContact]];
    else [easy.types removeObject:[NSNumber numberWithInteger:EasyContactTypeContact]];
}

+(void)presentFrom:(UIViewController*)sender messageBody:(NSString* _Nullable)messageBody{
    easy.sender = sender;
    easy.messageBody = messageBody;
    if(!easy){
        //ofir delegates..
        NSLog(@"missing email addresses, please call '[EasyContactMail setReport:reportEmailAddress' first.");
        return;
    }
    
    if (![MFMailComposeViewController canSendMail]) {
        //ofir delegates..
        [EasyContactMail showAlert:EasyContactAlertTypeCannotSendEMail];
        return;
    }
    if(easy.types.count == 1){ //exlpenation: thats skip email selection list...
        EasyContactType type = [[[easy.types allObjects] firstObject] integerValue];
        [EasyContactMail openMailType:type];
        return;
    }
    
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[EasyContactMail title]
                                                                             message:[EasyContactMail subtitle]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[EasyContactMail cancel] style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //ofir delegates..
        
    }];
    UIAlertAction *reportAction = [UIAlertAction actionWithTitle:[EasyContactMail report] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [EasyContactMail openMailType:EasyContactTypeReportABug];
    }];
    
    UIAlertAction *feedbackAction = [UIAlertAction actionWithTitle:[EasyContactMail feedback] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [EasyContactMail openMailType:EasyContactTypeFeedback];
    }];
    
    UIAlertAction *otherAction = [UIAlertAction actionWithTitle:[EasyContactMail other] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [EasyContactMail openMailType:EasyContactTypeContact];
    }];
    
    if(easy.reportEmailAddress){
        [alertController addAction:reportAction];
    }
    if(easy.feedbackEmailAddress){
        [alertController addAction:feedbackAction];
    }
    if(easy.otherEmailAddress){
        [alertController addAction:otherAction];
    }
    
    [alertController addAction:cancelAction];
    [easy.sender presentViewController:alertController animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    // Check the result or perform other tasks.
    
    // Dismiss the mail compose view controller.
    if(error){
        // [FlurryManager compose:self.file];
    }
    [easy.sender dismissViewControllerAnimated:YES completion:nil];
    
}

+(void)openMailType:(EasyContactType)type{
    
    //ofir delegates.. did openn
    NSString * subject;
    NSString * address;
    switch (type) {
        case EasyContactTypeReportABug:{
            subject = [NSString stringWithFormat:@"%@: %@",[EasyContactMail CFBundleDisplayName],[EasyContactLocalizedString(@"report.a.bug") capitalizedString]];
            address = easy.reportEmailAddress;
            break;
        }
        case EasyContactTypeFeedback:{
            subject = [NSString stringWithFormat:@"%@: %@",[EasyContactMail CFBundleDisplayName],[EasyContactLocalizedString(@"feedback")capitalizedString]];
            address = easy.feedbackEmailAddress;
            break;
        }
        case EasyContactTypeContact:{
            subject = [NSString stringWithFormat:@"%@: %@",[EasyContactMail CFBundleDisplayName],[EasyContactLocalizedString(@"contact")capitalizedString]];
            address = easy.otherEmailAddress;
            break;
        }
            
        default:
            break;
    }
    MFMailComposeViewController* composeVC = [[MFMailComposeViewController alloc] init];
    composeVC.mailComposeDelegate = easy;
    [composeVC setToRecipients:@[address]];
    [composeVC setSubject:subject];
    if(easy.messageBody){
        [composeVC setMessageBody:easy.messageBody isHTML:NO];
    }
    
    
    [easy.sender presentViewController:composeVC animated:YES completion:^{
        
    }];
}




+(NSString*)title{
    return nil;
    NSString * string = EasyContactLocalizedString(@"title.subtitle");
    return [NSString stringWithFormat:@"%@",[string capitalizedString]];
}
+(NSString*)subtitle{
    NSString * string = [NSString stringWithFormat:@"%@ %@",EasyContactLocalizedString(@"title.title"),[EasyContactMail CFBundleDisplayName]];
    return [NSString stringWithFormat:@"%@",[string capitalizedString]];
}
+(NSString*)cancel{
    NSString * string = EasyContactLocalizedString(@"title.cancel");
    return [NSString stringWithFormat:@"%@",[string capitalizedString]];
}
+(NSString*)close{
    NSString * string = EasyContactLocalizedString(@"btn.close");
    return [NSString stringWithFormat:@"%@:",[string capitalizedString]];
}
+(NSString*)report{
    NSString * string = EasyContactLocalizedString(@"report.a.bug");
    return [NSString stringWithFormat:@"%@",[string capitalizedString]];
}
+(NSString*)feedback{
    NSString * string = EasyContactLocalizedString(@"title.feedback");
    return [NSString stringWithFormat:@"%@",[string capitalizedString]];
}
+(NSString*)other{
    NSString * string = EasyContactLocalizedString(@"title.other");
    return [NSString stringWithFormat:@"%@",[string capitalizedString]];
}

+(NSString*)CFBundleDisplayName{
    NSString *CFBundleDisplayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    return CFBundleDisplayName;
}
+(void)showAlert:(EasyContactAlertType)type{
    
    NSString * title = @"";
    NSString * message = @"";
    NSString * close = [EasyContactMail close];
    switch (type) {
        case EasyContactAlertTypeCannotSendEMail:{
            title = EasyContactLocalizedString(@"mail.services.are.not.available");  //loclize
            break;
        }
        default:
            break;
    }
    
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:close style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //delegate
    }];
    
    [alertController addAction:cancelAction];
    [easy.sender presentViewController:alertController animated:YES completion:nil];
}

- (void)messageComposeViewController:(nonnull MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    //ofir delegate
    //    MessageComposeResultCancelled,
    //    MessageComposeResultSent,
    //    MessageComposeResultFailed
}
@end


