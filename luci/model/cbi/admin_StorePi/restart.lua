-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Copyright 2011 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

local sys   = require "luci.sys"
local zones = require "luci.sys.zoneinfo"
local fs    = require "nixio.fs"
local conf  = require "luci.config"

local m, s, o
local has_ntpd = fs.access("/usr/sbin/ntpd")

local curr_remote_fas_hostname
local curr_remote_fas_port
local curr_remote_fas_uripath
local curr_remote_fas_reqparam
local curr_remote_fas_enable

local curr_local_fas_hostname
local curr_local_fas_port
local curr_local_fas_uripath
local curr_local_fas_reqparam
local curr_local_fas_enable

local curr_ipport_list1

local curr_mac_whitelist1
local curr_mac_blacklist1

local curr_gatewayname
local curr_store_name
local curr_store_id

function repl(src,sect_name,val)
  s1="### begin " .. sect_name .. "\n"
  s2="### end " .. sect_name .. "\n"
  i1= string.find(src,s1)
  i2= string.find(src,s2,i1)
  if i1==nil or i2==nil then
     return src
  end
  before= string.sub(src, 1, i1+ string.len(s1)-1)
  after=  string.sub(src, i2)
  return before .. "  option " .. sect_name .. " '"  .. val .. "'\n" .. after
end

function repl_list_ipport(src,sect_name,vals)
  s1="### begin " .. sect_name .. "\n"
  s2="### end " .. sect_name .. "\n"
  i1= string.find(src,s1)
  i2= string.find(src,s2,i1)
  if i1==nil or i2==nil then
     return src
  end
  before= string.sub(src, 1, i1+ string.len(s1)-1)
  after=  string.sub(src, i2)
  val=""
  for i,v in ipairs(vals) do
    j1= string.find(v,":")
    port= string.sub(v,j1+1)
    ip  = string.sub(v,1,j1-1)
    val= val .. "  list " .. sect_name .. " '" .. 'allow tcp port ' .. port .. ' to ' .. ip .. "'\n"
  end
  return before .. val .. after
end

function repl_list(src,sect_name,vals)
  s1="### begin " .. sect_name .. "\n"
  s2="### end " .. sect_name .. "\n"
  i1= string.find(src,s1)
  i2= string.find(src,s2,i1)
  if i1==nil or i2==nil then
     return src
  end
  before= string.sub(src, 1, i1+ string.len(s1)-1)
  after=  string.sub(src, i2)
  val=""
  for i,v in ipairs(vals) do
    val= val .. "  list " .. sect_name .. " '" .. v .. "'\n"
  end
  return before .. val .. after
end

m = Map("storepi", translate("캡티브 포털 재시작"), translate("캡티브 포털 서버 재시작"))
m:chain("luci")

m.uci:foreach("storepi", "storepi", function(x) 
    if x['remote_fas_hostname'] then
       curr_remote_fas_hostname= x['remote_fas_hostname']
    end
    if x['remote_fas_port'] then
       curr_remote_fas_port= x['remote_fas_port']
    end
    if x['remote_fas_uripath'] then
       curr_remote_fas_uripath= x['remote_fas_uripath']
    end
    if x['remote_fas_reqparam'] then
       curr_remote_fas_reqparam= x['remote_fas_reqparam']
    end
    if x['remote_fas_enable'] then
       curr_remote_fas_enable= x['remote_fas_enable']
    end
    if x['gatewayname'] then
       curr_gatewayname= x['gatewayname']
    end
    if x['store_name'] then
       curr_store_name= x['store_name']
    end
    if x['store_id'] then
       curr_store_id= x['store_id']
    end

    if x['local_fas_hostname'] then
       curr_local_fas_hostname= x['local_fas_hostname']
    end
    if x['local_fas_port'] then
       curr_local_fas_port= x['local_fas_port']
    end
    if x['local_fas_uripath'] then
       curr_local_fas_uripath= x['local_fas_uripath']
    end
    if x['local_fas_reqparam'] then
       curr_local_fas_reqparam= x['local_fas_reqparam']
    end
    if x['local_fas_enable'] then
       curr_local_fas_enable= x['local_fas_enable']
    end

    if x['ipport_whitelist'] then
       curr_ipport_list1= x['ipport_whitelist']
    end

    if x['mac_whitelist'] then
       curr_mac_whitelist1= x['mac_whitelist']
    end
    if x['mac_blacklist'] then
       curr_mac_blacklist1= x['mac_blacklist']
    end
end)

s = m:section(TypedSection, "storepi", translate("설정 적용을 위한 캡티브 포털 재시작 "))
s.anonymous = true
s.addremove = false

o = s:option(Button, "restart", translate("캡티브 포털 재시작"))

o.inputstyle = "apply"
o.title= "캡티브 포털 재시작"
o.inputtitle= "지금 재시작"

o.write = function(self, section)
        config1= "/etc/config/nodogsplash"
        nodog= fs.readfile(config1)
        nodog= repl(nodog, "gatewayname", curr_store_id)
	if curr_fas_remote_enable=='1' then
	   nodog= repl(nodog, "fasport", curr_remote_fas_port)
	   nodog= repl(nodog, "fasremoteip", curr_remote_fas_hostname)
	   new_uri= curr_remote_fas_uripath .. "?store_id=" .. curr_store_id 
	   if curr_remote_fas_reqparam ~= nil then
	      new_uri= new_uri .. "&" .. curr_remote_fas_reqparam
	   end 
	   nodog= repl(nodog, "faspath", new_uri)
	else
	   nodog= repl(nodog, "fasport", curr_local_fas_port)
	   -- nodog= repl(nodog, "fasremoteip", curr_local_fas_hostname)
	   nodog= repl(nodog, "fasremoteip", "192.168.1.1")
	   new_uri= curr_local_fas_uripath .. "?store_id=" .. curr_store_id
	   if curr_local_fas_reqparam ~= nil then
	      new_uri= new_uri .. "&" .. curr_local_fas_reqparam
	   end 
	   nodog= repl(nodog, "faspath", new_uri)
	end 
	nodog= repl_list_ipport(nodog, "preauthenticated_users", curr_ipport_list1)
	nodog= repl_list(nodog, "trustedmac", curr_mac_whitelist1)
	nodog= repl_list(nodog, "blockedmac", curr_mac_blacklist1)
	fs.writefile(config1, nodog)
        sys.call("/etc/init.d/nodogsplash stop  > /dev/null")
        sys.call("/etc/init.d/nodogsplash start > /dev/null")
end

return m
