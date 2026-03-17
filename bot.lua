local HttpService = game:GetService("HttpService")
local FileName = "bot_brain_v4.json"

-- Настройки
local Blacklist = {"дурак", "тупой", "админ", "чит", "скам"} 
local Memory = { ["привет"] = {"Привет! Мой IQ растет с каждым словом."} }
local AutoChat = false

-- Проверка и сохранение
local function saveMemory() writefile(FileName, HttpService:JSONEncode(Memory)) end
local function loadMemory()
    if isfile(FileName) then
        local s, d = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
        if s then Memory = d end
    end
end
loadMemory()

-- Расчет IQ (базовый 50 + 5 за каждое уникальное знание)
local function getStats()
    local count = 0
    for _ in pairs(Memory) do count = count + 1 end
    local iq = 50 + (count * 5)
    return count, iq
end

-- GUI
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 480)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "🧠 NEURAL BRAIN v4.0"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Instance.new("UICorner", Title)

-- Индикатор IQ и Знаний
local StatsLabel = Instance.new("TextLabel", MainFrame)
StatsLabel.Size = UDim2.new(1, 0, 0, 40)
StatsLabel.Position = UDim2.new(0, 0, 0, 45)
StatsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatsLabel.BackgroundTransparency = 1
StatsLabel.RichText = true

local function updateStats()
    local count, iq = getStats()
    StatsLabel.Text = string.format("<font color='#00FF96'>Знаний: %d</font> | <font color='#00C8FF'>IQ: %d</font>", count, iq)
end
updateStats()

local ChatLog = Instance.new("ScrollingFrame", MainFrame)
ChatLog.Size = UDim2.new(0.9, 0, 0.35, 0)
ChatLog.Position = UDim2.new(0.05, 0, 0.18, 0)
ChatLog.CanvasSize = UDim2.new(0, 0, 20, 0)
ChatLog.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
Instance.new("UIListLayout", ChatLog).SortOrder = Enum.SortOrder.LayoutOrder

local InputBox = Instance.new("TextBox", MainFrame)
InputBox.Size = UDim2.new(0.9, 0, 0, 35)
InputBox.Position = UDim2.new(0.05, 0, 0.55, 0)
InputBox.PlaceholderText = "Напиши вопрос, а затем ответ..."
InputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
InputBox.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", InputBox)

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.Text = "Авто-ответ: ВЫКЛ"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", ToggleBtn)

-- Дополнительная кнопка "Загрузить базу из облака" (Пример)
local CloudBtn = Instance.new("TextButton", MainFrame)
CloudBtn.Size = UDim2.new(0.9, 0, 0, 35)
CloudBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
CloudBtn.Text = "ОБУЧИТЬ ИЗ ФАЙЛА"
CloudBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 120)
CloudBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", CloudBtn)

local ClearBtn = Instance.new("TextButton", MainFrame)
ClearBtn.Size = UDim2.new(0.9, 0, 0, 35)
ClearBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
ClearBtn.Text = "Сброс памяти"
ClearBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
ClearBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", ClearBtn)

-- Логика обучения
local lastMsg = ""
local function addLog(txt, col)
    local l = Instance.new("TextLabel", ChatLog)
    l.Size = UDim2.new(1, 0, 0, 20)
    l.Text = " " .. txt
    l.TextColor3 = col or Color3.new(1,1,1)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.BackgroundTransparency = 1
    ChatLog.CanvasPosition = Vector2.new(0, 9999)
end

local function process(msg, isGlobal)
    local t = msg:lower()
    if not isGlobal then addLog("Сообщение: " .. msg, Color3.new(0.6, 0.6, 1)) end
    
    if Memory[t] then
        local r = Memory[t][math.random(1, #Memory[t])]
        if isGlobal then
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(r, "All")
        else
            addLog("Бот: " .. r, Color3.new(0, 1, 0.5))
        end
    elseif lastMsg ~= "" then
        if not Memory[lastMsg] then Memory[lastMsg] = {} end
        table.insert(Memory[lastMsg], msg)
        saveMemory()
        updateStats()
        if not isGlobal then addLog("Усвоено: " .. lastMsg .. " -> " .. msg, Color3.new(1, 1, 0)) end
    end
    lastMsg = t
end

InputBox.FocusLost:Connect(function(e) if e and InputBox.Text ~= "" then process(InputBox.Text, false) InputBox.Text = "" end end)

ToggleBtn.MouseButton1Click:Connect(function()
    AutoChat = not AutoChat
    ToggleBtn.Text = "Авто-ответ: " .. (AutoChat and "ВКЛ" or "ВЫКЛ")
    ToggleBtn.BackgroundColor3 = AutoChat and Color3.fromRGB(30, 80, 30) or Color3.fromRGB(50, 50, 60)
end)

-- Новое: Быстрое обучение (Кнопка загрузки)
CloudBtn.MouseButton1Click:Connect(function()
    addLog("Загрузка данных из локального хранилища...", Color3.new(1, 0.5, 1))
    loadMemory()
    updateStats()
end)

game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(d)
    if AutoChat and d.FromSpeaker ~= game.Players.LocalPlayer.Name then process(d.Message, true) end
end)

ClearBtn.MouseButton1Click:Connect(function()
    Memory = {}
    saveMemory()
    updateStats()
    addLog("ПАМЯТЬ СТЕРТА", Color3.new(1,0,0))
end)
