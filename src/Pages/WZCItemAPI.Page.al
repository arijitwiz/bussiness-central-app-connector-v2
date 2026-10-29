page 50133 "WZC Item API"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Item';
    EntitySetCaption = 'Wiz Items';
    EntityName = 'wizItem';
    EntitySetName = 'wizItems';
    SourceTable = Item;
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Unified PRODUCT API. One call returns the item plus customer-aware price list lines, variants and units of measure via $expand=wizItemPrices,wizItemVariants,wizItemUnitsOfMeasure (replaces per-tenant items?$expand=priceListLines / itemMatrixWizCom?$expand=ItemPricing). Pricing is NOT the item base price - use wizItemPrices. Fields are tenant-gated through WZC Field Visibility (Api Operation = ITEM); tenant business rules (e.g. WZC Sell On Website = true) come from an enabled Pull Sync Profile on ITEM; the company Location Filter scopes inventory.';

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
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                }
                field(externalId; Rec."WZC External Id")
                {
                    Caption = 'External Id';
                }
                field(displayName; Rec.Description)
                {
                    Caption = 'Display Name';
                }
                field(description2; Rec."Description 2")
                {
                    Caption = 'Description 2';
                }
                field(searchDescription; Rec."Search Description")
                {
                    Caption = 'Search Description';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(itemCategoryCode; Rec."Item Category Code")
                {
                    Caption = 'Item Category Code';
                }
                field(baseUnitOfMeasure; Rec."Base Unit of Measure")
                {
                    Caption = 'Base Unit of Measure';
                }
                field(salesUnitOfMeasure; Rec."Sales Unit of Measure")
                {
                    Caption = 'Sales Unit of Measure';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Unit Price';
                }
                field(unitCost; Rec."Unit Cost")
                {
                    Caption = 'Unit Cost';
                }
                field(priceIncludesTax; Rec."Price Includes VAT")
                {
                    Caption = 'Price Includes Tax';
                }
                field(inventoryPostingGroup; Rec."Inventory Posting Group")
                {
                    Caption = 'Inventory Posting Group';
                }
                field(genProdPostingGroup; Rec."Gen. Prod. Posting Group")
                {
                    Caption = 'Gen. Prod. Posting Group';
                }
                field(taxGroupCode; Rec."Tax Group Code")
                {
                    Caption = 'Tax Group Code';
                }
                field(vendorNo; Rec."Vendor No.")
                {
                    Caption = 'Vendor No.';
                }
                field(vendorItemNo; Rec."Vendor Item No.")
                {
                    Caption = 'Vendor Item No.';
                }
                field(gtin; Rec.GTIN)
                {
                    Caption = 'GTIN';
                }
                field(tariffNo; Rec."Tariff No.")
                {
                    Caption = 'Tariff No.';
                }
                field(countryRegionOfOriginCode; Rec."Country/Region of Origin Code")
                {
                    Caption = 'Country/Region of Origin Code';
                }
                field(grossWeight; Rec."Gross Weight")
                {
                    Caption = 'Gross Weight';
                }
                field(netWeight; Rec."Net Weight")
                {
                    Caption = 'Net Weight';
                }
                field(unitVolume; Rec."Unit Volume")
                {
                    Caption = 'Unit Volume';
                }
                field(itemTrackingCode; Rec."Item Tracking Code")
                {
                    Caption = 'Item Tracking Code';
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                }
                field(salesBlocked; Rec."Sales Blocked")
                {
                    Caption = 'Sales Blocked';
                }
                field(sellOnWebsite; Rec."WZC Sell On Website")
                {
                    Caption = 'Sell On Website';
                }
                field(inventory; Rec.Inventory)
                {
                    Caption = 'Inventory';
                    Editable = false;
                }
                field(globalDimension1Code; Rec."Global Dimension 1 Code")
                {
                    Caption = 'Global Dimension 1 Code';
                }
                field(globalDimension2Code; Rec."Global Dimension 2 Code")
                {
                    Caption = 'Global Dimension 2 Code';
                }
                field(lastDateModified; Rec."Last Date Modified")
                {
                    Caption = 'Last Date Modified';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                part(wizItemPrices; "WZC Item Price Part")
                {
                    Caption = 'Prices';
                    SubPageLink = "Asset No." = field("No.");
                    EntityName = 'wizItemPrice';
                    EntitySetName = 'wizItemPrices';
                }
                part(wizItemVariants; "WZC Item Variant Part")
                {
                    Caption = 'Variants';
                    SubPageLink = "Item No." = field("No.");
                    EntityName = 'wizItemVariant';
                    EntitySetName = 'wizItemVariants';
                }
                part(wizItemUnitsOfMeasure; "WZC Item UoM Part")
                {
                    Caption = 'Units of Measure';
                    SubPageLink = "Item No." = field("No.");
                    EntityName = 'wizItemUnitOfMeasure';
                    EntitySetName = 'wizItemUnitsOfMeasure';
                }
                field(customFields; CustomFieldsJSON)
                {
                    Caption = 'Custom Fields';
                    Editable = false;
                }
                part(wizItemAttributes; "WZC Item Attr Mapping Part")
                {
                    Caption = 'Attributes';
                    SubPageLink = "Table ID" = const(27), "No." = field("No.");
                    EntityName = 'wizItemAttribute';
                    EntitySetName = 'wizItemAttributes';
                }
            }
        }
    }

    var
        ApiBase: Codeunit "WZC Api Base";
        FieldMap: Dictionary of [Code[50], Integer];
        ApiOperationTok: Label 'ITEM', Locked = true;
        CustomFieldsJSON: Text;

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.EnforceApiAccess(ApiOperationTok, 'WZC Item API');
        ApiBase.ApplyLocationFilter(Rec);
        ApiBase.ApplyPullProfileToItem(ApiOperationTok, Rec);
        BuildFieldMap();
    end;

    trigger OnAfterGetRecord()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        ApiBase.BlankHiddenFields(ApiOperationTok, RecRef, FieldMap);
        RecRef.SetTable(Rec);
        CustomFieldsJSON := ApiBase.BuildCustomFieldsJSON(RecRef);
    end;

    local procedure BuildFieldMap()
    begin
        Clear(FieldMap);
        FieldMap.Add('externalId', Rec.FieldNo("WZC External Id"));
        FieldMap.Add('displayName', Rec.FieldNo(Description));
        FieldMap.Add('description2', Rec.FieldNo("Description 2"));
        FieldMap.Add('searchDescription', Rec.FieldNo("Search Description"));
        FieldMap.Add('itemCategoryCode', Rec.FieldNo("Item Category Code"));
        FieldMap.Add('baseUnitOfMeasure', Rec.FieldNo("Base Unit of Measure"));
        FieldMap.Add('salesUnitOfMeasure', Rec.FieldNo("Sales Unit of Measure"));
        FieldMap.Add('unitPrice', Rec.FieldNo("Unit Price"));
        FieldMap.Add('unitCost', Rec.FieldNo("Unit Cost"));
        FieldMap.Add('priceIncludesTax', Rec.FieldNo("Price Includes VAT"));
        FieldMap.Add('inventoryPostingGroup', Rec.FieldNo("Inventory Posting Group"));
        FieldMap.Add('genProdPostingGroup', Rec.FieldNo("Gen. Prod. Posting Group"));
        FieldMap.Add('taxGroupCode', Rec.FieldNo("Tax Group Code"));
        FieldMap.Add('vendorNo', Rec.FieldNo("Vendor No."));
        FieldMap.Add('vendorItemNo', Rec.FieldNo("Vendor Item No."));
        FieldMap.Add('gtin', Rec.FieldNo(GTIN));
        FieldMap.Add('tariffNo', Rec.FieldNo("Tariff No."));
        FieldMap.Add('countryRegionOfOriginCode', Rec.FieldNo("Country/Region of Origin Code"));
        FieldMap.Add('grossWeight', Rec.FieldNo("Gross Weight"));
        FieldMap.Add('netWeight', Rec.FieldNo("Net Weight"));
        FieldMap.Add('unitVolume', Rec.FieldNo("Unit Volume"));
        FieldMap.Add('itemTrackingCode', Rec.FieldNo("Item Tracking Code"));
        FieldMap.Add('globalDimension1Code', Rec.FieldNo("Global Dimension 1 Code"));
        FieldMap.Add('globalDimension2Code', Rec.FieldNo("Global Dimension 2 Code"));
    end;
}
