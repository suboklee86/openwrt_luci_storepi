-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Copyright 2011 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.admin.StorePi", package.seeall)

function index()
	entry({"admin", "StorePi"}, alias("admin", "StorePi", "Setup"), _("StorePi"), 19).index = true

	entry({"admin", "StorePi", "Setup"},   cbi("admin_StorePi/setup"),  _("캡티브 포털 설정"), 1)
	entry({"admin", "StorePi", "restart"}, cbi("admin_StorePi/restart"), _("캡티브 포털 재시작"), 2)
end

function action_fas_setup()
	local syslog = luci.sys.syslog()
	luci.template.render("admin_StorePi/fas_setup", {syslog=syslog})
end

function action_dmesg()
	local dmesg = luci.sys.dmesg()
	luci.template.render("admin_StorePi/dmesg", {dmesg=dmesg})
end

function action_iptables()
	if luci.http.formvalue("zero") then
		if luci.http.formvalue("family") == "6" then
			luci.util.exec("/usr/sbin/ip6tables -Z")
		else
			luci.util.exec("/usr/sbin/iptables -Z")
		end
	elseif luci.http.formvalue("restart") then
		luci.util.exec("/etc/init.d/firewall restart")
	end

	luci.http.redirect(luci.dispatcher.build_url("admin/StorePi/iptables"))
end

function action_bandwidth(iface)
	luci.http.prepare_content("application/json")

	local bwc = io.popen("luci-bwc -i %s 2>/dev/null"
		% luci.util.shellquote(iface))

	if bwc then
		luci.http.write("[")

		while true do
			local ln = bwc:read("*l")
			if not ln then break end
			luci.http.write(ln)
		end

		luci.http.write("]")
		bwc:close()
	end
end

function action_wireless(iface)
	luci.http.prepare_content("application/json")

	local bwc = io.popen("luci-bwc -r %s 2>/dev/null"
		% luci.util.shellquote(iface))

	if bwc then
		luci.http.write("[")

		while true do
			local ln = bwc:read("*l")
			if not ln then break end
			luci.http.write(ln)
		end

		luci.http.write("]")
		bwc:close()
	end
end

function action_load()
	luci.http.prepare_content("application/json")

	local bwc = io.popen("luci-bwc -l 2>/dev/null")
	if bwc then
		luci.http.write("[")

		while true do
			local ln = bwc:read("*l")
			if not ln then break end
			luci.http.write(ln)
		end

		luci.http.write("]")
		bwc:close()
	end
end

function action_connections()
	local sys = require "luci.sys"

	luci.http.prepare_content("application/json")

	luci.http.write('{ "connections": ')
	luci.http.write_json(sys.net.conntrack())

	local bwc = io.popen("luci-bwc -c 2>/dev/null")
	if bwc then
		luci.http.write(', "statistics": [')

		while true do
			local ln = bwc:read("*l")
			if not ln then break end
			luci.http.write(ln)
		end

		luci.http.write("]")
		bwc:close()
	end

	luci.http.write(" }")
end

function action_nameinfo(...)
	local util = require "luci.util"

	luci.http.prepare_content("application/json")
	luci.http.write_json(util.ubus("network.rrdns", "lookup", {
		addrs = { ... },
		timeout = 5000,
		limit = 1000
	}) or { })
end
