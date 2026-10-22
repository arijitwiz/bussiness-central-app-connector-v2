page 50116 "WZC Api Config List"
{
    PageType = List;
    SourceTable = "WZC Api Config";
    Caption = 'WizCommerce Connector API Configuration';
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Friendly Name"; Rec."Friendly Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(EntityType; CurrentEntityType)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    Editable = false;
                    ToolTip = 'Which sync entity this API maps to. Blank = not linked to a filterable entity.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable or disable this API for this company.';
                }
                field("Rate Limit Per Hour"; Rec."Rate Limit Per Hour")
                {
                    ApplicationArea = All;
                    ToolTip = 'Maximum calls allowed per rolling hour for this API, in this company. 0 = unlimited.';
                }
                field(FilterStatus; CurrentFilterStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Filter';
                    Editable = false;
                    ToolTip = 'Whether a filter profile exists for this API and whether it''s active. Click Configure Filter to edit.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Initialize)
            {
                ApplicationArea = All;
                Caption = 'Refresh API List';
                Image = RefreshLines;
                ToolTip = 'Add any WZC APIs that are missing from this list (e.g. after an extension upgrade).';

                trigger OnAction()
                var
                    SetupMgt: Codeunit "WZC Setup Mgt";
                begin
                    SetupMgt.SeedAllApiConfigs();
                    CurrPage.Update(false);
                end;
            }
            action(ConfigureFilter)
            {
                ApplicationArea = All;
                Caption = 'Configure Filter';
                Image = Filter;
                ToolTip = 'Set up filter rules that apply to this API''s data (currently only Products support filtering).';

                trigger OnAction()
                var
                    Engine: Codeunit "WZC Sync Filter Engine";
                    Entity: Enum "WZC Sync Entity";
                    Profile: Record "WZC Sync Profile";
                    NewProfileNo: Code[20];
                begin
                    if not Engine.TryGetEntityForApiOperation(Rec."Api Name", Entity) then begin
                        Message('''%1'' isn''t linked to a filterable entity.', Rec."Friendly Name");
                        exit;
                    end;
                    if not Engine.IsEntityWired(Entity) then begin
                        Message('Filtering for ''%1'' (entity: %2) isn''t wired yet in this version - only Products supports filter rules currently.', Rec."Friendly Name", Entity);
                        exit;
                    end;

                    Profile.SetRange("Api Operation", Rec."Api Name");
                    if Profile.IsEmpty() then begin
                        if not Confirm('No filter profile exists yet for ''%1''. Create one now?', true, Rec."Friendly Name") then
                            exit;
                        NewProfileNo := CopyStr(Rec."Api Name" + '_FILTER', 1, 20);
                        Profile.Init();
                        Profile."Profile No." := NewProfileNo;
                        Profile.Description := Rec."Friendly Name" + ' Filter';
                        Profile.Entity := Entity;
                        Profile."Api Operation" := Rec."Api Name";
                        Profile.Direction := Profile.Direction::Pull;
                        Profile."Sync Mode" := Profile."Sync Mode"::Full;
                        Profile.Enabled := false;
                        Profile.Insert(true);
                    end else
                        Profile.FindFirst();

                    PAGE.Run(PAGE::"WZC Sync Profile Card", Profile);
                    CurrPage.Update(false);
                end;
            }
            action(ConfigureFields)
            {
                ApplicationArea = All;
                Caption = 'Configure Fields';
                Image = ViewDetails;
                ToolTip = 'Choose which response fields this company sees for this API. No rows configured = every field shown (code default).';

                trigger OnAction()
                var
                    FieldVisibility: Record "WZC Field Visibility";
                begin
                    FieldVisibility.SetRange("Api Operation", Rec."Api Name");
                    PAGE.Run(PAGE::"WZC Field Visibility List", FieldVisibility);
                end;
            }
        }
    }

    var
        CurrentEntityType: Text[30];
        CurrentFilterStatus: Text[100];

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.SeedAllApiConfigs();
    end;

    trigger OnAfterGetRecord()
    var
        Engine: Codeunit "WZC Sync Filter Engine";
        Entity: Enum "WZC Sync Entity";
        Profile: Record "WZC Sync Profile";
        ProfileCount: Integer;
    begin
        CurrentEntityType := '';
        CurrentFilterStatus := '';

        if not Engine.TryGetEntityForApiOperation(Rec."Api Name", Entity) then
            exit;

        CurrentEntityType := Format(Entity);

        if not Engine.IsEntityWired(Entity) then begin
            CurrentFilterStatus := 'Not wired yet';
            exit;
        end;

        Profile.SetRange("Api Operation", Rec."Api Name");
        ProfileCount := Profile.Count();
        if ProfileCount = 0 then
            CurrentFilterStatus := 'None configured'
        else begin
            Profile.SetRange(Enabled, true);
            if Profile.IsEmpty() then
                CurrentFilterStatus := StrSubstNo('%1 profile(s), none active', ProfileCount)
            else
                CurrentFilterStatus := StrSubstNo('Active (%1)', Profile.Count());
        end;
    end;
}
