page 50103 "WZC Item Availability"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v1.0';
    EntityCaption = 'Wiz Item Availability';
    EntitySetCaption = 'Wiz Item Availabilities';
    EntityName = 'wizItemAvailability';
    EntitySetName = 'wizItemAvailabilities';
    SourceTable = Item;
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Read-only item availability fields for WizCommerce inventory sync. Prefer this over multi-call inventory fallback in Business Central V2.';

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
                field(itemNo; Rec."No.")
                {
                    Caption = 'Item No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(inventory; Rec.Inventory)
                {
                    Caption = 'Inventory';
                    Editable = false;
                }
                field(qtyOnPurchOrder; Rec."Qty. on Purch. Order")
                {
                    Caption = 'Qty. on Purch. Order';
                    Editable = false;
                }
                field(qtyOnSalesOrder; Rec."Qty. on Sales Order")
                {
                    Caption = 'Qty. on Sales Order';
                    Editable = false;
                }
                field(dimension1Code; Rec."Global Dimension 1 Code")
                {
                    Caption = 'Global Dimension 1 Code';
                }
                field(dimension2Code; Rec."Global Dimension 2 Code")
                {
                    Caption = 'Global Dimension 2 Code';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        Setup: Record "WZC Connector Setup";
        SetupMgt: Codeunit "WZC Setup Mgt";
        SyncProfile: Record "WZC Sync Profile";
        FilterEngine: Codeunit "WZC Sync Filter Engine";
    begin
        SetupMgt.EnforceApiAccess('ITEMAVAIL', 'WZC Item Availability');
        SetupMgt.GetSetup(Setup);
        if Setup."Location Filter" <> '' then
            Rec.SetRange("Location Filter", Setup."Location Filter");

        SyncProfile.SetRange("Api Operation", 'ITEMAVAIL');
        SyncProfile.SetRange(Enabled, true);
        SyncProfile.SetRange(Direction, SyncProfile.Direction::Pull);
        if SyncProfile.IsEmpty() then
            SyncProfile.SetRange(Direction, SyncProfile.Direction::Both);
        if SyncProfile.FindFirst() then
            FilterEngine.ApplyProfileToItem(SyncProfile, 0DT, 0DT, Rec);
    end;
}
