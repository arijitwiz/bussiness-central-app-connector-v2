page 50109 "WZC Sync Run Log List"
{
    PageType = List;
    SourceTable = "WZC Sync Run Log";
    Caption = 'WizCommerce Sync Run Log';
    ApplicationArea = All;
    UsageCategory = Lists;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Profile No."; Rec."Profile No.")
                {
                    ApplicationArea = All;
                }
                field("Config Version"; Rec."Config Version")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Started At"; Rec."Started At")
                {
                    ApplicationArea = All;
                }
                field("Ended At"; Rec."Ended At")
                {
                    ApplicationArea = All;
                }
                field("Records Processed"; Rec."Records Processed")
                {
                    ApplicationArea = All;
                }
                field("Window Lower Bound"; Rec."Window Lower Bound")
                {
                    ApplicationArea = All;
                }
                field("Window Upper Bound"; Rec."Window Upper Bound")
                {
                    ApplicationArea = All;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                }
                field("Run By"; Rec."Run By")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
