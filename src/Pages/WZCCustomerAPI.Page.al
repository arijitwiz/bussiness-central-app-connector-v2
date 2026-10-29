page 50130 "WZC Customer API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Customer';
    EntitySetCaption = 'Wiz Customers';
    EntityName = 'wizCustomer';
    EntitySetName = 'wizCustomers';
    SourceTable = Customer;
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Unified BUYER API. Pull: $expand=wizCustomerAddresses($expand=wizShipToAttributes),wizCustomerContacts,wizCustomerDimensions,wizCustomerPrices,wizCustomerDirectPrices returns all standard and custom data in one call. Push: PATCH customFields JSON to write UDF/table-extension values back to BC. POST is idempotent on externalId. For dimension push use wizCustomerDimensionWrites endpoint.';

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
                field(displayName; BufferName)
                {
                    Caption = 'Display Name';

                    trigger OnValidate()
                    begin
                        Rec.Validate(Name, BufferName);
                    end;
                }
                field(name2; BufferName2)
                {
                    Caption = 'Name 2';

                    trigger OnValidate()
                    begin
                        Rec."Name 2" := BufferName2;
                    end;
                }
                field(address; BufferAddress)
                {
                    Caption = 'Address';

                    trigger OnValidate()
                    begin
                        Rec.Address := BufferAddress;
                    end;
                }
                field(address2; BufferAddress2)
                {
                    Caption = 'Address 2';

                    trigger OnValidate()
                    begin
                        Rec."Address 2" := BufferAddress2;
                    end;
                }
                field(city; BufferCity)
                {
                    Caption = 'City';

                    trigger OnValidate()
                    begin
                        Rec.City := BufferCity;
                    end;
                }
                field(county; BufferCounty)
                {
                    Caption = 'County/State';

                    trigger OnValidate()
                    begin
                        Rec.County := BufferCounty;
                    end;
                }
                field(postalCode; BufferPostalCode)
                {
                    Caption = 'Postal Code';

                    trigger OnValidate()
                    begin
                        Rec."Post Code" := BufferPostalCode;
                    end;
                }
                field(countryRegionCode; BufferCountry)
                {
                    Caption = 'Country/Region Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Country/Region Code", BufferCountry);
                    end;
                }
                field(phoneNo; BufferPhoneNo)
                {
                    Caption = 'Phone No.';

                    trigger OnValidate()
                    begin
                        Rec."Phone No." := BufferPhoneNo;
                    end;
                }
                field(email; BufferEmail)
                {
                    Caption = 'E-Mail';

                    trigger OnValidate()
                    begin
                        Rec.Validate("E-Mail", BufferEmail);
                    end;
                }
                field(homePage; BufferHomePage)
                {
                    Caption = 'Home Page';

                    trigger OnValidate()
                    begin
                        Rec."Home Page" := BufferHomePage;
                    end;
                }
                field(contact; BufferContact)
                {
                    Caption = 'Contact';

                    trigger OnValidate()
                    begin
                        Rec.Contact := BufferContact;
                    end;
                }
                field(customerPriceGroup; BufferCustomerPriceGroup)
                {
                    Caption = 'Customer Price Group';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Customer Price Group", BufferCustomerPriceGroup);
                    end;
                }
                field(customerDiscountGroup; BufferCustomerDiscGroup)
                {
                    Caption = 'Customer Disc. Group';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Customer Disc. Group", BufferCustomerDiscGroup);
                    end;
                }
                field(customerPostingGroup; BufferCustomerPostingGroup)
                {
                    Caption = 'Customer Posting Group';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Customer Posting Group", BufferCustomerPostingGroup);
                    end;
                }
                field(genBusPostingGroup; BufferGenBusPostingGroup)
                {
                    Caption = 'Gen. Bus. Posting Group';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Gen. Bus. Posting Group", BufferGenBusPostingGroup);
                    end;
                }
                field(paymentTermsCode; BufferPaymentTermsCode)
                {
                    Caption = 'Payment Terms Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Payment Terms Code", BufferPaymentTermsCode);
                    end;
                }
                field(paymentMethodCode; BufferPaymentMethodCode)
                {
                    Caption = 'Payment Method Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Payment Method Code", BufferPaymentMethodCode);
                    end;
                }
                field(shipmentMethodCode; BufferShipmentMethodCode)
                {
                    Caption = 'Shipment Method Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Shipment Method Code", BufferShipmentMethodCode);
                    end;
                }
                field(shippingAgentCode; BufferShippingAgentCode)
                {
                    Caption = 'Shipping Agent Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Shipping Agent Code", BufferShippingAgentCode);
                    end;
                }
                field(locationCode; BufferLocationCode)
                {
                    Caption = 'Location Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Location Code", BufferLocationCode);
                    end;
                }
                field(salespersonCode; BufferSalespersonCode)
                {
                    Caption = 'Salesperson Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Salesperson Code", BufferSalespersonCode);
                    end;
                }
                field(currencyCode; BufferCurrencyCode)
                {
                    Caption = 'Currency Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Currency Code", BufferCurrencyCode);
                    end;
                }
                field(languageCode; BufferLanguageCode)
                {
                    Caption = 'Language Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Language Code", BufferLanguageCode);
                    end;
                }
                field(taxAreaCode; BufferTaxAreaCode)
                {
                    Caption = 'Tax Area Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Tax Area Code", BufferTaxAreaCode);
                    end;
                }
                field(taxLiable; BufferTaxLiable)
                {
                    Caption = 'Tax Liable';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Tax Liable", BufferTaxLiable);
                    end;
                }
                field(pricesIncludingTax; BufferPricesIncludingTax)
                {
                    Caption = 'Prices Including Tax';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Prices Including VAT", BufferPricesIncludingTax);
                    end;
                }
                field(creditLimit; BufferCreditLimit)
                {
                    Caption = 'Credit Limit (LCY)';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Credit Limit (LCY)", BufferCreditLimit);
                    end;
                }
                field(gln; BufferGln)
                {
                    Caption = 'GLN';

                    trigger OnValidate()
                    begin
                        Rec.Validate(GLN, BufferGln);
                    end;
                }
                field(globalDimension1Code; BufferDim1)
                {
                    Caption = 'Global Dimension 1 Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Global Dimension 1 Code", BufferDim1);
                    end;
                }
                field(globalDimension2Code; BufferDim2)
                {
                    Caption = 'Global Dimension 2 Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Global Dimension 2 Code", BufferDim2);
                    end;
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                }
                field(webCustomer; Rec."WZC Web Customer")
                {
                    Caption = 'Web Customer';
                }
                field(balance; Rec."Balance (LCY)")
                {
                    Caption = 'Balance (LCY)';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                part(wizCustomerAddresses; "WZC Customer Address Part")
                {
                    Caption = 'Ship-to Addresses';
                    SubPageLink = "Customer No." = field("No.");
                    EntityName = 'wizCustomerAddress';
                    EntitySetName = 'wizCustomerAddresses';
                }
                part(wizCustomerContacts; "WZC Customer Contact Part")
                {
                    Caption = 'Contacts';
                    SubPageLink = "No." = field("No.");
                    EntityName = 'wizCustomerContact';
                    EntitySetName = 'wizCustomerContacts';
                }
                field(customFields; CustomFieldsJSON)
                {
                    Caption = 'Custom Fields';

                    trigger OnValidate()
                    begin
                        CustomFieldsChanged := true;
                    end;
                }
                part(wizCustomerDimensions; "WZC Customer Dim Part")
                {
                    Caption = 'Dimensions';
                    SubPageLink = "Table ID" = const(18), "No." = field("No.");
                    EntityName = 'wizCustomerDimension';
                    EntitySetName = 'wizCustomerDimensions';
                }
                part(wizCustomerPrices; "WZC Customer Price Part")
                {
                    Caption = 'Price Group Prices';
                    SubPageLink = "Source No." = field("Customer Price Group");
                    EntityName = 'wizCustomerPrice';
                    EntitySetName = 'wizCustomerPrices';
                }
                part(wizCustomerDirectPrices; "WZC Customer Direct Price Part")
                {
                    Caption = 'Customer Direct Prices';
                    SubPageLink = "Source No." = field("No.");
                    EntityName = 'wizCustomerDirectPrice';
                    EntitySetName = 'wizCustomerDirectPrices';
                }
            }
        }
    }

    var
        ApiBase: Codeunit "WZC Api Base";
        ApiOperationTok: Label 'CUSTOMER', Locked = true;
        BufferName: Text[100];
        BufferName2: Text[50];
        BufferAddress: Text[100];
        BufferAddress2: Text[50];
        BufferCity: Text[30];
        BufferCounty: Text[30];
        BufferPostalCode: Code[20];
        BufferCountry: Code[10];
        BufferPhoneNo: Text[30];
        BufferEmail: Text[80];
        BufferHomePage: Text[80];
        BufferContact: Text[100];
        BufferCustomerPriceGroup: Code[10];
        BufferCustomerDiscGroup: Code[20];
        BufferCustomerPostingGroup: Code[20];
        BufferGenBusPostingGroup: Code[20];
        BufferPaymentTermsCode: Code[10];
        BufferPaymentMethodCode: Code[10];
        BufferShipmentMethodCode: Code[10];
        BufferShippingAgentCode: Code[10];
        BufferLocationCode: Code[10];
        BufferSalespersonCode: Code[20];
        BufferCurrencyCode: Code[10];
        BufferLanguageCode: Code[10];
        BufferTaxAreaCode: Code[20];
        BufferTaxLiable: Boolean;
        BufferPricesIncludingTax: Boolean;
        BufferCreditLimit: Decimal;
        BufferGln: Code[13];
        BufferDim1: Code[20];
        BufferDim2: Code[20];
        CustomFieldsJSON: Text;
        CustomFieldsChanged: Boolean;

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.EnforceApiAccess(ApiOperationTok, 'WZC Customer API');
        ApiBase.ApplyPullProfileToCustomer(ApiOperationTok, Rec);
    end;

    trigger OnAfterGetRecord()
    var
        RecRef: RecordRef;
    begin
        BufferName := CopyStr(ApiBase.TextIf(ApiOperationTok, 'displayName', Rec.Name), 1, MaxStrLen(BufferName));
        BufferName2 := CopyStr(ApiBase.TextIf(ApiOperationTok, 'name2', Rec."Name 2"), 1, MaxStrLen(BufferName2));
        BufferAddress := CopyStr(ApiBase.TextIf(ApiOperationTok, 'address', Rec.Address), 1, MaxStrLen(BufferAddress));
        BufferAddress2 := CopyStr(ApiBase.TextIf(ApiOperationTok, 'address2', Rec."Address 2"), 1, MaxStrLen(BufferAddress2));
        BufferCity := CopyStr(ApiBase.TextIf(ApiOperationTok, 'city', Rec.City), 1, MaxStrLen(BufferCity));
        BufferCounty := CopyStr(ApiBase.TextIf(ApiOperationTok, 'county', Rec.County), 1, MaxStrLen(BufferCounty));
        BufferPostalCode := CopyStr(ApiBase.TextIf(ApiOperationTok, 'postalCode', Rec."Post Code"), 1, MaxStrLen(BufferPostalCode));
        BufferCountry := CopyStr(ApiBase.TextIf(ApiOperationTok, 'countryRegionCode', Rec."Country/Region Code"), 1, MaxStrLen(BufferCountry));
        BufferPhoneNo := CopyStr(ApiBase.TextIf(ApiOperationTok, 'phoneNo', Rec."Phone No."), 1, MaxStrLen(BufferPhoneNo));
        BufferEmail := CopyStr(ApiBase.TextIf(ApiOperationTok, 'email', Rec."E-Mail"), 1, MaxStrLen(BufferEmail));
        BufferHomePage := CopyStr(ApiBase.TextIf(ApiOperationTok, 'homePage', Rec."Home Page"), 1, MaxStrLen(BufferHomePage));
        BufferContact := CopyStr(ApiBase.TextIf(ApiOperationTok, 'contact', Rec.Contact), 1, MaxStrLen(BufferContact));
        BufferCustomerPriceGroup := CopyStr(ApiBase.TextIf(ApiOperationTok, 'customerPriceGroup', Rec."Customer Price Group"), 1, MaxStrLen(BufferCustomerPriceGroup));
        BufferCustomerDiscGroup := CopyStr(ApiBase.TextIf(ApiOperationTok, 'customerDiscountGroup', Rec."Customer Disc. Group"), 1, MaxStrLen(BufferCustomerDiscGroup));
        BufferCustomerPostingGroup := CopyStr(ApiBase.TextIf(ApiOperationTok, 'customerPostingGroup', Rec."Customer Posting Group"), 1, MaxStrLen(BufferCustomerPostingGroup));
        BufferGenBusPostingGroup := CopyStr(ApiBase.TextIf(ApiOperationTok, 'genBusPostingGroup', Rec."Gen. Bus. Posting Group"), 1, MaxStrLen(BufferGenBusPostingGroup));
        BufferPaymentTermsCode := CopyStr(ApiBase.TextIf(ApiOperationTok, 'paymentTermsCode', Rec."Payment Terms Code"), 1, MaxStrLen(BufferPaymentTermsCode));
        BufferPaymentMethodCode := CopyStr(ApiBase.TextIf(ApiOperationTok, 'paymentMethodCode', Rec."Payment Method Code"), 1, MaxStrLen(BufferPaymentMethodCode));
        BufferShipmentMethodCode := CopyStr(ApiBase.TextIf(ApiOperationTok, 'shipmentMethodCode', Rec."Shipment Method Code"), 1, MaxStrLen(BufferShipmentMethodCode));
        BufferShippingAgentCode := CopyStr(ApiBase.TextIf(ApiOperationTok, 'shippingAgentCode', Rec."Shipping Agent Code"), 1, MaxStrLen(BufferShippingAgentCode));
        BufferLocationCode := CopyStr(ApiBase.TextIf(ApiOperationTok, 'locationCode', Rec."Location Code"), 1, MaxStrLen(BufferLocationCode));
        BufferSalespersonCode := CopyStr(ApiBase.TextIf(ApiOperationTok, 'salespersonCode', Rec."Salesperson Code"), 1, MaxStrLen(BufferSalespersonCode));
        BufferCurrencyCode := CopyStr(ApiBase.TextIf(ApiOperationTok, 'currencyCode', Rec."Currency Code"), 1, MaxStrLen(BufferCurrencyCode));
        BufferLanguageCode := CopyStr(ApiBase.TextIf(ApiOperationTok, 'languageCode', Rec."Language Code"), 1, MaxStrLen(BufferLanguageCode));
        BufferTaxAreaCode := CopyStr(ApiBase.TextIf(ApiOperationTok, 'taxAreaCode', Rec."Tax Area Code"), 1, MaxStrLen(BufferTaxAreaCode));
        BufferTaxLiable := ApiBase.BoolIf(ApiOperationTok, 'taxLiable', Rec."Tax Liable");
        BufferPricesIncludingTax := ApiBase.BoolIf(ApiOperationTok, 'pricesIncludingTax', Rec."Prices Including VAT");
        BufferCreditLimit := ApiBase.DecIf(ApiOperationTok, 'creditLimit', Rec."Credit Limit (LCY)");
        BufferGln := CopyStr(ApiBase.TextIf(ApiOperationTok, 'gln', Rec.GLN), 1, MaxStrLen(BufferGln));
        BufferDim1 := CopyStr(ApiBase.TextIf(ApiOperationTok, 'globalDimension1Code', Rec."Global Dimension 1 Code"), 1, MaxStrLen(BufferDim1));
        BufferDim2 := CopyStr(ApiBase.TextIf(ApiOperationTok, 'globalDimension2Code', Rec."Global Dimension 2 Code"), 1, MaxStrLen(BufferDim2));

        RecRef.GetTable(Rec);
        CustomFieldsJSON := ApiBase.BuildCustomFieldsJSON(RecRef);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Existing: Record Customer;
        RecRef: RecordRef;
    begin
        if Rec."WZC External Id" <> '' then begin
            Existing.SetRange("WZC External Id", Rec."WZC External Id");
            if Existing.FindFirst() then begin
                Rec := Existing;
                exit(false);
            end;
        end;
        if CustomFieldsChanged then begin
            Rec.Insert(true);
            RecRef.GetTable(Rec);
            ApiBase.WriteCustomFieldsJSON(RecRef, CustomFieldsJSON);
            RecRef.SetTable(Rec);
            Rec.Modify(true);
            exit(false);
        end;
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        RecRef: RecordRef;
    begin
        if CustomFieldsChanged then begin
            RecRef.GetTable(Rec);
            ApiBase.WriteCustomFieldsJSON(RecRef, CustomFieldsJSON);
            RecRef.SetTable(Rec);
        end;
        Rec.Modify(true);
        exit(false);
    end;
}
