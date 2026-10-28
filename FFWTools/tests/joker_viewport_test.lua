package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local e=dofile('FFWTools/tests/joker_engine.lua').install()
package.preload.UEHelpers=function() return e.helpers end
local P,I=require('Panel'),require('Inventory')
local checks=0
local function check(ok,label) checks=checks+1;assert(ok,label) end
local ids={};for _,c in ipairs(require('Cards').all()) do if c.scope=='hero' and c.enabled and #ids<18 then ids[#ids+1]=c.id end end
local snapshot=I.fromSnapshot{selected={primary='itemShotgun',secondary='itemDualRevolver'},equipped={itemHero=ids},upgrades={},runtime={}}
for _,screen in ipairs({{1280,720,2},{1024,768,1},{1280,720,.75},{1920,1080,1.5},{2560,1440,2},{3840,2160,2}}) do
    e.viewport={width=screen[1],height=screen[2],dpiScale=screen[3]}
    local clicks={};local view=P.createView(nil,function(action,value) clicks[#clicks+1]={action,value} end)
    check(view.widget.desired.X*screen[3]<=screen[1],'F7 width fits the actual viewport/DPI')
    check(view.widget.desired.Y*screen[3]<=screen[2],'F7 height fits the actual viewport/DPI')
    local page=P.page(snapshot,1,view.layout.rows);P.render(view,page,true)
    check(page.pageSize==view.layout.rows,'pagination matches the visible row count')
    local before=view.mouse.buttons['row-1'].label.text
    e.click(view.mouse.buttons['row-2'].button)
    check(clicks[1][1]=='select' and clicks[1][2]==2,'mouse row selection survives resized geometry')
    P.render(view,P.page(snapshot,2,view.layout.rows),true)
    check(view.mouse.buttons['row-1'].label.text==before,'selection does not insert a width-changing marker')
    for _,entry in pairs(view.mouse.buttons) do
        if entry.visible then
            check(entry.label.AutoWrapText==false,'button labels stay on one line')
            check(entry.label.TextOverflowPolicy==1,'native TextOverflowPolicy uses ellipsis')
            check(entry.label.Slot.horizontalAlignment==0 and entry.label.Slot.verticalAlignment==2,'button text fills and centers within its slot')
            check(entry.slot.position.X>=0 and entry.slot.position.Y>=0,'button is inside top/left bounds')
            check(entry.slot.position.X+entry.slot.size.X<=view.layout.width,'button is inside right edge')
            check(entry.slot.position.Y+entry.slot.size.Y<=view.layout.height,'button is inside bottom edge')
            check(entry.slot.size.Y-4>=entry.label.Font.Size*1.5,'font line has room after vertical padding')
        end
    end
    check(view.title.text==P.page(snapshot,2,view.layout.rows).title,'full selected title is retained')
    check(view.detailScroll.Slot.size.Y>0,'full F7 rules retain a usable scroll area')
    P.destroyView(view)
end
-- In-place resize changes pagination/geometry without replacing the input owner.
e.viewport={width=1920,height=1080,dpiScale=1}
local view=P.createView();local mouse=view.mouse
P.render(view,P.page(snapshot,1,view.layout.rows),true)
e.viewport={width=1280,height=720,dpiScale=2};P.refreshLayout(view)
P.render(view,P.page(snapshot,1,view.layout.rows),true)
check(view.mouse==mouse,'resize does not acquire a second cursor/look lease')
check(e.controller.lookIgnores==1,'one visible overlay retains exactly one look lock')
P.destroyView(view);check(e.controller.lookIgnores==0,'normal close restores look input')
e.restore()
print('joker_viewport_test: '..checks..' checks passed')
