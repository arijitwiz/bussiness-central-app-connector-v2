codeunit 50130 "WZC Api Base"
{
    /// <summary>
    /// Shared helpers for every WZC API page/query. Keeps the pages themselves to pure
    /// projection: access enforcement, tenant sync-profile filtering, Location Filter
    /// scoping and Field-Visibility gating all live here, once.
    /// </summary>

    // ---------------------------------------------------------------------
    // Field Visibility (tenant-wise response control)
    // ---------------------------------------------------------------------

    procedure IsVisible(ApiOperation: Code[30]; FieldName: Code[50]): Boolean
    var
        FieldVisibility: Codeunit "WZC Field Visibility Mgt";
    begin
        exit(FieldVisibility.IsFieldVisible(ApiOperation, FieldName));
    end;

    /// <summary>Returns Value when the field is visible for this API, otherwise blank.</summary>
    procedure TextIf(ApiOperation: Code[30]; FieldName: Code[50]; Value: Text): Text
    begin
        if IsVisible(ApiOperation, FieldName) then
            exit(Value);
        exit('');
    end;

    procedure BoolIf(ApiOperation: Code[30]; FieldName: Code[50]; Value: Boolean): Boolean
    begin
        if IsVisible(ApiOperation, FieldName) then
            exit(Value);
        exit(false);
    end;

    procedure DecIf(ApiOperation: Code[30]; FieldName: Code[50]; Value: Decimal): Decimal
    begin
        if IsVisible(ApiOperation, FieldName) then
            exit(Value);
        exit(0);
    end;

    procedure DateIf(ApiOperation: Code[30]; FieldName: Code[50]; Value: Date): Date
    begin
        if IsVisible(ApiOperation, FieldName) then
            exit(Value);
        exit(0D);
    end;

    /// <summary>
    /// For READ-ONLY projections: blanks (in memory only - never Modify) every table field
    /// listed in FieldMap whose API field name is hidden for ApiOperation. FieldMap maps
    /// API field name -> table field no. Do not use on writable pages (a PATCH would then
    /// persist the blanks) - writable pages use the buffer-variable pattern with TextIf etc.
    /// Primary-key fields and FlowFields must not be put in FieldMap.
    /// </summary>
    procedure BlankHiddenFields(ApiOperation: Code[30]; var RecRef: RecordRef; FieldMap: Dictionary of [Code[50], Integer])
    var
        FieldVisibility: Codeunit "WZC Field Visibility Mgt";
        FldRef: FieldRef;
        FieldName: Code[50];
    begin
        if not FieldVisibility.HasAnyConfig(ApiOperation) then
            exit; // no tenant config -> code default: every field visible

        foreach FieldName in FieldMap.Keys() do
            if not FieldVisibility.IsFieldVisible(ApiOperation, FieldName) then begin
                FldRef := RecRef.Field(FieldMap.Get(FieldName));
                BlankFieldRef(FldRef);
            end;
    end;

    local procedure BlankFieldRef(var FldRef: FieldRef)
    var
        EmptyDate: Date;
        EmptyTime: Time;
        EmptyDateTime: DateTime;
        EmptyDecimal: Decimal;
        EmptyInteger: Integer;
        EmptyBigInteger: BigInteger;
        EmptyGuid: Guid;
    begin
        Clear(EmptyDate);
        Clear(EmptyTime);
        Clear(EmptyDateTime);
        Clear(EmptyDecimal);
        Clear(EmptyInteger);
        Clear(EmptyBigInteger);
        Clear(EmptyGuid);
        case FldRef.Type of
            FieldType::Text, FieldType::Code:
                FldRef.Value := '';
            FieldType::Decimal:
                FldRef.Value := EmptyDecimal;
            FieldType::Integer, FieldType::Option:
                FldRef.Value := EmptyInteger;
            FieldType::BigInteger:
                FldRef.Value := EmptyBigInteger;
            FieldType::Boolean:
                FldRef.Value := false;
            FieldType::Date:
                FldRef.Value := EmptyDate;
            FieldType::Time:
                FldRef.Value := EmptyTime;
            FieldType::DateTime:
                FldRef.Value := EmptyDateTime;
            FieldType::Guid:
                FldRef.Value := EmptyGuid;
        end;
    end;

    // ---------------------------------------------------------------------
    // Sync profile filtering (tenant business rules, e.g. Customer Price Group = RTMASTER)
    // ---------------------------------------------------------------------

    procedure ApplyPullProfileToItem(ApiOperation: Code[30]; var Item: Record Item)
    var
        SyncProfile: Record "WZC Sync Profile";
        FilterEngine: Codeunit "WZC Sync Filter Engine";
    begin
        if FindPullProfile(ApiOperation, SyncProfile) then
            FilterEngine.ApplyProfileToItem(SyncProfile, 0DT, 0DT, Item);
    end;

    procedure ApplyPullProfileToCustomer(ApiOperation: Code[30]; var Customer: Record Customer)
    var
        SyncProfile: Record "WZC Sync Profile";
        FilterEngine: Codeunit "WZC Sync Filter Engine";
    begin
        if FindPullProfile(ApiOperation, SyncProfile) then
            FilterEngine.ApplyProfileToCustomer(SyncProfile, 0DT, 0DT, Customer);
    end;

    procedure ApplyPullProfileToShipToAddress(ApiOperation: Code[30]; var ShipToAddress: Record "Ship-to Address")
    var
        SyncProfile: Record "WZC Sync Profile";
        FilterEngine: Codeunit "WZC Sync Filter Engine";
    begin
        if FindPullProfile(ApiOperation, SyncProfile) then
            FilterEngine.ApplyProfileToShipToAddress(SyncProfile, 0DT, 0DT, ShipToAddress);
    end;

    local procedure FindPullProfile(ApiOperation: Code[30]; var SyncProfile: Record "WZC Sync Profile"): Boolean
    begin
        SyncProfile.SetRange("Api Operation", ApiOperation);
        SyncProfile.SetRange(Enabled, true);
        SyncProfile.SetRange(Direction, SyncProfile.Direction::Pull);
        if SyncProfile.IsEmpty() then
            SyncProfile.SetRange(Direction, SyncProfile.Direction::Both);
        exit(SyncProfile.FindFirst());
    end;

    // ---------------------------------------------------------------------
    // Company-level scoping from WZC Connector Setup
    // ---------------------------------------------------------------------

    /// <summary>Scopes every Item FlowField (Inventory, Qty. on Sales/Purch. Order, ...) to the configured location.</summary>
    procedure ApplyLocationFilter(var Item: Record Item)
    var
        Setup: Record "WZC Connector Setup";
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.GetSetup(Setup);
        if Setup."Location Filter" <> '' then
            Item.SetRange("Location Filter", Setup."Location Filter");
    end;

    procedure ApplyPriceListFilter(var PriceListLine: Record "Price List Line")
    var
        Setup: Record "WZC Connector Setup";
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.GetSetup(Setup);
        if Setup."Price List Filter" <> '' then
            PriceListLine.SetRange("Price List Code", Setup."Price List Filter");
    end;

    // ---------------------------------------------------------------------
    // Custom Fields (UDF / table extension columns)
    // ---------------------------------------------------------------------

    procedure BuildCustomFieldsJSON(var RecRef: RecordRef): Text
    var
        FldRef: FieldRef;
        JObj: JsonObject;
        FldName: Text;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            if (FldRef.Number >= 50000) and (FldRef.Class = FieldClass::Normal) then begin
                FldName := FldRef.Name;
                if not FldName.StartsWith('WZC') then
                    JObj.Add(FldName, Format(FldRef.Value));
            end;
        end;
        JObj.WriteTo(Result);
        exit(Result);
    end;

    procedure WriteCustomFieldsJSON(var RecRef: RecordRef; CustomFieldsJSON: Text)
    var
        FldRef: FieldRef;
        JObj: JsonObject;
        JToken: JsonToken;
        FldName: Text;
        i: Integer;
    begin
        if (CustomFieldsJSON = '') or (CustomFieldsJSON = '{}') then
            exit;
        if not JObj.ReadFrom(CustomFieldsJSON) then
            exit;

        for i := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            if (FldRef.Number >= 50000) and (FldRef.Class = FieldClass::Normal) then begin
                FldName := FldRef.Name;
                if not FldName.StartsWith('WZC') then
                    if JObj.Get(FldName, JToken) then
                        SetFieldFromJsonToken(FldRef, JToken);
            end;
        end;
    end;

    local procedure SetFieldFromJsonToken(var FldRef: FieldRef; JToken: JsonToken)
    var
        JValue: JsonValue;
        TextVal: Text;
        DecVal: Decimal;
        IntVal: Integer;
        BoolVal: Boolean;
        DateVal: Date;
        BigIntVal: BigInteger;
    begin
        if not JToken.IsValue then
            exit;
        JValue := JToken.AsValue();
        if JValue.IsNull then
            exit;
        TextVal := JValue.AsText();
        if TextVal = '' then
            exit;
        case FldRef.Type of
            FieldType::Text, FieldType::Code:
                FldRef.Value := CopyStr(TextVal, 1, FldRef.Length);
            FieldType::Decimal:
                if Evaluate(DecVal, TextVal) then
                    FldRef.Value := DecVal;
            FieldType::Integer, FieldType::Option:
                if Evaluate(IntVal, TextVal) then
                    FldRef.Value := IntVal;
            FieldType::Boolean:
                if Evaluate(BoolVal, TextVal) then
                    FldRef.Value := BoolVal;
            FieldType::Date:
                if Evaluate(DateVal, TextVal) then
                    FldRef.Value := DateVal;
            FieldType::BigInteger:
                if Evaluate(BigIntVal, TextVal) then
                    FldRef.Value := BigIntVal;
        end;
    end;
}
