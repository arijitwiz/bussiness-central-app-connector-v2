table 50114 "WZC Sync Profile"
{
    DataClassification = CustomerContent;
    Caption = 'WizCommerce Sync Profile';

    fields
    {
        field(1; "Profile No."; Code[20])
        {
            Caption = 'Profile No.';
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(20; Entity; Enum "WZC Sync Entity")
        {
            Caption = 'Entity';

            trigger OnValidate()
            begin
                if Rec."Api Operation" <> '' then
                    TestField("Api Operation", '');
            end;
        }
        field(21; "Api Operation"; Code[30])
        {
            Caption = 'Api Operation';
            TableRelation = "WZC Api Config"."Api Name";
        }
        field(30; Direction; Enum "WZC Attribute Sync Direction")
        {
            Caption = 'Direction';
        }
        field(31; "Sync Mode"; Enum "WZC Sync Mode")
        {
            Caption = 'Sync Mode';
        }
        field(32; "Overlap Seconds"; Integer)
        {
            Caption = 'Overlap Seconds';
            InitValue = 60;
            MinValue = 0;
        }
        field(40; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(41; "Is Template"; Boolean)
        {
            Caption = 'Is Template';
            Editable = false;
        }
        field(50; "Config Version"; Integer)
        {
            Caption = 'Config Version';
            Editable = false;
            InitValue = 1;
        }
        field(60; "Validation Status"; Text[250])
        {
            Caption = 'Validation Status';
            Editable = false;
        }
        field(61; "Last Sync Result"; Text[250])
        {
            Caption = 'Last Sync Result';
            Editable = false;
        }
        field(62; "Last Sync At"; DateTime)
        {
            Caption = 'Last Sync At';
            Editable = false;
        }
        field(70; "Last Modified At"; DateTime)
        {
            Caption = 'Last Modified At';
            Editable = false;
        }
        field(71; "Last Modified By"; Code[50])
        {
            Caption = 'Last Modified By';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Profile No.")
        {
            Clustered = true;
        }
        key(SK1; Entity, "Api Operation", Enabled)
        {
        }
    }

    trigger OnInsert()
    begin
        BumpConfigVersion();
    end;

    trigger OnModify()
    begin
        BumpConfigVersion();
    end;

    trigger OnDelete()
    var
        FilterRule: Record "WZC Sync Filter Rule";
        Checkpoint: Record "WZC Sync Checkpoint";
    begin
        FilterRule.SetRange("Profile No.", Rec."Profile No.");
        FilterRule.DeleteAll(true);

        if Checkpoint.Get(Rec."Profile No.") then
            Checkpoint.Delete(true);
    end;

    local procedure BumpConfigVersion()
    var
        xRecCopy: Record "WZC Sync Profile";
        IsNew: Boolean;
    begin
        IsNew := not xRecCopy.Get(Rec."Profile No.");
        if not IsNew then
            if (xRecCopy.Direction = Rec.Direction)
                and (xRecCopy."Sync Mode" = Rec."Sync Mode")
                and (xRecCopy."Api Operation" = Rec."Api Operation")
                and (xRecCopy.Entity = Rec.Entity)
            then
                exit; // no change that affects what gets synced

        if not IsNew then
            Rec."Config Version" := xRecCopy."Config Version" + 1;

        Rec."Last Modified At" := CurrentDateTime();
        Rec."Last Modified By" := CopyStr(UserId(), 1, MaxStrLen(Rec."Last Modified By"));
    end;
}
