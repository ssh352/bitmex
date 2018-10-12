\l creds.q
\l utils.q

.utils.loadlib["../lib/cryptoq/src";"cryptoq_binary.q"];
.utils.loadlib["../lib/cryptoq/src";"cryptoq.q"];

// TODO - create testnet account
//settings:`apiHost`apiKey`apiSecret!("testnet.bitmex.com";"";"")   //testnet
settings:`apiHost`apiKey`apiSecret!("www.bitmex.com";apikey;secret)

////////////////////////////////////////////////////////////////////////////////
// Private Functions
////////////////////////////////////////////////////////////////////////////////

hmacsha256:{[k;m]
 if[not all 10 = type each (k;m);
 :`error_type];:.cryptoq.hmac_sha256[k;m];
 }

signature:{[secret;verb;path;nonce;data]
 message:verb,path,string[nonce],data;
 :""sv string hmacsha256[secret;message];
 }

// TODO - tidy up or look for library implementation
urlencode:{$[x like "*[?]*";$[x like "*=*";"&" sv{$[2=count x; "="sv(x 0;ssr[.h.hu x 1;"%??";upper]);x]}each "=" vs/: "&" vs x;x];x]}; 
qtime2unix:{`long$1e-9 * x - 1970.01.01D00:00};

createreq:{[host;verb;urlpath;apiKey;apiSecret;expires;data]
 :upper[verb]," ",urlpath," HTTP/1.1\r\nHost: ",host
 ,$[(apiKey~"")|apiSecret~"";"";"\r\napi-expires: ",string[expires]
 ,"\r\napi-key: ",apiKey,"\r\napi-signature: ",signature[apiSecret;verb;urlpath;expires;data]]
 ,$[data~"";"";"\r\nContent-Length: ",string[count data]
 ,"\r\nContent-Type: application/json"] ,"\r\n\r\n",data;
 }

restapi:{[host;verb;path;data;apiKey;apiSecret]
 if[not(6#10h)~type each(host;verb;path;data;apiKey;apiSecret);
  :`status`header`body!(-1;`;`)
  ];

 urlpath:urlencode path;
 expires:qtime2unix .z.p+00:00:10.000;
 httpresp:(`$":https://",host) createreq[host;verb;urlpath;apiKey;apiSecret;expires;data];
 i:first httpresp ss "\r\n\r\n"; headers:i#httpresp;body:(i+4) _ httpresp; 
 status:("J"$" " vs first["\r\n" vs headers])[1]; 
 header:raze{{enlist[`$x 0]!enlist x[1]}": " vs x}each "\r\n" vs "statusline: ",headers; 
 body:.j.k (i+4) _ httpresp;
 :`status`header`body!(status;header;body);
 };

////////////////////////////////////////////////////////////////////////////////
// Public Functions
////////////////////////////////////////////////////////////////////////////////

getpos:{
  r:restapi[settings`apiHost;"GET";"/api/v1/position";"";
  settings`apiKey;settings`apiSecret];
  :update `$symbol,ltime"Z"$timestamp from r`body;
  };   

getord:{
  r:restapi[settings`apiHost;"GET";"/api/v1/order?reverse=true";
  "";settings`apiKey;settings`apiSecret];
  :update `$symbol,`$side,`$ordStatus,ltime"Z"$transactTime,ltime"Z"$timestamp from r`body;
  };

getwallet:{
  r:restapi[settings`apiHost;"GET";"/api/v1/user/walletSummary";"";
  settings`apiKey;settings`apiSecret];:
  update `$currency,`$symbol,`$transactType from r`body;
  };   

//getNextClOrdID:{$[not `myClOrdID in key `.;myClOrdID::0;[myClOrdID+:1;myClOrdID]]};
//buy             // r:b x:`XBTUSD,1,  11111f
b:buy:ol:cs:{"b `sym,qty[,price]";
  if[0h<>type x;:`status`header`body!(-1;`;`)];
  o:`clOrdID`symbol`side`orderQty!(getNextClOrdID[];
  x 0;`Buy; x 1);
  if[3=count x;o:o,enlist[`price]!enlist[x 2]];
  r:restapi[settings`apiHost;"POST";"/api/v1/order";
  .j.j[o];settings`apiKey;settings`apiSecret];
  :r
  };  
  
//sell           // r:s x:`XBTUSD,1,  11111f
s:sell:os:cl:{"s `sym,qty[,price]";
  if[0h<>type x;:`status`header`body!(-1;`;`)];
  o:`clOrdID`symbol`side`orderQty!(getNextClOrdID[];x 0;`Sell;x 1);
  if[3=count x;o:o,enlist[`price]!enlist[x 2]];
  r:restapi[settings`apiHost;"POST";"/api/v1/order";
  .j.j[o];settings`apiKey;settings`apiSecret];
  :r
  };  

//cancel        // r: cc 5
c:cancel:{"c clOrdID(j)";
  if[-7h<>type x;:`status`header`body!(-1;`;`)];
  r:restapi[settings`apiHost;"DELETE";"/api/v1/order";
  .j.j[enlist[`clOrdID]!enlist[string x]];
  settings`apiKey;settings`apiSecret]
  ;:r
  };  

od:{
  r:restapi[settings`apiHost;"GET";"/api/v1/order?reverse=true&columns=",.j.j[`clOrdID`symbol`side`orderQty`price`ordStatus`cumQty`avgPx`timestamp];"";settings`apiKey;settings`apiSecret];
  :select "J"$clOrdID,ltime"Z"$timestamp,`$symbol,`$side,orderQty,price,`$ordStatus,cumQty,avgPx from r`body;
  }; 

ps:{
  r:restapi[settings`apiHost;"GET";"/api/v1/position?columns=",.j.j[`symbol`currentQty`avgCostPrice`marginCallPrice`maintMargin`lastPrice`timestamp];"";settings`apiKey;settings`apiSecret];
  :select ltime"Z"$timestamp,`$symbol,`$currency,currentQty,simpleQty,avgCostPrice,marginCallPrice,markPrice,liquidationPrice,maintMargin,lastPrice from r`body;
  };
