page 50156 "WZC Customer Dim Write"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Customer Dimension Write';
    EntitySetCaption = 'Wiz Customer Dimension Writes';
    EntityName = 'wizCustomerDimensionWrite';
    EntitySetName = 'wizCustomerDimensionWrites';
    SourceTable = "Default Dimension";
    SourceTableView = where("Table ID" = const(18));
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    Extensible = false;
    AboutText = 'Push API for customer default dimensions. POST to create, PATCH to update, DELETE to remove a dimension assignment. The customer must already exist. Dimension code and value code must be valid BC dimensions configured in the environment.';

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
                field(customerNumber; Rec."No.")
                {
                    Caption = 'Customer Number';

                    trigger OnValidate()
                    var
                        Cust: Record Customer;
                    begin
                        Cust.Get(Rec."No.");
                    end;
                }
                field(dimensionCode; Rec."Dimension Code")
                {
                    Caption = 'Dimension Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Dimension Code");
                    end;
                }
                field(dimensionValueCode; Rec."Dimension Value Code")
                {
                    Caption = 'Dimension Value Code';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Dimension Value Code");
                    end;
                }
                field(valuePosting; Rec."Value Posting")
                {
                    Caption = 'Value Posting';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.EnforceApiAccess('CUSTOMERDIMWRITE', 'WZC Customer Dim Write');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Table ID" := 18;
        Rec.Insert(true);
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec.Modify(true);
        exit(false);
    end;
}
