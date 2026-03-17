local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local FileName = "ai_master_brain.json"

-- ПАРАМЕТРЫ ИИ
local Memory = {["привет"] = {"Привет! Я стал еще умнее и теперь могу менять размер окна."}}
local ChatHistory = {} -- Контекстная память
local Mood = "Нейтральный"
local AutoChat = false

-- Загрузка данных
local function save() writefile(FileName, HttpService:JSONEncode(Memory)) end
if isfile(FileName) then 
    local s, d = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
    if s then Memory = d end
end

-- ИСПРАВЛЕННАЯ ФУНКЦИЯ WEB-ПОИСКА
local function askWeb(query)
    if not query or query == "" then return nil end
    local url = "https://api.duckduckgo.com" .. HttpService:UrlEncode(query) .. "&format=json&no_html=1"
    
    local success, response = pcall(function() return game:HttpGet(url) end)
    
    if success and response and response ~= "" then
        local data = HttpService:JSONDecode(response)
        if data and data.AbstractText and data.AbstractText ~= "" then
            return data.AbstractText
        end
    end
    return nil
end

-- СОЗДАНИЕ GUI
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 350, 0, 450)
Main.Position = UDim2.new(0.5, -175, 0.5, -225)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.Active = true
Main.Draggable = true -- Передвижение за любую часть фона

local Corner = Instance.new("UICorner", Main)

-- Хендл для изменения размера
local ResizeHandle = Instance.new("ImageButton", Main)
ResizeHandle.Size = UDim2.new(0, 20, 0, 20)
ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.Image = "rbxassetid://3854515233" -- Иконка уголка

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "🧠 NEURAL MASTER v6.0"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Instance.new("UICorner", Title)

local Log = Instance.new("ScrollingFrame", Main)
Log.Size = UDim2.new(0.9, 0, 0.5, 0)
Log.Position = UDim2.new(0.05, 0, 0.12, 0)
Log.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
Log.CanvasSize = UDim2.new(0,0,20,0)
Instance.new("UIListLayout", Log)

local Input = Instance.new("TextBox", Main)
Input.Size = UDim2.new(0.9, 0, 0, 35)
Input.Position = UDim2.new(0.05, 0, 0.65, 0)
Input.PlaceholderText = "Спроси меня о чем угодно..."
Input.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
Input.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", Input)

local Toggle = Instance.new("TextButton", Main)
Toggle.Size = UDim2.new(0.9, 0, 0, 30)
Toggle.Position = UDim2.new(0.05, 0, 0.75, 0)
Toggle.Text = "Глобальный чат: ВЫКЛ"
Toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
Toggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", Toggle)

-- ЛОГИКА ИЗМЕНЕНИЯ РАЗМЕРА
local resizing = false
ResizeHandle.MouseButton1Down:Connect(function() resizing = true end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end end)

UserInputService.InputChanged:Connect(function(input)
    if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = UserInputService:GetMouseLocation()
        local newSizeX = math.clamp(mousePos.X - Main.AbsolutePosition.X, 250, 800)
        local newSizeY = math.clamp(mousePos.Y - Main.AbsolutePosition.Y, 300, 800)
        Main.Size = UDim2.new(0, newSizeX, 0, newSizeY)
    end
end)

-- УМНАЯ ЛОГИКА ОТВЕТОВ
local function addLog(t, c)
    local l = Instance.new("TextLabel", Log)
    l.Size = UDim2.new(1, 0, 0, 20)
    l.Text = " " .. t
    l.TextColor3 = c or Color3.new(1,1,1)
    l.BackgroundTransparency = 1
    l.TextXAlignment = "Left"
    Log.CanvasPosition = Vector2.new(0, 9999)
end

local function process(msg, global)
    local low = msg:lower()
    
    -- Контекст: добавляем в историю
    table.insert(ChatHistory, low)
    if #ChatHistory > 5 then table.remove(ChatHistory, 1) end

    -- 1. Поиск в памяти
    if Memory[low] then
        local r = Memory[low][math.random(1, #Memory[low])]
        if global then game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(r, "All")
        else addLog("AI: " .. r, Color3.new(0, 1, 0.5)) end
        return
    end

    -- 2. Веб-поиск
    local web = askWeb(msg)
    if web then
        Memory[low] = {web}
        save()
        addLog("AI (Знания): " .. web:sub(1, 100) .. "...", Color3.new(0.4, 0.8, 1))
        return
    end

    -- 3. Обучение
    if #ChatHistory >= 2 then
        local question = ChatHistory[#ChatHistory-1]
        if not Memory[question] then Memory[question] = {} end
        table.insert(Memory[question], msg)
        save()
        addLog("[Связь создана: " .. question .. " -> " .. msg .. "]", Color3.new(1, 1, 0))
    end
end

Input.FocusLost:Connect(function(e)
    if e and Input.Text ~= "" then
        addLog("Вы: " .. Input.Text, Color3.new(0.7, 0.7, 1))
        process(Input.Text, false)
        Input.Text = ""
    end
end)

Toggle.MouseButton1Click:Connect(function()
    AutoChat = not AutoChat
    Toggle.Text = "Глобальный чат: " .. (AutoChat and "ВКЛ" or "ВЫКЛ")
    Toggle.BackgroundColor3 = AutoChat and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 70)
end)

game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(d)
    if AutoChat and d.FromSpeaker ~= game.Players.LocalPlayer.Name then process(d.Message, true) end
end)
