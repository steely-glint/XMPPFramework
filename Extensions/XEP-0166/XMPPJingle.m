//
//  XMPPJingle.m
//  PhonoNative
//
//  Created by Tim Panton on 20/12/2011.
//  Copyright (c) 2011 Westhhawk Ltd. All rights reserved.
//

#import "XMPPJingle.h"
#define NS_JINGLE          @"urn:xmpp:jingle:1"
#define NS_JINGLE_RTP      @"urn:xmpp:jingle:apps:rtp:1"
#define NS_JINGLE_UDP      @"urn:xmpp:jingle:transports:raw-udp:1"
#define NS_PHONOEMPTY      @""
#define NS_JABBER          @"jabber:client"
#define NS_RTMP            @"http://voxeo.com/gordon/apps/rtmp"
#define NS_RTMPT           @"http://voxeo.com/gordon/transports/rtmp"
#define SERVICEUNAVAIL     @"<error type='cancel'><service-unavailable xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error>"

@implementation XMPPJingle
@synthesize me, payloadAttrFilter ;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)initWithPhono:(BOOL)tphonoBugs
{
	self = [super initWithDispatchQueue:nil];
    namespaces = [[NSMutableDictionary alloc] init];
    [namespaces setObject:NS_JINGLE forKey:@"jingle"];
    [namespaces setObject:NS_JINGLE_RTP forKey:@"rtp"];
    [namespaces setObject:NS_JINGLE_UDP forKey:@"udp"];
    [namespaces setObject:NS_JABBER forKey:@"jabber"];
    phonoBugs = tphonoBugs;

	return self;
}


- (BOOL)activate:(XMPPStream *)aXmppStream
{
	if ([super activate:aXmppStream])
	{
		// Custom code goes here (if needed)
		return YES;
	}
	
	return NO;
}

- (void)deactivate
{
	[super deactivate];
}

- (void)dealloc
{
    // release stuff here
	[super dealloc];
}

- (NSString *) ptypeWithPayload:(NSXMLElement *)payload{
    return [[NSString alloc] initWithFormat:@"%@:%@:%@",
            [payload attributeStringValueForName:@"name"],
            [payload attributeStringValueForName:@"clockrate"],
            [payload attributeStringValueForName:@"id"]];
}
- (NSString *) ipWithCandidate:(NSXMLElement *)candidate{
    return [candidate attributeStringValueForName:@"ip"];
}

- (NSString *) portWithCandidate:(NSXMLElement *)candidate{
    return [candidate attributeStringValueForName:@"port"];
}
- (XMPPIQ *) sendResultAck:(XMPPIQ *) iq{
    /*<iq from='juliet@capulet.lit/balcony'
     id='xs51r0k4'
     to='romeo@montague.lit/orchard'
     type='result'/> */
    
    return [XMPPIQ iqWithType:@"result" to:[iq from] elementID:[iq elementID]];
}

- (XMPPIQ *) sendResultError:(XMPPIQ *) iq because:(NSString *)bs{
    /* <iq from='juliet@capulet.lit/balcony'
     id='xs51r0k4'
     to='romeo@montague.lit/orchard'
     type='error'>
     <error type='cancel'>
     <service-unavailable xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
     </error>
     </iq> */
    NSError *error;
    NSXMLElement * body = [[NSXMLElement alloc] initWithXMLString:bs error:&error ];
    return (error != nil)?nil:[XMPPIQ iqWithType:@"result" to:[iq from] elementID:[iq elementID] child:body];
}

- (NSXMLElement *) jingleBodyWithAction:(NSString *) act sid:(NSString *) sid {
    NSXMLElement * body = [[NSXMLElement alloc] initWithName:@"jingle" xmlns:NS_JINGLE  ];
    [body addAttributeWithName:@"sid" stringValue:sid];
    return body;
}


- (NSArray *) xpns:(NSXMLElement *)d q:(NSString *)q {
    NSError *error;
    if (phonoBugs) {
        q = [q stringByReplacingOccurrencesOfString:@"pjingle:" withString:@""]; 
        q = [q stringByReplacingOccurrencesOfString:@"prtp:" withString:@""]; 
        q = [q stringByReplacingOccurrencesOfString:@"pudp:" withString:@""]; 
    } else {
        q = [q stringByReplacingOccurrencesOfString:@"pjingle:" withString:@"jingle:"]; 
        q = [q stringByReplacingOccurrencesOfString:@"prtp:" withString:@"rtp:"]; 
        q = [q stringByReplacingOccurrencesOfString:@"pudp:" withString:@"udp:"];         
    }
    NSArray * ret = [d nodesForXPathWithNamespaces:q namespaces:namespaces error: &error];
    return ret;
}

