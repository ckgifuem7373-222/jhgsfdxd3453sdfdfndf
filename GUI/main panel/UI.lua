-- Eclipse AI ClickGui
-- github link to UI.lua: https://raw.githubusercontent.com/ckgifuem7373-222/jhgsfdxd3453sdfdfndf/refs/heads/main/GUI/main%20panel/UI.lua

local EclipseAI = {}

-- Конфигурация
local CONFIG = {
	MAIN_COLOR = Color3.fromRGB(30, 30, 35),
	ACCENT_COLOR = Color3.fromRGB(138, 43, 226), -- Фиолетовый акцент
	SECONDARY_COLOR = Color3.fromRGB(45, 45, 50),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	ICON_COLOR = Color3.fromRGB(255, 255, 255), -- Белый цвет для иконок
	
	LOGO_URL = "https://github.com/ckgifuem7373-222/jhgsfdxd3453sdfdfndf/blob/main/GUI/assets/logo.png?raw=true",
	ICONS = {
		BRAIN = "https://github.com/ckgifuem7373-222/jhgsfdxd3453sdfdfndf/blob/main/GUI/assets/lucide%20icons/aimodel(brain).png?raw=true",
		BOT = "https://github.com/ckgifuem7373-222/jhgsfdxd3453sdfdfndf/blob/main/GUI/assets/lucide%20icons/bot.png?raw=true",
		CHAT = "https://github.com/ckgifuem7373-222/jhgsfdxd3453sdfdfndf/blob/main/GUI/assets/lucide%20icons/message-circle.png?raw=true",
		RADIO = "https://github.com/ckgifuem7373-222/jhgsfdxd3453sdfdfndf/blob/main/GUI/assets/lucide%20icons/radio-tower.png?raw=true",
		SEND = "https://github.com/ckgifuem7373-222/jhgsfdxd3453sdfdfndf/blob/main/GUI/assets/lucide%20icons/send.png?raw=true",
		SETTINGS = "https://github.com/ckgifuem7373-222/jhgsfdxd3453sdfdfndf/blob/main/GUI/assets/lucide%20icons/settings.png?raw=true"
	}
}

-- Хранилище чатов
local Chats = {}
local CurrentChatId = nil

-- Создание главного GUI
function EclipseAI:CreateGui()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "EclipseAI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Главный фрейм
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 700, 0, 500)
	MainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
	MainFrame.BackgroundColor3 = CONFIG.MAIN_COLOR
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui
	
	-- Скругление углов
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 12)
	Corner.Parent = MainFrame
	
	-- Тень
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
	
	self:CreateTopBar(MainFrame)
	self:CreateSidebar(MainFrame)
	self:CreateChatArea(MainFrame)
	self:CreateInputArea(MainFrame)
	
	-- Делаем GUI перетаскиваемым
	self:MakeDraggable(MainFrame)
	
	return ScreenGui
end

