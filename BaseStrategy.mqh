//+------------------------------------------------------------------+
//|                                                 BaseStrategy.mqh |
//|                                               alexoro a.k.a. UAS |
//|                   https://github.com/alexoro/mt4-expert-template |
//+------------------------------------------------------------------+
#property copyright "alexoro"
#property link      "https://github.com/alexoro/mt4-expert-template"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


/**
 * Base abstract class for strategy, which implements some functions.
 * The comments for each method is described below in methods implementations.
 * This interface is without comments in order to provide better readability.
 */
class BaseStrategy {
    public:
        BaseStrategy();
        ~BaseStrategy();
        void onInit();
        void onTick();
        void onDeInit();
        double getSpread();
        int generateId();
        int getCurrentOrderTicketIdAndSelect();
        double calculateLot(double riskPercentage, double price);
        double calculateLot(double riskPercentage, double price, double stoploss);

    protected:
        int INVOKE_EACH_TICK;
        virtual int getReadyBarsTimeFrame();
        virtual int getReadyBarsMinCount();
        virtual int getInvokeTimeFrame();
        virtual int getOrderMagicNumber();
        virtual void onInitDelegate();
        virtual void onInvokeDelegate();
        virtual void onDeInitDelegate();
        virtual bool onShouldOpen(int &type, double &lots, double &price, double &sl, double &tp);
        virtual bool onShouldModify(double &sl, double &tp);
        virtual bool onShouldClose();

    private:
        int m_invokeLastTotalBars;
        int m_generatedId;
        int openPosition(int type, double lots, double price, double sl, double tp);
        bool modifyPosition(double sl, double tp);
        bool closePosition();
};

/**
 * Constructor
 */
BaseStrategy::BaseStrategy() {

}

/**
 * Destructor
 */
BaseStrategy::~BaseStrategy() {

}

/**
 * Call this method in expert implementation.
 * This method initializes the expert.
 */
void BaseStrategy::onInit(void) {
    m_invokeLastTotalBars = -1;
    m_generatedId = 0;
    INVOKE_EACH_TICK = -1;
    onInitDelegate();
}

/**
 * Call this method in expert implementation.
 * This method de-initilizes the expert.
 */
void BaseStrategy::onDeInit(void) {
    onDeInitDelegate();
}

/**
 * Call this method in expert implementation.
 * This method is responsible for operations with order and it's lifecycle.
 */
void BaseStrategy::onTick(void) {
    int totalBarsNowForStart = Bars(NULL, getReadyBarsTimeFrame());
    if (totalBarsNowForStart < getReadyBarsMinCount()) {
         return;
    }
    
    if (getInvokeTimeFrame() != INVOKE_EACH_TICK) {
        int totalBarsNowForInvoke = Bars(NULL, getInvokeTimeFrame());
        if (totalBarsNowForInvoke == m_invokeLastTotalBars) {
            return;
        } else {
            m_invokeLastTotalBars = totalBarsNowForInvoke;
        }
    }
    
    onInvokeDelegate();
    
    int ticketId = getCurrentOrderTicketIdAndSelect();
    
    if (ticketId != -1) {
        if (onShouldClose()) {
            closePosition();
            ticketId = -1;
        }
        if (ticketId != -1) {
            double sl, tp;
            if (onShouldModify(sl, tp)) {
                modifyPosition(sl, tp);
            }
        }
    } else {
        int type;
        double lots, price, sl, tp;
        if (onShouldOpen(type, lots, price, sl, tp)) {
            openPosition(type, lots, price, sl, tp);
        }
    }
}

/**
 * Execute the order opening.
 * @param type Order type: OP_BUY, OP_SELL and etc
 * @param lots The volume for the order
 * @param price Price Ask, Bid or etc.
 * @param sl StopLoss price level. Use 0 to ignore StopLoss
 * @param tp TakeProfit price level. Use 0 to ignore TakeProfit
 * @return Order/Ticket id
 */
