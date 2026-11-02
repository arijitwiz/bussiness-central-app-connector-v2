page 50158 "WZC Price List Header API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Price List Header';
    EntitySetCaption = 'Wiz Price List Headers';
    EntityName = 'wizPriceListHeader';
    EntitySetName = 'wizPriceListHeaders';
    SourceTable = "Price List Header";
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
                field(code; Rec.Code)
                {
                    Caption = 'Price List Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(sourceType; Rec."Source Type")
                {
                    Caption = 'Assign-to Type';
                }
                field(sourceNo; Rec."Source No.")
                {
                    Caption = 'Assign-to No.';
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
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(startingDate; Rec."Starting Date")
                {
                    Caption = 'Starting Date';
                }
                field(endingDate; Rec."Ending Date")
                {
                    Caption = 'Ending Date';
                }
                field(allowLineDisc; Rec."Allow Line Disc.")
                {
                    Caption = 'Allow Line Discount';
                }
                field(allowInvoiceDisc; Rec."Allow Invoice Disc.")
                {
                    Caption = 'Allow Invoice Discount';
                }
                field(priceIncludesVAT; Rec."Price Includes VAT")
                {
                    Caption = 'Price Includes VAT';
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
