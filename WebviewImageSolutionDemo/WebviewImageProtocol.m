//
//  WebviewImageProtocol.m
//  WebviewImageSolutionDemo
//
//  Created by Ljx. on 16/7/18.
//  Copyright © 2016年 Ljx. All rights reserved.
//

#import "WebviewImageProtocol.h"

static NSString *const WebviewImageProtocolHandledKey = @"WebviewImageProtocolHandledKey";

@interface WebviewImageProtocol () <NSURLConnectionDataDelegate>

@property(nonatomic, strong) NSURLConnection *connection;

@end

@implementation WebviewImageProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *path = request.URL.path;
    // 只处理是图片的URL请求
    if ([path hasSuffix:@".jpg"] || [path hasSuffix:@".jpeg"] || [path hasSuffix:@".webp"]) {
        if ([NSURLProtocol propertyForKey:WebviewImageProtocolHandledKey inRequest:request]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    //读取本地缓存数据
    NSData *data = [self imageDataWithURL:self.request.URL];
    
    if (data) {
        //加载本地数据 模拟请求成功 返回到webview上
        NSString *mimeType = @"image/jpeg";
        NSMutableDictionary *header = [[NSMutableDictionary alloc] initWithCapacity:2];
        NSString *contentType = [mimeType stringByAppendingString:@";charset=UTF-8"];
        header[@"Content-Type"] = contentType;
        header[@"Content-Length"] = [NSString stringWithFormat:@"%lu", (unsigned long) data.length];
        
        NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                      statusCode:200
                                                                     HTTPVersion:@"1.1"
                                                                    headerFields:header];
        
        [self.client URLProtocol:self didReceiveResponse:httpResponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
    } else {
        //本地没缓存 用带缓存策略的图片请求
        // 这里其实应该是图片库对于图片请求的处理，每个人实现的图片库不一样，所以我就直接以webview的方式请求了
        NSMutableURLRequest *newRequest = [self.request mutableCopy];
        newRequest.allHTTPHeaderFields = self.request.allHTTPHeaderFields;
        [NSURLProtocol setProperty:@YES forKey:WebviewImageProtocolHandledKey inRequest:newRequest];
        
        self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
    }
}

- (void)stopLoading {
    [self.connection cancel];
}

- (NSData*)imageDataWithURL:(NSURL*)url {
    if ([url.absoluteString isEqualToString:@"http://kuailejim.com/images/background-cover.jpg"]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"background-cover" ofType:@"jpg"];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        return  data;
    }
    return nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

@end
