--[[
    ETHREOS LOADING SYSTEM & UI
    Path: SyntoriMS/Zephurix/DLC/Modules/
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Ссылка на твой список разрешенных версий
local VERSION_CHECK_URL = "https://raw.githubusercontent.com/mewix1337/ethereos/main/supportedversions.lua"
local OBFUSCATOR_URL = "https://your-obfuscator-api.com/crypt" -- Заглушка для обфускатора
local KEYWORD = "ethereosdllzephurixsyntorims"

-- Глобальные пути
local ROOT_PATH = "SyntoriMS/Zephurix/DLC/Modules/"
local RESOURCES_PATH = ROOT_PATH .. "Resources/"

-- Создание папок
local function ensureFolder(path)
    local current = ""
    for part in path:gmatch("[^/]+") do
        current = current .. part .. "/"
        if not isfolder(current) then makefolder(current) end
    end
end

ensureFolder(RESOURCES_PATH)

--------------------------------------------------------------------------------
-- UI CONSTRUCTION (Base)
--------------------------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "EthereosMenu"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 600, 0, 350)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0

local UICorner = Instance.new("UICorner", MainFrame)
local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(45, 45, 50)
UIStroke.Thickness = 1

-- Панели вкладок
local HomeTab = Instance.new("Frame", MainFrame)
HomeTab.Size = UDim2.new(1, 0, 1, -50)
HomeTab.BackgroundTransparency = 1
HomeTab.Visible = true

local ModulesTab = Instance.new("Frame", MainFrame)
ModulesTab.Size = UDim2.new(1, 0, 1, -50)
ModulesTab.BackgroundTransparency = 1
ModulesTab.Visible = false

--------------------------------------------------------------------------------
-- HOME PAGE ELEMENTS
--------------------------------------------------------------------------------

-- Левый блок (Embedded/Game Scripts)
local ScriptsList = Instance.new("ScrollingFrame", HomeTab)
ScriptsList.Size = UDim2.new(0, 180, 0, 250)
ScriptsList.Position = UDim2.new(0, 10, 0, 10)
ScriptsList.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
ScriptsList.BorderSizePixel = 0
ScriptsList.CanvasSize = UDim2.new(0, 0, 2, 0)

local ScriptsTitle = Instance.new("TextButton", HomeTab)
ScriptsTitle.Size = UDim2.new(0, 180, 0, 20)
ScriptsTitle.Position = UDim2.new(0, 10, 0, 5)
ScriptsTitle.Text = "Embedded Scripts"
ScriptsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
ScriptsTitle.BackgroundTransparency = 1
ScriptsTitle.Font = Enum.Font.SourceSansBold

-- Правый блок (Settings)
local SettingsBox = Instance.new("Frame", HomeTab)
SettingsBox.Size = UDim2.new(0, 380, 0, 180)
SettingsBox.Position = UDim2.new(0, 205, 0, 10)
SettingsBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)

local AddModuleInput = Instance.new("TextBox", HomeTab)
AddModuleInput.Size = UDim2.new(0, 250, 0, 30)
AddModuleInput.Position = UDim2.new(0, 335, 0, 200)
AddModuleInput.PlaceholderText = "write module URL"
AddModuleInput.Text = ""
AddModuleInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35)

local AddBtn = Instance.new("TextButton", HomeTab)
AddBtn.Size = UDim2.new(0, 120, 0, 30)
AddBtn.Position = UDim2.new(0, 205, 0, 200)
AddBtn.Text = "Add Module"
AddBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)

--------------------------------------------------------------------------------
-- MODULES PAGE ELEMENTS
--------------------------------------------------------------------------------

local CustomModulesList = Instance.new("ScrollingFrame", ModulesTab)
CustomModulesList.Size = UDim2.new(0, 180, 0, 280)
CustomModulesList.Position = UDim2.new(0, 10, 0, 10)
CustomModulesList.BackgroundColor3 = Color3.fromRGB(15, 15, 18)

local ModuleDisplay = Instance.new("ScrollingFrame", ModulesTab)
ModuleDisplay.Size = UDim2.new(0, 380, 0, 280)
ModuleDisplay.Position = UDim2.new(0, 205, 0, 10)
ModuleDisplay.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
local UIGrid = Instance.new("UIGridLayout", ModuleDisplay)
UIGrid.CellSize = UDim2.new(0, 175, 0, 60)

--------------------------------------------------------------------------------
-- BOTTOM NAVIGATION
--------------------------------------------------------------------------------

local Nav = Instance.new("Frame", MainFrame)
Nav.Size = UDim2.new(1, 0, 0, 40)
Nav.Position = UDim2.new(0, 0, 1, -40)
Nav.BackgroundTransparency = 1

