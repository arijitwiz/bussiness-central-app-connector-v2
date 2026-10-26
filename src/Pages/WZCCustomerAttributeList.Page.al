page 50150 "WZC Customer Attribute List"
{
    PageType = List;
    SourceTable = "WZC Customer Attribute";
    Caption = 'WizCommerce Customer Attributes';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'The customer this attribute belongs to.';
                }
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The attribute key, e.g. ACCT_TIER, CREDIT_RATING.';
                }
                field("Attribute Value"; Rec."Attribute Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'The value for this attribute.';
                }
                field("Data Type"; Rec."Data Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'How WizCommerce should interpret the value: Text, Integer, Boolean, Decimal.';
                }
            }
        }
    }
}
