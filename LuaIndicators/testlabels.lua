Settings={}
Settings.Name = "FEK_test_labels"

function Init()
	--a = {}
	ScriptPath = getScriptPath()
	IconPath = ScriptPath .. "\\white_theme\\"

	return 1
end

function OnCalculate(index)
	if (index > 2500) then
		--message("candle:" .. tostring(index))
		--PrintDbgStr("candle:" .. tostring(index))

		datetime = T(index)

		LabelParams = { TEXT = tostring(index), 
		IMAGE_PATH = IconPath .. "plus_down.jpg", 
		ALIGNMENT = "BOTTOM", 
		YVALUE = L(index), 
		DATE = tostring(10000 * datetime.year + 100 * datetime.month + datetime.day),
		TIME = tostring(10000 * datetime.hour + 100 * datetime.min + datetime.sec), 
		R = 0, G = 0, B = 0, TRANSPARENCY = 0,
		TRANSPARENT_BACKGROUND = 1, FONT_FACE_NAME = "Arial", FONT_HEIGHT = 8, 
		HINT = tostring(index) }

		--if (a[index] == nil) then
			--a[index] = AddLabel("FEK_LITHIUMPrice", LabelParams)
		AddLabel("FEK_LITHIUMPrice", LabelParams)

		-- message("id label:" .. tostring(a[index]))
		-- PrintDbgStr(tostring(a[index]))
		--end		
	end
	-- if (index == 3075) then
	-- 	LabelParams = { IMAGE_PATH = IconPath .. "big_plus_down.jpg" }
	-- 	local count
	-- 	for count = 3000, 3050, 1 do
	-- 		SetLabelParams("FEK_LITHIUMPrice", a[count], LabelParams)				
	-- 	end
	-- end

	return L(index)
end

