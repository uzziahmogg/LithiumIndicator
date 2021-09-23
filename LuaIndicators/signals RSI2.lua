--[[==========================================================================
    TODO
	1. signal crossrsi - ok 
	2. signal cross50/crossrsi50
	3. signal trendon/cross60/crossrsi60
	4. signal unturninzone50-60/60-80
	5. diver80 (+level)
	6. spring80/60

	all slow in m1/fast in m3
--  ==========================================================================]]
Settings = {	Name = "FEK_RSI2", 
				Parameters = {	PeriodSlow = 14, 
								PeriodFast = 9	}, 
				line = {{	Name = "RSISlow",
							Type = TYPE_LINE, 
                            Color = RGB(221, 44, 44)	},
                        {   Name = "RSIFast",
                            Type = TYPE_LINE, 
                            Color = RGB(221, 221, 44)	}}}

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function Init()
	FuncSlow = RSI("SLOW")
	FuncFast = RSI("FAST")

	return #Settings.line
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function OnCalculate(index_candle)
	local rsi_slow = RoundScale(FuncSlow(index_candle), 4)

	local rsi_fast = RoundScale(FuncFast(index_candle), 4)

	return rsi_slow, rsi_fast
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function RSI(mode) 
    mode = string.sub(string.upper(mode), 1, 1)
	local MASettings = {}
    if (mode == "S") then
        MASettings.Period = Settings.Parameters.PeriodSlow
    elseif (mode == "F") then
        MASettings.Period = Settings.Parameters.PeriodFast
    end

	local MA_Up = MMA(MASettings)
	local MA_Down = MMA(MASettings)

	local Prices = { previous = nil, current = nil}
	local Itterations = { processed = 0, count = 0 }

	return function (index_candle)
		if (index_candle == 1) then
			Itterations = { processed = 0, count = 0 }
		end

		if CandleExist(index_candle) then
			if (index_candle ~= Itterations.processed) then 
				Itterations = { processed = index_candle, count = Itterations.count + 1 }
				Prices.previous = Prices.current
			end

			Prices.current = C(Itterations.processed)

			local move_up = 0
			local move_down = 0

			if (Itterations.count > 1) then
				if (Prices.previous < Prices.current) then
					move_up = Prices.current - Prices.previous
				end

				if (Prices.previous > Prices.current) then
					move_down = Prices.previous - Prices.current
				end
			end

			local value_up = MA_Up(Itterations.count, {[Itterations.count] = move_up})
			local value_down = MA_Down(Itterations.count, {[Itterations.count] = move_down})

			if (Itterations.count >= MASettings.Period) then
				if (value_down == 0) then 
					return 100
				else
					return 100 - (100 / (1 + (value_up / value_down)))
				end
			end
		end
		return nil
	end
end

--[[--------------------------------------------------------------------------
	MMA = (MMAi-1*(n-1) + Pi) / n
--  --------------------------------------------------------------------------]]
function MMA(ma_settings) 
	local MASettings = ma_settings
	local Sums = {}
	local Values = { previous = nil, current = nil }
	local Itterations = { processed = 0, count = 0 }

    local period
    return function(index_candle, prices)

		if (index_candle == 1) then
			Sums = {}
			Values = { previous = nil, current = nil }
			Itterations = { processed = 0, count = 0 }
		end

		if CandleExist(index_candle) then
			if (index_candle ~= Itterations.processed) then 
				Itterations = { processed = index_candle, count = Itterations.count + 1 } 
				Values.previous = Values.current 
			end

			local index1 = Squeeze(Itterations.count, MASettings.Period)
			local index2 = Squeeze(Itterations.count - 1, MASettings.Period)
			local index3 = Squeeze(Itterations.count - MASettings.Period, MASettings.Period)

			if (Itterations.count <= (MASettings.Period + 1)) then
				Sums[index1] = (Sums[index2] or 0) + prices[Itterations.processed]

				if ((Itterations.count == MASettings.Period) or (Itterations.count == MASettings.Period + 1)) then
					Values.current = (Sums[index1] - (Sums[index3] or 0)) / MASettings.Period 
				end
			else
				Values.current = (Values.previous * (MASettings.Period - 1) + prices[Itterations.processed]) / MASettings.Period 
			end

			if (Itterations.count >= MASettings.Period) then
				return Values.current
			end
		end
		return nil
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
function Squeeze(index, period)
	return math.fmod(index - 1, period + 1)
end

--[[ EOF ]]--