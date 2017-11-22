-- random 2d map
--[[
从这里获取的 
http://www.roguebasin.com/index.php?title=Cellular_Automata_Method_for_Generating_Random_Cave-Like_Levels


--]]
--参照的是c的部分

local TILE_FLOOR = 0;
local TILE_WALL = 1;

local grid = {};
local grid2 = {};

local fillprob = 40;
local r1_cutoff = 5;
local r2_cutoff = 2;
local size_x = 64
local size_y = 20;
local generations;

local params = nil;
local params_set = {};

local numArea = 0;

local function randpick()
	if ( math.random() * 100 < fillprob) then
		return TILE_WALL;
	else
		return TILE_FLOOR;
	end
end

local function initmap()
	-- 初始化
	for yi=1, size_y do
		if (grid[yi] == nil) then
			grid[yi] = {};
		end
		for xi=1,size_x do
			grid[yi][xi] = randpick();
		end
	end

	for yi=1, size_y do
		if (grid2[yi] == nil) then
			grid2[yi] = {};
		end
		for xi=1, size_x do
			grid2[yi][xi] = TILE_WALL;
		end
	end

	for yi=1,size_y do
		grid[yi][1] = TILE_WALL;
		grid[yi][size_x] = TILE_WALL;
	end
	for xi=1,size_x do
		grid[1][xi] = TILE_WALL;
		grid[size_y][xi] = TILE_WALL;
	end

end

local function generation()
	-- 生成
	for yi = 2,size_y-1 do
		for xi = 2, size_x-1 do
			local adjcount_r1 = 0;
 		    local adjcount_r2 = 0;

			for ii=-1,1 do
				for jj=-1,1 do
					if(grid[yi+ii][xi+jj] ~= TILE_FLOOR) then
						adjcount_r1 = adjcount_r1 + 1;
					end
				end
			end
			for ii=yi-2,yi+2 do
				for jj=xi-2,xi+2 do
					if(not (math.abs(ii-yi)==2 and math.abs(jj-xi)==2))
						and (not (ii<1 or jj<1 or ii>=size_y or jj>=size_x)) then
						if(grid[ii][jj] ~= TILE_FLOOR) then
							adjcount_r2 = adjcount_r2 + 1;
						end
					end
				end
			end
			if(adjcount_r1 >= params.r1_cutoff or adjcount_r2 <= params.r2_cutoff) then
				if (grid2[yi][xi] == TILE_FLOOR) then
					grid2[yi][xi] = TILE_WALL;
				end
			else
				grid2[yi][xi] = TILE_FLOOR;
			end
		end
	end
	for yi=2,size_y do
		for xi=2,size_x do
			--if (grid[yi][xi] == TILE_FLOOR and grid2[yi][xi] ~= TILE_FLOOR) then
				grid[yi][xi] = grid2[yi][xi];
			--end
		end
	end
	return grid;
end

local function printfunc()
	print("W[0](p) = rand[0,100) < "..fillprob.."\n");

	for ii = 1,generations do
		print("Repeat "..params_set[ii].reps..": W'(p) = R[1](p) >= "..params_set[ii].r1_cutoff)

		if (params_set[ii].r2_cutoff >= 0) then
			print(" || R[2](p) <= "..params_set[ii].r2_cutoff);
		else
			print('\n');
		end
	end
end

function printmap()
	local markn = {".","*","-","+","~","@","&"};
	local rs = {"A","B","C","E","F","G","H","I","J","K","L","N","M","O","P","Q","R","S","T"};
	local n = #rs;
	for yi = 1,size_y do
		local str = "";
		for xi = 1,size_x do
			local tr = grid[yi][xi];
			if (tr ~= TILE_FLOOR) then
				if (tr >= 1000) then
					str = str .. "#";
				elseif (tr >= 100) then
					local ni = math.floor(tr / 100);
					--str = str .. ".";--markn[ni]
					str = str .. markn[ni]
				else
					if (tr > n) then
						tr = n;
					end
					str = str .. rs[tr];
				end
				
			--if (grid[yi][xi] == TILE_WALL) then
				--str = str .. "#";
			else
				str = str ..".";
			end
		end
		print(str);
	end
end

-- 從一個點出發，找到所有可以連接的點，比較兩邊是否，還有沒有在列表裡面的，如果是，選擇這個點找尋所有可以到達的點
-- 1. 找出所有孤立的區域，之後再他們之間進行連接
function FindOneEmptyNode(filter)
	for i = 1, size_y do
		for j = 1, size_x do
			if (grid[i][j] == TILE_FLOOR and filter[j.."_"..i] == nil) then
				return j,i;
			end
		end
	end
	return -1,-1;
end

local Area_t = {
	{-1,0},
	{1,0},
	{0,-1},
	{0,1}
};

function IsInFilter(x,y, f)
	if (f[x.."_"..y] == nil) then
		return false;
	end
	return true;
