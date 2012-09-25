//
// Copyright 2009-2011 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Three20Style/TTStyledTextParser.h"

// Style
#import "Three20Style/TTStyledElement.h"
#import "Three20Style/TTStyledTextNode.h"
#import "Three20Style/TTStyledInline.h"
#import "Three20Style/TTStyledBlock.h"
#import "Three20Style/TTStyledLineBreakNode.h"
#import "Three20Style/TTStyledBoldNode.h"
#import "Three20Style/TTStyledButtonNode.h"
#import "Three20Style/TTStyledLinkNode.h"
#import "Three20Style/TTStyledItalicNode.h"
#import "Three20Style/TTStyledImageNode.h"

// Core
#import "Three20Core/TTCorePreprocessorMacros.h"
#import "Three20Core/TTDebug.h"


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTStyledTextParser

@synthesize rootNode        = _rootNode;
@synthesize parseLineBreaks = _parseLineBreaks;
@synthesize parseURLs       = _parseURLs;


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  TT_RELEASE_SAFELY(_rootNode);
  TT_RELEASE_SAFELY(_chars);
  TT_RELEASE_SAFELY(_stack);

  [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)addNode:(TTStyledNode*)node {
  if (!_rootNode) {
    _rootNode = [node retain];
    _lastNode = node;

  } else if (_topElement) {
    [_topElement addChild:node];

  } else {
    _lastNode.nextSibling = node;
    _lastNode = node;
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)pushNode:(TTStyledElement*)element {
  if (!_stack) {
    _stack = [[NSMutableArray alloc] init];
  }

  [self addNode:element];
  [_stack addObject:element];
  _topElement = element;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)popNode {
  TTStyledElement* element = [_stack lastObject];
  if (element) {
    [_stack removeLastObject];
  }

  _topElement = [_stack lastObject];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)flushCharacters {
  if (_chars.length) {
    [self parseText:_chars];
  }

  TT_RELEASE_SAFELY(_chars);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parseURLs:(NSString*)string {
  NSInteger stringIndex = 0;

  while (stringIndex < string.length) {
    NSRange searchRange = NSMakeRange(stringIndex, string.length - stringIndex);
    NSRange httpRange = [string rangeOfString:@"http://" options:NSCaseInsensitiveSearch
                                range:searchRange];
    NSRange httpsRange = [string rangeOfString:@"https://" options:NSCaseInsensitiveSearch
                                 range:searchRange];

    NSRange startRange;
    if (httpRange.location == NSNotFound) {
        startRange = httpsRange;

    } else if (httpsRange.location == NSNotFound) {
        startRange = httpRange;

    } else {
        startRange = (httpRange.location < httpsRange.location) ? httpRange : httpsRange;
    }

    if (startRange.location == NSNotFound) {
      NSString* text = [string substringWithRange:searchRange];
      TTStyledTextNode* node = [[[TTStyledTextNode alloc] initWithText:text] autorelease];
      [self addNode:node];
      break;

    } else {
      NSRange beforeRange = NSMakeRange(searchRange.location,
        startRange.location - searchRange.location);
      if (beforeRange.length) {
        NSString* text = [string substringWithRange:beforeRange];
        TTStyledTextNode* node = [[[TTStyledTextNode alloc] initWithText:text] autorelease];
        [self addNode:node];
      }

      NSRange subSearchRange = NSMakeRange(startRange.location,
                                           string.length - startRange.location);
      NSRange endRange = [string rangeOfString:@" " options:NSCaseInsensitiveSearch
                                 range:subSearchRange];
      if (endRange.location == NSNotFound) {
        NSString* URL = [string substringWithRange:subSearchRange];
        TTStyledLinkNode* node = [[[TTStyledLinkNode alloc] initWithText:URL] autorelease];
        node.URL = URL;
        [self addNode:node];
        break;

      } else {
        NSRange URLRange = NSMakeRange(startRange.location,
                                             endRange.location - startRange.location);
        NSString* URL = [string substringWithRange:URLRange];
        TTStyledLinkNode* node = [[[TTStyledLinkNode alloc] initWithText:URL] autorelease];
        node.URL = URL;
        [self addNode:node];
        stringIndex = endRange.location;
      }
    }
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSString *)stringFromInt:(unichar)unicodeValue
{
	return [NSString stringWithCharacters:&unicodeValue length:1];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSString *)stringFromEntity:(NSString *)entityName
{
	static NSDictionary * entities = nil;

	if (entities == nil) {
		entities = [NSDictionary dictionaryWithObjectsAndKeys:
                //markup-significant and internationalization characters
                [self stringFromInt:34], @"quot",
                [self stringFromInt:38], @"amp",
                [self stringFromInt:39], @"apos",
                [self stringFromInt:60], @"lt",
                [self stringFromInt:62], @"gt",
                [self stringFromInt:338], @"OElig",
                [self stringFromInt:339], @"oelig",
                [self stringFromInt:352], @"Scaron",
                [self stringFromInt:353], @"scaron",
                [self stringFromInt:376], @"Yuml",
                [self stringFromInt:710], @"circ",
                [self stringFromInt:732], @"tilde",
                [self stringFromInt:8194], @"ensp",
                [self stringFromInt:8195], @"emsp",
                [self stringFromInt:8201], @"thinsp",
                [self stringFromInt:8204], @"zwnj",
                [self stringFromInt:8205], @"zwj",
                [self stringFromInt:8206], @"lrm",
                [self stringFromInt:8207], @"rlm",
                [self stringFromInt:8211], @"ndash",
                [self stringFromInt:8212], @"mdash",
                [self stringFromInt:8212], @"emdash", //not valid entity, be we accept it anyway
                [self stringFromInt:8216], @"lsquo",
                [self stringFromInt:8217], @"rsquo",
                [self stringFromInt:8218], @"sbquo",
                [self stringFromInt:8220], @"ldquo",
                [self stringFromInt:8221], @"rdquo",
                [self stringFromInt:8222], @"bdquo",
                [self stringFromInt:8224], @"dagger",
                [self stringFromInt:8225], @"Dagger",
                [self stringFromInt:8240], @"permil",
                [self stringFromInt:8249], @"lsaquo",
                [self stringFromInt:8250], @"rsaquo",
                [self stringFromInt:8364], @"euro",

                //ISO 8859-1 characters
                [self stringFromInt:160]	,@"nbsp",
                [self stringFromInt:161]	,@"iexcl",
                [self stringFromInt:162]	,@"cent",
                [self stringFromInt:163]	,@"pound",
                [self stringFromInt:164]	,@"curren",
                [self stringFromInt:165]	,@"yen",
                [self stringFromInt:166]	,@"brvbar",
                [self stringFromInt:167]	,@"sect",
                [self stringFromInt:168]	,@"uml",
                [self stringFromInt:169]	,@"copy",
                [self stringFromInt:170]	,@"ordf",
                [self stringFromInt:171]	,@"laquo",
                [self stringFromInt:172]	,@"not",
                [self stringFromInt:173]	,@"shy",
                [self stringFromInt:174]	,@"reg",
                [self stringFromInt:175]	,@"macr",
                [self stringFromInt:176]	,@"deg",
                [self stringFromInt:177]	,@"plusmn",
                [self stringFromInt:178]	,@"sup2",
                [self stringFromInt:179]	,@"sup3",
                [self stringFromInt:180]	,@"acute",
                [self stringFromInt:181]	,@"micro",
                [self stringFromInt:182]	,@"para",
                [self stringFromInt:183]	,@"middot",
                [self stringFromInt:184]	,@"cedil",
                [self stringFromInt:185]	,@"sup1",
                [self stringFromInt:186]	,@"ordm",
                [self stringFromInt:187]	,@"raquo",
                [self stringFromInt:188]	,@"frac14",
                [self stringFromInt:189]	,@"frac12",
                [self stringFromInt:190]	,@"frac34",
                [self stringFromInt:191]	,@"iquest",
                [self stringFromInt:192]	,@"Agrave",
                [self stringFromInt:193]	,@"Aacute",
                [self stringFromInt:194]	,@"Acirc",
                [self stringFromInt:195]	,@"Atilde",
                [self stringFromInt:196]	,@"Auml",
                [self stringFromInt:197]	,@"Aring",
                [self stringFromInt:198]	,@"AElig",
                [self stringFromInt:199]	,@"Ccedil",
                [self stringFromInt:200]	,@"Egrave",
                [self stringFromInt:201]	,@"Eacute",
                [self stringFromInt:202]	,@"Ecirc",
                [self stringFromInt:203]	,@"Euml",
                [self stringFromInt:204]	,@"Igrave",
                [self stringFromInt:205]	,@"Iacute",
                [self stringFromInt:206]	,@"Icirc",
                [self stringFromInt:207]	,@"Iuml",
                [self stringFromInt:208]	,@"ETH",
                [self stringFromInt:209]	,@"Ntilde",
                [self stringFromInt:210]	,@"Ograve",
                [self stringFromInt:211]	,@"Oacute",
                [self stringFromInt:212]	,@"Ocirc",
                [self stringFromInt:213]	,@"Otilde",
                [self stringFromInt:214]	,@"Ouml",
                [self stringFromInt:215]	,@"times",
                [self stringFromInt:216]	,@"Oslash",
                [self stringFromInt:217]	,@"Ugrave",
                [self stringFromInt:218]	,@"Uacute",
                [self stringFromInt:219]	,@"Ucirc",
                [self stringFromInt:220]	,@"Uuml",
                [self stringFromInt:221]	,@"Yacute",
                [self stringFromInt:222]	,@"THORN",
                [self stringFromInt:223]	,@"szlig",
                [self stringFromInt:224]	,@"agrave",
                [self stringFromInt:225]	,@"aacute",
                [self stringFromInt:226]	,@"acirc",
                [self stringFromInt:227]	,@"atilde",
                [self stringFromInt:228]	,@"auml",
                [self stringFromInt:229]	,@"aring",
                [self stringFromInt:230]	,@"aelig",
                [self stringFromInt:231]	,@"ccedil",
                [self stringFromInt:232]	,@"egrave",
                [self stringFromInt:233]	,@"eacute",
                [self stringFromInt:234]	,@"ecirc",
                [self stringFromInt:235]	,@"euml",
                [self stringFromInt:236]	,@"igrave",
                [self stringFromInt:237]	,@"iacute",
                [self stringFromInt:238]	,@"icirc",
                [self stringFromInt:239]	,@"iuml",
                [self stringFromInt:240]	,@"eth",
                [self stringFromInt:241]	,@"ntilde",
                [self stringFromInt:242]	,@"ograve",
                [self stringFromInt:243]	,@"oacute",
                [self stringFromInt:244]	,@"ocirc",
                [self stringFromInt:245]	,@"otilde",
                [self stringFromInt:246]	,@"ouml",
                [self stringFromInt:247]	,@"divide",
                [self stringFromInt:248]	,@"oslash",
                [self stringFromInt:249]	,@"ugrave",
                [self stringFromInt:250]	,@"uacute",
                [self stringFromInt:251]	,@"ucirc",
                [self stringFromInt:252]	,@"uuml",
                [self stringFromInt:253]	,@"yacute",
                [self stringFromInt:254]	,@"thorn",
                [self stringFromInt:255]	,@"yuml",

                //symbols, mathematical symbols, and Greek letters
                [self stringFromInt:402]	,@"fnof",
                [self stringFromInt:913]	,@"Alpha",
                [self stringFromInt:914]	,@"Beta",
                [self stringFromInt:915]	,@"Gamma",
                [self stringFromInt:916]	,@"Delta",
                [self stringFromInt:917]	,@"Epsilon",
                [self stringFromInt:918]	,@"Zeta",
                [self stringFromInt:919]	,@"Eta",
                [self stringFromInt:920]	,@"Theta",
                [self stringFromInt:921]	,@"Iota",
                [self stringFromInt:922]	,@"Kappa",
                [self stringFromInt:923]	,@"Lambda",
                [self stringFromInt:924]	,@"Mu",
                [self stringFromInt:925]	,@"Nu",
                [self stringFromInt:926]	,@"Xi",
                [self stringFromInt:927]	,@"Omicron",
                [self stringFromInt:928]	,@"Pi",
                [self stringFromInt:929]	,@"Rho",
                [self stringFromInt:931]	,@"Sigma",
                [self stringFromInt:932]	,@"Tau",
                [self stringFromInt:933]	,@"Upsilon",
                [self stringFromInt:934]	,@"Phi",
                [self stringFromInt:935]	,@"Chi",
                [self stringFromInt:936]	,@"Psi",
                [self stringFromInt:937]	,@"Omega",
                [self stringFromInt:945]	,@"alpha",
                [self stringFromInt:946]	,@"beta",
                [self stringFromInt:947]	,@"gamma",
                [self stringFromInt:948]	,@"delta",
                [self stringFromInt:949]	,@"epsilon",
                [self stringFromInt:950]	,@"zeta",
                [self stringFromInt:951]	,@"eta",
                [self stringFromInt:952]	,@"theta",
                [self stringFromInt:953]	,@"iota",
                [self stringFromInt:954]	,@"kappa",
                [self stringFromInt:955]	,@"lambda",
                [self stringFromInt:956]	,@"mu",
                [self stringFromInt:957]	,@"nu",
                [self stringFromInt:958]	,@"xi",
                [self stringFromInt:959]	,@"omicron",
                [self stringFromInt:960]	,@"pi",
                [self stringFromInt:961]	,@"rho",
                [self stringFromInt:962]	,@"sigmaf",
                [self stringFromInt:963]	,@"sigma",
                [self stringFromInt:964]	,@"tau",
                [self stringFromInt:965]	,@"upsilon",
                [self stringFromInt:966]	,@"phi",
                [self stringFromInt:967]	,@"chi",
                [self stringFromInt:968]	,@"psi",
                [self stringFromInt:969]	,@"omega",
                [self stringFromInt:977]	,@"thetasym",
                [self stringFromInt:978]	,@"upsih",
                [self stringFromInt:982]	,@"piv",
                [self stringFromInt:8226]	,@"bull",
                [self stringFromInt:8230]	,@"hellip",
                [self stringFromInt:8242]	,@"prime",
                [self stringFromInt:8243]	,@"Prime",
                [self stringFromInt:8254]	,@"oline",
                [self stringFromInt:8260]	,@"frasl",
                [self stringFromInt:8472]	,@"weierp",
                [self stringFromInt:8465]	,@"image",
                [self stringFromInt:8476]	,@"real",
                [self stringFromInt:8482]	,@"trade",
                [self stringFromInt:8501]	,@"alefsym",
                [self stringFromInt:8592]	,@"larr",
                [self stringFromInt:8593]	,@"uarr",
                [self stringFromInt:8594]	,@"rarr",
                [self stringFromInt:8595]	,@"darr",
                [self stringFromInt:8596]	,@"harr",
                [self stringFromInt:8629]	,@"crarr",
                [self stringFromInt:8656]	,@"lArr",
                [self stringFromInt:8657]	,@"uArr",
                [self stringFromInt:8658]	,@"rArr",
                [self stringFromInt:8659]	,@"dArr",
                [self stringFromInt:8660]	,@"hArr",
                [self stringFromInt:8704]	,@"forall",
                [self stringFromInt:8706]	,@"part",
                [self stringFromInt:8707]	,@"exist",
                [self stringFromInt:8709]	,@"empty",
                [self stringFromInt:8711]	,@"nabla",
                [self stringFromInt:8712]	,@"isin",
                [self stringFromInt:8713]	,@"notin",
                [self stringFromInt:8715]	,@"ni",
                [self stringFromInt:8719]	,@"prod",
                [self stringFromInt:8721]	,@"sum",
                [self stringFromInt:8722]	,@"minus",
                [self stringFromInt:8727]	,@"lowast",
                [self stringFromInt:8730]	,@"radic",
                [self stringFromInt:8733]	,@"prop",
                [self stringFromInt:8734]	,@"infin",
                [self stringFromInt:8736]	,@"ang",
                [self stringFromInt:8743]	,@"and",
                [self stringFromInt:8744]	,@"or",
                [self stringFromInt:8745]	,@"cap",
                [self stringFromInt:8746]	,@"cup",
                [self stringFromInt:8747]	,@"int",
                [self stringFromInt:8756]	,@"there4",
                [self stringFromInt:8764]	,@"sim",
                [self stringFromInt:8773]	,@"cong",
                [self stringFromInt:8776]	,@"asymp",
                [self stringFromInt:8800]	,@"ne",
                [self stringFromInt:8801]	,@"equiv",
                [self stringFromInt:8804]	,@"le",
                [self stringFromInt:8805]	,@"ge",
                [self stringFromInt:8834]	,@"sub",
                [self stringFromInt:8835]	,@"sup",
                [self stringFromInt:8836]	,@"nsub",
                [self stringFromInt:8838]	,@"sube",
                [self stringFromInt:8839]	,@"supe",
                [self stringFromInt:8853]	,@"oplus",
                [self stringFromInt:8855]	,@"otimes",
                [self stringFromInt:8869]	,@"perp",
                [self stringFromInt:8901]	,@"sdot",
                [self stringFromInt:8968]	,@"lceil",
                [self stringFromInt:8969]	,@"rceil",
                [self stringFromInt:8970]	,@"lfloor",
                [self stringFromInt:8971]	,@"rfloor",
                [self stringFromInt:9001]	,@"lang",
                [self stringFromInt:9002]	,@"rang",
                [self stringFromInt:9674]	,@"loz",
                [self stringFromInt:9824]	,@"spades",
                [self stringFromInt:9827]	,@"clubs",
                [self stringFromInt:9829]	,@"hearts",
                [self stringFromInt:9830]	,@"diams",
                nil
                ];
		[entities retain];
	}

	NSString *result = [entities objectForKey:[entityName lowercaseString]];
	if (result)
		return result;

	TTDASSERT(false); //an encoding that we don't know how to resolve
	return [NSString stringWithFormat:@"&%@;",entityName];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSXMLParserDelegate


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
    namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
  [self flushCharacters];

  NSString* tag = [elementName lowercaseString];
  if ([tag isEqualToString:@"span"]) {
    TTStyledInline* node = [[[TTStyledInline alloc] init] autorelease];
    node.className =  [attributeDict objectForKey:@"class"];
    [self pushNode:node];

  } else if ([tag isEqualToString:@"br"]) {
    TTStyledLineBreakNode* node = [[[TTStyledLineBreakNode alloc] init] autorelease];
    node.className =  [attributeDict objectForKey:@"class"];
    [self pushNode:node];

  } else if ([tag isEqualToString:@"div"] || [tag isEqualToString:@"p"]) {
    TTStyledBlock* node = [[[TTStyledBlock alloc] init] autorelease];
    node.className =  [attributeDict objectForKey:@"class"];
    [self pushNode:node];

  } else if ([tag isEqualToString:@"b"] || [tag isEqualToString:@"strong"]) {
    TTStyledBoldNode* node = [[[TTStyledBoldNode alloc] init] autorelease];
    [self pushNode:node];

  } else if ([tag isEqualToString:@"i"] || [tag isEqualToString:@"em"]) {
    TTStyledItalicNode* node = [[[TTStyledItalicNode alloc] init] autorelease];
    [self pushNode:node];

  } else if ([tag isEqualToString:@"a"]) {
    TTStyledLinkNode* node = [[[TTStyledLinkNode alloc] init] autorelease];
    node.URL =  [attributeDict objectForKey:@"href"];
    node.className =  [attributeDict objectForKey:@"class"];
    [self pushNode:node];

  } else if ([tag isEqualToString:@"button"]) {
    TTStyledButtonNode* node = [[[TTStyledButtonNode alloc] init] autorelease];
    node.URL =  [attributeDict objectForKey:@"href"];
    [self pushNode:node];

  } else if ([tag isEqualToString:@"img"]) {
    TTStyledImageNode* node = [[[TTStyledImageNode alloc] init] autorelease];
    node.className =  [attributeDict objectForKey:@"class"];
    node.URL =  [attributeDict objectForKey:@"src"];
    NSString* width = [attributeDict objectForKey:@"width"];
    if (width) {
      node.width = width.floatValue;
    }
    NSString* height = [attributeDict objectForKey:@"height"];
    if (height) {
      node.height = height.floatValue;
    }
    [self pushNode:node];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
  if (!_chars) {
    _chars = [string mutableCopy];

  } else {
    [_chars appendString:string];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
    namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
  [self flushCharacters];
  [self popNode];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSData *)          parser:(NSXMLParser *)parser
   resolveExternalEntityName:(NSString *)entityName
                    systemID:(NSString *)systemID {
	NSString *entity = [TTStyledTextParser stringFromEntity:entityName];
	return [entity dataUsingEncoding:NSMacOSRomanStringEncoding];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parseText:(NSString*)string URLs:(BOOL)shouldParseURLs {
  if (shouldParseURLs) {
    [self parseURLs:string];
  }
  else {
    TTStyledTextNode* node = [[[TTStyledTextNode alloc] initWithText:string] autorelease];
    [self addNode:node];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parseXHTML:(NSString*)html {
  NSString* document = [NSString stringWithFormat:@"<x>%@</x>", html];
  NSData* data = [document dataUsingEncoding:html.fastestEncoding];
  NSXMLParser* parser = [[[NSXMLParser alloc] initWithData:data] autorelease];
  parser.delegate = self;
  [parser parse];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parseText:(NSString*)string {
  if (_parseLineBreaks) {
    NSCharacterSet* newLines = [NSCharacterSet newlineCharacterSet];
    NSInteger stringIndex = 0;
    NSInteger length = string.length;

    while (1) {
      NSRange searchRange = NSMakeRange(stringIndex, length - stringIndex);
      NSRange range = [string rangeOfCharacterFromSet:newLines options:0 range:searchRange];
      if (range.location != NSNotFound) {
        // Find all text before the line break and parse it
        NSRange textRange = NSMakeRange(stringIndex, range.location - stringIndex);
        NSString* substr = [string substringWithRange:textRange];
        [self parseText:substr URLs:_parseURLs];

        // Add a line break node after the text
        TTStyledLineBreakNode* br = [[[TTStyledLineBreakNode alloc] init] autorelease];
        [self addNode:br];

        stringIndex = stringIndex + substr.length + 1;

      }
      else {
        // Find all text until the end of hte string and parse it
        NSString* substr = [string substringFromIndex:stringIndex];
        [self parseText:substr URLs:_parseURLs];
        break;
      }
    }

  }
  else {
    [self parseText:string URLs:_parseURLs];
  }
}


@end
