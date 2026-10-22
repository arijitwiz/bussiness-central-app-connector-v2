table 50113 "WZC Ship-to Attribute"
{
    DataClassification = CustomerContent;
    Caption = 'WizCommerce Ship-to Address Attribute';

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer."No.";
        }
        field(2; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(3; "Attribute Name"; Code[50])
        {
            Caption = 'Attribute Name';
        }
        field(10; "Attribute Value"; Text[250])
        {
            Caption = 'Attribute Value';
        }
        field(20; "Data Type"; Enum "WZC Attribute Data Type")
        {
            Caption = 'Data Type';
        }
    }

    keys
    {
        key(PK; "Customer No.", "Ship-to Code", "Attribute Name")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        AttrMgt: Codeunit "WZC Attribute Mgt";
    begin
        AttrMgt.ValidateShipToOwnership(Rec."Customer No.", Rec."Ship-to Code");
        AttrMgt.ValidateAttributeValue(Rec);
    end;

    trigger OnModify()
    var
        AttrMgt: Codeunit "WZC Attribute Mgt";
    begin
        AttrMgt.ValidateShipToOwnership(Rec."Customer No.", Rec."Ship-to Code");
        AttrMgt.ValidateAttributeValue(Rec);
    end;
}
