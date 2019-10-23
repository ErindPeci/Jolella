/**********************************************
*                                             *
*@author: Joliardici                          *
*@since: 28/07/2019                           *
*                                             *
*Interfaccia per la gestione dei segnali      *
**********************************************/
include "objects.iol"

interface IsAvailable { //ricerca file nel network
RequestResponse:
javaEmbedFind(base)(encapsRes)
}

interface JolellaMain {//server interface
RequestResponse:
serverFunction(msgFromJeer)(undefined)
}

interface ClientClient {
  OneWay:
  sendMsgToNode(any),
  userCall(string)
  RequestResponse:
  download(any)(any)
}

interface MonitorInterface {
  RequestResponse:
  monitor(monInfo)(void)
}

interface TestIFace {
OneWay: callCheck(bool)
}
