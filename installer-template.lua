local term = require("component")
local component = require("component")
local net = component.internet
local gpu = component.gpu

local repositoryName = "OC-Invoice"
local ownerName = "Deleranax"
local branch = "master"
local baseUrl = "https://raw.githubusercontent.com/"

local manifestUrl = baseUrl.."/"..ownerName.."/"..repositoryName.."/"..branch.."/manifest.txt"

function initScreen()
    