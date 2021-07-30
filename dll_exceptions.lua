function SignalPriceCrossMA(prices, mas, index, direction, dev)
	if (CheckDataSufficiency(index, 1, prices.Open) and CheckDataSufficiency(index, 2, prices.Close) and CheckDataSufficiency(index_candle, 2, mas)) then
		dev = dev or 0
		direction = direction and string.upper(string.sub(direction, 1, 1))
	
		local key, value
		for key, value in pairs(Directions) do
			if (direction == value) then
				-- return true or false
				return (-- candle up/down
						SignalIsRelate(prices.Close[index-1], prices.Open[index-1], direction) and
						-- candle cross ma up/down
						SignalCross(prices.Close, mas, index, direction, dev))
			end
		end
		-- return error
		return false
	else
		-- return error
		return false
	end
end

    if (type(nnum) ~= "number") then
        local ntemp = tonumber(nnum)
        if (ntemp == nil)  then
            sLastProblem = snameFunc .. tStandardMessages.WRONGTYPE .. " of button number"
            WriteRobotLogFile(sLastProblem, tTypeLogMessages.ERROR)
            return -1
        else
            nnum = ntemp
        end
    end