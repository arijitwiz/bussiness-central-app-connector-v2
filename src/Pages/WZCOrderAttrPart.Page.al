page 50148 "WZC Order Attr Part"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Sales Order Attribute';
    EntitySetCaption = 'Wiz Sales Order Attributes';
    EntityName = 'wizSalesOrderAttribute';
    EntitySetName = 'wizSalesOrderAttributes';
    SourceTable = "WZC Sales Order Attribute";
    ODataKeyFields = "Attribute Name";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    Extensible = false;
    AboutText = 'Tenant-defined custom attributes on a sales order, inline under wizSalesOrders ($expand=wizSalesOrderAttributes). POST is idempotent on attributeName.';

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
