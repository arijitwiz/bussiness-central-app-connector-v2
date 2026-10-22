table 50119 "WZC Sync Run Log"
{
    DataClassification = SystemMetadata;
    Caption = 'WizCommerce Sync Run Log';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(10; "Profile No."; Code[20])
        {
            Caption = 'Profile No.';
            TableRelation = "WZC Sync Profile"."Profile No.";
        }
        field(11; "Config Version"; Integer)
        {
            Caption = 'Config Version';
        }
        field(20; "Started At"; DateTime)
        {
            Caption = 'Started At';
        }
        field(21; "Ended At"; DateTime)
        {
            Caption = 'Ended At';
        }
        field(30; Status; Enum "WZC Sync Run Status")
        {
            Caption = 'Status';
        }
        field(40; "Records Processed"; Integer)
        {
            Caption = 'Records Processed';
        }
        field(50; "Window Lower Bound"; DateTime)
        {
            Caption = 'Window Lower Bound';
        }
        field(51; "Window Upper Bound"; DateTime)
        {
            Caption = 'Window Upper Bound';
        }
        field(60; "Error Message"; Text[500])
        {
            Caption = 'Error Message';
        }
        field(70; "Run By"; Code[50])
        {
            Caption = 'Run By';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(SK1; "Profile No.", "Started At")
        {
        }
    }
}
