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
    AboutText = 'Unified contract pricing API. GET $expand=wizContractProducts returns each price list with its product lines in one call. Fields map to the integration contract structure: referenceId, name, status, customerGroupType/customerGroupIds (resolved from all 6 BC assignment types; customerGroupIds is an unbounded Text field with no practical limit for any real customer base). Products carry pricingType (flat/tiered) and effectivePrice (after discount).';

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
                field(status; Rec.Status)
                {
                    Caption = 'Status';
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
                field(scheduleStartDate; Rec."Starting Date")
                {
                    Caption = 'Schedule Start Date';
                }
                field(scheduleEndDate; Rec."Ending Date")
                {
                    Caption = 'Schedule End Date';
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
        CustomerGroupType: Text[20];
        CustomerGroupIds: Text;
        SourceTypeText: Text[30];
        AmountTypeText: Text[20];

    trigger OnAfterGetRecord()
    begin
        ContractName := BuildContractName();
        CustomerGroupType := MapCustomerGroupType();
        CustomerGroupIds := ResolveCustomerList();
        SourceTypeText := MapSourceType();
        AmountTypeText := MapAmountType();
    end;

    local procedure BuildContractName(): Text[250]
    begin
        if Rec.Description <> '' then
            exit(Rec.Description);
        exit(Rec.Code);
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

    /// <summary>
    /// Resolves all 6 BC assignment types to a deduped, comma-separated list of Customer numbers.
    /// Returns an unbounded Text so resolution can never overflow, regardless of group size.
    /// </summary>
    local procedure ResolveCustomerList(): Text
    var
        SegmentLine: Record "Segment Line";
        CustomerRec: Record Customer;
        PriceListLine: Record "Price List Line";
        SeenCustomers: Dictionary of [Code[20], Boolean];
        SeenContacts: Dictionary of [Code[20], Boolean];
        ResultBuilder: TextBuilder;
    begin
        case Rec."Source Type" of
            Rec."Source Type"::"All Customers":
                exit('');

            Rec."Source Type"::Customer:
                exit(Rec."Source No.");

            Rec."Source Type"::Contact:
                begin
                    // Header-level contact: every linked customer counts
                    AddAllCustomersForContact(Rec."Source No.", SeenCustomers, ResultBuilder);

                    // Line-level contact overrides
                    PriceListLine.SetRange("Price List Code", Rec.Code);
                    PriceListLine.SetRange("Price Type", PriceListLine."Price Type"::Sale);
                    PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
                    if PriceListLine.FindSet() then
                        repeat
                            if (PriceListLine."Assign-to No." <> '') and
                               (PriceListLine."Assign-to No." <> Rec."Source No.") and
                               not SeenContacts.ContainsKey(PriceListLine."Assign-to No.")
                            then begin
                                SeenContacts.Add(PriceListLine."Assign-to No.", true);
                                AddAllCustomersForContact(PriceListLine."Assign-to No.", SeenCustomers, ResultBuilder);
                            end;
                        until PriceListLine.Next() = 0;
                    exit(ResultBuilder.ToText());
                end;

            Rec."Source Type"::Campaign:
                begin
                    SegmentLine.SetRange("Campaign No.", Rec."Source No.");
                    if SegmentLine.FindSet() then
                        repeat
                            // Matches original behavior: first linked customer per enrolled contact
                            AddFirstCustomerForContact(SegmentLine."Contact No.", SeenCustomers, ResultBuilder);
                        until SegmentLine.Next() = 0;
                    exit(ResultBuilder.ToText());
                end;

            Rec."Source Type"::"Customer Price Group":
                begin
                    CustomerRec.SetRange("Customer Price Group", Rec."Source No.");
                    if CustomerRec.FindSet() then
                        repeat
                            AppendCustomer(CustomerRec."No.", SeenCustomers, ResultBuilder);
                        until CustomerRec.Next() = 0;
                    exit(ResultBuilder.ToText());
                end;

            Rec."Source Type"::"Customer Disc. Group":
                begin
                    CustomerRec.SetRange("Customer Disc. Group", Rec."Source No.");
                    if CustomerRec.FindSet() then
                        repeat
                            AppendCustomer(CustomerRec."No.", SeenCustomers, ResultBuilder);
                        until CustomerRec.Next() = 0;
                    exit(ResultBuilder.ToText());
                end;

            else
                exit('');
        end;
    end;

    local procedure AddAllCustomersForContact(ContactNo: Code[20]; var SeenCustomers: Dictionary of [Code[20], Boolean]; var ResultBuilder: TextBuilder)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        if ContactBusinessRelation.FindSet() then
            repeat
                AppendCustomer(ContactBusinessRelation."No.", SeenCustomers, ResultBuilder);
            until ContactBusinessRelation.Next() = 0;
    end;

    local procedure AddFirstCustomerForContact(ContactNo: Code[20]; var SeenCustomers: Dictionary of [Code[20], Boolean]; var ResultBuilder: TextBuilder)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        if ContactBusinessRelation.FindFirst() then
            AppendCustomer(ContactBusinessRelation."No.", SeenCustomers, ResultBuilder);
    end;

    local procedure AppendCustomer(CustomerNo: Code[20]; var SeenCustomers: Dictionary of [Code[20], Boolean]; var ResultBuilder: TextBuilder)
    begin
        if SeenCustomers.ContainsKey(CustomerNo) then
            exit;
        SeenCustomers.Add(CustomerNo, true);
        if ResultBuilder.Length() > 0 then
            ResultBuilder.Append(',');
        ResultBuilder.Append(CustomerNo);
    end;

}
