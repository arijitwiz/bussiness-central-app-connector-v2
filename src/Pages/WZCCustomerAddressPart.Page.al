page 50131 "WZC Customer Address Part"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Customer Address';
    EntitySetCaption = 'Wiz Customer Addresses';
    EntityName = 'wizCustomerAddress';
    EntitySetName = 'wizCustomerAddresses';
    SourceTable = "Ship-to Address";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Ship-to addresses inline under wizCustomers ($expand=wizCustomerAddresses). Address identity = customerNumber + code; code is never cleared. Deep insert on POST /wizCustomers and POST /wizCustomers({id})/wizCustomerAddresses are both supported.';

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
                field(county; Rec.County)
                {
                    Caption = 'County/State';
                }
                field(postalCode; Rec."Post Code")
                {
                    Caption = 'Postal Code';
                }
                field(countryRegionCode; Rec."Country/Region Code")
                {
                    Caption = 'Country/Region Code';
                }
                field(contact; Rec.Contact)
                {
                    Caption = 'Contact';
                }
                field(phoneNo; Rec."Phone No.")
                {
                    Caption = 'Phone No.';
                }
                field(email; Rec."E-Mail")
                {
                    Caption = 'E-Mail';
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
                field(deliveryInstructions; Rec."WZC Delivery Instructions")
                {
                    Caption = 'Delivery Instructions';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                part(wizShipToAttributes; "WZC Ship-to Attr Part V2")
                {
                    Caption = 'Custom Attributes';
                    SubPageLink = "Customer No." = field("Customer No."), "Ship-to Code" = field(Code);
                    EntityName = 'wizShipToAttribute';
                    EntitySetName = 'wizShipToAttributes';
                }
            }
        }
    }
}
