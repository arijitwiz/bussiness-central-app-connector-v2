table 50112 "WZC Api Config"
{
    DataClassification = SystemMetadata;
    Caption = 'WizCommerce Connector API Configuration';

    fields
    {
        field(1; "Api Name"; Code[30])
        {
            Caption = 'Api Name';
        }
        field(10; "Friendly Name"; Text[100])
        {
            Caption = 'Friendly Name';
        }
        field(20; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(30; "Rate Limit Per Hour"; Integer)
        {
            Caption = 'Rate Limit Per Hour';
            InitValue = 0;
            MinValue = 0;
        }
        field(40; "Window Start"; DateTime)
        {
            Caption = 'Window Start';
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to WZC Api Rate State to keep this table free of DateTime fields (a blank DateTime here was suspected of causing "The date is not valid" errors in the web client''s inline-edit grid).';
            ObsoleteTag = '1.0.0.10';
        }
        field(41; "Call Count"; Integer)
        {
            Caption = 'Call Count';
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to WZC Api Rate State.';
            ObsoleteTag = '1.0.0.10';
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
