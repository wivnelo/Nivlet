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
series = (root / 'patches/series').read_text().split()
assert series.index('browser-file-url.patch') > series.index('browser-url-only.patch')

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

        reverse = subprocess.run(['git', 'apply', '--reverse', '--check', str(patch)],
                                 cwd=work, capture_output=True, text=True)
        if reverse.returncode:
            raise RuntimeError('Native file URL patch does not match runtime source:\n' + check.stderr)

    source = (work / relative).read_text()
    callback = source.index('- (void)callbackWithURL:(NSString *)openUrl senderPID:(pid_t)pid {')
    start = source.index('    if ([openUrl hasPrefix:@"/"]) {', callback)
    end = source.index('    if (!url) {', start)
    conversion = source[start:end]
    query_start = source.index('    NSString *query = [url query];', end)
    query_end = source.index('    [skin pushLuaRef:', query_start)
    query_parsing = source[query_start:query_end]
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
    harness += ('static NSDictionary *QueryPairsForURL(NSURL *url) {\n'
                + query_parsing + '    return pairs;\n}\n')
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

    // Invalid UTF-8 query escapes must not crash native handling before the
    // full URL reaches Lua. Valid entries and the URL itself remain unchanged.
    for (NSString *input in @[
        @"https://example.com/?x=%FF",
        @"https://example.com/?%FF=1",
        @"https://example.com/?x=%E4%B8",
        @"file:///tmp/plain.html?x=%FF",
        @"file:///tmp/plain.html?%FF=1"
    ]) {
        NSURL *url = URLForInput(input);
        assert(url);
        assert(QueryPairsForURL(url).count == 0);
        assert([url.absoluteString isEqualToString:input]);
    }
    NSURL *mixedQuery = URLForInput(@"https://example.com/?good=a%26b&bad=%FF&%FF=1&unicode=%E4%B8%AD%E6%96%87");
    NSDictionary *mixedPairs = QueryPairsForURL(mixedQuery);
    assert(mixedPairs.count == 2);
    assert([mixedPairs[@"good"] isEqualToString:@"a&b"]);
    assert([mixedPairs[@"unicode"] isEqualToString:@"中文"]);
    // Preserve the established auxiliary-dictionary rules, including last-key
    // wins, empty keys/values, and omission of pairs with no or multiple '='.
    NSDictionary *existingPairs = QueryPairsForURL(URLForInput(@"https://example.com/?repeat=first&repeat=last&empty=&=value&missing&multiple=a=b"));
    assert(existingPairs.count == 3);
    assert([existingPairs[@"repeat"] isEqualToString:@"last"]);
    assert([existingPairs[@"empty"] isEqualToString:@""]);
    assert([existingPairs[@""] isEqualToString:@"value"]);
    assert(QueryPairsForURL(URLForInput(@"https://example.com/no-query")).count == 0);

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
    puts("Native path encoding, HTML document routing, and malformed-query handling pass");
} }
'''
    (work / 'file-url.m').write_text(harness)
    subprocess.run(['xcrun', 'clang', '-fobjc-arc', '-Wall', '-Wextra', '-Werror',
                    '-framework', 'Foundation', str(work / 'file-url.m'),
                    '-o', str(work / 'file-url-test')], check=True)
    subprocess.run([str(work / 'file-url-test')], check=True)
