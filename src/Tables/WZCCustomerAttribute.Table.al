table 50122 "WZC Customer Attribute"
{
    DataClassification = CustomerContent;
    Caption = 'WizCommerce Customer Attribute';

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer."No.";
        }
        field(2; "Attribute Name"; Code[50])
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
        key(PK; "Customer No.", "Attribute Name")
        {
            Clustered = true;
        }
    }
}
