with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;
with Chat_Messages;
with Client_Collections;

procedure Chat_Admin is

    package ATI renames Ada.Text_IO;
    package LLU renames Lower_Layer_UDP;
    package ASU renames Ada.Strings.Unbounded;
    package ACL renames Ada.Command_Line;
    package CM renames Chat_Messages;
    package CC renames Client_Collections;

    Usage_Error : exception;
    Password_Error : exception;

    procedure Show_Menu is
    begin
        ATI.Put_Line("Options");
        ATI.Put_Line("1 Show writers collection");
        ATI.Put_Line("2 Ban writer");
        ATI.Put_Line("3 Shutdown server");
        ATI.Put_Line("4 Quit");
        ATI.New_Line(1);
    end Show_Menu;

    Server_EP : LLU.End_Point_Type;
    Admin_EP : LLU.End_Point_Type;
    Buffer :  aliased LLU.Buffer_Type(1024);
    Expired : Boolean;
    Host : ASU.Unbounded_String;
    Port : Natural;
    IP : ASU.Unbounded_String;
    Password : ASU.Unbounded_String;
    Finish : Boolean := False;
    Option : Natural;
    Nick : ASU.Unbounded_String;
    Mess_Type : CM.Message_Type;
    Clients : ASU.Unbounded_String;

begin
    if ACL.Argument_Count /= 3 then
        raise Usage_Error;
    end if;

    Host := ASU.To_Unbounded_String (ACL.Argument(1));
    Port := Integer'Value (ACL.Argument(2));
    Password := ASU.To_Unbounded_String (ACL.Argument(3));
    IP := ASU.To_Unbounded_String (LLU.To_IP(ASU.To_String(Host)));
    Server_EP := LLU.Build (ASU.To_String(IP), Port);
    LLU.Bind_Any (Admin_EP);

    while not Finish loop
        Show_Menu;
        ATI.Put ("Your option? ");
        Option := Integer'Value (ATI.Get_Line);

        case Option is
            when 1 =>
                ATI.New_Line (1);
                LLU.Reset (Buffer);
                CM.Message_Type'Output (Buffer'Access, CM.Collection_Request);
                LLU.End_Point_Type'Output (Buffer'Access, Admin_EP);
                ASU.Unbounded_String'Output(Buffer'Access, Password);
                LLU.Send (Server_EP, Buffer'Access);

                LLU.Reset (Buffer);
                LLU.Receive (Admin_EP, Buffer'Access, 5.0, Expired);
                if Expired then
                    raise Password_Error;
                else
                    Mess_Type := CM.Message_Type'Input (Buffer'Access);
                    Clients := ASU.Unbounded_String'Input (Buffer'Access);
                    ATI.Put_Line(ASU.To_String(Clients));
                    LLU.Reset (Buffer);
                end if;
            when 2 =>
                ATI.Put ("Nick to ban? ");
                Nick := ASU.To_Unbounded_String(ATI.Get_Line);
                ATI.New_Line(1);
                LLU.Reset (Buffer);
                CM.Message_Type'Output (Buffer'Access, CM.Ban);                    ASU.Unbounded_String'Output (Buffer'Access, Password);
                ASU.Unbounded_String'Output (Buffer'Access, Nick);
                LLU.Send (Server_EP, Buffer'Access);
            when 3 =>
                ATI.Put_Line ("Server shutdown sent");
                ATI.New_Line(1);
                LLU.Reset (Buffer);
                CM.Message_Type'Output (Buffer'Access, CM.Shutdown);
                ASU.Unbounded_String'Output (Buffer'Access, Password);
                LLU.Send (Server_EP, Buffer'Access);
            when 4 =>
                Finish := True;
            when others =>
                ATI.New_Line(1);
                ATI.Put_Line("Option out of range");
                ATI.New_Line(1);
        end case;
    end loop;

    LLU.Reset (Buffer);
    LLU.Finalize;

exception
    when Usage_Error =>
 	    ATI.Put_Line("Usage Error. Use => usage: <Host> <port> <Pasword> ");
        LLU.Finalize;
    when Password_Error =>
        ATI.Put_Line("Incorrect Password");
        LLU.Finalize;
    when Ex:others =>
        ATI.Put_Line ("Excepción imprevista: " & Ada.Exceptions.Exception_Name(Ex) & " en: " & Ada.Exceptions.Exception_Message(Ex));
        LLU.Finalize;
end Chat_Admin;
