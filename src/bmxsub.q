\c 200 200

\l utils.q

privatesubs:0b
if[not () ~ key`:creds.q;
  privatesubs:1b;
  system"l creds.q";
  .utils.loadlib["../lib/cryptoq/src";"cryptoq_binary.q"]
  .utils.loadlib["../lib/cryptoq/src";"cryptoq.q"]
  ];

.utils.loadlib["../lib/ws.q";"ws.q"]

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////

.bmx.upd:{[x]
 if[.bmx.h <> neg .z.w;:()]; // prevent duplicates
 msg:.j.k[x],enlist[`rcvts]!enlist .z.p;
 @[logh;enlist (`.bmx.handlemsg;msg);{'`$"failed to handle msg - ",-3!x}];
 }

checkconn:{[url;topics]
 h:.ws.open[url;`.bmx.upd];
 if[null h;:0N];
 show `$"Connected ",url," at ",(-3!.z.z);
 if[privatesubs;
   expires:`long$10e-9 * .z.p - 1970.01.01D00:00;
   sig:""sv string .cryptoq.hmac_sha256[secret;"GET/realtime",string expires];
   h .j.j `op`args!`authKeyExpires,enlist (apikey;expires;sig);
   ];
 show `$"subscribing to ",","sv string topics;  
 h .j.j `op`args!`subscribe,enlist topics;
 h
 }

////////////////////////////////////////////////////////////////////////////////
// Configuration
////////////////////////////////////////////////////////////////////////////////

//url:"wss://www.testnet.com/realtime" // test stream
url:"wss://www.bitmex.com/realtime";

// market data
//topics:`orderBookL2`trade`instrument
topics:`orderBookL2`trade`instrument;

// info
topics,:`connected`announcement`publicNotifications;

// funding/settlement etc.
topics,:`funding`insurance`liquidation`settlement;


if[privatesubs;
  // private feed
  topics,:`execution`order`margin`position`transact`wallet;
  ];

////////////////////////////////////////////////////////////////////////////////
// z handlers
////////////////////////////////////////////////////////////////////////////////

\t 1000

.z.ts:{[x]
 if[currdate <> d:`date$x;
  logh::initlog[":../data";"BMX_msgs_";d];
  currdate::d;
  .bmx.h:0N; // reestablish connection and trigger snapshots
  ];

 if[null .bmx.h;
  .bmx.h:checkconn[url;topics];
 ];

 if[not null .bmx.h;
   hclose each key[.z.W] except neg .bmx.h; // drop all conns except to ws api
   ];
 }

disconnected:{[f;x]
 show `$" - "sv(-3!.z.p;string[f];-3!x);
 if[x=neg .bmx.h;
  show `$"Bitmex API disconnected at ",(-3!.z.p)," - ",-3!x;
  .bmx.h:0N
  ];
 }

.z.wc:disconnected[`.z.wc]
.z.pc:disconnected[`.z.pc]

////////////////////////////////////////////////////////////////////////////////
// Initialization
////////////////////////////////////////////////////////////////////////////////

initlog:{[path;prefix;d]
 logfile:`$path,"/",prefix,string[d],".log";
 if[()~key logfile;logfile set ()];
 :@[hopen;logfile;{'`$"Failed to open logfile - ",-3!x}];
 }

// setup up logfile
currdate:.z.d
logh:initlog[":../data";"BMX_msgs_";currdate];

// subscribe
.bmx.h:0N;
