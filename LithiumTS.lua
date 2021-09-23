--==========================================================================
--	TS Lithium, 2021 (c) FEK
--==========================================================================
Name = "FEKMOEX"
Version = 1.0
OneSecond = 1000
SecondsSleepMainCycle = 10
AttemptsConnect = 3
LastProblem = ""

TradingTypes = { LONG = 1, SHORT = 2 }

TSParams = { NAME = "Lithium", VERSION = 1.0, SECURITYCLASS = "TQBR", SECURITY = "GAZP", ISRUN = true, 
			TRADINGTYPE = TradingTypes.LONG + TradingTypes.Short, CURRENTSIGNAL = 0, STEPPRICE = 0 }

---------------------------------------------------------------------------
-- Init TS
----------------------------------------------------------------------------
function OnInit()
	CreateTS()
end

---------------------------------------------------------------------------
-- TS main cycle
---------------------------------------------------------------------------
---@diagnostic disable-next-line: lowercase-global
function main()
	-- main cycle
	while (TSParams.ISRUN == true) do
		if (RunTS() == -1) then
			TSParams.ISRUN = false
		else
			sleep(SecondsSleepMainCycle * OneSecond)
		end
	end

	DestroyTS()
end

---------------------------------------------------------------------------
--  Stop TS
----------------------------------------------------------------------------
function OnStop()
	TSParams.ISRUN = false
	return (10 * OneSecond)
end

---------------------------------------------------------------------------
--  Run TS
----------------------------------------------------------------------------
function RunTS()
	-- check connect to server
	local server_time = GetServerTime()
	if (server_time == -1) then
		return -1
	end
	message(string.upper_first_letter("server time:" .. tostring(server_time)))

	-- check session status of security
	local session_status = GetSessionStatus()
	if (session_status == -1) then
		return -1
	end
	message(string.upper_first_letter("session status ".. TSParams.SECURITY .." is ok"))

	-- check signals from charts and filter signals with type of tradings
	TSParams.CURRENTSIGNAL = GetSignalsChart()
end

----------------------------------------------------------------------------
--  CreateTS
----------------------------------------------------------------------------
function CreateTS()
	TSParams.STEPPRICE = tonumber(getParamEx(TSParams.SECURITYCLASS, TSParams.SECURITY, "SEC_PRICE_STEP").param_value)

	--todo init CLIENT_CODE field for transaction
	--todo open logfile/write logfile ts params
	--todo alloc ts able/add columns tstable/create tstable
	--todo open trades csv file
end

----------------------------------------------------------------------------
--  DestroyTS
----------------------------------------------------------------------------
function DestroyTS()
	--todo delete all orders
	--todo close all positions
	--todo close ts table
	--todo close logfile
	--todo close trades csv file
end

----------------------------------------------------------------------------
--  GetServerTime
----------------------------------------------------------------------------
function GetServerTime()
	local server_time = ""
	local count = 0

	-- try connect to server
	for count = 1, AttemptsConnect do
		server_time = getInfoParam("SERVERTIME")
		-- if server time ok
		if (server_time ~= "") then
			return server_time
		end

		-- write error to robot table
		LastProblem = "cannot get server time"

		-- wait one second to next itteration
		sleep(OneSecond)
	end

	-- return error
	return -1
end

----------------------------------------------------------------------------
--  GetSessionStatus
----------------------------------------------------------------------------
function GetSessionStatus()
	local session_status = ""
	local count = 0

	for count = 1, AttemptsConnect do
		-- try get session status
		session_status = tonumber(getParamEx(TSParams.SECURITYCLASS, TSParams.SECURITY, "STATUS").param_value)
		
		-- if session status ok
		if (session_status == 1) then         
			return session_status
		end

		-- write error to robot table
		LastProblem = "session " .. TSParams.SECURITY .. " closed status=" .. tostring(session_status)

		-- wait one second to next itteration
		sleep(OneSecond)
	end

	-- return error
	return -1
end

----------------------------------------------------------------------------
-- string.upper_first_letter
----------------------------------------------------------------------------
function string.upper_first_letter(str)
	-- input error
	if (str == nil) then
		return -1
	end

	-- check input string type
	if (type(str) ~= "string") then
		str = tostring(str)
	end

	-- nothing todo
	if ((str == "") or (str == nil)) then
		return 0
	end

	return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2, string.len(str))
end
--[[ EOF ]]--