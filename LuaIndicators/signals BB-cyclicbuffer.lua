--[[==========================================================================
TODO 1. signall crossMA
    2   signal uturnMA
    3.  signal uturn
    4. signal BBexpansion
--  ==========================================================================]]
Settings = {	Name = "FEK_Signals_BB_cyclic", 
				line = {{	Name = "BB",
							Type = TYPE_LINE, 
							Color = RGB(221, 44, 44)	},
						{	Name = "BBTop",
							Type = TYPE_LINE, 
							Color = RGB(0, 206, 0)		},
						{	Name = "BBBottom",
							ype = TYPE_LINE, 
							Color = RGB(0, 162, 232)	}}}

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function Init() 
	FuncBB = BB()
	TagChart = "CuPricecyclic"
    Count = 0
    ScriptPath = getScriptPath()
    LabelParams = { R = 2,
                    G = 2,
                    B = 2,
                    TRANSPARENCY = 0,
                    TRANSPARENT_BACKGROUND = 1,
                    FONT_FACE_NAME = "Arial",
					FONT_HEIGHT = 8 }
	MAParameters = {	Period = 20, 
						Shift = 2		}
    return #Settings.line
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function OnCalculate(index_candle) 
    -- Signal 1: CrossMA
    local ma = {}
    local bb_top = {}
    local bb_bottom = {}
    local price = {}

	ma[2], bb_top[2], bb_bottom[2] = FuncBB(index_candle)
	ma[2] = RoundScale(ma[2], 4)
	bb_top[2] = RoundScale(bb_top[2], 4)
	bb_bottom[2] = RoundScale(bb_bottom[2], 4)
	
	ErrorMessage(index_candle, ma[2], bb_top[2], bb_bottom[2] )
    
	ma[1] = RoundScale(GetValue(index_candle - 1, 1), 4)
	bb_top[1] = RoundScale(GetValue(index_candle - 1, 2), 4)
	bb_bottom[1] = RoundScale(GetValue(index_candle - 1, 3), 4)
	
	ErrorMessage(index_candle, ma[1], bb_top[1], bb_bottom[1] )

	price[2] = C(index_candle)
	price[1] = C(index_candle - 1)

    if (((ma[2] ~= nil ) and (ma[1]~= nil)) and ((price[2] ~= nil) and (price[1] ~= nil))) then

        -- price cross over ma - long
        if CrossOver(price, ma) then
            Count = Count + 1
            ErrorMessage(index_candle, "Long", Count)
            SetChartLabel(T(index_candle), C(index_candle), TagChart, "Long CrossMA #" .. Count)
            
            -- price cross under ma - short
        elseif CrossUnder(price, ma) then
            Count = Count + 1            
            ErrorMessage(index_candle, "Short", Count)
            SetChartLabel(T(index_candle), C(index_candle), TagChart, "Short CrossMA #" .. Count)
        end
    end  
    return ma[2], bb_top[2], bb_bottom[2]
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function BB() 
	local BB_MA = VMA()
	local BB_SD = SD()

	local Itterations = { processed = 0, count = 0 }

	return function (index_candle)
		if (MAParameters.Period > 0) then
			if (index_candle == 1) then
				Itterations = { processed = 0, count = 0 }
			end

			local b_ma = BB_MA(index_candle)
			local b_sd = BB_SD(index_candle)

			if (CandleExist(index_candle)) then
				if (index_candle ~= Itterations.processed) then 
					Itterations = { processed = index_candle, count = Itterations.count + 1 } 
				end

				if ((Itterations.count >= MAParameters.Period) and (b_ma and b_sd)) then
					return b_ma, (b_ma + MAParameters.Shift * b_sd), (b_ma - MAParameters.Shift * b_sd)
				end
			end
		end
		return nil, nil, nil
	end
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function SD() 
	local SD_MA = SMA()

	local Sums = {}
	local Sums2 = {}
	local Itterations = { processed = 0, count = 0 }

	return function (index_candle)

		if (MAParameters.Period > 0) then
			if (index_candle == 1) then 
				Sums = {}
				Sums2 = {}
				Itterations = { processed = 0, count = 0 }
			end

			local t_ma = SD_MA(index_candle)
			
			if CandleExist(index_candle) then
				if (index_candle ~= Itterations.processed) then 
					Itterations = { processed = index_candle, count = Itterations.count + 1 } 
				end
				
				local index1 = Squeeze(Itterations.count, MAParameters.Period)
				local index2 = Squeeze(Itterations.count - 1, MAParameters.Period)
				local index3 = Squeeze(Itterations.count - MAParameters.Period, MAParameters.Period)

				Sums[index1] = (Sums[index2] or 0) + C(Itterations.processed)
				Sums2[index1] = (Sums2[index2] or 0) + C(Itterations.processed) ^ 2

				if ((Itterations.count >= MAParameters.Period) and t_ma) then
					
					return math.sqrt((Sums2[index1] - (Sums2[index3] or 0) - 2 * t_ma * (Sums[index1] - (Sums[index3] or 0)) + MAParameters.Period * (t_ma ^ 2)) / MAParameters.Period) 
				end
			end
		end
		return nil
	end
