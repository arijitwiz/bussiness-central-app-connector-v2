page 50114 "WZC Ship-to Attribute API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v1.0';
    EntityCaption = 'Wiz Ship-to Attribute';
    EntitySetCaption = 'Wiz Ship-to Attributes';
    EntityName = 'wizShipToAttribute';
    EntitySetName = 'wizShipToAttributes';
    SourceTable = "WZC Ship-to Attribute";
    ODataKeyFields = "Customer No.", "Ship-to Code", "Attribute Name";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    Extensible = false;
    AboutText = 'Generic, tenant-defined custom attributes on Ship-to Address. Each tenant creates their own attribute rows here (no AL redeploy needed) and WizCommerce reads/writes them through this one generic endpoint. POST is idempotent: posting an existing key updates it instead of erroring.';

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
                field(shipToCode; Rec."Ship-to Code")
                {
                    Caption = 'Ship-to Code';
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
                field(logicalName; CurrentLogicalName)
                {
                    Caption = 'Logical Name';
                    Editable = false;
                }
            }
        }
    }

    var
        CurrentLogicalName: Code[50];

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.EnforceApiAccess('SHIPTOATTR', 'WZC Ship-to Attribute API');
    end;

    trigger OnAfterGetRecord()
    var
        Mapping: Record "WZC Attribute Mapping";
    begin
        Mapping.SetRange(Entity, 'SHIPTOADDR');
        Mapping.SetRange("Tenant Attribute Name", Rec."Attribute Name");
        if Mapping.FindFirst() then
            CurrentLogicalName := Mapping."Logical Name"
        else
            CurrentLogicalName := '';
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Existing: Record "WZC Ship-to Attribute";
    begin
        if Existing.Get(Rec."Customer No.", Rec."Ship-to Code", Rec."Attribute Name") then begin
            Existing."Attribute Value" := Rec."Attribute Value";
            Existing."Data Type" := Rec."Data Type";
            Existing.Modify(true);
            Rec := Existing;
            exit(false);
        end;
        exit(true);
    end;
}
