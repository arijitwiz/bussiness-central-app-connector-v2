page 50159 "WZC Price List Line API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Price List Line';
    EntitySetCaption = 'Wiz Price List Lines';
    EntityName = 'wizPriceListLine';
    EntitySetName = 'wizPriceListLines';
    SourceTable = "Price List Line";
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

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
                field(sourceType; Rec."Source Type")
                {
                    Caption = 'Assign-to Type';
                }
                field(sourceNo; Rec."Source No.")
                {
                    Caption = 'Assign-to No.';
                }
                field(assignToParentNo; Rec."Assign-to Parent No.")
                {
                    Caption = 'Assign-to Parent No.';
                }
                field(customerNo; CustomerNo)
                {
                    Caption = 'Customer No.';
                    Editable = false;
                }
                field(customerList; CustomerList)
                {
                    Caption = 'Customer List';
                    Editable = false;
                }
                field(assetType; Rec."Asset Type")
                {
                    Caption = 'Product Type';
                }
                field(assetNo; Rec."Asset No.")
                {
                    Caption = 'Product No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }
                field(minimumQuantity; Rec."Minimum Quantity")
                {
                    Caption = 'Minimum Quantity';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Unit Price';
                }
                field(allowLineDisc; Rec."Allow Line Disc.")
                {
                    Caption = 'Allow Line Discount';
                }
                field(lineDiscount; Rec."Line Discount %")
                {
                    Caption = 'Line Discount %';
                }
                field(allowInvoiceDisc; Rec."Allow Invoice Disc.")
                {
                    Caption = 'Allow Invoice Discount';
                }
                field(priceIncludesVAT; Rec."Price Includes VAT")
                {
                    Caption = 'Price Includes VAT';
                }
                field(startingDate; Rec."Starting Date")
                {
                    Caption = 'Starting Date';
                }
                field(endingDate; Rec."Ending Date")
                {
                    Caption = 'Ending Date';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
            }
        }
    }

    var
        CustomerNo: Code[20];
        CustomerList: Text[2048];

    trigger OnAfterGetRecord()
    begin
        CustomerNo := ResolveCustomerNo();
        CustomerList := ResolveCustomerList();
    end;

    local procedure ResolveCustomerNo(): Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        SegmentLine: Record "Segment Line";
    begin
        case Rec."Source Type" of
            Rec."Source Type"::Customer:
                exit(Rec."Source No.");
            Rec."Source Type"::Contact:
                begin
                    ContactBusinessRelation.SetRange("Contact No.", Rec."Source No.");
                    ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
                    if ContactBusinessRelation.FindFirst() then
                        exit(ContactBusinessRelation."No.");
                    exit('');
                end;
            Rec."Source Type"::Campaign:
                begin
                    SegmentLine.SetRange("Campaign No.", Rec."Source No.");
                    if SegmentLine.FindFirst() then begin
                        ContactBusinessRelation.SetRange("Contact No.", SegmentLine."Contact No.");
                        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
                        if ContactBusinessRelation.FindFirst() then
                            exit(ContactBusinessRelation."No.");
                    end;
                    exit('');
                end;
            else
                exit('');
        end;
    end;

    local procedure ResolveCustomerList(): Text[2048]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        SegmentLine: Record "Segment Line";
        CustomerRec: Record Customer;
        Result: Text[2048];
    begin
        case Rec."Source Type" of
            Rec."Source Type"::Customer:
                exit(Rec."Source No.");
            Rec."Source Type"::"All Customers":
                exit('*');
            Rec."Source Type"::Contact:
                begin
                    ContactBusinessRelation.SetRange("Contact No.", Rec."Source No.");
                    ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
                    if ContactBusinessRelation.FindSet() then
                        repeat
                            if Result <> '' then
                                Result += ',';
                            Result += ContactBusinessRelation."No.";
                        until ContactBusinessRelation.Next() = 0;
                    exit(Result);
                end;
            Rec."Source Type"::Campaign:
                begin
                    SegmentLine.SetRange("Campaign No.", Rec."Source No.");
                    if SegmentLine.FindSet() then
                        repeat
                            ContactBusinessRelation.Reset();
                            ContactBusinessRelation.SetRange("Contact No.", SegmentLine."Contact No.");
                            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
                            if ContactBusinessRelation.FindFirst() then
                                if StrPos(',' + Result + ',', ',' + ContactBusinessRelation."No." + ',') = 0 then begin
                                    if Result <> '' then
                                        Result += ',';
                                    Result += ContactBusinessRelation."No.";
                                end;
                        until SegmentLine.Next() = 0;
                    exit(Result);
                end;
            Rec."Source Type"::"Customer Price Group":
                begin
                    CustomerRec.SetRange("Customer Price Group", Rec."Source No.");
                    if CustomerRec.FindSet() then
                        repeat
                            if Result <> '' then
                                Result += ',';
                            Result += CustomerRec."No.";
                        until CustomerRec.Next() = 0;
                    exit(Result);
                end;
            Rec."Source Type"::"Customer Disc. Group":
                begin
                    CustomerRec.SetRange("Customer Disc. Group", Rec."Source No.");
                    if CustomerRec.FindSet() then
                        repeat
                            if Result <> '' then
                                Result += ',';
                            Result += CustomerRec."No.";
                        until CustomerRec.Next() = 0;
                    exit(Result);
                end;
            else
                exit('');
        end;
    end;
}
