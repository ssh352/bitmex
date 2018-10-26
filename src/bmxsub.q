\c 200 200

\l utils.q
\l creds.q

.utils.loadlib["../lib/cryptoq/src";"cryptoq_binary.q"];
.utils.loadlib["../lib/cryptoq/src";"cryptoq.q"];
.utils.loadlib["../lib/ws.q";"ws.q"]

////////////////////////////////////////////////////////////////////////////////
// Exchange Specific Functions
////////////////////////////////////////////////////////////////////////////////

.bitmex.sub:{[url;auth;topics]
 h:.ws.open[url;`.ccfh.upd];
 if[null h;:0Ni];
 show `$"Connected ",url," at ",(-3!.z.z);
 if[auth;
   expires:`long$10e-9 * .z.p - 1970.01.01D00:00;
   sig:""sv string .cryptoq.hmac_sha256[secret;"GET/realtime",string expires];
   h .j.j `op`args!`authKeyExpires,enlist (apikey;expires;sig);
   ];
 h .j.j `op`args!`subscribe,enlist topics;
 h
 }

.bitfinex.sub:{[url;auth;subdict]
 h:.ws.open[url;`.ccfh.upd];
 if[null h;:0Ni];
 // query for list of available symbols
 allsyms:.req.get["https://api.bitfinex.com/v1/symbols";()!()];
 show `$"Connected ",url," at ",(-3!.z.z);
 {[h;d;x] h .j.j d,enlist[`symbol]!enlist x}[h;subdict] each `$allsyms;
 h
 }

.gemini.sub:{[url;auth;subdict]
 h:.ws.open[url;`.ccfh.upd];
 if[null h;:0Ni];
 // query for list of available symbols
 //allsyms:.req.get["https://api.gemini.com/v1/symbols";()!()];
 show `$"Connected ",url," at ",(-3!.z.z);
 //{[h;d;x] h .j.j d,enlist[`symbol]!enlist x}[h;subdict] each `$allsyms;
 h
 }

.poloniex.sub:{[url;auth;subdict]
 h:.ws.open[url;`.ccfh.upd];
 if[null h;:0Ni];
 show `$"Connected ",url," at ",(-3!.z.z);
 h .j.j `command`subscribe!(`channel;1002);
 h .j.j `command`subscribe!(`channel;1003);
 h
 }

.binance.sub:{[url;auth;subdict]
 h:.ws.open[url;`.ccfh.upd];
 if[null h;:0Ni];
 show `$"Connected ",url," at ",(-3!.z.z);
 h
 }

.hitbtc.subfeed:{[h;tbl;x] 
 h .j.j `method`id`params!(`$"subscribe",tbl;123;enlist[`symbol]!enlist x)
 }

.hitbtc.sub:{[url;auth;subdict]
 h:.ws.open[url;`.ccfh.upd];
 if[null h;:0Ni];
 show `$"Connected ",url," at ",(-3!.z.z);
 allsyms:exec `$id from .req.get["https://api.hitbtc.com/api/2/public/symbol";()!()];
 .hitbtc.subfeed[h;"Ticker"] each allsyms;
 .hitbtc.subfeed[h;"Orderbook"] each allsyms;
 .hitbtc.subfeed[h;"Trades"] each allsyms;
 h
 }

.coinbasepro.sub:{[url;auth;subdict]
 h:.ws.open[url;`.ccfh.upd];
 if[null h;:0Ni];
 show `$"Connected ",url," at ",(-3!.z.z);
 // NOTE - there is also a level 3 feed available
 h .j.j `type`product_ids`channels!(`subscribe;`$" "vs"ETH-EUR ETH-USD";`level2`ticker`matches);
 h
 }

.btcc.sub:{[url;auth;subdict]
 h:.ws.open[url;`.ccfh.upd];
 if[null h;:0Ni];
 show `$"Connected ",url," at ",(-3!.z.z);
 show h .j.j enlist[`action]!enlist `SubscribeAllTickers;
 h
 }

.bitflyer.sub:{[url;auth;subdict]
 h:.ws.open[url;`.ccfh.upd];
 if[null h;:0Ni];
 show `$"Connected ",url," at ",(-3!.z.z);
 show h .j.j ("subscribe";enlist[`channel]!enlist`lightning_board_snapshot_BTC_JPY);
 show h .j.j ("subscribe";enlist[`channel]!enlist`lightning_board_BTC_JPY);
 show h .j.j ("subscribe";enlist[`channel]!enlist`lightning_ticker_BTC_JPY);
 show h .j.j ("subscribe";enlist[`channel]!enlist`lightning_executions_BTC_JPY);
 h
 }

////////////////////////////////////////////////////////////////////////////////
// Schemas
////////////////////////////////////////////////////////////////////////////////

// TODO - type fields
.ccfh.subs:([] name:`$(); subfunc:(); url:(); authenticate:`boolean$(); exargs:(); handle:`long$(); logh:`long$(); lastmsg:`timestamp$())

// TODO - move this to config
.bitmex.topics:`orderBookL2`trade`instrument`connected`announcement;
.bitmex.topics,:`publicNotifications`funding`insurance`liquidation;
.bitmex.topics,:`settlement`execution`order`margin`position`transact`wallet;

.bitfinex.subdict:`event`channel!`subscribe`trade

