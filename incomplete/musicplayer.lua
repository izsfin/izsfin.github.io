local CoreGui = game:GetService("CoreGui")
 local TweenService = game:GetService("TweenService")
  local RunService = game:GetService("RunService")
   local UserInputService = game:GetService("UserInputService")
    local SoundService = game:GetService("SoundService")

local Playlist = {
 {ID = "1837879011", Name = "Track 1"},
  {ID = "1836371371", Name = "Track 2"},
   {ID = "1843404009", Name = "Track 3"},
}
local CurrentTrack = 1

local Sound = SoundService:FindFirstChild("hux9z_Audio") or Instance.new("Sound", SoundService)
Sound.Name = "hux9z_Audio"; Sound.Looped = false; Sound.Volume = 0.5

for _, v in pairs(CoreGui:GetChildren()) do if v.Name:match("MusicPlayer") then v:Destroy() end end
local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = "MP_ezz"; ScreenGui.IgnoreGuiInset = true

local function ani(obj, info, goal)
 return TweenService:Create(obj, TweenInfo.new(info, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), goal)
end

local Mini = Instance.new("Frame", ScreenGui)
 Mini.Name = "MiniMenu"; Mini.AnchorPoint = Vector2.new(0.5, 0); Mini.Position = UDim2.new(0.5, 0, 0, 15)
  Mini.Size = UDim2.new(0, 150, 0, 28); Mini.BackgroundColor3 = Color3.fromRGB(30, 30, 30); Mini.BackgroundTransparency = 0.1
   Instance.new("UICorner", Mini).CornerRadius = UDim.new(0, 8)

local MiniTitle = Instance.new("TextLabel", Mini); MiniTitle.Size = UDim2.new(1, -10, 1, 0); MiniTitle.Position = UDim2.new(0, 10, 0, 0)
 MiniTitle.Font, MiniTitle.TextColor3, MiniTitle.TextSize, MiniTitle.BackgroundTransparency = "GothamBold", Color3.new(1,1,1), 11, 1

local Main = Instance.new("CanvasGroup", ScreenGui)
 Main.Name = "MainFrame"; Main.AnchorPoint = Vector2.new(0.5, 0); Main.Position = UDim2.new(0.5, 0, 0, 15)
  Main.Size = UDim2.new(0, 150, 0, 28); Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15); Main.BackgroundTransparency = 0.05
   Main.GroupTransparency = 1; Main.Visible = false; Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Content = Instance.new("Frame", Main)
 Content.Size = UDim2.new(1, 0, 1, 0); Content.BackgroundTransparency = 1; Content.Visible = false

local Title = Instance.new("TextLabel", Content); Title.Position = UDim2.new(0, 105, 0, 25); Title.Size = UDim2.new(0, 200, 0, 30)
 Title.Font, Title.TextSize, Title.TextColor3, Title.BackgroundTransparency = "GothamBold", 22, Color3.new(1,1,1), 1; Title.TextXAlignment = "Left"

local VolTrack = Instance.new("Frame", Content); VolTrack.Size, VolTrack.Position = UDim2.new(0, 4, 0, 80), UDim2.new(1, -30, 0, 25)
 VolTrack.BackgroundColor3 = Color3.fromRGB(45,45,45); Instance.new("UICorner", VolTrack)
local VolFill = Instance.new("Frame", VolTrack); VolFill.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", VolFill)

local VolTxt = Instance.new("TextLabel", Content); VolTxt.Position = UDim2.new(1, -45, 0, 110); VolTxt.Size = UDim2.new(0, 35, 0, 15)
 VolTxt.Font, VolTxt.TextSize, VolTxt.TextColor3, VolTxt.BackgroundTransparency = "Gotham", 11, Color3.new(0.7,0.7,0.7), 1

local function setVol(val)
 local v = math.clamp(val, 0, 1); Sound.Volume = v
  VolFill.Size = UDim2.new(1,0,v,0); VolFill.Position = UDim2.new(0,0,1-v,0); VolTxt.Text = math.floor(v*100).."%"
end
setVol(Sound.Volume)

local TaskbarFrame = Instance.new("Frame", Content); TaskbarFrame.Size, TaskbarFrame.Position = UDim2.new(0, 410, 0, 40), UDim2.new(0.5, -205, 0, 125)
TaskbarFrame.BackgroundColor3, TaskbarFrame.BackgroundTransparency = Color3.new(0,0,0), 0.7; Instance.new("UICorner", TaskbarFrame).CornerRadius = UDim.new(0, 10)

