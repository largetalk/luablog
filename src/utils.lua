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
    local user = {};
    local ukey = 'user::' .. uid;
    if redis:exists(ukey) == 0 then
        return user;
    end
    user.uid = uid;
    user.username = redis:hget(ukey, 'username');
    user.email = redis:hget(ukey, 'email');
    user.address = redis:hget(ukey, 'address');
    user.ctime = redis:hget(ukey, 'ctime');
    return user;
end

function M.set_user(redis, user)
    local ukey = 'user::' .. user.uid; 
    redis:hset(ukey, 'username', user.username);
    redis:hset(ukey, 'email', user.email);
    redis:hset(ukey, 'password', ngx.md5(user.password));
    redis:hset(ukey, 'address', user.address);
    redis:hset(ukey, 'ctime', user.ctime);

    redis:hset('username', user.username, user.uid);
    redis:sadd('uidlst', user.uid);
end

function M.delete_user(redis, user)
    redis:del('user::' .. user.uid);
    redis:hdel('username', user.username);
    redis:srem('uidlst', user.uid);
end

return M