local HomeBtn = Instance.new("TextButton", Nav)
HomeBtn.Size = UDim2.new(0, 40, 0, 40)
HomeBtn.Position = UDim2.new(0.4, 0, 0, 0)
HomeBtn.Text = "H"
HomeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local ModBtn = Instance.new("TextButton", Nav)
ModBtn.Size = UDim2.new(0, 40, 0, 40)
ModBtn.Position = UDim2.new(0.6, 0, 0, 0)
ModBtn.Text = "M"
ModBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local PageTitle = Instance.new("TextLabel", Nav)
PageTitle.Size = UDim2.new(0, 100, 1, 0)
PageTitle.Position = UDim2.new(0.5, -50, 0, 0)
PageTitle.Text = "Home"
PageTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PageTitle.BackgroundTransparency = 1

--------------------------------------------------------------------------------
-- LOGIC FUNCTIONS
--------------------------------------------------------------------------------

-- Проверка версии
local function isVersionSupported(ver)
    local success, list = pcall(function() return loadstring(game:HttpGet(VERSION_CHECK_URL))() end)
    if success and type(list) == "table" then
        for _, v in pairs(list) do if v == ver then return true end end
    end
    return false
end

-- Удаление модуля
local function deleteModule(pack, name)
    local path = ROOT_PATH .. pack .. "/" .. name .. "/" .. name .. ".lua"
    if isfile(path) then delfile(path) end
end

-- Отрисовка кнопок модуля (колонки 1 и 2)
local function renderButtons(mod)
    for _, child in pairs(ModuleDisplay:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    
    local sortedButtons = {}
    for id, data in pairs(mod.Buttons) do table.insert(sortedButtons, {id = id, data = data}) end
    table.sort(sortedButtons, function(a,b) return a.id < b.id end)

    for _, item in ipairs(sortedButtons) do
        local id = item.id
        local data = item.data
        
        local btnFrame = Instance.new("Frame", ModuleDisplay)
        btnFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        
        local title = Instance.new("TextLabel", btnFrame)
        title.Size = UDim2.new(1, -40, 0, 20)
        title.Text = data.name
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.BackgroundTransparency = 1
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", btnFrame)
        desc.Size = UDim2.new(1, -40, 0, 30)
        desc.Position = UDim2.new(0, 0, 0, 20)
        desc.Text = data.description
        desc.TextSize = 10
        desc.BackgroundTransparency = 1
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextWrapped = true

        local startBtn = Instance.new("TextButton", btnFrame)
        startBtn.Size = UDim2.new(0, 30, 0, 30)
        startBtn.Position = UDim2.new(1, -35, 0.5, -15)
        local icon = data.customStart or mod.customStart or "-"
        if #icon > 1 then 
            warn("Syntax Error: customStart too long!") 
            deleteModule(mod.ModulePack, mod.ModuleName)
            return
        end
        startBtn.Text = icon
        
        startBtn.MouseButton1Click:Connect(data.callback)
    end
end

-- Установка модуля
AddBtn.MouseButton1Click:Connect(function()
    local url = AddModuleInput.Text
    if url == "" then return end
    
    local code = game:HttpGet(url)
    local func = loadstring(code)
    local mod = func()
    
    if isVersionSupported(mod.ModuleSuppVer) then
        -- Логика обфускации (имитация)
        local finalCode = code -- Здесь должен быть запрос к OBFUSCATOR_URL
        
        local path = ROOT_PATH .. mod.ModulePack .. "/" .. mod.ModuleName .. "/"
        ensureFolder(path)
        writefile(path .. mod.ModuleName .. ".lua", finalCode)
        print("Installed!")
    else
        print("Error: Not supported version")
    end
end)

-- Переключение вкладок
HomeBtn.MouseButton1Click:Connect(function()
    HomeTab.Visible = true
    ModulesTab.Visible = false
    PageTitle.Text = "Home"
end)

ModBtn.MouseButton1Click:Connect(function()
    HomeTab.Visible = false
    ModulesTab.Visible = true
    PageTitle.Text = "Modules"
    
    -- Загрузка списка модулей из файлов
    for _, pack in pairs(listfiles(ROOT_PATH)) do
        if isfolder(pack) and not pack:find("Resources") then
            for _, modDir in pairs(listfiles(pack)) do
                local modFile = modDir .. "/" .. modDir:split("/")[#modDir:split("/")] .. ".lua"
                if isfile(modFile) then
                    local m = loadstring(readfile(modFile))()
                    local b = Instance.new("TextButton", CustomModulesList)
                    b.Size = UDim2.new(1, 0, 0, 30)
                    b.Text = m.ModulePack .. " | " .. m.ModuleName
                    b.MouseButton1Click:Connect(function() renderButtons(m) end)
                end
            end
        end
    end
end)

-- Проверка ключа в links.lua при старте
spawn(function()
    local lPath = RESOURCES_PATH .. "links.lua"
    if isfile(lPath) then
        if not readfile(lPath):find(KEYWORD) then
            warn("KEY NOT FOUND IN LINKS")
            -- Тут логика переустановки
        end
    end
end)