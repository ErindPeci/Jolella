/**********************************************
*                                             *
*@author: Joliardici                          *
*@since: 31/08/2019                           *
*                                             *
*Servizio di ordinamento degli alberi         *
**********************************************/

include "interfaces/objects.iol"
include "interfaces/messages.iol"
include "string_utils.iol"

define algoCall { //algoritmo di magia nera per ordinare i jeer in base al buffer
    for ( j = 0, j < #global.base.sharedFile, j++ ) {
      for ( k = 0, k < #global.base.sharedFile[j].relJeer-1, k++ ) {
        for ( y = k+1, y < #global.base.sharedFile[j].relJeer, y++ ) {
          if ( global.base.sharedFile[j].relJeer[y].buffer > global.base.sharedFile[j].relJeer[k].buffer ) {
            undef(temp);
            temp << global.base.sharedFile[j].relJeer[k];
            global.base.sharedFile[j].relJeer[k] << global.base.sharedFile[j].relJeer[y];
            global.base.sharedFile[j].relJeer[y] << temp
          }
        }
      }
    }
}

define addFile { //aggiunge un file alla rete evitando duplicazioni
    for ( z = 0 , z < #req.sharedFile, z++ ) {
      s_i=0;

      exist = false;
      exJeer = false;

      while ( s_i < #global.base.sharedFile && !exist ) {
        //verifico se esistono file corrispondenti
        if ( global.base.sharedFile[s_i].name == req.sharedFile[z].name ) {
          s_j=0;

          //se esiste verifico se è già associato al jeer
          while( s_j < #global.base.sharedFile[s_i].relJeer && !exJeer ) {
            if( global.base.sharedFile[s_i].relJeer[s_j].address == req.sharedFile[z].relJeer[0].address ) {
              global.base.sharedFile[s_i].relJeer[s_j].buffer = req.sharedFile[z].relJeer[0].buffer;
              global.base.sharedFile[s_i].relJeer[s_j].path = req.sharedFile[z].relJeer[0].path;
              global.base.sharedFile[s_i].relJeer[s_j].active = true;
              exJeer = true
            };
            s_j++
          };
          //se non ha trovato il jeer lo aggiungo
          if( !exJeer ) {
            global.base.sharedFile[s_i].relJeer[#global.base.sharedFile[s_i].relJeer] << req.sharedFile[z].relJeer[0]
          };
          exist = true
        };
          s_i++
        };
      //se il file non esiste nella rete creo un nuovo nodo
      if(!exist){
        global.base.sharedFile[#global.base.sharedFile] << req.sharedFile[z]
      }
    }
}

define resCheck{ //setta il nodo non attivo nell'albero della rete
  for ( z = 0 , z < #global.base.sharedFile , z++ ) {
    for ( j = 0 , j < #global.base.sharedFile[z].relJeer , j++ ) {
      if( global.base.sharedFile[z].relJeer[j].address == global.jeerAddress[i] ) {
        global.base.sharedFile[z].relJeer[j].active = false
        }
      }
    }
}

define reseTree{ //usata dal jeer per impostarsi nuovamente attivo
  for ( i = 0 , i < #global.base.sharedFile , i++ ) {
    for ( j = 0 , j < #global.base.sharedFile[i].relJeer , j++ ) {
      if( global.base.sharedFile[i].relJeer[j].address == req.jeerAddress ) {
        global.base.sharedFile[i].relJeer[j].active = true
        }
      }
    }
}

define setSecondChance{ //algoritmo di second chance
  l=0;
  for ( i = 0 , i < #global.jeerAddress , i++ ) {
      if( global.jeerAddress[i].secondChance ) {
        global.jeerAddress[i].secondChance = false
        }else if(!global.jeerAddress[i].deactivated && !global.jeerAddress[i].secondChance){
          //se il jeer non imposta nuovamente la variabile di second chance viene impostato non attivo

          global.jeerAddress[i].deactivated = true;
          unactiveList[l] = global.jeerAddress[i];
          l++;
          resCheck
        }
    }
}

define setActive{ //jeer imposta il suo stato come attivo
  for ( i = 0 , i < #global.jeerAddress , i++ ) {
      if( global.jeerAddress[i] == req.jeerAddress ) {
        if( global.jeerAddress[i].deactivated ) { //se era stato disattivato
          global.jeerAddress[i].deactivated = false;
          reseTree //il jeer si dichiara nuovamente attivo
        };
        global.jeerAddress[i].secondChance = true
        }
    }
}

define sendJeerForCon{ //per gestire il servizio in locale si assegna una porta progressiva

global.port++;
global.jeerAddress[global.port-9001] = req.jeerAddress + global.port;
global.jeerAddress[global.port-9001].secondChance = true;
global.jeerAddress[global.port-9001].deactivated = false;
msgFromSrv = "You are connected ";
msgFromSrv.jeerAddress = global.jeerAddress[global.port-9001]

}

define bufferReduce{ //algoritmo di riduzione del relativo buffer del jeer
  for ( j = 0, j < #global.base.sharedFile, j++ ) {
    for ( k = 0, k < #global.base.sharedFile[j].relJeer, k++ ) {
        if ( global.base.sharedFile[j].relJeer[k].address = req.jeerAddress ) {
          global.base.sharedFile[j].relJeer[k].buffer--
      }
    }
  }
}

define bufferIncrement{ //algoritmo di riduzione del relativo buffer del jeer
  for ( j = 0, j < #global.base.sharedFile, j++ ) {
    for ( k = 0, k < #global.base.sharedFile[j].relJeer, k++ ) {
        if ( global.base.sharedFile[j].relJeer[k].address = req.jeerAddress ) {
          global.base.sharedFile[j].relJeer[k].buffer++
      }
    }
  }
}

define leaveAction{ //jeer lascia la rete e viene impostato non attivo
  for ( i = 0 , i < #global.jeerAddress , i++ ) {
      if( global.jeerAddress[i] == req.jeerAddress ) {
          global.jeerAddress[i].deactivated = true
        };
        global.jeerAddress[i].secondChance = false
    };

  for ( j = 0, j < #global.base.sharedFile, j++ ) {
    for ( k = 0, k < #global.base.sharedFile[j].relJeer, k++ ) {
        if ( global.base.sharedFile[j].relJeer[k].address == req.jeerAddress ) {
          global.base.sharedFile[j].relJeer[k].active = false
      }
    }
  }
}
