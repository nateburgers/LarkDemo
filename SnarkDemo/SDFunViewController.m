//
//  SDFunViewController.m
//  SnarkDemo
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import "SDFunViewController.h"
#import "SDFunView.h"
#import "SDCircle.h"

@interface SDFunViewController ()

@end

@implementation SDFunViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _running = @(YES);
        _funView = [[SDFunView alloc] initWithFrame:CGRectZero];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    _funView = [[SDFunView alloc] initWithFrame: CGRectZero];
    _funView.backgroundColor = [UIColor whiteColor];
    self.view = _funView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [_funView setFrame:[[UIScreen mainScreen] applicationFrame]];
    for (NSUInteger i=0; i<60; i++) {
        [self addCircle];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (SDCircle *)addCircle
{
    return [self.funView addCircle];
}

- (SDCircle *)anyCircle
{
    return [self.funView anyCircle];
}

- (void)start
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(){
        double beginTime = 0;
        while ([[self running] boolValue]) {
            double sleep = (1.f / 30.f) - ((double)CFAbsoluteTimeGetCurrent() - beginTime);
            if (sleep > 0.f) {
                [NSThread sleepForTimeInterval:sleep];
            }
            [self update];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self view] setNeedsDisplay];
            });
            double endTime = (double)CFAbsoluteTimeGetCurrent();
            beginTime = endTime;
        }
    });
}

- (void)update
{
    @synchronized([[self funView] circles]) {
        [[self funView] update];
    }
}

@end
