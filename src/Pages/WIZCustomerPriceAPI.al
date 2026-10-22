page 50102 "WZC Customer Price API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v1.0';
    EntityCaption = 'Wiz Customer Price';
    EntitySetCaption = 'Wiz Customer Prices';
    EntityName = 'wizCustomerPrice';
    EntitySetName = 'wizCustomerPrices';
    SourceTable = "Price List Line";
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Read-only customer price list lines for WizCommerce buyer price enrichment. Microsoft APIV2 does not expose this projection.';

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
                field(customerNumber; Rec."Source No.")
                {
                    Caption = 'Customer Number';
                }
                field(itemNo; Rec."Asset No.")
                {
                    Caption = 'Item No.';
                }
                field(unitOfMeasure; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure';
                }
                field(minimumQuantity; Rec."Minimum Quantity")
                {
                    Caption = 'Minimum Quantity';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Unit Price';
                }
                field(startingDate; Rec."Starting Date")
                {
                    Caption = 'Starting Date';
                }
                field(endingDate; Rec."Ending Date")
                {
                    Caption = 'Ending Date';
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
        Setup: Record "WZC Connector Setup";
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.EnforceApiAccess('CUSTPRICE', 'WZC Customer Price API');
        SetupMgt.GetSetup(Setup);
        if Setup."Price List Filter" <> '' then
            Rec.SetRange("Price List Code", Setup."Price List Filter");
    end;
}
