page 50154 "WZC Item Attr Mapping Part"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Item Attribute';
    EntitySetCaption = 'Wiz Item Attributes';
    EntityName = 'wizItemAttribute';
    EntitySetName = 'wizItemAttributes';
    SourceTable = "Item Attribute Value Mapping";
    ODataKeyFields = "Item Attribute ID";
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Native BC item attribute values inline under wizItems ($expand=wizItemAttributes). Reads from standard BC Item Attribute Value Mapping — no WizCommerce-specific setup needed. Clients add attributes via BC Item Card > Attributes action.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(itemAttributeId; Rec."Item Attribute ID")
                {
                    Caption = 'Attribute Id';
                    Editable = false;
                }
                field(attributeName; AttributeName)
                {
                    Caption = 'Attribute Name';
                    Editable = false;
                }
                field(attributeValue; AttributeValue)
                {
                    Caption = 'Attribute Value';
                    Editable = false;
                }
                field(attributeType; AttributeType)
                {
                    Caption = 'Attribute Type';
                    Editable = false;
                }
                field(unitOfMeasure; UnitOfMeasure)
                {
                    Caption = 'Unit of Measure';
                    Editable = false;
                }
            }
        }
    }

    var
        ItemAttr: Record "Item Attribute";
        ItemAttrValue: Record "Item Attribute Value";
        AttributeName: Text[250];
        AttributeValue: Text[250];
        AttributeType: Text[50];
        UnitOfMeasure: Code[10];

    trigger OnAfterGetRecord()
    begin
        AttributeName := '';
        AttributeValue := '';
        AttributeType := '';
        UnitOfMeasure := '';
        if ItemAttr.Get(Rec."Item Attribute ID") then begin
            AttributeName := ItemAttr.Name;
            AttributeType := Format(ItemAttr.Type);
            UnitOfMeasure := ItemAttr."Unit of Measure";
        end;
        if ItemAttrValue.Get(Rec."Item Attribute ID", Rec."Item Attribute Value ID") then
            AttributeValue := ItemAttrValue.Value;
    end;
}