end

--[[--------------------------------------------------------------------------
	VMA = sums(Pi*Vi) / sums(Vi)
--  --------------------------------------------------------------------------]]
function VMA()
	local SumsPriceVolume = {}
	local SumsVolume = {}
	local Itterations = { processed = 0, count = 0 }

	return function(index_candle)
		if (index_candle == 1) then
			SumsPriceVolume = {}
			SumsVolume = {}
			Itterations = { processed = 0, count = 0 }
		end

		if CandleExist(index_candle) then
			if (index_candle ~= Itterations.processed) then 
				Itterations = { processed = index_candle, count = Itterations.count + 1 } 
			end

			local index1 = Squeeze(Itterations.count, MAParameters.Period)
			local index2 = Squeeze(Itterations.count - 1, MAParameters.Period)
			local index3 = Squeeze(Itterations.count - MAParameters.Period, MAParameters.Period)

			SumsPriceVolume[index1] = (SumsPriceVolume[index2] or 0) + C(Itterations.processed) * V(Itterations.processed)
			SumsVolume[index1] = (SumsVolume[index2] or 0) + V(Itterations.processed)

			if (Itterations.count >= MAParameters.Period) then
				return (SumsPriceVolume[index1] - (SumsPriceVolume[index3] or 0)) / (SumsVolume[index1] - (SumsVolume[index3] or 0))
			end
		end
		return nil
	end
end

--[[--------------------------------------------------------------------------
	SMA = sums(Pi) / n
--  --------------------------------------------------------------------------]]
function SMA()
	local Sums = {}
	local Itterations = { processed = 0, count = 0 }

	return function (index_candle)
		if (index_candle == 1) then
			Sums = {}
			Itterations = { processed = 0, count = 0 }
		end

		if CandleExist(index_candle) then
			if (index_candle ~= Itterations.processed) then 
				Itterations = { processed = index_candle, count = Itterations.count + 1 } 
			end

			local index1 = Squeeze(Itterations.count, MAParameters.Period)
			local index2 = Squeeze(Itterations.count - 1, MAParameters.Period)
			local index3 = Squeeze(Itterations.count - MAParameters.Period, MAParameters.Period)

			Sums[index1] = (Sums[index2] or 0) + C(Itterations.processed)

			if (Itterations.count >= MAParameters.Period) then
				return (Sums[index1] - (Sums[index3] or 0)) / MAParameters.Period
			end
		end
		return nil
	end
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function SetChartLabel(x_value, y_value, tag_chart, text)
    LabelParams.YVALUE = y_value
    LabelParams.HINT = text .. ":" .. tostring(LabelParams.YVALUE)
    LabelParams.TEXT = LabelParams.HINT
    
    LabelParams.DATE = tostring(10000 * x_value.year + 100 * x_value.month + x_value.day)
    LabelParams.TIME = tostring(10000 * x_value.hour + 100 *  x_value.min + x_value.sec)

    local direction = string.upper(string.sub(text, 1, 1))
    if (direction == "L") then
        LabelParams.IMAGE_PATH = ScriptPath .. "\\arrowupgreen.jpg"
        LabelParams.ALIGNMENT = "BOTTOM"
    elseif (direction == "S") then
        LabelParams.IMAGE_PATH = ScriptPath .. "\\arrowdownred.jpg"
        LabelParams.ALIGNMENT = "TOP"
    else
        return nil
	end
	
	message(table.tostring(LabelParams))
	PrintDbgStr(table.tostring(LabelParams))

    return AddLabel(tag_chart, LabelParams)
