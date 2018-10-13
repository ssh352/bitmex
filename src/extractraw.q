\l msgschema.q

dictfilter:`order`transact`wallet`instrument`liquidation`margin`position

extractdata:{[tbl;msgcnt;rts;data]
  // FIXME
  if[`withdrawalLock in key data;data:`withdrawalLock _ data];
  tdata:typedata . (data;tbl);
  tdata:update seqnum:msgcnt, rcvts:rts from tdata;
  :tdata;
  }

.tmp:enlist[`]!enlist[::]
msgcnt:0
extractmsgs:{[msg]
  if[(`table in key msg) and 0 < count msg`data;
    tbl:`$msg`table;
    if["partial"~msg`action;schemas[tbl]:enlist`$msg`types];
    // NOTE - handle all messages as lists of dicts
    data:extractdata each msg`data;
    tblname:`$""sv msg`table`action;
    data:extractdata[tbl;msgcnt;msg`rcvts] each msg`data; 
    if[tbl in dictfilter;data:enlist data];
    $[not tblname in key .tmp;
      @[`.tmp;tblname;:;data];
      .tmp[tblname],:data
    ];
  ];
  msgcnt+:1;
  if[0 = msgcnt mod 1000000;show msgcnt];
  }

schemas:get`:schemas.dat;
.bmx.handlemsg:extractmsgs;
-11!`:../data/BMX_msgs_2018.10.11.log;
`:schemas.dat set schemas;
