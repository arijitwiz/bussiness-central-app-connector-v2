tableextension 73734362 "WZC Item Ext" extends Item
{
    fields
    {
        field(73734350; "WZC Sell On Website"; Boolean)
        {
            Caption = 'WZC Sell On Website';
            DataClassification = CustomerContent;
            ToolTip = 'Gates which items WizCommerce pulls (replaces the per-tenant sellOnWebsite flag). Usable as a Sync Profile filter rule.';
        }
        field(73734351; "WZC External Id"; Code[50])
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
