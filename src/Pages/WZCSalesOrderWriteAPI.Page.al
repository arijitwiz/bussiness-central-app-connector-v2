page 50142 "WZC Sales Order Write API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Sales Order Write';
    EntitySetCaption = 'Wiz Sales Order Writes';
    EntityName = 'wizSalesOrderWrite';
    EntitySetName = 'wizSalesOrderWrites';
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = const(Order));
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Unified ORDER push API (replaces per-tenant salesOrderWs). POST creates a sales order with lines (deep insert on wizSalesOrderLines) and notes in one call. IDEMPOTENT: send the WizCommerce document id as externalId - a retried POST with the same externalId adopts the existing order (search-before-create) and never creates a second one. Dimension combinations / blocked values are validated before the order is accepted; orderNotes are also materialised as Sales Comment Lines (Code = WZC).';

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
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                }
                field(externalId; Rec."WZC External Id")
                {
                    Caption = 'External Id';
                }
                field(externalDocumentNumber; Rec."External Document No.")
                {
                    Caption = 'External Document No.';
                }
                field(yourReference; Rec."Your Reference")
                {
                    Caption = 'Your Reference';
                }
                field(source; Rec."WZC Source")
                {
                    Caption = 'Source';
                }
                field(customerNumber; Rec."Sell-to Customer No.")
                {
                    Caption = 'Customer Number';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Sell-to Customer No.");
                    end;
                }
                field(billToCustomerNumber; Rec."Bill-to Customer No.")
                {
                    Caption = 'Bill-to Customer Number';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Bill-to Customer No.");
                    end;
                }
                field(shipToCode; Rec."Ship-to Code")
                {
                    Caption = 'Ship-to Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Ship-to Code");
                    end;
                }
                field(shipToName; Rec."Ship-to Name")
                {
                    Caption = 'Ship-to Name';
                }
                field(shipToAddress; Rec."Ship-to Address")
                {
                    Caption = 'Ship-to Address';
                }
                field(shipToAddress2; Rec."Ship-to Address 2")
                {
                    Caption = 'Ship-to Address 2';
                }
                field(shipToCity; Rec."Ship-to City")
                {
                    Caption = 'Ship-to City';
                }
                field(shipToCounty; Rec."Ship-to County")
                {
                    Caption = 'Ship-to County';
                }
                field(shipToPostalCode; Rec."Ship-to Post Code")
                {
                    Caption = 'Ship-to Postal Code';
                }
                field(shipToCountryRegionCode; Rec."Ship-to Country/Region Code")
                {
                    Caption = 'Ship-to Country/Region Code';
                }
                field(orderDate; Rec."Order Date")
                {
                    Caption = 'Order Date';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Order Date");
                    end;
                }
                field(documentDate; Rec."Document Date")
                {
                    Caption = 'Document Date';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Document Date");
                    end;
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Posting Date");
                    end;
                }
                field(requestedDeliveryDate; Rec."Requested Delivery Date")
                {
                    Caption = 'Requested Delivery Date';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Requested Delivery Date");
                    end;
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Currency Code");
                    end;
                }
                field(pricesIncludingTax; Rec."Prices Including VAT")
                {
                    Caption = 'Prices Including Tax';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Prices Including VAT");
                    end;
                }
                field(paymentTermsCode; Rec."Payment Terms Code")
                {
                    Caption = 'Payment Terms Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Payment Terms Code");
                    end;
                }
                field(paymentMethodCode; Rec."Payment Method Code")
                {
                    Caption = 'Payment Method Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Payment Method Code");
                    end;
                }
                field(shipmentMethodCode; Rec."Shipment Method Code")
                {
                    Caption = 'Shipment Method Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Shipment Method Code");
                    end;
                }
                field(shippingAgentCode; Rec."Shipping Agent Code")
                {
                    Caption = 'Shipping Agent Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Shipping Agent Code");
                    end;
                }
                field(shippingAgentServiceCode; Rec."Shipping Agent Service Code")
                {
                    Caption = 'Shipping Agent Service Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Shipping Agent Service Code");
                    end;
                }
                field(salespersonCode; Rec."Salesperson Code")
                {
                    Caption = 'Salesperson Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Salesperson Code");
                    end;
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Location Code");
                    end;
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
                field(orderNotes; Rec."WZC Order Notes")
                {
                    Caption = 'Order Notes';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
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
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                part(wizSalesOrderLines; "WZC Sales Order Line Part")
                {
                    Caption = 'Lines';
                    SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    EntityName = 'wizSalesOrderLine';
                    EntitySetName = 'wizSalesOrderLines';
                }
            }
        }
    }

    var
        OrderWriteMgt: Codeunit "WZC Order Write Mgt";

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.EnforceApiAccess('SALESORDERWRITE', 'WZC Sales Order Write API');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Document Type" := Rec."Document Type"::Order;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Existing: Record "Sales Header";
    begin
        // Search-before-create: a retried POST for a document we already created
        // returns that order instead of inserting a duplicate.
        if OrderWriteMgt.FindExistingOrderByExternalId(Rec."WZC External Id", Existing) then begin
            Rec := Existing;
            exit(false);
        end;

        Rec."Document Type" := Rec."Document Type"::Order;
        if Rec."WZC Source" = '' then
            Rec."WZC Source" := OrderWriteMgt.DefaultSource();
        Rec.Insert(true);
        OrderWriteMgt.ValidateDimensions(Rec);
        OrderWriteMgt.WriteNotesAsComments(Rec);
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        OrderWriteMgt.ValidateDimensions(Rec);
        Rec.Modify(true);
        OrderWriteMgt.WriteNotesAsComments(Rec);
        exit(false);
    end;
}
