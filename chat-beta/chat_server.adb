with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;
with Chat_Messages;
with Client_Collections;

procedure Chat_Server is

    package ATI renames Ada.Text_IO;
    package LLU renames Lower_Layer_UDP;
    package ASU renames Ada.Strings.Unbounded;
    package ACL renames Ada.Command_Line;
    package CM renames Chat_Messages;
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
    Admin_EP : LLU.End_Point_Type;
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
    Password : ASU.Unbounded_String;
    Password_Admin : ASU.Unbounded_String;
    Clients_List : ASU.Unbounded_String;
    Finalize : Boolean := False;

begin
    if ACL.Argument_Count /= 2 then
        raise Usage_Error;
    end if;

    Port := Integer'Value (ACL.Argument(1));
    Host := ASU.To_Unbounded_String (LLU.Get_Host_Name);
    IP := ASU.To_Unbounded_String(LLU.To_IP (ASU.To_String(Host)));
    Password := ASU.To_Unbounded_String (ACL.Argument(2));
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
                    ATI.Put ("INIT recived from " & ASU.To_String(Nick));
                    if ASU.To_String (Nick) /= "reader" then
                        Unique := True;
                        begin
                            CC.Add_Client (Writers, Client_EP, Nick, Unique);
                            ATI.New_Line(1);
                            Reply := ASU.To_Unbounded_String (ASU.To_String(Nick) & " joins in the chat");
                            Nick := ASU.To_Unbounded_String ("Server");
                            Send_To_Reader (Buffer'Access, Nick, Reply, Readers);
                        exception
                            when CC.Client_Collection_Error =>
                                ATI.Put_Line (". IGNORERD, nick already used");
                        end;
                    elsif ASU.To_String (Nick) = "reader" then
                        Unique := False;
                        CC.Add_Client (Readers, Client_EP, Nick, Unique);
                        ATI.New_Line(1);
                    end if;
                when CM.Writer =>
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
                when CM.Collection_Request =>
                    Admin_EP := LLU.End_Point_Type'Input (Buffer'Access);
                    Password_Admin := ASU.Unbounded_String'Input (Buffer'Access);
                    ATI.Put ("LIST_REQUEST revived");
                    if ASU.To_String (Password_Admin) = ASU.To_String (Password) then
                        Clients_List := ASU.To_Unbounded_String (CC.Collection_Image(Writers));
                        ATI.New_Line (1);
                        LLU.Reset (Buffer);
                        CM.Message_Type'Output (Buffer'Access, CM.Collection_Data);
                        ASU.Unbounded_String'Output (Buffer'Access, Clients_List);
                        LLU.Send (Admin_EP, Buffer'Access);
                        LLU.Reset (Buffer);
                    else
                        ATI.Put_Line (". IGNORED, incorrect pasword");
                    end if;
                when CM.Ban =>
                    Password_Admin := ASU.Unbounded_String'Input (Buffer'Access);
                    Nick := ASU.Unbounded_String'Input (Buffer'Access);
                    ATI.Put ("BAN revived for " & ASU.To_String(Nick));
                    begin
                        if ASU.To_String (Password_Admin) = ASU.To_String (Password) then
                            CC.Delete_Client (Writers, Nick);
                            ATI.New_Line(1);
                        else
                            ATI.Put_Line(". IGNORED, incorrect pasword");
                        end if;
                    exception
                        when CC.Client_Collection_Error =>
                            ATI.Put_Line (". IGNORED, nick not found");
                    end;
                when CM.Shutdown =>
                    Password_Admin := ASU.Unbounded_String'Input (Buffer'Access);
                    ATI.Put ("SHUTDOWN revived");
                    if ASU.To_String (Password_Admin) = ASU.To_String (Password) then
                        ATI.New_Line(1);
                        Finalize := True;
                    else
                        ATI.Put_Line(". IGNORED, incorrect pasword");
                    end if;
                when others =>
  			           ATI.Put_Line("Type of message not found");
  		    end case;
        end if;
        LLU.Reset (Buffer);
        exit when Finalize;
    end loop;
    LLU.Reset (Buffer);
    LLU.Finalize;

exception
    when Usage_Error =>
		  ATI.Put_Line("Usage Error. Use => usage: <port> <Pasword>");
		        LLU.Finalize;
    when Ex:others =>
        ATI.Put_Line ("Excepción imprevista: " & Ada.Exceptions.Exception_Name(Ex) & " en: " & Ada.Exceptions.Exception_Message(Ex));
        LLU.Finalize;

end Chat_Server;
