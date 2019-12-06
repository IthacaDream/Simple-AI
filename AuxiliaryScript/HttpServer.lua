--[[
    使用说明
        LocalHttpPost为发送数据至本地80端口
        HttpPost为发送数据至远程服务器
        返回参数目前仅在控制台输出

    HttpPost远程连接url格式
        url地址省略http://
        比如服务器api地址为http://123.123.123.123:3000/
        调用方法为H.HttpPost(postData, '123.123.123.123:3000')

    json数据格式
        请注意字符需要额外使用""，示例如下
        输入格式
        {
            init = 'true',
            script = '"Simple AI"',
        }
        输出格式
        {
            "data": {
                "init": true,
                "script": "Simple AI"
            },
            "info": {
                "gameTime": 23（注：当前游戏进行时间）
                "script": "Simple AI"
            }
        }

    UUID参数
        发送远程数据时会默认向服务器获取UUID，如果不需要获取请将第三个参数设为true
        初次获取到UUID后每次发送数据都会附带UUID
        如需更新UUID请执行H.GetUUID(url)
]]

--[[
    示例api服务器
        服务器地址http://45.77.179.135:3001
        演示页面地址http://45.77.179.135
]]

local H = {}

local UUID = nil

function H.LocalHttpPost(postData)

    local httpData = jsonFormatting(postData)

    local req = CreateHTTPRequest( "" )
    req:SetHTTPRequestRawPostBody("application/json", httpData)
    req:Send( function( result )
        --此处result为获取到的返回参数
        print( "GET response:\n" )
        for k,v in pairs( result ) do
            print( string.format( "%s : %s\n", k, v ) )
        end 
        print( "Done." )
    end )

end

function H.HttpPost(postData, url, call, config, notUUID)

    if UUID ~= nil or notUUID then

        local httpData = jsonFormatting(postData)

        local req = CreateRemoteHTTPRequest( url )
        req:SetHTTPRequestRawPostBody("application/json", httpData)
        req:Send( function( result )
            for k,v in pairs( result ) do
                if type(v) == 'string'
                   and string.find(v, 'res:') ~= nil 
                then 
                    local resdata = string.sub(v, 5);
                    call(resdata, config)
                end
            end 
        end )
        
    else 
        H.GetUUID(url)
    end

end

function H.GetUUID(url)
    local postData = {
        operation = '"getuuid"'
    }
    local httpData = jsonFormatting(postData)
    local req = CreateRemoteHTTPRequest( url )
    req:SetHTTPRequestRawPostBody("application/json", httpData)
    req:Send( function( result )
        for k,v in pairs( result ) do
            if type(v) == 'string'
               and string.find(v, 'UUID:') ~= nil 
            then 
                UUID = string.sub(v, 6);
            end
        end
        if UUID == nil then 
            print('服务器返回数据错误，无法获取UUID')
        end
    end )
end

function H.jsonFormatting(obj)
    local json = '{"data":{'
    local count = 1
    for key, value in pairs(obj) do
        if count > 1 then json = json..',' end
        json = json .. '"' .. key .. '": ' .. value
        count = count + 1
    end
    json = json..'},"info":{'
    local uuid = UUID
    if uuid == nil then uuid = 'local' end
    local info = {
        uuid = '"'..uuid..'"',
        gameTime = DotaTime(),
        script = '"Simple AI"',
    }
    count = 1
    for key, value in pairs(info) do
        if count > 1 then json = json..',' end
        json = json .. '"' .. key .. '": ' .. value
        count = count + 1
    end
    json = json..'}}'
    return json
end

return H