with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;
with Chat_Messages;
with Ada.Characters.Handling;

procedure Chat_Client is

   package ATI renames Ada.Text_IO;
   package LLU renames Lower_Layer_UDP;
   package ASU renames Ada.Strings.Unbounded;
   package ACL renames Ada.Command_Line;
   package CM renames Chat_Messages;
   package ACH renames Ada.Characters.Handling;

   use type CM.Message_Type;

   Usage_Error : exception;

     Server_EP : LLU.End_Point_Type;
     Client_EP : LLU.End_Point_Type;
     Buffer :  aliased LLU.Buffer_Type(1024);
     Expired : Boolean;
     Host : ASU.Unbounded_String;
     Port : Natural;
     IP : ASU.Unbounded_String;
     Nick : ASU.Unbounded_String;
     Message : ASU.Unbounded_String;
     Reply : ASU.Unbounded_String;
     Type_Mess : CM.Message_Type;

begin
  if ACL.Argument_Count /= 3 then
      raise Usage_Error;
  end if;
-- Leer comandos y asignar todas las cosas
  Host := ASU.To_Unbounded_String (ACL.Argument(1));
  Port := Integer'Value (ACL.Argument(2));
  Nick := ASU.To_Unbounded_String (ACL.Argument(3));
  IP := ASU.To_Unbounded_String (LLU.To_IP(ASU.To_String(Host)));
  Server_EP := LLU.Build (ASU.To_String(IP), Port);
  LLU.Bind_Any (Client_EP);
--Mandar el Init
  LLU.Reset (Buffer);
  CM.Message_Type'Output (Buffer'Access, CM.Init);
  LLU.End_Point_Type'Output (Buffer'Access, Client_EP);
  ASU.Unbounded_String'Output (Buffer'Access, Nick);
  LLU.Send (Server_EP, Buffer'Access);
-- mandar mensajes o ser lector
  LLU.Reset (Buffer);
  if ACH.To_Lower (ASU.To_String(Nick)) /= "reader" then
    loop
      ATI.Put("Message: ");
      Message := ASU.To_Unbounded_String (ATI.Get_Line);
      exit when ASU.To_String (Message) = (".quit");
      CM.Message_Type'Output (Buffer'Access, CM.Writer);
      LLU.End_Point_Type'Output (Buffer'Access,Client_EP);
      ASU.Unbounded_String'Output (Buffer'Access, Message);
      LLU.Send (Server_EP, Buffer'Access);
      LLU.Reset (Buffer);
    end loop;
  elsif ACH.To_Lower (ASU.To_String(Nick)) = "reader" then
    loop
      LLU.Reset (Buffer);
      LLU.Receive (Client_EP, Buffer'Access, 1000.0, Expired);
      if Expired then
        ATI.Put_Line ("Plazo expirado, vuelva a intentarlo");
      else
        Type_Mess := CM.Message_Type'Input (Buffer'Access);
        Nick:= ASU.Unbounded_String'Input (Buffer'Access );
        Reply := ASU.Unbounded_String'Input (Buffer'Access);
        ATI.Put (ASU.To_String(Nick) & ": ");
        ATI.Put_Line (ASU.To_String(Reply));
      end if;
    end loop;
  end if;
  LLU.Finalize;

exception
  when Usage_Error =>
		ATI.Put_Line("usage: <Host> <port> <Nickname> ");
		LLU.Finalize;
  when Ex:others =>
    ATI.Put_Line ("Excepción imprevista: " & Ada.Exceptions.Exception_Name(Ex) & " en: " & Ada.Exceptions.Exception_Message(Ex));
    LLU.Finalize;

end Chat_Client;
