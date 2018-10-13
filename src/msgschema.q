parsetimespan:{$[10 = type x;"N"$-1_11_x;`timespan$0Nn]}

parsetyped:({key'[x$\:()]}t)!upper .Q.t t:5h$where" "<>20#.Q.t;

specialparsers:enlist["N"]!enlist parsetimespan;
parsers:{$[x in key specialparsers;specialparsers[x];x$]} each parsetyped;

casttyped:(({key'[x$\:()]}t)!t:5h$where" "<>20#.Q.t),enlist[`]!enlist 0h;

typedata:{[data;tbl]
  schema:first schemas tbl;
  scols:where 10=type each data;
  if[`timestamp in key data;
    data[`timestamp]:-1_data`timestamp;
  ];
  data[scols]:(parsers schema scols)@'data scols;
  data:(casttyped schema cols data)$data;
  :data;
  }
