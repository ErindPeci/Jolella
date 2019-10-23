 /**********************************************
*                                             *
*@author: Joliardici                          *
*@since: 28/07/2019                           *
*                                             *
* Applicazione client                         *
**********************************************/

include "console.iol"
include "runtime.iol"
include "file.iol"
include "processes/interfaces/objects.iol"
include "processes/interfaces/messages.iol"
include "network_service.iol"
include "time.iol"
include "string_utils.iol"
include "converter.iol"
include "exec.iol"

outputPort INNODE {
Protocol: http
Interfaces: ClientClient
}


// porta statica   per comunicare con il  nodo centrale
outputPort MAINSRV {
  Location: "socket://localhost:8000"
  Protocol: http
  Interfaces: JolellaMain
}

//porta per comunicare con il monitor
outputPort TOMONITOR {
  Location:"socket://localhost:8051"
  Protocol:http
  Interfaces:MonitorInterface
}


init
{
  println@Console( "Welcome to client " )();
  registerForInput@Console()();

  // id of shared files
  global.idFile = 1;
  PART_ADDRESS = "socket://localhost:";

  //il jeer manda un messaggio al server per connettersi al sistema con una stringa join
  msgFromJeer = "join";
  msgFromJeer.jeerAddress = PART_ADDRESS;
  serverFunction@MAINSRV(msgFromJeer)(response);


  loc = response.jeerAddress;
  println@Console( loc )();
  str = loc;
  str.begin = 22;
  str.end = 23;
  substring@StringUtils(str)(idFromLoc);

  println@Console("---------------------------------------------------")();
  println@Console(response + "as JEER <" + idFromLoc + ">" + " on " + loc )();
  if( idFromLoc == 1 ) {
    //si comunica al monitor che il sistema è attivo
    tosend.content = "THE SYSTEM IS RUNNING";
    monitor@TOMONITOR(tosend)()
  };

  println@Console("---------------------------------------------------")();


  verifyDir = false;
  directory = "";

  while( verifyDir  == false) {
    println@Console( "Enter the directory that contains the files \n")();
    in(dir);

    exists@File( dir )( resps );

    if( resps ) {

      isDirectory@File( dir )( isDir );

      if( isDir ) {
        directory = dir;
        verifyDir = true

      }else{
        println@Console( "You have inserted a file name ." )()
      }


    }else{
      println@Console( "Directory does not exist.")()
    }
  };


  /* dynamic embedding of node_service.ol */
  with( emb ) {
        .filepath = "-C LOCATION=\"" + loc + "\" node_service.ol";
        .type = "Jolie"
  };
  loadEmbeddedService@Runtime( emb )()

}

