-- Eclipse AI - Intelligent Game Analysis System
-- Version: 1.0.0
-- Compatible with: Xeno Executor

local Eclipse = {}
Eclipse.Version = "1.0.0"
Eclipse.Name = "Eclipse AI"

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local ScreenGui = nil
local MainFrame = nil
local ChatFrame = nil
local InputBox = nil
local MessagesContainer = nil
local IsVisible = false

-- AI Configuration
Eclipse.Config = {
    ApiEndpoint = "", -- Здесь будет API endpoint для ИИ
    MaxMessages = 50,
    LearningRate = 0.8, -- Скорость обучения (0-1)
    MinConfidence = 0.3, -- Минимальная уверенность для ответа
    SaveInterval = 30, -- Автосохранение каждые 30 секунд
    MaxKnowledgeSize = 10000, -- Максимум записей в базе знаний
    PersistentMemory = true, -- Постоянная память
    Theme = {
        Primary = Color3.fromRGB(138, 43, 226), -- Purple
        Secondary = Color3.fromRGB(75, 0, 130),
        Background = Color3.fromRGB(20, 20, 25),
        Surface = Color3.fromRGB(30, 30, 35),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 180),
        Success = Color3.fromRGB(46, 204, 113),
        Error = Color3.fromRGB(231, 76, 60)
    }
}

-- Chat History
Eclipse.ChatHistory = {}

-- Learning System
Eclipse.Knowledge = {
    patterns = {}, -- Паттерны вопрос-ответ
    gameData = {}, -- Данные о текущей игре
    functions = {}, -- Изученные функции
    remotes = {}, -- Изученные RemoteEvents
    contexts = {}, -- Контекстные связи
    feedback = {}, -- Обратная связь от пользователя
    customAnswers = {} -- Пользовательские ответы на вопросы
}

Eclipse.CurrentContext = {
    game = nil,
    lastTopic = nil,
    conversationDepth = 0,
    analyzedObjects = {},
    waitingForAnswer = false, -- Ожидает ответа от пользователя
    lastQuestion = nil -- Последний заданный вопрос
}

-- Persistent Storage
Eclipse.Storage = {
    SaveKey = "EclipseAI_Knowledge_v1",
    LastSave = 0,
    AutoSaveEnabled = true
}

-- UI Creation Functions
function Eclipse:CreateGui()
    -- Destroy existing GUI if present
    if ScreenGui then
        ScreenGui:Destroy()
    end
    
    -- Create ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "EclipseAI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Protection
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
            ScreenGui.Parent = game:GetService("CoreGui")
        elseif gethui then
            ScreenGui.Parent = gethui()
        elseif game:GetService("RunService"):IsStudio() == false then
            ScreenGui.Parent = game:GetService("CoreGui")
        else
            ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end)
    
    -- Fallback если что-то пошло не так
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    self:CreateMainFrame()
    self:CreateChatInterface()
    self:CreateToggleButton()
end

function Eclipse:CreateMainFrame()
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 500, 0, 600)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
    MainFrame.BackgroundColor3 = self.Config.Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui
    
    -- Corner
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame
    
    -- Shadow effect
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.7
    Shadow.ZIndex = 0
    Shadow.Parent = MainFrame
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = self.Config.Theme.Primary
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header
    
    -- Fix bottom corners
    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 12)
    HeaderFix.Position = UDim2.new(0, 0, 1, -12)
    HeaderFix.BackgroundColor3 = self.Config.Theme.Primary
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = Header
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🌙 " .. self.Name
    Title.TextColor3 = self.Config.Theme.Text
    Title.TextSize = 20
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    -- Learning Indicator
    local LearningIndicator = Instance.new("TextLabel")
    LearningIndicator.Name = "LearningIndicator"
    LearningIndicator.Size = UDim2.new(0, 80, 0, 20)
    LearningIndicator.Position = UDim2.new(1, -140, 0, 15)
    LearningIndicator.BackgroundColor3 = self.Config.Theme.Success
    LearningIndicator.Text = "🧠 Learning"
    LearningIndicator.TextColor3 = self.Config.Theme.Text
    LearningIndicator.TextSize = 10
    LearningIndicator.Font = Enum.Font.GothamBold
    LearningIndicator.BorderSizePixel = 0
    LearningIndicator.Visible = false
    LearningIndicator.Parent = Header
    
    local IndicatorCorner = Instance.new("UICorner")
    IndicatorCorner.CornerRadius = UDim.new(0, 4)
    IndicatorCorner.Parent = LearningIndicator
    
    -- Сохраняем ссылку для анимации
    self.LearningIndicator = LearningIndicator
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 40, 0, 40)
    CloseButton.Position = UDim2.new(1, -45, 0, 5)
    CloseButton.BackgroundColor3 = self.Config.Theme.Error
    CloseButton.Text = "✕"
    CloseButton.TextColor3 = self.Config.Theme.Text
    CloseButton.TextSize = 18
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.BorderSizePixel = 0
    CloseButton.Parent = Header
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        self:ToggleGui()
    end)
    
    -- Make draggable
    self:MakeDraggable(MainFrame, Header)
end

