class 'BattleRecorderServer'
local Bots = require('bots')


function BattleRecorderServer:__init()
	print("Initializing BattleRecorderServer")
	self:RegisterVars()
	self:RegisterEvents()
end


function BattleRecorderServer:RegisterVars()
	self.m_IsPlaying = false
	self.m_Recordings = {}
	self.m_TimeStep = {}

	self.m_CurrentRecording = {}
end


function BattleRecorderServer:RegisterEvents()
	NetEvents:Subscribe('BattleRecorder:Play', self, self.OnPlay)
	NetEvents:Subscribe('BattleRecorder:StartRecording', self, self.OnStartRecording)
	NetEvents:Subscribe('BattleRecorder:Stop', self, self.OnStop)
	NetEvents:Subscribe('BattleRecorder:Clear', self, self.OnClear)
	Events:Subscribe('Bot:Update', self, self.OnBotUpdate)
	Events:Subscribe('UpdateManager:Update', self, self.OnUpdate)
end

function BattleRecorderServer:OnUpdate(dt, pass)
	if pass ~= UpdatePass.UpdatePass_PostFrame then
		return
	end
	local id = 1
	for playerName, recordingParams in pairs(self.m_CurrentRecording) do
		self:Record(recordingParams.player, id)
		id = id + 1
	end
end


function BattleRecorderServer:OnPlay(player)
	print("Playing " .. #self.m_Recordings .. " amount of records")
	print(#self.m_Recordings)
	for k,v in pairs(self.m_Recordings) do
		self:SpawnBot(k)
		self.m_TimeStep[k] = 0
	end
	self.m_IsPlaying = true
end

function BattleRecorderServer:OnStop(player)
	print("Stopping recording for player: " .. player.name)
	print("Adding recording of size: " .. #self.m_CurrentRecording[player.name].records)
	table.insert(self.m_Recordings, self.m_CurrentRecording[player.name])
	self.m_CurrentRecording[player.name] = nil
	self.m_IsPlaying = false
	Bots:destroyAllBots()
	self.m_TimeStep = {}
end

function BattleRecorderServer:OnClear(player)
	print("Clearing recordings")
	self.m_Recordings = {}
end

function BattleRecorderServer:OnStartRecording(player)
	print("Start to record player: " .. player.name)
	self.m_CurrentRecording[player.name] = {
		timestep = 0,
		transform = player.soldier.transform,
		player = player,
		records = {}
	}
	if(#self.m_Recordings > 0) then
		self:OnPlay()
	end
end

function BattleRecorderServer:Record(player, recordingId)
	if(player == nil) then
		print("No player")
		return
	end
	if player.soldier == nil then
		print("No soldier")
		return
	end
	player.input.flags = EntryInputFlag.AuthoritativeAiming
	local state = {
		levels = {},
		aim = {
			pitch = player.input.authoritativeAimingPitch,
			yaw = player.input.authoritativeAimingYaw
		}
	}
	for i in range(0,63,1) do
		state.levels[i] =  player.input:GetLevel(i)
	end
	table.insert(self.m_CurrentRecording[player.name].records, state)
end



function BattleRecorderServer:SpawnBot(index)
	playerName = "Bot"..tostring(index)
	print("Spawning bot: " .. playerName)
	local existingPlayer = PlayerManager:GetPlayerByName(playerName)
	local bot = nil
	if existingPlayer ~= nil then
		-- If a player with this name exists and it's not a bot then error out.
		if not Bots:isBot(existingPlayer) then
			return
		end
		Bots:destroyBot(bot)
	end
	-- Otherwise, create a new bot. This returns a new Player object.
	bot = Bots:createBot(playerName, 1, 1)
		-- Get the default MpSoldier blueprint and the US assault kit.
	local soldierBlueprint = ResourceManager:SearchForInstanceByGUID(Guid('261E43BF-259B-41D2-BF3B-9AE4DDA96AD2'))
	local soldierKit = ResourceManager:SearchForInstanceByGUID(Guid('A15EE431-88B8-4B35-B69A-985CEA934855'))

	-- Create the transform of where to spawn the bot at.
	local transform = self.m_Recordings[index].transform
	print("Spawning bot at transform: " .. tostring(transform))
	-- And then spawn the bot. This will create and return a new SoldierEntity object.
	Bots:spawnBot(bot, transform, CharacterPoseType.CharacterPoseType_Stand, soldierBlueprint, soldierKit, {})
	for k,level in pairs(self.m_Recordings[bot.id].records[1].levels) do
		bot.input:SetLevel(k, level)
	end
	bot.input.flags = EntryInputFlag.AuthoritativeAiming
	bot.input.authoritativeAimingPitch = self.m_Recordings[bot.id].records[1].aim.pitch
	bot.input.authoritativeAimingYaw = self.m_Recordings[bot.id].records[1].aim.yaw
end


function BattleRecorderServer:OnBotUpdate(bot, deltaTime)
	if(bot == nil or bot.soldier == nil) then
		return
	end
	if(not self.m_IsPlaying) then
		return
	end
	if(self.m_Recordings[bot.id] == nil) then
		print("Failed to find recording for " .. bot.id)
	else
		self.m_TimeStep[bot.id] = self.m_TimeStep[bot.id] + 1
		if(#self.m_Recordings[bot.id].records < self.m_TimeStep[bot.id] and self.m_Recordings[bot.id].records[self.m_TimeStep[bot.id]] == nil) then
			--print("Failed to find timestep: " .. self.m_TimeStep)
		else
			if(bot ~= nil and bot.id ~= nil) then
				local currentRecord = self.m_Recordings[bot.id].records[self.m_TimeStep[bot.id]]
				for k,level in pairs(currentRecord.levels) do
					bot.input:SetLevel(k, level)
				end
				bot.input.flags = EntryInputFlag.AuthoritativeAiming
				bot.input.authoritativeAimingPitch = currentRecord.aim.pitch
				bot.input.authoritativeAimingYaw = currentRecord.aim.yaw
			end
		end
	end
end

function range(from, to, step)
  step = step or 1
  return function(_, lastvalue)
    local nextvalue = lastvalue + step
    if step > 0 and nextvalue <= to or step < 0 and nextvalue >= to or
       step == 0
    then
      return nextvalue
    end
  end, nil, from - step
end



g_BattleRecorderServer = BattleRecorderServer()
