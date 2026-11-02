page 50163 "WZC Contract Product Part"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Contract Product';
    EntitySetCaption = 'Wiz Contract Products';
    EntityName = 'wizContractProduct';
    EntitySetName = 'wizContractProducts';
    SourceTable = "Price List Line";
    SourceTableView = where("Price Type" = const(Sale), "Asset Type" = const(Item));
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Sub-page of wizContractPricings ($expand=wizContractProducts). One row per price list line. pricingType is computed: "flat" when only one line exists for this SKU in the price list, "tiered" when multiple lines exist (each row becomes a volume tier). effectivePrice = unitPrice after lineDiscount. Consumer groups rows by skuId: flat rows use effectivePrice as the contract price; tiered rows use startQuantity and effectivePrice as volume tier entries.';

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
                    Caption = 'Line No';
                }
                field(skuId; Rec."Asset No.")
                {
                    Caption = 'SKU Id';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(pricingType; PricingType)
                {
                    Caption = 'Pricing Type';
                    Editable = false;
                }
                field(amountType; AmountTypeText)
                {
                    Caption = 'Amount Type';
                    Editable = false;
                }
                field(lineStatus; LineStatusText)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(startQuantity; Rec."Minimum Quantity")
                {
                    Caption = 'Start Quantity';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Unit Price';
                }
                field(unitCost; Rec."Unit Cost")
                {
                    Caption = 'Unit Cost';
                }
                field(directUnitCost; Rec."Direct Unit Cost")
                {
                    Caption = 'Direct Unit Cost';
                }
                field(costFactor; Rec."Cost Factor")
                {
                    Caption = 'Cost Factor';
                }
                field(lineDiscount; Rec."Line Discount %")
                {
                    Caption = 'Line Discount';
                }
                field(effectivePrice; EffectivePrice)
                {
                    Caption = 'Effective Price';
                    Editable = false;
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit Of Measure Code';
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                }
                field(allowLineDiscount; Rec."Allow Line Disc.")
                {
                    Caption = 'Allow Line Discount';
                }
                field(allowInvoiceDiscount; Rec."Allow Invoice Disc.")
                {
                    Caption = 'Allow Invoice Discount';
                }
                field(priceIncludesTax; Rec."Price Includes VAT")
                {
                    Caption = 'Price Includes Tax';
                }
                field(vatBusPostingGroup; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    Caption = 'VAT Bus Posting Group';
                }
                field(vatProdPostingGroup; Rec."VAT Prod. Posting Group")
                {
                    Caption = 'VAT Prod Posting Group';
                }
                field(lineStartingDate; LineStartingDate)
                {
                    Caption = 'Starting Date';
                    Editable = false;
                }
                field(lineEndingDate; LineEndingDate)
                {
                    Caption = 'Ending Date';
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

    var
        PricingType: Text[10];
        EffectivePrice: Decimal;
        AmountTypeText: Text[20];
        LineStatusText: Text[20];
        LineStartingDate: Text[30];
        LineEndingDate: Text[30];

    trigger OnAfterGetRecord()
    begin
        PricingType := DeterminePricingType();
        EffectivePrice := CalcEffectivePrice();
        AmountTypeText := MapAmountType();
        LineStatusText := MapLineStatus();
        LineStartingDate := FormatDateISO(Rec."Starting Date");
        LineEndingDate := FormatDateISO(Rec."Ending Date");
    end;

    local procedure DeterminePricingType(): Text[10]
    var
        PriceListLine: Record "Price List Line";
        LineCount: Integer;
    begin
        PriceListLine.SetRange("Price List Code", Rec."Price List Code");
        PriceListLine.SetRange("Asset No.", Rec."Asset No.");
        PriceListLine.SetRange("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
        LineCount := PriceListLine.Count();
        if LineCount <= 1 then
            exit('flat');
        exit('tiered');
    end;

    local procedure CalcEffectivePrice(): Decimal
    var
        Price: Decimal;
        DiscountPct: Decimal;
    begin
        Price := Rec."Unit Price";
        DiscountPct := Rec."Line Discount %";
        if DiscountPct > 0 then
            Price := Round(Price * (1 - DiscountPct / 100), 0.0001);
        if Price < 0.01 then
            Price := 0.01;
        exit(Price);
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

    local procedure MapLineStatus(): Text[20]
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
}
