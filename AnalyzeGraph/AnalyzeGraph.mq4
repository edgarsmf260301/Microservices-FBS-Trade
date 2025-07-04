#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net/"
#property version   "1.00"
#property strict
#define MAGIC_NUMBER 123456
#define CROSS_COUNT_FILE "CrossCount.txt"

enum CrossDirection { NONE, UP, DOWN };
CrossDirection lastCrossDirection = NONE;
int crossCount = 0;
bool EA_Active = true;
bool operationDone = false; 

// Definición de variables input para permitir al usuario ajustar estos valores
input double lotSize = 0.1; 
input double stopLoss = 0; 
input double takeProfit = 0; 

int OnInit() {
    ObjectCreate(0, "StopEAButton", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "StopEAButton", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(0, "StopEAButton", OBJPROP_XDISTANCE, 100);
    ObjectSetInteger(0, "StopEAButton", OBJPROP_YDISTANCE, 20);
    UpdateButton();
    EventSetTimer(1); 

    // Inicialización y lectura del archivo CrossCount.txt
    int fileHandle = FileOpen(CROSS_COUNT_FILE, FILE_READ | FILE_WRITE);
    if(fileHandle == INVALID_HANDLE) {
      
        fileHandle = FileOpen(CROSS_COUNT_FILE, FILE_WRITE | FILE_CSV);
        if(fileHandle != INVALID_HANDLE) {
            FileWrite(fileHandle, 0); 
            FileClose(fileHandle);
        } else {
            Print("Error al crear el archivo ", CROSS_COUNT_FILE);
        }
    } else {

        crossCount = FileReadNumber(fileHandle);
        FileClose(fileHandle);
    }

    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    EventKillTimer(); 
}

void UpdateButton() {
    if(EA_Active) {
        ObjectSetString(0, "StopEAButton", OBJPROP_TEXT, "Stop");
        ObjectSetInteger(0, "StopEAButton", OBJPROP_COLOR, clrRed);
    } else {
        ObjectSetString(0, "StopEAButton", OBJPROP_TEXT, "Start");
        ObjectSetInteger(0, "StopEAButton", OBJPROP_COLOR, clrGreen);
    }
}

void OnTick() {
    if(!EA_Active || crossCount >= 20) return;

double macdCurrent = iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
double signalCurrent = iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
double macdPrevious = iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
double signalPrevious = iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 1);

if((macdPrevious > signalPrevious && macdCurrent < signalCurrent) || (macdPrevious < signalPrevious && macdCurrent > signalCurrent)) {
    lastCrossDirection = (macdPrevious > signalPrevious && macdCurrent < signalCurrent) ? DOWN : UP;
    crossCount++;
    operationDone = true;

    // Actualizar el archivo CrossCount.txt 
    int fileHandle = FileOpen(CROSS_COUNT_FILE, FILE_WRITE | FILE_CSV);
    if(fileHandle != INVALID_HANDLE) {
        FileWrite(fileHandle, crossCount);
        FileClose(fileHandle);
    } else {
        Print("Error al actualizar el archivo ", CROSS_COUNT_FILE);
    }

    if(crossCount >= 20) {
        EA_Active = false;
        UpdateButton();
        CloseAllOrders(); 
    }

    string fileName = "EOrderGraph.txt";
    fileHandle = FileOpen(fileName, FILE_READ|FILE_WRITE|FILE_CSV);
    if(fileHandle != INVALID_HANDLE) {
        FileSeek(fileHandle, 0, SEEK_END);
        string orderType = (lastCrossDirection == UP) ? "OP_BUY" : "OP_SELL";
        double price = (lastCrossDirection == UP) ? Ask : Bid;
        double slPrice = (stopLoss > 0) ? ((lastCrossDirection == UP) ? price - stopLoss * Point : price + stopLoss * Point) : 0;
        double tpPrice = (takeProfit > 0) ? ((lastCrossDirection == UP) ? price + takeProfit * Point : price - takeProfit * Point) : 0;
        string orderInfo = orderType + "," + DoubleToString(price, 5) + "," + DoubleToString(slPrice, 5) + "," + DoubleToString(tpPrice, 5) + ";";
        FileWrite(fileHandle, orderInfo);
        FileClose(fileHandle);
    } else {
        Print("Error opening file: ", fileName);
    }
}
}

void CloseAllOrders() {
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS) && (OrderType() == OP_BUY || OrderType() == OP_SELL)) {
            if(OrderType() == OP_BUY) {
                OrderClose(OrderTicket(), OrderLots(), Bid, 3, clrNONE);
            } else if(OrderType() == OP_SELL) {
                OrderClose(OrderTicket(), OrderLots(), Ask, 3, clrNONE);
            }
        }
    }
}

void OnTimer() {
    // Verificar y procesar órdenes desde el archivo
    string fileName = "IOrderGraph.txt"; 
    int fileHandle = FileOpen(fileName, FILE_READ);
    if(fileHandle != INVALID_HANDLE) {
        string line;
        while(!FileIsEnding(fileHandle)) {
            line = FileReadString(fileHandle);
            if(StringLen(line) > 0) {
                string orderDetails[];
                int detailsCount = StringSplit(line, ',', orderDetails);
                if(detailsCount >= 4) {
                   
                    string orderType = orderDetails[0];
                    double price = StrToDouble(orderDetails[1]);
                    double slPrice = StrToDouble(orderDetails[2]);
                    double tpPrice = StrToDouble(orderDetails[3]);
                    ProcessOrder(orderType, price, slPrice, tpPrice);
                }
            }
        }
        FileClose(fileHandle);

        // Vaciar el contenido del archivo después de procesar
        fileHandle = FileOpen(fileName, FILE_WRITE);
        FileClose(fileHandle);
    } else {
        Print("Error opening file: ", fileName);
    }
}

void ProcessOrder(string orderType, double price, double slPrice, double tpPrice) {

    int ticket;
    if(orderType == "OP_BUY") {
        ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 2, slPrice, tpPrice, "Buy Order", MAGIC_NUMBER, 0, clrGreen);
    } else if(orderType == "OP_SELL") {
        ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, 2, slPrice, tpPrice, "Sell Order", MAGIC_NUMBER, 0, clrRed);
    }

    if(ticket < 0) {
        Print("OrderSend failed with error #", GetLastError());
    } else {
        Print("Order ", ticket, " opened successfully.");
    }
}

void CloseOrders(int type) {
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS) && OrderType() == type) {
         double closePrice = (type == OP_BUY) ? Bid : Ask;
         OrderClose(OrderTicket(), OrderLots(), closePrice, 3, clrNONE);
      }
   }
}

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam) {
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == "StopEAButton") {
        EA_Active = !EA_Active;
        if(EA_Active) crossCount = 0; 
        operationDone = false; 
        UpdateButton(); 
    }
}
//+------------------------------------------------------------------+