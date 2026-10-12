package.path='Toolkit/?.lua;'..package.path
local preferred={'en-US'}
hs={host={locale={preferredLanguages=function() return preferred end}},settings={get=function() return nil end}}
local i=require('modules.i18n')
assert(i.mode=='system' and i.language()=='en')
for _,locale in ipairs({'zh-Hans-CN','zh-CN','zh-TW'}) do preferred={locale};assert(i.language()=='zh-Hans') end
for _,locale in ipairs({'en-US','fr-FR'}) do preferred={locale};assert(i.language()=='en') end
preferred={};assert(i.language()=='en')
i.configure('zh-Hans');assert(i.t('设置…')=='设置…')
i.configure('en');assert(i.t('设置…')=='Settings…')
assert(i.t('用户自己的内容')=='用户自己的内容')
i.configure('system');preferred={'zh-Hans'};assert(i.t('设置…')=='设置…')
print('System language selection, explicit overrides and unknown content preservation passed')
