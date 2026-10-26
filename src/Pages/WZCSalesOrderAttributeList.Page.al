page 50151 "WZC Sales Order Attribute List"
{
    PageType = List;
    SourceTable = "WZC Sales Order Attribute";
    Caption = 'WizCommerce Sales Order Attributes';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'The sales document type, e.g. Order, Quote.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'The sales document number.';
                }
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The attribute key, e.g. CAMPAIGN_CODE, SALES_CHANNEL.';
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