-- Верхняя панель с логотипом
function EclipseAI:CreateTopBar(parent)
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, 50)
	TopBar.BackgroundColor3 = CONFIG.SECONDARY_COLOR
	TopBar.BorderSizePixel = 0
	TopBar.Parent = parent
	
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 12)
	Corner.Parent = TopBar
	
	-- Лого
	local Logo = Instance.new("ImageLabel")
	Logo.Name = "Logo"
	Logo.Size = UDim2.new(0, 35, 0, 35)
	Logo.Position = UDim2.new(0, 10, 0.5, -17.5)
	Logo.BackgroundTransparency = 1
	Logo.Image = CONFIG.LOGO_URL
	Logo.Parent = TopBar
	
	-- Название
	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Size = UDim2.new(0, 200, 1, 0)
	Title.Position = UDim2.new(0, 50, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "Eclipse AI"
	Title.TextColor3 = CONFIG.TEXT_COLOR
	Title.TextSize = 20
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = TopBar
	
	-- Кнопка настроек
	local SettingsBtn = self:CreateIconButton(CONFIG.ICONS.SETTINGS, UDim2.new(1, -45, 0.5, -15), UDim2.new(0, 30, 0, 30))
	SettingsBtn.Parent = TopBar
	
	return TopBar
end

-- Боковая панель с чатами
function EclipseAI:CreateSidebar(parent)
	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.Size = UDim2.new(0, 180, 1, -50)
	Sidebar.Position = UDim2.new(0, 0, 0, 50)
	Sidebar.BackgroundColor3 = CONFIG.SECONDARY_COLOR
	Sidebar.BorderSizePixel = 0
	Sidebar.Parent = parent
	
	-- Заголовок "Чаты"
	local ChatsHeader = Instance.new("Frame")
	ChatsHeader.Name = "ChatsHeader"
	ChatsHeader.Size = UDim2.new(1, 0, 0, 40)
	ChatsHeader.BackgroundTransparency = 1
	ChatsHeader.Parent = Sidebar
	
	local ChatsIcon = Instance.new("ImageLabel")
	ChatsIcon.Size = UDim2.new(0, 20, 0, 20)
	ChatsIcon.Position = UDim2.new(0, 10, 0.5, -10)
	ChatsIcon.BackgroundTransparency = 1
	ChatsIcon.Image = CONFIG.ICONS.CHAT
	ChatsIcon.ImageColor3 = CONFIG.ICON_COLOR
	ChatsIcon.Parent = ChatsHeader
	
	local ChatsLabel = Instance.new("TextLabel")
	ChatsLabel.Size = UDim2.new(1, -40, 1, 0)
	ChatsLabel.Position = UDim2.new(0, 35, 0, 0)
	ChatsLabel.BackgroundTransparency = 1
	ChatsLabel.Text = "Чаты"
	ChatsLabel.TextColor3 = CONFIG.TEXT_COLOR
	ChatsLabel.TextSize = 16
	ChatsLabel.Font = Enum.Font.GothamBold
	ChatsLabel.TextXAlignment = Enum.TextXAlignment.Left
	ChatsLabel.Parent = ChatsHeader
	
	-- Список чатов
	local ChatsList = Instance.new("ScrollingFrame")
	ChatsList.Name = "ChatsList"
	ChatsList.Size = UDim2.new(1, 0, 1, -90)
	ChatsList.Position = UDim2.new(0, 0, 0, 40)
	ChatsList.BackgroundTransparency = 1
	ChatsList.BorderSizePixel = 0
	ChatsList.ScrollBarThickness = 4
	ChatsList.ScrollBarImageColor3 = CONFIG.ACCENT_COLOR
	ChatsList.Parent = Sidebar
	
	local ListLayout = Instance.new("UIListLayout")
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayout.Padding = UDim.new(0, 5)
	ListLayout.Parent = ChatsList
	
	-- Кнопка "Новый чат"
	local NewChatBtn = Instance.new("TextButton")
	NewChatBtn.Name = "NewChatBtn"
	NewChatBtn.Size = UDim2.new(1, -20, 0, 35)
	NewChatBtn.Position = UDim2.new(0, 10, 1, -45)
	NewChatBtn.BackgroundColor3 = CONFIG.ACCENT_COLOR
	NewChatBtn.Text = "+ Новый чат"
	NewChatBtn.TextColor3 = CONFIG.TEXT_COLOR
	NewChatBtn.TextSize = 14
	NewChatBtn.Font = Enum.Font.GothamBold
	NewChatBtn.BorderSizePixel = 0
	NewChatBtn.Parent = Sidebar
	
	local BtnCorner = Instance.new("UICorner")
	BtnCorner.CornerRadius = UDim.new(0, 8)
	BtnCorner.Parent = NewChatBtn
	
	NewChatBtn.MouseButton1Click:Connect(function()
		self:CreateNewChat(ChatsList)
	end)
	
	self.ChatsList = ChatsList
	
	-- Создаем первый чат по умолчанию
	self:CreateNewChat(ChatsList)
	
	return Sidebar
end

-- Область чата
function EclipseAI:CreateChatArea(parent)
	local ChatArea = Instance.new("ScrollingFrame")
	ChatArea.Name = "ChatArea"
	ChatArea.Size = UDim2.new(1, -190, 1, -130)
	ChatArea.Position = UDim2.new(0, 185, 0, 55)
	ChatArea.BackgroundColor3 = CONFIG.MAIN_COLOR
	ChatArea.BorderSizePixel = 0
	ChatArea.ScrollBarThickness = 6
	ChatArea.ScrollBarImageColor3 = CONFIG.ACCENT_COLOR
	ChatArea.CanvasSize = UDim2.new(0, 0, 0, 0)
	ChatArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ChatArea.Parent = parent
	
	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 15)
	Padding.PaddingRight = UDim.new(0, 15)
	Padding.PaddingTop = UDim.new(0, 10)
	Padding.PaddingBottom = UDim.new(0, 10)
	Padding.Parent = ChatArea
	
	local ListLayout = Instance.new("UIListLayout")
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayout.Padding = UDim.new(0, 10)
	ListLayout.Parent = ChatArea
	
	self.ChatArea = ChatArea
	
	return ChatArea
