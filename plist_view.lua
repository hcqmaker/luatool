package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")
require("LuaXML_lib")

local APP_DESCTION = ' 说明: 工具提供对plist资源图片的一个显示和选择;\n' ..
	'操作:\n'..
	'	打开: 选择plist文件或者图片文件会把plist进行加载\n'..
	'	保存选择的块: 直接把当前块保持到指定目录中\n'..
	'	保存所有: 把所有的块直接保存到指定目录中\n'..
	'	关闭: 直接关闭应用\n'..
	'	图片块操作:\n'..
	'		鼠标左键点击图片块Ctrl + C复制图片的名字\n'..
	'		或者鼠标右键点击图片也可以直接复制\n'..
	'	from: hcqmaker@gmail.com\n';
	

L ={
	FILE = '文件',
	HELP = '帮助',
	TITLE = 'Plist查看器',
	OPEN = '打开',
	COPY = '复制',
	SAVE = '保存选择块',
	SAVE_ALL = '保存所有块',
	EXIT = '关闭',
	ABOUT = '关于',
	
	
	OPEN_DES = '选择打开plist资源文件/图片文件',
	COPY_DES = '复制选择的图片块的名字',
	EXIT_DES = '关闭应用',
	ABOUT_DES = '关于应用',
	SAVE_DES = '保存当前选中的图片块',
	SAVE_ALL_DES = '保存所有图片块',
	
	FRAME_NAME = '图片块名字',
	
	WIN_BOTTOM = '欢迎使用Plist查看器',
	
	SAVE_OPEN_PATH = '选择保存的目录',
	SAVE_SAME_FILE = '有相同文件是否进行保存?',
	SAVE_FILE = '保存文件',
	
	ERR_UN_SELECT_FRAME = '没有选到数据库',
	ERR_SAVE_FILE_FAIL = '保存文件失败',
}

--===================================
-- 变量部分
--===================================
local m_window = nil
local m_canvas = nil;		-- 绘制用的panel
local m_listCtrl = nil;
local m_scrollWin = nil;

local m_select_img = nil;		-- 图片
local m_select_rect = nil;

local m_plist_frame_t = nil;	-- 数据块列表
local m_state_string = '';

local m_frame_name = 'xxxx';
local m_default_path = '';

--========================================================
-- ID标识
--========================================================
ID_OPEN_IMG = 1001
ID_SAVE_IMG = 1003
ID_SAVE_ALL = 1004
ID_LISTCTRL = 5001
ID_SPLITTERWINDOW = 5002
ID_PARENT_SCROLLEDWINDOW = 5003

--========================================================
function OnPaint(event)
	local dc = wx.wxPaintDC(m_canvas)
	if (m_select_img) then
		dc:DrawBitmap(m_select_img, 0, 0, false)
	end
	if (m_select_rect) then
		dc:SetPen(wx.wxPen(wx.wxColour(0,0,0,255), 3, wx.wxSOLID));
		dc:SetBrush(wx.wxBrush(wx.wxColour(255,255,255,255), wx.wxTRANSPARENT));
		dc:DrawRectangle(m_select_rect.x, m_select_rect.y, m_select_rect.w, m_select_rect.h);
	end
	dc:delete()
end
--========================================================
-- 获取plist中一个信息块的矩形区域
local function parse_rect(str)
	local ret = {};
	string.gsub(str, "%w+", function(a)  table.insert(ret, a); end);
	return {x = ret[1], y = ret[2], w = ret[3], h = ret[4]};
end
--========================================================
function OnOpenFileDrawing(filename)
	local plistfilename = nil;
	local imagefilename = nil;
	
	if (string.find(filename, '.plist') ~= nil) then
		local idx = string.find(filename, '.plist');
		imagefilename = string.sub(filename, 1, idx)..'png';
		plistfilename = filename;
	elseif(string.find(filename, '.png') ~= nil) then
		local idx = string.find(filename, '.png');
		plistfilename = string.sub(filename, 1, idx)..'plist';
		imagefilename = filename;
	else
		print("please select a plist and img in same path");
		return;
	end
	
	-- 查询获取必要的当前文件路径
	local tmp = string.reverse(plistfilename);
	local i = string.find(tmp, '/');
	if (i == nil) then
		i = string.find(tmp, '\\');
	end
	if (i) then
		m_default_path = string.sub(plistfilename, 1, string.len(tmp) - i + 1);
	end
	
	local image = wx.wxImage()
	if ( not image:LoadFile(imagefilename) ) then
        wx.wxLogError("Couldn't load image from '%s'.", imagefilename)
        return
    end
	
	m_select_img = wx.wxBitmap(image);
	local height = m_select_img:GetHeight();
	local width = m_select_img:GetWidth();
	m_canvas:SetSize(width, height);
	m_state_string = width.."x"..height.." ==>" ..imagefilename;
	m_window:SetStatusText(m_state_string);
	
	-- 分解数据和块
	local plist = xml.load(plistfilename)
	local plist_tag = plist[1]
	local t = plist_tag[2];
	local num = #t;
	
	m_plist_frame_t = {};
	local frame_name = nil;
	local r = nil; 
	-- 获取plist文件中的所有帧的信息
	for i = 1, num, 2 do
		frame_name = t[i][1];
		r = parse_rect(t[i+1][2][1]);
		local data = {rt=false, frame=frame_name,x=tonumber(r.x),y=tonumber(r.y),w=tonumber(r.w),h=tonumber(r.h)};
		if (t[i+1][6][0] == "true") then
			data = {rt=true, frame=frame_name,x=tonumber(r.x),y=tonumber(r.y),w=tonumber(r.h),h=tonumber(r.w)};
		end
		table.insert(m_plist_frame_t, data);
	end
	
	-- 更新数据列表
	m_listCtrl:ClearAll();
	m_listCtrl:InsertColumn(0, "frame name")
	m_listCtrl:SetColumnWidth(0, 200);
	for i, d in ipairs(m_plist_frame_t) do
		m_listCtrl:InsertItem(i - 1, d.frame);
	end
	m_listCtrl:Refresh();
	m_canvas:Refresh();
