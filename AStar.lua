--[[
        A*寻路算法，目前只适用于 01图, 0可通行， 1不可通行
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
 
local AStar = {}
 
-- 地图、起始点、终点
function AStar:init(map, startPoint, endPoint, four_dir)
	self.startPoint = startPoint
	self.endPoint   = endPoint
	self.map        = map
	self.cost       = 10 -- 单位花费
	self.diag       = 1.4 -- 对角线长， 根号2 一位小数
	self.open_list  = {}
	self.close_list = {}
	self.mapRows    = #map
	self.mapCols    = #map[1]
	self.four_dir   = four_dir -- 使用4方向的寻路还是八方向的寻路
end
 
-- 搜索路径 ,核心代码
function AStar:searchPath(self)
	-- 验证终点是否为阻挡，如果为阻挡，则直接返回空路径
	if self.map[self.endPoint.y][self.endPoint.x] ~= 0 then
		--Logger.info("(", self.endPoint.y, ",", self.endPoint.x, ") 是阻挡！！！无法寻路")
		print("(", self.endPoint.y, ",", self.endPoint.x, ") 是阻挡！！！无法寻路");
		return nil
	end

	-- 把第一节点加入 open_list中
	local startNode = {}  
	startNode.y = self.startPoint.y
	startNode.x = self.startPoint.x
	startNode.g = 0
	startNode.h = 0
	startNode.f = 0
	table.insert(self.open_list, startNode)
	 
	-- 检查边界、障碍点 
	local check = function(y, x)
		if 1 <= y and y <= self.mapRows and 1 <= x and x <= self.mapCols then
			if self.map[y][x] == 0 or (y == self.endPoint.y and x == self.endPoint.x) then
				return true
			end
		end

		return false
	end
 
	local dir = self.four_dir and four_dir or eight_dir
	while #self.open_list > 0 do
		local node = self:getMinNode()
		if node.y == self.endPoint.y and node.x == self.endPoint.x then
			-- 找到路径
			return self:buildPath(node)
		end

		for i = 1, #dir do
			local y = node.y + dir[i][1]
			local x = node.x + dir[i][2]
			if check(y, x) then
				local curNode = self:getFGH(node, y, x, (y ~= node.y and x ~= node.x))
				local openNode, openIndex = self:nodeInOpenList(y, x)
				local closeNode, closeIndex = self:nodeInCloseList(y, x)

				if not openNode and not closeNode then
					-- 不在OPEN表和CLOSE表中
					-- 添加特定节点到 open list
					table.insert(self.open_list, curNode)
				elseif openNode then
					-- 在OPEN表
					if openNode.f > curNode.f then
						-- 更新OPEN表中的估价值
						self.open_list[openIndex] = curNode
					end
				else
					-- 在CLOSE表中
					if closeNode.f > curNode.f then
						table.insert(self.open_list, curNode)
						table.remove(self.close_list, closeIndex)
					end
				end
			end
		end

		-- 节点放入到 close list 里面
		table.insert(self.close_list, node)
	end

	-- 不存在路径
	return nil
end
 
-- 获取 f ,g ,h, 最后参数是否对角线走
function AStar:getFGH( father, y, x, isdiag)
	local node = {}
	local cost = self.cost
	if isdiag then
		cost = cost * self.diag
	end

	node.father = father
	node.y = y
	node.x = x
	node.g = father.g + cost
	-- 估计值h
	if self.four_dir then
		node.h = self:manhattan(y, x)
	else
		node.h = self:diagonal(y, x)
	end
	node.f = node.g + node.h  -- f = g + h 
	return node
end
 
-- 判断节点是否已经存在 open list 里面
function AStar:nodeInOpenList( y, x)
	for i = 1, #self.open_list do
		local node = self.open_list[i]
		if node.y == y and node.x == x then
			return node, i   -- 返回节点和下标
		end
	end

	return nil
end
 
-- 判断节点是否已经存在 close list 里面
function AStar:nodeInCloseList( y, x)
	for i = 1, #self.close_list do
		local node = self.close_list[i];
		if node.y == y and node.x == x then
			return node, i
		end
	end

	return nil
end
 
-- 在open_list中找到最佳点,并删除
function AStar:getMinNode = function(self)
	if #self.open_list < 1 then
		return nil
	end

	local min_node = self.open_list[1]
	local min_i = 1
	for i,v in ipairs(self.open_list) do
		if min_node.f > v.f then
			min_node = v
			min_i = i
		end
	end

	table.remove(self.open_list, min_i)
	return min_node
end
 
-- 计算路径
function AStar:buildPath( node)
	local path = {}
	local sumCost = node.f -- 路径的总花费
	while node do
		path[#path + 1] = {y = node.y, x = node.x}
		node = node.father
	end

	return path, sumCost
end
 
-- 估价h函数
-- 曼哈顿估价法（用于不能对角行走）
function AStar:manhattan( y, x)  
	local h = math.abs(y - self.endPoint.y) + math.abs(x - self.endPoint.x)
	return h * self.cost
end
 
-- 对角线估价法,先按对角线走，一直走到与终点水平或垂直平行后，再笔直的走
function AStar:diagonal( y, x)
	local dx = math.abs(y - self.endPoint.y)
	local dy = math.abs(x - self.endPoint.x)
	local minD = math.min(dx, dy)
	local h = minD * self.diag + dx + dy - 2 * minD
	return h * self.cost
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

AStar:init(mp,{y=1,x=1},{y=8,x=8},four_dir);
local p = AStar:searchPath();
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


return AStar