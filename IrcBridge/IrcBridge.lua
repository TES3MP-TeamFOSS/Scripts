-- -*- lua -*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer
require("irc")

local IrcBridge = {}

local nick       = "TES3MPLoveBot"
local server     = "irc.freenode.net"
local nspasswd   = "PleaseNoCorprus"
local channel    = "#tes3mp"
local nickfilter = ""

-- Optionally use DataManager
if DataManager ~= nil then
   IrcBridge.defaultConfig = {
      nick = nick,
      server = server,
      nspasswd = nspasswd,
      channel = channel,
      nickfilter = nickfilter,
   }

   IrcBridge.config = DataManager.loadConfiguration("IrcBridge", IrcBridge.defaultConfig)

   nick = IrcBridge.config.nick
   server = IrcBridge.config.server
   nspasswd = IrcBridge.config.nspasswd
   channel = IrcBridge.config.channel
   nickfilter = IrcBridge.config.nickfilter
end

local client = irc.new { nick = nick }
local lastMessage = ""

client:connect(server)
nspasswd = "identify " .. nspasswd
client:sendChat("NickServ", nspasswd)
client:join(channel)

IrcBridge.client = client

local function sendMessage(message)
    client:sendChat(channel, message)
    client:think()
end

local function stringStarts(String, Start)
   return string.sub(String, 1, string.len(Start)) == Start
end

function IrcBridge.ChatHook(user, _channel, message)
   if lastMessage ~= message and tableHelper.getCount(Players) > 0 then
      for pid, _ in pairs(Players) do
         if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
            user.nick = string.gsub(user.nick, nickfilter, "")
            tes3mp.SendMessage(pid, color.GreenYellow .. user.nick ..
                                  color.Default .. ": " .. message .. "\n", true)
            lastMessage = message
            break
         end
      end
   end
end

function IrcBridge.KeepAlive()
    IrcBridge.client:think()
end

function IrcBridge.OnPlayerAuthentified(eventStatus, pid)
   sendMessage(logicHandler.GetChatName(pid) .. " joined the server.")
end

function IrcBridge.OnPlayerDisconnect(eventStatus, pid)
   sendMessage(logicHandler.GetChatName(pid) .. " left the server.\n")
end

function IrcBridge.OnPlayerSendMessage(eventStatus, pid, message)
    if not stringStarts(message, "/") then
       sendMessage(logicHandler.GetChatName(pid) .. ": " .. message)
    end
end

function IrcBridge.RecvMessage()
    IrcBridge.KeepAlive()
    IrcBridge.client:hook("OnChat", IrcBridge.ChatHook)
end

customEventHooks.registerHandler("OnPlayerAuthentified", IrcBridge.OnPlayerAuthentified)
customEventHooks.registerValidator("OnPlayerDisconnect", IrcBridge.OnPlayerDisconnect)
customEventHooks.registerHandler("OnPlayerSendMessage", IrcBridge.OnPlayerSendMessage)

customEventHooks.registerHandler("UpdateTime", IrcBridge.RecvMessage)
