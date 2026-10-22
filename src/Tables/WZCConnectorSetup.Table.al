table 50110 "WZC Connector Setup"
{
    DataClassification = SystemMetadata;
    Caption = 'WizCommerce Connector Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Ship-to Address API Enabled"; Boolean)
        {
            Caption = 'Ship-to Address API Enabled';
            ObsoleteState = Pending;
            ObsoleteReason = 'Superseded by the Enabled field on WZC Api Config (row ''SHIPTOADDR''), which also carries the per-hour rate limit. No longer read by any page.';
            ObsoleteTag = '1.0.0.5';
        }
        field(11; "Shipment Tracking API Enabled"; Boolean)
        {
            Caption = 'Shipment Tracking API Enabled';
            ObsoleteState = Pending;
            ObsoleteReason = 'Superseded by the Enabled field on WZC Api Config (row ''SHIPMENTTRACK'').';
            ObsoleteTag = '1.0.0.5';
        }
        field(12; "Customer Price API Enabled"; Boolean)
        {
            Caption = 'Customer Price API Enabled';
            ObsoleteState = Pending;
            ObsoleteReason = 'Superseded by the Enabled field on WZC Api Config (row ''CUSTPRICE'').';
            ObsoleteTag = '1.0.0.5';
        }
        field(13; "Item Availability API Enabled"; Boolean)
        {
            Caption = 'Item Availability API Enabled';
            ObsoleteState = Pending;
            ObsoleteReason = 'Superseded by the Enabled field on WZC Api Config (row ''ITEMAVAIL'').';
            ObsoleteTag = '1.0.0.5';
        }
        field(20; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            TableRelation = Location.Code;
        }
        field(21; "Price List Filter"; Code[20])
        {
            Caption = 'Price List Filter';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
