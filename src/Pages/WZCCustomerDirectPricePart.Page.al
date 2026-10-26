page 50149 "WZC Customer Direct Price Part"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Customer Direct Price';
    EntitySetCaption = 'Wiz Customer Direct Prices';
    EntityName = 'wizCustomerDirectPrice';
    EntitySetName = 'wizCustomerDirectPrices';
    SourceTable = "Price List Line";
    SourceTableView = where("Source Type" = const(Customer), "Price Type" = const(Sale), "Asset Type" = const(Item), Status = const(Active));
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Active price list lines set directly on this customer (Source Type = Customer), inline under wizCustomers ($expand=wizCustomerDirectPrices). For price group prices use $expand=wizCustomerPrices.';

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
                field(priceListCode; Rec."Price List Code")
                {
                    Caption = 'Price List Code';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(itemNo; Rec."Asset No.")
                {
                    Caption = 'Item No.';
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
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
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(lineDiscountPercent; Rec."Line Discount %")
                {
                    Caption = 'Line Discount %';
                }
                field(priceIncludesTax; Rec."Price Includes VAT")
                {
                    Caption = 'Price Includes Tax';
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
}
