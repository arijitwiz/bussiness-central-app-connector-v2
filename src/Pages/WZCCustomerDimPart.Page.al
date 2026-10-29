page 50155 "WZC Customer Dim Part"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Customer Dimension';
    EntitySetCaption = 'Wiz Customer Dimensions';
    EntityName = 'wizCustomerDimension';
    EntitySetName = 'wizCustomerDimensions';
    SourceTable = "Default Dimension";
    ODataKeyFields = "Dimension Code";
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Native BC customer default dimensions inline under wizCustomers ($expand=wizCustomerDimensions). Reads from standard BC Default Dimension table (Table ID=18) — no WizCommerce-specific setup needed. Clients configure dimensions via BC Customer Card > Dimensions action.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(dimensionCode; Rec."Dimension Code")
                {
                    Caption = 'Dimension Code';
                    Editable = false;
                }
                field(dimensionValueCode; Rec."Dimension Value Code")
                {
                    Caption = 'Dimension Value Code';
                    Editable = false;
                }
                field(dimensionValueName; DimensionValueName)
                {
                    Caption = 'Dimension Value Name';
                    Editable = false;
                }
                field(valuePosting; Rec."Value Posting")
                {
                    Caption = 'Value Posting';
                    Editable = false;
                }
            }
        }
    }

    var
        DimValue: Record "Dimension Value";
        DimensionValueName: Text[50];

    trigger OnAfterGetRecord()
    begin
        DimensionValueName := '';
        if DimValue.Get(Rec."Dimension Code", Rec."Dimension Value Code") then
            DimensionValueName := DimValue.Name;
    end;
}