main
{

    INNODE.location = loc;

    //userCall chiama node service e fa partire il ciclo dei messaggi active che si mandano al server.
    userCall@INNODE(loc);

    with(jeer){
      .id = int(idFromLoc);
      .address = loc;
      .path = directory;
      .buffer = 5 ;
      .active  = true
    };

    //inizializza la directory di ogni jeer con un file scaricato.
    execRequest = "curl";
     with( execRequest ){
    .args[0] = "-L";
    .args[1] = "http://ipv4.download.thinkbroadband.com:81/" + idFromLoc + "MB.zip";
    .args[2] = "-O";
    .workingDirectory = directory;
    .stdOutConsoleEnable = true
    };
    exec@Exec( execRequest )( execResponse );

    tosend.content = "JEER <" + jeer.id + "> is now connected to the system.";
    monitor@TOMONITOR(tosend)();

    println@Console("---------------------------------------------------")();
    println@Console("The files present at your directory :")();
    cartella.directory = jeer.path ;
    list@File( cartella)( rispostaProva);

    for( j = 0, j < #rispostaProva.result, j++ ) {
      sendMsgToNode@INNODE(rispostaProva.result[j]);
      msgFromJeer.sharedFile[j].id = global.idFile++;
      msgFromJeer.sharedFile[j].name = rispostaProva.result[j];
      msgFromJeer.sharedFile[j].relJeer << jeer
    };
    msgFromJeer = "add";
    serverFunction@MAINSRV(msgFromJeer)(response);
    sendMsgToNode@INNODE(response);


    println@Console("---------------------------------------------------")();


    sleep@Time(800)();

    while( cmd!= "exit" ) {

      println@Console("###################################################" )();
      println@Console( "# Insert the number of the command :              #" )();
      println@Console( "#   1 - Search and download                       #" )();
      println@Console( "#   2 - Update the directory                      #" )();
      println@Console( "#   3 - Exit from the system                      #" )();
      println@Console("###################################################" )();

      in(command);
      idCommand = int(command);

      if( idCommand == 1 ) {

        //lookup and download
        //lookup tramite "find" al server che chiama il servizio java che si occupa della ricerca.
        println@Console("Enter the file name you want to search for in the system :")();
        in(filen) ;
        msgFromJeer = "find";
        msgFromJeer.toSearch = filen;
        serverFunction@MAINSRV(msgFromJeer)(resp);

        // controlla se la lista dei jeer non è vuota, e se esiste solo un jeer la sua location deve essere diversa da loc
        if( #resp.jeers.jeer > 0  && resp.jeers.jeer[0].address != loc) {

            println@Console("The files are staged at these JEER :")();
            //mostra la lista dei jeer che offrono il file chiesto , in ordine in base al buffer dei jeer .
            for (z = 0, z < #resp.jeers.jeer , z++ ) {
              if(resp.jeers.jeer[z].address != loc ) {
                sleep@Time(200)();
                sendMsgToNode@INNODE( "ID : " + resp.jeers.jeer[z].id + "  ON ADDRESS : " + resp.jeers.jeer[z].address )
              }
            };

            sleep@Time(200)();
            println@Console("Insert the id of the JEER that you want to get the file from :" )();
            in(iddownload);

            // controllo se il jeer scelto esiste ancora nella rete
            serverFunction@MAINSRV(msgFromJeer)(controllo);
            jeerSelezionato = false;

            for ( m = 0, m < #controllo.jeers.jeer , m++ ) {
              if( controllo.jeers.jeer[m].id == iddownload ) {
                jeerSelezionato = true
              }
            };

            if( jeerSelezionato ) {

                //join tra i jeer :
                for ( k = 0, k < #resp.jeers.jeer , k++ ) {

                  if( resp.jeers.jeer[k].id == iddownload ) {

                    // cambiare la location del output port con la location del jeer da cui viene scaricato il file
                    INNODE.location = resp.jeers.jeer[k].address;
                    sendMsgToNode@INNODE("Hello JEER " + iddownload + " -- this is JEER  "+ jeer.id + ", downloading "+filen);

                    // network Visualizzer
                    tosend.content = "  JEER <" + jeer.id + "> connected to JEER  <" + iddownload + ">. ";
                    monitor@TOMONITOR(tosend)();

                    // manda un messaggio buffer al server per chiamare il metodo che gestisce il buffer .
                     msgFromJeer = "buffer" ;
                     msgFromJeer.jeerAddress = resp.jeers.jeer[k].address ;
                     serverFunction@MAINSRV(msgFromJeer)(response);

                    // si chiama il metodo download verso node service per fare il "read" dei file
                    filename = "./"+resp.jeers.jeer[k].path+"/" + filen ;
                    download@INNODE(filename)(fileResponse);

                    // download  del file nel path del jeer actuale.
                    base64ToRaw@Converter(fileResponse)(fileToWrite);
                    writeFile@File({
                      .filename = "./" + jeer.path + "/" + filen,
                      .format = "binary",
                      .content = fileToWrite
                    })();
                    msgFromJeer = "bufferUp" ;
                     msgFromJeer.jeerAddress = resp.jeers.jeer[k].address ;
                     serverFunction@MAINSRV(msgFromJeer)(response);
                    //messaggi tra node che sono in connessione e verso il monitor
                    sendMsgToNode@INNODE("File " + filen +  " sent to JEER : " +jeer.id);
                    println@Console("File " + filen + " received from JEER : " +iddownload)();
                    tosend.content = "File " + filen + " downloaded from  JEER <" + jeer.id + "> to JEER <" + iddownload + ">.";
                    monitor@TOMONITOR(tosend)()

                  }
                };

                //si riimposta la location del outputport con la location del jeer acutale .
                INNODE.location = loc

            }else{
               println@Console( "The JEER  you have chosen is not available in  the network !!! " )()
            }

        }else{
              println@Console( "There is no JEER having the files you are looking for " )()
        }

      }else if(idCommand == 2){

        // Update della directory
        println@Console("---------------------------------------------------")();
        println@Console("The files present at your directory :")();
        cartella.directory = jeer.path ;
        list@File( cartella)( rispostaProva);

        for( j = 0, j < #rispostaProva.result, j++ ) {
          sendMsgToNode@INNODE(rispostaProva.result[j]);
          msgFromJeer.sharedFile[j].id = global.idFile++;
          msgFromJeer.sharedFile[j].name = rispostaProva.result[j];
          msgFromJeer.sharedFile[j].relJeer << jeer
        };
        msgFromJeer = "add";
        serverFunction@MAINSRV(msgFromJeer)(response);
       // sendMsgToNode@INNODE(response);
        sendMsgToNode@INNODE("You have succesfuly updated your directory");
        sleep@Time(200)()

      }else if(idCommand == 3){

        //Leave del jeer.
        tosend.content = "JEER <" + jeer.id + "> left the system. ";
        monitor@TOMONITOR(tosend)();
        msgFromJeer = "leave";
        msgFromJeer.jeerAddress = loc;
        // msgFromJeer.sharedFile  già completato sopra nella list@File
        serverFunction@MAINSRV(msgFromJeer)();
        cmd = "exit"

      }else{
        println@Console( "Ooops! Your command seems not to be valid!
                              Please insert a number between 1 and 3." )()
      }

  }

}