// TODO - try this with 1 connection - is the 250 symbols limit fixed
.ccfh.subs,:(`Bitfinex; .bitfinex.sub;  "wss://api.bitfinex.com/ws/2";                0b;`event`channel!`subscribe`trades; 0Ni;0Ni;0Np)
.ccfh.subs,:(`Bitfinex; .bitfinex.sub;  "wss://api.bitfinex.com/ws/2";                0b;`event`channel!`subscribe`ticker; 0Ni;0Ni;0Np)
.ccfh.subs,:(`Bitfinex; .bitfinex.sub;  "wss://api.bitfinex.com/ws/2";                0b;`event`channel`precision!`subscribe`book`R0; 0Ni;0Ni;0Np)
.ccfh.subs,:(`BitMEX;   .bitmex.sub;    "wss://www.bitmex.com/realtime";              0b;.bitmex.topics;    0Ni;0Ni;0Np)
//.ccfh.subs,:(`Bitstamp;  .bitstamp.sub;   "wss://ws.lightstream.bitflyer.com/json-rpc";0b;()!(); 0Ni;0Ni;0Np)
.ccfh.subs,:(`CoinbasePro;.coinbasepro.sub;"wss://ws-feed.pro.coinbase.com";          0b;()!(); 0Ni;0Ni;0Np)
.ccfh.subs,:(`Gemini;   .gemini.sub;    "wss://api.gemini.com/v1/marketdata/btcusd";  0b;()!(); 0Ni;0Ni;0Np)
//.ccfh.subs,:(`HitBTC;    .hitbtc.sub;    "wss://api.hitbtc.com/api/2/ws";             0b;()!(); 0Ni;0Ni;0Np)
.ccfh.subs,:(`Poloniex; .poloniex.sub;  "wss://api2.poloniex.com";                    0b;()!(); 0Ni;0Ni;0Np)

.ccfh.subs,:(`Binance;  .binance.sub;   "wss://stream.binance.com:9443/stream?streams=!ticker@trade/!ticker@arr/!ticker@depth";              0b;()!(); 0Ni;0Ni;0Np)
.ccfh.subs,:(`BTCC;      .btcc.sub;       "wss://ws.btcc.com";                        0b;()!(); 0Ni;0Ni;0Np)
//.ccfh.subs,:(`bitFlyer;  .bitflyer.sub;   "wss://ws.lightstream.bitflyer.com/json-rpc";0b;()!(); 0Ni;0Ni;0Np)

////////////////////////////////////////////////////////////////////////////////
// z handlers
////////////////////////////////////////////////////////////////////////////////

\t 1000

.z.ts:{[x]
 if[.ccfh.currdate <> d:`date$x;
  @[hclose;;{'`$"Failed to close socket - ",x}] each abs allh where not null allh:raze .ccfh.subs`handle`logh;
  .ccfh.subs:update logh:.ccfh.initlog[":../data/raw";;"msgs_";d] each string name, handle:0Ni from .ccfh.subs;
  .ccfh.currdate:d;
  ];

 // TODO - is this really necessary?
 tst1:select from .ccfh.subs where not null handle, not neg[handle] in key .z.W;
 if[0 < count tst1;show `$"test 1 - still required - investigate"];
 .ccfh.subs:update handle:0Ni from .ccfh.subs where not null handle, not neg[handle] in key .z.W;
  
  // re-establish closed connections
 .ccfh.subs:update handle:{[f;x;y;z] f[x;y;z]}'[subfunc;url;authenticate;exargs] from .ccfh.subs where null handle;

 // drop all conns except to ws api
 tst2:key[.z.W] except neg .ccfh.subs`handle;
 if[0 < count tst2;show `$"test 2 - still required - investigate"];
 hclose each key[.z.W] except neg .ccfh.subs`handle;
 }

////////////////////////////////////////////////////////////////////////////////
// Framework Functions
////////////////////////////////////////////////////////////////////////////////

.ccfh.upd:{[x]
 msg:.j.k[x];
 $[99 = type msg;msg,:enlist[`rcvts]!enlist .z.p;msg:raze enlist[msg],.z.p];
 logfile:select logh from .ccfh.subs where neg[handle]=.z.w;
 if[0 = count logfile;show `$"Failed to find .z.w in .ccfh.subs for - ",string .z.w;:()];
 @[first logfile`logh;.j.j[msg],"\n";{'`$"Failed to handle msg - ",-3!x}];
 .ccfh.subs:update lastmsg:.z.p from .ccfh.subs where neg[handle]=.z.w;
 }

.ccfh.disconnected:{[f;x]
 show `$" - "sv(-3!.z.p;string[f];-3!x);
 conn:select from .ccfh.subs where neg[handle]=x;
 if[1=count conn;
  show `$string[first conn`name]," API disconnected at ",(-3!.z.p)," - ",-3!x;
  .ccfh.subs:update handle:0Ni from .ccfh.subs where neg[handle]=x;
  ];
 }

.z.wc:.ccfh.disconnected[`.z.wc]
.z.pc:.ccfh.disconnected[`.z.pc]

.ccfh.initlog:{[path;dir;prefix;d]
 logfile:`$path,"/",dir,"/",prefix,string[d],".json";
 :@[hopen;logfile;{'`$"Failed to open logfile - ",-3!x}];
 }

////////////////////////////////////////////////////////////////////////////////
// Initialization
////////////////////////////////////////////////////////////////////////////////

.ccfh.currdate:0Nd
