table 50121 "WZC Field Visibility"
{
    DataClassification = CustomerContent;
    Caption = 'WizCommerce Field Visibility';

    fields
    {
        field(1; "Api Operation"; Code[30])
        {
            Caption = 'Api Operation';
            TableRelation = "WZC Api Config"."Api Name";
        }
        field(2; "Field Name"; Code[50])
        {
            Caption = 'Field Name';
        }
        field(10; Visible; Boolean)
        {
            Caption = 'Visible';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Api Operation", "Field Name")
        {
            Clustered = true;
        }
    }
}
