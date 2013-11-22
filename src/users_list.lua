ngx.header.content_type = "text/json";

local redis = require "resty.redis";
local cjson = require "cjson";

local config = ngx.shared.config;

local instance = redis:new();

local host = config:get("host");
local port = config:get("port");

get_next_user_id = function(redis)
    local uid = redis:incr('uidseq');
    --ngx.say('id ', id);
    return uid;
end

get_user = function(redis, uid)
    local user = {}
    user.username = redis:hget('user::' .. uid, 'username');
    user.email = redis:hget('user::' .. uid, 'email');
    user.address = redis:hget('user::' .. uid, 'address');
    user.ctime = redis:hget('user::' .. uid, 'ctime');
    return user;
end

set_user = function(redis, user)
    redis:hset('user::' .. user.uid, 'username', user.username);
    redis:hset('user::' .. user.uid, 'email', user.email);
    redis:hset('user::' .. user.uid, 'password', ngx.md5(user.password));
    redis:hset('user::' .. user.uid, 'address', user.address);
    redis:hset('user::' .. user.uid, 'ctime', user.ctime);
end

local ok, err = instance:connect(host, port);
if not ok then
    ngx.log(ngx.ERR, err);
    ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
end
instance:select(5);

local req_method = ngx.req.get_method();
if req_method == 'GET' then
    local args = ngx.req.get_uri_args();
    if args.username ~= nil and args.password ~= nil then
        if instance:hexists("username", args.username) ~= 0 then
            local uid = instance:hget("username", args.username);
            local password = instance:hget('user::' .. uid, 'password');
            if ngx.md5(args.password) == password  then
                ngx.say(cjson.encode(get_user(instance, uid)));
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
        ngx.say(cjson.encode(get_user(instance, uid)));
        ngx.exit(ngx.HTTP_OK);
    end
    user.uid = get_next_user_id(instance);
    user.ctime = ngx.utctime();
    set_user(instance, user);
    instance:hset('username', user.username, user.uid);
    instance:sadd('uidlst', user.uid);
    ngx.status = ngx.HTTP_CREATED;
    ngx.say(cjson.encode(user));
    ngx.exit(ngx.HTTP_OK);
end

instance:close();
