#import "AmapFlutterSearchPlugin.h"
#import <AMapSearchKit/AMapSearchKit.h>
#import <objc/message.h>


@interface AmapFlutterSearchPlugin ()<AMapSearchDelegate>
{
    AMapSearchAPI *search;
    FlutterResult resultCallback;
}

@end

@implementation AmapFlutterSearchPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"amap_flutter_search"
            binaryMessenger:[registrar messenger]];
  AmapFlutterSearchPlugin* instance = [[AmapFlutterSearchPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
      result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }else if ([@"setApiKey" isEqualToString:call.method]){
        NSString *apiKey = call.arguments[@"ios"];
        if (apiKey && [apiKey isKindOfClass:[NSString class]]) {
            [AMapServices sharedServices].apiKey = apiKey;
            result(@YES);
        }else {
            result(@NO);
        }
    }else if ([@"updatePrivacyStatement" isEqualToString:call.method]) {
        [self updatePrivacyStatement:call.arguments];
    }else if([@"searchKeyword" isEqualToString:call.method]){
        NSString *keyword = call.arguments[@"keyword"];
        NSString *city = call.arguments[@"city"];
        NSString *types = call.arguments[@"types"];
        NSNumber *page = call.arguments[@"page"];
        NSNumber *pageSize = call.arguments[@"pageSize"];
        search = [[AMapSearchAPI alloc] init];
        search.delegate = self;
        AMapPOIKeywordsSearchRequest *geo = [[AMapPOIKeywordsSearchRequest alloc] init];
        geo.keywords = keyword;
        geo.city = city;
        geo.types               = types;
        geo.requireExtension    = YES;
            
        /*  搜索SDK 3.2.0 中新增加的功能，只搜索本城市的POI。*/
        geo.cityLimit           = YES;
        geo.requireSubPOIs      = YES;
        // 分页参数
        if (page != nil) {
            geo.page = [page intValue];
        }
        if (pageSize != nil) {
            geo.offset = [pageSize intValue];
        }
        
        [search AMapPOIKeywordsSearch:geo];
        
        resultCallback = result;
    }else if([@"searchAround" isEqualToString:call.method]){
        NSString *keyword = call.arguments[@"keyword"];
        NSString *city = call.arguments[@"city"];
        NSString *latitude = call.arguments[@"latitude"];
        NSString *longitude = call.arguments[@"longitude"];
        NSNumber *page = call.arguments[@"page"];
        NSNumber *pageSize = call.arguments[@"pageSize"];
        NSNumber *radius = call.arguments[@"radius"];
        search = [[AMapSearchAPI alloc] init];
        search.delegate = self;
        AMapPOIAroundSearchRequest *geo = [[AMapPOIAroundSearchRequest alloc] init];
        geo.keywords = keyword;
        geo.city = city;
        geo.location            = [AMapGeoPoint locationWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
        geo.keywords            = keyword;
        geo.requireExtension    = YES;
        geo.requireSubPOIs      = YES;
        if (radius != nil) {
            geo.radius = [radius intValue];
        }
        // 分页参数
        if (page != nil) {
            geo.page = [page intValue];
        }
        if (pageSize != nil) {
            geo.offset = [pageSize intValue];
        }
        
        [search AMapPOIAroundSearch:geo];
        
        resultCallback = result;
        
        
        
    }else if([@"fetchInputTips" isEqualToString:call.method]){
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }else if([@"searchGeocode" isEqualToString:call.method]){
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }else if([@"searchReGeocode" isEqualToString:call.method]){
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }else {
        result(FlutterMethodNotImplemented);
      }
}

- (void)updatePrivacyStatement:(NSDictionary *)arguments {
//    if ((AMapServices.version) < 20800) {
//        NSLog(@"当前定位SDK版本没有隐私合规接口，请升级定位SDK到2.8.0及以上版本");
//        return;
//    }
    if (arguments == nil) {
        return;
    }
    if (arguments[@"hasContains"] != nil && arguments[@"hasShow"] != nil) {
        [AMapSearchAPI updatePrivacyShow:[arguments[@"hasShow"] integerValue] privacyInfo:[arguments[@"hasContains"] integerValue]];
    }
    if (arguments[@"hasAgree"] != nil) {
        [AMapSearchAPI updatePrivacyAgree:[arguments[@"hasAgree"] integerValue]];
    }
}

/* POI 搜索回调. */
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    if (response.pois.count == 0)
    {
        return;
    }
    
    NSArray *dataList = [self arrayWithObject:response.pois];
    
    NSLog(@"搜索信息%@",dataList);
    resultCallback(dataList);
}

