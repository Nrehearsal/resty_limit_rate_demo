local limit_rate = require "resty.limit.rate"
local limit_const_args = require("limit_const_args")
local control_args_store = ngx.shared.control_args_store

local current_uri = ngx.var.uri
local current_path = ngx.var.current_path
-- here we use the userkey as the limiting key
local userkey = ngx.var.arg_userkey or "__single__"

local limit_switch = control_args_store:get(current_path..limit_const_args.switch)

-- do not limit rate
if limit_switch ~= "on" then
	return
end

local global_quantum = control_args_store:get(current_path..limit_const_args.global_quantum)

local lim_global = limit_rate.new("userkey_store", 100, global_quantum * 10, global_quantum)

if not lim_global then
	ngx.log(ngx.ERR,"failed to instantiate a [global] resty.limit.rate object: ", err)
	return ngx.exit(500)
end

local lim_single = nil
local order_uri = "Order.json"
if string.find(current_uri, order_uri, 1, true) ~= nil then
	-- single 2r/s, for Order.json
	lim_single = limit_rate.new("userkey_store", 1000, 2, 2)
else
	-- single 8r/s, for other
	lim_single = limit_rate.new("userkey_store", 500, 8, 4)
end

if not lim_single then
	ngx.log(ngx.ERR,"failed to instantiate a [single] resty.limit.rate object: ", err)
	return ngx.exit(500)
end

-- take 1 token from global bucket
local t0, err = lim_global:take_available("__global__", 1)
if not t0 then
	ngx.log(ngx.ERR, "failed to take global: ", err)
	return ngx.exit(500)
end

if t0 == 1 then
	-- take 1 token from single bucket
	local t1, err = lim_single:take_available(userkey, 1)
	if not t1 then
		ngx.log(ngx.ERR, "failed to take single: ", err)
		return ngx.exit(500)
	end

	if t1 == 1 then
		-- return to nginx
		return
	else
		ngx.log(ngx.ERR, "limit rate by [single], current userkey: ", userkey, ", t1: ", t1)
		return ngx.exit(503)
	end
	--return
else
	ngx.log(ngx.ERR, "limit rate by [global], current userkey: ", userkey, ", t0: ", t0)
	return ngx.exit(503)
end
