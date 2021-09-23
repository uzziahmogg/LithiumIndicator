--[[==========================================================================
TODO 1. signall crossMA ok
    2   signal uturnMA
    3.  signal uturn
	4. signal BBexpansion
	5. BBDiver
--  ==========================================================================]]
Settings = {	Name = "FEK_BB",
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
    BBs = { Name = "BB", Top = {}, Bottom = {}, Delta = {} }
    MAs = { Name = "MA", Delta = {} }
    Prices = { Name = "Price", Open = {}, Close = {}, High = {}, Low = {}  }

    ChartTag = Settings.Name .. Prices.Name 	-- FEK_BBPrice

    LabelParams = { R = 255, G = 255, B = 255,
                    TRANSPARENCY = 0, TRANSPARENT_BACKGROUND = 1,
                    FONT_FACE_NAME = "Arial", FONT_HEIGHT = 8 }

	MAParameters = { Period = 20,  Shift = 2 }

    Directions = { Up = "L", Down = "S" }

    FuncBB = BB()

	ScriptPath = getScriptPath()

	Signals = { [Directions.Up] = { Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }}, 
	[Directions.Down] = { Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }}, Duration = 4}

	ChartStep = 15

	return #Settings.line
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function OnCalculate(index_candle)

	if (index_candle == 1) then
		DataSource = getDataSourceInfo()
		SecInfo = getSecurityInfo(DataSource.class_code, DataSource.sec_code)

		Signals[Directions.Up].Uturn3.Count = 0
		Signals[Directions.Up].Uturn4.Count = 0

		Signals[Directions.Down].Uturn3.Count = 0
		Signals[Directions.Down].Uturn4.Count = 0
	end

	Prices.Open[index_candle] = O(index_candle)
	Prices.Close[index_candle] = C(index_candle)
	Prices.High[index_candle] = H(index_candle)
	Prices.Low[index_candle] = L(index_candle)

	MAs[index_candle], BBs.Top[index_candle], BBs.Bottom[index_candle] = FuncBB(index_candle)
	MAs[index_candle] = RoundScale(MAs[index_candle], 4)
	BBs.Top[index_candle] = RoundScale(BBs.Top[index_candle], 4)
	BBs.Bottom[index_candle] = RoundScale(BBs.Bottom[index_candle], 4)

	BBs.Delta[index_candle] =  ((BBs.Top[index_candle] ~= nil) and (BBs.Bottom[index_candle] ~= nil)) and RoundScale(GetDelta(BBs.Top[index_candle], BBs.Bottom[index_candle]), 4)
	MAs.Delta[index_candle] = ((Prices.Close[index_candle]~= nil) and (MAs[index_candle] ~= nil)) and RoundScale(GetDelta(Prices.Close[index_candle], MAs[index_candle]), 4)

	PrintDbgStr("candle:" .. index_candle.. "|".. T(index_candle).day  .. "|".. T(index_candle).hour  .. "|".. T(index_candle).min .. "============================")

	if (CheckDataSufficiency(index_candle, 3, Prices.Close) and CheckDataSufficiency(index_candle, 3, Prices.Open) and
	CheckDataSufficiency(index_candle, 3, Prices.High) and CheckDataSufficiency(index_candle, 3, Prices.Low) and
	CheckDataSufficiency(index_candle, 3, MAs) and CheckDataSufficiency(index_candle, 3, MAs.Delta)) then

		-- check price uturn3 up
		if (SignalPriceUturn3(Prices, MAs, index_candle, Directions.Up)) then

			-- set elementary down signal off
			Signals[Directions.Down].Uturn3.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].Uturn3.Candle = index_candle - 1
			Signals[Directions.Up].Uturn3.Count = Signals[Directions.Up].Uturn3.Count + 1

			-- set chart label
			SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1] - 2 * ChartStep * SecInfo.min_price_step), ChartTag, "LPriceUturn3#" .. tostring(Signals[Directions.Up].Uturn3.Count))

		-- check elementary up signal duration
		elseif ((Signals[Directions.Up].Uturn3.Candle > 0) and ((index_candle - Signals[Directions.Up].Uturn3.Candle) > Signals.Duration)) then

			-- set elementary up signal off
			Signals[Directions.Up].Uturn3.Candle = 0

		-- check price uturn3 down
		elseif (SignalPriceUturn3(Prices, MAs, index_candle, Directions.Down)) then

			-- set elementary up signal off
			Signals[Directions.Up].Uturn3.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].Uturn3.Candle = index_candle - 1
			Signals[Directions.Down].Uturn3.Count = Signals[Directions.Down].Uturn3.Count + 1

			-- set chart label
			SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1] + 2 * ChartStep * SecInfo.min_price_step), ChartTag, "SPriceUturn3#" .. tostring(Signals[Directions.Down].Uturn3.Count))

		-- check elementary down signal duration
		elseif ((Signals[Directions.Down].Uturn3.Candle > 0) and ((index_candle - Signals[Directions.Down].Uturn3.Candle) > Signals.Duration)) then

			-- set elementary down signal off
			Signals[Directions.Down].Uturn3.Candle = 0
		end
	end

	--
	-- I.3. Elementary Signals: Signals[Directions.Down/Up].Prices.Uturn4
	-- 		Enter Signal: Signals[Directions.Down/Up].Uturn, Signals[Directions.Down/Up].Spring1/2
	--
	if (CheckDataSufficiency(index_candle, 4, Prices.Close) and	CheckDataSufficiency(index_candle, 4, Prices.Open) and
	CheckDataSufficiency(index_candle, 4, Prices.High) and CheckDataSufficiency(index_candle, 4, Prices.Low) and 
	CheckDataSufficiency(index_candle, 4, MAs) and CheckDataSufficiency(index_candle, 4, MAs.Delta)) then

		-- check price uturn4 up
		if (SignalPriceUturn4(Prices, MAs, index_candle, Directions.Up)) then

			-- set elementary down signal off
			Signals[Directions.Down].Uturn4.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].Uturn4.Candle = index_candle - 1
			Signals[Directions.Up].Uturn4.Count = Signals[Directions.Up].Uturn4.Count + 1

			-- set debug chart label
			SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1] - 3 * ChartStep * SecInfo.min_price_step), ChartTag, "LPriceUturn4#" .. tostring(Signals[Directions.Up].Uturn4.Count))

		-- check elementary up signal duration
		elseif ((Signals[Directions.Up].Uturn4.Candle  > 0) and (index_candle - Signals[Directions.Up].Uturn4.Candle) > Signals.Duration) then
			Signals[Directions.Up].Uturn4.Candle = 0

			-- check price uturn4 down
		elseif (SignalPriceUturn4(Prices, MAs, index_candle, Directions.Down)) then

			-- set elementary up signal off
			Signals[Directions.Up].Uturn4.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].Uturn4.Candle = index_candle - 1
			Signals[Directions.Down].Uturn4.Count = Signals[Directions.Down].Uturn4.Count + 1

			-- set debug chart label
			SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1] + 3 * ChartStep * SecInfo.min_price_step), ChartTag, "SPriceUturn4#" .. tostring(Signals[Directions.Down].Uturn4.Count))

		-- check elementary down signal duration
		elseif ((Signals[Directions.Up].Uturn4.Candle  > 0) and (index_candle - Signals[Directions.Down].Uturn4.Candle) > Signals.Duration) then

			-- set elementary down signal off
			Signals[Directions.Down].Uturn4.Candle = 0			
		end
	end

	return BBs.Top[index_candle], MAs[index_candle], BBs.Bottom[index_candle]
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
	local Sum = 0
	local Queue = {}

	return function (index_candle)
		if (index_candle == 1) then
			Queue = {}
			Sum = 0
		end

		if CandleExist(index_candle) then
			table.insert(Queue, C(index_candle))
			Sum = Sum + Queue[#Queue]

			if (#Queue == MAParameters.Period) then
				local sma = Sum / MAParameters.Period
				Sum = Sum - Queue[1]
				table.remove(Queue, 1)
				return sma
			end
		end
		return nil
	end
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function SetChartLabel(x_value, y_value, tag_chart, text)
	LabelParams.YVALUE = y_value
	LabelParams.HINT = text
	LabelParams.TEXT = LabelParams.HINT

	LabelParams.DATE = tostring(10000 * x_value.year + 100 * x_value.month + x_value.day)
	LabelParams.TIME = tostring(10000 * x_value.hour + 100 *  x_value.min + x_value.sec)

	local direction = string.upper(string.sub(text, 1, 1))
	if (direction == "L") then
		LabelParams.IMAGE_PATH = ScriptPath .. "\\arrow_up_green.jpg"
		LabelParams.ALIGNMENT = "BOTTOM"
	elseif (direction == "S") then
		LabelParams.IMAGE_PATH = ScriptPath .. "\\arrow_down_orange.jpg"
		LabelParams.ALIGNMENT = "TOP"
	else
		return nil
	end

	return AddLabel(tag_chart, LabelParams)
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

--[[--------------------------------------------------------------------------
	CheckDataSufficiency(index, number, value)
--  --------------------------------------------------------------------------]]
function CheckDataSufficiency(index, number, value)
	if (index <= number) then
		return false
	end

	local count
	for count = 1, number, 1 do
		if (value[index-count] == nil) then
			return false
		end
	end

	return true
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function GetDelta(value1, value2)
	return math.abs(value1 - value2)
end

--[[--------------------------------------------------------------------------
	PrintDebugString(message1, message2, ...)
--  --------------------------------------------------------------------------]]
--[[ function PrintDebugMessage(...)
	local args = { n = select("#",...), ... }
	if (args.n > 0) then
		local count
		local tmessage = {}

		for count = 1, args.n do
			table.insert(tmessage, args[count])
		end

		local smessage = table.concat(tmessage, "|")

		message(smessage)
		PrintDbgStr("QUIK|" .. smessage)
		return args.n
	else
		return 0
	end
end ]]

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function SignalPriceUturn3(price, ma, index, direction)
	direction = string.upper(string.sub(direction, 1, 1))

	if (direction == Directions.Up) then
		PrintDbgStr("from uturn3 up-----------")
		PrintDbgStr("from uturn3 up:[3]" .. price.Open[index-3] .."|"..price.Close[index-3] .. "[2]" .. price.Open[index-2]  .."|".. price.Close[index-2] .. "[1]" .. price.Open[index-1] .."|".. price.Close[index-1]) 
		PrintDbgStr("from uturn3 up:(price.Open[index-3] > price.Close[index-3])|" .. tostring((price.Open[index-3] > price.Close[index-3]) ))
		PrintDbgStr("from uturn3 up:(price.Open[index-2] > price.Close[index-2])|"..tostring((price.Open[index-2] > price.Close[index-2])))
		PrintDbgStr("from uturn3 up:(price.Close[index-1] > price.Open[index-1])|"..tostring((price.Close[index-1] > price.Open[index-1])))
		PrintDbgStr("from uturn3 up:SignalUturn(price.Close, index, direction)|"..tostring(SignalUturn(price.Close, index, direction)))
		PrintDbgStr("from uturn3 up:SignalUturn(ma.Delta, index, Directions.Up)|"..tostring(SignalUturn(ma.Delta, index, Directions.Up)))
		PrintDbgStr("from uturn3 up:SignalMove(ma, (index-1), direction)|"..tostring(SignalMove(ma, (index-1), direction)))
		PrintDbgStr("from uturn3 up:SignalMove(ma, index, direction)|"..tostring(SignalMove(ma, index, direction)))
		PrintDbgStr("from uturn3 up:(price.Close[index-1] > (price.Low[index-3] + 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3])))|"..tostring((price.Close[index-1] > (price.Low[index-3] + 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3])))))
		PrintDbgStr("from uturn3 up:(price.Close[index-1] > (price.Low[index-2] + 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])))|"..tostring((price.Close[index-1] > (price.Low[index-2] + 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])))))

		return ((((price.Open[index-3] > price.Close[index-3]) or (price.Open[index-2] > price.Close[index-2])) and
			(price.Close[index-1] > price.Open[index-1])) and
			-- price.close uturn
			SignalUturn(price.Close, index, direction) and
			-- delta min at top uturn
			SignalUturn(ma.Delta, index, Directions.Up) and
			-- ma move up
			(SignalMove(ma, (index-1), direction) and SignalMove(ma, index, direction)) and
			-- strength condition
			((price.Close[index-1] > (price.Low[index-3] + 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3]))) or
			(price.Close[index-1] > (price.Low[index-2] + 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])))))

	elseif (direction == Directions.Down) then
		PrintDbgStr("from uturn3 down-----------")
		PrintDbgStr("from uturn3 down:[3]" .. price.Open[index-3] .. "|".. price.Close[index-3] .. "[2]" .. price.Open[index-2] .."|".. price.Close[index-2] .. "[1]" .. price.Open[index-1] .."|"..price.Close[index-1]) 
		PrintDbgStr("from uturn3 down:(price.Close[index-3] > price.Open[index-3])|" .. tostring((price.Close[index-3] > price.Open[index-3])))
		PrintDbgStr("from uturn3 down:(price.Close[index-2] > price.Open[index-2])|"..tostring((price.Close[index-2] > price.Open[index-2])))
		PrintDbgStr("from uturn3 down:(price.Open[index-1] > price.Close[index-1])|"..tostring((price.Open[index-1] > price.Close[index-1])))
		PrintDbgStr("from uturn3 down:SignalUturn(price.Close, index, direction)|"..tostring(SignalUturn(price.Close, index, direction)))
		PrintDbgStr("from uturn3 down:SignalUturn(ma.Delta, index, Directions.Up)|"..tostring(SignalUturn(ma.Delta, index, Directions.Up)))
		PrintDbgStr("from uturn3 down:SignalMove(ma, (index-1), direction)|"..tostring(SignalMove(ma, (index-1), direction)))
		PrintDbgStr("from uturn3 down:SignalMove(ma, index, direction)|"..tostring(SignalMove(ma, index, direction)))
		PrintDbgStr("from uturn3 down:((price.High[index-3] - 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3])) > price.Close[index-1])|"..tostring(((price.High[index-3] - 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3])) > price.Close[index-1])))
		PrintDbgStr("from uturn3 down:((price.High[index-2] - 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])) > price.Close[index-1])|"..tostring(((price.High[index-2] - 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])) > price.Close[index-1])))


		return ((((price.Close[index-3] > price.Open[index-3]) or (price.Close[index-2] > price.Open[index-2])) and
			(price.Open[index-1] > price.Close[index-1])) and
			-- price.close uturn
			SignalUturn(price.Close, index, direction) and
			-- delta min at top uturn
			SignalUturn(ma.Delta, index, Directions.Up) and
			-- ma move down
			(SignalMove(ma, (index-1), direction) and SignalMove(ma, index, direction)) and
			-- strength condition
			(((price.High[index-3] - 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3])) > price.Close[index-1]) or
			((price.High[index-2] - 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])) > price.Close[index-1])))
	end
