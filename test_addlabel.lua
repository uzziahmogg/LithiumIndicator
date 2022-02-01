Settings = {
	Name = "FEK_minimal",
	line = { Name = "Top", Type = TYPE_LINE, Color = RGB(221, 44, 44) }
}

function Init()
	Pass = 0
	A = {}
	return 1
end

function OnCalculate(index)
	if (index == 1) then
		Pass = Pass + 1
		PrintDbgStr("Pass: " .. tostring(Pass))
	end

	if (index == Size()) then
		local label_params = {}
		label_params.TEXT = "Sample text" .. "," .. tostring(Pass) .. "," .. tostring(index)
		label_params.HINT = label_params.TEXT
		label_params.IMAGE_PATH = getScriptPath() .. "\\black_theme\\big_arrow_L.jpg"
		label_params.ALIGNMENT = "BOTTOM" 
		
		local t = T(index)
		label_params.DATE = tostring(10000 * t.year + 100 * t.month + t.day)
		label_params.TIME = tostring(10000 * t.hour + 100 * t.min + t.sec)
		label_params.R = 255
		label_params.G = 255 
		label_params.B = 255 
		label_params.TRANSPARENCY = 0 
		label_params.TRANSPARENT_BACKGROUND = 1
		label_params.FONT_FACE_NAME = "Arial"
		label_params.FONT_HEIGHT = 8 
		
		PrintDbgStr("===" .. tostring(Pass) .. "," .. tostring(index))
		
		PrintDbgStr(" before A[1]="  .. tostring(A[1]))
		label_params.YVALUE = 75700
		A[1] = AddLabel("xxx", label_params)
		PrintDbgStr(" after A[1]="  .. tostring(A[1]))
		
		PrintDbgStr(" before A[2]="  .. tostring(A[2]))
		label_params.IMAGE_PATH = getScriptPath() .. "\\black_theme\\big_romb_L.jpg"
		label_params.YVALUE = 40 
		A[2] = AddLabel("yyy", label_params)
		PrintDbgStr(" after A[2]="  .. tostring(A[2]))
		
		PrintDbgStr(" before A[3]="  .. tostring(A[3]))
		label_params.IMAGE_PATH = getScriptPath() .. "\\black_theme\\big_plus_L.jpg"
		label_params.YVALUE = 50
		A[3] = AddLabel("zzz", label_params)
		PrintDbgStr(" after A[3]="  .. tostring(A[3]))
	end
	return 50
end
