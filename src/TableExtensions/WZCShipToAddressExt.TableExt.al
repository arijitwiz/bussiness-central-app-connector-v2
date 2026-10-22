tableextension 50110 "WZC Ship-to Address Ext" extends "Ship-to Address"
{
    fields
    {
        field(50100; "WZC Create Address"; Boolean)
        {
            Caption = 'WZC Create Address';
            DataClassification = CustomerContent;
        }
        field(50101; "WZC Delivery Instructions"; Text[250])
        {
            Caption = 'WZC Delivery Instructions';
            DataClassification = CustomerContent;
        }
    }

    trigger OnAfterInsert()
    begin
        SyncWzcToAttrStore();
    end;

    trigger OnAfterModify()
    begin
        SyncWzcToAttrStore();
    end;

    local procedure SyncWzcToAttrStore()
    begin
        UpsertAttr('CREATEADDRESS', Format(Rec."WZC Create Address"), Enum::"WZC Attribute Data Type"::Boolean);
        UpsertAttr('DELIVERYINSTRUCTIONS', Rec."WZC Delivery Instructions", Enum::"WZC Attribute Data Type"::Text);
    end;

    local procedure UpsertAttr(AttrName: Code[50]; AttrValue: Text[250]; DataType: Enum "WZC Attribute Data Type")
    var
        Attr: Record "WZC Ship-to Attribute";
    begin
        if AttrValue = '' then begin
            if Attr.Get(Rec."Customer No.", Rec.Code, AttrName) then
                Attr.Delete(false);
            exit;
        end;

        if not Attr.Get(Rec."Customer No.", Rec.Code, AttrName) then begin
            Attr.Init();
            Attr."Customer No." := Rec."Customer No.";
            Attr."Ship-to Code" := Rec.Code;
            Attr."Attribute Name" := AttrName;
            Attr."Data Type" := DataType;
            Attr."Attribute Value" := AttrValue;
            Attr.Insert(false);
        end else begin
            Attr."Attribute Value" := AttrValue;
            Attr."Data Type" := DataType;
            Attr.Modify(false);
        end;
    end;
}
