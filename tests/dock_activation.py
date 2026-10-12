from pathlib import Path
import subprocess,tempfile
# Compile the actual patched Runtime logic against isolated fakes: no AppKit UI or user defaults.
root=Path(__file__).resolve().parent.parent
source=(root/'vendor/hammerspoon/Hammerspoon/MJDockIcon.m').read_text()
source='\n'.join(line for line in source.splitlines() if not line.startswith('#import'))
prefix=r'''
#import <Foundation/Foundation.h>
static NSString *MJShowDockIconKey=@"show";
static NSString *HSOpenConsoleOnDockClickKey=@"console";
typedef NSInteger NSApplicationActivationPolicy;
enum { NSApplicationActivationPolicyRegular=0, NSApplicationActivationPolicyAccessory=1 };
@interface TestDefaults : NSObject
+ (instancetype)standardUserDefaults;
- (BOOL)boolForKey:(NSString*)key;
- (void)setBool:(BOOL)value forKey:(NSString*)key;
@end
@implementation TestDefaults
static BOOL dock;
+ (instancetype)standardUserDefaults { static TestDefaults *d; if (!d) d=[self new]; return d; }
- (BOOL)boolForKey:(NSString*)key { return [key isEqual:MJShowDockIconKey] ? dock : NO; }
- (void)setBool:(BOOL)value forKey:(NSString*)key { if ([key isEqual:MJShowDockIconKey]) dock=value; }
@end
#define NSUserDefaults TestDefaults
@interface NSApplication : NSObject
@property NSApplicationActivationPolicy activationPolicy;
@property int activations;
@property int unhides;
+ (instancetype)sharedApplication;
- (void)setActivationPolicy:(NSApplicationActivationPolicy)value;
- (void)unhide:(id)sender;
- (void)activateIgnoringOtherApps:(BOOL)value;
@end
@implementation NSApplication
+ (instancetype)sharedApplication { static NSApplication *a; if (!a) a=[self new]; return a; }
- (void)unhide:(id)sender { self.unhides++; }
- (void)activateIgnoringOtherApps:(BOOL)value { self.activations++; }
@end
#define dispatch_after testDispatchAfter
static void testDispatchAfter(dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t work) { work(); }
static void NSDisableScreenUpdates(void) {}
static void NSEnableScreenUpdates(void) {}
BOOL MJDockIconVisible(void);
'''
suffix=r'''
int main(void) { @autoreleasepool {
 if (MJDockIconVisible()) return 6;
 NSApplication *a=[NSApplication sharedApplication];
 a.activationPolicy=NSApplicationActivationPolicyRegular;
 MJDockIconSetVisible(NO);
 if (a.activations || a.unhides) { fprintf(stderr,"FAIL: hiding Dock icon activated/unhid app (%d/%d)\n",a.activations,a.unhides); return 1; }
 if (a.activationPolicy!=NSApplicationActivationPolicyAccessory) return 2;
 MJDockIconSetVisible(NO);
 if (a.activations || a.unhides) return 3;
 MJDockIconSetVisible(YES);
 if (a.activationPolicy!=NSApplicationActivationPolicyRegular || a.activations!=1 || a.unhides!=1) return 4;
 MJDockIconSetVisible(YES);
 if (a.activations!=1 || a.unhides!=1) return 5;
 puts("Dock policy: hiding stays background; explicit showing activates; unchanged policy is a no-op");
 } return 0; }
'''
with tempfile.TemporaryDirectory(prefix='nivlet-dock-regression-') as d:
 p=Path(d);(p/'test.m').write_text(prefix+source+suffix)
 subprocess.run(['xcrun','clang','-fobjc-arc','-fblocks','-framework','Foundation',str(p/'test.m'),'-o',str(p/'test')],check=True)
 subprocess.run([str(p/'test')],check=True)
