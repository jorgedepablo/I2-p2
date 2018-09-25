with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;
with Chat_Messages;
with Ada.Characters.Handling;
with Client_Collections;

procedure Chat_Server is

   package ATI renames Ada.Text_IO;
   package LLU renames Lower_Layer_UDP;
   package ASU renames Ada.Strings.Unbounded;
   package ACL renames Ada.Command_Line;
   package CM renames Chat_Messages;
   package ACH renames Ada.Characters.Handling;
   package CC renames Client_Collections;

   Usage_Error : exception;

  procedure Send_To_Reader (Buffer: access LLU.Buffer_Type;
                            Nick: in ASU.Unbounded_String;
                            Reply: in ASU.Unbounded_String;
                            Collection: in CC.Collection_Type ) is
  begin
    LLU.Reset (Buffer.all);
    CM.Message_Type'Output (Buffer, CM.Server);
    ASU.Unbounded_String'Output (Buffer, Nick);
    ASU.Unbounded_String'Output (Buffer, Reply);
    CC.Send_To_All (Collection, Buffer);
  end Send_To_Reader;


   Server_EP : LLU.End_Point_Type;
   Client_EP : LLU.End_Point_Type;
   Buffer : aliased LLU.Buffer_Type (1024);
   Expired : Boolean;
   Host : ASU.Unbounded_String;
   Port : Natural;
   IP: ASU.Unbounded_String;
   Nick: ASU.Unbounded_String;
   Message : ASU.Unbounded_String;
   Mess_Type : CM.Message_Type;
   Unique : Boolean;
   Readers : CC.Collection_Type;
   Writers : CC.Collection_Type;
   Reply : ASU.Unbounded_String;

begin
  if ACL.Argument_Count /= 1 then
      raise Usage_Error;
  end if;

   Port := Integer'Value (ACL.Argument(1));
   Host := ASU.To_Unbounded_String (LLU.Get_Host_Name);
   IP := ASU.To_Unbounded_String(LLU.To_IP (ASU.To_String(Host)));
   Server_EP := LLU.Build (ASU.To_String(IP), Port);
   LLU.Bind (Server_EP);


   loop
      LLU.Reset (Buffer);
      LLU.Receive (Server_EP, Buffer'Access, 1000.0, Expired);
      if Expired then
         ATI.Put_Line ("Plazo expirado, vuelva a intentarlo");
      else
        Mess_Type := CM.Message_Type'Input (Buffer'Access);
        case Mess_Type is

          when CM.Init =>
            Client_EP := LLU.End_Point_Type'Input (Buffer'Access);
            Nick :=  ASU.Unbounded_String'Input (Buffer'Access);
            ATI.Put ("INIT recived from ");
            ATI.Put (ASU.To_String(Nick));

            if ASU.To_String(Nick) /= "reader" then
              Unique := True;
              begin
                CC.Add_Client (Writers, Client_EP, Nick, Unique);
                Reply := ASU.To_Unbounded_String (ASU.To_String(Nick) & " joins in the chat");
                Nick := ASU.To_Unbounded_String ("Server");
                Send_To_Reader (Buffer'Access, Nick, Reply, Readers);
                ATI.New_Line(1);
              exception
                when CC.Client_Collection_Error =>
                  ATI.Put_Line (". IGNORERD, nick already used");
              end;

            elsif ASU.To_String (Nick) = "reader" then
              Unique := False;
              CC.Add_Client (Readers, Client_EP, Nick, Unique);
            end if;

          when  CM.Writer =>
            begin
              Client_EP := LLU.End_Point_Type'Input (Buffer'Access);
              Nick := CC.Search_Client (Writers, Client_EP);
              Reply := ASU.Unbounded_String'Input (Buffer'Access);
              Send_To_Reader (Buffer'Access, Nick, Reply, Readers);
              ATI.Put ("WRITER received from ");
              ATI.Put_Line (ASU.To_String(Nick) & ": " & ASU.To_String(Reply));
            exception
              when CC.Client_Collection_Error =>
                ATI.Put_Line ("WRITER received from unkdown client. IGNORED");
            end;
         when others =>
  			    ATI.Put_Line("Type of message not found");
  		  end case;
      end if;
      LLU.Reset (Buffer);
   end loop;

exception
  when Usage_Error =>
		ATI.Put_Line("usage: <port> ");
		LLU.Finalize;
   when Ex:others =>
      ATI.Put_Line ("Excepción imprevista: " & Ada.Exceptions.Exception_Name(Ex) & " en: " & Ada.Exceptions.Exception_Message(Ex));
      LLU.Finalize;

end Chat_Server;
