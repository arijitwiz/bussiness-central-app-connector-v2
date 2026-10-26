page 50145 "WZC Customer Attr Part"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Customer Attribute';
    EntitySetCaption = 'Wiz Customer Attributes';
    EntityName = 'wizCustomerAttribute';
    EntitySetName = 'wizCustomerAttributes';
    SourceTable = "WZC Customer Attribute";
    ODataKeyFields = "Attribute Name";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    Extensible = false;
    AboutText = 'Tenant-defined custom attributes on the customer, inline under wizCustomers ($expand=wizCustomerAttributes). POST an {attributeName, attributeValue, dataType} to set a value; repeat to update it.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(customerNumber; Rec."Customer No.")
                {
                    Caption = 'Customer Number';
                }
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