// find the first thing that the xpath matches
- (NSXMLElement *) xp0:(NSXMLElement *)d q:(NSString *)path{
    NSXMLElement * ret = nil;
    NSArray *a = [self xpns:d q:path];
    if ((a != nil) && ([a count] == 1)){
        ret = [a objectAtIndex:0];
    }
    return ret;
}
// set the value of the attribute the xpath matches
- (void) xp0sa:(NSXMLElement *)d q:(NSString *)path value:(NSString*)val{
    NSXMLElement *a = [self xp0:d q:path];
    [a setStringValue:val];
}

- (NSXMLElement *) mkCandidate:(NSString *)host port:(NSString*)port gen:(NSString *)gen comp:(NSString *)comp {
    NSXMLElement *ca = [NSXMLElement elementWithName:@"candidate"];
    [ca addAttributeWithName:@"ip" stringValue:host ];
    [ca addAttributeWithName:@"port" stringValue:port ];
    [ca addAttributeWithName:@"generation" stringValue:@"0"];
    [ca addAttributeWithName:@"component" stringValue:@"1"];
    return ca;
}

- (void) sendSessionAccept:(NSString *)sid to:(NSString *)tos host:(NSString *)host port:(NSString *)port payload:(NSXMLElement*)payload{
    NSString *template = @"<jingle xmlns=\"urn:xmpp:jingle:1\" action=\"session-accept\" initiator=\"\" sid=\"\">\
       <content creator=\"initiator\">\
        <description xmlns=\"urn:xmpp:jingle:apps:rtp:1\">\
         <payload-type id=\"101\" name=\"telephone-event\" clockrate=\"8000\"/>\
        </description>\
        <transport xmlns=\"urn:xmpp:jingle:transports:raw-udp:1\">\
        </transport>\
       </content>\
      </jingle>";
    NSString *initiator = @"timpanton@sip2sip.info"; // FIX FIX FIX

    NSError *error;
    NSXMLElement * body =[[NSXMLElement alloc] initWithXMLString:template error:&error ];


    
    XMPPJID *to = [XMPPJID jidWithString:tos];
    NSString *elementID =@"123456"; // FIX FIX FIX
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:to  elementID:elementID child:body];

    NSLog(@" before -> %@",[iq XMLString]);
    // now find and set some stuff

    [self xp0sa:iq q:@"/iq/jingle:jingle/@initiator" value:initiator];
    [self xp0sa:iq q:@"/iq/jingle:jingle/@sid" value:sid];
    [[self xp0:iq q:@"/iq/jingle:jingle/jingle:content/rtp:description"] addChild:payload];
    [[self xp0:iq q:@"/iq/jingle:jingle/jingle:content/udp:transport"] 
     addChild:[self mkCandidate:host port:port gen:@"0" comp:@"1"]];

    
    NSLog(@" Send -> %@",[iq XMLString]);
    
    [xmppStream sendElement:iq]; 
}


