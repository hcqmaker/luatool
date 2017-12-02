--[[
        A*寻路算法，目前只适用于 01图, 0可通行， 1不可通行

	A*的目的是查询想要的路线，所有进行不要弄太多的函数和处理

--]]



 
-- 行走的4个方向
local four_dir = {
	{1, 0},
	{0, 1},
	{0, -1},
	{-1, 0},
}
 
-- 行走的8个方向
local eight_dir = {
	{1, 1},
	{1, 0},
	{1, -1},
	{0, 1},
	{0, -1},
	{-1, 1},
	{-1, 0},
	{-1, -1}
}

--============================================
local function check(m, x, y, tx, ty, w, h)
	if (1 <= y and y <= h and 1 <= x and x <= w) then
		if (m[y][x] == 0 or (y == ty and x == tx)) then
			return true;
		end
	end
	return false;
end

local function get_min_node(open_list)
	if (#open_list < 1) then
		return nil;
	end
	local node = open_list[1];
	local idx = 1;
	for i,v in ipairs(open_list) do
		if (node.f > v.f) then
			node = v;
			idx = i;
		end
	end

	table.remove(open_list, idx);
	return node;
end

local function build_path(node)
	local path = {};
	local sum_cost = node.f;
	while (node) do
		table.insert(path, {y=node.y,x=node.x});
		node = node.parent;
	end
	return path, sum_cost;
end


local function search_list(list, x, y)
	for i = 1, #list do
		local n = list[i];
		if (n.x == x and n.y == y) then
			return n, i;
		end
	end
	return nil, -1;
end

function search_path(m, x, y, tx, ty, odir)

	local cost = 10;	-- 单元格花费
	local diag = 1.4; 	-- 对角线划分

	local mh = #m;
	local mw = #m[1];
	local open_list = {};
	local close_list = {};

	if (m[ty][tx] ~= 0) then
		print("from ("..x..","..y..") to ("..ty..","..tx..") can't find the way");
		return nil;
	end

	local snode = {x=x,y=y,g=0,h=0,f=0}
	table.insert(open_list, snode);

	local dir = odir and four_dir or eight_dir
	while (#open_list > 0) do
		local node = get_min_node(open_list);
		
		if (node.y == ty and node.x == tx) then
			return build_path(node);
		end

		for i=1,#dir do
			local nx = node.x + dir[i][2];
			local ny = node.y + dir[i][1];

			if (check(m, nx, ny, tx, ty, mw, mh)) then
				local cost = cost;
				local isdiag = nx ~= node.x and ny ~= node.y;
				if (isdiag) then
					cost = cost * diag;
				end

				local cur = {parent = node, x = nx, y = ny, g = node.g + cost};
				if fdir then
					cur.h = math.abs(ny - ty) + math.abs(nx - tx) * cost;
				else
					local dx = math.abs(ny - ty)
					local dy = math.abs(nx - tx)
					local minD = math.min(dx, dy)
					cur.h = (minD * diag + dx + dy - 2 * minD) * cost;
				end
				cur.f = cur.g + cur.h;

				local onode, oidx = search_list(open_list, nx, ny);
				local cnode, cidx = search_list(close_list, nx, ny);

				if not onode and not cnode then
					table.insert(open_list, cur);
				elseif onode then
					if (onode.f > cur.f) then
						open_list[oidx] = cur;
					end
				else
					if cnode.f > cur.f then
						table.insert(open_list, cur);
						table.remove(close_list, cidx);
					end
				end
				
			end
		end
		
		table.insert(close_list, node);
	end

	return nil;
end


local mp = {
	{0,1,0,1,0,0,0,0,0},
	{0,1,0,1,0,0,0,0,0},
	{0,1,1,1,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0},
	{0,1,1,1,0,0,0,0,0},
	{0,1,1,1,0,0,1,0,0},
	{0,1,1,1,0,0,0,1,0},
	{0,1,1,1,0,0,1,0,0}

};



local p = search_path(mp, 1, 1, 8, 8, four_dir);
--local p = search_path(mp, 1, 1, 1, 4, four_dir);
if (p == nil) then
	print("-------");
	return;
end

for k,v in ipairs(p) do
	mp[v.y][v.x] = 3;
end

for i = 1, #mp do
	local str = "";
	for j = 1, #mp[1] do
		str = str .. mp[i][j];
	end
	print(str);
end
