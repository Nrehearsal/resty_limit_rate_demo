local limit_const_args = require("limit_const_args")
local control_args_store = ngx.shared.control_args_store

local current_path = ngx.var.current_path

local slow_time = 4 -- in seconds
local max_slow = 40

local req_interval = 100

local req_total = control_args_store:incr(current_path..limit_const_args.req_total, 1, 0)

local request_time = ngx.now() - ngx.req.start_time()
if request_time > slow_time then
	control_args_store:incr(current_path..limit_const_args.slow_total, 1, 0)
	ngx.log(ngx.ERR, "current_path: ", current_path, ", request_time: ", request_time, ", is a slow request")
end

local slow_total = control_args_store:get(current_path..limit_const_args.slow_total)
if slow_total > max_slow then
	local limit_global_quantum = control_args_store:get(current_path..limit_const_args.global_quantum)

	-- down to half
	new_limit_global_quantum = limit_global_quantum / 2

	control_args_store:set(current_path..limit_const_args.global_quantum, new_limit_global_quantum)
	control_args_store:set(current_path..limit_const_args.slow_total, 0)
	control_args_store:set(current_path..limit_const_args.req_total, 0)

	ngx.log(ngx.ERR, "current_path: ", current_path, ", req_total: ", req_total, ", slow total: ", slow_total, ", global_quantum: ", new_limit_global_quantum, ", reset bucket")
	return
end

if req_total % req_interval == 0 then
	control_args_store:set(current_path..limit_const_args.req_total, 0)
	ngx.log(ngx.ERR, "current_path: ", current_path, ", req_total: ", req_total, ", reset req_total")
end
