with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Ada.Unchecked_Deallocation;

package body Client_Collections is

  package ATI renames Ada.Text_IO;

  procedure Free is new Ada.Unchecked_Deallocation(Cell, Cell_A);

procedure Add_Client (Collection: in out Collection_Type;
                      EP: in LLU.End_Point_Type;
                      Nick: in ASU.Unbounded_String;
                      Unique: in Boolean) is

  P_Aux : Cell_A;
  P_Search : Cell_A := Collection.P_First;
  In_List: Boolean := False;
  begin

    while	not In_List and P_Search /= null loop
      if ASU.To_String (P_Search.Nick) = ASU.To_String(Nick) then
        In_List := True;
      else
        P_Search := P_Search.Next;
      end if;
    end loop;
--Busca si el Nick está en la lista

    if not In_List then
      P_Aux := Collection.P_First;
      Collection.P_First := new Cell'(EP,Nick,P_Aux);
      Collection.Total := Collection.Total + 1;
    elsif In_List and Unique then
      raise Client_Collection_Error;
    elsif In_List and not Unique then
      P_Aux := Collection.P_First;
      Collection.P_First := new Cell'(EP,Nick,P_Aux);
      Collection.Total := Collection.Total + 1;
    end if;
  end Add_Client;

  procedure Delete_Client (Collection: in out Collection_Type;
                           Nick: in ASU.Unbounded_String) is
  begin
    null;
  end Delete_Client;

  function Search_Client (Collection: in Collection_Type;
                          EP: in LLU.End_Point_Type)
                          return ASU.Unbounded_String is
  P_Aux: Cell_A := Collection.P_First;
  Finish: Boolean := False;
  Nick: ASU.Unbounded_String;
  begin
    while not Finish and P_Aux /= null loop
      if LLU.Image (EP) =  LLU.Image (P_Aux.Client_EP) then --El LLU soluciona el error de CA_Adress
        Nick := P_Aux.Nick;
        Finish := True;
      else
        P_Aux := P_Aux.Next;
      end if;
    end loop;

    if not Finish then
        raise Client_Collection_Error;
    end if;

    return Nick;

  end Search_Client;

  procedure Send_To_All (Collection: in Collection_Type; P_Buffer: access LLU.Buffer_Type) is

   P_Aux: Cell_A := Collection.P_First;
   begin
     while P_Aux /= null loop
      LLU.Send(P_Aux.Client_EP, P_Buffer);
      P_Aux:= P_Aux.next;
     end loop;
  end Send_To_All;

  function Collection_Image (Collection: in Collection_Type)
                            return String is
  begin
    return "hola";
  end Collection_Image;

end Client_Collections;
