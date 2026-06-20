-- LocalScript
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework

local NotificationController = Flamework.resolveDependency(
	'@easy-games/game-core:client/controllers/notification-controller@NotificationController'
)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CommandBarGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Parent = screenGui
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Size = UDim2.new(0, 1040, 0, 56)
frame.Position = UDim2.new(0.5, -520, 0, 10)

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

local textBox = Instance.new("TextBox")
textBox.Parent = frame
textBox.Size = UDim2.new(1, 0, 1, 0)
textBox.Position = UDim2.new(0, 0, 0, 0)
textBox.BackgroundTransparency = 1
textBox.Text = ""
textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
textBox.Font = Enum.Font.SourceSans
textBox.TextSize = 24
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.PlaceholderText = ""
textBox.ClearTextOnFocus = false

-- Notification system (slides in from top-right)
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "NotificationGui"
notifGui.ResetOnSpawn = false
notifGui.Parent = playerGui

local notifLabel = Instance.new("TextLabel")
notifLabel.Name = "Notification"
notifLabel.Parent = notifGui
notifLabel.AnchorPoint = Vector2.new(1, 0)
notifLabel.Size = UDim2.new(0, 320, 0, 50)
notifLabel.Position = UDim2.new(1, 340, 0, 10)
notifLabel.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
notifLabel.BackgroundTransparency = 0.1
notifLabel.BorderSizePixel = 0
notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifLabel.Font = Enum.Font.SourceSansBold
notifLabel.TextSize = 18
notifLabel.TextWrapped = true
notifLabel.Text = ""
notifLabel.Visible = false
notifLabel.ZIndex = 10

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 10)
notifCorner.Parent = notifLabel

local notifInInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local notifOutInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local activeNotifThread = nil

local function showError(message)
	notifLabel.Text = message
	notifLabel.Visible = true
	notifLabel.Position = UDim2.new(1, 340, 0, 10)

	local tweenIn = TweenService:Create(notifLabel, notifInInfo, { Position = UDim2.new(1, -10, 0, 10) })
	tweenIn:Play()

	if activeNotifThread then
		task.cancel(activeNotifThread)
	end

	activeNotifThread = task.spawn(function()
		task.wait(3)
		local tweenOut = TweenService:Create(notifLabel, notifOutInfo, { Position = UDim2.new(1, 340, 0, 10) })
		tweenOut:Play()
		tweenOut.Completed:Wait()
		notifLabel.Visible = false
	end)
end

-- Config: key to open the command bar
local openKeyCode = Enum.KeyCode.Equals

local function toggleGui()
	screenGui.Enabled = not screenGui.Enabled
	if screenGui.Enabled then
		pcall(function() textBox:CaptureFocus() end)
		textBox.Text = ""
	end
end

-- Toggle on key (only when GUI is closed)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if screenGui.Enabled then return end

	if input.KeyCode == openKeyCode then
		toggleGui()
	end
end)

-- Command handling
local validCommands = {
	changekeybind = true,
	announce = true,
}

local function joinRest(parts, startIndex)
	local out = {}
	for i = startIndex, #parts do
		out[#out + 1] = parts[i]
	end
	return table.concat(out, " ")
end

local function handleCommand(cmd)
	if cmd == "" then return end

	local parts = string.split(cmd, " ")
	local commandName = parts[1]

	if not validCommands[commandName] then
		showError("Unknown command: " .. tostring(commandName))
		return
	end

	if commandName == "announce" then
		local message = joinRest(parts, 2)
		if message == "" then
			showError("Usage: announce <message>")
			return
		end

				local fullMessage = '<font color="rgb(75, 0, 130)"><b>[THEMAGICPISTON]</b></font> : <b>' .. message .. '</b>'

		pcall(function()
			NotificationController:sendInfoNotification({
				message = fullMessage
			})
		end)

	elseif commandName == "changekeybind" then
		if not parts[2] or parts[2] == "" then
			showError("Usage: changekeybind <key>")
			return
		end

		local keyName = parts[2]

		local aliases = {
			["="] = "Equals",
			["minus"] = "Minus",
			["plus"] = "Equals",
		}

		keyName = aliases[keyName] or keyName

		local ok, keyEnum = pcall(function()
			return Enum.KeyCode[keyName]
		end)

		if ok and keyEnum then
			openKeyCode = keyEnum
		else
			showError("Invalid key: " .. tostring(keyName))
		end
	end
end

textBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local cmd = textBox.Text or ""
		screenGui.Enabled = false
		textBox.Text = ""
		handleCommand(cmd)
	end
end)

-- LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local lplr = Players.LocalPlayer
local function Color3ToHex(r, g, b)
	return string.lower(string.format("#%02X%02X%02X", r, g, b))
end

-- ===== Settings =====
local TAG_TEXT = "THEMAGICPISTON"

-- Dark purple (you can tweak these HSV values if you want a slightly different purple)
local ColorHSV = { Hue = 0.78, Sat = 0.60, Val = 0.45 }

-- =====================

local old, old2
local tagRenderConn
local tagGuiConn

local TAG = { Value = TAG_TEXT }
local Color = {
	Hue = ColorHSV.Hue,
	Sat = ColorHSV.Sat,
	Value = ColorHSV.Val
}

local function CompleteTagEffect()
	if not lplr:FindFirstChild("Tags") then return end
	local tagObj = lplr.Tags:FindFirstChild("0")
	if not tagObj then return end

	if not old then
		old = tagObj.Value
		old2 = tagObj:GetAttribute("Text")
	end

	local color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
	local R = math.floor(color.R * 255)
	local G = math.floor(color.G * 255)
	local B = math.floor(color.B * 255)

	tagObj.Value = string.format("<font color='rgb(%d,%d,%d)'>[%s]</font>", R, G, B, TAG.Value)
	tagObj:SetAttribute("Text", TAG.Value)
	lplr:SetAttribute("ClanTag", TAG.Value)

	if tagRenderConn then
		tagRenderConn:Disconnect()
		tagRenderConn = nil
	end
	if tagGuiConn then
		tagGuiConn:Disconnect()
		tagGuiConn = nil
	end

	tagGuiConn = lplr.PlayerGui.ChildAdded:Connect(function(child)
		if child.Name ~= "TabListScreenGui" or not child:IsA("ScreenGui") then return end

		tagRenderConn = RunService.RenderStepped:Connect(function()
			local nameToFind = (lplr.DisplayName == "" or lplr.DisplayName == lplr.Name) and lplr.Name or lplr.DisplayName

			for _, v in ipairs(child:GetDescendants()) do
				if v:IsA("TextLabel") then
					if string.find(string.lower(v.Text), string.lower(nameToFind)) then
						v.Text = string.format(
							'<font transparency="0.3" color="%s">[%s]</font> %s',
							Color3ToHex(R, G, B),
							TAG.Value,
							nameToFind
						)
					end
				end
			end
		end)
	end)
end

local function RemoveTagEffect()
	if tagRenderConn then
		tagRenderConn:Disconnect()
		tagRenderConn = nil
	end
	if tagGuiConn then
		tagGuiConn:Disconnect()
		tagGuiConn = nil
	end

	if lplr:FindFirstChild("Tags") then
		local tagObj = lplr.Tags:FindFirstChild("0")
		if tagObj then
			if old then
				tagObj.Value = old
			end
			if old2 then
				tagObj:SetAttribute("Text", old2)
			end
		end
	end

	if lplr:GetAttribute("ClanTag") then
		lplr:SetAttribute("ClanTag", old)
	end

	old = nil
	old2 = nil
end

-- Apply (wait for Tags to exist)
if lplr:FindFirstChild("Tags") then
	CompleteTagEffect()
else
	lplr.ChildAdded:Connect(function(child)
		if child.Name == "Tags" then
			CompleteTagEffect()
		end
	end)
end

-- Optional: if you ever want it removed, call RemoveTagEffect()
