pageextension 50124 "WZC Customer Card Ext" extends "Customer Card"
{
    layout
    {
        addlast(factboxes)
        {
            part(WZCCustomerAttrFactbox; "WZC Customer Attr Factbox")
            {
                ApplicationArea = All;
                Caption = 'WizCommerce Attributes';
                SubPageLink = "Customer No." = field("No.");
            }
        }
    }

    actions
    {
        addlast("Customer")
        {
            action(WZCCustomerAttributes)
            {
                ApplicationArea = All;
                Caption = 'WizCommerce Attributes';
                Image = Attributes;
                RunObject = page "WZC Customer Attribute List";
                RunPageLink = "Customer No." = field("No.");
                ToolTip = 'View and manage WizCommerce custom attributes for this customer.';
            }
        }
    }
}
