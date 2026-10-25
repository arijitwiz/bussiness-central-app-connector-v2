tableextension 50112 "WZC Item Ext" extends Item
{
    fields
    {
        field(50100; "WZC Sell On Website"; Boolean)
        {
            Caption = 'WZC Sell On Website';
            DataClassification = CustomerContent;
            ToolTip = 'Gates which items WizCommerce pulls (replaces the per-tenant sellOnWebsite flag). Usable as a Sync Profile filter rule.';
        }
        field(50101; "WZC External Id"; Code[50])
        {
            Caption = 'WZC External Id';
            DataClassification = CustomerContent;
            ToolTip = 'WizCommerce product id, written back by the connector for reconciliation.';
        }
    }

    keys
    {
        key(WZCSellOnWebsite; "WZC Sell On Website")
        {
        }
    }
}
