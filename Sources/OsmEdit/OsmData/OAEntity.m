//
//  OAEntity.m
//  OsmAnd
//
//  Created by Paul on 1/19/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAEntity.h"
#import "OrderedDictionary.h"
#import "OAOSMSettings.h"
#import "OANode.h"
#import "OAWay.h"
#import "OARelation.h"

static const int MODIFY_UNKNOWN = 0;
static const int MODIFY_DELETED = -1;
static const int MODIFY_MODIFIED = 1;
static const int MODIFY_CREATED = 2;

@implementation OAEntity
{
    MutableOrderedDictionary<NSString *, NSString *> *_tags;
    NSSet<NSString *> *_changedTags;
    long _id;
    BOOL _dataLoaded;
    NSInteger _modify;
    NSInteger _version;
    double _latitude;
    double _longitude;
}


-(id)initWithId:(long)identifier
{
    self = [super init];
    if (self) {
        _id = identifier;
    }
    return self;
}

-(id)initWithId:(long)identifier latitude:(double)lat longitude:(double)lon
{
    self = [super init];
    if (self) {
        _id = identifier;
        _latitude = lat;
        _longitude = lon;
    }
    return self;
}

-(id)initWithEntity:(OAEntity *)copy identifier:(long)identifier
{
    self = [super init];
    if (self) {
        _id = identifier;
        for (NSString *t in [copy getTagKeySet]) {
            [self putTagNoLC:t value:[copy getTagFromString:t]];
        }
        _dataLoaded = [copy isDataLoaded];
        _latitude = [copy getLatitude];
        _longitude = [copy getLongitude];
    }
    return self;
}


-(NSSet<NSString *> *) getChangedTags
{
    return [NSSet setWithSet:_changedTags];
}

-(void) setChangedTags:(NSSet<NSString *> *)changedTags
{
    _changedTags = changedTags;
}

-(NSInteger) getModify
{
    return _modify;
}

-(void)setModify:(NSInteger)modify
{
    _modify = modify;
}

-(long) getId
{
    return _id;
}

-(void)setLatitude:(double) latitude
{
    _latitude = latitude;
}

-(void) setLongitude:(double) longitude
{
    _longitude = longitude;
}

-(void)removeTag:(NSString *)key
{
    if (_tags)
        [_tags removeObjectForKey:key];
}

-(void)removeTags:(NSArray<NSString *> *)keys
{
    if (_tags)
    {
        for (NSString *tag in keys) {
            [_tags removeObjectForKey:tag];
        }
    }
}

-(void)putTag:(NSString *)key value:(NSString *)value
{
    [self putTagNoLC:[key lowerCase] value:value];
}

-(void) putTagNoLC:(NSString *)key value:(NSString *)value
{
    if (!_tags)
        _tags = [MutableOrderedDictionary new];
    
    [_tags setObject:value forKey:key];
    
}

-(void)replaceTags:(NSDictionary<NSString *, NSString *> *)toPut
{
    MutableOrderedDictionary<NSString *, NSString *> *result = [MutableOrderedDictionary new];
    [result addEntriesFromDictionary:toPut];
    _tags = result;
}

-(NSString *)getTag:(EOAOsmTagKey)key
{
    return [self getTagFromString:[OAOSMSettings getOSMKey:key]];
}
-(NSString *)getTagFromString:(NSString *) key
{
    if (!_tags)
        return nil;
    
    return [_tags objectForKey:key];
}

-(NSDictionary<NSString *, NSString *> *)getNameTags
{
    MutableOrderedDictionary<NSString *, NSString *> *result = [MutableOrderedDictionary new];
    [_tags enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL* stop) {
        if ([key hasPrefix:@"name:"])
            [result setObject:value forKey:key];
    }];
    return result;
}

-(NSInteger)getVersion
{
    return _version;
}

-(void)setVersion:(NSInteger)version
{
    _version = version;
}
-(NSDictionary<NSString *, NSString *> *)getTags
{
    return _tags;
}

-(NSArray<NSString *> *)getTagKeySet
{
    return _tags.allKeys;
}

-(BOOL)isDataLoaded
{
    return _dataLoaded;
}

-(double)getLatitude
{
    return _latitude;
}

-(double) getLongitude
{
    return _longitude;
}

+(EOAEntityType)typeOf:(OAEntity *)entity
{
    if ([entity isKindOfClass:[OANode class]]) {
        return NODE;
    } else if ([entity isKindOfClass:[OAWay class]]) {
        return WAY;
    } else if ([entity isKindOfClass:[OARelation class]]) {
        return RELATION;
    }
    return UNDEFINED;
}

-(NSString *) toNSString
{
    return [[OAEntityId valueOf:self] toNSString];
}

- (NSUInteger)hash
{
    if (_id < 0) {
        return super.hash;
    }
    return (NSUInteger) _id;
}

-(BOOL) isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object)
        return NO;
    if (![object isKindOfClass:self.class])
        return NO;
    OAEntity *other = (OAEntity *) object;
    if (_id != [other getId])
        return NO;
    // virtual are not equal
    if (_id < 0) {
        return NO;
    }
    return YES;
}

@end

@implementation OAEntityId
{
    EOAEntityType _entityType;
    long _identifier;
}

-(id) initWithEntityType:(EOAEntityType)type identifier:(long)identifier
{
    self = [super init];
    if (self) {
        _entityType = type;
        _identifier = identifier;
    }
    return self;
}

+ (OAEntityId *) valueOf:(OAEntity *)entity
{
    return [[OAEntityId alloc] initWithEntityType:[OAEntity typeOf:entity] identifier:[entity getId]];
}

- (NSUInteger)hash
{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result = prime * result + (!_identifier ? 0 : [[NSNumber numberWithLong:_identifier] hash]);
    result = prime * result + (!_entityType ? 0 : [[NSNumber numberWithInteger:_entityType] hash]);
    return result;
}

-(NSString *) toNSString
{
    return [NSString stringWithFormat:@"%ld %ld", _entityType, _identifier];
}

-(EOAEntityType) getType
{
    return _entityType;
}

-(long) getId
{
    return _identifier;
}

-(NSString *) getOsmUrl
{
    static const NSString *browseUrl = @"https://www.openstreetmap.org/browse/";
    if (_entityType == NODE)
        return [NSString stringWithFormat:@"%@node/%ld", browseUrl, _identifier];
    if (_entityType == WAY)
        return [NSString stringWithFormat:@"%@way/%ld", browseUrl, _identifier];
    return nil;
}

-(BOOL) isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object)
        return NO;
    if (![object isKindOfClass:self.class])
        return NO;
    OAEntityId *other = (OAEntityId *) object;
    if (!_identifier) {
        if ([other getId])
            return NO;
    } else if (_identifier != [other getId])
        return NO;
    if (!_entityType) {
        if ([other getType])
            return NO;
    } else if (_entityType != [other getType])
        return NO;
    return YES;
}

@end
