#import <Cocoa/Cocoa.h>

static NSString *HomebrewExecutable(NSString *name) {
    NSArray<NSString *> *prefixes = @[@"/opt/homebrew", @"/usr/local"];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    for (NSString *prefix in prefixes) {
        NSString *path = [[prefix stringByAppendingPathComponent:@"bin"] stringByAppendingPathComponent:name];
        if ([fileManager isExecutableFileAtPath:path]) {
            return path;
        }
    }

    return [[@"/usr/local/bin" stringByAppendingPathComponent:name] copy];
}

static NSDictionary<NSString *, NSString *> *Environment(void) {
    NSMutableDictionary<NSString *, NSString *> *environment = [[[NSProcessInfo processInfo] environment] mutableCopy];
    environment[@"LANG"] = @"en_CA.UTF-8";
    return environment;
}

@interface ClickDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSTimer *timer;
@end

@implementation ClickDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [self click:nil];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(click:) userInfo:nil repeats:YES];
}

- (void)click:(NSTimer *)timer {
    (void)timer;
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = HomebrewExecutable(@"cliclick");
    task.arguments = @[@"c:."];
    task.environment = Environment();
    @try {
        [task launch];
    } @catch (NSException *exception) {
        NSLog(@"Failed to run cliclick: %@", exception.reason);
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    (void)sender;
    [self.timer invalidate];
    self.timer = nil;
    return NSTerminateNow;
}

@end

int main(int argc, const char *argv[]) {
    (void)argc;
    (void)argv;

    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        ClickDelegate *delegate = [[ClickDelegate alloc] init];
        app.delegate = delegate;

        NSMenu *menuBar = [[NSMenu alloc] init];
        NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
        [menuBar addItem:appMenuItem];
        app.mainMenu = menuBar;

        NSMenu *appMenu = [[NSMenu alloc] init];
        [appMenu addItemWithTitle:@"Quit Click" action:@selector(terminate:) keyEquivalent:@"q"];
        appMenuItem.submenu = appMenu;

        [app run];
    }

    return 0;
}
