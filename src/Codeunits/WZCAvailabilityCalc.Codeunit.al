codeunit 50131 "WZC Availability Calc"
{
    /// <summary>
    /// Server-side availability math. Replaces the WizCommerce-side computation that pulled
    /// EVERY sales order and purchase order to derive availability per item. All figures
    /// honour whatever filters the caller already set on Item (e.g. Location Filter).
    ///
    ///   availableQuantity          = Inventory - Qty. on Sales Order
    ///   availableInventory         = Inventory - Reserved Qty. on Inventory   (BC "Available Inventory")
    ///   projectedAvailableQuantity = availableQuantity + Qty. on Purch. Order (inbound included)
    /// </summary>
    procedure Calculate(var Item: Record Item; var AvailableQuantity: Decimal; var AvailableInventory: Decimal; var ProjectedAvailableQuantity: Decimal)
    begin
        Item.CalcFields(Inventory, "Qty. on Sales Order", "Qty. on Purch. Order", "Reserved Qty. on Inventory");
        AvailableQuantity := Item.Inventory - Item."Qty. on Sales Order";
        AvailableInventory := Item.Inventory - Item."Reserved Qty. on Inventory";
        ProjectedAvailableQuantity := AvailableQuantity + Item."Qty. on Purch. Order";
    end;

    procedure GetAvailableQuantity(var Item: Record Item): Decimal
    var
        Available: Decimal;
        AvailableInv: Decimal;
        Projected: Decimal;
    begin
        Calculate(Item, Available, AvailableInv, Projected);
        exit(Available);
    end;

    procedure GetProjectedAvailableQuantity(var Item: Record Item): Decimal
    var
        Available: Decimal;
        AvailableInv: Decimal;
        Projected: Decimal;
    begin
        Calculate(Item, Available, AvailableInv, Projected);
        exit(Projected);
    end;
}
