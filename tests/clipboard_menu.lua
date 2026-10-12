package.path='Toolkit/?.lua;'..package.path
local canvases,deleted={},0
hs={settings={get=function() end},timer={secondsSinceEpoch=function() return 1000 end},application={frontmostApplication=function() return nil end},
 drawing={getTextDrawingSize=function(text,style) assert(style.size==14);return {w=utf8.len(text)*14} end},
 canvas={new=function(frame)
  assert(frame.w>0 and frame.w<=360 and frame.h>0 and frame.h<=260)
  local canvas={imageFromCanvas=function(self) return {canvas=self} end,delete=function() deleted=deleted+1 end}
  canvases[#canvases+1]=canvas;return canvas
 end}}
local c=require('modules.clipboard');c.config=c.defaults()
local preview={};local original={size=function() return {w=640.5,h=480} end,encodeAsURLString=function() return "data:image/png;base64,YWJj" end}
c.entries={{id=1,kind='text',time=1000,text='  第一行\n第二行\t'..string.rep('内容',30)},{id=2,kind='image',time=1000,image=original,thumb=preview}}
local menu=c.menuItems();local text,image=menu[5],menu[3]
assert(menu[4].title=="-")
assert(text.image and image.image and text.image~=image.image)
assert(text.image.canvas[2].text=='T' and text.image.canvas[1].roundedRectRadii.xRadius==5)
assert(image.image.canvas[2].image==original and image.image.canvas[2].imageScaling=='scaleToFit')
assert(image.image.canvas[2].frame.w==20 and image.image.canvas[2].frame.h==20)
assert(text.title:find('第一行 第二行',1,true) and text.title:sub(-3)=='…' and utf8.len(text.title)*14<=240)
assert(text.tooltip==c.entries[1].text)
assert(image.title:match('^图片 .* · .* KB · %d%d%-%d%d %d%d:%d%d') and image.menu[1].image)
assert(c.entries[2].thumb==preview and c.entries[2].image==original)
local second=c.menuItems();assert(second[5].image==text.image and second[3].image==image.image)
assert(#canvases==3 and deleted==3,'Menu icons should be cached and canvases released')
print('Clipboard menu: aligned 24-point text/image tiles, aspect fit, UTF-8 width, original tooltip, metadata, caching and original image preservation passed')

c.entries={{id=1,kind="text",time=1000,text="new text"},{id=2,kind="image",time=999,image=original},{id=3,kind="text",time=998,text="old text"},{id=4,kind="image",time=997,image=original}}
menu=c.menuItems();assert(menu[3].title:find("图片",1,true) and menu[4].title:find("图片",1,true) and menu[5].title=="-")
assert(menu[6].title=="new text" and menu[7].title=="old text")
assert(c.entries[1].id==1 and c.entries[2].id==2 and c.entries[3].id==3 and c.entries[4].id==4)
local selected;c.copy=function(id) selected=id;return true end
menu[3].fn();assert(selected==2);menu[4].fn();assert(selected==4);menu[6].fn();assert(selected==1)
for _,kind in ipairs({"text","image"}) do
 c.entries={kind=="image" and {id=1,kind=kind,time=1000,image=original} or {id=1,kind=kind,time=1000,text="only text"}}
 menu=c.menuItems();assert(menu[3].title~="-" and menu[4].title=="-" and menu[5].title~="-")
end
c.entries={};menu=c.menuItems();assert(menu[3].disabled)
print("Menu image/text groups preserve recency, copy targets and settings chronology; single and empty groups passed")
