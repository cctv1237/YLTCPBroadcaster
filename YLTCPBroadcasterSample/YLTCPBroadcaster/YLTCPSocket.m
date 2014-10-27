//
//  YLTCPSocket.m
//  YLTCPBroadcasterSample
//
//  Created by Yannick Loriot on 27/10/14.
//  Copyright (c) 2014 Yannick Loriot. All rights reserved.
//

#import "YLTCPSocket.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

const NSUInteger kTCPSocketDefaultTimeoutInSeconds = 2;

@interface YLTCPSocket ()
@property (nonatomic, strong) NSString   *hostname;
@property (nonatomic, assign) NSUInteger port;
@property (nonatomic, strong) dispatch_queue_t backgroundQueue;

@end

@implementation YLTCPSocket

- (id)initWithHostName:(NSString *)hostname port:(NSUInteger)port {
    if ((self = [super init])) {
        NSParameterAssert(hostname);
        NSParameterAssert(port);
        
        _hostname = hostname;
        _port     = port;
        
        _backgroundQueue = dispatch_queue_create("com.yannickloriot.tcpsocket.queue", NULL);
    }
    return self;
}

+ (instancetype)socketWithHostName:(NSString *)hostname port:(NSUInteger)port {
    return [[self alloc] initWithHostName:hostname port:port];
}

- (void)connectWithCompletionHandler:(YLTCPSocketCompletionBlock)completion {
    [self connectWithTimeout:kTCPSocketDefaultTimeoutInSeconds completionHandler:completion];
}

- (void)connectWithTimeout:(NSTimeInterval)timeout completionHandler:(YLTCPSocketCompletionBlock)completion {
    dispatch_async(_backgroundQueue, ^ {
        YLTCPSocketCompletionBlock performCompletionHandler = ^ (BOOL success, NSString *message) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(success, message);
                });
            }
        };
        
        // http://stackoverflow.com/questions/2597608/c-socket-connection-timeout
        // http://developerweb.net/viewtopic.php?id=3196
        int sockfd, res, valopt;
        long arg;
        fd_set fdset;
        socklen_t socklen;
        struct sockaddr_in serv_addr;
        struct hostent *endpoint;
        struct timeval tv;
        

        // Open the socket
        sockfd = socket(AF_INET, SOCK_STREAM, 0);
        
        if (sockfd < 0) {
            performCompletionHandler(NO, @"Can not opening socket");
            return;
        }
        
        // Create the remote endpoint
        endpoint = gethostbyname([_hostname cStringUsingEncoding:NSUTF8StringEncoding]);
        
        if (endpoint == NULL) {
            performCompletionHandler(NO, @"No such host");
            close(sockfd);
            return;
        }
        
        // Build the socket description
        bzero((char *) &serv_addr, sizeof(serv_addr));
        serv_addr.sin_family = AF_INET;
        bcopy((char *)endpoint->h_addr,
              (char *)&serv_addr.sin_addr.s_addr,
              endpoint->h_length);
        serv_addr.sin_port = htons(_port);
        
        // Set non-blocking
        if ((arg = fcntl(sockfd, F_GETFL, NULL)) < 0) {
            performCompletionHandler(NO, [NSString stringWithFormat:@"Error fcntl(..., F_GETFL) (%s)", strerror(errno)]);
            close(sockfd);
            return;
        }
        
        arg |= O_NONBLOCK;
        
        if (fcntl(sockfd, F_SETFL, arg) < 0) {
            performCompletionHandler(NO, [NSString stringWithFormat:@"Error fcntl(..., F_SETFL) (%s)", strerror(errno)]);
            close(sockfd);
            return;
        }
        
        // Trying to connect with timeout
        res = connect(sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr));
        
        if (res < 0) {
            if (errno == EINPROGRESS) {
                // Set the timeout interval
                double timeoutDecimal = (NSInteger)timeout;
                tv.tv_sec             = timeoutDecimal;
                tv.tv_usec            = (timeout - timeoutDecimal) * 1000;

                FD_ZERO(&fdset);
                FD_SET(sockfd, &fdset);
                
                res = select(sockfd + 1, NULL, &fdset, NULL, &tv);
                
                if (res < 0 && errno != EINTR) {
                    performCompletionHandler(NO, [NSString stringWithFormat:@"Error connecting %d - %s", errno, strerror(errno)]);
                    close(sockfd);
                    return;
                }
                else if (res > 0) {
                    // Socket selected for write
                    socklen = sizeof(socklen_t);
                    
                    if (getsockopt(sockfd, SOL_SOCKET, SO_ERROR, (void*)(&valopt), &socklen) < 0) {
                        performCompletionHandler(NO, [NSString stringWithFormat:@"Error in getsockopt() %d - %s", errno, strerror(errno)]);
                        close(sockfd);
                        return;
                    }
                    
                    // Check the returned value...
                    if (valopt) {
                        performCompletionHandler(NO, [NSString stringWithFormat:@"Error in delayed connection() %d - %s", valopt, strerror(valopt)]);
                        close(sockfd);
                        return;
                    }
                    
                    // The endpoint is alive!
                    if (valopt == 0) {
                        performCompletionHandler(YES, @"Remote TCP socket opened");
                        close(sockfd);
                        return;
                    }
                }
                else {
                    performCompletionHandler(NO, @"Timeout");
                    close(sockfd);
                    return;
                }
            }
            else {
                performCompletionHandler(NO, [NSString stringWithFormat:@"Error connecting %d - %s", errno, strerror(errno)]);
                close(sockfd);
                return;
            }
        }
        
        close(sockfd);
    });
}

@end
