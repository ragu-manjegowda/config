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

@interface ZimDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSTask *task;
@end

@implementation ZimDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    self.task = [[NSTask alloc] init];
    self.task.launchPath = HomebrewExecutable(@"zim");
    self.task.environment = Environment();

    __weak ZimDelegate *weakSelf = self;
    self.task.terminationHandler = ^(NSTask *task) {
        (void)task;
        dispatch_async(dispatch_get_main_queue(), ^{
            ZimDelegate *strongSelf = weakSelf;
            strongSelf.task = nil;
            [NSApp terminate:nil];
        });
    };

    @try {
        [self.task launch];
    } @catch (NSException *exception) {
        NSLog(@"Failed to run zim: %@", exception.reason);
        self.task = nil;
        [NSApp terminate:nil];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    (void)sender;
    if (self.task.isRunning) {
        [self.task terminate];
    }
    return NSTerminateNow;
}

@end

int main(int argc, const char *argv[]) {
    (void)argc;
    (void)argv;

    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        ZimDelegate *delegate = [[ZimDelegate alloc] init];
        app.delegate = delegate;

        NSMenu *menuBar = [[NSMenu alloc] init];
        NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
        [menuBar addItem:appMenuItem];
        app.mainMenu = menuBar;

        NSMenu *appMenu = [[NSMenu alloc] init];
        [appMenu addItemWithTitle:@"Quit Zim" action:@selector(terminate:) keyEquivalent:@"q"];
        appMenuItem.submenu = appMenu;

        [app run];
    }

    return 0;
}
