local param = require("common.param")
local init_args = require("init_args")
local new_tab = require "table.new"
local json = require "cjson"
local limit_const_args = require("limit_const_args")

local control_args_store = ngx.shared.control_args_store

local access_key = "admin_key"

local userkey = ngx.var.arg_userkey
local path = ngx.var.arg_path
local action = ngx.var.arg_action

-- defalult interval == 100ms, 600 * 10 = 6000r/s
local default_global_quantum = 600

if userkey == nil or userkey ~= access_key then
	ngx.say("bad request, invalid user")
	return ngx.exit(200)
end

if path == nil or path == ngx.null or not init_args.has_location(path) then
	ngx.say("bad request, invalid path")
	return ngx.exit(200)
end

if action == nil or action == ngx.null then
	action = "show"
end

local resp_table = new_tab(0, 10)

if action == "show" then
	local limit_switch = control_args_store:get(path..limit_const_args.switch)
	local limit_global_quantum = control_args_store:get(path..limit_const_args.global_quantum)
	local req_total = control_args_store:get(path..limit_const_args.req_total)
	local slow_total = control_args_store:get(path..limit_const_args.slow_total)


	resp_table["limit_switch"] = limit_switch		
	resp_table["limit_global_quantum"] = limit_global_quantum
	resp_table["limit_rate"] = limit_global_quantum * 10
	resp_table["req_total"] = req_total
	resp_table["slow_total"] = slow_total
	resp_table["path"] = path
	
	ngx.say(json.encode(resp_table))
	return ngx.exit(200)
end

local global_quantum = ngx.var.arg_quantum
if action == "change" then
	if not global_quantum or not param.is_number(global_quantum) then		
		ngx.say("bad request, invalid global_quantum")
		return ngx.exit(200)
	end

	control_args_store:set(path..limit_const_args.global_quantum, tonumber(global_quantum))

	resp_table["limit_switch"] = "on"
	resp_table["limit_global_quantum"] = global_quantum
	resp_table["path"] = path

	ngx.say(json.encode(resp_table))
	return ngx.exit(200)
end

if action == "reset" then
	control_args_store:set(path..limit_const_args.switch, "on")
	control_args_store:set(path..limit_const_args.global_quantum, default_global_quantum)
	control_args_store:set(path..limit_const_args.req_total, 0)
	control_args_store:set(path..limit_const_args.slow_total, 0)

	resp_table["limit_switch"] = "on"
	resp_table["limit_global_quantum"] = default_global_quantum
	resp_table["path"] = path

	ngx.say(json.encode(resp_table))
	return ngx.exit(200)
end

if action == "on" then
	local limit_global_quantum = control_args_store:get(path..limit_const_args.global_quantum)

	control_args_store:set(path..limit_const_args.switch, "on")
	control_args_store:set(path..limit_const_args.req_total, 0)
	control_args_store:set(path..limit_const_args.slow_total, 0)

	resp_table["limit_switch"] = "on"
	resp_table["limit_global_quantum"] = limit_global_quantum
	resp_table["path"] = path

	ngx.say(json.encode(resp_table))
	return ngx.exit(200)

end

if action == "off" then
	control_args_store:set(path..limit_const_args.switch, "off")

	resp_table["limit_switch"] = "off"
	resp_table["path"] = path

	ngx.say(json.encode(resp_table))
	return ngx.exit(200)
end

ngx.say("bad request, invalid action")
return ngx.exit(200)
