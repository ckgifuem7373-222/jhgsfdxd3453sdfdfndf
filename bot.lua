local HttpService = game:GetService("HttpService")
local FileName = "bot_knowledge.json"

-- Таблица ответов по умолчанию
local KnowledgeBase = {
    ["привет"] = {"Привет!", "Хай!", "Ку!"},
    ["ты кто"] = {"Я обучаемый бот через Xeno."}
}

-- Функция загрузки памяти из файла на диске (папка workspace в Xeno)
local function loadMemory()
    if isfile(FileName) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
        if success then KnowledgeBase = data end
    end
end

-- Функция сохранения памяти
local function saveMemory()
    writefile(FileName, HttpService:JSONEncode(KnowledgeBase))
end

-- Логика обучения и ответов
local lastMsg = ""

local function onChat(msg, speaker)
    if speaker == game.Players.LocalPlayer.Name then 
        lastMsg = msg:lower()
        return 
    end

    local input = msg:lower()
    
    -- Если бот знает ответ
    if KnowledgeBase[input] then
        local responses = KnowledgeBase[input]
        local randomResponse = responses[math.random(1, #responses)]
        task.wait(1)
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(randomResponse, "All")
    
    -- Если бот не знает, он учится у последнего сообщения игрока
    elseif lastMsg ~= "" then
        if not KnowledgeBase[lastMsg] then KnowledgeBase[lastMsg] = {} end
        table.insert(KnowledgeBase[lastMsg], msg)
        saveMemory()
        print("Запомнил: '" .. lastMsg .. "' -> '" .. msg .. "'")
        lastMsg = "" -- сброс, чтобы не учить одно и то же
    end
end

-- Подключение к чату
game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(data)
    onChat(data.Message, data.FromSpeaker)
end)

loadMemory()
print("Бот активен. Все знания сохраняются в " .. FileName)
