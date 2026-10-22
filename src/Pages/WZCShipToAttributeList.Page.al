page 50115 "WZC Ship-to Attribute List"
{
    PageType = List;
    SourceTable = "WZC Ship-to Attribute";
    Caption = 'WizCommerce Ship-to Address Attributes';
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
                    ToolTip = 'The customer this ship-to address belongs to.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'The Ship-to Address code on that customer.';
                }
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Whatever name this tenant wants to call the attribute, e.g. GST Number, Delivery Window.';
                }
                field("Attribute Value"; Rec."Attribute Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'The value for this attribute.';
                }
                field("Data Type"; Rec."Data Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'How WizCommerce should interpret the value.';
                }
            }
        }
    }
}