int BaseStrategy::openPosition(int type, double lots, double price, double sl, double tp) {
    int ticketId = -1;
    for (int i = 0; i < 5; i++) {
        ticketId = OrderSend(
            NULL, type,
            NormalizeDouble(lots, Digits()), NormalizeDouble(price, Digits()), 2,
            NormalizeDouble(sl, Digits()), NormalizeDouble(tp, Digits()),
            NULL, getOrderMagicNumber(), 0, clrGreen);
        if (ticketId >= 0) {
            break;
        } else if (GetLastError() == ERR_REQUOTE) {
            Sleep(3000);
            RefreshRates();
        } else {
            break;
        }
    }
    return ticketId;
}

/**
 * Modify the current order params
 * @param sl New StopLoss price level
 * @param tp New TakeProfit price level
 * @return True, if modification was successful
 */
bool BaseStrategy::modifyPosition(double sl, double tp) {
    tp = tp == OrderTakeProfit() ? 0 : tp;
    sl = sl == OrderStopLoss() ? 0 : sl;
    for (int i = 0; i < 5; i++) {
        bool ok = OrderModify(
            OrderTicket(), 0,
            NormalizeDouble(sl, Digits()), NormalizeDouble(tp, Digits()),
            NULL, clrYellow);
        if (ok) {
            return true;
        } else if (GetLastError() == ERR_REQUOTE) {
            Sleep(3000);
            RefreshRates();
        } else {
            return false;
        }
    }
    return false;
}

/**
 * Close the current order
 * @return True if order was closed
 */
bool BaseStrategy::closePosition(void) {
    double price = OrderType() == OP_BUY ? Bid : Ask;
    for (int i = 0; i < 5; i++) {
        bool ok = OrderClose(OrderTicket(), OrderLots(), price, 2, clrRed);
        if (ok) {
            return true;
        } else {
            Sleep(3000);
            RefreshRates();
        }
    }
    return false;
}


// =============================================================
// =============================================================
// =============================================================

/**
 * @return Get spread current level in price-form (points)
 */
double BaseStrategy::getSpread() {
    return MarketInfo(Symbol(), MODE_SPREAD) / MathPow(10.0, Digits());
}

/**
 * @return Genrate the unique ID. May be used for chart objects.
 */
int BaseStrategy::generateId() {
    m_generatedId++;
    return m_generatedId;
}

/**
 * @return Get current order/ticket id or -1
 */
int BaseStrategy::getCurrentOrderTicketIdAndSelect() {
    int ticketId = -1;
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        bool selectOk = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if (selectOk && OrderSymbol() == Symbol() && OrderMagicNumber() == getOrderMagicNumber()) {
            ticketId = OrderTicket();
            break;
        }
    }
    return ticketId;
}

/**
 * Calculate lot volume for specified price and risk percentage.
 * Depends on current free margin. Current leverage is used in calculation.
 * Usage example:
 * 1 lot is equal to 1000$
 * price = 1.00
 * risk = 0.5 (~50%)
 * balance = 1000$
 * The return value will be 0.5 lots.
 *
 * @param riskPercentage Risk percentage from current margin. Use values like 0.02 (2%), 0.05 (5%) and so on
 * @price Price, that will be used for calculation
 * @return Lot size to use for trade or -1 if there is no margin to be used with specified risk
 */
double BaseStrategy::calculateLot(double riskPercentage, double price) {
    double minLot  = MarketInfo(Symbol(), MODE_MINLOT);
    double maxLot  = MarketInfo(Symbol(), MODE_MAXLOT);
    double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    double lotSize = MarketInfo(Symbol(), MODE_LOTSIZE);
    double margin  = AccountFreeMargin();

    double riskMargin = margin * riskPercentage * AccountLeverage();
    double lots = NormalizeDouble(riskMargin / lotSize, 2);
    lots = NormalizeDouble(NormalizeDouble(lots/lotStep, 0) * lotStep, 2);

    if (lots < minLot) {
        return -1;
    }
    if (lots > maxLot) {
        lots = maxLot;
    }

    return lots;
}