end

--
-- Signal Price Uturn4
--
function SignalPriceUturn4(price, ma, index, direction)
	direction = string.upper(string.sub(direction, 1, 1))

    if (direction == Directions.Up) then

		PrintDbgStr("from uturn4 up-----------")
		PrintDbgStr("from uturn4 up:" .. index.."|4|"..price.Open[index-4] .."|".. price.Close[index-4].."|3|"..price.Open[index-3] .."|".. price.Close[index-3].."|2|"..price.Open[index-2] .."|".. price.Close[index-2].."|1|"..price.Open[index-1] .."|".. price.Close[index-1])
		PrintDbgStr("from uturn4 up:(price.Open[index-4] > price.Close[index-4])|" .. tostring((price.Open[index-4] > price.Close[index-4])))
		PrintDbgStr("from uturn4 up:(price.Open[index-3] > price.Close[index-3])|" .. tostring((price.Open[index-3] > price.Close[index-3])))
		PrintDbgStr("from uturn4 up:(price.Close[index-1] > price.Open[index-1])|" .. tostring((price.Close[index-1] > price.Open[index-1])))
		PrintDbgStr("from uturn4 up:SignalMove(price.Close, index-2, Reverse(direction)|" .. tostring(SignalMove(price.Close, index-2, Reverse(direction))))
		PrintDbgStr("from uturn4 up:SignalMove(price.Close, index, direction)|" .. tostring(SignalMove(price.Close, index, direction)))
		PrintDbgStr("from uturn4 up:SignalMove(ma, (index-2), direction)|" .. tostring(SignalMove(ma, (index-2), direction)))
		PrintDbgStr("from uturn4 up:SignalMove(ma, index, direction)|" .. tostring(SignalMove(ma, index, direction)))
		PrintDbgStr("from uturn4 up:SignalMove(ma.Delta, index-2, Directions.Down)|" .. tostring(SignalMove(ma.Delta, index-2, Directions.Down)))
		PrintDbgStr("from uturn4 up:SignalMove(ma.Delta, index, Directions.Up)|" .. tostring(SignalMove(ma.Delta, index, Directions.Up)))
		PrintDbgStr("from uturn4 up:(price.Close[index-1] > (price.Low[index-3] + 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3])))|" .. tostring((price.Close[index-1] > (price.Low[index-3] + 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3])))))
		PrintDbgStr("from uturn4 up:(price.Close[index-1] > (price.Low[index-2] + 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])))|" .. tostring((price.Close[index-1] > (price.Low[index-2] + 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])))))

		-- first 2 candles down, last candle up
		return ((((price.Open[index-4] > price.Close[index-4]) or (price.Open[index-3] > price.Close[index-3])) and
			(price.Close[index-1] > price.Open[index-1])) and
			-- price.close uturn
			(SignalMove(price.Close, index-2, Reverse(direction)) and SignalMove(price.Close, index, direction)) and
			-- ma move up
			(SignalMove(ma, (index-2), direction) and SignalMove(ma, index, direction)) and
			-- delta min at top uturn
			(SignalMove(ma.Delta, index-2, Directions.Down) and SignalMove(ma.Delta, index, Directions.Up)) and
			-- strength condition
			((price.Close[index-1] > (price.Low[index-3] + 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3]))) or
			(price.Close[index-1] > (price.Low[index-2] + 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])))))

	elseif (direction == Directions.Down) then

		PrintDbgStr("from uturn4 down-----------")
		PrintDbgStr("from uturn4 down:" .. index.."|4|"..price.Open[index-4] .."|".. price.Close[index-4].."|3|"..price.Open[index-3] .."|".. price.Close[index-3].."|2|"..price.Open[index-2] .."|".. price.Close[index-2].."|1|"..price.Open[index-1] .."|".. price.Close[index-1])
		PrintDbgStr("from uturn4 down:(price.Close[index-4] > price.Open[index-4])|" .. tostring((price.Close[index-4] > price.Open[index-4]) ))
		PrintDbgStr("from uturn4 down:(price.Close[index-3] > price.Open[index-3])|" .. tostring((price.Close[index-3] > price.Open[index-3])))
		PrintDbgStr("from uturn4 down:(price.Open[index-1] > price.Close[index-1])|" .. tostring((price.Open[index-1] > price.Close[index-1])))
		PrintDbgStr("from uturn4 down:SignalMove(price.Close, index-2, Reverse(direction))|" .. tostring(SignalMove(price.Close, index-2, Reverse(direction))))
		PrintDbgStr("from uturn4 down:SignalMove(price.Close, index, direction)|" .. tostring(SignalMove(price.Close, index, direction)))
		PrintDbgStr("from uturn4 down:SignalMove(ma, (index-2), direction)|" .. tostring(SignalMove(ma, (index-2), direction)))
		PrintDbgStr("from uturn4 down:SignalMove(ma, index, direction)|" .. tostring(SignalMove(ma, index, direction)))
		PrintDbgStr("from uturn4 down:SignalMove(ma.Delta, index-2, Directions.Down)|" .. tostring(SignalMove(ma.Delta, index-2, Directions.Down)))
		PrintDbgStr("from uturn4 down:SignalMove(ma.Delta, index, Directions.Up)|" .. tostring(SignalMove(ma.Delta, index, Directions.Up)))
		PrintDbgStr("from uturn4 down:((price.High[index-3] - 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3])) > price.Close[index-1])|" .. tostring(((price.High[index-3] - 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3])) > price.Close[index-1]) ))
		PrintDbgStr("from uturn4 down:((price.High[index-2] - 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])) > price.Close[index-1])|" .. tostring(((price.High[index-2] - 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])) > price.Close[index-1])))

		-- one or two of 2 first candles are down, last 1 candle is up
		return ((((price.Close[index-4] > price.Open[index-4]) or (price.Close[index-3] > price.Open[index-3])) and
			(price.Open[index-1] > price.Close[index-1])) and
			-- price.close uturn
			(SignalMove(price.Close, index-2, Reverse(direction)) and SignalMove(price.Close, index, direction)) and
			-- ma move down
			(SignalMove(ma, (index-2), direction) and SignalMove(ma, index, direction)) and
			-- delta min at top uturn
			(SignalMove(ma.Delta, index-2, Directions.Down) and SignalMove(ma.Delta, index, Directions.Up)) and
		-- strength condition
			(((price.High[index-3] - 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3])) > price.Close[index-1]) or
			((price.High[index-2] - 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])) > price.Close[index-1])))
	end
