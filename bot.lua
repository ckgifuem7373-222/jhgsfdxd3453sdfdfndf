local HttpService = game:GetService("HttpService")
local FileName = "bot_memory.json"

-- База знаний
local Memory = { ["привет"] = {"Привет! Я твой ИИ."} }

-- Функции сохранения/загрузки (специфичные для Xeno/Exploits)
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

-- СОЗДАНИЕ GUI
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "Xeno_AI_Chat"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true
MainFrame.Draggable = true -- Можно двигать мышкой

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "AI Chat Engine (Xeno Edition)"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

local ChatLog = Instance.new("ScrollingFrame", MainFrame)
ChatLog.Size = UDim2.new(0.9, 0, 0.6, 0)
ChatLog.Position = UDim2.new(0.05, 0, 0.1, 0)
ChatLog.CanvasSize = UDim2.new(0, 0, 5, 0)
ChatLog.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

local UIList = Instance.new("UIListLayout", ChatLog)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

local InputBox = Instance.new("TextBox", MainFrame)
InputBox.Size = UDim2.new(0.9, 0, 0, 30)
InputBox.Position = UDim2.new(0.05, 0, 0.75, 0)
InputBox.PlaceholderText = "Напиши что-нибудь..."
InputBox.Text = ""
InputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
InputBox.TextColor3 = Color3.new(1, 1, 1)

local ClearBtn = Instance.new("TextButton", MainFrame)
ClearBtn.Size = UDim2.new(0.9, 0, 0, 30)
ClearBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
ClearBtn.Text = "ОЧИСТИТЬ ПАМЯТЬ"
ClearBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
ClearBtn.TextColor3 = Color3.new(1, 1, 1)

-- Логика чата
local lastInput = ""

local function addMessage(text, color)
    local msg = Instance.new("TextLabel", ChatLog)
    msg.Size = UDim2.new(1, 0, 0, 25)
    msg.BackgroundTransparency = 1
    msg.Text = text
    msg.TextColor3 = color or Color3.new(1, 1, 1)
    msg.TextWrapped = true
end

InputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and InputBox.Text ~= "" then
        local userText = InputBox.Text:lower()
        addMessage("Вы: " .. userText, Color3.new(0.7, 0.7, 1))
        
        -- Поиск ответа
        if Memory[userText] then
            local resp = Memory[userText][math.random(1, #Memory[userText])]
            task.wait(0.5)
            addMessage("ИИ: " .. resp, Color3.new(0.7, 1, 0.7))
        else
            -- Если не знает, запоминает контекст для обучения
            if lastInput ~= "" then
                if not Memory[lastInput] then Memory[lastInput] = {} end
                table.insert(Memory[lastInput], userText)
                saveMemory()
                addMessage("[Выучено новое соответствие]", Color3.new(1, 1, 0))
            end
            addMessage("ИИ: Я пока не знаю, что ответить.", Color3.new(1, 0.5, 0.5))
        end
        
        lastInput = userText
        InputBox.Text = ""
    end
end)

-- Команда очистки
ClearBtn.MouseButton1Click:Connect(function()
    Memory = { ["привет"] = {"Привет! Я твой ИИ."} }
    saveMemory()
    addMessage("!!! ПАМЯТЬ ОЧИЩЕНА !!!", Color3.fromRGB(255, 0, 0))
end)

-- Клавиша скрытия меню (Insert)
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)