end
--============================================================
--
function OnLeftDown(event)
	for n = 1, m_listCtrl:GetItemCount() do
		m_listCtrl:SetItemState(n - 1, n - 1, wx.wxLIST_STATE_DONTCARE);
	end
	
	local is_need_refresh = false;
	local x, y = event:GetPositionXY()
	for i, d in ipairs(m_plist_frame_t) do
		if (d.x < x and d.x + d.w > x and d.y < y and d.y + d.h > y) then
			m_select_rect = d;
			is_need_refresh = true;
			m_window:SetStatusText(m_state_string.."   "..d.frame.."==>("..d.w.."x"..d.h..")");
			m_frame_name = d.frame;
			m_listCtrl:SetItemState(i - 1, i - 1, wx.wxLIST_STATE_SELECTED);
		end
	end
	if (is_need_refresh) then
		m_canvas:Refresh();
	end
end

--========================================================
function OnRightDown(event)
	local clipBoard = wx.wxClipboard.Get()
    if clipBoard and clipBoard:Open() then
        clipBoard:SetData(wx.wxTextDataObject(m_frame_name))
        clipBoard:Close()
    end
end


local function open_find_dir(parent, filter_t)
	local dir = nil;
	local has_save = false;
	while (dir == nil) do
        dir = wx.wxDirSelector(L.SAVE_OPEN_PATH, "", wx.wxDD_DIR_MUST_EXIST, wx.wxDefaultPosition, parent)
        if (dir == "") then
            return dir;
        end
        dir = dir.."/"
		local has_same = false;
		for i, d in pairs(filter_t) do	
			if (wx.wxFile.Exists(dir .. d)) then
				has_same = true;
				break;
			end
		end
		has_save = true;
		if (has_same) then -- 有相同文件是否进行保存
			local ret = wx.wxMessageBox(L.SAVE_SAME_FILE, L.SAVE_FILE,
                            wx.wxOK + wx.wxICON_INFORMATION + wx.wxCENTRE,
                            parent)
			print(ret);
			if (ret == wx.wxOK) then
				has_save = true;
			end
		end
    end
	return dir, has_save;
end
--============================================================
-- 监听事件
function event_close_handle(event) m_window:Close(true); end
function event_open_handle(event)
	local filename = wx.wxFileSelector("Select plist file", m_default_path)
    if ( not filename or filename == '' ) then
        return
    end
	OnOpenFileDrawing(filename);
end
function event_about_handle(event)
	print(APP_DESCTION);
end

function event_copy_handle(event)
	OnRightDown(event);
end

function event_save_handle(event)
	if (m_select_rect == nil) then
		print(L.ERR_UN_SELECT_FRAME);
		return;
	end
	
	local r = m_select_rect;
	local name = r.frame;
	local rotation = r.rt;
	
	local dir, b = open_find_dir(m_window, {name});
	if (not b) then
		return;
	end
	local img = m_select_img:GetSubBitmap(wx.wxRect(r.x, r.y, r.w, r.h));
	if (rotation) then
		img:Rotate(-90, wx.wxPoint(r.w / 2,r.h / 2), false, nil);
		img:Resize(wx.wxSize(r.h, r.w), wx.wxPoint(r.w / 2, r.h / 2), -1, -1, -1);
	end
	if (not img:SaveFile( dir .. name, wx.wxBITMAP_TYPE_PNG)) then
		wx.wxLogError(L.ERR_SAVE_FILE_FAIL);
	end
end

function event_save_all_handle(event)
	
end