end
function PushFilter(x,y, f)
	f[x.."_"..y] = true;
end


function GetNearNode(x,y, filter)
	local r = {};
	for k,v in pairs(Area_t) do
		local i = x + v[1];
		local j = y + v[2];
		if (grid[j][i] == TILE_FLOOR and not IsInFilter(i,j,filter)) then
			table.insert(r, {x=i,y=j});
			PushFilter(i,j,filter);
		end
	end
	return r;
end

function GetOneArea(x, y, ot, filter)
	table.insert(ot, {x=x,y=y});
	PushFilter(x, y, filter);
	local r = GetNearNode(x,y, filter);
	for k,v in pairs(r) do
		table.insert(ot, {x=v.x,y=v.y});
		GetOneArea(v.x,v.y, ot, filter);
	end
end

function LinkTwoArea(r1, r2)
	-- 随便选择两个点直接强制进行连接
	-- 得到一条路线

	-- 找到最短的两个点进行连接
	local minlen = 100;
	local n1 = nil;
	local n2 = nil;

	for i,v in ipairs(r1) do
		for j,nv in ipairs(r2) do
			local ln = math.abs(nv.x - v.x)  + math.abs(nv.y - v.y);
			if (ln < minlen) then
				n1 = v;
				n2 = nv;
				minlen = ln;
			end
		end
	end

	--[[
	local i1 = math.floor(math.random() * 100 % #r1 + 1);
	local i2 = math.floor(math.random() * 100 % #r2 + 1);

	local n1 = r1[i1];
	local n2 = r2[i2];
	--]]

	print("===>("..n1.x..","..n1.y..")=>("..n2.x..","..n2.y..")");
	local r = {};

	local step = 1;
	if (n1.x > n2.x) then
		step = -1;
	end
	for i = n1.x, n2.x, step do
		if (grid[n1.y][i] ~= 0) then
			table.insert(r, {x=i,y=n1.y});
			grid[n1.y][i] = 1000;
		end
	end
	step = 1;
	if (n1.y > n2.y) then
		step = -1;
	end
	for j = n1.y,n2.y, step do
		if (grid[j][n2.x] ~= 0) then
			table.insert(r, {x=n2.x,y=j});
			grid[j][n2.x] = 1000;
		end
	end
	return r;
end

function SearchLinkArea()
	local filter = {}
	local rt = {};
	while (true) do
		local x,y = FindOneEmptyNode(filter);
		if (x == -1) then
			break;
		end
		--print("========>>=======");
		local ot = {};
		GetOneArea(x, y, ot, filter);
		table.insert(rt, ot);
	end
	

	-- 进行区域标记
	-- 需要的话，这块就注释掉了
	for k,v in pairs(rt) do
		for k1,v1 in pairs(v) do
			grid[v1.y][v1.x] = k * 100;
		end
	end
	
	if (#rt > 1) then
		print("====>has num:".. #rt .. " to connect");
		-- 进行建立路线,1~2,2~3这样进行
		for i = 1, #rt - 1 do
			local area1 = rt[i];
			local area2 = rt[i+1];
			local linkPath = LinkTwoArea(area1, area2);
		end
	else
		print("====>has one area");
	end

end



function tmain()
	-- 60 20 40 5 2 40
	-- 60 40 40 5 2 40
	--local argv = {60,20,40,5,2,10};
	local argv = {100,40,40,5,2,10};
	local argc = table.maxn(argv) + 1;
	size_x = argv[1];
	size_y = argv[2];
	fillprob = argv[3];

	generations = (argc - 4) / 3 ;

	params = {};
	params_set = {};
	for i = 1,generations do
		params_set[i] = {
			r1_cutoff = 0;
			r2_cutoff = 0;
			reps = 0;
		};
	end


	local idx = 1;
	params = params_set[idx];
	ii = 4;
	while(true) do
		if (ii + 2 >= argc) then
			break;
		end

		params.r1_cutoff = (argv[ii]);
		params.r2_cutoff = (argv[ii + 1]);
		params.reps = (argv[ii + 2]);

		idx = idx + 1;
		params = params_set[idx];
		ii = ii + 3;
	end

	--srand(time(NULL));
	local sd = tonumber(tostring(os.time()):reverse():sub(1,6))
	print("seed:"..sd);
	math.randomseed(sd)

	initmap();

	for ii = 1, generations do
		params = params_set[ii];
		for jj = 1,params.reps do
			generation();
			TILE_WALL = TILE_WALL + 1;
		end
	end

	SearchLinkArea();
	printfunc();
	printmap();
	
	return 0;
end


tmain();
--[[
local sd = tonumber(tostring(os.time()):reverse():sub(1,6))
	print("seed:"..sd);
	math.randomseed(sd)
local r1 = {1,2,3,3,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5};
print("num:"..#r1);
print(math.floor(math.random() * 100 % #r1 + 1))
--]]