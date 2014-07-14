package.cpath = package.cpath ..";G:/program/lua/lua_mysql_catch/?.dll";
package.path = package.path..";G:/tool/Lua/5.1/lua/?.lua";
require("luasql.mysql");
local socket = require("socket");


rs_tip = {"select:", "insert:", "delete:", "update:"};
cfg = {dbname="phone_monster",dbuser="root", dbpwd="zuzhang202", dbip="192.168.1.222", dbport=3306};


nod = {};
od = {};



function print_t(r)
	ss = '';
	for i,v in pairs(r) do
		ss = ss .."["..i.."]="..v;
	end
	--print(ss);

	local vn = r["Variable_name"];
	od[vn] = tonumber(r["Value"]);

end

function print_od()
	print("------------------ mysql total ---------------");
	for i,v in pairs(od) do
		if (nod[i] ~= nil) then
			print("["..i.."]="..(v - nod[i]));
		end
		nod[i] = v;
	end
end


function mysql_push_info(cfg)
    r = {0, 0, 0, 0};
	local env = luasql.mysql();
	local con, err = env:connect(cfg.dbname, cfg.dbuser, cfg.dbpwd, cfg.dbip, cfg.dbport);
	if (con) then
		for i=1,10 do
			cur,er = con:execute("show global status where Variable_name in('com_select','com_insert','com_delete','com_update');");
			local rs = cur:fetch({}, "a");
			while (rs) do
				print_t(rs);
				rs = cur:fetch({}, "a");
			end
			print_od();
			socket.sleep(1)
		end
		con:close();
		con = nil;
		cr = nil;
	else
		print(err);
	end
end

function start_data()
	mysql_push_info(cfg);
end

start_data();



