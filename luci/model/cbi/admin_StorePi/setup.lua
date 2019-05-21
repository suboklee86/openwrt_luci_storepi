-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Copyright 2011 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

local sys   = require "luci.sys"
local zones = require "luci.sys.zoneinfo"
local fs    = require "nixio.fs"
local conf  = require "luci.config"

local m, s, o
local has_ntpd = fs.access("/usr/sbin/ntpd")


m = Map("storepi", translate("캡티브 포털  셋업"), translate("캡티브 포털 서버 설정"))
m:chain("luci")


s = m:section(TypedSection, "storepi", translate("System Properties"))
s.anonymous = true
s.addremove = false

s:tab("basic",  translate("기본 정보"))
s:tab("remote_fas_setup",  translate("원격 캡티브 포털  셋업"))
s:tab("ipport", translate("IP/MAC 화이트리스트"))
s:tab("local_fas_setup",  translate("로컬 캡티브 설정"))
s:tab("before_auth",  translate("로컬 캡티브: 인증 페이지"))
s:tab("after_auth",  translate("로컬 캡티브: 인증 후 페이지"))


--
-- Remote Captive Portal Properties
--



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


o = s:taboption("basic", Value, "store_name", translate("상점 이름"))


function o.cfgvalue(self)
    return curr_store_name
end


function o.write(self, section, value)
	Value.write(self, section, value)
end

o = s:taboption("basic", Value, "store_id", translate("상점 ID"))


function o.cfgvalue(self)
    return curr_store_id
end


function o.write(self, section, value)
	Value.write(self, section, value)
end



--
-- IP:PORT WHITELIST
--

o = s:taboption("ipport", DynamicList, "ipport_whitelist", translate("IP:Port whitelist"))
o.datatype = "hostport"

-- retain server list even if disabled
function o.remove() 
end

function o.cfgvalue(self)
    return curr_ipport_list1
end


--
-- MAC WHITELIST
--

o = s:taboption("ipport", DynamicList, "mac_whitelist", translate("MAC whitelist"))
o.datatype = "macaddr"

-- retain server list even if disabled function o.remove() end
function o.remove() 
end

function o.cfgvalue(self)
    return curr_mac_whitelist1
end


o = s:taboption("ipport", DynamicList, "mac_blacklist", translate("MAC blacklist"))
o.datatype = "macaddr"

-- retain server list even if disabled function o.remove() end
function o.remove() 
end

function o.cfgvalue(self)
    return curr_mac_blacklist1
end


o = s:taboption("before_auth", TextValue, "splash_html", translate("로컬 캡티브 인증 전 페이지 HTML 내용"))
o.template = "cbi/tvalue"
o.rows = "25"

-- retain server list even if disabled function o.remove() end
function o.remove() 
end

splash_html= "/etc/nodogsplash/htdocs/splash_new.html"
function o.cfgvalue(self)
    return fs.readfile(splash_html)
end

function o.write(self, section, value)
    fs.writefile(splash_html, value:gsub("\r\n", "\n"))
    Value.write(self, section, os.date("Updated at %Y-%m-%d %H:%M:%S"))
end


return m
