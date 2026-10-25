page 50137 "WZC Inventory Feed API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Inventory Feed Item';
    EntitySetCaption = 'Wiz Inventory Feed Items';
    EntityName = 'wizInventoryFeedItem';
    EntitySetName = 'wizInventoryFeedItems';
    SourceTable = Item;
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Unified INVENTORY API. Availability is computed server-side (WZC Availability Calc) - WizCommerce no longer needs to pull every sales and purchase order. $expand=wizFutureAvailabilities returns open purchase order lines (inbound / future ATP). Replaces per-tenant inventoryitems and inventoryFeedItems?$expand=futureAvailability. The company Location Filter scopes every quantity; tenant rules come from a Pull Sync Profile on INVFEED.';

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
                field(baseUnitOfMeasure; Rec."Base Unit of Measure")
                {
                    Caption = 'Base Unit of Measure';
                }
                field(inventory; Rec.Inventory)
                {
                    Caption = 'Inventory';
                    Editable = false;
                }
                field(qtyOnSalesOrder; Rec."Qty. on Sales Order")
                {
                    Caption = 'Qty. on Sales Order';
                    Editable = false;
                }
                field(qtyOnPurchOrder; Rec."Qty. on Purch. Order")
                {
                    Caption = 'Qty. on Purch. Order';
                    Editable = false;
                }
                field(reservedQtyOnInventory; Rec."Reserved Qty. on Inventory")
                {
                    Caption = 'Reserved Qty. on Inventory';
                    Editable = false;
                }
                field(availableQuantity; AvailableQuantity)
                {
                    Caption = 'Available Quantity';
                    Editable = false;
                }
                field(availableInventory; AvailableInventory)
                {
                    Caption = 'Available Inventory';
                    Editable = false;
                }
                field(projectedAvailableQuantity; ProjectedAvailableQuantity)
                {
                    Caption = 'Projected Available Quantity';
                    Editable = false;
                }
                field(sellOnWebsite; Rec."WZC Sell On Website")
                {
                    Caption = 'Sell On Website';
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                }
                field(salesBlocked; Rec."Sales Blocked")
                {
                    Caption = 'Sales Blocked';
                }
                field(globalDimension1Code; Rec."Global Dimension 1 Code")
                {
                    Caption = 'Global Dimension 1 Code';
                }
                field(globalDimension2Code; Rec."Global Dimension 2 Code")
                {
                    Caption = 'Global Dimension 2 Code';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                part(wizFutureAvailabilities; "WZC Future Availability Part")
                {
                    Caption = 'Future Availability';
                    SubPageLink = "No." = field("No.");
                    EntityName = 'wizFutureAvailability';
                    EntitySetName = 'wizFutureAvailabilities';
                }
            }
        }
    }

    var
        ApiBase: Codeunit "WZC Api Base";
        AvailabilityCalc: Codeunit "WZC Availability Calc";
        ApiOperationTok: Label 'INVFEED', Locked = true;
        AvailableQuantity: Decimal;
        AvailableInventory: Decimal;
        ProjectedAvailableQuantity: Decimal;

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.EnforceApiAccess(ApiOperationTok, 'WZC Inventory Feed API');
        ApiBase.ApplyLocationFilter(Rec);
        ApiBase.ApplyPullProfileToItem(ApiOperationTok, Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        AvailabilityCalc.Calculate(Rec, AvailableQuantity, AvailableInventory, ProjectedAvailableQuantity);
    end;
}
