page 50140 "WZC Sales Order Line Part"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Sales Order Line';
    EntitySetCaption = 'Wiz Sales Order Lines';
    EntityName = 'wizSalesOrderLine';
    EntitySetName = 'wizSalesOrderLines';
    SourceTable = "Sales Line";
    SourceTableView = where("Document Type" = const(Order));
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    Extensible = false;
    AboutText = 'Sales order lines, shared by wizSalesOrders (read) and wizSalesOrderWrites (push). Deep insert with the header is supported; lineNo is assigned automatically when omitted. Field order matters on POST: lineType and number are validated before quantity and unitPrice.';

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
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(lineType; Rec.Type)
                {
                    Caption = 'Line Type';
                }
                field(number; Rec."No.")
                {
                    Caption = 'Number';

                    trigger OnValidate()
                    begin
                        Rec.Validate("No.");
                    end;
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Variant Code");
                    end;
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(description2; Rec."Description 2")
                {
                    Caption = 'Description 2';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Location Code");
                    end;
                }
                field(unitOfMeasure; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Unit of Measure Code");
                    end;
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';

                    trigger OnValidate()
                    begin
                        Rec.Validate(Quantity);
                    end;
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Unit Price';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Unit Price");
                    end;
                }
                field(lineDiscountPercent; Rec."Line Discount %")
                {
                    Caption = 'Line Discount %';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Line Discount %");
                    end;
                }
                field(lineDiscountAmount; Rec."Line Discount Amount")
                {
                    Caption = 'Line Discount Amount';
                    Editable = false;
                }
                field(lineAmount; Rec."Line Amount")
                {
                    Caption = 'Line Amount';
                    Editable = false;
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                    Editable = false;
                }
                field(amountIncludingTax; Rec."Amount Including VAT")
                {
                    Caption = 'Amount Including Tax';
                    Editable = false;
                }
                field(taxPercent; Rec."VAT %")
                {
                    Caption = 'Tax %';
                    Editable = false;
                }
                field(taxGroupCode; Rec."Tax Group Code")
                {
                    Caption = 'Tax Group Code';
                }
                field(quantityShipped; Rec."Quantity Shipped")
                {
                    Caption = 'Quantity Shipped';
                    Editable = false;
                }
                field(quantityInvoiced; Rec."Quantity Invoiced")
                {
                    Caption = 'Quantity Invoiced';
                    Editable = false;
                }
                field(outstandingQuantity; Rec."Outstanding Quantity")
                {
                    Caption = 'Outstanding Quantity';
                    Editable = false;
                }
                field(shipmentDate; Rec."Shipment Date")
                {
                    Caption = 'Shipment Date';
                }
                field(requestedDeliveryDate; Rec."Requested Delivery Date")
                {
                    Caption = 'Requested Delivery Date';
                }
                field(promisedDeliveryDate; Rec."Promised Delivery Date")
                {
                    Caption = 'Promised Delivery Date';
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Shortcut Dimension 1 Code");
                    end;
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Shortcut Dimension 2 Code");
                    end;
                }
                field(dimensionSetId; Rec."Dimension Set ID")
                {
                    Caption = 'Dimension Set ID';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Document Type" := Rec."Document Type"::Order;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        OrderWriteMgt: Codeunit "WZC Order Write Mgt";
    begin
        Rec."Document Type" := Rec."Document Type"::Order;
        if Rec."Line No." = 0 then
            Rec."Line No." := OrderWriteMgt.NextSalesLineNo(Rec."Document Type", Rec."Document No.");
        exit(true);
    end;
}
