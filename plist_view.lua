package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")
require("LuaXML_lib")

local m_frame = nil
local m_draw = nil;		-- 绘制用的panel
local m_listCtrl = nil;
local m_scrollWin = nil;

local m_img = nil;		-- 图片
local m_rect = nil;

local m_frame_list = nil;	-- 数据块列表
local m_state_string = '';

local m_frame_name = 'xxxx';

function OnPaint(event)
	local dc = wx.wxPaintDC(m_draw)
	if (m_img) then
		dc:DrawBitmap(m_img, 0, 0, false)
	end
	if (m_rect) then
		dc:SetPen(wx.wxPen(wx.wxColour(0,0,0,255), 3, wx.wxSOLID));
		dc:SetBrush(wx.wxBrush(wx.wxColour(255,255,255,255), wx.wxTRANSPARENT));
		dc:DrawRectangle(m_rect.x, m_rect.y, m_rect.w, m_rect.h);
	end
	dc:delete()
end

local function get_rect(str)
	local ret = {};
	string.gsub(str, "%w+", function(a)  table.insert(ret, a); end);
	return {x = ret[1], y = ret[2], w = ret[3], h = ret[4]};
end

function OnOpenImage(event)
	local plistfn = wx.wxFileSelector("Select plist file")
    if ( not plistfn or plistfn == '' ) then
        return
    end
	
	local idx = string.find(plistfn, '.plist');
	if (idx == nil) then
		print("please select a plist and img in same path");
		return;
	end
	
	local imgfn = string.sub(plistfn, 1, idx)..'png';
	local image = wx.wxImage()
	if ( not image:LoadFile(imgfn) ) then
        wx.wxLogError("Couldn't load image from '%s'.", imgfn)
        return
    end
	
	m_img = wx.wxBitmap(image);
	local height = m_img:GetHeight();
	local width = m_img:GetWidth();
	m_draw:SetSize(width, height);
	m_state_string = width.."x"..height.." ==>" ..imgfn;
	m_frame:SetStatusText(m_state_string);
	
	-- 分解数据和块
	local plist = xml.load(plistfn)
	local plist_tag = plist[1]
	local t = plist_tag[2];
	local num = #t;
	
	m_frame_list = {};
	local frame_name = nil;
	local r = nil; 
	for i = 1, num, 2 do
		frame_name = t[i][1];
		r = get_rect(t[i+1][2][1]);
		local data = {frame=frame_name,x=tonumber(r.x),y=tonumber(r.y),w=tonumber(r.w),h=tonumber(r.h)};
		table.insert(m_frame_list, data);
	end
	
	-- 更新数据列表
	m_listCtrl:ClearAll();
	m_listCtrl:InsertColumn(0, "frame name")
	m_listCtrl:SetColumnWidth(0, 200);
	for i, d in ipairs(m_frame_list) do
		m_listCtrl:InsertItem(i - 1, d.frame);
	end
	m_listCtrl:Refresh();
end

ID_OPEN_IMG = 1001;
ID_LISTCTRL = 5001
ID_SPLITTERWINDOW = 5002
ID_PARENT_SCROLLEDWINDOW = 5003

--============================================================
--
function AddControlList(parent)
	local control = wx.wxListCtrl(parent, ID_LISTCTRL,
                            wx.wxDefaultPosition, wx.wxSize(100, 200),
                            wx.wxLC_REPORT)
	control:InsertColumn(0, "frame name")
	
	
	control:Connect(wx.wxEVT_COMMAND_LIST_ITEM_SELECTED , function(event)
		local listCtrl = event:GetEventObject():DynamicCast("wxListCtrl")
		for n = 1, listCtrl:GetItemCount() do
            local s = listCtrl:GetItemState(n-1, wx.wxLIST_STATE_SELECTED)
            if s ~= 0 then
				local data = m_frame_list[n];
				m_rect = data;
				m_draw:Refresh();
				m_frame:SetStatusText(m_state_string.."   "..data.frame);
				m_frame_name = data.frame;
				break;
			end
		end
	end);
	return control;
