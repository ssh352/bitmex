\l order.q
\l creds.q
\l utils.q

.utils.loadlib["../lib/cryptoq/src";"cryptoq_binary.q"];
.utils.loadlib["../lib/cryptoq/src";"cryptoq.q"];

bmxapispec:.j.k first read0 `:swagger.json

// TODO - test flag on by default and print live banner
settings:`apiProtocol`apiHost`apiKey`apiSecret`apiBasePath!("https://";"testnet.bitmex.com";apikey;secret;bmxapispec[`basePath],"/")
//settings:`apiHost`apiKey`apiSecret!("www.bitmex.com";apikey;secret)

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

 // TODO - improve
 urlpath:urlencode path;
 expires:qtime2unix .z.p+00:00:10.000;
 httpresp::(`$":https://",host) httpreq::createreq[host;verb;urlpath;apiKey;apiSecret;expires;data];
 i:first httpresp ss "\r\n\r\n"; headers:i#httpresp;body:(i+4) _ httpresp; 
 status:("J"$" " vs first["\r\n" vs headers])[1]; 
 header:raze{{enlist[`$x 0]!enlist x[1]}": " vs x}each "\r\n" vs "statusline: ",headers; 
 body:.j.k (i+4) _ httpresp;
 :`status`header`body!(status;header;body);
 };

restapiv2:{[host;verb;path;data;apiKey;apiSecret]
 if[not(6#10h)~type each(host;verb;path;data;apiKey;apiSecret);
  :`status`header`body!(-1;`;`)
  ];

 // TODO - improve
 urlpath:urlencode path;
 expires:qtime2unix .z.p+00:00:10.000;
 httpresp::(`$":https://",host) httpreq::createreq[host;verb;urlpath;apiKey;apiSecret;expires;data];
 i:first httpresp ss "\r\n\r\n"; headers:i#httpresp;body:(i+4) _ httpresp; 
 status:("J"$" " vs first["\r\n" vs headers])[1]; 
 header:raze{{enlist[`$x 0]!enlist x[1]}": " vs x}each "\r\n" vs "statusline: ",headers; 
 body:.j.k (i+4) _ httpresp;
 :`status`header`body!(status;header;body);
 };
////////////////////////////////////////////////////////////////////////////////
// Public Functions
////////////////////////////////////////////////////////////////////////////////

// TODO - expose other functions
getpos:{
  r:restapi[settings`apiHost;"GET";"/api/v1/position";"";
  settings`apiKey;settings`apiSecret];
  // TODO - handle empty r`body when no orders have been placed
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

getNextClOrdID:{:first -1?0Ng;};

// TODO - use bulk api instead
// TODO - factor out commonality
// TODO - expose ordertypes and flags
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
  r:restapi[settings`apiHost;"DELETE";"/api/v1/order";
  .j.j[enlist[`clOrdID]!enlist x];
  settings`apiKey;settings`apiSecret]
  ;:r
  };  

// TODO - generalise other functions to support this using cols wildcard
od:{
  r:restapi[settings`apiHost;"GET";"/api/v1/order?reverse=true&columns=",.j.j[`clOrdID`symbol`side`orderQty`price`ordStatus`cumQty`avgPx`timestamp];"";settings`apiKey;settings`apiSecret];
  :select "J"$clOrdID,ltime"Z"$timestamp,`$symbol,`$side,orderQty,price,`$ordStatus,cumQty,avgPx from r`body;
  }; 

ps:{
  r:restapi[settings`apiHost;"GET";"/api/v1/position?columns=",.j.j[`symbol`currentQty`avgCostPrice`marginCallPrice`maintMargin`lastPrice`timestamp];"";settings`apiKey;settings`apiSecret];
  :select ltime"Z"$timestamp,`$symbol,`$currency,currentQty,simpleQty,avgCostPrice,marginCallPrice,markPrice,liquidationPrice,maintMargin,lastPrice from r`body;
  };

neworder:{[orders]
  if[99 = type orders;orders:enlist orders];
  :restapi[settings`apiHost;"POST";"/api/v1/order/bulk";.j.j enlist[`orders]!enlist orders;settings`apiKey;settings`apiSecret];
  }

\l ../lib/reQ/req.q
.req.VERBOSE:1b

restapiv2:{[endpoint;reqtype;data]
  expires:qtime2unix .z.p+00:00:10.000;
  sig:signature[settings`apiSecret;reqtype;settings[`apiBasePath],endpoint;expires;data];
  url:(""sv settings`apiProtocol`apiHost`apiBasePath),endpoint;
  dhdrs:(`$" "vs"Host api-expires api-key api-signature")!(settings`apiHost;expires;settings`apiKey;sig);
  :.req.get[url;dhdrs];
  }

////////////////////////////////////////////////////////////////////////////////
// BitMEX API
////////////////////////////////////////////////////////////////////////////////

//r:restapi[settings`apiHost;"GET";"/api/v1/position";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/apiKey?reverse=false";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/chat?count=100&reverse=true";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/announcement";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/announcement/urgent";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/execution";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/execution/tradeHistory";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/funding";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/instrument";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/order";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/orderBook/L2?symbol=XBTUSD";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/quote?symbol=XBTUSD&reverse=true";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/schema";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/schema/websocketHelp";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/stats";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/trade?symbol=XBTUSD&count=5&start=0&startTime=2018-03-01 00:20:00";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/user";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/user/wallet";"";settings`apiKey;settings`apiSecret];r`body
//r:restapi[settings`apiHost;"GET";"/api/v1/user/walletSummary";"";settings`apiKey;settings`apiSecret];r`body
