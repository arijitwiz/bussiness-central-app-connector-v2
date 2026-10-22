page 50108 "WZC Sync Checkpoint List"
{
    PageType = List;
    SourceTable = "WZC Sync Checkpoint";
    Caption = 'WizCommerce Sync Checkpoints';
    ApplicationArea = All;
    UsageCategory = Lists;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Profile No."; Rec."Profile No.")
                {
                    ApplicationArea = All;
                }
                field("Last Checkpoint DateTime"; Rec."Last Checkpoint DateTime")
                {
                    ApplicationArea = All;
                }
                field("Config Version At Checkpoint"; Rec."Config Version At Checkpoint")
                {
                    ApplicationArea = All;
                }
                field("Run In Progress"; Rec."Run In Progress")
                {
                    ApplicationArea = All;
                }
                field("Run Started At"; Rec."Run Started At")
                {
                    ApplicationArea = All;
                }
                field("Last Successful Run At"; Rec."Last Successful Run At")
                {
                    ApplicationArea = All;
                }
                field("Last Successful Run Count"; Rec."Last Successful Run Count")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
