---@diagnostic disable: lowercase-global
Settings={	Name = "FEK_test",
			line = {{ Name 	= "Slow",
                    Type 	= TYPE_LINE,
                    Color 	= RGB(255, 68, 68),
                    Width 	= 3,
                Value = 1	},
				{	Name 	= "Fast",
                    Type 	= TYPE_LINE,
                    Color 	= RGB(255, 208, 96),
                    Width 	= 1,
                Value = 2}}}

function Init()
    trigger = -1
    count = 0
	ind = {1}
    str = "Full String"
	return Settings.line[2].Value
end

function OnCalculate(index)

	message(index .. "\t" .. T(index).day .. "\t" .. count)

    count = count + 1

    if (count%10 == 0) then
        if (trigger == 1) then
            trigger = -1
        elseif (trigger == -1) then
            trigger = 1
        end
    end

	if (trigger == 1) then
		-- ind[count] = ind[count-1] + 1
        --message(tostring(index) .. "\t" .. tostring(count) .. "\t" .. tostring(trigger) .. "\t" .. tostring(ind[count]))
	elseif (trigger == -1) then
		-- ind[count] = ind[count-1] - 1
        --message(tostring(index) .. "\t" .. tostring(count) .. "\t" .. tostring(trigger) .. "\t" .. tostring(ind[count]))
	end

	return 10, 20 -- ind[count], ind[count] + 1
end

