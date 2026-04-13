local UI = loadstring(game:HttpGet("https://weakez.pages.dev/$/library/protogen.lua"))()

local Window = UI.Create({
    Title   = "Prototype Menu",
    Keybind = "RightShift" 
})

local Tab1 = Window:TabCreate({
    Title       = "Active",
    OpenOnStart = true
})

local Tab2 = Window:TabCreate({
    Title       = "Settings",
    OpenOnStart = false
})

local Sec = Tab1:SectionCreate({
    Title_1 = "Not Active Sec",
    Title_2 = "Active Sec"
})

local MyLabel = Sec:AddLabel({
    Word    = "TextLabel",
    Content = "True",
    Pane    = "Not Active Sec"
})

local MyToggle = Sec:AddToggle({
    Title    = "Toggle = Off",
    Default  = false,
    Pane     = "Not Active Sec",
    Callback = function(state)
        print("Toggle:", state)
    end
})

local MyToggleOn = Sec:AddToggle({
    Title    = "Toggle = On",
    Default  = true,
    Pane     = "Not Active Sec",
    Callback = function(state)
        print("Toggle2:", state)
    end
})

local MySlider = Sec:AddSlider({
    Title    = "SliderLabel (title)",
    Min      = 0,
    Max      = 100,
    Default  = 42,
    Pane     = "Not Active Sec",
    Callback = function(v)
        print("Slider:", v)
    end
})

local MyTB = Sec:AddTextBox({
    Title       = "TextBoxTitle",
    Placeholder = "TextHolder",
    Pane        = "Not Active Sec",
    Callback    = function(txt)
        print("TextBox:", txt)
    end
})

local MyCP = Sec:AddColorPicker({
    Title    = "ColorPicker",
    Default  = Color3.fromRGB(255, 0, 0),
    Pane     = "Active Sec",
    Callback = function(color)
        print("Color:", color)
    end
})

local MyDD = Sec:AddDropdown({
    Title    = "DropDown",
    Options  = { "SelectedOption", "Option 2", "Option 3", "Option 4", "Option 5", "Option 6" },
    Default  = "SelectedOption",
    Pane     = "Active Sec",
    Callback = function(val)
        print("Dropdown:", val)
    end
})

local Sec2 = Tab2:SectionCreate({
    Title_1 = "General"
})

Sec2:AddToggle({
    Title    = "Fly",
    Default  = false,
    Callback = function(v)
        print("Fly:", v)
    end
})