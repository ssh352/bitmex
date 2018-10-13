\l msgschema.q
\l msghandling.q

msgcnt:0
.data:enlist[`]!enlist[::]
schemas:get`:schemas.dat
//\ts -11!(150;`:../data/BMX_msgs_2018.10.06.log)
\ts -11!`:../data/BMX_msgs_2018.10.07.log

// {x!count `.tmp[x]} each 1_key `.tmp
// 
// latestob10:select ob10upd:max timestamp by seqnum from .tmp.orderBook10update;
// latestquoins:select quoins:max timestamp by seqnum from .tmp.quoteinsert;
// latesttrdins:select trdins:max timestamp by seqnum from .tmp.tradeinsert;
// 
// 50_`seqnum xasc latestob10 uj latestquoins uj latesttrdins
// 
// select `timespan$avg rcvts - timestamp from .data.trade where not null trdMatchID
// 
// xbtusd:update pdir:prev tickDirection from select from .data.trade where symbol=`XBTUSD;
// delete grossValue, homeNotional, foreignNotional, rcvts from xbtusd 
// 
// tickdir:select symbol, first distinct tickDirection by timestamp, trdMatchID from .data.trade where not null trdMatchID 
// 
// select from tickdir where symbol ~' prev symbol, tickDirection ~' prev tickDirection, tickDirection in `PlusTick`MinusTick
// 
// \c 80 4000
// select from .data.trade where symbol=`XRPZ18, timestamp > 2018.10.06D13:28:30.195000000
// 
// update id:`long$id from select from .tmp.orderBookL2delete where symbol~\:"XRPZ18", rcvts > 2018.10.06D13:27:40.195000000 
// 
// \p 54321

