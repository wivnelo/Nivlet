"""Check native HTML document routing and path encoding using Foundation only.

Requires macOS/Xcode and a fetched runtime. NIVLET_RUNTIME_SOURCE can point to a
read-only runtime checkout when the current checkout has no vendor directory.
The tracked patch is applied to a temporary copy; no app or browser is launched,
and no system association, user settings, or source runtime is changed.
"""
from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
runtime = Path(os.environ.get('NIVLET_RUNTIME_SOURCE', root / 'vendor/hammerspoon'))
relative = Path('extensions/urlevent/liburlevent.m')
delegate_relative = Path('Hammerspoon/MJAppDelegate.m')
patch = root / 'patches/browser-file-url.patch'
fetch = (root / 'scripts/fetch-runtime.sh').read_text()
assert fetch.index('patches/browser-file-url.patch') > fetch.index('patches/browser-url-only.patch')

with tempfile.TemporaryDirectory(prefix='nivlet-file-url-test-') as directory:
    work = Path(directory)
    for relative_source in (relative, delegate_relative):
        copied = work / relative_source
        copied.parent.mkdir(parents=True)
        copied.write_bytes((runtime / relative_source).read_bytes())
    check = subprocess.run(['git', 'apply', '--check', str(patch)], cwd=work,
                           capture_output=True, text=True)
    if check.returncode == 0:
        subprocess.run(['git', 'apply', str(patch)], cwd=work, check=True)
    else:
        # A normal freshly fetched runtime already includes the patch.
        reverse = subprocess.run(['git', 'apply', '--reverse', '--check', str(patch)],
                                 cwd=work, capture_output=True, text=True)
        if reverse.returncode:
            raise RuntimeError('Native file URL patch does not match runtime source:\n' + check.stderr)

    source = (work / relative).read_text()
    callback = source.index('- (void)callbackWithURL:(NSString *)openUrl senderPID:(pid_t)pid {')
    start = source.index('    if ([openUrl hasPrefix:@"/"]) {', callback)
    end = source.index('    if (!url) {', start)
    conversion = source[start:end]
    delegate = (work / delegate_relative).read_text()
    extension_start = delegate.index('    NSString *fileExtension = [fileAndPath pathExtension];')
    extension_end = delegate.index('    NSDictionary *infoDict', extension_start)
    extension_normalization = delegate[extension_start:extension_end]
    predicate_start = delegate.index('    if (', extension_end)
    predicate_end = delegate.index(') {', predicate_start)
    document_predicate = delegate[predicate_start + len('    if ('):predicate_end]
    harness = r'''
#import <Foundation/Foundation.h>
#include <assert.h>
static NSURL *URLForInput(NSString *openUrl) {
'''
    harness += conversion + '\n    return url;\n}\n'
    harness += ('static BOOL HandlesDocument(NSString *fileAndPath, NSArray *flatSupportedExtensions) {\n'
                + extension_normalization + '    return ' + document_predicate + ';\n}\n')
    harness += r'''
int main(void) { @autoreleasepool {
    NSArray<NSString *> *paths = @[
        @"/tmp/plain.html",
        @"/tmp/a folder/中文 空格 # ? 100%.html",
        @"/tmp/literal%20name.htm",
        @"/tmp/preview?mode=raw#fragment.HTML",
        @"/tmp/中文目录/样例.htm"
    ];
    for (NSString *path in paths) {
        NSURL *url = URLForInput(path);
        assert(url && url.isFileURL);
        assert([url.path isEqualToString:path]);
        assert(url.query == nil && url.fragment == nil);
        assert([URLForInput(url.absoluteString).path isEqualToString:path]);
    }
    NSString *encoded = URLForInput(paths[1]).absoluteString;
    for (NSString *escape in @[@"%20", @"%23", @"%3F", @"%25"]) {
        assert([encoded containsString:escape]);
    }
    assert([URLForInput(paths[2]).absoluteString containsString:@"%2520"]);

    // Real URL query/fragment components must not become filename characters.
    for (NSString *input in @[
        @"file:///tmp/plain.html?mode=preview#section-2",
        @"file:///tmp/a%20folder/name%23part.html?query=a%26b#anchor",
        @"https://example.com/a%20b?query=c%26d#part"
    ]) {
        NSURL *url = URLForInput(input);
        assert([url.absoluteString isEqualToString:input]);
        assert(url.query != nil && url.fragment != nil);
    }
    NSArray *supportedExtensions = @[@"html", @"htm", @"txt", @"xhtml"];
    for (NSString *path in @[@"/tmp/plain.html", @"/tmp/plain.htm", @"/tmp/page.HTML",
                            @"/tmp/page.HTM", @"/tmp/page.HtMl", @"/tmp/page.hTm",
                            @"/tmp/中文页面.HTML"]) {
        assert(HandlesDocument(path, supportedExtensions));
    }
    // Preserve the existing declared-extension behavior for every other type.
    assert(HandlesDocument(@"/tmp/plain.txt", supportedExtensions));
    assert(HandlesDocument(@"/tmp/plain.xhtml", supportedExtensions));
    for (NSString *path in @[@"/tmp/plain.TXT", @"/tmp/plain.XHTML", @"/tmp/plain.pdf",
                            @"/tmp/plain.html.lua", @"/tmp/html"]) {
        assert(!HandlesDocument(path, supportedExtensions));
    }
    assert(!HandlesDocument(@"/tmp/plain.HTML", @[]));
    assert(!HandlesDocument(@"/tmp/plain.HTM", @[@"html"]));
    puts("Native paths preserve spaces, Unicode, #, ?, and %; URL components and HTML document routing pass");
} }
'''
    (work / 'file-url.m').write_text(harness)
    subprocess.run(['xcrun', 'clang', '-fobjc-arc', '-Wall', '-Wextra', '-Werror',
                    '-framework', 'Foundation', str(work / 'file-url.m'),
                    '-o', str(work / 'file-url-test')], check=True)
    subprocess.run([str(work / 'file-url-test')], check=True)
