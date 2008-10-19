/**
 *  @file O3PipeControl.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 10/18/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "O3PipeControl.h"
#import <unistd.h>

@implementation O3PipeControl
static BOOL sCapturing = NO;
static BOOL sForwardsRegularInput = YES;
static int sOldStdout = 1;
static int sOldStderr = 2;
static int sOldStdin = 0;

int sStdoutPipes[2]; BOOL sStdoutPipesValid;
int sStderrPipes[2]; BOOL sStderrPipesValid;
int sStdinPipes[2];  BOOL sStdinPipesValid;

static id sDelegate;
static NSTimer* sTimer;

+ (void)initialize {
	static BOOL sInited = NO;
	if (sInited) return;
	sInited = YES;
	sOldStdout = dup(STDOUT_FILENO);
	sOldStdin = dup(STDIN_FILENO);
	sOldStderr = dup(STDERR_FILENO);
	if (sOldStdout==-1) {sOldStdout=1; NSLog(@"OutputControl couldn't dup stdout");}
	if (sOldStdin==-1) {sOldStdin=0; NSLog(@"OutputControl couldn't dup stdin");}
	if (sOldStderr==-1) {sOldStderr=2; NSLog(@"OutputControl couldn't dup stderr");}
}

+ (BOOL)capturingEnabled {return sCapturing;}
+ (void)setCapturingEnabled:(BOOL)ce {
	int e;
	
	if (ce&&!sCapturing) {
		if (!sStdoutPipesValid) {
			if (pipe(sStdoutPipes)) {NSLog(@"Couldn't enable capturing: stdout pipe creation failed (%i)", errno); return;}
			fclose(stdout);
			if ((e=dup2(sStdoutPipes[1],STDOUT_FILENO))!=STDOUT_FILENO) {NSLog(@"Couldn't dup over STDOUT (%i:%i).",e,errno); return;}
			FILE* newstdout = fdopen(sStdoutPipes[1], "w");
			if ((stdout=newstdout)!=newstdout) {NSLog(@"Couldn't change FILE*stdout! (%i)",errno); return;}
			sStdoutPipesValid = YES;
		}
		if (!sStderrPipesValid) {
			if (pipe(sStderrPipes)) {printf("Couldn't enable capturing: stderr pipe creation failed (%i).\n", errno); return;}
			fclose(stderr);
			if ((e=dup2(sStderrPipes[1],STDERR_FILENO))!=STDERR_FILENO) {printf("Couldn't dup over STDERR (%i:%i).\n",e,errno); return;}
			FILE* newstderr = fdopen(sStderrPipes[1], "w");
			if ((stderr=newstderr)!=newstderr) {NSLog(@"Couldn't change FILE*stderr! (%i)",errno); return;}
			sStderrPipesValid = YES;
		}
		sCapturing = YES;
		if (!sTimer) sTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/20.0 target:self selector:@selector(checkPipes:) userInfo:nil repeats:YES];
	}
	
	if (!ce&&sCapturing) {
		sCapturing = NO;
		if (sStdoutPipesValid) {
			sStdoutPipesValid = NO;
			fclose(stdout);
			close(sStdoutPipes[0]);
			close(sStdoutPipes[1]);
			if (dup2(sOldStdout,STDOUT_FILENO)!=STDOUT_FILENO) NSLog(@"Couldn't move stdout back to its normal place.");
			FILE* newstdout = fdopen(STDOUT_FILENO, "w");
			if ((stdout=newstdout)!=newstdout) NSLog(@"Couldn't create the new FILE*stdout (%i).",errno);
		}
		if (sStderrPipesValid) {
			sStderrPipesValid = NO;
			fclose(stderr);
			close(sStderrPipes[0]);
			close(sStderrPipes[1]);
			if (dup2(sOldStderr,STDERR_FILENO)!=STDERR_FILENO) NSLog(@"Couldn't move stderr back to its normal place.");
			FILE* newstderr = fdopen(STDERR_FILENO, "w");
			if ((stderr=newstderr)!=newstderr) printf("Couldn't create the new FILE*stderr (%i).",errno);
		}
		if (sTimer) [sTimer invalidate];
		sTimer = nil;
	}
	
}



+ (id)delegate {
	return sDelegate;
}

+ (void)setDelegate:(id)newDele {
	if (sDelegate==newDele) return;
	[sDelegate release];
	sDelegate = [newDele retain];
}



+ (void)sendStdinData:(id)indata {
	if (!sStdinPipesValid) {
		if (pipe(sStdinPipes)) {NSLog(@"Couldn't create pipe to capture stdin (%i)", errno); return;}
		if (dup2(sStdinPipes[0], STDIN_FILENO)) {NSLog(@"Couldn't dup over stdin (%i)", errno); close(sStdinPipes[0]); close(sStdinPipes[1]); return;}
		sStdinPipesValid = YES;
	}
	if ([indata isKindOfClass:[NSString class]]) indata = [indata dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	write(sStdinPipes[1], [indata bytes], [indata length]);
}



+ (BOOL)forwardsRegularInput {
	return sForwardsRegularInput;
}

+ (void)setForwardsRegularInput:(BOOL)f {
	sForwardsRegularInput = f;
}


+ (void)checkPipes:(id)notification {
	int s; char buffer[512];
	
	if (fcntl(sStdoutPipes[0], F_SETFL, O_NONBLOCK)==-1) {NSLog(@"Couldn't make reading nonblocking on stdout:%i",errno); return;}
	if (sStdoutPipesValid && [sDelegate respondsToSelector:@selector(processStdoutData:)]) {
		intptr_t s;
		fflush(stdout);
		while (1) {
			s = read(sStdoutPipes[0], buffer, sizeof(buffer));
			if (s<=0) break;
			[sDelegate performSelector:@selector(processStdoutData:) withObject:[NSData dataWithBytesNoCopy:buffer length:s freeWhenDone:NO]];
		}
	} else if (sStdoutPipesValid) {
		fflush(stdout);
		while (1) {
			s = read(sStdoutPipes[0], buffer, sizeof(buffer));
			if (s<=0) break;
			write(sOldStdout, buffer, s);
		}		
	}
	
	if (fcntl(sStderrPipes[0], F_SETFL, O_NONBLOCK)==-1) {NSLog(@"Couldn't make reading nonblocking on stderr:%i",errno); return;}
	if (sStderrPipesValid && [sDelegate respondsToSelector:@selector(processStderrData:)]) {
		intptr_t s;
		fflush(stderr);
		while (1) {
			s = read(sStderrPipes[0], buffer, sizeof(buffer));
			if (s<=0) break;
			[sDelegate performSelector:@selector(processStderrData:) withObject:[NSData dataWithBytesNoCopy:buffer length:s freeWhenDone:NO]];
		}
	} else if (sStderrPipesValid) {
		fflush(stderr);
		while (1) {
			s = read(sStderrPipes[0], buffer, sizeof(buffer));
			if (s<=0) break;
			write(sOldStderr, buffer, s);
		}		
	}
	
	if (sStdinPipesValid && sForwardsRegularInput) {
		uintptr_t s;
		while (1) {
			s = read(sOldStdin, buffer, sizeof(buffer));
			if (s<=0) break;
			if (sForwardsRegularInput) write(sStdinPipes[1], buffer, s);
		}
	}
}

+ (void)testStdout {
	write(sStdoutPipes[1], "STDOUT Test 1\n",15);
	printf("STDOUT Test 2...\n");
}

+ (void)testStderr {
	write(sStderrPipes[1], "STDERR Test 1\n",15);
	NSLog(@"STDERR Test 2...");
}

+ (NSArray*)pipes {
	return [NSArray arrayWithObjects:
			[NSNumber numberWithInt:sStdoutPipes[0]],[NSNumber numberWithInt:sStdoutPipes[1]],
			[NSNumber numberWithInt:sStderrPipes[0]],[NSNumber numberWithInt:sStderrPipes[1]],
			[NSNumber numberWithInt:sStdinPipes[0]],[NSNumber numberWithInt:sStdinPipes[1]], nil];
}


@end
