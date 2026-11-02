
dofile('tests/runtime.lua')
local app=desktopToolkit
local i18n=require('modules.i18n')
local function general(language)
 local value={};for key,item in pairs(app.general) do value[key]=item end
 value.language=language;return value
end
for _,language in ipairs({'zh-Hans','en','zh-Hant','ja','system'}) do
 assert(app.saveGeneral(general(language)))
 assert(app.general.language==language and hs.settings.get('desktoptoolkit.general.v1').language==language)
 assert(i18n.mode==language)
 local exported=app.configuration.export()
 assert(exported.modules.general.language==language)
 local imported={format='Nivlet',version=1,modules={general=general(language)}}
 assert(app.configuration.prepare(imported))
 assert(app.configuration.apply(imported))
 assert(hs.settings.get('desktoptoolkit.general.v1').language==language)
end
local before=app.general.language
assert(not app.saveGeneral(general('fr')))
assert(not app.configuration.prepare({format='Nivlet',version=1,modules={general=general('fr')}}))
assert(app.general.language==before)
assert(app.saveGeneral(general(nil)))
assert(app.general.language=='system','Legacy preferences without language must retain system mode')
print('Four languages plus system persist, export/import, invalid rejection and legacy missing-language default passed')
