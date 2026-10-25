query 50130 "WZC Inventory By Location"
{
    QueryType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Inventory By Location';
    EntitySetCaption = 'Wiz Inventory By Locations';
    EntityName = 'wizInventoryByLocation';
    EntitySetName = 'wizInventoryByLocations';
    DataAccessIntent = ReadOnly;
    AboutText = 'On-hand quantity per item / variant / location, aggregated server-side from Item Ledger Entries. Filter with $filter=itemNo eq ''...'' or locationCode eq ''...''.';

    elements
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            column(itemNo; "Item No.")
            {
            }
            column(variantCode; "Variant Code")
            {
            }
            column(locationCode; "Location Code")
            {
            }
            column(quantity; Quantity)
            {
                Method = Sum;
            }
            column(remainingQuantity; "Remaining Quantity")
            {
                Method = Sum;
            }
        }
    }

    trigger OnBeforeOpen()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.EnforceApiAccess('INVBYLOC', 'WZC Inventory By Location');
    end;
}
