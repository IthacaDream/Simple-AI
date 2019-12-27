local C = {}

dkjson = require( "game/dkjson" )

--当前bot剧本缓存
--[[
    scenario
    缓存结构
    {
        时序剧本
        sequential
        {
            speech    讲话内容
            all       是否公共频道讲话
            interval  距离上一次讲话间隔
        }
        触发剧本
        trigger
        {
            scenarioType        触发类型 []死亡 []杀敌 []逃脱 []反塔 []团灭 []被团灭
            scenarioTimeNeeded  剧本所需时间
            scenario            触发中的时序剧本
            [
                {
                    speech    讲话内容
                    all       是否公共频道讲话
                    interval  距离上一次讲话间隔
                }
            ]
            state               剧本状态 true为运行中，false为等待触发
            handling            结束后处理方式 reset为复位 del为删除
        }
        

        
    }
]]

--bot数据
--[[
    scenario 缓存剧本
    speechTime  上一次说话时间
    scenarioTimeNeeded  因触发剧本导致的时序延后时间
    triggerScenario  正在执行的触发剧本
    triggerspeechTime  触发剧本中的上一次说话时间
]]


--[[
    聊天剧本核心程序，需要每帧调用
]]
function C.Speech()
    local bot = GetBot()
    local time = DotaTime()

    if bot.scenario ~= nil
    then

        --时序剧本
        if bot.scenario.sequential ~= nil 
           and #bot.scenario.sequential > 0
        then

            local scenario = bot.scenario.sequential[#bot.scenario.sequential - 1]
            local scenarioTimeNeeded = 0

            if bot.speechTime == nil then bot.speechTime = 0 end --如果从未说过话，设置时间为0
            if bot.scenarioTimeNeeded == nil then scenarioTimeNeeded = 0 else scenarioTimeNeeded = bot.scenarioTimeNeeded end --如果正在执行触发型剧本，则延后时序剧本

            if bot.speechTime + scenario['interval'] + scenarioTimeNeeded < time then --到说话时间了
                bot:ActionImmediate_Chat(scenario['speech'], scenario['all'])
                bot.speechTime = time --设置上一次说话时间
                table.remove(bot.scenario.sequential) --删除已说过的剧本内容
            end

        end

        --触发剧本
        if bot.scenario.trigger ~= nil 
           and bot.triggerScenario == nil --有正在执行的触发剧本时，不再触发新的剧本
        then
            --检查所有触发条件
            for i,trigger in pairs(bot.scenario.trigger)
            do
                --根据不同的触发条件，进行检查程序
                
            end
        end

        --执行触发中的剧本
        if bot.triggerScenario ~= nil then
            --[[
                触发中剧本的属性
                triggerScenarioId  id
                scenario           剧本
                handling           结束处理
            ]]
            local triggerScenario = bot.triggerScenario.scenario
            local handling = bot.triggerScenario.handling
            local triggerId = bot.triggerScenario.triggerScenarioId

            --触发中的剧本执行完了
            if #triggerScenario == 0 then
                if handling == 'reset' then --重置
                    bot.scenario.trigger[triggerId].state = false
                else --不是重置就删除
                    table.remove(bot.scenario.trigger, triggerId)
                end
                --通用变量重置
                bot.triggerScenario = nil
                bot.triggerspeechTime = nil
                return
            end

            local scenario = triggerScenario[#triggerScenario - 1]

            if bot.triggerspeechTime == nil then bot.triggerspeechTime = 0 end --如果从未说过话，设置时间为0

            if bot.triggerspeechTime + scenario['interval'] < time then --到说话时间了
                bot:ActionImmediate_Chat(scenario['speech'], scenario['all'])
                bot.triggerspeechTime = time --设置上一次说话时间
                table.remove(bot.triggerScenario.scenario.sequential) --删除已说过的剧本内容
            end

        end

    end
end

function C.JoinScenario(bot, scenario)
    if bot.scenario == nil
    then
        bot.scenario = {}
    end
    --时序剧本缓存
    if bot.scenario.sequential ~= nil then
        for _,i in pairs(scenario.sequential)
        do
            table.insert(bot.scenario.sequential,i) --将获取到的剧本全部加入剧本缓存
        end
    else
        bot.scenario.sequential = scenario.sequential
    end
    --触发剧本缓存
    if bot.scenario.trigger ~= nil then
        for _,i in pairs(scenario.trigger)
        do
            table.insert(bot.scenario.trigger,i) --将获取到的剧本全部加入剧本缓存
        end
    else
        bot.scenario.trigger = scenario.trigger
    end
end

function C.GetScenario()
    local bot = GetBot()
    local botId = bot:GetPlayerID()

    local data = {
        operation = '"getscenario"'
    }

    data.botId = botId

    H.HttpPost(data, '45.77.179.135:3010',
        function (res, par)
            local scenario = dkjson.decode(data)
            par:C.JoinScenario(scenario)
        end
    , bot, true);
end

--触发型剧本检查函数
function C.CheckTrigger(bot, script)
    if script.state then return end --这个脚本正在运行，不再执行检查
    
    local scenarioTimeNeeded = script.scenarioTimeNeeded
    local handling = script.handling

    if script.scenarioType == '被团灭' then
        local nArreysTeam = GetTeamPlayers(GetTeam())
        local dieInCount = 0
        for i,aTeam in pairs(nArreysTeam)
        do
            member = GetTeamMember(i)
            if not member:IsAlive() then dieInCount = dieInCount + 1 end
        end
        if dieInCount == 5 then 
            --被团灭时的操作
        end
    end
end