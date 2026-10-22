table 50115 "WZC Sync Filter Rule"
{
    DataClassification = CustomerContent;
    Caption = 'WizCommerce Sync Filter Rule';

    fields
    {
        field(1; "Profile No."; Code[20])
        {
            Caption = 'Profile No.';
            TableRelation = "WZC Sync Profile"."Profile No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Field Name"; Text[50])
        {
            Caption = 'Field Name';

            trigger OnValidate()
            var
                Profile: Record "WZC Sync Profile";
                Engine: Codeunit "WZC Sync Filter Engine";
            begin
                if Profile.Get(Rec."Profile No.") then
                    Engine.CheckFieldAllowed(Profile.Entity, Rec."Field Name");
            end;
        }
        field(20; Operator; Enum "WZC Filter Operator")
        {
            Caption = 'Operator';

            trigger OnValidate()
            var
                Profile: Record "WZC Sync Profile";
                Engine: Codeunit "WZC Sync Filter Engine";
            begin
                if Profile.Get(Rec."Profile No.") then
                    Engine.CheckOperatorAllowed(Profile.Entity, Rec."Field Name", Rec.Operator);
            end;
        }
        field(30; Value; Text[250])
        {
            Caption = 'Value';
        }
        field(40; "Group No."; Integer)
        {
            Caption = 'Group No.';
        }
        field(50; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Profile No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if Rec."Line No." = 0 then
            Rec."Line No." := GetNextLineNo();
        if Rec."Group No." = 0 then
            Rec."Group No." := Rec."Line No.";
    end;

    local procedure GetNextLineNo(): Integer
    var
        LastRule: Record "WZC Sync Filter Rule";
    begin
        LastRule.SetRange("Profile No.", Rec."Profile No.");
        if LastRule.FindLast() then
            exit(LastRule."Line No." + 10000);
        exit(10000);
    end;
}
