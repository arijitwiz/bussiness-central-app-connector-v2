page 50100 "WZC Ship-to Address API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v1.0';
    EntityName = 'wizShipToAddress';
    EntitySetName = 'wizShipToAddresses';
    SourceTable = "Ship-to Address";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Ship-to Address. Every field below except id/customerNumber/code/lastModifiedDateTime is tenant-configurable via WZC Field Visibility (Api Operation = SHIPTOADDR) - a tenant with no configuration sees every field (code default); a tenant with any configured rows sees only the fields explicitly marked Visible. Values are pulled live from the real Ship-to Address record - nothing to type in manually.';

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
                field(customerNumber; Rec."Customer No.")
                {
                    Caption = 'Customer Number';
                }
                field(code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(name; BufferName)
                {
                    Caption = 'Name';

                    trigger OnValidate()
                    begin
                        Rec.Name := BufferName;
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
                field(contact; BufferContact)
                {
                    Caption = 'Contact';

                    trigger OnValidate()
                    begin
                        Rec.Contact := BufferContact;
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
                field(faxNo; BufferFaxNo)
                {
                    Caption = 'Fax No.';

                    trigger OnValidate()
                    begin
                        Rec."Fax No." := BufferFaxNo;
                    end;
                }
                field(email; BufferEmail)
                {
                    Caption = 'E-Mail';

                    trigger OnValidate()
                    begin
                        Rec."E-Mail" := BufferEmail;
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
                field(postalCode; BufferPostalCode)
                {
                    Caption = 'Postal Code';

                    trigger OnValidate()
                    begin
                        Rec."Post Code" := BufferPostalCode;
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
                field(country; BufferCountry)
                {
                    Caption = 'Country/Region Code';

                    trigger OnValidate()
                    begin
                        Rec."Country/Region Code" := BufferCountry;
                    end;
                }
                field(locationCode; BufferLocationCode)
                {
                    Caption = 'Location Code';

                    trigger OnValidate()
                    begin
                        Rec."Location Code" := BufferLocationCode;
                    end;
                }
                field(shipmentMethodCode; BufferShipmentMethodCode)
                {
                    Caption = 'Shipment Method Code';

                    trigger OnValidate()
                    begin
                        Rec."Shipment Method Code" := BufferShipmentMethodCode;
                    end;
                }
                field(shippingAgentCode; BufferShippingAgentCode)
                {
                    Caption = 'Shipping Agent Code';

                    trigger OnValidate()
                    begin
                        Rec."Shipping Agent Code" := BufferShippingAgentCode;
                    end;
                }
                field(shippingAgentServiceCode; BufferShippingAgentServiceCode)
                {
                    Caption = 'Shipping Agent Service Code';

                    trigger OnValidate()
                    begin
                        Rec."Shipping Agent Service Code" := BufferShippingAgentServiceCode;
                    end;
                }
                field(gln; BufferGln)
                {
                    Caption = 'GLN';

                    trigger OnValidate()
                    begin
                        Rec.GLN := BufferGln;
                    end;
                }
                field(taxAreaCode; BufferTaxAreaCode)
                {
                    Caption = 'Tax Area Code';

                    trigger OnValidate()
                    begin
                        Rec."Tax Area Code" := BufferTaxAreaCode;
                    end;
                }
                field(taxLiable; BufferTaxLiable)
                {
                    Caption = 'Tax Liable';

                    trigger OnValidate()
                    begin
                        Rec."Tax Liable" := BufferTaxLiable;
                    end;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                part(shipToAttributes; "WZC Ship-to Attr Part")
                {
                    Caption = 'Attributes';
                    SubPageLink = "Customer No." = field("Customer No."), "Ship-to Code" = field(Code);
                    EntityName = 'shipToAttribute';
                    EntitySetName = 'shipToAttributes';
                }
            }
        }
    }

    var
        BufferName: Text[100];
        BufferName2: Text[50];
        BufferAddress: Text[100];
        BufferAddress2: Text[50];
        BufferCity: Text[30];
        BufferContact: Text[100];
        BufferPhoneNo: Text[30];
        BufferFaxNo: Text[30];
        BufferEmail: Text[80];
        BufferHomePage: Text[80];
        BufferPostalCode: Code[20];
        BufferCounty: Text[30];
        BufferCountry: Code[10];
        BufferLocationCode: Code[10];
        BufferShipmentMethodCode: Code[10];
        BufferShippingAgentCode: Code[10];
        BufferShippingAgentServiceCode: Code[10];
        BufferGln: Code[13];
        BufferTaxAreaCode: Code[20];
        BufferTaxLiable: Boolean;

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
        SyncProfile: Record "WZC Sync Profile";
        FilterEngine: Codeunit "WZC Sync Filter Engine";
    begin
        SetupMgt.EnforceApiAccess('SHIPTOADDR', 'WZC Ship-to Address API');

        SyncProfile.SetRange("Api Operation", 'SHIPTOADDR');
        SyncProfile.SetRange(Enabled, true);
        SyncProfile.SetRange(Direction, SyncProfile.Direction::Pull);
        if SyncProfile.IsEmpty() then
            SyncProfile.SetRange(Direction, SyncProfile.Direction::Both);
        if SyncProfile.FindFirst() then
            FilterEngine.ApplyProfileToShipToAddress(SyncProfile, 0DT, 0DT, Rec);
    end;

    trigger OnAfterGetRecord()
    var
        FieldVisibility: Codeunit "WZC Field Visibility Mgt";
    begin
        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'name') then
            BufferName := Rec.Name
        else
            BufferName := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'name2') then
            BufferName2 := Rec."Name 2"
        else
            BufferName2 := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'address') then
            BufferAddress := Rec.Address
        else
            BufferAddress := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'address2') then
            BufferAddress2 := Rec."Address 2"
        else
            BufferAddress2 := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'city') then
            BufferCity := Rec.City
        else
            BufferCity := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'contact') then
            BufferContact := Rec.Contact
        else
            BufferContact := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'phoneNo') then
            BufferPhoneNo := Rec."Phone No."
        else
            BufferPhoneNo := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'faxNo') then
            BufferFaxNo := Rec."Fax No."
        else
            BufferFaxNo := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'email') then
            BufferEmail := Rec."E-Mail"
        else
            BufferEmail := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'homePage') then
            BufferHomePage := Rec."Home Page"
        else
            BufferHomePage := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'postalCode') then
            BufferPostalCode := Rec."Post Code"
        else
            BufferPostalCode := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'county') then
            BufferCounty := Rec.County
        else
            BufferCounty := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'country') then
            BufferCountry := Rec."Country/Region Code"
        else
            BufferCountry := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'locationCode') then
            BufferLocationCode := Rec."Location Code"
        else
            BufferLocationCode := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'shipmentMethodCode') then
            BufferShipmentMethodCode := Rec."Shipment Method Code"
        else
            BufferShipmentMethodCode := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'shippingAgentCode') then
            BufferShippingAgentCode := Rec."Shipping Agent Code"
        else
            BufferShippingAgentCode := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'shippingAgentServiceCode') then
            BufferShippingAgentServiceCode := Rec."Shipping Agent Service Code"
        else
            BufferShippingAgentServiceCode := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'gln') then
            BufferGln := Rec.GLN
        else
            BufferGln := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'taxAreaCode') then
            BufferTaxAreaCode := Rec."Tax Area Code"
        else
            BufferTaxAreaCode := '';

        if FieldVisibility.IsFieldVisible('SHIPTOADDR', 'taxLiable') then
            BufferTaxLiable := Rec."Tax Liable"
        else
            BufferTaxLiable := false;
    end;
}
