local function dumpTable ( o )
	if type ( o ) == 'table' then
		local s = '{ '
		for k , v in pairs ( o ) do
			if type ( k ) ~= 'number' then
				k = '"'..k..'"'
			end
			s = s ..'['..k..'] = ' ..dumpTable ( v ) ..','
		end
		return s ..'} '
	else
		return tostring ( o )
	end
end

local function addMap ( m , k , v )
	local v0 = m [ k ]
	-- print ( string.format ( "[d]addMap %s %s v0=%s, %s" , k , v , v0 , dumpTable ( m ) ) )
	if v0 == nil then
		m [ k ] = v
	else
		m [ k ] = v0 + v
	end
end

local function addMap2 ( m , m2 )
	for k , v in pairs ( m2 ) do
		addMap ( m , k , v )
	end
end

local function mod1 ( a , b )
	return a - math.floor ( a / b ) * b
end

local function tryProduce ( fac , itemId , cnt )
	--[[
	GetEntitiesWithComponent (Faction Function)
	GetEntity
	ent.producers
	]]
	local ent = data.all [ itemId ]
	-- print ( string.format ( "tryProduce %s x %s " , itemId , cnt ) )
	local production_recipe = ent.production_recipe
	local producers = production_recipe and production_recipe.producers
	local idle_producers = { }
	if producers then
		for k , v in pairs ( producers ) do
			local hits = fac : GetComponents ( k )
			-- if hits then 				print ( dumpTable ( hits ) ) 			end
			for _ , producer in ipairs ( hits ) do
				if not producer : GetRegisterId ( 1 ) then
					table.insert ( idle_producers , producer )
				end
			end
			-- print ( string.format ( "%s in %s ticks, %d idel" , k , v , # idle_producers ) )
		end
	end
	-- print ( "]" )
	local cnt_idle_producers = # idle_producers
	if cnt_idle_producers > 0 then
		print ( string.format ( "assign %s x %s into %s idle producers" ,
				cnt , itemId , cnt_idle_producers ) )
		if cnt_idle_producers > 1 and cnt > 1 then
			local avg = cnt // cnt_idle_producers
			if avg == 0 then
				for i = 1 , cnt do
					idle_producers [ i ] : SetRegisterId ( 1 , itemId , 1 )
				end
			else
				local remain = mod1 ( cnt , cnt_idle_producers )
				for i = 1 , cnt_idle_producers do
					local cnt2 = avg
					if i == 1 then
						cnt2 = cnt2 + remain
					end
					print ( string.format ( "%s/%s avg %s remain %s i %s cnt2 %s" ,
							cnt , cnt_idle_producers , avg , remain , i , cnt2
						) )
					idle_producers [ i ] : SetRegisterId ( 1 , itemId , cnt2 )
				end
			end
		else
			idle_producers [ 1 ] : SetRegisterId ( 1 , itemId , cnt )
		end
	end
end

local function checkProduce ( fac , item_id , needCnt , lack )
	local avaCnt = fac : GetItemAmount ( item_id )
	local needMoreCnt = needCnt - avaCnt
	if needMoreCnt > 0 then
		addMap ( lack , item_id , needMoreCnt )
	else
		return true
	end
	local subLack = { }
	local production_recipe = data.all [ item_id ].production_recipe
	if production_recipe then
		for sItem , sCnt in pairs ( production_recipe.ingredients ) do
			checkProduce ( fac , sItem , sCnt * needMoreCnt , subLack )
		end
		if subLack then
			addMap2 ( lack , subLack )
		end
	end
end

local function reverse_pairs ( t )
	local keys = { }
	for k in pairs ( t ) do
		table.insert ( keys , k )
	end
	local i = # keys + 1
	return function ( )
		i = i - 1
		if i > 0 then
			local k = keys [ i ]
			return k , t [ k ]
		end
	end

end

data.instructions.mod_pass_down_order =
{
	func = function ( comp , state , cause )
		--[[
		CountItem
		GetActiveOrders
		IsWaitingForOrder
		HaveFreeSpace
		]]
		local fac = comp.faction
		local lack = { }
		for _ , o in ipairs ( fac : GetActiveOrders ( ) ) do
			checkProduce ( fac , o.item_id , o.amount , lack )
		end
		for k , v in reverse_pairs ( lack ) do
			print ( string.format ( "lack: %s x %s" , v , k ) )
			tryProduce ( fac , k , v )
		end
	end

	,
	name = "订单吩咐下去[MOD]" ,
	desc = [[ 这个指令执行一次，把当前缺少的订单(不管是建筑还是生产)都安排下去，包括缺少的零件的子零件(递归)。
	注意:只针对当前状态，如果有正在生产的零件会认为是别的计划，不会纳入目标。所以如果连续执行两次这个指令，就会多生产一遍目前缺少的零件。
	如果你在意执行细节，可以在steam游戏的启动栏填入'-log'来显示log。
	例子: 比如现在缺少20个铁板，有3个锅炉闲置，那么执行一下会自动分别安排8+6+6个铁板给这3个锅炉。
	例子: 比如现在缺少一个激光炮台，而造激光炮台需要的小炮台也缺一个，那么执行一下会自动分别安排一个小炮台给一个制造器，一个激光炮台给另一个制造器，(如果有闲置的制造器的话)。
	]],
	category = "Global" ,
	icon = "Main/skin/Icons/Common/56x56/Processing.png" ,
}
