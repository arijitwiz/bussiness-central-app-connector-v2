tableextension 50113 "WZC Sales Header Ext" extends "Sales Header"
{
    fields
    {
        field(50100; "WZC External Id"; Code[50])
        {
            Caption = 'WZC External Id';
            DataClassification = CustomerContent;
            ToolTip = 'WizCommerce document id. Idempotency key for order push: a retried POST with the same id adopts the existing order instead of creating a second one.';
        }
        field(50101; "WZC Order Notes"; Text[2048])
        {
            Caption = 'WZC Order Notes';
            DataClassification = CustomerContent;
            ToolTip = 'Free-text order notes from WizCommerce. Also materialised as Sales Comment Lines (Code = WZC).';
        }
        field(50102; "WZC Source"; Code[20])
        {
            Caption = 'WZC Source';
            DataClassification = CustomerContent;
            ToolTip = 'Originating system of the order (WIZCOMMERCE when created through the WZC Sales Order Write API).';
        }
    }

    keys
    {
        key(WZCExternalId; "WZC External Id")
        {
        }
    }
}
