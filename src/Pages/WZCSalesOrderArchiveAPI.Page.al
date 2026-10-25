page 50143 "WZC Sales Order Archive API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Sales Order Archive';
    EntitySetCaption = 'Wiz Sales Order Archives';
    EntityName = 'wizSalesOrderArchive';
    EntitySetName = 'wizSalesOrderArchives';
    SourceTable = "Sales Header Archive";
    SourceTableView = where("Document Type" = const(Order));
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Archived sales orders with lines ($expand=wizSalesOrderArchiveLines). Replaces per-tenant salesorderExpandArchiveLatest: filter isLatestVersion eq true for the newest archived version of each order.';

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
                field(docNoOccurrence; Rec."Doc. No. Occurrence")
                {
                    Caption = 'Doc. No. Occurrence';
                }
                field(versionNo; Rec."Version No.")
                {
                    Caption = 'Version No.';
                }
                field(isLatestVersion; IsLatestVersion)
                {
                    Caption = 'Is Latest Version';
                    Editable = false;
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
                field(shipToCode; Rec."Ship-to Code")
                {
                    Caption = 'Ship-to Code';
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
                field(paymentTermsCode; Rec."Payment Terms Code")
                {
                    Caption = 'Payment Terms Code';
                }
                field(shipmentMethodCode; Rec."Shipment Method Code")
                {
                    Caption = 'Shipment Method Code';
                }
                field(salespersonCode; Rec."Salesperson Code")
                {
                    Caption = 'Salesperson Code';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(dateArchived; Rec."Date Archived")
                {
                    Caption = 'Date Archived';
                }
                field(timeArchived; Rec."Time Archived")
                {
                    Caption = 'Time Archived';
                }
                field(archivedBy; Rec."Archived By")
                {
                    Caption = 'Archived By';
                }
                field(sourceDocExists; Rec."Source Doc. Exists")
                {
                    Caption = 'Source Doc. Exists';
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
                part(wizSalesOrderArchiveLines; "WZC Sales Order Arch Line Part")
                {
                    Caption = 'Lines';
                    SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No."), "Doc. No. Occurrence" = field("Doc. No. Occurrence"), "Version No." = field("Version No.");
                    EntityName = 'wizSalesOrderArchiveLine';
                    EntitySetName = 'wizSalesOrderArchiveLines';
                }
            }
        }
    }

    var
        IsLatestVersion: Boolean;

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.EnforceApiAccess('SALESORDERARCH', 'WZC Sales Order Archive API');
    end;

    trigger OnAfterGetRecord()
    var
        Latest: Record "Sales Header Archive";
    begin
        Latest.SetRange("Document Type", Rec."Document Type");
        Latest.SetRange("No.", Rec."No.");
        Latest.SetRange("Doc. No. Occurrence", Rec."Doc. No. Occurrence");
        if Latest.FindLast() then
            IsLatestVersion := Latest."Version No." = Rec."Version No."
        else
            IsLatestVersion := true;
    end;
}
