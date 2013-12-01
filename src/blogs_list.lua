ngx.header.content_type = "text/json";

local redis = require "resty.redis";
local cjson = require "cjson";

local utils = require 'utils'

local instance = utils.init_redis();

local req_method = ngx.req.get_method();
if req_method == 'GET' then

    local bidlst = instance:smembers('bidlst');
    --ngx.say(type(bidlst))
    ngx.say(cjson.encode(bidlst));
else
    ngx.req.read_body();
    data = ngx.req.get_body_data();
    --ngx.say(data, type(data));
    local blog = cjson.decode(data);
    if blog.title and blog.content and blog.user_id then
        local user = utils.get_user(instance, blog.user_id);
        if next(user) == nil then
            ngx.status = ngx.HTTP_BAD_REQUEST;
            ngx.exit(ngx.OK);
        end

        local ret = utils.create_blog(instance, blog);
        ngx.status = ngx.HTTP_CREATED;
        ngx.say(cjson.encode(ret));
        ngx.exit(ngx.HTTP_OK);
    else
        ngx.status = ngx.HTTP_BAD_REQUEST;
        ngx.exit(ngx.OK);
    end
end

instance:close();
