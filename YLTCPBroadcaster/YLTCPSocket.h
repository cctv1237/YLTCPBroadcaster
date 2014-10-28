/*
 * YLTCPBroadcaster
 *
 * Copyright 2014 - present, Yannick Loriot.
 * http://yannickloriot.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import <Foundation/Foundation.h>

extern const NSUInteger kTCPSocketDefaultTimeoutInSeconds;

/**
 * @abstract The TCP socket completion block. This block has no return value 
 * and takes two arguments: the `success` and the `message`.
 *
 * - `success`: Boolean value to check whether the socket achieved a connection
 * with the remote host. If the value is equal to `NO` it means that an error 
 * occured and you should look at the `errorMessage` argument.
 * - `errorMessage`: A NSString to describe the reason of the connection failure.
 */
typedef void (^YLTCPSocketCompletionBlock) (BOOL success, NSString *errorMessage);

/**
 * The main purpose of the `YLTCPSocket` is to try to open a TCP socket with a
 * remote host to check if a connection is possible.
 */
@interface YLTCPSocket : NSObject
@property (nonatomic, strong, readonly) NSString *hostname;
@property (nonatomic, readonly) NSUInteger       port;

- (id)initWithHostname:(NSString *)hostname port:(NSUInteger)port;
+ (instancetype)socketWithHostname:(NSString *)hostname port:(NSUInteger)port;

- (void)connectWithCompletionHandler:(YLTCPSocketCompletionBlock)completion;
- (void)connectWithTimeout:(NSTimeInterval)timeout completionHandler:(YLTCPSocketCompletionBlock)completion;

@end
