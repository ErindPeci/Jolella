package processes.embedd;

import jolie.runtime.JavaService;
import jolie.runtime.Value;
import jolie.runtime.ValueVector;
import java.util.*;

public class Search extends JavaService{

  public Value javaEmbedFind(Value srcVl){
    //utilizzo variabili locali per evitare race condition
    ValueVector ordVect = ValueVector.create();
    Value response = Value.create();
    Value thisOne = Value.create();
    Value unChockOpt = Value.create();
    ValueVector jeerTree = ValueVector.create();
    String nextOne;
    int buff = 5;

    //file da cercare
    String toFind = srcVl.getFirstChild("src").strValue();

    ordVect.deepCopy(srcVl.getChildren("sharedFile"));
    Iterator<Value> vectIterat = ordVect.iterator();

    //itero l'albero dei file per trovare quello corrispondente al valore di ricerca
    while(vectIterat.hasNext()){

      thisOne.erase();
      thisOne.deepCopy(vectIterat.next());
      nextOne = thisOne.getFirstChild("name").strValue();


      if(nextOne.equals(toFind)){
        jeerTree.deepCopy(thisOne.getChildren("relJeer"));
        Iterator<Value> jeerIterat = jeerTree.iterator();

        //prelevo massimo 5 jeer da proporre al client che ha effettuato la ricerca
        while(jeerIterat.hasNext() && buff > 0){
          unChockOpt.erase();
          unChockOpt.deepCopy(jeerIterat.next());

          if(unChockOpt.getFirstChild("active").boolValue() && unChockOpt.getFirstChild("buffer").intValue()>0){
            response.getNewChild("jeer").deepCopy(unChockOpt);
            buff--;
          }
        }
        break; //interrompo la ricerca una volta trovato
      }
    }
    return response;
  }

}
