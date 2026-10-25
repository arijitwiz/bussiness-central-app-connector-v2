page 50136 "WZC Item UoM Part"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Item Unit of Measure';
    EntitySetCaption = 'Wiz Item Units of Measure';
    EntityName = 'wizItemUnitOfMeasure';
    EntitySetName = 'wizItemUnitsOfMeasure';
    SourceTable = "Item Unit of Measure";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Item units of measure (pack sizes, conversions, dimensions) inline under wizItems ($expand=wizItemUnitsOfMeasure).';

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
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field(code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(qtyPerUnitOfMeasure; Rec."Qty. per Unit of Measure")
                {
                    Caption = 'Qty. per Unit of Measure';
                }
                field(weight; Rec.Weight)
                {
                    Caption = 'Weight';
                }
                field(height; Rec.Height)
                {
                    Caption = 'Height';
                }
                field(width; Rec.Width)
                {
                    Caption = 'Width';
                }
                field(length; Rec.Length)
                {
                    Caption = 'Length';
                }
                field(cubage; Rec.Cubage)
                {
                    Caption = 'Cubage';
                }
            }
        }
    }
}
