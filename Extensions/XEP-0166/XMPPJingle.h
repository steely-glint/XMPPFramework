//
//  XMPPJingle.h
//  PhonoNative
//
//  Created by Tim Panton on 20/12/2011.
//  Copyright (c) 2011 Westhhawk Ltd. All rights reserved.
//

#import "XMPPModule.h"
#import "XMPPFramework.h"

@interface XMPPJingle : XMPPModule
{
    XMPPJID *me;
    NSMutableDictionary *namespaces;
    NSString *payloadAttrFilter;
    BOOL phonoBugs;
}
@property (nonatomic, readonly) XMPPJID *me;
@property (copy, readwrite) NSString *payloadAttrFilter;

- (id)initWithPhono:(BOOL)phonoBugs;
- (NSString *) ptypeWithPayload:(NSXMLElement *)payload;
- (NSString *) ipWithCandidate:(NSXMLElement *) candidate;
- (NSString *) portWithCandidate:(NSXMLElement *) candidate;
- (void) sendSessionAccept:(NSString *)sid to:(NSString *)tos host:(NSString *)host port:(NSString *)port payload:(NSXMLElement*)payload;

@end

@protocol XMPPJingleDelegate <NSObject>
- (void)xmppJingle:(XMPPJingle *)sender didReceiveIncommingAudioCall:(NSString *)sid from:(XMPPJID *)from to:(XMPPJID *)to transport:(NSXMLElement *)candidate sdp:(NSXMLElement *)payload ;


@optional


@end