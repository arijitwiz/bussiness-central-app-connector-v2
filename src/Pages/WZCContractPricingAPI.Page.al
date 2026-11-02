page 50162 "WZC Contract Pricing API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Contract Pricing';
    EntitySetCaption = 'Wiz Contract Pricings';
    EntityName = 'wizContractPricing';
    EntitySetName = 'wizContractPricings';
    SourceTable = "Price List Header";
    SourceTableView = where("Price Type" = const(Sale));
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Unified contract pricing API. GET $expand=wizContractProducts returns each price list with its product lines in one call. Fields map to the integration contract structure: referenceId, name, status, customerGroupType/customerGroupIds (resolved from all 6 BC assignment types), scheduleStartDate/scheduleEndDate. Products carry pricingType (flat/tiered) and effectivePrice (after discount).';

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
                field(referenceId; Rec.Code)
                {
                    Caption = 'Reference Id';
                }
                field(name; ContractName)
                {
                    Caption = 'Name';
                    Editable = false;
                }
                field(status; ContractStatus)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(customerGroupType; CustomerGroupType)
                {
                    Caption = 'Customer Group Type';
                    Editable = false;
                }
                field(customerGroupIds; CustomerGroupIds)
                {
                    Caption = 'Customer Group Ids';
                    Editable = false;
                }
                field(sourceType; SourceTypeText)
                {
                    Caption = 'Source Type';
                    Editable = false;
                }
                field(sourceNo; Rec."Source No.")
                {
                    Caption = 'Source No';
                }
                field(parentSourceNo; Rec."Parent Source No.")
                {
                    Caption = 'Parent Source No';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(amountType; AmountTypeText)
                {
                    Caption = 'Amount Type';
                    Editable = false;
                }
                field(allowUpdatingDefaults; Rec."Allow Updating Defaults")
                {
                    Caption = 'Allow Updating Defaults';
                }
                field(allowLineDiscount; Rec."Allow Line Disc.")
                {
                    Caption = 'Allow Line Discount';
                }
                field(allowInvoiceDiscount; Rec."Allow Invoice Disc.")
                {
                    Caption = 'Allow Invoice Discount';
                }
                field(priceIncludesVat; Rec."Price Includes VAT")
                {
                    Caption = 'Price Includes VAT';
                }
                field(vatBusPostingGroup; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    Caption = 'VAT Bus Posting Group';
                }
                field(scheduleStartDate; ScheduleStartDate)
                {
                    Caption = 'Schedule Start Date';
                    Editable = false;
                }
                field(scheduleEndDate; ScheduleEndDate)
                {
                    Caption = 'Schedule End Date';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                part(wizContractProducts; "WZC Contract Product Part")
                {
                    Caption = 'Products';
                    EntityName = 'wizContractProduct';
                    EntitySetName = 'wizContractProducts';
                    SubPageLink = "Price List Code" = field(Code);
                }
            }
        }
    }

    var
        ContractName: Text[250];
        ContractStatus: Text[20];
        CustomerGroupType: Text[20];
        CustomerGroupIds: Text[2048];
        SourceTypeText: Text[30];
        AmountTypeText: Text[20];
        ScheduleStartDate: Text[30];
        ScheduleEndDate: Text[30];

    trigger OnAfterGetRecord()
    begin
        ContractName := BuildContractName();
        ContractStatus := MapStatus();
        CustomerGroupType := MapCustomerGroupType();
        CustomerGroupIds := ResolveCustomerList();
        SourceTypeText := MapSourceType();
        AmountTypeText := MapAmountType();
        ScheduleStartDate := FormatDateISO(Rec."Starting Date");
        ScheduleEndDate := FormatDateISO(Rec."Ending Date");
    end;

    local procedure BuildContractName(): Text[250]
    begin
        if Rec.Description <> '' then
            exit(Rec.Description);
        exit(Rec.Code);
    end;

    local procedure MapStatus(): Text[20]
    begin
        case Rec.Status of
            Rec.Status::Active:
                exit('active');
            Rec.Status::Draft:
                exit('draft');
            Rec.Status::Inactive:
                exit('inactive');
            else
                exit('draft');
        end;
    end;

    local procedure FormatDateISO(DateValue: Date): Text[30]
    begin
        if DateValue = 0D then
            exit('');
        exit(Format(DateValue, 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00Z');
    end;

    local procedure MapSourceType(): Text[30]
    begin
        case Rec."Source Type" of
            Rec."Source Type"::"All Customers":
                exit('All Customers');
            Rec."Source Type"::Customer:
                exit('Customer');
            Rec."Source Type"::Contact:
                exit('Contact');
            Rec."Source Type"::Campaign:
                exit('Campaign');
            Rec."Source Type"::"Customer Price Group":
                exit('Customer Price Group');
            Rec."Source Type"::"Customer Disc. Group":
                exit('Customer Disc. Group');
            else
                exit(Format(Rec."Source Type"));
        end;
    end;

    local procedure MapAmountType(): Text[20]
    begin
        case Rec."Amount Type" of
            Rec."Amount Type"::Price:
                exit('Price');
            Rec."Amount Type"::Discount:
                exit('Discount');
            else
                exit(Format(Rec."Amount Type"));
        end;
    end;

    local procedure MapCustomerGroupType(): Text[20]
    begin
        case Rec."Source Type" of
            Rec."Source Type"::"All Customers":
                exit('all');
            else
                exit('customer');
        end;
    end;

    local procedure ResolveCustomerList(): Text[2048]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        SegmentLine: Record "Segment Line";
        CustomerRec: Record Customer;
        PriceListLine: Record "Price List Line";
        ProcessedContacts: Text[2048];
        Result: Text[2048];
    begin
        case Rec."Source Type" of
            Rec."Source Type"::"All Customers":
                exit('');

            Rec."Source Type"::Customer:
                exit(Rec."Source No.");

            Rec."Source Type"::Contact:
                begin
                    // Resolve header-level contact
                    ContactBusinessRelation.SetRange("Contact No.", Rec."Source No.");
                    ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
                    if ContactBusinessRelation.FindSet() then
                        repeat
                            if StrPos(',' + Result + ',', ',' + ContactBusinessRelation."No." + ',') = 0 then begin
                                if Result <> '' then
                                    Result += ',';
                                Result += ContactBusinessRelation."No.";
                            end;
                        until ContactBusinessRelation.Next() = 0;

                    // Also resolve line-level contact overrides
                    PriceListLine.SetRange("Price List Code", Rec.Code);
                    PriceListLine.SetRange("Price Type", PriceListLine."Price Type"::Sale);
                    PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
                    if PriceListLine.FindSet() then
                        repeat
                            if (PriceListLine."Assign-to No." <> '') and
                               (PriceListLine."Assign-to No." <> Rec."Source No.") and
                               (StrPos(',' + ProcessedContacts + ',', ',' + PriceListLine."Assign-to No." + ',') = 0)
                            then begin
                                if ProcessedContacts <> '' then
                                    ProcessedContacts += ',';
                                ProcessedContacts += PriceListLine."Assign-to No.";

                                ContactBusinessRelation.Reset();
                                ContactBusinessRelation.SetRange("Contact No.", PriceListLine."Assign-to No.");
                                ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
                                if ContactBusinessRelation.FindSet() then
                                    repeat
                                        if StrPos(',' + Result + ',', ',' + ContactBusinessRelation."No." + ',') = 0 then begin
                                            if Result <> '' then
                                                Result += ',';
                                            Result += ContactBusinessRelation."No.";
                                        end;
                                    until ContactBusinessRelation.Next() = 0;
                            end;
                        until PriceListLine.Next() = 0;
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
