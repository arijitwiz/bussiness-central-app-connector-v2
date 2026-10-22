table 50118 "WZC Attribute Change Log"
{
    DataClassification = SystemMetadata;
    Caption = 'WizCommerce Attribute Change Log';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(10; "Log Type"; Option)
        {
            Caption = 'Log Type';
            OptionMembers = "Config Change","Sync Error";
        }
        field(20; "Logical Name"; Code[50])
        {
            Caption = 'Logical Name';
        }
        field(21; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
        }
        field(22; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
        }
        field(30; "Change Type"; Text[20])
        {
            Caption = 'Change Type';
        }
        field(31; "Old Value"; Text[250])
        {
            Caption = 'Old Value';
        }
        field(32; "New Value"; Text[250])
        {
            Caption = 'New Value';
        }
        field(40; "Message"; Text[500])
        {
            Caption = 'Message';
        }
        field(50; "Changed By"; Code[50])
        {
            Caption = 'Changed By';
        }
        field(51; "Changed At"; DateTime)
        {
            Caption = 'Changed At';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(SK1; "Logical Name", "Changed At")
        {
        }
    }
}