local TimeL = Instance.new("TextLabel", TaskbarFrame); TimeL.Position = UDim2.new(0, 10, 0, 0); TimeL.Text = "00:00"
local TimeR = Instance.new("TextLabel", TaskbarFrame); TimeR.Position = UDim2.new(1, -50, 0, 0); TimeR.Text = "00:00"
for _, t in pairs({TimeL, TimeR}) do t.Size, t.TextColor3, t.BackgroundTransparency, t.TextSize, t.Font = UDim2.new(0, 40, 1, 0), Color3.new(0.8,0.8,0.8), 1, 12, "Gotham" end

local Bar = Instance.new("TextButton", TaskbarFrame); Bar.Text = ""; Bar.Size, Bar.Position = UDim2.new(0, 280, 0, 6), UDim2.new(0.5, -140, 0.5, -3)
Bar.BackgroundColor3, Bar.AutoButtonColor = Color3.fromRGB(60,60,60), false; Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)
local Fill = Instance.new("Frame", Bar); Fill.Size, Fill.BackgroundColor3 = UDim2.new(0,0,1,0), Color3.new(1,1,1); Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

local Nav = Instance.new("Frame", Content); Nav.Size = UDim2.new(0, 100, 0, 20); Nav.Position = UDim2.new(0.5, -50, 0, 168); Nav.BackgroundTransparency = 1
local PrevBtn = Instance.new("TextButton", Nav); PrevBtn.Text = "<"; PrevBtn.Size = UDim2.new(0, 30, 1, 0); PrevBtn.Position = UDim2.new(0, 15, 0, 0)
local NextBtn = Instance.new("TextButton", Nav); NextBtn.Text = ">"; NextBtn.Size = UDim2.new(0, 30, 1, 0); NextBtn.Position = UDim2.new(1, -45, 0, 0)
for _, b in pairs({PrevBtn, NextBtn}) do b.Font, b.TextSize, b.TextColor3, b.BackgroundTransparency = "GothamBold", 14, Color3.new(1,1,1), 1 end

local function Load(num)
 CurrentTrack = (num - 1) % #Playlist + 1
 Sound.SoundId = "rbxassetid://"..Playlist[CurrentTrack].ID
 Sound:Play(); Title.Text = Playlist[CurrentTrack].Name; MiniTitle.Text = Playlist[CurrentTrack].Name
end

NextBtn.MouseButton1Click:Connect(function() Load(CurrentTrack + 1) end)
PrevBtn.MouseButton1Click:Connect(function() Load(CurrentTrack - 1) end)

local function toggle(open)
 if open then
  Main.Visible = true; Mini.Visible = false
  ani(Main, 1, {Size = UDim2.new(0, 450, 0, 200), GroupTransparency = 0}):Play()
  task.delay(0.2, function() Content.Visible = true end)
 else
  Content.Visible = false
 local t = ani(Main, 1, {Size = UDim2.new(0, 150, 0, 28), GroupTransparency = 1}); t:Play()
  t.Completed:Connect(function() if Main.GroupTransparency >= 0.9 then Main.Visible = false; Mini.Visible = true end end)
 end
end

Bar.MouseButton1Click:Connect(function()
 local mouseX = UserInputService:GetMouseLocation().X
  local relative = math.clamp((mouseX - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
 if Sound.TimeLength > 0 then Sound.TimePosition = Sound.TimeLength * relative end
end)

local vDrag = false
VolTrack.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then vDrag = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then vDrag = false end end)

RunService.RenderStepped:Connect(function()
 if vDrag then
  local mY = UserInputService:GetMouseLocation().Y - 36
  setVol(1 - math.clamp((mY - VolTrack.AbsolutePosition.Y) / VolTrack.AbsoluteSize.Y, 0, 1))
end
 if Sound.TimeLength > 0 then
  Fill.Size = UDim2.new(Sound.TimePosition / Sound.TimeLength, 0, 1, 0)
  TimeL.Text = string.format("%02d:%02d", math.floor(Sound.TimePosition/60), Sound.TimePosition%60)
  TimeR.Text = string.format("%02d:%02d", math.floor(Sound.TimeLength/60), Sound.TimeLength%60)
 end
end)

Mini.MouseEnter:Connect(function() toggle(true) end)
Main.MouseLeave:Connect(function() toggle(false) end)
Load(1)