-- Grow a Garden: Stock Bot Script (Discord Webhook)
-- Version: 1.1 - เพิ่มภาพใหญ่ตกแต่ง Embed

-- ✅ CONFIG
_G.Enabled = true
_G.Layout = {
    ["ROOT/SeedStock/Stocks"] = {
        title = "🌱 SEEDS STOCK",
        color = 65280,
        webhook = "https://discord.com/api/webhooks/1388574453847298138/Gnuh0k2HjsLpxNuvZT6fnO3yafRYZ2sTK3LeKgJEkrpq1fr9kN_H6dXv3c2eRnU4qo98",
        image = "https://cdn.discordapp.com/attachments/1217027368825262144/1388582267881914568/1717516914963.png?ex=68618183&is=68603003&hm=206fa1db6e88a49360dfe2086dc5d65555a543692b37dd7efd8fba13019cb917&" -- ตัวอย่างภาพ (เปลี่ยนได้)
    },
    ["ROOT/PetEggStock/Stocks"] = {
        title = "🥚 EGG STOCK",
        color = 16776960,
        webhook = "https://discord.com/api/webhooks/1388574964629635072/4ctVFDUBW0caH0L9dSOx3dPCxyH48nPY7O2uAEm7D8xUDkvHRfuOAdKrtJQo7Kf7M-t4",
        image = "https://cdn.discordapp.com/attachments/1217027368825262144/1388582267881914568/1717516914963.png?ex=68618183&is=68603003&hm=206fa1db6e88a49360dfe2086dc5d65555a543692b37dd7efd8fba13019cb917&"
    },
    ["ROOT/GearStock/Stocks"] = {
        title = "🛠️ GEAR STOCK",
        color = 16753920,
        webhook = "https://discord.com/api/webhooks/1388575214421544961/tSJoMnsGcoG2KIEFuVfmpWjsbgD1npg8aivX6TJqmKuGBt7FNjAoXCXlXdYxeXwkg5HA",
        image = "https://cdn.discordapp.com/attachments/1217027368825262144/1388582267881914568/1717516914963.png?ex=68618183&is=68603003&hm=206fa1db6e88a49360dfe2086dc5d65555a543692b37dd7efd8fba13019cb917&"
    },
    ["ROOT/CosmeticStock/ItemStocks"] = {
        title = "🎨 COSMETIC STOCK",
        color = 16737792,
        webhook = "https://discord.com/api/webhooks/1388575549919854612/deq8UA0uu_7rIario0ZbKniJClY8A_dYeRuSdNocQD0auPrzX0pjgP-VoGUKNPLbKW7v",
        image = "https://cdn.discordapp.com/attachments/1217027368825262144/1388582267881914568/1717516914963.png?ex=68618183&is=68603003&hm=206fa1db6e88a49360dfe2086dc5d65555a543692b37dd7efd8fba13019cb917&"
    },
    ["ROOT/EventShopStock/Stocks"] = {
        title = "🎁 EVENT STOCK",
        color = 10027263,
        webhook = "https://discord.com/api/webhooks/1388575755058810971/aaVAXtLx6MzX29lVpDtLWBQdZ1-jkWGiAfJ90ClLahrDkBSXPvVMMq7xitU0X1wO9f7T",
        image = "https://cdn.discordapp.com/attachments/1217027368825262144/1388582267881914568/1717516914963.png?ex=68618183&is=68603003&hm=206fa1db6e88a49360dfe2086dc5d65555a543692b37dd7efd8fba13019cb917&"
    }
}

-- 📡 SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local DataStream = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("DataStream")

-- 🌐 HTTP fallback
local requestFunc = http_request or request or syn and syn.request
if not requestFunc then
    warn("[❌] HTTP request ไม่รองรับบน executor นี้")
end

-- 🔁 แปลง stock object เป็นข้อความ
local function GetStockString(stock)
    local s = ""
    for name, data in pairs(stock) do
        local display = data.EggName or name
        s ..= (`{display} x{data.Stock}\n`)
    end
    return s
end

-- 📤 ส่ง webhook แยก embed ต่อหมวด พร้อมรูป (image)
local function SendSingleEmbed(title, bodyText, color, webhookUrl, imageUrl)
    if not _G.Enabled or not requestFunc then return end
    if bodyText == "" or not webhookUrl then return end

    local embed = {
        title = title,
        description = bodyText,
        color = color,
        timestamp = DateTime.now():ToIsoDate(),
        footer = {
            text = "Grow a Garden Stock Bot (By RTaO)"
        }
    }

    if imageUrl then
        embed.image = { url = imageUrl }
    end

    local body = {
        embeds = {embed}
    }

    local success, result = pcall(function()
        return requestFunc({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(body)
        })
    end)

    if success and result and (result.StatusCode == 200 or result.StatusCode == 204) then
        print("[📤] ส่ง " .. title .. " ไปยัง Webhook เรียบร้อย")
    else
        warn("[❌] ส่ง " .. title .. " ไม่สำเร็จ: " .. tostring(result and result.StatusCode or "Unknown Error"))
    end
end

-- 🔍 ค้นหาข้อมูล stock ตาม path
local function GetPacket(data, key)
    for _, packet in ipairs(data) do
        if packet[1] == key then
            return packet[2]
        end
    end
end

-- 📥 รับ Event แล้วแยกส่ง Embed ตามหมวด
DataStream.OnClientEvent:Connect(function(eventType, profile, data)
    if eventType ~= "UpdateData" then return end
    if not profile:find(LocalPlayer.Name) then return end

    for path, layout in pairs(_G.Layout) do
        local stockData = GetPacket(data, path)
        if stockData then
            local stockStr = GetStockString(stockData)
            if stockStr ~= "" then
                SendSingleEmbed(layout.title, stockStr, layout.color, layout.webhook, layout.image)
            end
        end
    end
end)

print("[✅] Stock Checker พร้อมทำงาน (แยก Webhook + ภาพใหญ่ Embed)")
