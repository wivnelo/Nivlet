package.path='Toolkit/?.lua;'..package.path
local preferred,stored={'en-US'},nil
hs={host={locale={preferredLanguages=function() return preferred end}},settings={get=function() return stored end}}
local i=require('modules.i18n')
assert(i.mode=='system' and i.language()=='en')
local cases={
 ['zh-Hans-CN']='zh-Hans',['zh-Hans-TW']='zh-Hans',['zh_Hans_HK']='zh-Hans',['zh-CN']='zh-Hans',['zh-SG']='zh-Hans',['zh']='zh-Hans',
 ['zh-Hant']='zh-Hant',['zh-Hant-CN']='zh-Hant',['zh-TW']='zh-Hant',['zh_HK']='zh-Hant',['zh-MO']='zh-Hant',
 ['ja']='ja',['ja-JP']='ja',['ja_JP']='ja',['en-US']='en',['fr-FR']='en',
}
for locale,language in pairs(cases) do preferred={locale};assert(i.language()==language,locale) end
for _,value in ipairs({{},false,{false}}) do preferred=value;assert(i.language()=='en') end
local lookup=hs.host.locale.preferredLanguages
hs.host.locale.preferredLanguages=nil;assert(i.language()=='zh-Hans')
hs.host.locale.preferredLanguages=function()error('Locale unavailable')end;assert(i.language()=='zh-Hans')
hs.host.locale.preferredLanguages=lookup
for _,language in ipairs({'zh-Hans','en','zh-Hant','ja'}) do
 i.configure(language);preferred={'fr-FR'};assert(i.language()==language)
 assert(i.t('用户自己的内容')=='用户自己的内容')
 assert(i.t('com.example.App')=='com.example.App')
 local dictionary=i.translations()
 assert(type(dictionary)=='table' and dictionary.ja==nil and dictionary['zh-Hant']==nil,'Bridge must send only the active dictionary')
 if language=='zh-Hans' then assert(next(dictionary)==nil and i.t('设置…')=='设置…')
 else
  assert(dictionary['设置…'] and i.t('设置…')==dictionary['设置…'])
  local saved=dictionary['设置…'];dictionary['设置…']=nil;assert(i.t('设置…')=='设置…');dictionary['设置…']=saved
 end
end
i.configure('en');assert(i.translations()==i.dictionary and i.t('设置…')=='Settings…','English dictionary API compatibility')
i.configure('invalid');preferred={'ja-JP'};assert(i.mode=='system' and i.language()=='ja')
for _,value in ipairs({{},{language='system'},{language='zh-Hans'},{language='en'},{language='zh-Hant'},{language='ja'},{language='invalid'}}) do
 stored=value;package.loaded['modules.i18n']=nil;i=require('modules.i18n')
 local expected=(value.language=='zh-Hans' or value.language=='en' or value.language=='zh-Hant' or value.language=='ja') and value.language or 'system'
 assert(i.mode==expected,'Stored preference migration failed')
end
local english=require('modules.translations')
local function formats(text)
 local result={};for spec in text:gmatch('%%[-+ #0]*%d*%.?%d*[cdeEfgGiouxXqs]') do result[#result+1]=spec end
 for spec in text:gmatch('{[%w_]+}') do result[#result+1]=spec end
 return table.concat(result,'|')
end
local count=0;for _ in pairs(english) do count=count+1 end
for _,module in ipairs({'modules.translations_zh_hant','modules.translations_ja'}) do
 local dictionary=require(module);local actual=0
 for key,value in pairs(dictionary) do
  actual=actual+1;assert(english[key]~=nil,'Extra key: '..key)
  assert(type(value)=='string' and value:find('%S'),'Empty translation: '..key)
  assert(formats(key)==formats(value),'Placeholder mismatch: '..key)
 end
 for key in pairs(english) do assert(dictionary[key]~=nil,'Missing key: '..key) end
 assert(actual==count,'Dictionary coverage differs')
end
print('Four-language system mapping, explicit/stored preferences, API fallback, missing keys, active-only catalogues and '..count..'-key placeholder parity passed')
