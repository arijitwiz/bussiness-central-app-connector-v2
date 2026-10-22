page 50122 "WZC Field Visibility List"
{
    PageType = List;
    SourceTable = "WZC Field Visibility";
    Caption = 'WizCommerce Field Visibility';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Api Operation"; Rec."Api Operation")
                {
                    ApplicationArea = All;
                    ToolTip = 'Which WZC API this applies to, e.g. SHIPTOADDR.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The response field name as it appears in the JSON, e.g. country, county.';
                }
                field(Visible; Rec.Visible)
                {
                    ApplicationArea = All;
                    ToolTip = 'If any row exists for an Api Operation, only fields marked Visible here are shown - everything else is blanked for that API. If NO rows exist for an Api Operation, every field is shown by default.';
                }
            }
        }
    }
}
