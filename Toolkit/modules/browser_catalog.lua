local M={}
-- Only these browsers participate in routing. Clear-data adapters are verified per browser.
M.browsers={
    {id="com.apple.Safari",name="Safari",clearDataAdapter="safariHistory"},
    {id="com.google.Chrome",name="Chrome",clearDataAdapter="chromeShortcut"},
    {id="org.mozilla.firefox",name="Firefox"},
    {id="com.microsoft.edgemac",name="Edge"},
    {id="com.brave.Browser",name="Brave",clearDataAdapter="braveShortcut"},
}
function M.get(id)
    for _,browser in ipairs(M.browsers) do if browser.id==id then return browser end end
end
return M