end

-- Область ввода
function EclipseAI:CreateInputArea(parent)
	local InputArea = Instance.new("Frame")
	InputArea.Name = "InputArea"
	InputArea.Size = UDim2.new(1, -190, 0, 60)
	InputArea.Position = UDim2.new(0, 185, 1, -65)
	InputArea.BackgroundColor3 = CONFIG.SECONDARY_COLOR
	InputArea.BorderSizePixel = 0
	InputArea.Parent = parent
	
	-- Поле ввода
	local InputBox = Instance.new("TextBox")
	InputBox.Name = "InputBox"
	InputBox.Size = UDim2.new(1, -70, 0, 40)
	InputBox.Position = UDim2.new(0, 10, 0.5, -20)
	InputBox.BackgroundColor3 = CONFIG.MAIN_COLOR
	InputBox.Text = ""
	InputBox.PlaceholderText = "Напишите сообщение..."
	InputBox.TextColor3 = CONFIG.TEXT_COLOR
	InputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	InputBox.TextSize = 14
	InputBox.Font = Enum.Font.Gotham
	InputBox.TextXAlignment = Enum.TextXAlignment.Left
	InputBox.ClearTextOnFocus = false
	InputBox.MultiLine = true
	InputBox.TextWrapped = true
	InputBox.BorderSizePixel = 0
	InputBox.Parent = InputArea
	
	local InputCorner = Instance.new("UICorner")
	InputCorner.CornerRadius = UDim.new(0, 8)
	InputCorner.Parent = InputBox
	
	local InputPadding = Instance.new("UIPadding")
	InputPadding.PaddingLeft = UDim.new(0, 10)
	InputPadding.PaddingRight = UDim.new(0, 10)
	InputPadding.Parent = InputBox
	
	-- Кнопка отправки
	local SendBtn = self:CreateIconButton(CONFIG.ICONS.SEND, UDim2.new(1, -50, 0.5, -20), UDim2.new(0, 40, 0, 40))
	SendBtn.BackgroundColor3 = CONFIG.ACCENT_COLOR
	SendBtn.Parent = InputArea
	
	SendBtn.MouseButton1Click:Connect(function()
		self:SendMessage(InputBox.Text)
		InputBox.Text = ""
	end)
	
	-- Отправка по Enter
	InputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed and InputBox.Text ~= "" then
			self:SendMessage(InputBox.Text)
			InputBox.Text = ""
		end
	end)
	
	self.InputBox = InputBox
	
	return InputArea
end

-- Создание кнопки с иконкой
function EclipseAI:CreateIconButton(iconUrl, position, size)
	local Button = Instance.new("TextButton")
	Button.Size = size
	Button.Position = position
	Button.BackgroundColor3 = CONFIG.SECONDARY_COLOR
	Button.Text = ""
	Button.BorderSizePixel = 0
	
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Button
	
	local Icon = Instance.new("ImageLabel")
	Icon.Size = UDim2.new(0.6, 0, 0.6, 0)
	Icon.Position = UDim2.new(0.2, 0, 0.2, 0)
	Icon.BackgroundTransparency = 1
	Icon.Image = iconUrl
	Icon.ImageColor3 = CONFIG.ICON_COLOR
	Icon.Parent = Button
	
	-- Эффект наведения
	Button.MouseEnter:Connect(function()
		Button.BackgroundColor3 = CONFIG.ACCENT_COLOR
	end)
	
	Button.MouseLeave:Connect(function()
		Button.BackgroundColor3 = CONFIG.SECONDARY_COLOR
	end)
	
	return Button
end

-- Создание нового чата
function EclipseAI:CreateNewChat(chatsList)
	local chatId = #Chats + 1
	local chatData = {
		id = chatId,
		name = "Чат " .. chatId,
		messages = {}
	}
	
	table.insert(Chats, chatData)
	
	local ChatItem = Instance.new("TextButton")
	ChatItem.Name = "Chat_" .. chatId
	ChatItem.Size = UDim2.new(1, -10, 0, 35)
	ChatItem.BackgroundColor3 = CONFIG.MAIN_COLOR
	ChatItem.Text = chatData.name
	ChatItem.TextColor3 = CONFIG.TEXT_COLOR
	ChatItem.TextSize = 13
	ChatItem.Font = Enum.Font.Gotham
	ChatItem.TextXAlignment = Enum.TextXAlignment.Left
	ChatItem.BorderSizePixel = 0
	ChatItem.Parent = chatsList
	
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = ChatItem
	
	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 10)
	Padding.Parent = ChatItem
	
	ChatItem.MouseButton1Click:Connect(function()
		self:SwitchToChat(chatId)
	end)
	
	-- Автоматически переключаемся на новый чат
	self:SwitchToChat(chatId)
	
	return chatData
