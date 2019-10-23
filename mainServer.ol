/**********************************************
*                                             *
*@author: Joliardici                          *
*@since: 28/07/2019                           *
*                                             *
*Applicazione main Server: nodo centrale      *
*della rete                                   *
**********************************************/



include "processes/algo.iol"
include "processes/interfaces/objects.iol"
include "processes/interfaces/messages.iol"
include "console.iol"
include "time.iol"
include "runtime.iol"
include "file.iol"
include "semaphore_utils.iol"



execution{ concurrent }


inputPort MAINSRV {
Location: "socket://localhost:8000"
Protocol: http
Interfaces: JolellaMain
}

inputPort localPort {
Location: "local"
Interfaces: TestIFace
}

outputPort javaPort {
Interfaces: IsAvailable
}

outputPort OUTMONITOR {
Location: "socket://localhost:8051"
Protocol: http
Interfaces: MonitorInterface
}

embedded {
  Java:
    "processes.embedd.Search" in javaPort
}


init{
  timeout = 30000;
  timeout.operation = "callCheck";
  timeout.message = true;

  //semafori per la gestione lettore-scrittore (può andare incontro a starvation)

  global.num_file_lettori = 0;
  global.wr_file.name = "add";
  global.wr_file.permits = 1;
  global.wr_stat.name = "stat";
  global.wr_stat.permits = 1;
  global.rd_file.name = "rdfile";
  global.rd_file.permits = 1;
  global.rd_stat.name = "rdstat";
  global.rd_stat.permits = 1;
  release@SemaphoreUtils(global.wr_file)(stat);
  release@SemaphoreUtils(global.wr_stat)(stat);
  release@SemaphoreUtils(global.rd_file)(stat);
  release@SemaphoreUtils(global.rd_stat)(stat);
  global.port = 9000;

  //timeout per richiamare l'algoritmo di second chance per il monitoraggio della rete
  setNextTimeout@Time( timeout );

  println@Console( "\t\t    ***** Server is now active  *****
                      *** Keep the Planet clean ***
                        * Powered by Joliardici *" )()
}


main{

  //funzione principale eseguita concorrentemente per le richieste al server

  [serverFunction(req)(msgFromSrv){

    //gestione eccezione comando
    install( CmdFault =>
                println@Console( exceptMsg.message + req )()
                );
                exceptMsg.message = "Command not recognized: ";

        if( req == "add" ){ //operazione di aggiunta file alla rete

              //wait su semaforo scrittore
              acquire@SemaphoreUtils(global.wr_file)(stat);

              addFile;
              algoCall;
              //signal su semaforo scrittore
              release@SemaphoreUtils(global.wr_file)(stat);

              msgFromSrv = "File added"
        }else if ( req=="find" ) { //operazione di ricerca file nella rete
              //wait lettore che verifica di essere il primo e incrementa il numero lettori
              acquire@SemaphoreUtils(global.rd_file)(stat);
              //se è il primo lettore acquisisce il semaforo di scrittura
              if( global.num_file_lettori == 0 ) {
                acquire@SemaphoreUtils(global.wr_file)(stat)
              };

              global.num_file_lettori++;
              //signal lettore
              release@SemaphoreUtils(global.rd_file)(stat);

              println@Console( "Searching for: "+ req.toSearch )();

              javaBase.src = req.toSearch;
              javaBase.sharedFile << global.base.sharedFile;
              //servizio Java di ricerca
              javaEmbedFind@javaPort(javaBase)(found);

              msgFromSrv = "founded";

              msgFromSrv.jeers.jeer << found.jeer;
              //wait lettore
              acquire@SemaphoreUtils(global.rd_file)(stat);
              global.num_file_lettori--;
              //se ultimo lettore signal write
              if( global.num_file_lettori == 0) {
                release@SemaphoreUtils(global.wr_file)(stat)
              };
              //signal lettore
              release@SemaphoreUtils(global.rd_file)(stat)
        }else if ( req == "active" ) { //operazione riservata al server per dichiararsi attivo

              //scrittore statistiche (diverso per variabili coinvolte race condition)
              acquire@SemaphoreUtils(global.wr_stat)(stat);
              acquire@SemaphoreUtils(global.wr_file)(stat);

              setActive;

              release@SemaphoreUtils(global.wr_stat)(stat);
              release@SemaphoreUtils(global.wr_file)(stat);
              msgFromSrv = "ok"
        }else if(req == "join"){ //operazione di ingresso nella rete

              acquire@SemaphoreUtils(global.wr_stat)(stat);


              sendJeerForCon;

              println@Console( msgFromSrv.jeerAddress + " joined the Jolella network")();


              release@SemaphoreUtils(global.wr_stat)(stat)

        }else if(req == "buffer"){ //operazione di riduzione del buffer dei nodi della rete

              acquire@SemaphoreUtils(global.wr_file)(stat);

              bufferReduce;
              algoCall;

              release@SemaphoreUtils(global.wr_file)(stat);

              msgFromSrv = "Buffer reduced"

        }else if(req == "leave"){ //operazione di uscita dalla rete
              println@Console( req.jeerAddress + " left the network" )();
              acquire@SemaphoreUtils(global.wr_file)(stat);

              leaveAction;

              release@SemaphoreUtils(global.wr_file)(stat);

              msgFromSrv = "Say Hello to Jeer "+req.address

        }else if(req == "bufferUp"){ //operazione di riduzione del buffer dei nodi della rete

              acquire@SemaphoreUtils(global.wr_file)(stat);

              bufferIncrement;
              algoCall;

              release@SemaphoreUtils(global.wr_file)(stat);

              msgFromSrv = "Buffer incremented"

        }else{ //comando non trovato
            throw( CmdFault, exceptMsg )
        }
  }]
  [callCheck(req)]{
    println@Console( "Validating network" )();

    //wait su scrittore statistiche
    //wait su scrittore file
    acquire@SemaphoreUtils(global.wr_stat)(stat);
    acquire@SemaphoreUtils(global.wr_file)(stat);

    setSecondChance;

    //signal scrittore file

    release@SemaphoreUtils(global.wr_file)(stat);
    //richiamo nuovo timeout
    setNextTimeout@Time( timeout );
    //posso eseguire concorrentemente perchè non modifico albero file
    for ( i = 0, i < #unactiveList, i++ ) {

      if( is_defined( unactiveList[i] ) ) {
        str = unactiveList[i];
        str.begin = 22;
        str.end = 23;
        substring@StringUtils(str)(idToSend);
        monInfo.content = "The JEER <" + idToSend + "> is no longer active and has been kicked-off the network";
        println@Console( monInfo.content )();
        monitor@OUTMONITOR(monInfo)()
      }

    };
    //signal scrittore statistiche
    release@SemaphoreUtils(global.wr_stat)(stat)
  }
}
