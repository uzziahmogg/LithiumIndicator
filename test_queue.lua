
--todo function to calc number of candles
function Queue(from, to)
    From = from
    To = to
	Queues = { Indexes = {}, Values = {} }
    Size = (to - from + 1)

	return function (index, value)
		if (index == 1) then
			Queues = { Indexes = {}, Values = {} }			
		end

		if (--CandleExist(index) and 
        (index >= From) and (index <= To)) then
            -- insert close price to end of Queues and update Sum of closes
			table.insert(Queues.Indexes, index)
            table.insert(Queues.Values, value)
	
            -- DUBLICATE "and (index <= To)" - if Queues growth up max size
			--[[ if ((#Queues.Indexes > Size) and (#Queues.Values > Size)) then
                --remove earlest price from Queues
				table.remove(Queues.Indexes, 1)
                table.remove(Queues.Values, 1)
			end ]]
		end 
		return Queues
	end
end 

-- constructor
q = Queue(11, 33)

for i = 1, 50 do
    qq = q(i, i/2)
end

for i, j in pairs(qq.Indexes) do
    print( 'Queues.Indexes[' .. i .. "]=" .. j)
end

for x, y in pairs(qq.Values) do
    print( 'Queues.Values[' .. x .. "]=" .. y)
end 

for i = 1, 50 do
    print('qq[' .. i .. "/" .. tostring(qq.Indexes[i]).. "]=" .. tostring(qq.Values[i]))
end

