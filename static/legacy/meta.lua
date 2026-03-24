-- [[ static/legacy/meta ]]
return function()
    local MetaData = {
        -- Основная инфа
        Name = "jessi Legacy",
        Version = "v2.1.56 beta",
        Author = "hux9z",
        
        -- Ссылки (если хранишь их отдельно)
        Discord = "https://discord.gg/yourlink",
        
        -- Коллбэки для обработки ошибок в лоадере
        mi_down = function()
            warn("sUWO || [CRITICAL] Map Host is Down!")
            -- Тут можно вызывать системное уведомление Roblox
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Critical Error",
                Text = "Script Map (SM) could not be loaded.",
                Duration = 10
            })
        end,
        
        logic_down = function()
            warn("sUWO || [CRITICAL] Logic/UI Host is Down!")
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Logic Error",
                Text = "Functions or UI module failed to initialize.",
                Duration = 10
            })
        end
    }
    
    return MetaData
end