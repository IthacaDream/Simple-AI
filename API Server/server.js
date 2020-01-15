const http = require('http'),
      express = require('express'),
      router = express.Router(),
      bodyParser = require('body-parser'),
      api = require('express')(),
      server = require('http').createServer(api),
      SqliteDB = require('./sqlist');
      uuid = require('node-uuid');

let serverdb = SqliteDB.SqliteDB('db.db');
let apicont = 0;

setInterval(() => {
    apicont = 0
},1000 * 60 * 60)
server.listen(3010);

api.use(bodyParser());

api.post('/', function(req, res){
    var result = req.body;
    let ip = req.ip.match(/\d+\.\d+\.\d+\.\d+/);
    //res.send(JSON.stringify(result));
    switch (result.data.operation) {
    case 'message':
        startRequest(result.data.message, res)
    break;
    case 'gameEnd':
        if (Array.isArray(result.data.gameData)) {
            for (let i = 0; i < result.data.gameData.length; i++) {
                installHeroData(JSON.parse(result.data.gameData[i]), result.info)
            }
        } else {
            installHeroData(result.data, result.info)
        }
        serverdb.executeSql(`DELETE FROM UUID WHERE ip = '${ip}';`)
    break;
    //原始数据
    case 'getGameData':
        let page = 0
        if (result.data.page) {page = result.data.page}
        serverdb.queryData(`SELECT * from heroData ORDER BY Date DESC LIMIT 100 OFFSET ${page * 30};`, (data) => {
            if (data.length > 0) {
                res.send(JSON.stringify(data));
            }
        })
    break;
    //英雄热度
    case 'getheat':
        serverdb.queryData(`SELECT * FROM (SELECT hero as 英雄, COUNT(hero) as 热度 FROM "heroData" where bot = '电脑' GROUP BY hero ORDER BY 热度) WHERE 热度 >= 50`, (data) => {
            if (data.length > 0) {
                res.send(JSON.stringify(data));
            }
        })
    break;
    //英雄统计数据
    case 'getGameDataCount':
        serverdb.queryData(`SELECT hero AS '英雄',CAST (avg(kill) AS int) AS '平均击杀',CAST (avg(Death) AS int) AS '平均死亡',CAST (avg(Assist) AS int) AS '平均助攻',CAST (avg(Level) AS int) AS '平均等级',count(CASE WHEN Win='赢' THEN 1 END) AS '胜利场数',count(CASE WHEN Win='输' THEN 1 END) AS '失败场数',(count(CASE WHEN Win='赢' THEN 1 END)+0.0)/(count(hero)+0.0) AS '胜率值',Round((((count(CASE WHEN Win='赢' THEN 1 END)+0.0)/(count(hero)+0.0))*100),2) || '%' AS '胜率' FROM 'heroData' WHERE Bot='电脑' GROUP BY Hero HAVING COUNT(Hero)>=50 ORDER BY 胜率值 DESC;`, (data) => {
            if (data.length > 0) {
                res.send(JSON.stringify(data));
            }
        })
    break;
    //装备统计数据
    case 'getItemsMatch':
        serverdb.queryData(`SELECT hero AS 英雄, 装备,((次数 +0.0)/(总数 +0.0)) AS 胜率值 ,Round((((次数 +0.0)/(总数 +0.0))*100),2) || '%' AS 胜率 FROM (
SELECT hero, 装备,Win,SUM(数量) 次数 FROM (
SELECT hero,item0 AS 装备,Win,COUNT(item0) AS 数量 FROM "heroData" WHERE Bot='电脑' GROUP BY Win,hero,item0 UNION ALL
SELECT hero,item1 AS 装备,Win,COUNT(item0) AS 数量 FROM "heroData" WHERE Bot='电脑' GROUP BY Win,hero,item0 UNION ALL
SELECT hero,item2 AS 装备,Win,COUNT(item0) AS 数量 FROM "heroData" WHERE Bot='电脑' GROUP BY Win,hero,item0 UNION ALL
SELECT hero,item3 AS 装备,Win,COUNT(item0) AS 数量 FROM "heroData" WHERE Bot='电脑' GROUP BY Win,hero,item0 UNION ALL
SELECT hero,item4 AS 装备,Win,COUNT(item0) AS 数量 FROM "heroData" WHERE Bot='电脑' GROUP BY Win,hero,item0 UNION ALL
SELECT hero,item5 AS 装备,Win,COUNT(item0) AS 数量 FROM "heroData" WHERE Bot='电脑' GROUP BY Win,hero,item0) GROUP BY Win,hero,装备 ORDER BY 装备,hero, 数量 DESC) AS ITEM LEFT OUTER JOIN (
SELECT hero, 装备,SUM(数量) 总数 FROM (
SELECT hero,item0 AS 装备,Win,COUNT(item0) AS 数量 FROM "heroData" WHERE Bot='电脑' GROUP BY Win,hero,item0 UNION ALL
SELECT hero,item1 AS 装备,Win,COUNT(item0) AS 数量 FROM "heroData" WHERE Bot='电脑' GROUP BY Win,hero,item0 UNION ALL
SELECT hero,item2 AS 装备,Win,COUNT(item0) AS 数量 FROM "heroData" WHERE Bot='电脑' GROUP BY Win,hero,item0 UNION ALL
SELECT hero,item3 AS 装备,Win,COUNT(item0) AS 数量 FROM "heroData" WHERE Bot='电脑' GROUP BY Win,hero,item0 UNION ALL
SELECT hero,item4 AS 装备,Win,COUNT(item0) AS 数量 FROM "heroData" WHERE Bot='电脑' GROUP BY Win,hero,item0 UNION ALL
SELECT hero,item5 AS 装备,Win,COUNT(item0) AS 数量 FROM "heroData" WHERE Bot='电脑' GROUP BY Win,hero,item0) GROUP BY hero,装备 ORDER BY 装备,hero, 数量 DESC) AS COUN USING (Hero, 装备) WHERE Win='赢' AND 总数 > 100 AND 装备 <> 'none' AND 装备 <> '未知物品' ORDER BY 胜率值 DESC`, (data) => {
            if (data.length > 0) {
                res.send(JSON.stringify(data));
            }
        })
    break;
    //锦囊数据
    case 'getKitsData':
        serverdb.queryData(`SELECT heroData.GameID AS 游戏Id,heroData.Hero AS 英雄,kill AS 击杀,Death AS 死亡,Assist AS 助攻,Level AS 等级,Win AS 输赢,Ability AS 技能,Talent AS 天赋,Buy AS 购买清单,Sell AS 替换清单,Auxiliary AS 是否辅助装备 FROM heroData LEFT OUTER JOIN kits ON heroData.GameID=kits.GameId AND heroData.Hero=kits.Hero WHERE kits.GameId IS NOT NULL ORDER BY 英雄`, (data) => {
            if (data.length > 0) {
                res.send(JSON.stringify(data));
            }
        })
    break;
    //锦囊统计数据
    case 'getKitsDataCount':
        serverdb.queryData(`SELECT heroData.Hero AS 英雄,CAST (avg(kill) AS int) AS 平均击杀,CAST (avg(Death) AS int) AS 平均死亡,CAST (avg(Assist) AS int) AS 平均助攻,CAST (avg(Level) AS int) AS 平均等级,count(CASE WHEN Win='赢' THEN 1 END) AS '胜利场数',count(CASE WHEN Win='输' THEN 1 END) AS '失败场数',(count(CASE WHEN Win='赢' THEN 1 END)+0.0)/(count(heroData.Hero)+0.0) AS '胜率值',Round((((count(CASE WHEN Win='赢' THEN 1 END)+0.0)/(count(heroData.Hero)+0.0))*100),2) || '%' AS '胜率',Ability AS 技能,Talent AS 天赋,Buy AS 购买清单,Sell AS 替换清单,Auxiliary AS 是否辅助装备 ,Ability || Talent || Buy || Sell || Auxiliary AS 锦囊 FROM heroData LEFT OUTER JOIN kits ON heroData.GameID=kits.GameId AND heroData.Hero=kits.Hero WHERE kits.GameId IS NOT NULL GROUP BY 锦囊 ORDER BY 英雄, 胜率值 DESC`, (data) => {
            if (data.length > 0) {
                res.send(JSON.stringify(data));
            }
        })
    break;
    //云锦囊模块
    case 'getcloudkits':
        serverdb.queryData(`
SELECT
	锦囊信息.英雄, 锦囊信息.胜利场数, 锦囊信息.失败场数, 锦囊信息.胜率, 锦囊信息.技能, 锦囊信息.天赋, 锦囊信息.购买清单, 锦囊信息.替换清单, 锦囊信息.是否辅助装备 
FROM
	(
	SELECT
		heroData.Hero AS 英雄,
		count( CASE WHEN Win = '赢' THEN 1 END ) AS '胜利场数',
		count( CASE WHEN Win = '输' THEN 1 END ) AS '失败场数',
	( count( CASE WHEN Win = '赢' THEN 1 END ) + 0.0 ) / ( count( heroData.Hero ) + 0.0 ) AS '胜率值',
	Round(
		(
		( ( count( CASE WHEN Win = '赢' THEN 1 END ) + 0.0 ) / ( count( heroData.Hero ) + 0.0 ) ) * 100 
	),
	2 
	) || '%' AS '胜率',
	Ability AS 技能,
	Talent AS 天赋,
	Buy AS 购买清单,
	Sell AS 替换清单,
	Auxiliary AS 是否辅助装备 ,
	Ability || Talent || Buy || Sell || Auxiliary AS 锦囊 
FROM
	heroData
	LEFT OUTER JOIN kits ON heroData.GameID = kits.GameId 
	AND heroData.Hero = kits.Hero 
WHERE
	kits.GameId IS NOT NULL 
	AND heroData.Bot = '电脑' 
GROUP BY
	锦囊 
HAVING
	COUNT( Win ) >= 4 
	AND 英雄 = '${result.data.bot}' 
ORDER BY
	cast(( 胜利场数/ 10 ) as int) DESC, 胜率值 DESC 
	) AS 锦囊信息
	LEFT OUTER JOIN (
	SELECT
		hero AS '英雄',
	( count( CASE WHEN Win = '赢' THEN 1 END ) + 0.0 ) / ( count( Hero ) + 0.0 ) AS '胜率值' 
FROM
	'heroData' 
WHERE
	Bot = '电脑' 
GROUP BY
	Hero 
	) AS 英雄胜率 ON 锦囊信息.英雄 = 英雄胜率.英雄 
WHERE
	锦囊信息.胜率值 > 英雄胜率.胜率值
`, (data) => {
            if (data.length > 0) {
                res.send(`res:${JSON.stringify(data[randomNum(0, Math.ceil(data.length - 1) / 3)])}`);
            }
        })
    break;
    case 'getuuid':
        serverdb.queryData(`SELECT uuid from UUID where ip = '${ip}';`, (data) => {
            if (data.length > 0) {
                res.send(`UUID:${data[0].uuid}`);
            } else {
                let newUUID = uuid.v1()
                serverdb.queryData(`
                INSERT INTO UUID (ip, uuid)
                VALUES (
                '${ip}',
                '${newUUID}'
                );
                `, () => {
                    res.send(`UUID:${newUUID}`);
                });
            }
        });
    break;
    case 'delUUID':
        serverdb.executeSql(`DELETE FROM UUID WHERE ip = '${ip}';`)
    break;
    default:
        res.send({error: '未知指令'});
    break;
  }

});
//message
function startRequest(message, ctx) {
    let time = new Date();
    time = time.setDate(time.getDate() - 7);
    time = new Date(time);
    if (message.indexOf('-') === 0) {
        //游戏内输入指令
        let send = `什么？哦哦~`
        if (message.toLowerCase().indexOf('-levelbots') !== -1) {//bot升级
            send = `我觉得我变强了(๑•̀ㅂ•́)و✧`;
        } else if (message.toLowerCase().indexOf('-givebots') !== -1) {//给bot物品
            send = `看看我得到了什么好东西(o゜▽゜)o☆`;
        } else if (message.toLowerCase().indexOf('-item') !== -1) {//给玩家物品
            send = `有人耍赖~举报举报(′д｀σ)σ`;
        } else if (message.toLowerCase().indexOf('-respawn') !== -1) {//复活
            send = `是不是玩不起ε=( o｀ω′)ノ`;
        } else if (message.toLowerCase().indexOf('-refresh') !== -1) {//刷新状态
            send = `（＞人＜；）`;
        } else if (message.toLowerCase().indexOf('-lvlup') !== -1) {//玩家升级
            send = `永远也追不上你的升级速度(。_。)`;
        } else if (message.toLowerCase().indexOf('-levelmax') !== -1) {//玩家升满级
            send = `GG，成神了(￣﹏￣；)`;
        } else if (message.toLowerCase().indexOf('-gold') !== -1) {//玩家添加金钱
            send = `别以为我不知道你藏了私房钱(*≧︶≦))(￣▽￣* )ゞ`;
        }
        serverdb.queryData(`SELECT count from message where message = '${message.toLowerCase()}' and content = '${send}';`, (data) => {
            if (data.length > 0) {
                serverdb.executeSql(`
                UPDATE message
                SET count = ${data[0].count + 1}
                WHERE message = '${message.toLowerCase()}' and content = '${send}';
                `)
                sendCheck(ctx, send)
            } else {
                serverdb.queryData(`
                INSERT INTO message (message, content, time, count)
                VALUES (
                '${message.toLowerCase()}',
                '${send}',
                '${dateFormat("YYYY-mm-dd HH:MM:SS", new Date())}',
                1
                );
                `, () => {
                    sendCheck(ctx, send)
                });
            }
        });
    } else {
        serverdb.queryData(`SELECT content, time, count from message where message = '${message}' ORDER BY count DESC;`, (data) => {
            if (data.length > 0) {
                let content = data[randomNum(0, data.length - 1)]
                if (new Date(content.time) < time && content.count < 30) {
                    serverdb.executeSql(`DELETE FROM message WHERE message = '${message}' and content = '${content.content}';`)
                    getmessage(message, ctx)
                } else {
                    if (content.count < 10) {
                        getmessage(message, ctx)
                    } else {
                        serverdb.executeSql(`
                        UPDATE message
                        SET count = ${content.count + 1}
                        WHERE message = '${message}' and content = '${content.content}';
                        `)
                        sendCheck(ctx, content.content)
                    }
                }
            } else {
                getmessage(message, ctx)
            }
        })
    }
}

