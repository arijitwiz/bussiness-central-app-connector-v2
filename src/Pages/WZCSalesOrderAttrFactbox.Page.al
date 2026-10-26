page 50153 "WZC Sales Order Attr Factbox"
{
    PageType = ListPart;
    SourceTable = "WZC Sales Order Attribute";
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
                    ToolTip = 'Attribute key, e.g. CAMPAIGN_CODE, SALES_CHANNEL.';
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
