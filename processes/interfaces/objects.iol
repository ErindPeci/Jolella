/**********************************************
*                                             *
*@author: Joliardici                          *
*@since: 28/07/2019                           *
*                                             *
*Interfaccia per la definizione degli oggetti *
**********************************************/

type jeer: void {
  .id?:int
  .address?: string
  .path: string
  .buffer: int
  .active: bool
}

type encapsRes: void {
    .jeer*: jeer
}

type sharedFile: void {
  .name: string
  .id: int
  .relJeer*: jeer
}

type base: void {
  .sharedFile*: sharedFile
  .src?:string
}

type javaBase: void {
  .sharedFile*: sharedFile
  .src?:string
}

type jeerAddress: string{
  .secondChance?: bool
  .deactivated?: bool
}

type msgFromJeer: string{
  .jeerAddress?: string
  .sharedFile*: sharedFile
  .toSearch?: string
}

type msgFromSrv: string{
  .jeer?: encapsRes
  .jeerAddress?: string
}

type monInfo : void {
  .content: string
}

type exceptMsg: void{
  .message?: string
}
