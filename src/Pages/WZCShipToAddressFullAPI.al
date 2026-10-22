page 50104 "WZC Ship-to Address Full API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v1.0';
    EntityCaption = 'Wiz Ship-to Address Full';
    EntitySetCaption = 'Wiz Ship-to Addresses Full';
    EntityName = 'wizShipToAddressFull';
    EntitySetName = 'wizShipToAddressesFull';
    SourceTable = "Ship-to Address";
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Full field projection of Ship-to Address (every standard field), for WizCommerce integrations that need more than the curated wizShipToAddresses set.';

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
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(name2; Rec."Name 2")
                {
                    Caption = 'Name 2';
                }
                field(address; Rec.Address)
                {
                    Caption = 'Address';
                }
                field(address2; Rec."Address 2")
                {
                    Caption = 'Address 2';
                }
                field(city; Rec.City)
                {
                    Caption = 'City';
                }
                field(contact; Rec.Contact)
                {
                    Caption = 'Contact';
                }
                field(phoneNo; Rec."Phone No.")
                {
                    Caption = 'Phone No.';
                }
                field(faxNo; Rec."Fax No.")
                {
                    Caption = 'Fax No.';
                }
                field(email; Rec."E-Mail")
                {
                    Caption = 'E-Mail';
                }
                field(homePage; Rec."Home Page")
                {
                    Caption = 'Home Page';
                }
                field(postCode; Rec."Post Code")
                {
                    Caption = 'Postal Code';
                }
                field(county; Rec.County)
                {
                    Caption = 'County';
                }
                field(countryRegionCode; Rec."Country/Region Code")
                {
                    Caption = 'Country/Region Code';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
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
                field(gln; Rec.GLN)
                {
                    Caption = 'GLN';
                }
                field(taxAreaCode; Rec."Tax Area Code")
                {
                    Caption = 'Tax Area Code';
                }
                field(taxLiable; Rec."Tax Liable")
                {
                    Caption = 'Tax Liable';
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

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.EnforceApiAccess('SHIPTOADDRFULL', 'WZC Ship-to Address Full API');
    end;
}
