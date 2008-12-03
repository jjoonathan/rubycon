/**
 *  @file O3PipeControl.h
 *  @license MIT License (see LICENSE.txt)
 *  @date 10/18/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */


@interface O3PipeControl : NSObject {}
///Decides weather or not stdin and stderr are redirected to the delegate
+ (BOOL)capturingEnabled;
+ (void)setCapturingEnabled:(BOOL)ce;

+ (void)flush; //Synonym for checkPipes:
+ (BOOL)manualFlush;
+ (void)setManualFlush:(BOOL)newFlush;

+ (void)checkPipes:(id)notification;

///When capturing is enabled, the delegate will receive calls processStderrData:(NSData*) and processStdoutData:(NSData*) when new data is put through those pipes. If the delegate doesn't respond to one of those methods, the data is forwarded to the old output sink.
+ (id)delegate;
+ (void)setDelegate:(id)newDele;

///Sends (NSData*)indata or [indata dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] into stdin.
+ (void)sendStdinData:(id)indata;

///If YES, the sendStdinData: method doesn't have a monopoly on the STDIN pipe.
+ (BOOL)forwardsRegularInput;
+ (void)setForwardsRegularInput:(BOOL)f;

+ (void)testStdout;
+ (void)testStderr;
+ (NSArray*)pipes;
@end
