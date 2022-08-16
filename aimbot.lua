getgenv().Aimbot = true
getgenv().AimPart = "Head"
getgenv().Key = "MouseButton2"
getgenv().TeamCheck = true
getgenv().WallCheck = true
getgenv().Smoothing = 2
getgenv().FOVEnabled = false
getgenv().FOVRadius = 360
getgenv().UseFOV = false

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
Player.CharacterAdded:Connect(function(NewCharacter)
    Character = NewCharacter
end)
local Mouse = Player:GetMouse()

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Camera = game:GetService("Workspace").CurrentCamera

local Holding = false
local AimbotConn
local MouseConns = {}

local AimParts = {"Head","Torso"}
local Keys = {"MouseButton1","MouseButton2"}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = FOVRadius * 2
FOVCircle.Filled = false
FOVCircle.Visible = FOVEnabled
FOVCircle.Transparency = 0.7
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(255,255,255)

-- Aimbot Functions

local function GetClosestPlayer()
    local MaxDist = (UseFOV and FOVRadius * 2) or math.huge
    local Target = nil

    task.spawn(function()
        wait(20)
        MaxDist = (UseFOV and FOVRadius * 2) or math.huge
    end)

    for _, v in next, Players:GetPlayers() do
        if v.Name ~= Player.Name then
            if (TeamCheck and v.Team ~= Player.Team) or (not TeamCheck) then
                if v.Character then
                    if v.Character:FindFirstChild("HumanoidRootPart") then
                        if v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("Humanoid").Health ~= 0 then
                            local ScreenPoint, Visible = Camera:WorldToScreenPoint(v.Character:WaitForChild("HumanoidRootPart").Position)
                            local Dist = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude

                            if Visible and Dist < MaxDist then
                                if WallCheck then
                                    local Ignore = {}
                                    for _,Plr in pairs(Players:GetPlayers()) do
                                        if Plr.Character then
                                            table.insert(Ignore,Plr.Character)
                                        end
                                    end

                                    local RayStart = Character:WaitForChild("Head").Position
                                    local RayEnd = v.Character:WaitForChild("Head").Position
                                    local RayDir = RayEnd - RayStart
                                    local RayParams = RaycastParams.new()
                                    RayParams.FilterDescendantsInstances = Ignore
                                    RayParams.FilterType = Enum.RaycastFilterType.Blacklist
                                    RayParams.IgnoreWater = true

                                    local RayResult = workspace:Raycast(RayStart, RayDir, RayParams)

                                    if not RayResult then
                                        Target = v
                                        MaxDist = Dist
                                    end
                                else
                                    Target = v
                                    MaxDist = Dist
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return Target
end

-- GUI Variables

getgenv().AimbotWindow = RenderWindow.new("Aimbot")
AimbotWindow.Visible = true
AimbotWindow.VisibilityOverride = true
local Settings = {}
local Connections = {}
local Objects = {}

local RunService = game:GetService('RunService')

function NewElement(Window,Props)
    local Element = Window[Props.Type](Window)

    Element.Label = type(Props.Title) == 'string' and Props.Title or 'No title'

    if type(Props.Callback) == 'function' then
        Element.OnUpdated:Connect(Props.Callback)
    end

    if Props["Properties"] then
        for Property, Value in next, Props.Properties do
            Element[Property] = Value;
        end
    end

    Objects[Props.Title] = Element
end

-- GUI Objects

NewElement(AimbotWindow,{
    Title = 'Close Window';
    Type = 'Button';

    Callback = function()
        getgenv().AimbotWindow = nil
    end
})

NewElement(AimbotWindow,{ 
    Title = 'Smoothing';
    Type = 'IntSlider'; 

    Properties = {
        Min = 0;
        Max = 20;
        Value = Smoothing;
    };

    Callback = function(value)
        Smoothing = value
    end
})

NewElement(AimbotWindow,{
    Title = 'Aim Part';
    Type = 'Combo';

    Properties = {
        SelectedItem = 1;
        Items = AimParts;
    };

    Callback = function(value)
        AimPart = AimParts[value]
    end
})

NewElement(AimbotWindow,{
    Title = 'Lock Key';
    Type = 'Combo';

    Properties = {
        SelectedItem = 2;
        Items = Keys;
    };

    Callback = function(value)
        Key = Keys[value]
    end
})

local AimbotSameLine = AimbotWindow:SameLine()

NewElement(AimbotSameLine,{
    Title = 'Team Check';
    Type = 'CheckBox';

    Properties = {
        Value = TeamCheck;
    };

    Callback = function(value)
        TeamCheck = value
    end
})

NewElement(AimbotSameLine,{
    Title = 'Wall Check';
    Type = 'CheckBox';

    Properties = {
        Value = WallCheck;
    };

    Callback = function(value)
        WallCheck = value
    end
})

NewElement(AimbotSameLine,{
    Title = 'Toggle Aimbot';
    Type = 'CheckBox';

    Properties = {
        Value = false;
    };

    Callback = function(value)
        Aimbot = value
        if value then
            MouseConns.Start = UserInputService.InputBegan:Connect(function(Input)
                InputType = (Key == "MouseButton2" and Enum.UserInputType.MouseButton2) or (Key == "MouseButton1" and Enum.UserInputType.MouseButton1)
                if Input.UserInputType == InputType then
                    Holding = true
                end
            end)

            MouseConns.End = UserInputService.InputEnded:Connect(function(Input)
                InputType = (Key == "MouseButton2" and Enum.UserInputType.MouseButton2) or (Key == "MouseButton1" and Enum.UserInputType.MouseButton1)
                if Input.UserInputType == InputType then
                    Holding = false
                end
            end)

            AimbotConn = RunService.RenderStepped:Connect(function()
                if Holding then
                    local ClosestPlayer = GetClosestPlayer()
                    if ClosestPlayer and ClosestPlayer.Character then
                        local AimAt = (AimPart == "Head" and "Head") or (AimPart == "Torso" and ClosestPlayer.Character:FindFirstChild("Torso") and "Torso") or (AimPart == "Torso" and "UpperTorso") or ""
                        if AimAt ~= "" then
                            local AimObj = ClosestPlayer.Character[AimAt]
                            local ScreenPos, Visible = Camera:WorldToViewportPoint(AimObj.Position)
                            if ScreenPos and Visible then
                                local MouseLocation = UserInputService:GetMouseLocation()
                                mousemoverel(((ScreenPos.X - MouseLocation.X) / Smoothing), ((ScreenPos.Y - MouseLocation.Y) / Smoothing))
                            end
                        end
                    end
                end
            end)
        else
            MouseConns.Start:Disconnect()
            MouseConns.End:Disconnect()
            AimbotConn:Disconnect()
        end
    end
})

NewElement(AimbotWindow,{ 
    Title = 'FOV';
    Type = 'IntSlider'; 

    Properties = {
        Min = 0;
        Max = 360;
        Value = FOVRadius;
    };

    Callback = function(value)
        FOVRadius = value
        FOVCircle.Radius = value * 2
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
})

local FOVSameline = AimbotWindow:SameLine()

NewElement(FOVSameline,{
    Title = 'Use FOV';
    Type = 'CheckBox';

    Properties = {
        Value = UseFOV;
    };

    Callback = function(value)
        UseFOV = value
    end
})

NewElement(FOVSameline,{
    Title = 'Toggle FOV Circle';
    Type = 'CheckBox';

    Properties = {
        Value = FOVEnabled;
    };

    Callback = function(value)
        FOVEnabled = value
        FOVCircle.Visible = value
    end
})
