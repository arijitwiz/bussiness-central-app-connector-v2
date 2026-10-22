page 50101 "WZC Shipment Tracking API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v1.0';
    EntityCaption = 'Wiz Shipment Tracking';
    EntitySetCaption = 'Wiz Shipment Trackings';
    EntityName = 'wizShipmentTracking';
    EntitySetName = 'wizShipmentTrackings';
    SourceTable = "Sales Shipment Header";
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Read-only projection of carrier and package tracking fields from Sales Shipment Header for WizCommerce shipment enrichment.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(shipmentNumber; Rec."No.")
                {
                    Caption = 'Shipment Number';
                }
                field(shippingAgent; Rec."Shipping Agent Code")
                {
                    Caption = 'Shipping Agent';
                }
                field(packageTrackingNo; Rec."Package Tracking No.")
                {
                    Caption = 'Package Tracking No.';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.EnforceApiAccess('SHIPMENTTRACK', 'WZC Shipment Tracking API');
    end;
}
