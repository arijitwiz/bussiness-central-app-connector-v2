table 50116 "WZC Sync Checkpoint"
{
    DataClassification = SystemMetadata;
    Caption = 'WizCommerce Sync Checkpoint';

    fields
    {
        field(1; "Profile No."; Code[20])
        {
            Caption = 'Profile No.';
            TableRelation = "WZC Sync Profile"."Profile No.";
        }
        field(10; "Last Checkpoint DateTime"; DateTime)
        {
            Caption = 'Last Checkpoint DateTime';
            Editable = false;
        }
        field(11; "Config Version At Checkpoint"; Integer)
        {
            Caption = 'Config Version At Checkpoint';
            Editable = false;
        }
        field(20; "Run In Progress"; Boolean)
        {
            Caption = 'Run In Progress';
            Editable = false;
        }
        field(21; "Run Started At"; DateTime)
        {
            Caption = 'Run Started At';
            Editable = false;
        }
        field(30; "Last Successful Run At"; DateTime)
        {
            Caption = 'Last Successful Run At';
            Editable = false;
        }
        field(31; "Last Successful Run Count"; Integer)
        {
            Caption = 'Last Successful Run Count';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Profile No.")
        {
            Clustered = true;
        }
    }
}
