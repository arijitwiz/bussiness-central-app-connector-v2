table 50120 "WZC Api Rate State"
{
    DataClassification = SystemMetadata;
    Caption = 'WizCommerce API Rate State';

    fields
    {
        field(1; "Api Name"; Code[30])
        {
            Caption = 'Api Name';
        }
        field(10; "Window Start"; DateTime)
        {
            Caption = 'Window Start';
        }
        field(11; "Call Count"; Integer)
        {
            Caption = 'Call Count';
        }
    }

    keys
    {
        key(PK; "Api Name")
        {
            Clustered = true;
        }
    }
}
