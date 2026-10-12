"""Exercise the patched native handler with intercepted LaunchServices calls.

Requires fetched Runtime and macOS/Xcode; never changes system associations.
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'vendor/hammerspoon/extensions/urlevent/liburlevent.m').read_text()
start = source.index('static int urleventsetDefaultHandler(lua_State *L) {')
end = source.index('\n/// hs.urlevent.getDefaultHandler', start)
handler = source[start:end]
harness = r'''
#import <Foundation/Foundation.h>
#include <assert.h>
#define LSSetDefaultHandlerForURLScheme mockSetScheme
#define LSSetDefaultRoleHandlerForContentType mockSetContent
typedef int lua_State;
typedef int OSStatus;
#define noErr 0
#define LS_TSTRING 1
#define LS_TOPTIONAL 2
#define LS_TBOOLEAN 4
#define LS_TBREAK 0
#define LUA_TSTRING 1
#define kLSRolesViewer 1
static const char *schemeValue;
static BOOL urlOnly;
static int schemeCalls, contentCalls, startupCalls;
static int lua_type(lua_State *L, int index) { return LUA_TSTRING; }
static const char *lua_tostring(lua_State *L, int index) {
    return index == 1 ? schemeValue : "dev.local.DesktopToolkit";
}
static int lua_toboolean(lua_State *L, int index) { return urlOnly; }
static OSStatus LSSetDefaultHandlerForURLScheme(CFStringRef scheme, CFStringRef bundle) {
    assert([(__bridge NSString *)scheme isEqualToString:@(schemeValue)]);
    assert([(__bridge NSString *)bundle isEqualToString:@"dev.local.DesktopToolkit"]);
    schemeCalls++; return noErr;
}
static OSStatus LSSetDefaultRoleHandlerForContentType(CFStringRef type, int role, CFStringRef bundle) {
    contentCalls++; return noErr;
}
@interface LuaSkin : NSObject
+ (instancetype)sharedWithState:(lua_State *)state;
- (void)checkArgs:(int)first, ...;
- (void)logError:(NSString *)message;
- (void)logWarn:(NSString *)message;
@end
@implementation LuaSkin
+ (instancetype)sharedWithState:(lua_State *)state { return [self new]; }
- (void)checkArgs:(int)first, ... {}
- (void)logError:(NSString *)message { abort(); }
- (void)logWarn:(NSString *)message { abort(); }
@end
@interface Handler : NSObject
@property NSMutableDictionary *restoreHandlers;
- (void)handleStartupEvents;
@end
@implementation Handler
- (void)handleStartupEvents { startupCalls++; }
@end
static Handler *eventHandler;
static NSArray *defaultContentTypes;
'''
harness += handler
harness += r'''
int main(void) { @autoreleasepool {
    eventHandler = [Handler new]; eventHandler.restoreHandlers = [NSMutableDictionary new];
    defaultContentTypes = @[@"public.url", @"public.file-url", @"public.text"];
    for (NSString *scheme in @[@"http", @"https"]) {
        schemeValue = scheme.UTF8String;
        for (NSNumber *only in @[@YES, @NO]) {
            urlOnly = only.boolValue; schemeCalls = contentCalls = startupCalls = 0;
            urleventsetDefaultHandler(NULL);
            assert(schemeCalls == 1 && startupCalls == 1);
            assert(contentCalls == (urlOnly ? 0 : 3));
        }
    }
    puts("Native HTTP/HTTPS URL-only requests leave content associations untouched; legacy behavior and startup drain preserved");
} }
'''
with tempfile.TemporaryDirectory(prefix='nivlet-url-only-test-') as directory:
    path = Path(directory)
    (path / 'handler.m').write_text(harness)
    subprocess.run(['xcrun', 'clang', '-fobjc-arc', '-framework', 'Foundation',
                    str(path / 'handler.m'), '-o', str(path / 'handler')], check=True)
    subprocess.run([str(path / 'handler')], check=True)
