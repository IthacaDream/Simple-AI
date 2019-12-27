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
        installHeroData(result.data, result.info)
        serverdb.executeSql(`DELETE FROM UUID WHERE ip = '${ip}';`)
    break;
    case 'getGameData':
        let page = 0
        if (result.data.page) {page = result.data.page}
        serverdb.queryData(`SELECT * from heroData ORDER BY Date LIMIT 100 OFFSET ${page * 30};`, (data) => {
            if (data.length > 0) {
                res.send(JSON.stringify(data));
            }
        })
    break;
    case 'getheat':
        serverdb.queryData(`SELECT hero as 英雄, COUNT(hero) as 热度
        FROM "heroData" where bot = '电脑' GROUP BY hero ORDER BY 热度 DESC`, (data) => {
            if (data.length > 0) {
                res.send(JSON.stringify(data));
            }
        })
    break;
    case 'getGameDataCount':
        serverdb.queryData(`SELECT hero as "英雄" ,cast(avg(kill) as int) as "平均击杀",cast(avg(Death) as int) as "平均死亡", cast(avg(Assist) as int) as "平均助攻", cast(avg(Level) as int) as "平均等级",count(case when Win="赢" then 1 end) as "胜利场数",count(case when Win="输" then 1 end) as "失败场数"
        FROM "heroData" WHERE Bot = "电脑" GROUP BY Hero ORDER BY 胜利场数 DESC, 失败场数 DESC`, (data) => {
            if (data.length > 0) {
                res.send(JSON.stringify(data));
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
                '${new Date()}',
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
                        '${new Date()}',
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
    INSERT INTO heroData (GameID, Hero, MaxHealth, MaxMana, kill, Death, Assist, Level, Gold, Item0, Item1, Item2, Item3, Item4, Item5, Win, Time, Date, Bot)
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
    '${heroData.Win == 'true' ? '赢' : '输'}',
    '${gameInfo.gameTime}',
    '${new Date()}',
    '${heroData.Bot == 'false' ? '玩家' : '电脑'}'
    );
    `);
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

module.exports = router;