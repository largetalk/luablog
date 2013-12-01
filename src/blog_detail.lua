ngx.header.content_type = "text/json";

local redis = require "resty.redis";
local cjson = require "cjson";

local utils = require 'utils'

local instance = utils.init_redis();

--get user
local bid = ngx.var.bid;
local blog = utils.get_blog(instance, bid);
if next(blog) == nil then
    ngx.status = ngx.HTTP_NOT_FOUND;
    ngx.exit(ngx.HTTP_OK);
end

local req_method = ngx.req.get_method();
if req_method == 'GET' then
    ngx.say(cjson.encode(blog));
elseif req_method == 'POST' then
    ngx.req.read_body();
    data = ngx.req.get_body_data();
    local comer = cjson.decode(data);

    blog.title = comer.title and comer.title or blog.title;
    blog.content = comer.content;

    utils.update_blog(instance, blog);
    ngx.say(cjson.encode(blog));
elseif req_method == 'DELETE' then
    utils.delete_blog(instance, blog);
    ngx.say(cjson.encode({['status'] = 0}));
else
    err = {}
    err.status = -1;
    err.msg = 'wrong method';
    ngx.say(cjson.encode(err));
end

instance:close();
