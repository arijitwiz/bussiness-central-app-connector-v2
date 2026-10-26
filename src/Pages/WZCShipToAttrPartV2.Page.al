page 50147 "WZC Ship-to Attr Part V2"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Ship-to Attribute';
    EntitySetCaption = 'Wiz Ship-to Attributes';
    EntityName = 'wizShipToAttribute';
    EntitySetName = 'wizShipToAttributes';
    SourceTable = "WZC Ship-to Attribute";
    ODataKeyFields = "Attribute Name";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    Extensible = false;
    AboutText = 'Tenant-defined custom attributes on a ship-to address, inline under wizCustomerAddresses ($expand=wizShipToAttributes). POST is idempotent on attributeName: repeating an existing name updates the value.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(attributeName; Rec."Attribute Name")
                {
                    Caption = 'Attribute Name';
                }
                field(attributeValue; Rec."Attribute Value")
                {
                    Caption = 'Attribute Value';
                }
                field(dataType; Rec."Data Type")
                {
                    Caption = 'Data Type';
                }
            }
        }
    }
}
