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
    ngx.req.read_body();
    data = ngx.req.get_body_data();
    local comer = cjson.decode(data);

    user.email = comer.email and comer.email or user.email;
    user.password = comer.password and comer.password or nil;
    user.address = comer.address and comer.address or user.address;

    utils.set_user(instance, user);
    ngx.say(cjson.encode(user));
elseif req_method == 'DELETE' then
    utils.delete_user(instance, user);
    ngx.say(cjson.encode({['status'] = 0}));
else
    err = {}
    err.status = -1;
    err.msg = 'wrong method';
    ngx.say(cjson.encode(err));
end

instance:close();
