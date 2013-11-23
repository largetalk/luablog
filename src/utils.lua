local redis = require "resty.redis";

local modname = 'utils'
local M = {}
_G[modname] = M

function M.init_redis()
    local config = ngx.shared.config;
    local instance = redis:new();
    
    local host = config:get("host");
    local port = config:get("port");
    
    local ok, err = instance:connect(host, port);
    if not ok then
        ngx.log(ngx.ERR, err);
        ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
    end
    instance:select(5);
    return instance;
end

function M.get_next_user_id(redis)
    local uid = redis:incr('uidseq');
    --ngx.say('id ', id);
    return uid;
end

function M.get_user(redis, uid)
    local user = {}
    user.username = redis:hget('user::' .. uid, 'username');
    user.email = redis:hget('user::' .. uid, 'email');
    user.address = redis:hget('user::' .. uid, 'address');
    user.ctime = redis:hget('user::' .. uid, 'ctime');
    return user;
end

function M.set_user(redis, user)
    redis:hset('user::' .. user.uid, 'username', user.username);
    redis:hset('user::' .. user.uid, 'email', user.email);
    redis:hset('user::' .. user.uid, 'password', ngx.md5(user.password));
    redis:hset('user::' .. user.uid, 'address', user.address);
    redis:hset('user::' .. user.uid, 'ctime', user.ctime);
end

return M
