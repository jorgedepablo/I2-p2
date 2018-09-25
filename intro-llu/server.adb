with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;

procedure Server is
   package ATI renames Ada.Text_IO;
   package LLU renames Lower_Layer_UDP;
   package ASU renames Ada.Strings.Unbounded;
   package ACL renames Ada.Command_Line;

   Server_EP: LLU.End_Point_Type;
   Client_EP: LLU.End_Point_Type;
   Buffer:    aliased LLU.Buffer_Type(1024);
   Reply: Natural;
   Expired : Boolean;
   Maquina: ASU.Unbounded_String;
   Puerto: Natural;
   IP: ASU.Unbounded_String;
   Option: Natural;
   Entero: Natural;
   Cadena: ASU.Unbounded_String;

begin

   Puerto := Integer'Value(ACL.Argument(1));
   Maquina := ASU.To_Unbounded_String(LLU.Get_Host_Name);
   IP := ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Maquina)));
   Server_EP := LLU.Build (ASU.To_String(IP), Puerto);
   LLU.Bind (Server_EP);


   loop
      LLU.Reset(Buffer);
      LLU.Receive (Server_EP, Buffer'Access, 1000.0, Expired);

      if Expired then
         Ada.Text_IO.Put_Line ("Plazo expirado, vuelvo a intentarlo");
      else
         Client_EP := LLU.End_Point_Type'Input (Buffer'Access);
         Option := Integer'Input (Buffer'Access);
         if Option = 1  then
           Entero := Integer'Input (Buffer'Access);
           Reply := Entero * 2;
           LLU.Reset (Buffer);
         elsif Option = 2 then
           Cadena := ASU.Unbounded_String'Input (Buffer'Access);
           Reply := ASU.Length(Cadena);
           LLU.Reset (Buffer);
         end if;
          Integer'Output (Buffer'Access, Reply);
          LLU.Send (Client_EP, Buffer'Access);
          LLU.Reset (Buffer);
      end if;
   end loop;

exception
   when Ex:others =>
      Ada.Text_IO.Put_Line ("Excepción imprevista: " & Ada.Exceptions.Exception_Name(Ex) & " en: " & Ada.Exceptions.Exception_Message(Ex));
      LLU.Finalize;

end Server;