function Eclipse:CreateChatInterface()
    -- Chat Container
    ChatFrame = Instance.new("Frame")
    ChatFrame.Name = "ChatFrame"
    ChatFrame.Size = UDim2.new(1, -20, 1, -120)
    ChatFrame.Position = UDim2.new(0, 10, 0, 60)
    ChatFrame.BackgroundColor3 = self.Config.Theme.Surface
    ChatFrame.BorderSizePixel = 0
    ChatFrame.Parent = MainFrame
    
    local ChatCorner = Instance.new("UICorner")
    ChatCorner.CornerRadius = UDim.new(0, 8)
    ChatCorner.Parent = ChatFrame
    
    -- Messages Container (ScrollingFrame)
    MessagesContainer = Instance.new("ScrollingFrame")
    MessagesContainer.Name = "MessagesContainer"
    MessagesContainer.Size = UDim2.new(1, -10, 1, -10)
    MessagesContainer.Position = UDim2.new(0, 5, 0, 5)
    MessagesContainer.BackgroundTransparency = 1
    MessagesContainer.BorderSizePixel = 0
    MessagesContainer.ScrollBarThickness = 6
    MessagesContainer.ScrollBarImageColor3 = self.Config.Theme.Primary
    MessagesContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    MessagesContainer.Parent = ChatFrame
    
    local MessagesLayout = Instance.new("UIListLayout")
    MessagesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    MessagesLayout.Padding = UDim.new(0, 8)
    MessagesLayout.Parent = MessagesContainer
    
    MessagesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        MessagesContainer.CanvasSize = UDim2.new(0, 0, 0, MessagesLayout.AbsoluteContentSize.Y + 10)
        MessagesContainer.CanvasPosition = Vector2.new(0, MessagesContainer.CanvasSize.Y.Offset)
    end)
    
    -- Input Container
    local InputContainer = Instance.new("Frame")
    InputContainer.Name = "InputContainer"
    InputContainer.Size = UDim2.new(1, -20, 0, 50)
    InputContainer.Position = UDim2.new(0, 10, 1, -60)
    InputContainer.BackgroundColor3 = self.Config.Theme.Surface
    InputContainer.BorderSizePixel = 0
    InputContainer.Parent = MainFrame
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 8)
    InputCorner.Parent = InputContainer
    
    -- Input Box
    InputBox = Instance.new("TextBox")
    InputBox.Name = "InputBox"
    InputBox.Size = UDim2.new(1, -70, 1, -10)
    InputBox.Position = UDim2.new(0, 10, 0, 5)
    InputBox.BackgroundTransparency = 1
    InputBox.Text = ""
    InputBox.PlaceholderText = "Спроси Eclipse о чем-нибудь..."
    InputBox.TextColor3 = self.Config.Theme.Text
    InputBox.PlaceholderColor3 = self.Config.Theme.TextSecondary
    InputBox.TextSize = 14
    InputBox.Font = Enum.Font.Gotham
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.ClearTextOnFocus = false
    InputBox.Parent = InputContainer
    
    -- Send Button
    local SendButton = Instance.new("TextButton")
    SendButton.Name = "SendButton"
    SendButton.Size = UDim2.new(0, 50, 0, 40)
    SendButton.Position = UDim2.new(1, -60, 0, 5)
    SendButton.BackgroundColor3 = self.Config.Theme.Primary
    SendButton.Text = "➤"
    SendButton.TextColor3 = self.Config.Theme.Text
    SendButton.TextSize = 18
    SendButton.Font = Enum.Font.GothamBold
    SendButton.BorderSizePixel = 0
    SendButton.Parent = InputContainer
    
    local SendCorner = Instance.new("UICorner")
    SendCorner.CornerRadius = UDim.new(0, 8)
    SendCorner.Parent = SendButton
    
    -- Send message on button click
    SendButton.MouseButton1Click:Connect(function()
        self:SendMessage()
    end)
    
    -- Send message on Enter key
    InputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            self:SendMessage()
        end
    end)
    
    -- Welcome message
    local welcomeMsg = "Привет! Я Eclipse AI с системой быстрого обучения и постоянной памятью. "
    
    -- Проверяем, есть ли сохраненные знания
    local hasKnowledge = false
    for _ in pairs(self.Knowledge.patterns) do
        hasKnowledge = true
        break
    end
    
    if hasKnowledge then
        welcomeMsg = welcomeMsg .. "Я загрузил свои знания и помню наши прошлые разговоры! "
    end
    
    welcomeMsg = welcomeMsg .. "Я учусь с каждым твоим сообщением и автоматически сохраняю все знания. Задай мне вопрос или научи меня чему-то новому!"
    
    self:AddSystemMessage(welcomeMsg)
end

function Eclipse:CreateToggleButton()
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 50, 0, 50)
    ToggleButton.Position = UDim2.new(0, 10, 0.5, -25)
    ToggleButton.BackgroundColor3 = self.Config.Theme.Primary
    ToggleButton.Text = "🌙"
    ToggleButton.TextColor3 = self.Config.Theme.Text
    ToggleButton.TextSize = 24
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Parent = ScreenGui
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 12)
    ToggleCorner.Parent = ToggleButton
    
    ToggleButton.MouseButton1Click:Connect(function()
        self:ToggleGui()
    end)
end

-- Utility Functions
function Eclipse:MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragInput, mousePos, framePos
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
end

function Eclipse:ToggleGui()
    IsVisible = not IsVisible
    MainFrame.Visible = IsVisible
    
    if IsVisible then
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 500, 0, 600),
            Position = UDim2.new(0.5, -250, 0.5, -300)
        })
        tween:Play()
    end
end

-- Message Functions
function Eclipse:AddMessage(sender, message, isUser)
    local MessageFrame = Instance.new("Frame")
    MessageFrame.Name = "Message"
    MessageFrame.Size = UDim2.new(1, -10, 0, 0)
    MessageFrame.BackgroundColor3 = isUser and self.Config.Theme.Primary or self.Config.Theme.Background
    MessageFrame.BorderSizePixel = 0
    MessageFrame.AutomaticSize = Enum.AutomaticSize.Y
    MessageFrame.Parent = MessagesContainer
    
    local MessageCorner = Instance.new("UICorner")
    MessageCorner.CornerRadius = UDim.new(0, 8)
    MessageCorner.Parent = MessageFrame
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 10)
    Padding.PaddingRight = UDim.new(0, 10)
    Padding.PaddingTop = UDim.new(0, 8)
    Padding.PaddingBottom = UDim.new(0, 8)
    Padding.Parent = MessageFrame
    
    local SenderLabel = Instance.new("TextLabel")
    SenderLabel.Name = "Sender"
    SenderLabel.Size = UDim2.new(1, 0, 0, 16)
    SenderLabel.BackgroundTransparency = 1
    SenderLabel.Text = sender
    SenderLabel.TextColor3 = self.Config.Theme.Text
    SenderLabel.TextSize = 12
    SenderLabel.Font = Enum.Font.GothamBold
    SenderLabel.TextXAlignment = Enum.TextXAlignment.Left
    SenderLabel.Parent = MessageFrame
    
    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Name = "MessageText"
    MessageLabel.Size = UDim2.new(1, 0, 0, 0)
    MessageLabel.Position = UDim2.new(0, 0, 0, 20)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.Text = message
    MessageLabel.TextColor3 = self.Config.Theme.Text
    MessageLabel.TextSize = 14
    MessageLabel.Font = Enum.Font.Gotham
    MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
    MessageLabel.TextYAlignment = Enum.TextYAlignment.Top
    MessageLabel.TextWrapped = true
    MessageLabel.AutomaticSize = Enum.AutomaticSize.Y
    MessageLabel.Parent = MessageFrame
    
    -- Add to history
    table.insert(self.ChatHistory, {
        sender = sender,
        message = message,
        isUser = isUser,
        timestamp = os.time()
    })
    
    -- Limit history
    if #self.ChatHistory > self.Config.MaxMessages then
        table.remove(self.ChatHistory, 1)
    end
