package.path='Toolkit/?.lua;'..package.path
local assigned,taken={},{}
hs={hotkey={systemAssigned=function(mods,key) return assigned[table.concat(mods,'+')..'+'..key] end,assignable=function(mods,key) return not taken[table.concat(mods,'+')..'+'..key] end}}
local p=require('modules.preferences')
assert(p.signature({key='K',mods={'ctrl','alt'}})=='ctrl+alt+K')
assert(p.same({key='K',mods={'ctrl','alt'}},{key='K',mods={'ctrl','alt'}}))
assert(not p.same({key='K',mods={'ctrl'}},{key='K',mods={'ctrl','alt'}}) and not p.same(nil,{key='K',mods={}}) and not p.same({key='K',mods={}},nil))
local item=p.normalize({key='k',mods={'alt','ctrl'}});assert(item.key=='K' and table.concat(item.mods,'+')=='ctrl+alt','Normalized key and modifier order')
assert(p.normalize({key='',mods={'ctrl'}})==nil and select(2,p.normalize({key='',mods={'ctrl'}}))==nil,'Empty key clears without error')
local none,message=p.normalize({key='K',mods={'shift'}});assert(none==nil and type(message)=='string','Invalid shortcut returns its message')
assert(p.bindable({'cmd'},'L'))
assigned['cmd+L']={enabled=true};assert(not p.bindable({'cmd'},'L'),'System-assigned shortcut is not bindable')
assigned['cmd+L']=nil;taken['cmd+L']=true;assert(not p.bindable({'cmd'},'L'),'Unassignable shortcut is not bindable')
print('Shortcut signature, equality, normalization and bindability helpers passed')
