//+------------------------------------------------------------------+
//|                                                      Example.mq4 |
//|                                               alexoro a.k.a. UAS |
//|                   https://github.com/alexoro/mt4-expert-template |
//+------------------------------------------------------------------+
#property copyright "alexoro"
#property link      "https://github.com/alexoro/mt4-expert-template"
#property version   "1.00"
#property strict

#include "./BaseStrategy.mqh"

class StrategyImpl: public BaseStrategy {

    public:
        virtual int getReadyBarsTimeFrame() {
            return PERIOD_H1;
        }
        
        virtual int getReadyBarsMinCount() {
            return 21;
        }
        
        virtual int getInvokeTimeFrame() {
            return PERIOD_H1;
        }
        
        virtual int getOrderMagicNumber() {
            return 548357385;
        }
        
        virtual bool onShouldOpen(int &type, double &lots, double &price, double &sl, double &tp) {
            double maFast = iMA(NULL, PERIOD_H1, 13, 0, MODE_EMA, PRICE_CLOSE, 1);
            double maSlow = iMA(NULL, PERIOD_H1, 21, 0, MODE_EMA, PRICE_CLOSE, 1);
            if (maFast < maSlow) {
                type = OP_SELL;
                lots = 1;
                price = Bid;
                sl = 0;
                tp = 0;
                return true;
            }
            return false;
        }
        
        virtual bool onShouldModify(double &sl, double &tp) {
            return false;
        }
        
        virtual bool onShouldClose() {
            double maFast = iMA(NULL, PERIOD_H1, 13, 0, MODE_EMA, PRICE_CLOSE, 1);
            double maSlow = iMA(NULL, PERIOD_H1, 21, 0, MODE_EMA, PRICE_CLOSE, 1);
            if (maFast > maSlow) {
                return true;
            }
            return false;
        }

};


StrategyImpl * sStrategy;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    sStrategy = new StrategyImpl();
    sStrategy.onInit();
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    sStrategy.onDeInit();
    delete sStrategy;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    sStrategy.onTick();
}


