pwd:system"pwd"
\cd ../lib/ws.q
\l ws.q
system"cd ",first pwd 

.bmx.info:()
.bmx.subs:()
.bmx.tbls:()!()
.bmx.misc:()

.bmx.handlemsg:{[msg]
 if[`info in key msg;.bmx.info,:enlist msg;:()];
 if[`subscribe in key msg;.bmx.subs,:enlist msg;:()];
 if[`table in key msg;
  tbl:`$msg`table;
  if[not tbl in key .bmx.tbls;@[`.bmx.tbls;tbl;:;()]];
  .bmx.tbls[tbl],:enlist enlist msg;
  :();
  ];
 .bmx.misc:enlist msg;
 }

.bmx.upd:{[x]
 msg:.j.k x;
 @[logh;enlist (`.bmx.handlemsg;msg);{'`$"Failed to handle msg - ",-3!x}];
 .bmx.handlemsg[msg];
 }

url:"wss://www.bitmex.com/realtime"
topics:`orderBookL2`trade`connected`announcement`funding`instrument`insurance`liquidation`publicNotifications`settlement
syms:"XBTUSD ETHUSD ADAZ18 BCHZ18 EOSZ18 LTCZ18 TRXZ18 XRPZ18"

.bmx.h:.ws.open[url;`.bmx.upd]
.bmx.h .j.j `op`args!`subscribe,enlist topics;

logfile:`$":../data/BMX_msgs_",string[.z.d],".log"
if[()~key logfile;logfile set ()];
logh:@[hopen;logfile;{'`$"Failed to open logfile - ",-3!x}];
