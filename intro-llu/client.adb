with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;

procedure Client is
   pacKAGE ATI renames Ada.Text_IO;
   package LLU renames Lower_Layer_UDP;
   package ASU renames Ada.Strings.Unbounded;
   package ACL renames Ada.Command_Line;

   procedure Show_Menu is
   begin
    ATI.New_Line(1);
    ATI.Put_Line("Options: ");
    ATI.Put_Line("1 Enviar un entero");
    ATI.Put_Line("2 Enviar una cadena de caracteres");
    ATI.Put_Line("3 quit");
    ATI.New_Line(1);
  end Show_Menu;

     Server_EP: LLU.End_Point_Type;
     Client_EP: LLU.End_Point_Type;
     Buffer:  aliased LLU.Buffer_Type(1024);
     Cadena: ASU.Unbounded_String;
     Reply: Natural;
     Expired: Boolean;
     Maquina: ASU.Unbounded_String;
     Puerto: Natural;
     IP: ASU.Unbounded_String;
     Finish: Boolean := False;
     Option: Natural;
     Entero: Natural;

begin
   Maquina := ASU.To_Unbounded_String(ACL.Argument(1));
   Puerto := Integer'Value(ACL.Argument(2));
   IP := ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Maquina)));
   Server_EP := LLU.Build(ASU.To_String(IP), Puerto);
   LLU.Bind_Any(Client_EP);
   LLU.Reset(Buffer);

   while not Finish loop
    Show_Menu;
    ATI.Put("Your option? ");
    Option := Integer'Value(ATI.Get_Line);
    LLU.End_Point_Type'Output(Buffer'Access,Client_EP);
    case Option is
        when 1 =>
          ATI.Put("Introduce un entero: ");
          Entero := Integer'Value(ATI.Get_Line);
          Integer'Output(Buffer'Access, Option);
          Integer'Output(Buffer'Access, Entero);
          LLU.Send(Server_EP, Buffer'Access );
        when 2 =>
          ATI.Put("Introduce una cadena caracteres: ");
          Cadena := ASU.To_Unbounded_String(ATI.Get_Line);
          Integer'Output(Buffer'Access, Option);
          ASU.Unbounded_String'Output(Buffer'Access, Cadena);
          LLU.Send(Server_EP, Buffer'Access);
        when 3 =>
          Finish := True;
        when others =>
          ATI.Put_Line("Opcion invalida");
          Finish := True;
        end case;

    if not Finish then
     LLU.Reset(Buffer);
     LLU.Receive(Client_EP, Buffer'Access, 2.0, Expired);
      if Expired then
        ATI.Put_Line ("Plazo expirado");
      else
        Reply := Integer'Input(Buffer'Access);
        ATI.Put("Respuesta: ");
        ATI.Put_Line(Integer'Image(Reply));
      end if;
    end if;
    LLU.Reset(Buffer);
  end loop;
   LLU.Finalize;

exception
   when Ex:others =>
      ATI.Put_Line ("Excepción imprevista: " & Ada.Exceptions.Exception_Name(Ex) & " en: " &Ada.Exceptions.Exception_Message(Ex));
      LLU.Finalize;

end Client;
