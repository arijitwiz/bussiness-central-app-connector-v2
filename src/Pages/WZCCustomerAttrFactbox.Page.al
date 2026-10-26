page 50152 "WZC Customer Attr Factbox"
{
    PageType = ListPart;
    SourceTable = "WZC Customer Attribute";
    Caption = 'WizCommerce Attributes';
    ApplicationArea = All;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Attribute key, e.g. ACCT_TIER, CREDIT_RATING.';
                }
                field("Attribute Value"; Rec."Attribute Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'The value for this attribute.';
                }
                field("Data Type"; Rec."Data Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Text, Integer, Boolean, or Decimal.';
                }
            }
        }
    }
}