function event_drop_file_handle(event)
	local files = event:GetFiles();
	local num = #files;
	if (num > 0) then
		local imgFile = files[1];
		OnOpenFileDrawing(imgFile);
	end
end

function event_list_item_selected_handle(event)
	local listCtrl = event:GetEventObject():DynamicCast("wxListCtrl")
	for i = 1, listCtrl:GetItemCount() do
		local s = listCtrl:GetItemState(i - 1, wx.wxLIST_STATE_SELECTED)
		if s ~= 0 then
			local data = m_plist_frame_t[i];
			m_select_rect = data;
			m_canvas:Refresh();
			m_window:SetStatusText(m_state_string.."   "..data.frame.."==>("..data.w.."x"..data.h..")");
			m_frame_name = data.frame;
			break;
		end
	end
end

--============================================================
--
function build_frame()
	--=================================================
	-- 主要窗口添加
	m_window = wx.wxFrame( wx.NULL, wx.wxID_ANY, L.TITLE, wx.wxDefaultPosition,wx.wxSize(800, 600), wx.wxDEFAULT_FRAME_STYLE )
	m_window:DragAcceptFiles(true);	 -- 接受图片拖动
	
	local fileMenu = wx.wxMenu()
	local menuBar = wx.wxMenuBar()
    local helpMenu = wx.wxMenu()
	
	fileMenu:Append(ID_OPEN_IMG, 	L.OPEN.."\tCtrl+O", 	L.OPEN_DES)
	fileMenu:Append(wx.wxID_COPY, 	L.COPY.."\tCtrl+C", 	L.COPY_DES)
	fileMenu:Append(ID_SAVE_IMG, 	L.SAVE.."\tCtrl+S", 	L.SAVE_DES)
	fileMenu:Append(ID_SAVE_ALL, 	L.SAVE_ALL.."\tShift+S", L.SAVE_ALL_DES)
	fileMenu:Append(wx.wxID_EXIT, 	L.EXIT.."", 			L.EXIT_DES);
    helpMenu:Append(wx.wxID_ABOUT, 	L.ABOUT.."", 			L.ABOUT_DES);
    
	m_window:Connect(wx.wxID_EXIT, 	wx.wxEVT_COMMAND_MENU_SELECTED, event_close_handle)
	m_window:Connect(ID_OPEN_IMG, 	wx.wxEVT_COMMAND_MENU_SELECTED, event_open_handle)
	m_window:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED, event_about_handle);
	m_window:Connect(wx.wxID_COPY, 	wx.wxEVT_COMMAND_MENU_SELECTED, event_copy_handle);
	m_window:Connect(ID_SAVE_IMG, 	wx.wxEVT_COMMAND_MENU_SELECTED, event_save_handle);
	m_window:Connect(ID_SAVE_ALL, 	wx.wxEVT_COMMAND_MENU_SELECTED, event_save_all_handle);
	
	m_window:Connect(wx.wxEVT_DROP_FILES, event_drop_file_handle);
	
    menuBar:Append(fileMenu, L.FILE)
    menuBar:Append(helpMenu, L.HELP)
	
    m_window:SetMenuBar(menuBar)
    m_window:CreateStatusBar(1)
    m_window:SetStatusText(L.WIN_BOTTOM)

	-- ===============================================
	-- 分割两边界面:左边是绘图区域, 右边是一个列表区域
	local splitter = wx.wxSplitterWindow(m_window, wx.wxID_ANY)
    splitter:SetMinimumPaneSize(50)
    splitter:SetSashGravity(.8)
	--=================
	-- 左边区域
	m_scrollWin = wx.wxScrolledWindow(splitter, ID_PARENT_SCROLLEDWINDOW, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxHSCROLL + wx.wxVSCROLL)
    m_scrollWin:SetScrollbars(15, 15, 400, 1000, 0, 0, false)
	
	m_canvas = wx.wxPanel(m_scrollWin, wx.wxID_ANY)
	m_canvas:SetBackgroundColour(wx.wxColour(255, 100, 100));
	m_canvas:Connect(wx.wxEVT_PAINT, OnPaint)
	--=================
	-- 右边区域
	m_listCtrl = wx.wxListCtrl(splitter, ID_LISTCTRL, wx.wxDefaultPosition, wx.wxSize(100, 200), wx.wxLC_REPORT)
	m_listCtrl:InsertColumn(0, L.FRAME_NAME)
	m_listCtrl:Connect(wx.wxEVT_COMMAND_LIST_ITEM_SELECTED , event_list_item_selected_handle);
	--=================
	m_canvas:Connect(wx.wxEVT_LEFT_DOWN, OnLeftDown )
	m_canvas:Connect(wx.wxEVT_RIGHT_DOWN, OnRightDown )

	splitter:SplitVertically(m_scrollWin, m_listCtrl,500)
    m_window:Show(true)
end

build_frame()
wx.wxGetApp():MainLoop()