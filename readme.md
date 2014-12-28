# Description
This is a template expert framework for using with MetaTrader4.
License: Apache 2.0
Features:
- Works only with one ticket/order at time.
- Hides the logic for opening, modifying and closing the ticket. All you need is to override some abstract methods.
- Specifies the invoke period for expert.
- Has "history is ready" functionality, that is used to yield the expert until the enough history data will be collecated.
- Money management function, that is used to calculate the lot size depending from free margin and stoploss (if provided).

# How to use
See the Example.mq4

# Limitations and not tested features
- Limitation: works only with one order/ticket.
- Expert is tested with OP_BUY and OP_SELL. No other types is tested.
- Not tested on real account and currently used is for history testing.

# For commiters
I am the Java developer, so I prefer to use it's code style.
Use the codestyle, which is similar to this repository classes.
I hate this terrible mq4 codestyle, which is used for all examples.
All commits with bad codestyle will not be merged in.
Some notices:
- Use 4 spaces as indent.
- Use C/Java style ({} on each line, spaces between "for" and "(" and so on).