double GainLimit = 1.5; 
double LossLimit = 1.0; 

void OnTick()
{
    string fileName = "Orders.txt";
    string modifiedFileName = "DuplicateOrders.txt";
    bool hasPendingOrders = false;
    int i; 
    string orderTypeStr;


    for(i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS) && (OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLLIMIT))
        {
            hasPendingOrders = true;
            break;
        }
    }

    if(hasPendingOrders)
    {

        int fileHandle = FileOpen(fileName, FILE_READ|FILE_WRITE|FILE_CSV);
        if(fileHandle < 0)
        {
            Print("Error al abrir el archivo para escribir: ", GetLastError());
            return;
        }


        FileSeek(fileHandle, 0, SEEK_END);


        for(i = 0; i < OrdersTotal(); i++)
        {
            if(OrderSelect(i, SELECT_BY_POS) && (OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLLIMIT))
            {
                orderTypeStr = OrderType() == OP_BUYLIMIT ? "Buy Limit" : "Sell Limit";

                FileWrite(fileHandle, 
                          OrderSymbol(), 
                          OrderLots(), 
                          OrderStopLoss(), 
                          OrderTakeProfit(), 
                          OrderComment(), 
                          orderTypeStr, 
                          OrderOpenPrice(), 
                          TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES), 
                          TimeToString(OrderExpiration(), TIME_DATE|TIME_MINUTES)); 
            }
        }
        FileClose(fileHandle); 
    }

    
    int modifiedFileHandle = FileOpen(modifiedFileName, FILE_READ|FILE_CSV);
    if(modifiedFileHandle < 0)
    {
        Print("Error al abrir el archivo modificado: ", GetLastError());
        return; 
    }

    
    string lastLine;
    while(!FileIsEnding(modifiedFileHandle))
    {
        lastLine = FileReadString(modifiedFileHandle, true);
    }
    FileClose(modifiedFileHandle); 

    
    if(StringLen(lastLine) > 0)
    {
        

        
        if(StringGetCharacter(lastLine, StringLen(lastLine) - 1) == ';')
        {
            lastLine = StringSubstr(lastLine, 0, StringLen(lastLine) - 1);
        }

        
        string orderData[];
        
        int elements = StringSplit(lastLine, ',', orderData);

  
        if(elements < 9)
        {
            Print("Error: La línea no contiene suficientes datos para procesar la orden.");
            return;
        }

        string symbol = orderData[0];
        double lots = StrToDouble(orderData[1]);
        double stopLoss = StrToDouble(orderData[2]);
        double takeProfit = StrToDouble(orderData[3]);
        string comment = orderData[4];
        orderTypeStr = orderData[5]; 
        double openPrice = StrToDouble(orderData[6]);

        datetime expiration = StrToTime(orderData[8]);

 
        int orderType = orderTypeStr == "Buy Limit" ? OP_BUYLIMIT : OP_SELLLIMIT;
        int ticket = OrderSend(symbol, orderType, lots, openPrice, 3, stopLoss, takeProfit, comment, 0, expiration, clrNONE);
        if(ticket < 0)
        {
            Print("Error al crear la orden: ", GetLastError());
        }
        else
        {
            Print("Orden creada con éxito: ", ticket);

            int clearFileHandle = FileOpen(modifiedFileName, FILE_WRITE|FILE_CSV);
            if(clearFileHandle < 0)
            {
                Print("Error al abrir el archivo para limpiar: ", GetLastError());
                return;
            }
            FileClose(clearFileHandle); 
        }
    }
}