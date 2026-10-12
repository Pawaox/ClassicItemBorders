local addon=...
local db={}
local _b,_t,_char,_bank,_mul={},{},{},{},{[2]=.75,[3]=1.4,[4]=1.6}
local pending
local function Chat(m) print("|cFF4FC0C4[ClassicItemBorder]:|r |cFF40C24F"..m.."|r") end
local function Create(btn)
	local brd=btn:CreateTexture(nil,"OVERLAY")
	brd:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	brd:SetBlendMode("ADD")
	brd:SetAlpha(0.7)
	brd:SetSize(68,68)
	brd:SetPoint("CENTER",btn,"CENTER",0,0)
	brd:Hide()
	local t=btn:CreateFontString(nil,"OVERLAY")
	t:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
	t:SetPoint("CENTER",btn,"CENTER",2,-1)
	t:SetTextColor(1,1,1)
	t:Hide()
	_b[btn],_t[btn]=brd,t
	return brd,t
end
local function Display(btn,iLnk,q)
	if not btn then return end
	local brd,ilt=_b[btn],_t[btn]
	if not brd then brd,ilt=Create(btn) end
	local showB,showI
	if iLnk then
		local _,_,_,_,_,c=C_Item.GetItemInfoInstant(iLnk)
		if not q or q<0 then q=select(3,C_Item.GetItemInfo(iLnk)) end
		if not q then pending=true end
		if c==12 then
			brd:SetVertexColor(1,1,.1)
			showB=true
		elseif q and q>1 then
			local r,g,b=C_Item.GetItemQualityColor(q)
			local m=_mul[q] or 1
			brd:SetVertexColor(r*m,g*m,b*m)
			showB=true
			if db[2]~=false and (c==2 or c==4) then
				local il=C_Item.GetDetailedItemLevelInfo(iLnk)
				if il and il>1 then
					ilt:SetText(il)
					showI=true
				elseif not il then
					pending=true
				end
			end
		end
	end
	brd:SetShown(showB and db[3]~=false)
	ilt:SetShown(showI)
end
local function UpdateChar(btn)
	_char[btn]=true
	local s=btn:GetID()
	Display(btn,GetInventoryItemLink("player",s),GetInventoryItemQuality("player",s))
end
local function UpdateBag(frame)
	local bag,name=frame:GetID(),frame:GetName()
	for i=1,frame.size or 0 do
		local btn=_G[name.."Item"..i]
		if btn then
			local info=C_Container.GetContainerItemInfo(bag,btn:GetID())
			Display(btn,info and info.hyperlink,info and info.quality)
		end
	end
end
local function UpdateBank(btn)
	if not (btn and btn.GetInventorySlot) then return end
	_bank[btn]=true
	local s=btn:GetInventorySlot()
	Display(btn,GetInventoryItemLink("player",s),GetInventoryItemQuality("player",s))
end
local function UpdateMerchant()
	local off=((MerchantFrame.page or 1)-1)*MERCHANT_ITEMS_PER_PAGE
	for i=1,MERCHANT_ITEMS_PER_PAGE do
		Display(_G["MerchantItem"..i.."ItemButton"],GetMerchantItemLink(off+i))
	end
end
local function UpdateBuyback()
	for i=1,BUYBACK_ITEMS_PER_PAGE do
		Display(_G["MerchantItem"..i.."ItemButton"],GetBuybackItemLink(i))
	end
end
local function Hook(f,fn) if _G[f] then hooksecurefunc(f,fn) end end
Hook("PaperDollItemSlotButton_Update",UpdateChar)
Hook("ContainerFrame_Update",UpdateBag)
Hook("BankFrameItemButton_Update",UpdateBank)
Hook("MerchantFrame_UpdateMerchantInfo",UpdateMerchant)
Hook("MerchantFrame_UpdateBuybackInfo",UpdateBuyback)
local function Refresh()
	pending=nil
	for btn in pairs(_char) do UpdateChar(btn) end
	for i=1,NUM_CONTAINER_FRAMES or 13 do
		local f=_G["ContainerFrame"..i]
		if f and f:IsShown() then UpdateBag(f) end
	end
	if BankFrame and BankFrame:IsShown() then
		for btn in pairs(_bank) do UpdateBank(btn) end
	end
	if MerchantFrame and MerchantFrame:IsShown() then
		if MerchantFrame.selectedTab==2 then UpdateBuyback() else UpdateMerchant() end
	end
end
local function Toggle(keys,val,label)
	if val=="on" or val=="enable" or val=="yes" or val=="y" then
		for _,k in ipairs(keys) do db[k]=true end
	elseif val=="off" or val=="disable" or val=="no" or val=="n" then
		for _,k in ipairs(keys) do db[k]=false end
	end
	Chat(label..(db[keys[1]]~=false and "on" or "off"))
	Refresh()
end
SLASH_CITEMBRD1="/itemborder"
SLASH_CITEMBRD2="/iborder"
SlashCmdList["CITEMBRD"]=function(msg)
	local p1,p2=msg:lower():match("(%S*)%s*(%S*)")
	if p1=="ilvl" then
		Toggle({2},p2,"ItemLevels are ")
	elseif p1=="border" or p1=="borders" then
		Toggle({3},p2,"Borders are ")
	elseif p1~="" then
		Toggle({2,3},p1,"ItemLevels and borders are ")
	else
		Chat("/iborder ilvl 'on/off' toggles the itemlevels")
		Chat("/iborder border 'on/off' toggles the colored borders")
		Chat("/iborder 'on/off' toggles both")
	end
end
local frm=CreateFrame("Frame")
frm:RegisterEvent("ADDON_LOADED")
frm:RegisterEvent("GET_ITEM_INFO_RECEIVED")
frm:SetScript("OnEvent",function(self,event,arg1)
	if event=="ADDON_LOADED" then
		if arg1~=addon then return end
		self:UnregisterEvent("ADDON_LOADED")
		SV_iborder=SV_iborder or {}
		db=SV_iborder
		if db[1]==false then db[2],db[3]=false,false end
		db[1],db.showItemLevel=nil,nil
	elseif pending then
		pending=nil
		C_Timer.After(0.2,Refresh)
	end
end)