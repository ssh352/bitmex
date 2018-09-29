\l utils.q
.utils.loadlib["../lib/ws.q";"ws.q"]

////////////////////////////////////////////////////////////////////////////////
// Configuration
////////////////////////////////////////////////////////////////////////////////

.bmx.info:()
.bmx.subs:()
.bmx.tbls:()!()
.bmx.misc:()

.bmx.handlemsg:{[msg]
 if[`info in key msg;.bmx.info,:enlist msg;:()];
 if[`subscribe in key msg;.bmx.subs,:enlist msg;:()];
 if[`table in key msg;
 // tbl:`$msg`table;
 // if[not tbl in key .bmx.tbls;@[`.bmx.tbls;tbl;:;()]];
 // .bmx.tbls[tbl],:enlist enlist msg;
  :();
  ];
 .bmx.misc:enlist msg;
 }

.bmx.upd:{[x]
 msg:.j.k[x],enlist[`rcvts]!enlist .z.p;
 @[logh;enlist (`.bmx.handlemsg;msg);{'`$"Failed to handle msg - ",-3!x}];
 .bmx.handlemsg[msg];
 }

////////////////////////////////////////////////////////////////////////////////
// Configuration
////////////////////////////////////////////////////////////////////////////////

// url:"" // test stream
url:"wss://www.bitmex.com/realtime"

// market data
topics:`orderBookL2`trade`instrument

// info
topics,:`connected`announcement`publicNotifications

// funding/settlement etc.
topics,:`funding`insurance`liquidation`settlement

logfile:`$":../data/BMX_msgs_",string[.z.d],".log"

////////////////////////////////////////////////////////////////////////////////
// Initialization
////////////////////////////////////////////////////////////////////////////////

// setup up logfile
if[()~key logfile;logfile set ()];
logh:@[hopen;logfile;{'`$"Failed to open logfile - ",-3!x}];

// subscribe
.bmx.h:.ws.open[url;`.bmx.upd]
.bmx.h .j.j `op`args!`subscribe,enlist topics;
