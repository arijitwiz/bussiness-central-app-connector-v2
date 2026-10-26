pageextension 50125 "WZC Sales Order Ext" extends "Sales Order"
{
    layout
    {
        addlast(factboxes)
        {
            part(WZCSalesOrderAttrFactbox; "WZC Sales Order Attr Factbox")
            {
                ApplicationArea = All;
                Caption = 'WizCommerce Attributes';
                SubPageLink = "Document Type" = const(Order), "Document No." = field("No.");
            }
        }
    }

    actions
    {
        addlast("Order")
        {
            action(WZCSalesOrderAttributes)
            {
                ApplicationArea = All;
                Caption = 'WizCommerce Attributes';
                Image = Attributes;
                RunObject = page "WZC Sales Order Attribute List";
                RunPageLink = "Document Type" = const(Order), "Document No." = field("No.");
                ToolTip = 'View and manage WizCommerce custom attributes for this sales order.';
            }
        }
    }
}
