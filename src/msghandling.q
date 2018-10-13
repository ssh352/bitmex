\c 40 1000

obupd:{[data]
  mods:(update newsize:size by id from data) lj select by id from .data.ob where id in data`id;
  moddown:select from mods where newsize < size;
  if[0 < count moddown;
    tmp:select from .data.ob where id in moddown`id;
    if[count[moddown] <> count tmp;show each (moddown;tmp)];
    .data.ob:update size:moddown`newsize from .data.ob where any id =/: moddown`id;
    ];
  modup:select from mods where newsize > size;
  if[0 < count modup;
    // TODO - could there be an ordering issue here?
    .data.ob:delete from .data.ob where id in modup`id;
    .data.ob,:delete newsize from update size:newsize from modup;
    ];
  }

get10levels:{[qsym;buysell]
 tbl:select sum size by price from .data.ob where symbol=`$qsym, side=`$buysell;
 :`float$flip value flip 0!10#$[buysell~"Buy";`price xdesc tbl;`price xasc tbl];
 }

.bmx.handlemsg:{[msg]
  if[`table in key msg;
    tbl:`$msg[`table];
    if[tbl~`trade;
      if["insert"~msg`action;
        data:update rcvts:msg`rcvts from typedata . (msg`data;tbl);
        `.data.trade insert data;
        ];
    ];

    if[tbl~`orderBookL2;
      if["partial"~msg`action;
        schemas[tbl]:enlist`$msg`types;
        .data.ob:typedata . msg`data`table;
      ];
      if[not `ob in tables`.data;:()];
      data:typedata . msg`data`table;
      //if["update"~msg`action;obupd[data]];
      if["insert"~msg`action;.data.ob,:delete from data where id in .data.ob`id];
      if["delete"~msg`action;.data.ob::delete from .data.ob where id in data`id];
    ];
  ];
  msgcnt+:1;
  if[0 = msgcnt mod 1000000;show msgcnt];
 }

