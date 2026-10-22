codeunit 50114 "WZC Sync Filter Engine"
{
    var
        FieldNotAllowedErr: Label 'Field ''%1'' is not in the allowlist for entity %2.';
        OperatorNotAllowedErr: Label 'Operator %1 is not allowed on field ''%2'' (type %3).';
        EntityNotWiredErr: Label 'Entity %1 is not wired for filtering/sync yet in this version of the extension.';
        InvalidValueErr: Label 'Value ''%1'' for field ''%2'' does not parse as %3.';
        NoRulesNeedValueErr: Label 'Operator %1 does not use a Value - leave it blank.';
        NoRulesNeedBlankErr: Label 'Operator %1 requires a Value.';

    /// <summary>Maps a WZC Api Config "Api Name" to the Sync Entity it represents, if any.</summary>
    procedure TryGetEntityForApiOperation(ApiOperation: Code[30]; var Entity: Enum "WZC Sync Entity"): Boolean
    begin
        case ApiOperation of
            'ITEMAVAIL':
                begin
                    Entity := Entity::Product;
                    exit(true);
                end;
            'SHIPTOADDR', 'SHIPTOADDRFULL', 'SHIPTOATTR':
                begin
                    Entity := Entity::ShipToAddress;
                    exit(true);
                end;
            'CUSTPRICE':
                begin
                    Entity := Entity::Price;
                    exit(true);
                end;
            else
                exit(false);
        end;
    end;

    /// <summary>Whether the filter engine actually has an allowlist/evaluator wired for this entity yet.</summary>
    procedure IsEntityWired(Entity: Enum "WZC Sync Entity"): Boolean
    begin
        exit(Entity in [Entity::Product, Entity::ShipToAddress]);
    end;

    procedure ValidateProfile(var Profile: Record "WZC Sync Profile")
    var
        FilterRule: Record "WZC Sync Filter Rule";
        Status: Text[250];
    begin
        Status := 'OK';

        if Profile."Api Operation" = '' then
            Status := 'Api Operation is blank.';

        if Status = 'OK' then begin
            FilterRule.SetRange("Profile No.", Profile."Profile No.");
            if FilterRule.FindSet() then
                repeat
                    if not TryValidateRule(Profile.Entity, FilterRule."Field Name", FilterRule.Operator, FilterRule.Value) then
                        Status := CopyStr(StrSubstNo('Line %1: %2', FilterRule."Line No.", GetLastErrorText()), 1, 250);
                until (Status <> 'OK') or (FilterRule.Next() = 0);
        end;

        Profile."Validation Status" := Status;
    end;

    [TryFunction]
    local procedure TryValidateRule(Entity: Enum "WZC Sync Entity"; FieldName: Text[50]; Operator: Enum "WZC Filter Operator"; Value: Text[250])
    begin
        ValidateRuleValue(Entity, FieldName, Operator, Value);
    end;

    /// <summary>Counts matching records without a time window - used by the Preview Records action.</summary>
    procedure PreviewMatchingItemCount(Profile: Record "WZC Sync Profile"; var SampleNos: Text): Integer
    var
        Item: Record Item;
        Count: Integer;
        SampleCount: Integer;
    begin
        Count := ApplyProfileToItem(Profile, 0DT, 0DT, Item);
        SampleNos := '';
        SampleCount := 0;
        if Item.FindSet() then
            repeat
                if SampleCount > 0 then
                    SampleNos += ', ';
                SampleNos += Item."No.";
                SampleCount += 1;
            until (Item.Next() = 0) or (SampleCount >= 5);
        exit(Count);
    end;

    /// <summary>Same as PreviewMatchingItemCount, for the Ship-to Address entity.</summary>
    procedure PreviewMatchingShipToAddressCount(Profile: Record "WZC Sync Profile"; var SampleCodes: Text): Integer
    var
        ShipToAddress: Record "Ship-to Address";
        Count: Integer;
        SampleCount: Integer;
    begin
        Count := ApplyProfileToShipToAddress(Profile, 0DT, 0DT, ShipToAddress);
        SampleCodes := '';
        SampleCount := 0;
        if ShipToAddress.FindSet() then
            repeat
                if SampleCount > 0 then
                    SampleCodes += ', ';
                SampleCodes += ShipToAddress."Customer No." + '/' + ShipToAddress.Code;
                SampleCount += 1;
            until (ShipToAddress.Next() = 0) or (SampleCount >= 5);
        exit(Count);
    end;

    procedure CheckFieldAllowed(Entity: Enum "WZC Sync Entity"; FieldName: Text[50])
    var
        FieldNo: Integer;
        DataType: Enum "WZC Sync Field Data Type";
    begin
        if not TryGetFieldInfo(Entity, FieldName, FieldNo, DataType) then
            Error(FieldNotAllowedErr, FieldName, Entity);
    end;

    procedure CheckOperatorAllowed(Entity: Enum "WZC Sync Entity"; FieldName: Text[50]; Operator: Enum "WZC Filter Operator")
    var
        FieldNo: Integer;
        DataType: Enum "WZC Sync Field Data Type";
    begin
        if not TryGetFieldInfo(Entity, FieldName, FieldNo, DataType) then
            Error(FieldNotAllowedErr, FieldName, Entity);
        if not IsOperatorAllowedForType(DataType, Operator) then
            Error(OperatorNotAllowedErr, Operator, FieldName, DataType);
    end;

    procedure ValidateRuleValue(Entity: Enum "WZC Sync Entity"; FieldName: Text[50]; Operator: Enum "WZC Filter Operator"; Value: Text[250])
    var
        FieldNo: Integer;
        DataType: Enum "WZC Sync Field Data Type";
        DecimalValue: Decimal;
        DateValue: Date;
    begin
        if not TryGetFieldInfo(Entity, FieldName, FieldNo, DataType) then
            Error(FieldNotAllowedErr, FieldName, Entity);

        case Operator of
            Operator::IsEmpty, Operator::IsNotEmpty:
                if Value <> '' then
                    Error(NoRulesNeedValueErr, Operator);
            else
                if Value = '' then
                    Error(NoRulesNeedBlankErr, Operator);
        end;

        if Value <> '' then
            case DataType of
                DataType::Number:
                    if not Evaluate(DecimalValue, Value) then
                        Error(InvalidValueErr, Value, FieldName, DataType);
                DataType::Date:
                    if not Evaluate(DateValue, Value) then
                        Error(InvalidValueErr, Value, FieldName, DataType);
                DataType::Boolean:
                    if not (LowerCase(Value) in ['true', 'false']) then
                        Error(InvalidValueErr, Value, FieldName, DataType);
            end;
    end;

    /// <summary>
    /// Builds the filtered, time-windowed result set for a profile. Entity must already
    /// be wired (Phase 1: Product/Item only - other entities raise EntityNotWiredErr).
    /// Marks matching records on the passed-in Record variable; caller should use
    /// Item.MarkedOnly(true) afterwards. No string-built filter expressions are used -
    /// every comparison is typed, via RecordRef/FieldRef, against the allowlist.
    /// Does NOT reset existing filters on Item - composes with whatever the caller
    /// already set (e.g. a Location Filter from WZC Connector Setup).
    /// </summary>
    procedure ApplyProfileToItem(Profile: Record "WZC Sync Profile"; LowerBound: DateTime; UpperBound: DateTime; var Item: Record Item): Integer
    var
        RecRef: RecordRef;
        DistinctGroups: List of [Integer];
        MatchCount: Integer;
    begin
        if Profile.Entity <> Profile.Entity::Product then
            Error(EntityNotWiredErr, Profile.Entity);

        if UpperBound <> 0DT then
            Item.SetFilter(SystemModifiedAt, '%1..%2', LowerBound, UpperBound);

        GetDistinctGroups(Profile."Profile No.", DistinctGroups);

        if Item.FindSet() then
            repeat
                RecRef.GetTable(Item);
                if RuleSetMatches(Profile.Entity, Profile."Profile No.", DistinctGroups, RecRef) then begin
                    Item.Mark(true);
                    MatchCount += 1;
                end;
            until Item.Next() = 0;

        Item.MarkedOnly(true);
        exit(MatchCount);
    end;

    /// <summary>Same as ApplyProfileToItem, for the Ship-to Address entity.</summary>
    procedure ApplyProfileToShipToAddress(Profile: Record "WZC Sync Profile"; LowerBound: DateTime; UpperBound: DateTime; var ShipToAddress: Record "Ship-to Address"): Integer
    var
        RecRef: RecordRef;
        DistinctGroups: List of [Integer];
        MatchCount: Integer;
    begin
        if Profile.Entity <> Profile.Entity::ShipToAddress then
            Error(EntityNotWiredErr, Profile.Entity);

        if UpperBound <> 0DT then
            ShipToAddress.SetFilter(SystemModifiedAt, '%1..%2', LowerBound, UpperBound);

        GetDistinctGroups(Profile."Profile No.", DistinctGroups);

        if ShipToAddress.FindSet() then
            repeat
                RecRef.GetTable(ShipToAddress);
                if RuleSetMatches(Profile.Entity, Profile."Profile No.", DistinctGroups, RecRef) then begin
                    ShipToAddress.Mark(true);
                    MatchCount += 1;
                end;
            until ShipToAddress.Next() = 0;

        ShipToAddress.MarkedOnly(true);
        exit(MatchCount);
    end;

    local procedure GetDistinctGroups(ProfileNo: Code[20]; var DistinctGroups: List of [Integer])
    var
        FilterRule: Record "WZC Sync Filter Rule";
    begin
        Clear(DistinctGroups);
        FilterRule.SetRange("Profile No.", ProfileNo);
        FilterRule.SetRange(Enabled, true);
        if FilterRule.FindSet() then
            repeat
                if not DistinctGroups.Contains(FilterRule."Group No.") then
                    DistinctGroups.Add(FilterRule."Group No.");
            until FilterRule.Next() = 0;
    end;

    local procedure RuleSetMatches(Entity: Enum "WZC Sync Entity"; ProfileNo: Code[20]; var DistinctGroups: List of [Integer]; var RecRef: RecordRef): Boolean
    var
        GroupRule: Record "WZC Sync Filter Rule";
        GroupNo: Integer;
        GroupMatched: Boolean;
    begin
        if DistinctGroups.Count() = 0 then
            exit(true); // no rules at all - matches everything

        foreach GroupNo in DistinctGroups do begin
            GroupMatched := false;
            GroupRule.SetRange("Profile No.", ProfileNo);
            GroupRule.SetRange(Enabled, true);
            GroupRule.SetRange("Group No.", GroupNo);
            if GroupRule.FindSet() then
                repeat
                    if RuleMatches(Entity, GroupRule, RecRef) then
                        GroupMatched := true;
                until GroupRule.Next() = 0;
            if not GroupMatched then
                exit(false);
        end;
        exit(true);
    end;

    local procedure RuleMatches(Entity: Enum "WZC Sync Entity"; var FilterRule: Record "WZC Sync Filter Rule"; var RecRef: RecordRef): Boolean
    var
        FieldNo: Integer;
        DataType: Enum "WZC Sync Field Data Type";
        ActualText: Text;
        FldRef: FieldRef;
    begin
        if not TryGetFieldInfo(Entity, FilterRule."Field Name", FieldNo, DataType) then
            exit(false);

        FldRef := RecRef.Field(FieldNo);
        ActualText := Format(FldRef.Value);

        case FilterRule.Operator of
            FilterRule.Operator::Equals:
                exit(CompareEquals(ActualText, FilterRule.Value, DataType));
            FilterRule.Operator::NotEquals:
                exit(not CompareEquals(ActualText, FilterRule.Value, DataType));
            FilterRule.Operator::IsEmpty:
                exit(ActualText = '');
            FilterRule.Operator::IsNotEmpty:
                exit(ActualText <> '');
            FilterRule.Operator::InList:
                exit(ValueInList(ActualText, FilterRule.Value));
            FilterRule.Operator::GreaterThan:
                exit(CompareNumeric(ActualText, FilterRule.Value, DataType) > 0);
            FilterRule.Operator::GreaterOrEqual:
                exit(CompareNumeric(ActualText, FilterRule.Value, DataType) >= 0);
            FilterRule.Operator::LessThan:
                exit(CompareNumeric(ActualText, FilterRule.Value, DataType) < 0);
            FilterRule.Operator::LessOrEqual:
                exit(CompareNumeric(ActualText, FilterRule.Value, DataType) <= 0);
        end;
        exit(false);
    end;

    local procedure CompareEquals(ActualText: Text; RuleValue: Text; DataType: Enum "WZC Sync Field Data Type"): Boolean
    begin
        case DataType of
            DataType::Boolean:
                exit(LowerCase(ActualText) = LowerCase(RuleValue));
            else
                exit(UpperCase(ActualText) = UpperCase(RuleValue));
        end;
    end;

    local procedure ValueInList(ActualText: Text; CommaList: Text): Boolean
    var
        Token: Text;
        Pos: Integer;
        Remaining: Text;
    begin
        Remaining := CommaList;
        while Remaining <> '' do begin
            Pos := StrPos(Remaining, ',');
            if Pos = 0 then begin
                Token := Remaining;
                Remaining := '';
            end else begin
                Token := CopyStr(Remaining, 1, Pos - 1);
                Remaining := CopyStr(Remaining, Pos + 1);
            end;
            if UpperCase(DelChr(Token, '<>', ' ')) = UpperCase(ActualText) then
                exit(true);
        end;
        exit(false);
    end;

    local procedure CompareNumeric(ActualText: Text; RuleValue: Text; DataType: Enum "WZC Sync Field Data Type"): Integer
    var
        ActualDecimal: Decimal;
        RuleDecimal: Decimal;
        ActualDate: Date;
        RuleDate: Date;
    begin
        case DataType of
            DataType::Date:
                begin
                    Evaluate(ActualDate, ActualText);
                    Evaluate(RuleDate, RuleValue);
                    if ActualDate > RuleDate then
                        exit(1);
                    if ActualDate < RuleDate then
                        exit(-1);
                    exit(0);
                end;
            else begin
                Evaluate(ActualDecimal, ActualText);
                Evaluate(RuleDecimal, RuleValue);
                if ActualDecimal > RuleDecimal then
                    exit(1);
                if ActualDecimal < RuleDecimal then
                    exit(-1);
                exit(0);
            end;
        end;
    end;

    local procedure IsOperatorAllowedForType(DataType: Enum "WZC Sync Field Data Type"; Operator: Enum "WZC Filter Operator"): Boolean
    begin
        case DataType of
            DataType::Boolean:
                exit(Operator in [Operator::Equals, Operator::NotEquals]);
            DataType::Number:
                exit(Operator in [Operator::Equals, Operator::NotEquals, Operator::GreaterThan,
                    Operator::GreaterOrEqual, Operator::LessThan, Operator::LessOrEqual]);
            DataType::Date:
                exit(Operator in [Operator::Equals, Operator::NotEquals, Operator::GreaterThan,
                    Operator::GreaterOrEqual, Operator::LessThan, Operator::LessOrEqual,
                    Operator::IsEmpty, Operator::IsNotEmpty]);
            DataType::Option:
                exit(Operator in [Operator::Equals, Operator::NotEquals]);
            DataType::Text:
                exit(Operator in [Operator::Equals, Operator::NotEquals, Operator::InList,
                    Operator::IsEmpty, Operator::IsNotEmpty]);
        end;
        exit(false);
    end;

    [TryFunction]
    local procedure TryGetFieldInfo(Entity: Enum "WZC Sync Entity"; FieldName: Text[50]; var FieldNo: Integer; var DataType: Enum "WZC Sync Field Data Type")
    var
        Item: Record Item;
        ShipToAddress: Record "Ship-to Address";
        RecRef: RecordRef;
    begin
        case Entity of
            Entity::ShipToAddress:
                begin
                    RecRef.GetTable(ShipToAddress);
                    case FieldName of
                        'Customer No.':
                            begin
                                FieldNo := ShipToAddress.FieldNo("Customer No.");
                                DataType := DataType::Text;
                            end;
                        'Code':
                            begin
                                FieldNo := ShipToAddress.FieldNo(Code);
                                DataType := DataType::Text;
                            end;
                        'Name':
                            begin
                                FieldNo := ShipToAddress.FieldNo(Name);
                                DataType := DataType::Text;
                            end;
                        'City':
                            begin
                                FieldNo := ShipToAddress.FieldNo(City);
                                DataType := DataType::Text;
                            end;
                        'County':
                            begin
                                FieldNo := ShipToAddress.FieldNo(County);
                                DataType := DataType::Text;
                            end;
                        'Post Code':
                            begin
                                FieldNo := ShipToAddress.FieldNo("Post Code");
                                DataType := DataType::Text;
                            end;
                        'Country/Region Code':
                            begin
                                FieldNo := ShipToAddress.FieldNo("Country/Region Code");
                                DataType := DataType::Text;
                            end;
                        'Location Code':
                            begin
                                FieldNo := ShipToAddress.FieldNo("Location Code");
                                DataType := DataType::Text;
                            end;
                        else
                            Error(FieldNotAllowedErr, FieldName, Entity);
                    end;
                end;
            Entity::Product:
                begin
                    RecRef.GetTable(Item);
                    case FieldName of
                        'No.':
                            begin
                                FieldNo := Item.FieldNo("No.");
                                DataType := DataType::Text;
                            end;
                        'Description':
                            begin
                                FieldNo := Item.FieldNo(Description);
                                DataType := DataType::Text;
                            end;
                        'Type':
                            begin
                                FieldNo := Item.FieldNo(Type);
                                DataType := DataType::Option;
                            end;
                        'Blocked':
                            begin
                                FieldNo := Item.FieldNo(Blocked);
                                DataType := DataType::Boolean;
                            end;
                        'Sales Blocked':
                            begin
                                FieldNo := Item.FieldNo("Sales Blocked");
                                DataType := DataType::Boolean;
                            end;
                        'Item Category Code':
                            begin
                                FieldNo := Item.FieldNo("Item Category Code");
                                DataType := DataType::Text;
                            end;
                        'Base Unit of Measure':
                            begin
                                FieldNo := Item.FieldNo("Base Unit of Measure");
                                DataType := DataType::Text;
                            end;
                        'Inventory':
                            begin
                                FieldNo := Item.FieldNo(Inventory);
                                DataType := DataType::Number;
                            end;
                        'Vendor No.':
                            begin
                                FieldNo := Item.FieldNo("Vendor No.");
                                DataType := DataType::Text;
                            end;
                        'Global Dimension 1 Code':
                            begin
                                FieldNo := Item.FieldNo("Global Dimension 1 Code");
                                DataType := DataType::Text;
                            end;
                        'Global Dimension 2 Code':
                            begin
                                FieldNo := Item.FieldNo("Global Dimension 2 Code");
                                DataType := DataType::Text;
                            end;
                        else
                            Error(FieldNotAllowedErr, FieldName, Entity);
                    end;
                end;
            else
                Error(EntityNotWiredErr, Entity);
        end;
    end;
}
