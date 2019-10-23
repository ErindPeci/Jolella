/**********************************************
*                                             *
*@author: Joliardici                          *
*@since: 28/07/2019                           *
*                                             *
*Nodes service embedded with client.ol 		  *
**********************************************/

include "console.iol"
include "processes/interfaces/objects.iol"
include "processes/interfaces/messages.iol"
include "file.iol"
include "converter.iol"
include "time.iol"

/* this service is embedded within client.ol and it is in charge to receive messages from the server and send messages to the nodes . */
execution{ concurrent }

inputPort INNODE  {
  Location: LOCATION
  Protocol: http
  Interfaces: ClientClient
}

outputPort MAINSRV {
	Location : "socket://localhost:8000"
	Protocol: http
	Interfaces: JolellaMain
}

main {
		//manda al server ogni 15 sec un messaggio "active" per non far' disconnettere il jeer.
		[userCall(loc) ]{

			for(i=0, i >=0 , i++) {
				sleep@Time(15000)();
				msgFromJeer = "active";
	         	msgFromJeer.jeerAddress = loc;
				serverFunction@MAINSRV(msgFromJeer)(response)
			}
		}

		//manda un messaggio ad un altro Jeer , (quello che ha fatto join )
		[sendMsgToNode(result)]{

			    println@Console(result)()
	    }

	    //esegue il read dei files per poi chiamare write nel client actuale .
		[download(request)(response){
			fileToRead.filename = request ;
			fileToRead.format = "base64";
			//errore da gestire
			readFile@File(fileToRead)(res);
			response = res
		}]

}
