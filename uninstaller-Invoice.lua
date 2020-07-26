local term = require("term")
local component = require("component")
local math = require("math")
local text = require("text")
local net = require("internet")
local serialization = require("serialization")
local fs = require("filesystem")
local gpu = component.gpu

if not component.isAvailable("internet") then
    io.stderr:write("This program requires an internet card to run.")
    os.exit()
end

local repositoryName = "OC-Invoice"
local ownerName = "Deleranax"
local branch = "master"
local baseUrl = "https://raw.githubusercontent.com/"

local blue = 0x006DC0
local white = 0xFFFFFF
local black = 0x000000
local nblack = 0x5A5A5A
local gray = 0xE1E1E1
local lightGray = 0xF0F0F0
local green = 0x00B640

local scrolltmp = 0

local buttonList = {}
local manifest = {}
local rmList = {}

local w, h = gpu.getResolution()
gpu.getResolution(math.max(w, 50), math.max(h, 16))

w, h = gpu.getResolution()
local bx = 1
local by = 1

if w > 50 then
    bx = math.floor((w - 50)/2)
end

if h > 16 then
    by = math.floor((h - 16)/2)
end

function lwrite(x, y, mx, str, offset, limit)
    offset = offset or 0
    strs = text.tokenize(str)
    local txt = ""
    local dy = 0
    for k, v in pairs(strs) do
        local otxt = txt
        txt = txt..v.." "
        if limit ~= nil then
            if dy >= limit then
                return dy +1
            end
        end
        if txt:len() >= mx or string.find(txt, "\n") ~= nil then
            txt = string.gsub(txt, "\n", "")
            if offset <= 0 then
                gpu.set(x, y+dy, otxt)
                dy = dy + 1
                txt = v.." "
            else
                offset = offset - 1
                txt = v.." "
            end
        end
    end
    gpu.set(x, y+dy, txt)
    return dy +1
end

function addButton(str, f)
    str = " "..str.." "
    x = bx + 46 - str:len()
    for k,v in pairs(buttonList) do
        x = x - 2 - v[3]
    end
    y = by + 14
    dx = str:len()
    
    gpu.setBackground(lightGray)
    gpu.setForeground(nblack)
    table.insert(buttonList, {x, y, dx, f})
    gpu.set(x, y, str)
end

function getOnlineData(url)
    local result, response = pcall(net.request, url)
    if result then
        local str = ""
        for chunk in response do
            str = str..chunk
        end
        local result, rt = pcall(serialization.unserialize, str)
        if result then
            return rt
        else
            gpu.setBackground(black)
            gpu.setForeground(white)
            term.clear()
            io.stderr:write("Corrupted collected installation infos. Try to rerun the setup.")
            os.exit()
        end
    else
        gpu.setBackground(black)
        gpu.setForeground(white)
        term.clear()
        io.stderr:write("Unable to collect the installation infos. Try to rerun the setup or fix internet connection issues.")
        os.exit()
    end
end

function drawWindow()
    buttonList = {}
    gpu.setBackground(white)
    gpu.setForeground(white)
    gpu.fill(bx, by, 50, 16, " ")
    
    gpu.setBackground(gray)
    gpu.fill(bx, by + 13, 50, 3, " ")
    
    gpu.setBackground(blue)
    gpu.set(bx, by, "               Temver Setup Wizard                ")
end

function drawBar(c, m)
    local nb = math.ceil((c/m) * 42)
    
    gpu.setBackground(white)
    gpu.setForeground(black)
    gpu.set(bx + 23, by + 2, math.ceil((c/m) * 100).."%")
    
    gpu.setBackground(gray)
    gpu.fill(bx + 4, by + 3, 42, 1, " ")
    gpu.setBackground(green)
    gpu.fill(bx + 4, by + 3, nb, 1, " ")
end

function cancel()
    gpu.setBackground(black)
    gpu.setForeground(white)
    term.clear()
    os.exit()
end

function lastPage()
    drawWindow()
    gpu.setForeground(black)
    gpu.setBackground(white)
    local dy = lwrite(bx + 4, by + 2, 42, "Completing the "..repositoryName.." Setup Wizard")
    
    gpu.setForeground(nblack)
    
    dy = dy + lwrite(bx + 4, by + 3 + dy, 42, "Setup has finished removing "..repositoryName.." and all these components from your computer.")
    
    dy = dy + lwrite(bx + 4, by + 4 + dy, 42, "Click Finish to exit Setup.")

    addButton("Finish", cancel)
    
    while true do
        local evs = {term.pull("touch")}
        for k, button in pairs(buttonList) do
            if evs[3] >= button[1] and evs[3] <= button[1] + button[3] and evs[4] == button[2] then
                button[4]()
                break
            end
        end
    end
end

function uninstall()
    manifest = getOnlineData(baseUrl.."/"..ownerName.."/"..repositoryName.."/"..branch.."/manifest.txt")
    drawWindow()
    gpu.setForeground(nblack)
    gpu.setBackground(white)
    gpu.set(bx + 4, by + 5, "Uninstalling "..repositoryName.."...")
    
    local delList = {}
    
    for k, entry in ipairs(manifest["files"]) do
        table.insert(delList, entry[2]..entry[3])
    end
    
    for k, entry in ipairs(manifest["directories"]) do
        table.insert(delList, entry)
    end
    
    table.sort(delList)
    
    for i = #delList, 1, -1 do
        drawBar(#delList-i, #delList)
        local file = delList[i]
        
        local result = fs.remove(file)
        
        if result then
            local txt = "OK "..file
            text.padRight(txt, 42)
            table.insert(rmList, 1, txt)
        else
            local txt = "ERR "..file
            text.padRight(txt, 42)
            table.insert(rmList, 1, txt)
        end
        
        for k, txt in pairs(rmList) do
            if k > 6 then
                break
            end
            gpu.setForeground(nblack)
            gpu.setBackground(white)
            gpu.set(bx + 4, by + 5 + k, txt)
        end
    end
    
    
    drawBar(#manifest["files"], #manifest["files"])
    addButton("Next >", lastPage)
    
    while true do
        local evs = {term.pull("touch")}
        for k, button in pairs(buttonList) do
            if evs[3] >= button[1] and evs[3] <= button[1] + button[3] and evs[4] == button[2] then
                button[4]()
                break
            end
        end
    end
end


function firstPage()
    drawWindow()
    gpu.setForeground(black)
    gpu.setBackground(white)
    local dy = lwrite(bx + 4, by + 2, 42, repositoryName.." Uninstallation Wizard")

    gpu.setForeground(nblack)
    dy = dy + lwrite(bx + 4, by + 3 + dy, 42, "Are you sure you want to delete "..repositoryName.." and all these components?")

    addButton("Cancel", cancel)
    addButton("Yes", uninstall)
    
    while true do
        local evs = {term.pull("touch")}
        for k, button in pairs(buttonList) do
            if evs[3] >= button[1] and evs[3] <= button[1] + button[3] and evs[4] == button[2] then
                button[4]()
                break
            end
        end
    end
end

gpu.setBackground(black)
gpu.setForeground(white)
term.clear()

firstPage()