end

-- Переключение между чатами
function EclipseAI:SwitchToChat(chatId)
	CurrentChatId = chatId
	
	-- Обновляем визуальное выделение
	for _, child in pairs(self.ChatsList:GetChildren()) do
		if child:IsA("TextButton") then
			if child.Name == "Chat_" .. chatId then
				child.BackgroundColor3 = CONFIG.ACCENT_COLOR
			else
				child.BackgroundColor3 = CONFIG.MAIN_COLOR
			end
		end
	end
	
	-- Очищаем область чата
	for _, child in pairs(self.ChatArea:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Загружаем сообщения текущего чата
	local chatData = Chats[chatId]
	if chatData then
		for _, message in ipairs(chatData.messages) do
			self:DisplayMessage(message.text, message.isUser)
		end
	end
end

-- Отправка сообщения
function EclipseAI:SendMessage(text)
	if text == "" or not CurrentChatId then return end
	
	local chatData = Chats[CurrentChatId]
	if not chatData then return end
	
	-- Сохраняем сообщение пользователя
	table.insert(chatData.messages, {
		text = text,
		isUser = true
	})
	
	-- Отображаем сообщение
	self:DisplayMessage(text, true)
	
	-- Здесь будет вызов нейросети
	-- Пока что делаем заглушку
	task.wait(0.5)
	local aiResponse = "Привет! Я Eclipse AI. Скоро я смогу помогать тебе с анализом игры и созданием скриптов!"
	
	table.insert(chatData.messages, {
		text = aiResponse,
		isUser = false
	})
	
	self:DisplayMessage(aiResponse, false)
end

-- Отображение сообщения
function EclipseAI:DisplayMessage(text, isUser)
	local MessageFrame = Instance.new("Frame")
	MessageFrame.Size = UDim2.new(1, 0, 0, 0)
	MessageFrame.BackgroundTransparency = 1
	MessageFrame.AutomaticSize = Enum.AutomaticSize.Y
	MessageFrame.Parent = self.ChatArea
	
	local MessageBubble = Instance.new("Frame")
	MessageBubble.Size = UDim2.new(0.7, 0, 0, 0)
	MessageBubble.Position = isUser and UDim2.new(0.3, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
	MessageBubble.BackgroundColor3 = isUser and CONFIG.ACCENT_COLOR or CONFIG.SECONDARY_COLOR
	MessageBubble.BorderSizePixel = 0
	MessageBubble.AutomaticSize = Enum.AutomaticSize.Y
	MessageBubble.Parent = MessageFrame
	
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 10)
	Corner.Parent = MessageBubble
	
	local MessageText = Instance.new("TextLabel")
	MessageText.Size = UDim2.new(1, -20, 0, 0)
	MessageText.Position = UDim2.new(0, 10, 0, 10)
	MessageText.BackgroundTransparency = 1
	MessageText.Text = text
	MessageText.TextColor3 = CONFIG.TEXT_COLOR
	MessageText.TextSize = 13
	MessageText.Font = Enum.Font.Gotham
	MessageText.TextXAlignment = Enum.TextXAlignment.Left
	MessageText.TextYAlignment = Enum.TextYAlignment.Top
	MessageText.TextWrapped = true
	MessageText.AutomaticSize = Enum.AutomaticSize.Y
	MessageText.Parent = MessageBubble
	
	local Padding = Instance.new("UIPadding")
	Padding.PaddingBottom = UDim.new(0, 10)
	Padding.Parent = MessageBubble
end

-- Делаем GUI перетаскиваемым
function EclipseAI:MakeDraggable(frame)
	local dragging, dragInput, dragStart, startPos
	
	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)
	
	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- Инициализация
function EclipseAI:Init()
	local gui = self:CreateGui()
	gui.Parent = game:GetService("CoreGui")
	print("Eclipse AI загружен!")
end

return EclipseAI
