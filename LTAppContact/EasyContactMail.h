//
//  EasyContactMail.h
//  EasyContact
//
//  Created by Ofir Malachi on 29/10/2018.
//  Copyright © 2018 www.LegoTechApps.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EasyContactMail : NSObject
+(void)setReport:(NSString* _Nullable)reportEmailAddress
        Feedback:(NSString* _Nullable)feedbackEmailAddress
           other:(NSString* _Nullable)contactEmailAddress;

+(void)presentFrom:(UIViewController*)sender messageBody:(NSString* _Nullable)messageBody;
@end

NS_ASSUME_NONNULL_END
