Console:Register('record', 'Start recording', function(args)
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
end)

Console:Register('stop', 'Stop recording', function(args)
	print("Stop recording")
	NetEvents:SendLocal('BattleRecorder:Stop')
end)

Console:Register('play', 'Play recording', function(args)
	print("Playing recording")
	NetEvents:SendLocal('BattleRecorder:Play')
end)

Console:Register('clear', 'Clear recording', function(args)
	print("Playing recording")
	NetEvents:SendLocal('BattleRecorder:Clear')
end)