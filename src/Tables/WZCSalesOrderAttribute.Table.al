table 50123 "WZC Sales Order Attribute"
{
    DataClassification = CustomerContent;
    Caption = 'WizCommerce Sales Order Attribute';

    fields
    {
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
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
        key(PK; "Document Type", "Document No.", "Attribute Name")
        {
            Clustered = true;
        }
    }
}