end

--[[--------------------------------------------------------------------------
	ErrorMessage(message1, message2, ...)
--  --------------------------------------------------------------------------]]
function ErrorMessage(...)
	local args = { n = select("#",...), ... }
    if (args.n > 0) then
        local count
        local tmessage = {}

        for count = 1, args.n do
			table.insert(tmessage, args[count])
        end
		local smessage = table.concat(tmessage, "/")
		
        message(smessage)    
        PrintDbgStr("QUIK|" .. smessage)
    end
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function RoundScale(value, scale)
    if ((value == nil) or (scale == nil)) then
        return nil
    end

	-- calc and return result
	local mult = 10^(scale or 0)

	if (value >= 0) then 
		return (math.floor(value * mult + 0.5) / mult)
	else 
		return (math.ceil(value * mult - 0.5) / mult) 
	end
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function CrossOver(value1, value2)
    if ((value1[1] < value2[1]) and (value1[2] > value2[2])) then
        return true
    else 
        return false
    end
end

function CrossUnder(value1, value2)
    if ((value1[1] > value2[1]) and (value1[2] < value2[2])) then
        return true
    else 
        return false
    end
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function Squeeze(index, period)
	return math.fmod(index - 1, period + 1)
end

--[[--------------------------------------------------------------------------
    table.val_to_str
--  --------------------------------------------------------------------------]]
function table.val_to_str(v)
    if "string" == type(v) then
        v = string.gsub(v, "\n", "\\n")
        if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v, '"', '\\"') .. '"'
    end
    return "table" == type(v) and table.tostring(v) or tostring(v)
end

--[[--------------------------------------------------------------------------
    table.key_to_str
--  --------------------------------------------------------------------------]]
function table.key_to_str(k)
    if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
        return k
    end
    return "[" .. table.val_to_str(k) .. "]"
end

--[[--------------------------------------------------------------------------
    table.tostring
--  --------------------------------------------------------------------------]]
function table.tostring(tbl)
    if type(tbl) ~= 'table' then return table.val_to_str(tbl) end
    local result, done = {}, {}
    for k, v in ipairs(tbl) do
        table.insert(result, table.val_to_str(v))
        done[k] = true
    end
    for k, v in pairs(tbl) do
        if not done[k] then
            table.insert(result, table.key_to_str(k) .. "=" .. table.val_to_str(v))
        end
    end
    return "{" .. table.concat(result, ",") .. "}"
end

--[[--------------------------------------------------------------------------
    table.tostring
--  --------------------------------------------------------------------------]]
function table.load(fname)
    local f, err = io.open(fname, "r")
    if f == nil then return {} end
    local fn, err = loadstring("return "..f:read("*a"))
    f:close()
    if type(fn) == "function" then
        local succ, res = pcall(fn)
        if succ and type(res) == "table" then return res end
    end
    return {}
end

--[[-------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function table.save(fname, tbl)
    local f, err = io.open(fname, "w")
    if f ~= nil then
        f:write(table.tostring(tbl))
        f:close()
    end
end
--[[ EOF ]]--