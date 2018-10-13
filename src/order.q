// symbol		string    (required) Instrument symbol. e.g. 'XBTUSD'.  
// side			string    Order side. Valid options: Buy, Sell. Defaults to 'Buy' unless orderQty or simpleOrderQty is negative.  
// simpleOrderQty	double    Order quantity in units of the underlying instrument (i.e. Bitcoin).  
// orderQty		double    Order quantity in units of the instrument (i.e. contracts).  
// price		double    Optional limit price for 'Limit', 'StopLimit', and 'LimitIfTouched' orders.  
// displayQty		double    Optional quantity to display in the book. Use 0 for a fully hidden order.  
// stopPx		double    Optional trigger price for 'Stop', 'StopLimit', 'MarketIfTouched', and 'LimitIfTouched' orders. Use a price below the current price for stop-sell orders and buy-if-touched orders. Use execInst of 'MarkPrice' or 'LastPrice' to define the current price used for triggering.  
// clOrdID		string    Optional Client Order ID. This clOrdID will come back on the order and any related executions.  
// clOrdLinkID		string    Optional Client Order Link ID for contingent orders.  
// pegOffsetValue	double    Optional trailing offset from the current price for 'Stop', 'StopLimit', 'MarketIfTouched', and 'LimitIfTouched' orders; use a negative offset for stop-sell orders and buy-if-touched orders. Optional offset from the peg price for 'Pegged' orders.  
// pegPriceType 	string    Optional peg price type. Valid options: LastPeg, MidPricePeg, MarketPeg, PrimaryPeg, TrailingStopPeg.  
// ordType		string    Limit Order type. Valid options: Market, Limit, Stop, StopLimit, MarketIfTouched, LimitIfTouched, MarketWithLeftOverAsLimit, Pegged. Defaults to 'Limit' when price is specified. Defaults to 'Stop' when stopPx is specified. Defaults to 'StopLimit' when price and stopPx are specified.  
// timeInForce		string    Time in force. Valid options: Day, GoodTillCancel, ImmediateOrCancel, FillOrKill. Defaults to 'GoodTillCancel' for 'Limit', 'StopLimit', 'LimitIfTouched', and 'MarketWithLeftOverAsLimit' orders.  
// execInst		string    Optional execution instructions. Valid options: ParticipateDoNotInitiate, AllOrNone, MarkPrice, IndexPrice, LastPrice, Close, ReduceOnly, Fixed. 'AllOrNone' instruction requires displayQty to be 0. 'MarkPrice', 'IndexPrice' or 'LastPrice' instruction valid for 'Stop', 'StopLimit', 'MarketIfTouched', and 'LimitIfTouched' orders.  
// contingencyType	string    Optional contingency type for use with clOrdLinkID. Valid options: OneCancelsTheOther, OneTriggersTheOther, OneUpdatesTheOtherAbsolute, OneUpdatesTheOtherProportional.  
// text			string    Optional order annotation. e.g. 'Take profit'.  

getNextClOrdID:{:first -1?0Ng;};

safeargs:`ordType`timeInForce!`Limit`GoodTillCancel

pcheck:{[params;types;valids]
 if[not all m:types = type each params;
  msg:", "sv -3 !/: (til count params;params;types) @\:/: w:where not m;
  '`$"bad param type - ",msg;
  ];
 .[@';(valids;params);{'`$"Failed to apply validators - ",x}];
 } 

createorder:{[sym;side;qty;extraargs] 
 .[pcheck;
   ((sym;side;qty;extraargs);
    (-11;-11;-7;99);
    ({not null x};in[;`Buy`Sell];>[;0];{1b}));
   {'`$"Failed to createorder - ",x}];
 :(`symbol`side`orderQty`clOrdID!(sym;side;qty;getNextClOrdID[])),safeargs,extraargs;
 }

marketorderexargs:{[sym;side;qty;extraargs] 
 :createorder[sym;side;qty;extraargs,enlist[`ordType]!enlist `Market];
 }

marketorder:marketorderexargs[;;;()!()];

limitorderexargs:{[sym;side;qty;price;extraargs] 
 .[pcheck;(price;-9;>[;0.0]);{'`$"Failed to create limitorder - ",x}];
 :createorder[sym;side;qty;extraargs,`price`ordType!(price;`Limit)];
 }

limitorder:limitorderexargs[;;;;()!()];