end
--============================================================
--
function OnLeftDown(event)
	for n = 1, m_listCtrl:GetItemCount() do
		m_listCtrl:SetItemState(n - 1, n - 1, wx.wxLIST_STATE_DONTCARE);
	end
	
	local x, y = event:GetPositionXY()
	for i, d in ipairs(m_frame_list) do
		if (d.x < x and d.x + d.w > x and d.y < y and d.y + d.h > y) then
			m_rect = d;
			m_draw:Refresh();
			m_frame:SetStatusText(m_state_string.."   "..d.frame);
			m_frame_name = d.frame;
			m_listCtrl:SetItemState(i - 1, i - 1, wx.wxLIST_STATE_SELECTED);
		end
	end
end

function OnRightDown(event)
	local clipBoard = wx.wxClipboard.Get()
    if clipBoard and clipBoard:Open() then
        clipBoard:SetData(wx.wxTextDataObject(m_frame_name))
        clipBoard:Close()
    end
end

--============================================================
--
function AddControlDraw(parent)
	--control = wx.wxSlider(scrollWin, ID_SLIDER, 10, 0, 100, wx.wxDefaultPosition, wx.wxSize(200, -1))
	local scrollWin = wx.wxScrolledWindow(parent, ID_PARENT_SCROLLEDWINDOW,
                                    wx.wxDefaultPosition, wx.wxDefaultSize,
                                    wx.wxHSCROLL + wx.wxVSCROLL)

    scrollWin:SetScrollbars(15, 15, 400, 1000, 0, 0, false)
	
	local panel = wx.wxPanel(scrollWin, wx.wxID_ANY)
	panel:SetBackgroundColour(wx.wxColour(255, 100, 100));
	panel:Connect(wx.wxEVT_PAINT, OnPaint)
	return panel, scrollWin;
end


--============================================================
--
function OnAbout(event)
		wx.wxMessageBox('This is the "About" dialog of the Minimal wxLua sample.\n'..
						wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
						"About wxLua",
						wx.wxOK + wx.wxICON_INFORMATION,
						frame)
end 

function OnCopy(event)
	OnRightDown(event);
end

--============================================================
--
function AddFrame()
	local frame = wx.wxFrame( wx.NULL, wx.wxID_ANY,"wxLua Minimal Demo",wx.wxDefaultPosition,wx.wxSize(800, 600), wx.wxDEFAULT_FRAME_STYLE )
	local fileMenu = wx.wxMenu()
	local menuBar = wx.wxMenuBar()
    local helpMenu = wx.wxMenu()
	
	fileMenu:Append(ID_OPEN_IMG, "O&pen", "open image")
	fileMenu:Append(wx.wxID_COPY, "Copy\tCtrl+C", "open image")
	fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")
    helpMenu:Append(wx.wxID_ABOUT, "&About", "About the wxLua Minimal Application")
    
	frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED, function (event) frame:Close(true) end )
	frame:Connect(ID_OPEN_IMG, wx.wxEVT_COMMAND_MENU_SELECTED, OnOpenImage)
	frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED, OnAbout);
	frame:Connect(wx.wxID_COPY, wx.wxEVT_COMMAND_MENU_SELECTED, OnCopy);
	
    menuBar:Append(fileMenu, "&File")
    menuBar:Append(helpMenu, "&Help")
	
    frame:SetMenuBar(menuBar)
    frame:CreateStatusBar(1)
    frame:SetStatusText("Welcome to wxLua.")
	return frame;
end

--============================================================
--
function main()
	m_frame = AddFrame();
	
	splitter = wx.wxSplitterWindow(m_frame, wx.wxID_ANY)
    splitter:SetMinimumPaneSize(50)
    splitter:SetSashGravity(.8)
	
	m_draw,m_scrollWin = AddControlDraw(splitter);
	m_listCtrl = AddControlList(splitter);
	
	m_draw:Connect(wx.wxEVT_LEFT_DOWN, OnLeftDown )
	m_draw:Connect(wx.wxEVT_RIGHT_DOWN, OnRightDown )
	
	
	splitter:SplitVertically(m_scrollWin,m_listCtrl,500)
    m_frame:Show(true)
end

main()
wx.wxGetApp():MainLoop()