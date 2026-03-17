local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local FileName = "bot_brain_v2.json"

-- База знаний
local Memory = { ["привет"] = {"Привет! Я твой ИИ-ученик."}, ["кто ты"] = {"Я самообучающийся скрипт для Xeno!"} }
local AutoChat = false -- По умолчанию выключено

-- Функции работы с файлами
local function saveMemory()
    writefile(FileName, HttpService:JSONEncode(Memory))
end

local function loadMemory()
    if isfile(FileName) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
        if success then Memory = data end
    end
end

loadMemory()

-- СЧЕТЧИК ЗНАНИЙ
local function getMemorySize()
    local count = 0
    for _ in pairs(Memory) do count = count + 1 end
    return count
end

-- СОЗДАНИЕ GUI
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 450)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.Active = true
MainFrame.Draggable = true

-- Скругление углов
local Corner = Instance.new("UICorner", MainFrame)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "🤖 AI BRAIN [v2.0]"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Instance.new("UICorner", Title)

local StatsLabel = Instance.new("TextLabel", MainFrame)
StatsLabel.Size = UDim2.new(1, 0, 0, 20)
StatsLabel.Position = UDim2.new(0, 0, 0, 40)
StatsLabel.Text = "Выучено фраз: " .. getMemorySize()
StatsLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
StatsLabel.BackgroundTransparency = 1

local ChatLog = Instance.new("ScrollingFrame", MainFrame)
ChatLog.Size = UDim2.new(0.9, 0, 0.45, 0)
ChatLog.Position = UDim2.new(0.05, 0, 0.15, 0)
ChatLog.CanvasSize = UDim2.new(0, 0, 10, 0)
ChatLog.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Instance.new("UIListLayout", ChatLog).SortOrder = Enum.SortOrder.LayoutOrder

local InputBox = Instance.new("TextBox", MainFrame)
InputBox.Size = UDim2.new(0.9, 0, 0, 35)
InputBox.Position = UDim2.new(0.05, 0, 0.65, 0)
InputBox.PlaceholderText = "Напиши что-то для обучения..."
InputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
InputBox.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", InputBox)

-- КНОПКА ГЛОБАЛЬНОГО ЧАТА
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 30)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
ToggleBtn.Text = "Глобальный авто-ответ: ВЫКЛ"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", ToggleBtn)

local ClearBtn = Instance.new("TextButton", MainFrame)
ClearBtn.Size = UDim2.new(0.9, 0, 0, 30)
ClearBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
ClearBtn.Text = "СБРОСИТЬ ВСЕ ЗНАНИЯ"
ClearBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
ClearBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", ClearBtn)

-- ЛОГИКА
local function addLog(txt, col)
    local l = Instance.new("TextLabel", ChatLog)
    l.Size = UDim2.new(1, 0, 0, 20)
    l.Text = txt
    l.TextColor3 = col or Color3.new(1,1,1)
    l.BackgroundTransparency = 1
    ChatLog.CanvasPosition = Vector2.new(0, 9999)
end

local lastMsg = ""

local function processBrain(msg, isGlobal)
    local input = msg:lower()
    if Memory[input] then
        local r = Memory[input][math.random(1, #Memory[input])]
        if isGlobal then
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(r, "All")
        else
            addLog("ИИ: " .. r, Color3.new(0.5, 1, 0.5))
        end
    else
        if lastMsg ~= "" and lastMsg ~= input then
            if not Memory[lastMsg] then Memory[lastMsg] = {} end
            table.insert(Memory[lastMsg], msg)
            saveMemory()
            StatsLabel.Text = "Выучено фраз: " .. getMemorySize()
            addLog("[Новое знание получено]", Color3.new(1, 1, 0))
        end
        if not isGlobal then addLog("ИИ: (запоминаю...)", Color3.new(1, 0.4, 0.4)) end
    end
    lastMsg = input
end

-- Обработка ввода в GUI
InputBox.FocusLost:Connect(function(enter)
    if enter and InputBox.Text ~= "" then
        addLog("Вы: " .. InputBox.Text, Color3.new(0.6, 0.6, 1))
        processBrain(InputBox.Text, false)
        InputBox.Text = ""
    end
end)

-- Переключатель авто-чата
ToggleBtn.MouseButton1Click:Connect(function()
    AutoChat = not AutoChat
    ToggleBtn.Text = "Глобальный авто-ответ: " .. (AutoChat and "ВКЛ" or "ВЫКЛ")
    ToggleBtn.BackgroundColor3 = AutoChat and Color3.fromRGB(40, 100, 40) or Color3.fromRGB(60, 60, 70)
end)

-- Слушатель глобального чата
game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(data)
    if AutoChat and data.FromSpeaker ~= game.Players.LocalPlayer.Name then
        processBrain(data.Message, true)
    end
end)

-- Очистка
ClearBtn.MouseButton1Click:Connect(function()
    Memory = {}
    saveMemory()
    StatsLabel.Text = "Выучено фраз: 0"
    addLog("!!! ПАМЯТЬ СТЕРТА !!!", Color3.new(1,0,0))
end)
