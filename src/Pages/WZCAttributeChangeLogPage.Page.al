page 50121 "WZC Attribute Change Log"
{
    PageType = List;
    SourceTable = "WZC Attribute Change Log";
    Caption = 'WizCommerce Attribute Change Log';
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
                field("Log Type"; Rec."Log Type")
                {
                    ApplicationArea = All;
                }
                field("Logical Name"; Rec."Logical Name")
                {
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = All;
                }
                field("Change Type"; Rec."Change Type")
                {
                    ApplicationArea = All;
                }
                field("New Value"; Rec."New Value")
                {
                    ApplicationArea = All;
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                }
                field("Changed By"; Rec."Changed By")
                {
                    ApplicationArea = All;
                }
                field("Changed At"; Rec."Changed At")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