end
--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
--
-- Signal 2 last candles Value move up or down
--
function SignalMove(value, index, direction) 
    direction = string.upper(string.sub(direction, 1, 1))
	PrintDbgStr("from SignalMove index|" .. index .. "|direction:".. direction)
	PrintDbgStr("from SignalMove value}" .. value[index-2] .. "|" .. value[index-1])
	if (direction == Directions.Up) then
		PrintDbgStr("from SignalMove up|" .. tostring(value[index-1] > value[index-2]))
		return (value[index-1] > value[index-2])
		
	elseif (direction == Directions.Down) then
		PrintDbgStr("from SignalMove down|" .. tostring(value[index-2] > value[index-1]))
		return (value[index-2] > value[index-1])
	end

	return false
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
--
-- Signal 3 last candles Value uturn up or down FIXME: code 5 candles
--
function SignalUturn(value, index, direction)
	direction = string.upper(string.sub(direction, 1, 1))
	PrintDbgStr("from SignalUturn index:" .. index .. "|direction:"..direction )
	PrintDbgStr("from SignalUturn value:" .. value[index-3] .. "|" .. value[index-2] .. "|".. value[index-1])
	if (direction == Directions.Up) then
		local result1 = (value[index-3] > value[index-2]) 
		local result2 = (value[index-1] > value[index-2])
		local result3 = result1 and result2
		PrintDbgStr("from SignalUturn up||" .. tostring(result1) .. "|".. tostring(result2) .. "|".. tostring(result3))

		return ((value[index-3] > value[index-2]) and (value[index-1] > value[index-2]))

	elseif (direction == Directions.Down) then
		local result1 = (value[index-2] > value[index-3]) 
		local result2 = (value[index-2] > value[index-1])
		local result3 = result1 and result2
		PrintDbgStr("from SignalUturn down||" .. tostring(result1) .. "|".. tostring(result2) .. "|".. tostring(result3))

		return ((value[index-2] > value[index-3]) and (value[index-2] > value[index-1]))
	end

	return false
end

function Reverse(direction)
	direction = string.upper(string.sub(direction, 1, 1))
	if (direction == Directions.Up) then
		return Directions.Down
	elseif (direction == Directions.Down) then
		return Directions.Up
	else
		return nil
	end
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