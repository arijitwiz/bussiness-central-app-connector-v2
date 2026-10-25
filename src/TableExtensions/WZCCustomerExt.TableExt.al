tableextension 50111 "WZC Customer Ext" extends Customer
{
    fields
    {
        field(50100; "WZC External Id"; Code[50])
        {
            Caption = 'WZC External Id';
            DataClassification = CustomerContent;
            ToolTip = 'WizCommerce buyer id. Used as the idempotency key for buyer push: a POST that repeats an existing external id updates that customer instead of creating a duplicate.';
        }
        field(50101; "WZC Web Customer"; Boolean)
        {
            Caption = 'WZC Web Customer';
            DataClassification = CustomerContent;
            ToolTip = 'Marks the customer as synced to WizCommerce. Usable as a Sync Profile filter rule.';
        }
    }

    keys
    {
        key(WZCExternalId; "WZC External Id")
        {
        }
    }
}
