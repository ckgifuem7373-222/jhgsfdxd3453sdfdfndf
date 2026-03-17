local HttpService = game:GetService("HttpService")
local FileName = "ultra_bot_brain.json"

-- Конфигурация
local Memory = {["кто ты"] = {"Я автономный ИИ v5.0 с доступом к сети."}}
local Blacklist = {"дурак", "скам", "чит"}
local AutoChat = false
local WebSearchEnabled = true

-- Функция загрузки/сохранения
local function save() writefile(FileName, HttpService:JSONEncode(Memory)) end
if isfile(FileName) then 
    local s, d = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
    if s then Memory = d end
end

-- ВЕБ-ПОИСК (Используем DuckDuckGo API через Proxy для Roblox)
local function askWeb(query)
    local url = "https://api.duckduckgo.com" .. HttpService:UrlEncode(query) .. "&format=json&no_html=1&skip_disambig=1"
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success then
        local data = HttpService:JSONDecode(response)
        if data.AbstractText and data.AbstractText ~= "" then
            return data.AbstractText
        end
    end
    return nil
end

-- GUI СТРУКТУРА
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 350, 0, 500)
Main.Position = UDim2.new(0.5, -175, 0.5, -250)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Instance.new("UICorner", Main)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "🌐 ULTRA AI ENGINE v5.0"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Instance.new("UICorner", Title)

local Stats = Instance.new("TextLabel", Main)
Stats.Size = UDim2.new(1, 0, 0, 30)
Stats.Position = UDim2.new(0, 0, 0, 50)
Stats.TextColor3 = Color3.fromRGB(0, 200, 255)
Stats.BackgroundTransparency = 1
Stats.Text = "Интеллект: Анализ данных..."

local Log = Instance.new("ScrollingFrame", Main)
Log.Size = UDim2.new(0.9, 0, 0.4, 0)
Log.Position = UDim2.new(0.05, 0, 0.18, 0)
Log.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
Instance.new("UIListLayout", Log)

local Input = Instance.new("TextBox", Main)
Input.Size = UDim2.new(0.9, 0, 0, 40)
Input.Position = UDim2.new(0.05, 0, 0.6, 0)
Input.PlaceholderText = "Спроси меня о чем угодно..."
Input.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Input.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", Input)

local WebToggle = Instance.new("TextButton", Main)
WebToggle.Size = UDim2.new(0.9, 0, 0, 30)
WebToggle.Position = UDim2.new(0.05, 0, 0.7, 0)
WebToggle.Text = "Web-Search: ВКЛ"
WebToggle.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
WebToggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", WebToggle)

local ChatToggle = Instance.new("TextButton", Main)
ChatToggle.Size = UDim2.new(0.9, 0, 0, 30)
ChatToggle.Position = UDim2.new(0.05, 0, 0.78, 0)
ChatToggle.Text = "Глобальный чат: ВЫКЛ"
ChatToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
ChatToggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", ChatToggle)

-- ЛОГИКА ОБРАБОТКИ
local lastInput = ""

local function updateIQ()
    local count = 0 for _ in pairs(Memory) do count = count + 1 end
    Stats.Text = "🧠 База: " .. count .. " | IQ: " .. (100 + count * 2)
end

local function addLog(t, c)
    local l = Instance.new("TextLabel", Log)
    l.Size = UDim2.new(1, 0, 0, 25)
    l.Text = " " .. t
    l.TextColor3 = c or Color3.new(1,1,1)
    l.BackgroundTransparency = 1
    l.TextXAlignment = "Left"
    Log.CanvasPosition = Vector2.new(0, 9999)
end

local function process(msg, global)
    msg = msg:lower()
    for _, b in pairs(Blacklist) do if msg:find(b) then return end end

    if Memory[msg] then
        local r = Memory[msg][math.random(1, #Memory[msg])]
        if global then 
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(r, "All")
        else 
            addLog("AI: " .. r, Color3.new(0, 1, 0.5)) 
        end
    else
        -- Попытка Web-поиска
        if WebSearchEnabled then
            addLog("AI: Ищу в сети...", Color3.new(1, 1, 0))
            local webResult = askWeb(msg)
            if webResult then
                local shortResult = webResult:sub(1, 150) .. "..."
                Memory[msg] = {shortResult}
                save()
                updateIQ()
                addLog("AI (Web): " .. shortResult, Color3.new(0.3, 0.8, 1))
                return
            end
        end

        -- Обычное обучение
        if lastInput ~= "" then
            if not Memory[lastInput] then Memory[lastInput] = {} end
            table.insert(Memory[lastInput], msg)
            save()
            updateIQ()
            addLog("[Выучено соответствие]", Color3.new(1, 0.5, 0))
        end
    end
    lastInput = msg
end

Input.FocusLost:Connect(function(e)
    if e and Input.Text ~= "" then
        addLog("Вы: " .. Input.Text, Color3.new(0.7, 0.7, 1))
        process(Input.Text, false)
        Input.Text = ""
    end
end)

WebToggle.MouseButton1Click:Connect(function()
    WebSearchEnabled = not WebSearchEnabled
    WebToggle.Text = "Web-Search: " .. (WebSearchEnabled and "ВКЛ" or "ВЫКЛ")
    WebToggle.BackgroundColor3 = WebSearchEnabled and Color3.fromRGB(0, 80, 150) or Color3.fromRGB(60, 60, 70)
end)

ChatToggle.MouseButton1Click:Connect(function()
    AutoChat = not AutoChat
    ChatToggle.Text = "Глобальный чат: " .. (AutoChat and "ВКЛ" or "ВЫКЛ")
    ChatToggle.BackgroundColor3 = AutoChat and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 70)
end)

updateIQ()
