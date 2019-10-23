/**********************************************
*                                             *
*@author: Joliardici                          *
*@since: 28/07/2019                           *
*                                             *
**********************************************/

include "math.iol"
include "message_digest.iol"
include "time.iol"
include "processes/algo.iol"
include "processes/interfaces/objects.iol"
include "processes/interfaces/messages.iol"
include "console.iol"
include "runtime.iol"
include "file.iol"


// inputPort per il nodo centrale 
inputPort TOMONITOR {
  Location: "socket://localhost:8051"
  Protocol: http
  Interfaces: MonitorInterface
}

execution{ concurrent }

init
{
  global.cont=0;
  getCurrentDateTime@Time()( date );

  println@Console( "  NETWORK VISUALIZER IS RUNNING " )();
  println@Console( "************************************************" )();
    println@Console("Current time:" + date)()
}

main
{
  
 [monitor(moninfo)(){
    global.contatore++;
    println@Console( global.contatore +":" )();
    getCurrentDateTime@Time()( date );
    println@Console(  "Current Time: " + date)() ;
    println@Console(moninfo.content )();   
    println@Console( "*************************************" )()

  }]
}