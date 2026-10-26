page 50111 "WZC Connector Setup Card"
{
    PageType = Card;
    SourceTable = "WZC Connector Setup";
    Caption = 'WizCommerce Connector Setup';
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Data Filters';
                field("Location Filter"; Rec."Location Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Scope Item Availability to a single location. Leave blank for all locations.';
                }
                field("Price List Filter"; Rec."Price List Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Scope Customer Price API to a single Price List Code. Leave blank for all price lists.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenApiConfig)
            {
                ApplicationArea = All;
                Caption = 'API Configuration (enable/disable & rate limits)';
                Image = Setup;
                RunObject = page "WZC Api Config List";
                ToolTip = 'Enable/disable each WZC API and set per-hour rate limits for this company.';
            }
            action(OpenAttributeSetup)
            {
                ApplicationArea = All;
                Caption = 'Attribute Setup';
                Image = Setup;
                RunObject = page "WZC Attribute Setup";
                ToolTip = 'Configure which custom attributes are allowed on Ship-to Address, their data type, default, required status, and sync direction.';
            }
            action(OpenShipToAttributes)
            {
                ApplicationArea = All;
                Caption = 'Ship-to Address Attribute Values';
                Image = Comment;
                RunObject = page "WZC Ship-to Attribute List";
                ToolTip = 'Browse/edit the actual attribute values stored per address.';
            }
            action(OpenCustomerAttributes)
            {
                ApplicationArea = All;
                Caption = 'Customer Attribute Values';
                Image = CustomerList;
                RunObject = page "WZC Customer Attribute List";
                ToolTip = 'Browse/edit WizCommerce custom attribute values stored per customer.';
            }
            action(OpenSalesOrderAttributes)
            {
                ApplicationArea = All;
                Caption = 'Sales Order Attribute Values';
                Image = Sales;
                RunObject = page "WZC Sales Order Attribute List";
                ToolTip = 'Browse/edit WizCommerce custom attribute values stored per sales order.';
            }
        }
    }

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.GetSetup(Rec);
    end;
}
