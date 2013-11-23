ngx.header.content_type = "text/json";

local redis = require "resty.redis";
local cjson = require "cjson";

local utils = require 'utils'

local instance = utils.init_redis();

local req_method = ngx.req.get_method();
if req_method == 'GET' then
    local args = ngx.req.get_uri_args();
    if args.username ~= nil and args.password ~= nil then
        if instance:hexists("username", args.username) ~= 0 then
            local uid = instance:hget("username", args.username);
            local password = instance:hget('user::' .. uid, 'password');
            if ngx.md5(args.password) == password  then
                ngx.say(cjson.encode(utils.get_user(instance, uid)));
            else
                ngx.status = ngx.HTTP_UNAUTHORIZED;
            end
        else
            ngx.status = ngx.HTTP_NOT_FOUND;
        end
        ngx.exit(ngx.HTTP_OK);
    end

    local uidlst = instance:smembers('uidlst');
    --ngx.say(type(uidlst))
    ngx.say(cjson.encode(uidlst));
else
    ngx.req.read_body();
    data = ngx.req.get_body_data();
    --ngx.say(data, type(data));
    local user = cjson.decode(data);
    if instance:hexists("username", user.username) ~= 0 then
        local uid = instance:hget("username", user.username);
        ngx.status = ngx.HTTP_NOT_MODIFIED;
        ngx.say(cjson.encode(utils.get_user(instance, uid)));
        ngx.exit(ngx.HTTP_OK);
    end
    user.uid = utils.get_next_user_id(instance);
    user.ctime = ngx.utctime();
    utils.set_user(instance, user);
    ngx.status = ngx.HTTP_CREATED;
    ngx.say(cjson.encode(user));
    ngx.exit(ngx.HTTP_OK);
end

instance:close();
