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
 if[null h;:0N];
 show `$"Connected ",url," at ",(-3!.z.z);
 if[auth;
   expires:`long$10e-9 * .z.p - 1970.01.01D00:00;
   sig:""sv string .cryptoq.hmac_sha256[secret;"GET/realtime",string expires];
   h .j.j `op`args!`authKeyExpires,enlist (apikey;expires;sig);
   ];
 show `$"subscribing to ",","sv string topics;  
 h .j.j `op`args!`subscribe,enlist topics;
 h
 }

.bitfinex.sub:{[url;auth;subdict]
 h:.ws.open[url;`.ccfh.upd];
 if[null h;:0N];
 show `$"Connected ",url," at ",(-3!.z.z);
 show `$"subscribing to ",-3!subdict;  
 h .j.j subdict;
 h
 }

////////////////////////////////////////////////////////////////////////////////
// Schemas
////////////////////////////////////////////////////////////////////////////////

// TODO - type fields
.ccfh.subs:([] name:(); subfunc:(); url:(); authenticate:(); exargs:(); handle:(); logh:(); lastmsg:())

// TODO - move this to config
.bitmex.topics:`orderBookL2`trade`instrument`connected`announcement;
.bitmex.topics,:`publicNotifications`funding`insurance`liquidation;
.bitmex.topics,:`settlement`execution`order`margin`position`transact`wallet;

.bitfinex.subdict:`event`pair`channel!`subscribe`BTCUSD`ticker

.ccfh.subs,:(`BitMEX;   .bitmex.sub;  "wss://www.bitmex.com/realtime";1b;.bitmex.topics;    0N;`;0Np)
.ccfh.subs,:(`Bitfinex; .bitfinex.sub;"wss://api.bitfinex.com/ws/2";  0b;.bitfinex.subdict; 0N;`;0Np)

////////////////////////////////////////////////////////////////////////////////
// z handlers
////////////////////////////////////////////////////////////////////////////////

\t 1000

.z.ts:{[x]
 if[.ccfh.currdate <> d:`date$x;
  .ccfh.subs:update logh:.ccfh.initlog[":../data";;"msgs_";d] each string name, handle:0N from .ccfh.subs;
  .ccfh.currdate:d;
  ];

 // TODO - is this really necessary?
 tst1:select from .ccfh.subs where not null handle, not neg[handle] in key .z.W;
 if[0 < count tst1;show `$"test 1 - still required - investigate"];
 .ccfh.subs:update handle:0N from .ccfh.subs where not null handle, not neg[handle] in key .z.W;
  
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
 msg:.j.k[x],enlist[`rcvts]!enlist .z.p;
 logfile:first exec logh from .ccfh.subs where neg[handle]=.z.w;
 @[logfile;enlist (`.ccfh.handlemsg;msg);{'`$"Failed to handle msg - ",-3!x}];
 .ccfh.subs:update lastmsg:.z.p from .ccfh.subs where neg[handle]=.z.w;
 }

.ccfh.disconnected:{[f;x]
 show `$" - "sv(-3!.z.p;string[f];-3!x);
 conn:select from .ccfh.subs where neg[handle]=x;
 if[1=count conn;
  show `$string[first conn`name]," API disconnected at ",(-3!.z.p)," - ",-3!x;
  .ccfh.subs:update handle:0N from .ccfh.subs where neg[handle]=x;
  ];
 }

.z.wc:.ccfh.disconnected[`.z.wc]
.z.pc:.ccfh.disconnected[`.z.pc]

.ccfh.initlog:{[path;dir;prefix;d]
 logfile:`$path,"/",dir,"/",prefix,string[d],".log";
 if[()~key logfile;logfile set ()];
 :@[hopen;logfile;{'`$"Failed to open logfile - ",-3!x}];
 }

////////////////////////////////////////////////////////////////////////////////
// Initialization
////////////////////////////////////////////////////////////////////////////////

.ccfh.currdate:0Nd
