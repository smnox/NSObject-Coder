//
//  NSObject+Archive.m
//
//  Created by echen on 14/07/2015.
//

#import "NSObject+Archive.h"
#import <objc/runtime.h>

static NSString *const kPropertyName = @"propertyName";
static NSString *const kPropertyAttributeReadonly = @"readonly";
static NSString *const kPropertyType = @"propertyType";
@implementation NSObject (Archive)
static const char *getPropertyType(objc_property_t property)
{
	//property format example : T@,R,N,V_first
	const char *attributes = property_getAttributes(property);

	char buffer[1 + strlen(attributes)];
	strcpy(buffer, attributes);
	char *state = buffer, *attribute;
	while ((attribute = strsep(&state, ",")) != NULL) {
		if (attribute[0] == 'T' && attribute[1] != '@') {
			// it's a C primitive type:
			/*
			   if you want a list of what will be returned for these primitives, search online for
			   "objective-c" "Property Attribute Description Examples"
			   apple docs list plenty of examples of what you get for int "i", long "l", unsigned "I", struct, etc.
			 */
			NSString *name = [[NSString alloc] initWithBytes:attribute + 1 length:strlen(attribute) - 1 encoding:NSASCIIStringEncoding];
			return (const char *)[name cStringUsingEncoding:NSASCIIStringEncoding];
		}
		else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
			// it's an ObjC id type:
			return "id";
		}
		else if (attribute[0] == 'T' && attribute[1] == '@') {
			// it's another ObjC object type:
			NSString *name = [[NSString alloc] initWithBytes:attribute + 3 length:strlen(attribute) - 4 encoding:NSASCIIStringEncoding];
			return (const char *)[name cStringUsingEncoding:NSASCIIStringEncoding];
		}
	}
	return "";
}

- (BOOL)isPropertyReadOnly:(objc_property_t)property {
	const char *attributes = property_getAttributes(property);
	//printf("attributes=%s\n", attributes);
	char buffer[1 + strlen(attributes)];
	strcpy(buffer, attributes);
	char *state = buffer, *attribute;
	while ((attribute = strsep(&state, ",")) != NULL) {
		if (attribute[0] == 'R') {
			return YES;
		}
	}
	return NO;
}

- (NSArray *)propertyList {
	Class klass = [self class];
	if (klass == NULL) {
		return nil;
	}

	NSMutableArray *results = [[NSMutableArray alloc] init];

	unsigned int outCount, i;
	objc_property_t *properties = class_copyPropertyList(klass, &outCount);
	for (i = 0; i < outCount; i++) {
		objc_property_t property = properties[i];
		const char *propName = property_getName(property);
		if (propName) {
			const char *propType = getPropertyType(property);
			NSDictionary *propertyInfo = @{ kPropertyName : [NSString stringWithUTF8String:propName],
				                            kPropertyAttributeReadonly : @([self isPropertyReadOnly:property]),
				                            kPropertyType : [NSString stringWithUTF8String:propType] };
			[results addObject:propertyInfo];
		}
	}
	free(properties);

	return [NSArray arrayWithArray:results];
}

- (void)enCodeProperties:(NSCoder *)aCoder {
	NSArray *classProperties = [self propertyList];
	for (NSDictionary *propertyInfo in classProperties) {
		NSString *propertyName = propertyInfo[kPropertyName];
		//Skip readonly properties
		BOOL isReadOnly = [propertyInfo[kPropertyAttributeReadonly] boolValue];
		if (!isReadOnly) {
			id value = [self valueForKey:propertyName];
			[aCoder encodeObject:value forKey:propertyName];
		}
	}
}

- (void)deCodeProperites:(NSCoder *)aDecoder {
	NSArray *classProperties = [self propertyList];
	for (NSDictionary *propertyInfo in classProperties) {
		NSString *propertyName = propertyInfo[kPropertyName];
		//Skip readonly properties
		BOOL isReadOnly = [propertyInfo[kPropertyAttributeReadonly] boolValue];
		if (!isReadOnly) {
			id value = [aDecoder decodeObjectForKey:propertyName];
			[self setValue:value forKey:propertyName];
		}
	}
}

@end