function getmessage(message, ctx) {
    if (apicont < 1000) {
        apicont ++
        // 采用http模块向服务器发起一次get请求     
        http.get(`http://api.qingyunke.com/api.php?key=free&appid=0&msg=${encodeURI(message)}`, res => {
            // 防止中文乱码
            res.setEncoding('utf-8');
            // 监听data事件，每次取一块数据
            res.on('data', chunk => {
                let content = JSON.parse(chunk).content
                serverdb.queryData(`SELECT count from message where message = '${message}' and content = '${content}';`, (data) => {
                    if (data.length > 0) {
                        serverdb.executeSql(`
                        UPDATE message
                        SET count = ${data[0].count + 1}
                        WHERE message = '${message}' and content = '${content}';
                        `)
                        sendCheck(ctx, content)
                    } else {
                        serverdb.queryData(`
                        INSERT INTO message (message, content, time, count)
                        VALUES (
                        '${message}',
                        '${content}',
                        '${dateFormat("YYYY-mm-dd HH:MM:SS", new Date())}',
                        1
                        );
                        `, () => {
                            sendCheck(ctx, content)
                        });
                    }
                });
                
            });
        }).on('error', err => {
            ctx.send(`res:对不起，网络故障了`);
        });
    } else {
        ctx.send({error: '当前服务超过上限'});
    }
}
function sendCheck(ctx, content) {
    serverdb.queryData(`SELECT content from blockWord where content = '${content}';`, (data) => {
        if (data.length > 0) {
            ctx.send(`res:(⊙﹏⊙)，不想做出回答。`);
        } else {
            ctx.send(`res:${content}`);
        }
    })
}
//gameEnd
function installHeroData(heroData, gameInfo) {
    serverdb.executeSql(`
    INSERT INTO heroData (GameID, Hero, MaxHealth, MaxMana, kill, Death, Assist, Level, Gold, Item0, Item1, Item2, Item3, Item4, Item5, Team, Win, Time, Date, Bot, BotScript)
    VALUES (
    '${gameInfo.uuid}',
    '${heroData.Hero}',
    '${heroData.MaxHealth}',
    '${heroData.MaxMana}',
    '${heroData.kill}',
    '${heroData.Death}',
    '${heroData.Assist}',
    '${heroData.Level}',
    '${heroData.Gold}',
    '${heroData.Item0}',
    '${heroData.Item1}',
    '${heroData.Item2}',
    '${heroData.Item3}',
    '${heroData.Item4}',
    '${heroData.Item5}',
    '${heroData.Team}',
    '${heroData.Win == 'true' ? '赢' : '输'}',
    '${gameInfo.gameTime}',
    '${dateFormat("YYYY-mm-dd HH:MM:SS", new Date())}',
    '${heroData.Bot == 'false' ? '玩家' : '电脑'}',
    '${gameInfo.script}'
    );
    `);
    if (heroData.kits) {
        heroData.kits = JSON.parse(heroData.kits)
        serverdb.executeSql(`
        INSERT INTO kits (GameID, Hero, Ability, Talent, Buy, Sell, Auxiliary)
        VALUES (
        '${gameInfo.uuid}',
        '${heroData.Hero}',
        '${heroData.kits.KitName}',
        '${JSON.parse(heroData.kits.Ability.replace(/[&\|\\\*^%$#@\-]/g,""))}',
        '${JSON.parse(heroData.kits.Talent.replace(/[&\|\\\*^%$#@\-]/g,""))}',
        '${JSON.parse(heroData.kits.Buy.replace(/[&\|\\\*^%$#@\-]/g,""))}',
        '${JSON.parse(heroData.kits.Sell.replace(/[&\|\\\*^%$#@\-]/g,""))}',
        '${heroData.kits.Auxiliary}'
        );
        `);
    }
}
//杂项
function randomNum(minNum,maxNum){ 
    switch(arguments.length){ 
        case 1: 
            return parseInt(Math.random()*minNum+1,10); 
        case 2: 
            return parseInt(Math.random()*(maxNum-minNum+1)+minNum,10); 
        default: 
            return 0; 
    } 
}

function dateFormat(fmt, date) {
    let ret;
    let opt = {
        "Y+": date.getFullYear().toString(),        // 年
        "m+": (date.getMonth() + 1).toString(),     // 月
        "d+": date.getDate().toString(),            // 日
        "H+": date.getHours().toString(),           // 时
        "M+": date.getMinutes().toString(),         // 分
        "S+": date.getSeconds().toString()          // 秒
        // 有其他格式化字符需求可以继续添加，必须转化成字符串
    };
    for (let k in opt) {
        ret = new RegExp("(" + k + ")").exec(fmt);
        if (ret) {
            fmt = fmt.replace(ret[1], (ret[1].length == 1) ? (opt[k]) : (opt[k].padStart(ret[1].length, "0")))
        };
    };
    return fmt;
}

module.exports = router;