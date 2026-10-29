page 50157 "WZC Item Attr Write"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Item Attribute Write';
    EntitySetCaption = 'Wiz Item Attribute Writes';
    EntityName = 'wizItemAttributeWrite';
    EntitySetName = 'wizItemAttributeWrites';
    SourceTable = "Item Attribute Value Mapping";
    SourceTableView = where("Table ID" = const(27));
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    Extensible = false;
    AboutText = 'Push API for item attribute value mappings. POST to assign an attribute value to an item, PATCH to change the value, DELETE to remove. The item, attribute (table 7500) and attribute value (table 7501) must already exist in BC. Use itemAttributeId and itemAttributeValueId from the BC Item Attribute / Item Attribute Value tables.';

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
                field(itemNumber; Rec."No.")
                {
                    Caption = 'Item Number';

                    trigger OnValidate()
                    var
                        Item: Record Item;
                    begin
                        Item.Get(Rec."No.");
                    end;
                }
                field(itemAttributeId; Rec."Item Attribute ID")
                {
                    Caption = 'Item Attribute ID';

                    trigger OnValidate()
                    var
                        ItemAttr: Record "Item Attribute";
                    begin
                        ItemAttr.Get(Rec."Item Attribute ID");
                    end;
                }
                field(itemAttributeValueId; Rec."Item Attribute Value ID")
                {
                    Caption = 'Item Attribute Value ID';

                    trigger OnValidate()
                    var
                        ItemAttrVal: Record "Item Attribute Value";
                    begin
                        ItemAttrVal.Get(Rec."Item Attribute ID", Rec."Item Attribute Value ID");
                    end;
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
            }
        }
    }

    var
        AttributeName: Text[250];
        AttributeValue: Text[250];

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.EnforceApiAccess('ITEMATTRIBUTEWRITE', 'WZC Item Attr Write');
    end;

    trigger OnAfterGetRecord()
    var
        ItemAttr: Record "Item Attribute";
        ItemAttrVal: Record "Item Attribute Value";
    begin
        AttributeName := '';
        AttributeValue := '';
        if ItemAttr.Get(Rec."Item Attribute ID") then
            AttributeName := ItemAttr.Name;
        if ItemAttrVal.Get(Rec."Item Attribute ID", Rec."Item Attribute Value ID") then
            AttributeValue := ItemAttrVal.Value;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Table ID" := 27;
        Rec.Insert(true);
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec.Modify(true);
        exit(false);
    end;
}
