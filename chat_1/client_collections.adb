with Ada.Unchecked_Deallocation;

package body Client_Collections is

    procedure Free is new Ada.Unchecked_Deallocation (Cell, Cell_A);

    procedure Add_Client (Collection: in out Collection_Type;
                            EP: in LLU.End_Point_Type;
                            Nick: in ASU.Unbounded_String;
                            Unique: in Boolean) is

        P_Aux : Cell_A;
        P_Search : Cell_A := Collection.P_First;
        In_List: Boolean := False;
    begin
        while not In_List and P_Search /= null loop
            if ASU.To_String (P_Search.Nick) = ASU.To_String (Nick) then
                In_List := True;
            else
                P_Search := P_Search.Next;
            end if;
        end loop;

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

    procedure Delete_Client (Collection: in out Collection_Type; Nick: in ASU.Unbounded_String) is
        P_Aux_1 : Cell_A := Collection.P_First;
        P_Aux_2 : Cell_A := Collection.P_First;
        In_List : Boolean := False;
    begin
        if Collection.P_First = null then
            raise Client_Collection_Error;
        end if;

        if ASU.To_String (Collection.P_First.Nick) = ASU.To_String (Nick)  then
		    P_Aux_2 := P_Aux_1.Next;
			Free (P_Aux_1);
			Collection.Total := Collection.Total-1;
			Collection.P_First := P_Aux_2;
		else
			P_Aux_1 := P_Aux_2.Next;
			while not In_List loop
				if P_Aux_1 /= null and then ASU.To_String (Nick) = ASU.To_String (P_Aux_1.Nick) then
					P_Aux_2.Next := P_Aux_1.Next;
					Free (P_Aux_1);
					Collection.Total := Collection.Total-1;
					In_List := True;
				elsif P_Aux_1 = null then
					raise Client_Collection_Error;
				else
					P_Aux_1 := P_Aux_1.Next;
					P_Aux_2 := P_Aux_2.Next;
				end if;
			end loop;
        end if;

    end Delete_Client;

    function Search_Client (Collection: in Collection_Type; EP: in LLU.End_Point_Type) return ASU.Unbounded_String is
        P_Aux: Cell_A := Collection.P_First;
        Finish: Boolean := False;
        Nick: ASU.Unbounded_String;
    begin
        while not Finish and P_Aux /= null loop
            if LLU.Image (EP) =  LLU.Image (P_Aux.Client_EP) then
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
            P_Aux := P_Aux.next;
        end loop;
    end Send_To_All;

    procedure Client_Adress (Adress: in out ASU.Unbounded_String) is
        Posicion: Natural;
        Port: ASU.Unbounded_String;
        IP: ASU.Unbounded_String;
    begin
        Posicion := ASU.Index (Adress, ":" );
        Adress := ASU.Tail (Adress, ASU.Length(Adress)-(Posicion+1));
        Posicion := ASU.Index (Adress, ",");
        IP := ASU.Head (Adress, Posicion-1);
        Posicion := ASU.Index (Adress, ":");
        Port := ASU.Tail (Adress, ASU.Length(Adress)-Posicion);
        Posicion := ASU.Index (Port, " ");
        Port := ASU.Tail (Port, ASU.Length(Port)-(Posicion+1));
        Adress := ASU.To_Unbounded_String (ASU.To_String(IP) & ":" & ASU.To_String(Port));
    end Client_Adress;

    function Collection_Image (Collection: in Collection_Type) return String is
        P_Aux: Cell_A := Collection.P_First;
        Adress: ASU.Unbounded_String ;
        Clients: ASU.Unbounded_String;
    begin
        while P_Aux /= null loop
            Adress := ASU.To_Unbounded_String (LLU.Image(P_Aux.Client_EP));
            Client_Adress (Adress);
            Clients := ASU.To_Unbounded_String (ASU.To_String(Clients) & ASU.To_String(Adress) & " " & ASU.To_String(P_Aux.Nick) & ASCII.LF);
            P_Aux := P_Aux.Next;
        end loop;

        return ASU.To_String (Clients);

    end Collection_Image;

end Client_Collections;
