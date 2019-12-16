local _M = {}

local limit_const_args = require("limit_const_args")
local control_args_store = ngx.shared.control_args_store

-- global 6000r/s 6000 * 300 r/5m
local locations = {api = 600}

function _M.has_location(path)
	if not locations[path] then
		return false
	end
	return true
end

for k, v in pairs(locations) do
	control_args_store:set(k..limit_const_args.switch, "on")
	control_args_store:set(k..limit_const_args.global_quantum, v)
	control_args_store:set(k..limit_const_args.req_total, 0)
	control_args_store:set(k..limit_const_args.slow_total, 0)
	ngx.log(ngx.ERR, "init args done, ", k)
end

return _M