/**
 * Calculate lot volume for specified price and risk percentage.
 * Depends on current free margin and specified stoploss price level. Current leverage is used in calculation.
 * Usage example:
 * 1 lot is equal to 1000$
 * price = 1.00
 * risk = 0.5 (~50%)
 * stoploss = 0.5
 * balance = 1000$
 * The return value will be 1 lot.
 *
 * @param riskPercentage Risk percentage from current margin. Use values like 0.02 (2%), 0.05 (5%) and so on
 * @param Price, that will be used for calculation
 * @param stoploss StopLoss price level
 * @return Lot size to use for trade or -1 if there is no margin to be used with specified risk
 */
 double BaseStrategy::calculateLot(double riskPercentage, double price, double stoploss) {
    double minLot  = MarketInfo(Symbol(), MODE_MINLOT);
    double maxLot  = MarketInfo(Symbol(), MODE_MAXLOT);
    double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    double lotSize = MarketInfo(Symbol(), MODE_LOTSIZE);
    double margin  = AccountFreeMargin();
    
    double riskMargin = margin * riskPercentage * AccountLeverage();
    double riskMarginDiff = riskMargin / (MathAbs(price - stoploss) * AccountLeverage());
    double lots = NormalizeDouble(riskMarginDiff/lotSize, 2);
    lots = NormalizeDouble(NormalizeDouble(lots/lotStep, 0) * lotStep, 2);
    
    if (lots < minLot) {
        return -1;
    }
    if (lots > maxLot) {
        lots = maxLot;
    }

    return lots;
}


// =============================================================
// =============================================================
// =============================================================

/**
 * Sometimes there is no enough history to be used in calculation.
 * Expert will be sleeping until the history will be fullfilled with valid info.
 * Use this method with #getReadyBarsMinCount()
 * @return TimeFrame (PERIOD_H1 and so on), that will be used for #getReadyBarsMinCount()
 */
int BaseStrategy::getReadyBarsTimeFrame() {
    return PERIOD_H1;
}

/**
 * Sometimes there is no enough history to be used in calculation.
 * Expert will be sleeping until the history will be fullfilled with valid info.
 * Use this method with getReadyBarsTimeFrame()
 * @return Minimal number of bars (#getReadyBarsTimeFrame()) to allow the expert' work.
 *         Return -1 to tell the expert to work immidiatly with no waiting for data.
 */
int BaseStrategy::getReadyBarsMinCount() {
    return 0;
}

/**
 * The period when the expert will be invoked for execution.
 * @return Return required period (i.e. PERIOD_H1) or INVOKE_EACH_TICK to invoke expert each tick.
 */
int BaseStrategy::getInvokeTimeFrame() {
    return INVOKE_EACH_TICK;
};

/**
 * Order Magic Number. Must be equal for each expert implementation.
 * @return Order Magic Number, that is used for finding the expert's order.
 */
int BaseStrategy::getOrderMagicNumber() {
    return 0;
}

/**
 * Delegate, that is called on expert's #onInit().
 */
void BaseStrategy::onInitDelegate() {

}

/**
 * Delegate, that is called when expert is invoked.
 * Method is called before all calculations and logic for order.
 */
void BaseStrategy::onInvokeDelegate() {

}

/**
 * Delegate, that is called on expert's #onDeInit().
 */
void BaseStrategy::onDeInitDelegate() {

}

/**
 * This method is used to decide whether the order must be opened or not.
 * All arguments is passed by reference and used by the base expert for opening the orders.
 * @param type Order type: OP_BUY, OP_SELL and so on
 * @param lots Lot/Volume size
 * @param price Order open price, i.e. Ask, Bid
 * @param sl StopLoss price level. Use 0 to ignore
 * @param tp TakeProfit price level. Use 0 to ignore
 * @return True, if order must be opened, false otherwise
 */
bool BaseStrategy::onShouldOpen(int &type, double &lots, double &price, double &sl, double &tp) {
    return false;
}

/**
 * This method is used to decide whether the order must be modified or not.
 * All arguments is passed by reference and used by the base expert for modifying the orders.
 * Order is selected, when this method is called.
 * @param sl New StopLoss price level
 * @param tp New TakeProfit price level
 * @return True, if order must be modified, false otherwise
 */
bool BaseStrategy::onShouldModify(double &sl, double &tp) {
    return false;
}

/**
 * This method is used to decide whether the order must be closed or not.
 * Order is selected, when this method is called.
 * @return True, if order must be closed, false otherwise
 */
bool BaseStrategy::onShouldClose() {
    return false;
}