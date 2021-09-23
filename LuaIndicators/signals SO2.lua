--[[==========================================================================
	TODO:
	coding elementary signals:
	1. StochFast cross StochSlow  
	2. SlowStoch cross lvl50
	3. StochSlow Trendon - cross lvl80

	coding complex signals:
	4. Stoch Uturn
	5. Stoch Spring
	6. StochZigZag
--  ==========================================================================]]
Settings = {	Name = "FEK_STOCH2", 
				Slow = {    PeriodK = 10, 
				            Shift 	= 3, 
                            PeriodD = 1 },
                Fast = {    PeriodK = 5, 
                            Shift 	= 2, 
                            PeriodD = 1 },
                line = {{	Name 	= "StochSlow", 
							Type 	= TYPE_LINE, 
							Color 	= RGB(255, 68, 68),
							Width 	= 3	},
                        {	Name 	= "StochFast", 
							Type 	= TYPE_LINE, 
							Color 	= RGB(255, 208, 96),
							Width 	= 1	}}}
			
--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]							
function Init()
	FuncSlow = Stoch("SLOW")
	FuncFast = Stoch("FAST")

	return #Settings.line
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function OnCalculate(index_candle) 
	local count
	local stochs = { slow = 0, fast = 0 }

	-- calculate current stoch
	stochs.slow, _ = RoundScale(FuncSlow(index_candle), 4)
	stochs.fast, _ = RoundScale(FuncFast(index_candle), 4)

	return stochs.slow, stochs.fast
end

--[[--------------------------------------------------------------------------
	Stochastic Oscillator ("SO")
--  --------------------------------------------------------------------------]]
function Stoch(mode) 
    mode = string.upper(string.sub(mode, 1, 1))
    local settings
    if (mode == "S") then
        settings = {  	period_k 	= Settings.Slow.PeriodK, 
						shift 		= Settings.Slow.Shift, 
						period_d 	= Settings.Slow.PeriodD }
    elseif (mode == "F") then
        settings = {  	period_k 	= Settings.Fast.PeriodK, 
						shift 		= Settings.Fast.Shift, 
						period_d 	= Settings.Fast.PeriodD }
    end

	local k_ma1 = SMA(settings)
	local k_ma2 = SMA(settings)
	local d_ma  = EMA(settings)

	local highs = {}
	local lows = {}
	local candles = { processed = 0, count = 0 }

	return function (index_candle)
		if (settings.period_k > 0) and (settings.period_d > 0) then
			if (index_candle == 1) then 
				highs = {}
				lows = {}
				candles = { processed = 0, count = 0 }
			end

			if CandleExist(index_candle) then
				if (index_candle ~= candles.processed) then 
					candles = { processed = index_candle, count = candles.count + 1 } 
				end

				highs[Squeeze(candles.count, settings.period_k - 1) + 1] = H(candles.processed)
				lows[Squeeze(candles.count, settings.period_k - 1) + 1] = L(candles.processed)

				if (candles.count >= settings.period_k)  then
					local max_high = math.max(unpack(highs))
					local max_low = math.min(unpack(lows))

					local value_k1 = k_ma1(candles.count - settings.period_k + 1, 
										{[candles.count - settings.period_k + 1] = C(candles.processed) - max_low})

					local value_k2 = k_ma2(candles.count - settings.period_k + 1, 
										{[candles.count - settings.period_k + 1 ] = max_high - max_low})
					
					if ((candles.count >= (settings.period_k + settings.shift - 1)) and (value_k2 ~= 0)) then
						local stoch_k = 100 * value_k1 / value_k2
						local stoch_d = d_ma(candles.count - (settings.period_k + settings.shift - 2), 
											{[candles.count - (settings.period_k + settings.shift - 2)] = stoch_k})

						return stoch_k, stoch_d
					end
				end
			end
		end
		return nil, nil
	end
end

--[[--------------------------------------------------------------------------
	EMAi = (EMAi-1*(n-1)+2*Pi) / (n+1)
--  --------------------------------------------------------------------------]]
function EMA(settings)
	local EMAs = { previous = nil, current = nil }
	local candles = { processed = 0, count = 0 }

	return function(index_candle, prices)
		if (index_candle == 1) then
			EMAs = { previous = nil, current = nil }
			candles = { processed = 0, count = 0 }
		end

		if CandleExist(index_candle) then
			if (index_candle ~= candles.processed) then 
				candles = { processed = index_candle, count = candles.count + 1 } 
				EMAs.previous = EMAs.current 
			end

			if (candles.count == 1) then
				EMAs.current = prices[candles.processed]
			else
				EMAs.current = (EMAs.previous * (settings.period_d - 1) + 2 * prices[candles.processed]) / (settings.period_d + 1)
			end
			if (candles.count >= settings.period_d) then
				return EMAs.current
			end
		end
		return nil
	end
end

--[[--------------------------------------------------------------------------
	SMA = sums(Pi) / n
--  --------------------------------------------------------------------------]]
function SMA(settings)
	local sums = {}
	local candles = { processed = 0, count = 0 }

	return function (index_candle, prices)
		if (index_candle == 1) then
			sums = {}
			candles = { processed = 0, count = 0 }
		end

		if CandleExist(index_candle) then
			if (index_candle ~= candles.processed) then 
				candles = { processed = index_candle, count = candles.count + 1 } 
			end

			local index1 = Squeeze(candles.count, settings.shift)
			local index2 = Squeeze(candles.count - 1, settings.shift)
			local index3 = Squeeze(candles.count - settings.shift, settings.shift)

			sums[index1] = (sums[index2] or 0) + prices[candles.processed]

			if (candles.count >= settings.shift) then
				return (sums[index1] - (sums[index3] or 0)) / settings.shift
			end
		end
		return nil
	end
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function Squeeze(index, period)
	return math.fmod(index - 1, period + 1)
end

--[[--------------------------------------------------------------------------
    RoundScale
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

--[[ EOF ]]--