local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local FileName = "neural_synapse_v7.json"

-- СТРУКТУРА НЕЙРОСЕТИ
local Brain = {
    Nodes = {}, -- Слова/Понятия
    Synapses = {} -- Связи между ними { ["слово1_слово2"] = вес }
}

local function save() writefile(FileName, HttpService:JSONEncode(Brain)) end
if isfile(FileName) then 
    local s, d = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
    if s then Brain = d end
end

-- ЛОГИКА НЕЙРОНОВ
local function activateNeurons(input, output)
    input = input:lower()
    output = output:lower()
    
    local key = input .. "_" .. output
    Brain.Synapses[key] = (Brain.Synapses[key] or 0) + 1 -- Усиливаем связь (обучение)
    
    if not table.find(Brain.Nodes, input) then table.insert(Brain.Nodes, input) end
    if not table.find(Brain.Nodes, output) then table.insert(Brain.Nodes, output) end
    save()
end

local function getStrongestResponse(input)
    input = input:lower()
    local bestResp = nil
    local maxWeight = 0
    
    for key, weight in pairs(Brain.Synapses) do
        local trigger, response = key:match("^(.-)_(.-)$")
        if trigger == input and weight > maxWeight then
            maxWeight = weight
            bestResp = response
        end
    end
    return bestResp
end

-- ГРАФИЧЕСКИЙ ИНТЕРФЕЙС (GUI)
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 350, 0, 450)
Main.Position = UDim2.new(0.5, -175, 0.5, -225)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main)

-- Resize Handle
local ResizeBtn = Instance.new("ImageButton", Main)
ResizeBtn.Size = UDim2.new(0, 20, 0, 20)
ResizeBtn.Position = UDim2.new(1, -20, 1, -20)
ResizeBtn.Image = "rbxassetid://3854515233"
ResizeBtn.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "🧠 NEURAL SYNAPSE v7.0"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
Instance.new("UICorner", Title)

local BrainActivity = Instance.new("Frame", Main)
BrainActivity.Size = UDim2.new(0.9, 0, 0, 4)
BrainActivity.Position = UDim2.new(0.05, 0, 0, 42)
BrainActivity.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
BrainActivity.BorderSizePixel = 0

local Log = Instance.new("ScrollingFrame", Main)
Log.Size = UDim2.new(0.9, 0, 0.45, 0)
Log.Position = UDim2.new(0.05, 0, 0.15, 0)
Log.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
Instance.new("UIListLayout", Log)

local Input = Instance.new("TextBox", Main)
Input.Size = UDim2.new(0.9, 0, 0, 40)
Input.Position = UDim2.new(0.05, 0, 0.65, 0)
Input.PlaceholderText = "Обучай нейроны здесь..."
Input.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Input.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", Input)

-- ЛОГИКА ИЗМЕНЕНИЯ РАЗМЕРА
local resizing = false
ResizeBtn.MouseButton1Down:Connect(function() resizing = true end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end end)
UserInputService.InputChanged:Connect(function(i)
    if resizing and i.UserInputType == Enum.UserInputType.MouseMovement then
        local m = UserInputService:GetMouseLocation()
        Main.Size = UDim2.new(0, math.clamp(m.X - Main.AbsolutePosition.X, 250, 800), 0, math.clamp(m.Y - Main.AbsolutePosition.Y, 300, 800))
    end
end)

-- РАБОТА С СЕТЬЮ
local lastInput = ""

local function addLog(t, c)
    local l = Instance.new("TextLabel", Log)
    l.Size = UDim2.new(1, 0, 0, 20)
    l.Text = " " .. t
    l.TextColor3 = c or Color3.new(1,1,1)
    l.BackgroundTransparency = 1
    l.TextXAlignment = "Left"
    Log.CanvasPosition = Vector2.new(0, 9999)
end

local function think(msg)
    BrainActivity:TweenSize(UDim2.new(0.9, 0, 0, 6), "Out", "Quad", 0.1)
    task.wait(0.2)
    BrainActivity:TweenSize(UDim2.new(0.9, 0, 0, 4), "Out", "Quad", 0.5)

    local response = getStrongestResponse(msg)
    
    if response then
        addLog("Нейрон: " .. response, Color3.new(0, 1, 0.5))
    else
        if lastInput ~= "" then
            activateNeurons(lastInput, msg)
            addLog("[Связь укреплена]", Color3.new(1, 1, 0))
        end
        addLog("ИИ: Нейроны не активированы...", Color3.new(1, 0.4, 0.4))
    end
    lastInput = msg:lower()
end

Input.FocusLost:Connect(function(e)
    if e and Input.Text ~= "" then
        addLog("Вы: " .. Input.Text, Color3.new(0.7, 0.7, 1))
        think(Input.Text)
        Input.Text = ""
    end
end)

print("Neural Synapse v7.0 Loaded. Nodes: " .. #Brain.Nodes)