- (XMPPIQ *) didRecvSessionInitiate:(XMPPStream *)sender iq:(XMPPIQ *)iq {
    XMPPIQ * ret = nil;
    /* THis is what old phono sends - note the xmlns="" errors  -we need to cope with them. Sigh.
     hence the faffing with prtp namespace - we rewrite that to being rtp or "" depending on 
     the state of the phonoBugs flag.
     
     <iq xmlns="jabber:client" type="set" from="timpanton\40sip2sip.info@sip" to="e873e415-272b-4e36-8fdc-3ea3d26097e1@phono.com/voxeo" id="08d36f0f-1be4-40f9-9c3f-11e3ca97c6e3">
      <jingle xmlns="urn:xmpp:jingle:1" initiator="timpanton@sip2sip.info" sid="c027b7a5-b464-4cc9-9b9c-351904640dd0" action="session-initiate">
       <content xmlns="">
        <description xmlns="http://voxeo.com/gordon/apps/rtmp" media="audio"><payload-type xmlns="" id="116" name="SPEEX" clockrate="16000"/></description>
        <transport xmlns="http://voxeo.com/gordon/transports/rtmp">
          <candidate xmlns="" rtmpUri="rtmfp://ec2-50-19-77-101.compute-1.amazonaws.com/live" playName="f24eb8d0-e540-4fd2-8f52-fe399dbd50f8" publishName="f5570db8-dbee-4930-b2e4-4c2046efe36e" id="1"/>
        </transport>
        <transport xmlns="urn:xmpp:jingle:transports:raw-udp:1">
          <candidate xmlns="" ip="50.19.77.101" port="20074" id="1" generation="0" component="1"/>
        </transport>
        <description xmlns="urn:xmpp:jingle:apps:rtp:1" media="audio">
         <payload-type xmlns="" id="9" name="G722" clockrate="8000"/>
         <payload-type xmlns="" id="0" name="PCMU" clockrate="8000"/>
         <payload-type xmlns="" id="116" name="SPEEX" clockrate="16000"/>
         <payload-type xmlns="" id="101" name="telephone-event" clockrate="8000"/>
         <payload-type xmlns="" id="115" name="SPEEX" clockrate="8000"/>
        </description>
       </content>
      </jingle>
     </iq>
     */
    
    NSLog(@" got -> %@",[iq XMLString]);


    NSXMLElement *sid = [self xp0:iq q:@"jingle:jingle[@action=\"session-initiate\"]/@sid"];
    NSArray * candidates = [self xpns:iq q:@"jingle:jingle[@action=\"session-initiate\"]/pjingle:content/udp:transport/pudp:candidate"];
    NSXMLElement *candidate = nil;
    if (candidates != nil) {
        for (int i=0; i<[candidates count]; i++){
            NSLog(@"candidate -> %@",[((NSXMLElement *)[candidates objectAtIndex:i]) XMLString]);
            if (candidate == nil){
                candidate = (NSXMLElement *)[candidates objectAtIndex:i];
            }
        }
    } 
    NSXMLElement *payload = nil;
    NSString *xpath = [NSString stringWithFormat:@"jingle:jingle[@action=\"session-initiate\"]/pjingle:content/rtp:description[@media=\"audio\"]/prtp:payload-type%@", payloadAttrFilter];
    
    NSArray * payloads = [self xpns:iq q:xpath];
    if (payloads != nil) {
        for (int i=0; i<[payloads count]; i++){
            NSLog(@"payload -> %@",[((NSXMLElement *)[payloads objectAtIndex:i]) XMLString]);
            if (payload == nil){
                payload = [payloads objectAtIndex:i];
            }
        }
    }       
    
    if ((sid != nil) && (payload != nil) && (candidate != nil)){
        // say we will think about it.
        ret = [self sendResultAck:iq];
        // and tell the user:
        NSString *ssid =[sid stringValue];
        XMPPJID *sfrom = [iq from];
        XMPPJID *sto = [iq to];

        [multicastDelegate xmppJingle:self didReceiveIncommingAudioCall:ssid from:sfrom to:sto transport:candidate sdp:payload ];

    } else {
        // nothing we can understand...
        ret = [self sendResultError:iq because:SERVICEUNAVAIL];
    }


    return ret;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Delegate method to receive incoming IQ stanzas.
 **/
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    /*
     <iq from='juliet@capulet.lit/balcony'
     id='jd82f517'
     to='romeo@montague.lit/orchard'
     type='set'>
     <jingle xmlns='urn:xmpp:jingle:1'
     action='session-accept'
     responder='juliet@capulet.lit/balcony'
     sid='a73sjjvkla37jfea'/> 
     */
    XMPPIQ *rep = nil;
    if ([iq isSetIQ]){
        NSString *to = [iq toStr];
        NSString *from = [iq fromStr];
        NSXMLElement * jingle  = [iq elementForName:@"jingle" xmlns:NS_JINGLE];
        if (jingle != nil) {
            NSString *action = [jingle attributeStringValueForName:@"action"];
            NSLog(@"jingle action %@ from %@ to %@",action,from,to );
            if ([action compare:@"session-initiate"] == NSOrderedSame ){
                rep = [self didRecvSessionInitiate:sender iq:iq];
            }
            // say what we have to say....
            if (rep != nil) {
                [sender sendElement:rep];
            }
        }
	}
	return (rep != nil);
}
@end
