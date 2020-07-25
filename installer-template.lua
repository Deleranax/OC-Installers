local term = require("term")
local component = require("component")
local math = require("math")
local text = require("text")
local net = require("internet")
local gpu = component.gpu

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

local scrolltmp = 0

local buttonList = {}
local manifest = {}

local w, h = gpu.getResolution()
gpu.getResolution(math.max(w, 50), math.max(h, 16))

w, h = gpu.getResolution()
local bx = 1
local by = 1

if w > 50 then
    bx = (w - 50)//2
end

if h > 16 then
    by = (h - 16)//2
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
        local result, rt = pcall(serialization.unserialize(str))
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

function downloadFile(url, path, name)
    local f, reason = io.open(path..name, "w")
    if not f then
        return false, path..name
    end
    local result, response = pcall(net.request, url)
    if result then
        for chunk in response do
            string.gsub(chunk, "\r\n", "\n")
            f:write(chunk)
        end
        f:close()
        return true, path..name
    else
        f:close()
        filesystem.remove(path..name)
        return false, path..name
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

function cancel()
    gpu.setBackground(black)
    gpu.setForeground(white)
    term.clear()
    os.exit()
end

function install()
end

function firstPage()
    manifest = getOnlineData(baseUrl.."/"..ownerName.."/"..repositoryName.."/"..branch.."/manifest.txt")
    drawWindow()
    gpu.setForeground(nblack)
    gpu.setBackground(white)
    local dy = lwrite(bx + 4, by + 2, 42, "The setup is now ready to begin the installation.")
    
    dy = dy + lwrite(bx + 4, by + 3 + dy, 42, "File to download: "..#manifest["files"])
    
    dy = dy + lwrite(bx + 4, by + 4 + dy, 42, "Click Install to continue with the installation, or click Back to review any settings.")

    addButton("Cancel", cancel)
    addButton("Install >", install)
    addButton("< Back", licensePage)
    
    while true do
        local evs = {term.pull("touch")}
        for button in buttonList do
            if evs[3] >= button[1] and evs[3] <= button[1] + button[3] and evs[4] == button[2] then
                button[4]()
                break
            end
        end
    end
end

function licensePage()
    drawWindow()
    gpu.setForeground(nblack)
    gpu.setBackground(white)
    local dy = lwrite(bx + 4, by + 2, 42, "Please read the following License Agreement. You must accept the terms of this agreement before continuing with the installation.")
    
    gpu.setBackground(gray)
    gpu.fill(bx, by + 3 + dy, 50, 7, " ")
    
    addButton("Cancel", cancel)
    addButton("Accept >", summaryPage)
    addButton("< Back", firstPage)
        
    while true do
        gpu.setForeground(white)
        gpu.setBackground(gray)
        gpu.fill(bx, by + 3 + dy, 50, 7, " ")
        lwrite(bx + 4, by + 4 + dy, 42, "This work is licensed under CC BY-NC-SA 4.0. You are free to: Share — copy and redistribute the material in any medium or format; Adapt — remix, transform, and build upon the material. The licensor cannot revoke these freedoms as long as you follow the license terms. Under the following terms: Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use; NonCommercial — You may not use the material for commercial purposes; ShareAlike — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original. No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits. Notices: You do not have to comply with the license for elements of the material in the public domain or where your use is permitted by an applicable exception or limitation. No warranties are given. The license may not give you all of the permissions necessary for your intended use. For example, other rights such as publicity, privacy, or moral rights may limit how you use the material. To view a copy of this license, visit creativecommons.org/licenses/by-nc-sa/4.0", scrolltmp, 5)
        
        local evs = {term.pull()}
        if evs[1] == "touch" then
            for button in buttonList do
                if evs[3] >= button[1] and evs[3] <= button[1] + button[3] and evs[4] == button[2] then
                    button[4]()
                    break
                end
            end
        elseif evs[1] == "scroll" then
            scrolltmp = math.max(0, scrolltmp - evs[5])
        end
    end
end

function firstPage()
    drawWindow()
    gpu.setForeground(black)
    gpu.setBackground(white)
    local dy = lwrite(bx + 4, by + 2, 42, "Welcome to the "..repositoryName.." Installation Wizard")

    gpu.setForeground(nblack)
    dy = dy + lwrite(bx + 4, by + 3 + dy, 42, "This wizard helps you install "..repositoryName.." on your computer.")
    dy = dy + lwrite(bx + 4, by + 4 + dy, 42, "Click Next to continue, or Cancel to exit Setup.")

    addButton("Cancel", cancel)
    addButton("Next >", licensePage)
    
    while true do
        local evs = {term.pull("touch")}
        for button in buttonList do
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