page 50141 "WZC Order Dimension Part"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Sales Order Dimension';
    EntitySetCaption = 'Wiz Sales Order Dimensions';
    EntityName = 'wizSalesOrderDimension';
    EntitySetName = 'wizSalesOrderDimensions';
    SourceTable = "Dimension Set Entry";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Header dimension set entries inline under wizSalesOrders ($expand=wizSalesOrderDimensions). Dimension sets are immutable in Business Central; on push, set shortcutDimension1Code / shortcutDimension2Code on the header or lines - WZC Order Write Mgt validates combinations and blocked values before the order is accepted.';

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
                field(dimensionSetId; Rec."Dimension Set ID")
                {
                    Caption = 'Dimension Set ID';
                }
                field(dimensionCode; Rec."Dimension Code")
                {
                    Caption = 'Dimension Code';
                }
                field(dimensionName; Rec."Dimension Name")
                {
                    Caption = 'Dimension Name';
                    Editable = false;
                }
                field(dimensionValueCode; Rec."Dimension Value Code")
                {
                    Caption = 'Dimension Value Code';
                }
                field(dimensionValueName; Rec."Dimension Value Name")
                {
                    Caption = 'Dimension Value Name';
                    Editable = false;
                }
            }
        }
    }
}