end

function Eclipse:AddSystemMessage(message)
    self:AddMessage("System", message, false)
end

function Eclipse:SendMessage()
    local message = InputBox.Text
    if message == "" or message:match("^%s*$") then
        return
    end
    
    -- Add user message
    self:AddMessage("You", message, true)
    InputBox.Text = ""
    
    -- Process AI response
    self:ProcessAIResponse(message)
end

-- AI Processing Functions
function Eclipse:ProcessAIResponse(userMessage)
    -- Показываем индикатор загрузки
    self:AddMessage("Eclipse", "Думаю...", false)
    
    -- Показываем индикатор обучения
    if self.LearningIndicator then
        self.LearningIndicator.Visible = true
    end
    
    task.spawn(function()
        task.wait(0.3) -- Быстрая обработка
        
        -- Удаляем сообщение "Думаю..."
        local lastMessage = MessagesContainer:GetChildren()[#MessagesContainer:GetChildren()]
        if lastMessage and lastMessage.Name == "Message" then
            lastMessage:Destroy()
        end
        
        -- Обучаемся на вопросе
        self:LearnFromInput(userMessage)
        
        -- Генерируем ответ с учетом обучения
        local response = self:GenerateIntelligentResponse(userMessage)
        self:AddMessage("Eclipse", response, false)
        
        -- Обновляем контекст
        self:UpdateContext(userMessage, response)
        
        -- Скрываем индикатор обучения
        task.wait(1)
        if self.LearningIndicator then
            self.LearningIndicator.Visible = false
        end
    end)
end

function Eclipse:GenerateIntelligentResponse(message)
    local lowerMessage = message:lower()
    
    -- ПРИОРИТЕТ 1: Проверяем пользовательские ответы
    local customAnswer = self:FindCustomAnswer(message)
    if customAnswer then
        return customAnswer
    end
    
    -- ПРИОРИТЕТ 2: Проверяем изученные паттерны
    local learnedResponse = self:CheckLearnedPatterns(lowerMessage)
    if learnedResponse then
        return learnedResponse
    end
    
    -- ПРИОРИТЕТ 3: Анализируем контекст разговора
    local contextResponse = self:AnalyzeContext(lowerMessage)
    if contextResponse then
        return contextResponse
    end
    
    -- Базовые паттерны ответов
    if lowerMessage:match("привет") or lowerMessage:match("hello") or lowerMessage:match("hi") then
        self:LearnPattern(lowerMessage, "greeting")
        return "Привет! Я Eclipse AI. Я создан для анализа игр в Roblox и быстро учусь. Чем могу помочь?"
    
    elseif lowerMessage:match("как.*работа") or lowerMessage:match("что.*дела") then
        return "Я анализирую структуру игр, изучаю функции и логику. С каждым вопросом я становлюсь умнее!"
    
    elseif lowerMessage:match("remote") or lowerMessage:match("ремоут") then
        self:LearnGameConcept("remotes", message)
        return "RemoteEvent и RemoteFunction - это объекты для связи между клиентом и сервером. RemoteEvent:FireServer() отправляет данные на сервер, а RemoteFunction:InvokeServer() ждет ответа. Хочешь, я найду все RemoteEvents в этой игре?"
    
    elseif lowerMessage:match("script") or lowerMessage:match("скрипт") then
        self:LearnGameConcept("scripts", message)
        return "В Roblox есть три типа скриптов: Script (серверный), LocalScript (клиентский) и ModuleScript (модульный). Каждый выполняет свою роль в архитектуре игры."
    
    elseif lowerMessage:match("function") or lowerMessage:match("функци") then
        return "Я могу проанализировать функции в игре. Скажи мне имя функции или покажи код, и я объясню, как она работает."
    
    elseif lowerMessage:match("game") or lowerMessage:match("игра") then
        self:AutoAnalyzeGame()
        return "Я проанализировал текущую игру. Могу помочь понять структуру, найти важные скрипты, изучить RemoteEvents и механики. Что именно тебя интересует?"
    
    elseif lowerMessage:match("учись") or lowerMessage:match("learn") or lowerMessage:match("запомни") then
        return [[Отлично! Есть несколько способов научить меня:

1. Вопрос-ответ:
   Запомни: Что такое античит? Система защиты от читеров

2. Определение:
   Запомни что RemoteEvent это объект для связи клиент-сервер

3. Просто расскажи:
   Запомни: В этой игре для прыжка используется функция Jump()

Я запомню все и буду использовать при ответах!]]
    
    elseif lowerMessage:match("что.*знаешь") or lowerMessage:match("what.*know") then
        return self:ShowKnowledge()
    
    elseif lowerMessage:match("помощь") or lowerMessage:match("help") then
        return [[Я могу помочь с:
• Анализом структуры игры
• Объяснением функций и скриптов
• Поиском RemoteEvents
• Изучением игровых механик
• Обучением на твоих примерах

Я учусь с каждым вопросом! Просто общайся со мной.]]
    
    elseif lowerMessage:match("спасибо") or lowerMessage:match("thanks") then
        self:LearnPattern(lowerMessage, "gratitude")
        return "Всегда пожалуйста! Обращайся, если нужна помощь. 🌙"
    
    else
        -- Пытаемся извлечь знания из вопроса
        local extractedKnowledge = self:ExtractKnowledge(message)
        if extractedKnowledge then
            return "Интересно! Я запомнил это. " .. extractedKnowledge
        end
        
        return "Интересный вопрос! Я пока не знаю ответа. Научи меня:\n\nЗапомни: " .. message .. " [твой ответ]\n\nИ я запомню навсегда!"
    end
end

-- Game Analysis Functions (для будущего развития)
function Eclipse:AnalyzeGame()
    local gameInfo = {
        name = game.Name,
        placeId = game.PlaceId,
        jobId = game.JobId,
        players = #Players:GetPlayers()
    }
    
    return gameInfo
end

-- Learning System Functions
function Eclipse:LearnFromInput(message)
    local lowerMessage = message:lower()
    
    -- Распознаем паттерн сообщения
    local patterns = self:RecognizePattern(message)
    
    -- Если это код, анализируем его
    if patterns.code then
        local analysis = self:AnalyzeCode(message)
        if #analysis.functions > 0 then
            self:AddSystemMessage("🔍 Обнаружено функций: " .. #analysis.functions .. ". Анализирую...")
        end
    end
    
    -- Если это команда на обучение
    if patterns.learning then
        local knowledge = message:match("[Зз]апомни:?%s*(.+)") or message:match("[Нн]аучись:?%s*(.+)")
        if knowledge then
            self:LearnPattern(knowledge, "user_taught")
            self:AddSystemMessage("✅ Записал в базу знаний!")
        end
    end
    
    -- Извлекаем ключевые слова
    local keywords = self:ExtractKeywords(message)
    
    -- Сохраняем в базу знаний
    for _, keyword in ipairs(keywords) do
        if not self.Knowledge.patterns[keyword] then
            self.Knowledge.patterns[keyword] = {
                count = 0,
                contexts = {},
                responses = {}
            }
        end
        self.Knowledge.patterns[keyword].count = self.Knowledge.patterns[keyword].count + 1
        table.insert(self.Knowledge.patterns[keyword].contexts, {
            message = message,
            timestamp = os.time()
        })
    end
    
    -- Автоматический анализ, если упоминается игра
    if lowerMessage:match("игра") or lowerMessage:match("game") then
        self:AutoAnalyzeGame()
    end
end

function Eclipse:ExtractKeywords(text)
    local keywords = {}
    local lowerText = text:lower()
    
    -- Важные термины для Roblox
    local terms = {
        "remote", "script", "function", "game", "player", "gui", "workspace",
        "event", "service", "module", "local", "server", "client", "exploit",
        "hook", "метод", "функция", "скрипт", "игра", "игрок"
    }
    
    for _, term in ipairs(terms) do
        if lowerText:match(term) then
            table.insert(keywords, term)
        end
    end
    
    return keywords
end

function Eclipse:LearnPattern(input, category)
    if not self.Knowledge.patterns[category] then
        self.Knowledge.patterns[category] = {}
    end
    
    table.insert(self.Knowledge.patterns[category], {
        input = input,
        timestamp = os.time(),
        confidence = 1.0,
        priority = category == "user_taught" and 10 or 1 -- Высокий приоритет для обучения от пользователя
    })
    
    -- Автосохранение после обучения
    if #self.Knowledge.patterns[category] % 5 == 0 then
        self:SaveKnowledge()
    end
end

function Eclipse:LearnGameConcept(concept, details)
    if not self.Knowledge.gameData[concept] then
        self.Knowledge.gameData[concept] = {
            mentions = 0,
            details = {},
            lastUpdated = os.time(),
            importance = 1 -- Важность концепции
        }
    end
    
    self.Knowledge.gameData[concept].mentions = self.Knowledge.gameData[concept].mentions + 1
    self.Knowledge.gameData[concept].lastUpdated = os.time()
    self.Knowledge.gameData[concept].importance = math.min(self.Knowledge.gameData[concept].mentions / 5, 10)
    
    table.insert(self.Knowledge.gameData[concept].details, {
        text = details,
        timestamp = os.time()
    })
    
    -- Ограничиваем количество деталей
    if #self.Knowledge.gameData[concept].details > 20 then
        table.remove(self.Knowledge.gameData[concept].details, 1)
    end
end

function Eclipse:CheckLearnedPatterns(message)
    -- Проверяем, встречали ли мы похожий вопрос
    local bestMatch = nil
    local bestScore = 0
    
    for keyword, data in pairs(self.Knowledge.patterns) do
        if message:match(keyword) then
            local confidence = math.min(data.count / 10, 1.0) -- Максимум 1.0
            
            if confidence > bestScore and confidence >= self.Config.MinConfidence then
                bestScore = confidence
                bestMatch = data
            end
        end
    end
    
    if bestMatch and #bestMatch.responses > 0 then
        local response = bestMatch.responses[#bestMatch.responses]
        
        -- Добавляем индикатор уверенности
        if bestScore >= 0.8 then
            return "✅ [Уверен на " .. math.floor(bestScore * 100) .. "%] " .. response
        elseif bestScore >= 0.5 then
            return "🤔 [Уверен на " .. math.floor(bestScore * 100) .. "%] " .. response
        else
            return "❓ [Уверен на " .. math.floor(bestScore * 100) .. "%] " .. response
        end
    end
    
    return nil
end

function Eclipse:AnalyzeContext(message)
    -- Анализируем контекст разговора
    if self.CurrentContext.lastTopic then
        local lowerMessage = message:lower()
        
        -- Если вопрос связан с предыдущей темой
        if lowerMessage:match("как") or lowerMessage:match("что") or lowerMessage:match("почему") then
            if self.CurrentContext.lastTopic == "remotes" then
                return "Основываясь на нашем разговоре о RemoteEvents: они используются для коммуникации клиент-сервер. Хочешь узнать больше о конкретном аспекте?"
            elseif self.CurrentContext.lastTopic == "scripts" then
                return "Продолжая тему скриптов: они выполняются в разных контекстах. LocalScript - на клиенте, Script - на сервере. Что именно интересует?"
            end
        end
    end
    return nil
end

function Eclipse:UpdateContext(question, answer)
    self.CurrentContext.conversationDepth = self.CurrentContext.conversationDepth + 1
    
    -- Определяем тему
    local lowerQuestion = question:lower()
    if lowerQuestion:match("remote") then
        self.CurrentContext.lastTopic = "remotes"
    elseif lowerQuestion:match("script") then
        self.CurrentContext.lastTopic = "scripts"
    elseif lowerQuestion:match("function") then
        self.CurrentContext.lastTopic = "functions"
    end
    
    -- Сохраняем ответ для будущего обучения
    local keywords = self:ExtractKeywords(question)
    for _, keyword in ipairs(keywords) do
        if self.Knowledge.patterns[keyword] then
            table.insert(self.Knowledge.patterns[keyword].responses, answer)
            
            -- Ограничиваем количество сохраненных ответов
            if #self.Knowledge.patterns[keyword].responses > 5 then
                table.remove(self.Knowledge.patterns[keyword].responses, 1)
            end
        end
    end
end

function Eclipse:ExtractKnowledge(message)
    local lowerMessage = message:lower()
    
    -- Паттерн: "Запомни: вопрос? ответ"
    local question, answer = message:match("[Зз]апомни:%s*(.-)%?%s*(.+)")
    if question and answer then
        self:LearnQuestionAnswer(question, answer)
        return "Запомнил! Теперь на вопрос '" .. question .. "?' я буду отвечать: " .. answer
    end
    
    -- Паттерн: "Запомни что [тема] это [ответ]"
    local topic, definition = message:match("[Зз]апомни%s+что%s+(.-)%s+это%s+(.+)")
    if topic and definition then
        self:LearnQuestionAnswer("Что такое " .. topic, definition)
        return "Запомнил! Теперь я знаю что такое " .. topic
    end
    
    -- Паттерны для извлечения знаний
    if lowerMessage:match("это") or lowerMessage:match("называется") or lowerMessage:match("используется") then
        -- Пользователь что-то объясняет
        self:LearnPattern(message, "user_knowledge")
        return "Записал в базу знаний!"
    end
    
    -- Если упоминается конкретный объект
    local objectName = message:match("(%w+)%s*=%s*") or message:match("local%s+(%w+)")
    if objectName then
        self:LearnGameConcept("variables", "Переменная: " .. objectName)
        return "Запомнил переменную " .. objectName .. "!"
    end
    
    return nil
end

function Eclipse:LearnQuestionAnswer(question, answer)
    local normalizedQuestion = question:lower():gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    
    if not self.Knowledge.customAnswers[normalizedQuestion] then
        self.Knowledge.customAnswers[normalizedQuestion] = {
            question = question,
            answers = {},
            count = 0,
            lastUpdated = os.time(),
            priority = 10 -- Максимальный приоритет
        }
    end
    
    table.insert(self.Knowledge.customAnswers[normalizedQuestion].answers, {
        text = answer,
        timestamp = os.time()
    })
    
    self.Knowledge.customAnswers[normalizedQuestion].count = self.Knowledge.customAnswers[normalizedQuestion].count + 1
    self.Knowledge.customAnswers[normalizedQuestion].lastUpdated = os.time()
    
    -- Сохраняем
    self:SaveKnowledge()
end

function Eclipse:FindCustomAnswer(question)
    local normalizedQuestion = question:lower():gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    
    -- Точное совпадение
    if self.Knowledge.customAnswers[normalizedQuestion] then
        local data = self.Knowledge.customAnswers[normalizedQuestion]
        local latestAnswer = data.answers[#data.answers].text
        return "✅ [Из моих знаний] " .. latestAnswer
    end
    
    -- Частичное совпадение (ищем похожие вопросы)
    local bestMatch = nil
    local bestScore = 0
    
    for savedQuestion, data in pairs(self.Knowledge.customAnswers) do
        local score = self:CalculateSimilarity(normalizedQuestion, savedQuestion)
        if score > bestScore and score > 0.6 then -- 60% совпадение
            bestScore = score
            bestMatch = data
        end
    end
    
    if bestMatch then
        local latestAnswer = bestMatch.answers[#bestMatch.answers].text
        return "🤔 [Похожий вопрос, уверен на " .. math.floor(bestScore * 100) .. "%] " .. latestAnswer
    end
    
    return nil
end

function Eclipse:CalculateSimilarity(str1, str2)
    -- Простой алгоритм сравнения строк
    local words1 = {}
    local words2 = {}
    
    for word in str1:gmatch("%w+") do
        words1[word] = true
    end
    
    for word in str2:gmatch("%w+") do
        words2[word] = true
    end
    
    local common = 0
    local total = 0
    
    for word in pairs(words1) do
        total = total + 1
        if words2[word] then
            common = common + 1
        end
    end
    
    for word in pairs(words2) do
        if not words1[word] then
            total = total + 1
        end
    end
    
    return total > 0 and (common / total) or 0
end

function Eclipse:AutoAnalyzeGame()
    if not self.CurrentContext.game or self.CurrentContext.game ~= game.PlaceId then
        self.CurrentContext.game = game.PlaceId
        
        -- Быстрый анализ
        task.spawn(function()
            local remotes = self:FindRemotes()
            self.Knowledge.remotes = remotes
            
            local structure = self:GetGameStructure()
            self.Knowledge.gameData.structure = structure
            
            -- Сохраняем проанализированные объекты
            self.CurrentContext.analyzedObjects = {
                remotes = #remotes,
                timestamp = os.time()
            }
        end)
    end
end

function Eclipse:ShowKnowledge()
    local knowledge = "📚 Моя база знаний:\n\n"
    
    -- Пользовательские ответы
    local customCount = 0
    for _ in pairs(self.Knowledge.customAnswers) do
        customCount = customCount + 1
    end
    if customCount > 0 then
        knowledge = knowledge .. "💡 Выученных ответов: " .. customCount .. "\n"
    end
    
    -- Изученные паттерны
    local patternCount = 0
    for _ in pairs(self.Knowledge.patterns) do
        patternCount = patternCount + 1
    end
    knowledge = knowledge .. "• Изучено паттернов: " .. patternCount .. "\n"
    
    -- Данные об игре
    if self.Knowledge.remotes then
        local remoteCount = 0
        for _ in pairs(self.Knowledge.remotes) do
            remoteCount = remoteCount + 1
        end
        if remoteCount > 0 then
            knowledge = knowledge .. "• RemoteEvents найдено: " .. remoteCount .. "\n"
        end
    end
    
    -- Концепции
    local conceptCount = 0
    for _ in pairs(self.Knowledge.gameData) do
        conceptCount = conceptCount + 1
    end
    knowledge = knowledge .. "• Изучено концепций: " .. conceptCount .. "\n"
    
    -- Глубина разговора
    knowledge = knowledge .. "• Глубина разговора: " .. self.CurrentContext.conversationDepth .. "\n"
    
    if self.CurrentContext.lastTopic then
        knowledge = knowledge .. "• Текущая тема: " .. self.CurrentContext.lastTopic .. "\n"
    end
    
    -- Показываем несколько примеров выученных ответов
    if customCount > 0 then
        knowledge = knowledge .. "\n📖 Примеры выученного:\n"
        local count = 0
        for question, data in pairs(self.Knowledge.customAnswers) do
            if count >= 3 then break end
            knowledge = knowledge .. "• " .. data.question .. "\n"
            count = count + 1
        end
        if customCount > 3 then
            knowledge = knowledge .. "... и еще " .. (customCount - 3) .. " ответов"
        end
    end
    
    return knowledge
end

function Eclipse:FindRemotes()
    local remotes = {}
    
    local function scan(parent)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                local remoteData = {
                    name = child.Name,
                    path = child:GetFullName(),
                    type = child.ClassName,
                    parent = child.Parent.Name
                }
                table.insert(remotes, remoteData)
                
                -- Обучаемся на найденных RemoteEvents
                self:LearnRemote(remoteData)
            end
        end
    end
    
    scan(game:GetService("ReplicatedStorage"))
    scan(game:GetService("Workspace"))
    
    return remotes
end

function Eclipse:LearnRemote(remoteData)
    if not self.Knowledge.remotes[remoteData.name] then
        self.Knowledge.remotes[remoteData.name] = {
            type = remoteData.type,
            path = remoteData.path,
            parent = remoteData.parent,
            usageCount = 0,
            discovered = os.time(),
            importance = 1,
            notes = {} -- Заметки пользователя
        }
    end
    self.Knowledge.remotes[remoteData.name].usageCount = self.Knowledge.remotes[remoteData.name].usageCount + 1
    self.Knowledge.remotes[remoteData.name].importance = math.min(self.Knowledge.remotes[remoteData.name].usageCount / 3, 10)
end

function Eclipse:GetGameStructure()
    local structure = {}
    
    local services = {
        "Workspace",
        "ReplicatedStorage",
        "ReplicatedFirst",
        "StarterGui",
        "StarterPlayer",
        "Lighting",
        "SoundService"
    }
    
    for _, serviceName in ipairs(services) do
        local service = game:GetService(serviceName)
        structure[serviceName] = {
            children = #service:GetChildren(),
            descendants = #service:GetDescendants()
        }
        
        -- Обучаемся на структуре
        self:LearnGameConcept("structure_" .. serviceName, {
            children = #service:GetChildren(),
            descendants = #service:GetDescendants(),
            timestamp = os.time()
        })
    end
    
    return structure
end

-- Advanced Learning: Code Analysis
function Eclipse:AnalyzeCode(code)
    local analysis = {
        functions = {},
        variables = {},
        remotes = {},
        patterns = {}
    }
    
    -- Находим функции
    for funcName in code:gmatch("function%s+(%w+)") do
        table.insert(analysis.functions, funcName)
        self:LearnFunction(funcName, "standard")
    end
    
    -- Находим локальные функции
    for funcName in code:gmatch("local%s+function%s+(%w+)") do
        table.insert(analysis.functions, funcName)
        self:LearnFunction(funcName, "local")
    end
    
    -- Находим переменные
    for varName in code:gmatch("local%s+(%w+)%s*=") do
        table.insert(analysis.variables, varName)
    end
    
    -- Находим вызовы RemoteEvent
    for remoteName in code:gmatch("(%w+):Fire") do
        table.insert(analysis.remotes, remoteName)
    end
    
    return analysis
end

function Eclipse:LearnFunction(funcName, funcType)
    if not self.Knowledge.functions[funcName] then
        self.Knowledge.functions[funcName] = {
            type = funcType,
            callCount = 0,
            discovered = os.time(),
            context = {},
            importance = 1,
            description = "" -- Описание от пользователя
        }
    end
    self.Knowledge.functions[funcName].callCount = self.Knowledge.functions[funcName].callCount + 1
    self.Knowledge.functions[funcName].importance = math.min(self.Knowledge.functions[funcName].callCount / 2, 10)
end

-- Smart Response Generation with Learning
function Eclipse:GenerateSmartResponse(topic, context)
    -- Используем накопленные знания для генерации ответа
    local knowledge = self.Knowledge.gameData[topic]
    
    if knowledge and knowledge.mentions > 3 then
        -- Если мы много раз обсуждали эту тему, даем экспертный ответ
        return "Основываясь на моих знаниях о " .. topic .. " (изучено " .. knowledge.mentions .. " раз), могу сказать: " .. context
    end
    
    return context
end

-- Pattern Recognition
function Eclipse:RecognizePattern(message)
    local patterns = {
        question = message:match("^%s*[Кк]ак") or message:match("^%s*[Чч]то") or message:match("^%s*[Пп]очему"),
        command = message:match("^%s*[Нн]айди") or message:match("^%s*[Пп]окажи") or message:match("^%s*[Аа]нализируй"),
        learning = message:match("[Зз]апомни") or message:match("[Нн]аучись") or message:match("[Зз]апиши"),
        code = message:match("function") or message:match("local") or message:match("=")
    }
    
    return patterns
end

-- Persistent Storage System
function Eclipse:SaveKnowledge()
    if not self.Config.PersistentMemory then
        return false
    end
    
    local success, err = pcall(function()
        local saveData = {
            version = self.Version,
            timestamp = os.time(),
            knowledge = self.Knowledge,
            context = self.CurrentContext,
            stats = {
                totalPatterns = 0,
                totalRemotes = 0,
                totalFunctions = 0
            }
        }
        
        for _ in pairs(self.Knowledge.patterns) do
            saveData.stats.totalPatterns = saveData.stats.totalPatterns + 1
        end
        for _ in pairs(self.Knowledge.remotes) do
            saveData.stats.totalRemotes = saveData.stats.totalRemotes + 1
        end
        for _ in pairs(self.Knowledge.functions) do
            saveData.stats.totalFunctions = saveData.stats.totalFunctions + 1
        end
        
        local jsonData = HttpService:JSONEncode(saveData)
        
        if writefile then
            writefile(self.Storage.SaveKey .. ".json", jsonData)
            self.Storage.LastSave = os.time()
            
            -- Показываем индикатор сохранения
            if self.LearningIndicator then
                self.LearningIndicator.Text = "💾 Saved"
                self.LearningIndicator.BackgroundColor3 = self.Config.Theme.Success
                self.LearningIndicator.Visible = true
                
                task.delay(2, function()
                    if self.LearningIndicator then
                        self.LearningIndicator.Visible = false
                    end
                end)
            end
            
            return true
        end
        
        return false
    end)
    
    if success then
        print("✅ Eclipse AI: Знания сохранены")
        return true
    else
        return false
    end
end

function Eclipse:LoadKnowledge()
    if not self.Config.PersistentMemory then
        return false
    end
    
    local success, result = pcall(function()
        if readfile and isfile and isfile(self.Storage.SaveKey .. ".json") then
            local jsonData = readfile(self.Storage.SaveKey .. ".json")
            local saveData = HttpService:JSONDecode(jsonData)
            
            if saveData.version == self.Version then
                self.Knowledge = saveData.knowledge or self.Knowledge
                self.CurrentContext = saveData.context or self.CurrentContext
                
                print("✅ Eclipse AI: Знания загружены!")
                print("📊 Паттернов: " .. (saveData.stats.totalPatterns or 0))
                print("📊 RemoteEvents: " .. (saveData.stats.totalRemotes or 0))
                print("📊 Функций: " .. (saveData.stats.totalFunctions or 0))
                
                return true
            end
        end
        
        return false
    end)
    
    if success and result then
        return true
    else
        print("ℹ️ Eclipse AI: Начинаю с чистого листа")
        return false
    end
end

function Eclipse:AutoSave()
    if not self.Storage.AutoSaveEnabled then
        return
    end
    
    task.spawn(function()
        while self.Storage.AutoSaveEnabled do
            task.wait(self.Config.SaveInterval)
            
            local hasData = false
            for _ in pairs(self.Knowledge.patterns) do
                hasData = true
                break
            end
            
            if hasData then
                self:SaveKnowledge()
            end
        end
    end)
end

function Eclipse:ExportKnowledge()
    local export = "# Eclipse AI Knowledge Export\n"
    export = export .. "Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n"
    
    export = export .. "## Learned Patterns\n"
    for keyword, data in pairs(self.Knowledge.patterns) do
        export = export .. "- " .. keyword .. ": " .. data.count .. " mentions\n"
    end
    
    export = export .. "\n## Remote Events\n"
    for name, data in pairs(self.Knowledge.remotes) do
        export = export .. "- " .. name .. " (" .. data.type .. "): " .. data.usageCount .. " uses\n"
    end
    
    export = export .. "\n## Functions\n"
    for name, data in pairs(self.Knowledge.functions) do
        export = export .. "- " .. name .. " (" .. data.type .. "): " .. data.callCount .. " calls\n"
    end
    
    return export
end

-- Commands
Eclipse.Commands = {
    ["/analyze"] = function(self)
        local info = self:AnalyzeGame()
        local response = string.format(
            "📊 Анализ игры:\n• Название: %s\n• Place ID: %s\n• Игроков: %d",
            info.name, info.placeId, info.players
        )
        self:AddMessage("Eclipse", response, false)
    end,
    
    ["/remotes"] = function(self)
        local remotes = self:FindRemotes()
        if #remotes == 0 then
            self:AddMessage("Eclipse", "RemoteEvents не найдены.", false)
        else
            local response = "🔍 Найденные RemoteEvents:\n"
            for i, remote in ipairs(remotes) do
                response = response .. string.format("• %s (%s)\n", remote.name, remote.type)
                if i >= 10 then
                    response = response .. "... и еще " .. (#remotes - 10) .. " объектов"
                    break
                end
            end
            self:AddMessage("Eclipse", response, false)
        end
    end,
    
    ["/structure"] = function(self)
        local structure = self:GetGameStructure()
        local response = "🏗️ Структура игры:\n"
        for service, data in pairs(structure) do
            response = response .. string.format("• %s: %d объектов\n", service, data.descendants)
        end
        self:AddMessage("Eclipse", response, false)
    end,
    
    ["/clear"] = function(self)
        for _, child in ipairs(MessagesContainer:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        self.ChatHistory = {}
        self:AddSystemMessage("Чат очищен.")
    end,
    
    ["/learn"] = function(self)
        self:AddMessage("Eclipse", self:ShowKnowledge(), false)
    end,
    
    ["/answers"] = function(self)
        local customCount = 0
        for _ in pairs(self.Knowledge.customAnswers) do
            customCount = customCount + 1
        end
        
        if customCount == 0 then
            self:AddMessage("Eclipse", "📖 Я еще не выучил ни одного ответа. Научи меня!\n\nПример:\nЗапомни: Что такое античит? Система защиты от читеров", false)
            return
        end
        
        local response = "📖 Выученные ответы (" .. customCount .. "):\n\n"
        local count = 0
        
        for question, data in pairs(self.Knowledge.customAnswers) do
            count = count + 1
            local latestAnswer = data.answers[#data.answers].text
            response = response .. count .. ". " .. data.question .. "?\n"
            response = response .. "   → " .. latestAnswer:sub(1, 50)
            if #latestAnswer > 50 then
                response = response .. "..."
            end
            response = response .. "\n\n"
            
            if count >= 10 then
                response = response .. "... и еще " .. (customCount - 10) .. " ответов"
                break
            end
        end
        
        self:AddMessage("Eclipse", response, false)
    end,
    
    ["/teach"] = function(self)
        self:AddMessage("Eclipse", [[📖 Режим обучения активирован!

Научи меня чему-то новому. Примеры:
• "Запомни: RemoteEvent 'Damage' используется для урона"
• "В этой игре прыжок работает через функцию Jump()"
• "Переменная PlayerData хранит статистику игрока"

Я быстро учусь и запоминаю все, что ты мне говоришь!]], false)
    end,
    
    ["/reset"] = function(self)
        self.Knowledge = {
            patterns = {},
            gameData = {},
            functions = {},
            remotes = {},
            contexts = {},
            feedback = {},
            customAnswers = {}
        }
        self.CurrentContext = {
            game = nil,
            lastTopic = nil,
            conversationDepth = 0,
            analyzedObjects = {},
            waitingForAnswer = false,
            lastQuestion = nil
        }
        
        -- Удаляем сохранение
        if writefile and isfile and isfile(self.Storage.SaveKey .. ".json") then
            pcall(function()
                delfile(self.Storage.SaveKey .. ".json")
            end)
        end
        
        self:AddSystemMessage("🔄 База знаний сброшена. Начинаю обучение заново!")
    end,
    
    ["/save"] = function(self)
        local success = self:SaveKnowledge()
        if success then
            self:AddSystemMessage("💾 Знания успешно сохранены!")
        else
            self:AddSystemMessage("⚠️ Не удалось сохранить знания. Возможно, executor не поддерживает writefile.")
        end
    end,
    
    ["/export"] = function(self)
        local export = self:ExportKnowledge()
        
        if writefile then
            local filename = "EclipseAI_Export_" .. os.time() .. ".txt"
            writefile(filename, export)
            self:AddSystemMessage("📤 Знания экспортированы в файл: " .. filename)
        else
            self:AddSystemMessage("📋 Экспорт:\n" .. export:sub(1, 500) .. "\n... (слишком длинно для чата)")
        end
    end,
    
    ["/stats"] = function(self)
        local stats = {
            patterns = 0,
            remotes = 0,
            functions = 0,
            concepts = 0
        }
        
        for _ in pairs(self.Knowledge.patterns) do stats.patterns = stats.patterns + 1 end
        for _ in pairs(self.Knowledge.remotes) do stats.remotes = stats.remotes + 1 end
        for _ in pairs(self.Knowledge.functions) do stats.functions = stats.functions + 1 end
        for _ in pairs(self.Knowledge.gameData) do stats.concepts = stats.concepts + 1 end
        
        local lastSave = self.Storage.LastSave > 0 and os.date("%H:%M:%S", self.Storage.LastSave) or "Никогда"
        
        local response = string.format([[📊 Статистика памяти:

💭 Паттернов: %d
🔌 RemoteEvents: %d
⚙️ Функций: %d
📚 Концепций: %d
💾 Последнее сохранение: %s
🔄 Автосохранение: %s

Всего записей: %d]], 
            stats.patterns, stats.remotes, stats.functions, stats.concepts,
            lastSave,
            self.Storage.AutoSaveEnabled and "Включено" or "Выключено",
            stats.patterns + stats.remotes + stats.functions + stats.concepts
        )
        
        self:AddMessage("Eclipse", response, false)
    end,
    
    ["/help"] = function(self)
        local response = [[📋 Доступные команды:
/analyze - Анализ текущей игры
/remotes - Поиск RemoteEvents
/structure - Структура игры
/learn - Показать базу знаний
/answers - Список выученных ответов
/teach - Режим обучения
/stats - Статистика памяти
/save - Сохранить знания
/export - Экспорт знаний в файл
/reset - Сбросить знания
/clear - Очистить чат
/help - Список команд]]
        self:AddMessage("Eclipse", response, false)
    end
}

-- Override SendMessage to handle commands
local originalSendMessage = Eclipse.SendMessage
function Eclipse:SendMessage()
    local message = InputBox.Text
    if message == "" or message:match("^%s*$") then
        return
    end
    
    -- Check for commands
    if message:sub(1, 1) == "/" then
        local command = message:match("^/%S+")
        if self.Commands[command] then
            InputBox.Text = ""
            self.Commands[command](self)
            return
        end
    end
    
    -- Call original function
    originalSendMessage(self)
end

-- Initialize
function Eclipse:Init()
    print("🌙 Eclipse AI v" .. self.Version .. " загружается...")
    
    -- Загружаем сохраненные знания
    self:LoadKnowledge()
    
    -- Создаем GUI
    self:CreateGui()
    self:ToggleGui()
    
    -- Запускаем автосохранение
    self:AutoSave()
    
    print("✅ Eclipse AI готов к работе!")
    print("💡 Нажми на кнопку с луной, чтобы открыть интерфейс")
    
    if self.Config.PersistentMemory then
        print("💾 Постоянная память включена - все знания сохраняются автоматически")
    end
end

-- Auto-start
Eclipse:Init()

return Eclipse
