Console:Register('record', 'start recording', function(args)
	-- Print usage instructions if we got an invalid number of arguments.
	if #args ~= 1 then
		return 'Usage: _BattleRecorder.record <*Start/Stop/Play/Clear*>'
	end

	-- Parse and validate the arguments.
	local state = args[1]
	if state:lower() == "start" or state:lower() == "record" then
		local localPlayer = PlayerManager:GetLocalPlayer()
		if localPlayer == nil then
			print("No local player")
			return
		end
		if localPlayer.soldier == nil then
			print("No soldier")
			return
		end
		print("Recording")
		NetEvents:SendLocal('BattleRecorder:StartRecording')
	end

	if state:lower() == "stop" then
		print("Stop recording")
		NetEvents:SendLocal('BattleRecorder:Stop')
	end
	if state:lower() == "play" then
		print("Playing recording")
		NetEvents:SendLocal('BattleRecorder:Play')
	end
	if state:lower() == "clear" then
		NetEvents:SendLocal('BattleRecorder:Clear')
	end
	return nil
end)
