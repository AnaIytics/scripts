local defaultBoxProperties = {
	Thickness = 1;
	Color = Color3.new(1,1,1); 
	Outlined = true;
	Rounding = 4;
}

local defaultTextProperties = {
	Size = 18;
	Color = Color3.new(1, 1, 1);
	Outlined = true;
}

local playerList, connects = {}, {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Camera = game:GetService("Workspace").CurrentCamera

local StreamingEnabled = workspace.StreamingEnabled

local Rogue = game.GameId == 1087859240
local FightingGame = game.GameId == 1277659167
local Deepwoken = game.GameId == 1359573625

local Green, Red = Color3.new(0, 1, 0), Color3.new(1, 0, 0)

local lower, Vector2New, Vector3New, WTVPP, FindFirstChild, FindFirstChildOfClass, floor, C3fromRGB, C3New = string.lower, Vector2.new, Vector3.new, Camera.WorldToViewportPoint, game.FindFirstChild, game.FindFirstChildOfClass, math.floor, Color3.fromRGB, Color3.new

local Enabled = true

local function Destroy()
    Enabled = false; task.wait(0.05)

    for _,v in pairs(connects) do v:Disconnect() end

    for _,v in pairs(playerList) do v:Destroy() end

    table.clear(playerList)
    table.clear(connects)

    RunService:UnbindFromRenderStep("x_upESP")

    getgenv().Destroy = nil
end

getgenv().Destroy = Destroy

local function GetHeldTool(Character)
	return ((FindFirstChildOfClass(Character, "Tool") and FindFirstChildOfClass(Character, "Tool").Name) or "N/A")
end

local Player = {}; do
	Player.__index = Player

	function Player.new(player)
        if player == LocalPlayer then return end
        
		local self = {}; setmetatable(self, Player)

		self.Player = player
		self.Character = player.Character
        self.Humanoid = nil
        self.RootPart = nil
        self.HPP = nil
        self.Health = nil
        self.MaxHealth = nil
		self.Name = player.Name
		self.Team = player.Team ~= nil and player.Team.Name or nil
        self.Size = Vector2New()
		self.Drawings = {}
		self.Connects = {}
        self.Points = {}

		self.Connects["CharacterAdded"] = player.CharacterAdded:Connect(function(char) self:SetupCharacter(char) end)
		self.Connects["CharacterRemoving"] = player.CharacterRemoving:Connect(function() 
            for i,v in pairs({"Character", "RootPart", "Humanoid"}) do
				self[v] = nil
			end
		end)
		self.Connects["TeamChanged"] = player:GetPropertyChangedSignal("Team"):Connect(function()
			self.Team = player.Team ~= nil and player.Team.Name or nil
		end)

		self:SetupCharacter(player.Character)

		self.Index = table.insert(playerList, self)

		return self
	end

	function Player:SetupCharacter(Character)
		if Character then --// todo: make function to support other games (i.e. phantom forces, strucid, etc,.)
			self.Character = Character
			self.RootPart = Character:WaitForChild("HumanoidRootPart", 3)
            self.Humanoid = Character:WaitForChild("Humanoid", 3)
            self.Health = self.Humanoid.Health
            self.MaxHealth = self.Humanoid.MaxHealth
            self.HPP = self.Health / self.MaxHealth

            self.Connects["HealthChanged"] = self.Humanoid.HealthChanged:Connect(function()
                self:UpdateHealth()
            end)
			
			if StreamingEnabled and self.Character and not self.RootPart then
				self.Connects["ChildAdded"] = self.Character.ChildAdded:Connect(function(part)
					if part.Name == "HumanoidRootPart" and part:WaitForChild("RootAttachment", 3) and part:WaitForChild("RootJoint", 3) then
						self.RootPart = part
						self:SetupESP()
					end
				end)
			end

			if self.RootPart then
				self:SetupESP()
			end
		end
	end

	function Player:SetupESP()
		--// create points
		local topLeftBoxPoint = PointInstance.new(self.RootPart, CFrame.new(-2, 2.5, 0))
		local bottomLeftBoxPoint = PointInstance.new(self.RootPart, CFrame.new(-2, -3, 0))
		local bottomRightBoxPoint = PointInstance.new(self.RootPart, CFrame.new(2, -3, 0))
		
		local middleHealthPoint = PointInstance.new(self.RootPart, CFrame.new(-2, 2.5, 0))
		local topLeftHealthPoint = PointOffset.new(topLeftBoxPoint, -4, 0)
		local bottomRightHealthPoint = PointOffset.new(bottomLeftBoxPoint, -3, 0)

		local textPoint = PointInstance.new(self.RootPart, CFrame.new(0, -3, 0))

		for i,v in pairs({topLeftBoxPoint, bottomRightBoxPoint, textPoint, bottomLeftBoxPoint}) do v.RotationType = CFrameRotationType.CameraRelative end
		--// create drawings
		local PrimaryBox = RectDynamic.new(topLeftBoxPoint, bottomRightBoxPoint); for i,v in pairs(defaultBoxProperties) do PrimaryBox[i] = v end
		PrimaryBox.Visible = false

		local PrimaryText = TextDynamic.new(textPoint); for i,v in pairs(defaultTextProperties) do PrimaryText[i] = v end
		PrimaryText.Text = self.Name
		PrimaryText.YAlignment = YAlignment.Bottom
        PrimaryText.Visible = false
        
		local HealthBox = RectDynamic.new(topLeftHealthPoint, bottomRightHealthPoint); for i,v in pairs(defaultBoxProperties) do HealthBox[i] = v end
		HealthBox.Filled = true
		HealthBox.Color = Green
        HealthBox.Rounding = 0
        HealthBox.Visible = false
--[[   
        local HealthBoxBorder = RectDynamic.new(PointOffset.new(topLeftBoxPoint, -6, -1), PointOffset.new(topLeftBoxPoint, -2, 1))
        HealthBoxBorder
]]      
		--// add to table for updates
		self.Drawings.Box = PrimaryBox
		self.Drawings.Text = PrimaryText
		self.Drawings.HealthBar = HealthBox

        self.Points.TopLeftBox = topLeftBoxPoint
        self.Points.BottomLeftBox = bottomLeftBoxPoint
        self.Points.BottomRightBox = bottomRightBoxPoint

        self.Points.MiddleHealth = middleHealthPoint 
        self.Points.TopLeftHealth = topLeftHealthPoint
        self.Points.BottomRightHealth = bottomRightHealthPoint

        self:UpdateHealth()
	end

    function Player:UpdateHealth()
    	local topLeftHealthPoint = PointInstance.new(self.RootPart, CFrame.new(-2, (self.HPP * 5.5) - 3, 0))

        self.Points.TopLeftHealth = PointOffset.new(topLeftHealthPoint, -4, 0)
        self.Drawings.HealthBar.Position = self.Points.TopLeftHealth
    end

	function Player:Update()
		if not self.Player then self:Destroy() return end --// if the player is gone then dont update

		local Box = self.Drawings.Box
		local Text = self.Drawings.Text
		local HealthBar = self.Drawings.HealthBar
        
		if not Box or not Text or not self.Character or not self.RootPart or not self.Humanoid then return end --// if no box or text or character then dont update
		
		local Humanoid = self.Humanoid
		local Health, MaxHealth = Humanoid.Health, Humanoid.MaxHealth
        self.Health = Health
        self.MaxHealth = MaxHealth

		local HPP = math.clamp(Health / MaxHealth, 0, 1)
        self.HPP = HPP

        for i,v in pairs({Box, Text, HealthBar}) do v.Visible = Enabled end 

		--// get display name | todo: function for getting display name to support other games easier?
		local InGameName;
        if Deepwoken and self.Humanoid and self.Humanoid.DisplayName then 
            local displayName = self.Humanoid.DisplayName:split("\n")[1]
            InGameName = displayName
        end

		--// update text
		Text.Text = self.Name..((Deepwoken and InGameName) and " ["..InGameName.."]" or "").."\n["..floor((Camera.CFrame.p - self.RootPart.Position).Magnitude).."] ["..floor(self.Humanoid.Health).."/"..floor(self.Humanoid.MaxHealth).."]\n["..GetHeldTool(self.Character).."]"
	
		--// update health bar
		HealthBar.Color = Green:Lerp(Red, math.clamp(1 - HPP, 0, 1)) --// thx ic3 

        --print(self.Points.TopLeftBox.ScreenPos, self.Points.BottomRightBox.ScreenPos)
        self.Size = self.Points.BottomRightBox.ScreenPos - self.Points.TopLeftBox.ScreenPos
	end

	function Player:Destroy()
        for i,v in pairs(self.Connects) do v:Disconnect() end

        for i,v in pairs(self.Drawings) do v.Visible = false end

        self:Update()

        table.clear(self.Drawings)
		table.clear(self.Connects)

        for i,v in pairs(self) do
            if typeof(v) == "table" then
                table.clear(v)
            elseif typeof(v) == "RBXScriptSignal" then
                v:Disconnect()
            end
            self[i] = nil
        end

        table.remove(playerList, self.Index)

        self = nil
	end
end

for _,v in pairs(Players:GetPlayers()) do task.spawn(Player.new, v) end

table.insert(connects, Players.PlayerAdded:Connect(Player.new))
table.insert(connects, game:GetService("UserInputService").InputBegan:Connect(function(inputObject, gp)
    if gp then return end
    if inputObject.KeyCode == Enum.KeyCode.F3 then
        Enabled = not Enabled
    end
end))

RunService:BindToRenderStep("x_upESP", 200, function()
    for i,v in pairs(playerList) do
		v:Update()
	end
end)