page 50123 "WZC Ship-to Attr Part"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v1.0';
    EntityName = 'shipToAttribute';
    EntitySetName = 'shipToAttributes';
    SourceTable = "WZC Ship-to Attribute";
    ODataKeyFields = "Attribute Name";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    Extensible = false;

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
