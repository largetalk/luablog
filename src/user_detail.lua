ngx.header.content_type = "text/json";

local redis = require "resty.redis";
local cjson = require "cjson";

local utils = require 'utils'

local instance = utils.init_redis();

--get user
local uid = ngx.var.uid;
local user = utils.get_user(instance, uid);
if next(user) == nil then
    ngx.status = ngx.HTTP_NOT_FOUND;
    ngx.exit(ngx.HTTP_OK);
end

local req_method = ngx.req.get_method();
if req_method == 'GET' then
    ngx.say(cjson.encode(user));
elseif req_method == 'POST' then
    ngx.say('post');
elseif req_method == 'DELETE' then
    utils.delete_user(instance, user);
    ngx.say(cjson.encode({['status'] = 0}));
else
    ngx.say('err');
end

instance:close();