- (void)onGeocodeSearchDone:(AMapGeocodeSearchRequest *)request response:(AMapGeocodeSearchResponse *)response
{
    if (response.geocodes.count == 0)
    {
        return;
    }
    
    NSArray *dataList = [self arrayWithObject:response.geocodes];
    
    NSLog(@"搜索信息%@",dataList);
    resultCallback(dataList);
}

- (NSDictionary *)dicFromObject:(NSObject *)object {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    unsigned int count;
    objc_property_t *propertyList = class_copyPropertyList([object class], &count);
    
    for (int i = 0; i < count; i++) {
        objc_property_t property = propertyList[i];
        const char *cName = property_getName(property);
        NSString *name = [NSString stringWithUTF8String:cName];
        NSObject *value = [object valueForKey:name];//valueForKey返回的数字和字符串都是对象
        
        if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
            //string , bool, int ,NSinteger
            [dic setObject:value forKey:name];
            
        } else if ([value isKindOfClass:[NSArray class]]) {
            //数组或字典
            [dic setObject:[self arrayWithObject:value] forKey:name];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            //数组或字典
            [dic setObject:[self dicWithObject:value] forKey:name];
        } else if (value == nil) {
            //null
        } else {
            //model
            [dic setObject:[self dicFromObject:value] forKey:name];
        }
    }
    
    return [dic copy];
}

- (NSArray *)arrayWithObject:(id)object {
    //数组
    NSMutableArray *array = [NSMutableArray array];
    NSArray *originArr = (NSArray *)object;
    if ([originArr isKindOfClass:[NSArray class]]) {
        for (NSObject *object in originArr) {
            if ([object isKindOfClass:[NSString class]]||[object isKindOfClass:[NSNumber class]]) {
                //string , bool, int ,NSinteger
                [array addObject:object];
            } else if ([object isKindOfClass:[NSArray class]]) {
                //数组或字典
                [array addObject:[self arrayWithObject:object]];
            } else if ([object isKindOfClass:[NSDictionary class]]) {
                //数组或字典
                [array addObject:[self dicWithObject:object]];
            } else {
                //model
                [array addObject:[self dicFromObject:object]];
            }
        }
        return [array copy];
    }
    return array.copy;
}

- (NSDictionary *)dicWithObject:(id)object {
    //字典
    NSDictionary *originDic = (NSDictionary *)object;
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    if ([object isKindOfClass:[NSDictionary class]]) {
        for (NSString *key in originDic.allKeys) {
            id object = [originDic objectForKey:key];
            if ([object isKindOfClass:[NSString class]]||[object isKindOfClass:[NSNumber class]]) {
                //string , bool, int ,NSinteger
                [dic setObject:object forKey:key];
            } else if ([object isKindOfClass:[NSArray class]]) {
                //数组或字典
                [dic setObject:[self arrayWithObject:object] forKey:key];
            } else if ([object isKindOfClass:[NSDictionary class]]) {
                //数组或字典
                [dic setObject:[self dicWithObject:object] forKey:key];
            } else {
                //model
                [dic setObject:[self dicFromObject:object] forKey:key];
            }
        }
        return [dic copy];
    }
    return dic.copy;
}

#pragma mark -数组转换成json串
- (NSString *)arrayToJsonString:(NSArray *)array{
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&error];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];;
}


@end
