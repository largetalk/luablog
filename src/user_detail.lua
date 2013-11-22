ngx.header.content_type = "text/json";

local redis = require "resty.redis";

local config = ngx.shared.config;

local instance = redis:new();

local host = config:get("host");
local port = config:get("port");

local ok, err = instance:connect(host, port);
if not ok then
    ngx.log(ngx.ERR, err);
    ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
end

local req_method = ngx.req.get_method();
ngx.say(req_method)

instance:close();
