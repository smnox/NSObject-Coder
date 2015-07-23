//
//  NSObject+Archive.h
//
//  Created by echen on 14/07/2015.
//  This category encodes/decodes all object properties by using property names as encode/decode keys
//

#import <Foundation/Foundation.h>

@interface NSObject (Archive)
/**
 *  @return list of property attributes in the format of @{@"propertyName":name, @"readonly": YES/NO, @"propertyType": NSString/NSNumber...}
 */
- (NSArray *)propertyList;

/**
 *  encode all non-readonly properties
 *
 *  @param aCode NSCoder context
 */
- (void)enCodeProperties:(NSCoder *)aCoder;

/**
 *  decode all non-readonly properties
 *
 *  @param aDecoder NSCoder context
 */
- (void)deCodeProperites:(NSCoder *)aDecoder;
@end
