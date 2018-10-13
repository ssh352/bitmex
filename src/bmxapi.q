\l order.q
\l creds.q
\l utils.q
\l ../lib/reQ/req.q
.req.VERBOSE:1b
.req.put:{parseresp okstatus[VERBOSE] send[`PUT;x;y;();VERBOSE]} 

.utils.loadlib["../lib/cryptoq/src";"cryptoq_binary.q"];
.utils.loadlib["../lib/cryptoq/src";"cryptoq.q"];

// load the swagger API definition file
bmxapispec:.j.k first read0 `:swagger.json;
bmxpaths:key each bmxapispec[`paths];
bmxapicalls:raze {x ,/: y}'[key bmxpaths;value bmxpaths];

// TODO - test flag on by default and print live banner
settings:`apiProtocol`apiHost`apiKey`apiSecret`apiBasePath!("https://";"testnet.bitmex.com";apikey;secret;bmxapispec[`basePath])
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

qtime2unix:{`long$1e-9 * x - 1970.01.01D00:00};

restapiv2:{[path;reqtype;data]
  if[not (`$(path;lower reqtype)) in bmxapicalls;'`$"Error - Invalid API Call - ",-3!(path;reqtype);];
  expires:qtime2unix .z.p+00:00:10.000;
  sig:signature[settings`apiSecret;reqtype;settings[`apiBasePath],path;expires;data];
  url:(""sv settings`apiProtocol`apiHost`apiBasePath),path;
  dhdrs:(`$" "vs"Host api-expires api-key api-signature")!(settings`apiHost;expires;settings`apiKey;sig);
  :.req.get[url;dhdrs];
  }

////////////////////////////////////////////////////////////////////////////////
// BitMEX API
////////////////////////////////////////////////////////////////////////////////

getpositions:restapiv2["/position";"GET";""]
