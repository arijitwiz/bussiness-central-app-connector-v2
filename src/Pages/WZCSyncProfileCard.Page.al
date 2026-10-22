page 50106 "WZC Sync Profile Card"
{
    PageType = Card;
    SourceTable = "WZC Sync Profile";
    Caption = 'WizCommerce Sync Profile';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Profile No."; Rec."Profile No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Entity; Rec.Entity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Only Products is wired for filtering/sync in this version.';
                }
                field("Api Operation"; Rec."Api Operation")
                {
                    ApplicationArea = All;
                    ToolTip = 'Which WZC API this profile governs - must match an Api Name in WZC Api Config.';
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = All;
                }
                field("Sync Mode"; Rec."Sync Mode")
                {
                    ApplicationArea = All;
                }
                field("Overlap Seconds"; Rec."Overlap Seconds")
                {
                    ApplicationArea = All;
                    Visible = Rec."Sync Mode" = Rec."Sync Mode"::Incremental;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
                field("Is Template"; Rec."Is Template")
                {
                    ApplicationArea = All;
                }
                field("Config Version"; Rec."Config Version")
                {
                    ApplicationArea = All;
                }
            }
            group(Status)
            {
                Caption = 'Status';
                field("Validation Status"; Rec."Validation Status")
                {
                    ApplicationArea = All;
                }
                field("Last Sync Result"; Rec."Last Sync Result")
                {
                    ApplicationArea = All;
                }
                field("Last Sync At"; Rec."Last Sync At")
                {
                    ApplicationArea = All;
                }
            }
            part(FilterRules; "WZC Sync Filter Rule Subpage")
            {
                ApplicationArea = All;
                Caption = 'Filter Rules (AND across groups, OR within a group)';
                SubPageLink = "Profile No." = field("Profile No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Validate)
            {
                ApplicationArea = All;
                Caption = 'Validate';
                Image = CheckList;
                ToolTip = 'Check every filter rule against this entity''s allowlist and data types.';

                trigger OnAction()
                var
                    Engine: Codeunit "WZC Sync Filter Engine";
                begin
                    Engine.ValidateProfile(Rec);
                    Rec.Modify(true);
                    CurrPage.Update(false);
                    if Rec."Validation Status" = 'OK' then
                        Message('Validation passed.')
                    else
                        Message('Validation failed: %1', Rec."Validation Status");
                end;
            }
            action(PreviewRecords)
            {
                ApplicationArea = All;
                Caption = 'Preview Records';
                Image = ViewDetails;
                ToolTip = 'Count how many records currently match this profile''s filter rules (business rules only, no time window).';

                trigger OnAction()
                var
                    Engine: Codeunit "WZC Sync Filter Engine";
                    SampleNos: Text;
                    Count: Integer;
                begin
                    case Rec.Entity of
                        Rec.Entity::Product:
                            Count := Engine.PreviewMatchingItemCount(Rec, SampleNos);
                        Rec.Entity::ShipToAddress:
                            Count := Engine.PreviewMatchingShipToAddressCount(Rec, SampleNos);
                        else
                            Error('Preview isn''t wired for entity %1 yet.', Rec.Entity);
                    end;
                    Message('%1 matching record(s).\nSample: %2', Count, SampleNos);
                end;
            }
            action(ActivateProfile)
            {
                ApplicationArea = All;
                Caption = 'Activate';
                Image = Approve;
                ToolTip = 'Validate, then enable this profile.';

                trigger OnAction()
                var
                    Engine: Codeunit "WZC Sync Filter Engine";
                begin
                    Engine.ValidateProfile(Rec);
                    if Rec."Validation Status" <> 'OK' then begin
                        Rec.Modify(true);
                        Error('Cannot activate: %1', Rec."Validation Status");
                    end;
                    Rec.Enabled := true;
                    Rec.Modify(true);
                    CurrPage.Update(false);
                    Message('Profile activated.');
                end;
            }
            action(FetchAll)
            {
                ApplicationArea = All;
                Caption = 'Fetch All (Disable Filter)';
                Image = ClearFilter;
                ToolTip = 'Stop applying this profile''s filter rules - the API falls back to the code default of returning every record. The rules themselves are kept, not deleted, so you can Activate again later.';

                trigger OnAction()
                begin
                    Rec.Enabled := false;
                    Rec.Modify(true);
                    CurrPage.Update(false);
                    Message('Filter disabled - %1 will now return every record for this company until re-activated.', Rec."Api Operation");
                end;
            }
            action(CloneProfile)
            {
                ApplicationArea = All;
                Caption = 'Clone Profile';
                Image = CopyItem;
                ToolTip = 'Create a new, disabled copy of this profile and its filter rules.';

                trigger OnAction()
                var
                    NewProfile: Record "WZC Sync Profile";
                    SourceRule: Record "WZC Sync Filter Rule";
                    NewRule: Record "WZC Sync Filter Rule";
                    NewProfileNo: Code[20];
                begin
                    NewProfileNo := CopyStr(IncStr(Rec."Profile No."), 1, 20);
                    if NewProfileNo = Rec."Profile No." then
                        NewProfileNo := CopyStr(Rec."Profile No." + '_COPY', 1, 20);

                    NewProfile.Init();
                    NewProfile.TransferFields(Rec);
                    NewProfile."Profile No." := NewProfileNo;
                    NewProfile.Enabled := false;
                    NewProfile."Is Template" := false;
                    NewProfile."Validation Status" := '';
                    NewProfile."Last Sync Result" := '';
                    NewProfile."Last Sync At" := 0DT;
                    NewProfile.Insert(true);

                    SourceRule.SetRange("Profile No.", Rec."Profile No.");
                    if SourceRule.FindSet() then
                        repeat
                            NewRule.Init();
                            NewRule.TransferFields(SourceRule);
                            NewRule."Profile No." := NewProfileNo;
                            NewRule.Insert(true);
                        until SourceRule.Next() = 0;

                    Message('Cloned to profile ''%1''.', NewProfileNo);
                    PAGE.Run(PAGE::"WZC Sync Profile Card", NewProfile);
                end;
            }
            action(ResetCheckpointAction)
            {
                ApplicationArea = All;
                Caption = 'Reset Checkpoint';
                Image = ResetStatus;
                ToolTip = 'Clears the incremental watermark for this profile - the next run becomes a full resync. Use with care.';

                trigger OnAction()
                var
                    CheckpointMgt: Codeunit "WZC Checkpoint Mgt";
                begin
                    if not Confirm('Reset the checkpoint for ''%1''? The next run will reprocess every matching record.', false, Rec."Profile No.") then
                        exit;
                    CheckpointMgt.ResetCheckpoint(Rec."Profile No.", 'Manually reset from profile card');
                    Message('Checkpoint reset.');
                end;
            }
            action(ViewCheckpoint)
            {
                ApplicationArea = All;
                Caption = 'View Checkpoint';
                Image = Approve;
                ToolTip = 'View this profile''s current watermark and run-lock status.';

                trigger OnAction()
                var
                    Checkpoint: Record "WZC Sync Checkpoint";
                begin
                    Checkpoint.SetRange("Profile No.", Rec."Profile No.");
                    PAGE.Run(PAGE::"WZC Sync Checkpoint List", Checkpoint);
                end;
            }
            action(ViewRunLog)
            {
                ApplicationArea = All;
                Caption = 'View Run Log';
                Image = Log;
                ToolTip = 'View this profile''s sync run history, including errors.';

                trigger OnAction()
                var
                    RunLog: Record "WZC Sync Run Log";
                begin
                    RunLog.SetRange("Profile No.", Rec."Profile No.");
                    PAGE.Run(PAGE::"WZC Sync Run Log List", RunLog);
                end;
            }
        }
    }
}
