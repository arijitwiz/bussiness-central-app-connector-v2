page 50139 "WZC Sales Order API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Sales Order';
    EntitySetCaption = 'Wiz Sales Orders';
    EntityName = 'wizSalesOrder';
    EntitySetName = 'wizSalesOrders';
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = const(Order));
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Unified ORDER read API (pull). Use $expand=wizSalesOrderLines,wizSalesOrderDimensions,wizSalesOrderAttributes to pull lines, dimension set, and tenant-defined order attributes in one call. Fields are tenant-gated through WZC Field Visibility (Api Operation = SALESORDER).';

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
                }
                field(customerName; Rec."Sell-to Customer Name")
                {
                    Caption = 'Customer Name';
                }
                field(billToCustomerNumber; Rec."Bill-to Customer No.")
                {
                    Caption = 'Bill-to Customer Number';
                }
                field(billToName; Rec."Bill-to Name")
                {
                    Caption = 'Bill-to Name';
                }
                field(shipToCode; Rec."Ship-to Code")
                {
                    Caption = 'Ship-to Code';
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
                }
                field(documentDate; Rec."Document Date")
                {
                    Caption = 'Document Date';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(requestedDeliveryDate; Rec."Requested Delivery Date")
                {
                    Caption = 'Requested Delivery Date';
                }
                field(promisedDeliveryDate; Rec."Promised Delivery Date")
                {
                    Caption = 'Promised Delivery Date';
                }
                field(shipmentDate; Rec."Shipment Date")
                {
                    Caption = 'Shipment Date';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(pricesIncludingTax; Rec."Prices Including VAT")
                {
                    Caption = 'Prices Including Tax';
                }
                field(paymentTermsCode; Rec."Payment Terms Code")
                {
                    Caption = 'Payment Terms Code';
                }
                field(paymentMethodCode; Rec."Payment Method Code")
                {
                    Caption = 'Payment Method Code';
                }
                field(shipmentMethodCode; Rec."Shipment Method Code")
                {
                    Caption = 'Shipment Method Code';
                }
                field(shippingAgentCode; Rec."Shipping Agent Code")
                {
                    Caption = 'Shipping Agent Code';
                }
                field(shippingAgentServiceCode; Rec."Shipping Agent Service Code")
                {
                    Caption = 'Shipping Agent Service Code';
                }
                field(packageTrackingNo; Rec."Package Tracking No.")
                {
                    Caption = 'Package Tracking No.';
                }
                field(salespersonCode; Rec."Salesperson Code")
                {
                    Caption = 'Salesperson Code';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(customerPriceGroup; Rec."Customer Price Group")
                {
                    Caption = 'Customer Price Group';
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(dimensionSetId; Rec."Dimension Set ID")
                {
                    Caption = 'Dimension Set ID';
                }
                field(orderNotes; Rec."WZC Order Notes")
                {
                    Caption = 'Order Notes';
                }
                field(completelyShipped; Rec."Completely Shipped")
                {
                    Caption = 'Completely Shipped';
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
                part(wizSalesOrderDimensions; "WZC Order Dimension Part")
                {
                    Caption = 'Dimensions';
                    SubPageLink = "Dimension Set ID" = field("Dimension Set ID");
                    EntityName = 'wizSalesOrderDimension';
                    EntitySetName = 'wizSalesOrderDimensions';
                }
                part(wizSalesOrderAttributes; "WZC Order Attr Part")
                {
                    Caption = 'Custom Attributes';
                    SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    EntityName = 'wizSalesOrderAttribute';
                    EntitySetName = 'wizSalesOrderAttributes';
                }
            }
        }
    }

    var
        ApiBase: Codeunit "WZC Api Base";
        FieldMap: Dictionary of [Code[50], Integer];
        ApiOperationTok: Label 'SALESORDER', Locked = true;

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.EnforceApiAccess(ApiOperationTok, 'WZC Sales Order API');
        BuildFieldMap();
    end;

    trigger OnAfterGetRecord()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        ApiBase.BlankHiddenFields(ApiOperationTok, RecRef, FieldMap);
        RecRef.SetTable(Rec);
    end;

    local procedure BuildFieldMap()
    begin
        Clear(FieldMap);
        FieldMap.Add('externalDocumentNumber', Rec.FieldNo("External Document No."));
        FieldMap.Add('yourReference', Rec.FieldNo("Your Reference"));
        FieldMap.Add('customerName', Rec.FieldNo("Sell-to Customer Name"));
        FieldMap.Add('billToName', Rec.FieldNo("Bill-to Name"));
        FieldMap.Add('shipToName', Rec.FieldNo("Ship-to Name"));
        FieldMap.Add('shipToAddress', Rec.FieldNo("Ship-to Address"));
        FieldMap.Add('shipToAddress2', Rec.FieldNo("Ship-to Address 2"));
        FieldMap.Add('shipToCity', Rec.FieldNo("Ship-to City"));
        FieldMap.Add('shipToCounty', Rec.FieldNo("Ship-to County"));
        FieldMap.Add('shipToPostalCode', Rec.FieldNo("Ship-to Post Code"));
        FieldMap.Add('shipToCountryRegionCode', Rec.FieldNo("Ship-to Country/Region Code"));
        FieldMap.Add('promisedDeliveryDate', Rec.FieldNo("Promised Delivery Date"));
        FieldMap.Add('paymentTermsCode', Rec.FieldNo("Payment Terms Code"));
        FieldMap.Add('paymentMethodCode', Rec.FieldNo("Payment Method Code"));
        FieldMap.Add('shipmentMethodCode', Rec.FieldNo("Shipment Method Code"));
        FieldMap.Add('shippingAgentCode', Rec.FieldNo("Shipping Agent Code"));
        FieldMap.Add('shippingAgentServiceCode', Rec.FieldNo("Shipping Agent Service Code"));
        FieldMap.Add('packageTrackingNo', Rec.FieldNo("Package Tracking No."));
        FieldMap.Add('salespersonCode', Rec.FieldNo("Salesperson Code"));
        FieldMap.Add('locationCode', Rec.FieldNo("Location Code"));
        FieldMap.Add('customerPriceGroup', Rec.FieldNo("Customer Price Group"));
        FieldMap.Add('shortcutDimension1Code', Rec.FieldNo("Shortcut Dimension 1 Code"));
        FieldMap.Add('shortcutDimension2Code', Rec.FieldNo("Shortcut Dimension 2 Code"));
        FieldMap.Add('orderNotes', Rec.FieldNo("WZC Order Notes"));
    end;
}
