return function(sizeX, sizeY, sizeText, text)
	local WtrMark = Instance.new("ScreenGui", game:GetService("CoreGui"))
	local Txt = Instance.new("TextLabel")

	Txt.Parent = WtrMark
	Txt.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
	Txt.BorderColor3 = Color3.fromRGB(255, 0, 0)
	Txt.BorderSizePixel = 2
	Txt.Position = UDim2.new(0.0169765502, 0, 0.891549289, 0)
	Txt.Size = UDim2.new(0, sizeX, 0, sizeY)
	Txt.Font = Enum.Font.Ubuntu
	Txt.Text = text
	Txt.TextColor3 = Color3.fromRGB(255, 255, 255)
	Txt.TextSize = sizeText
end