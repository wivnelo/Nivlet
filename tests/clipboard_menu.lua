package.path='Toolkit/?.lua;'..package.path
local canvases,deleted={},0
hs={settings={get=function() end},timer={secondsSinceEpoch=function() return 1000 end,doAfter=function() return {stop=function() end} end},application={frontmostApplication=function() return nil end},
 drawing={getTextDrawingSize=function(text,style) assert(style.size==14);return {w=utf8.len(text)*14} end},
 canvas={new=function(frame)
  assert(frame.w>0 and frame.w<=360 and frame.h>0 and frame.h<=260)
  local canvas={imageFromCanvas=function(self) return {canvas=self,size=function() return {w=self.frame.w,h=self.frame.h} end} end,frame=frame,delete=function() deleted=deleted+1 end}
  canvases[#canvases+1]=canvas;return canvas
 end}}
local c=require('modules.clipboard');c.config=c.defaults()
local preview={size=function() return {w=120,h=90} end};local original={size=function() return {w=640.5,h=480} end,encodeAsURLString=function() return "data:image/png;base64,YWJj" end}
c.entries={{id=1,kind='text',time=1000,text='  第一行\n第二行\t'..string.rep('内容',30)},{id=2,kind='image',time=1000,image=original,thumb=preview}}
local menu=c.menuItems();local text,image=menu[5],menu[3]
assert(menu[4].title=="-")
assert(text.image and image.image and text.image~=image.image)
assert(text.image.canvas[2].text=='T' and text.image.canvas[1].roundedRectRadii.xRadius==5)
assert(image.image.canvas[2].image==preview and image.image.canvas[2].imageScaling=='scaleToFit','Menu icons use the small thumbnail')
assert(image.image.canvas[2].frame.w==20 and image.image.canvas[2].frame.h==20)
assert(text.title:find('第一行 第二行',1,true) and text.title:sub(-3)=='…' and utf8.len(text.title)*14<=240)
assert(text.tooltip==c.entries[1].text)
assert(image.title:match('^图片 .* · .* KB · %d%d%-%d%d %d%d:%d%d') and image.menu[1].image)
assert(c.entries[2].thumb==preview and c.entries[2].image==original)
local second=c.menuItems();assert(second[5].image==text.image and second[3].image==image.image)
assert(#canvases==3 and deleted==3,'Menu icons and previews should be cached and canvases released')
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

-- Restored history: the menu shows the stored preview and size without reading the full image.
c.entries={{id=5,kind="image",time=1000,path="/nowhere/clip_1_5.png",preview=preview,width=2560,height=1440,menuBytes=2048}}
menu=c.menuItems();assert(menu[3].title:find("2560×1440",1,true) and menu[3].menu[1].image==preview)
assert(c.entries[1].image==nil,'The full image stays on disk until it is copied, pinned or opened')
print("Restored images use the stored preview and size without loading the full image passed")

-- Long entries: only the start is measured, and the label is cached on the entry.
local measured,longest=0,0
hs.drawing.getTextDrawingSize=function(text) measured=measured+1;longest=math.max(longest,utf8.len(text));return {w=utf8.len(text)*7} end
c.entries={{id=9,kind="text",time=1000,text=string.rep("长文本 ",20000)}}
menu=c.menuItems();assert(menu[3].title:sub(-3)=="…" and longest<=101,"Only the first 100 characters are measured")
local first=measured;c.menuItems();assert(measured==first,"Menu labels are cached per entry")
c.entries[1].menuLabel=nil;c.prepare(c.entries[1]);assert(c.entries[1].menuLabel==menu[3].title)
print("Long text labels measure at most 100 characters and are cached passed")
