//+------------------------------------------------------------------+
//|                                                  CustomMACD.mq4  |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property strict
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 Red // Color for MACD Line
#property indicator_color2 LimeGreen  // Color for Signal Line

//--- input parameters
input int fastEMA = 12; // Fast EMA Period
input int slowEMA = 26; // Slow EMA Period
input int signalSMA = 9;  // Signal SMA Period

//--- indicator buffers
double MACDLine[];
double SignalLine[];

//+------------------------------------------------------------------+
//| Indicator initialization function                               |
//+------------------------------------------------------------------+
int OnInit()
{
    IndicatorBuffers(2);
    SetIndexBuffer(0, MACDLine);
    SetIndexBuffer(1, SignalLine);
    
    SetIndexStyle(0, DRAW_LINE);
    SetIndexStyle(1, DRAW_LINE);
    
    // Asignar etiquetas a cada línea para identificación
    SetIndexLabel(0, "MACD Line");
    SetIndexLabel(1, "Signal Line");
    
    IndicatorShortName("Custom MACD (Red: MACD Line, Lime: Signal Line)");
    
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Indicator iteration function                                    |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    for(int i = 0; i < rates_total; i++)
    {
        MACDLine[i] = iMA(NULL, 0, fastEMA, 0, MODE_EMA, PRICE_CLOSE, i) - iMA(NULL, 0, slowEMA, 0, MODE_EMA, PRICE_CLOSE, i);
    }
    
    for(int i = 0; i < rates_total; i++)
    {
        SignalLine[i] = iMAOnArray(MACDLine, rates_total, signalSMA, 0, MODE_SMA, i);
    }
    
    return(rates_total);
}