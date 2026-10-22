codeunit 50116 "WZC Sync Tests"
{
    Subtype = Test;

    [Test]
    procedure NoFieldVisibilityConfigShowsEverything()
    var
        FieldVisibility: Codeunit "WZC Field Visibility Mgt";
    begin
        if not FieldVisibility.IsFieldVisible('TESTFV_NONE', 'anyFieldAtAll') then
            Error('Expected every field to be visible by default when no WZC Field Visibility rows exist for this Api Operation.');
    end;

    [Test]
    procedure FieldVisibilityConfigActsAsWhitelist()
    var
        Config: Record "WZC Field Visibility";
        FieldVisibility: Codeunit "WZC Field Visibility Mgt";
    begin
        // Tenant configures only 'country' and 'county' as visible for this API -
        // mirrors "Tenant A needs country and state" from the real request.
        Config.Init();
        Config."Api Operation" := 'TESTFV_SOME';
        Config."Field Name" := 'country';
        Config.Visible := true;
        Config.Insert(true);

        Config.Init();
        Config."Api Operation" := 'TESTFV_SOME';
        Config."Field Name" := 'county';
        Config.Visible := true;
        Config.Insert(true);

        if not FieldVisibility.IsFieldVisible('TESTFV_SOME', 'country') then
            Error('Expected ''country'' to be visible - it was explicitly configured Visible = true.');
        if not FieldVisibility.IsFieldVisible('TESTFV_SOME', 'county') then
            Error('Expected ''county'' to be visible - it was explicitly configured Visible = true.');
        if FieldVisibility.IsFieldVisible('TESTFV_SOME', 'name') then
            Error('Expected ''name'' to be hidden - once ANY row exists for this Api Operation, unlisted fields are no longer shown by default.');
    end;

    [Test]
    procedure DisallowedFieldIsRejected()
    var
        Engine: Codeunit "WZC Sync Filter Engine";
    begin
        if TryCheckField(Engine, "WZC Sync Entity"::Product, 'Not A Real Field') then
            Error('Expected an error for a field not in the allowlist, but it succeeded.');
    end;

    [Test]
    procedure DisallowedOperatorIsRejected()
    var
        Engine: Codeunit "WZC Sync Filter Engine";
        Operator: Enum "WZC Filter Operator";
    begin
        // Description is Text - GreaterThan is not a valid Text operator
        if TryCheckOperator(Engine, "WZC Sync Entity"::Product, 'Description', Operator::GreaterThan) then
            Error('Expected an error for GreaterThan on a Text field, but it succeeded.');
    end;

    [Test]
    procedure AndAcrossGroupsOrWithinGroupMatchesCorrectly()
    var
        Profile: Record "WZC Sync Profile";
        MatchingItem: Record Item;
        NonMatchingItem: Record Item;
        Engine: Codeunit "WZC Sync Filter Engine";
        Item: Record Item;
        Count: Integer;
    begin
        // Profile: (ItemCategoryCode = 'CATA' OR ItemCategoryCode = 'CATB') AND Blocked = false
        CreateProfile(Profile, 'TESTAND1', 'ITEMAVAIL');
        AddRule(Profile."Profile No.", 10000, 10000, 'Item Category Code', "WZC Filter Operator"::Equals, 'CATA');
        AddRule(Profile."Profile No.", 20000, 10000, 'Item Category Code', "WZC Filter Operator"::Equals, 'CATB');
        AddRule(Profile."Profile No.", 30000, 30000, 'Blocked', "WZC Filter Operator"::Equals, 'false');

        CreateTestItem(MatchingItem, 'CATB', false);
        CreateTestItem(NonMatchingItem, 'CATC', false);

        Count := Engine.ApplyProfileToItem(Profile, 0DT, 0DT, Item);

        Item.SetRange("No.", MatchingItem."No.");
        if Item.IsEmpty() then
            Error('Expected the OR-matched, non-blocked item to be included, but it was not.');

        Item.Reset();
        Item.MarkedOnly(true);
        Item.SetRange("No.", NonMatchingItem."No.");
        if not Item.IsEmpty() then
            Error('Expected the item with a non-matching category to be excluded, but it was included.');
    end;

    [Test]
    procedure ShipToAddressCityFilterMatchesCorrectly()
    var
        Profile: Record "WZC Sync Profile";
        MatchingShipTo: Record "Ship-to Address";
        NonMatchingShipTo: Record "Ship-to Address";
        Engine: Codeunit "WZC Sync Filter Engine";
        ShipToAddress: Record "Ship-to Address";
        Count: Integer;
    begin
        CreateProfile(Profile, 'TESTCITY1', 'SHIPTOADDR');
        Profile.Entity := Profile.Entity::ShipToAddress;
        Profile.Modify(true);
        AddRule(Profile."Profile No.", 10000, 10000, 'City', "WZC Filter Operator"::Equals, 'Cheltenham');

        CreateTestShipToAddress(MatchingShipTo, 'WZCTESTCUST', 'Cheltenham');
        CreateTestShipToAddress(NonMatchingShipTo, 'WZCTESTCUST', 'London');

        Count := Engine.ApplyProfileToShipToAddress(Profile, 0DT, 0DT, ShipToAddress);

        ShipToAddress.SetRange(Code, MatchingShipTo.Code);
        if ShipToAddress.IsEmpty() then
            Error('Expected the Cheltenham ship-to to be included, but it was not.');

        ShipToAddress.Reset();
        ShipToAddress.MarkedOnly(true);
        ShipToAddress.SetRange(Code, NonMatchingShipTo.Code);
        if not ShipToAddress.IsEmpty() then
            Error('Expected the London ship-to to be excluded, but it was included.');
    end;

    [Test]
    procedure CheckpointDoesNotAdvanceOnFailure()
    var
        Profile: Record "WZC Sync Profile";
        Checkpoint: Record "WZC Sync Checkpoint";
        RunLog: Record "WZC Sync Run Log";
        CheckpointMgt: Codeunit "WZC Checkpoint Mgt";
        LowerBound: DateTime;
        UpperBound: DateTime;
    begin
        CreateProfile(Profile, 'TESTCP1', 'ITEMAVAIL');
        Profile."Sync Mode" := Profile."Sync Mode"::Incremental;
        Profile.Modify(true);

        CheckpointMgt.GetSyncWindow(Profile, LowerBound, UpperBound);
        CheckpointMgt.StartRun(Profile, UpperBound, LowerBound, RunLog);
        CheckpointMgt.CompleteRun(RunLog, false, 0, 'Simulated failure');

        Checkpoint.Get(Profile."Profile No.");
        if Checkpoint."Last Checkpoint DateTime" <> 0DT then
            Error('Expected the checkpoint to stay at 0DT after a failed run, but it advanced.');
        if Checkpoint."Run In Progress" then
            Error('Expected Run In Progress to be cleared after CompleteRun, but it is still set.');
    end;

    [Test]
    procedure CheckpointAdvancesOnSuccess()
    var
        Profile: Record "WZC Sync Profile";
        Checkpoint: Record "WZC Sync Checkpoint";
        RunLog: Record "WZC Sync Run Log";
        CheckpointMgt: Codeunit "WZC Checkpoint Mgt";
        LowerBound: DateTime;
        UpperBound: DateTime;
    begin
        CreateProfile(Profile, 'TESTCP2', 'ITEMAVAIL');
        Profile."Sync Mode" := Profile."Sync Mode"::Incremental;
        Profile.Modify(true);

        CheckpointMgt.GetSyncWindow(Profile, LowerBound, UpperBound);
        CheckpointMgt.StartRun(Profile, UpperBound, LowerBound, RunLog);
        CheckpointMgt.CompleteRun(RunLog, true, 3, '');

        Checkpoint.Get(Profile."Profile No.");
        if Checkpoint."Last Checkpoint DateTime" <> UpperBound then
            Error('Expected the checkpoint to advance to the run''s upper bound on success.');
        if Checkpoint."Last Successful Run Count" <> 3 then
            Error('Expected Last Successful Run Count to be 3.');
    end;

    [Test]
    procedure ConcurrentRunIsRejectedUnlessStale()
    var
        Profile: Record "WZC Sync Profile";
        RunLog1: Record "WZC Sync Run Log";
        RunLog2: Record "WZC Sync Run Log";
        CheckpointMgt: Codeunit "WZC Checkpoint Mgt";
        LowerBound: DateTime;
        UpperBound: DateTime;
    begin
        CreateProfile(Profile, 'TESTCONC1', 'ITEMAVAIL');

        CheckpointMgt.GetSyncWindow(Profile, LowerBound, UpperBound);
        CheckpointMgt.StartRun(Profile, UpperBound, LowerBound, RunLog1);

        if TryStartRun(CheckpointMgt, Profile, UpperBound, LowerBound, RunLog2) then
            Error('Expected a second StartRun on the same profile to be rejected while the first is still running.');
    end;

    [Test]
    procedure ResetCheckpointClearsWatermark()
    var
        Profile: Record "WZC Sync Profile";
        Checkpoint: Record "WZC Sync Checkpoint";
        RunLog: Record "WZC Sync Run Log";
        CheckpointMgt: Codeunit "WZC Checkpoint Mgt";
        LowerBound: DateTime;
        UpperBound: DateTime;
    begin
        CreateProfile(Profile, 'TESTRESET1', 'ITEMAVAIL');
        Profile."Sync Mode" := Profile."Sync Mode"::Incremental;
        Profile.Modify(true);

        CheckpointMgt.GetSyncWindow(Profile, LowerBound, UpperBound);
        CheckpointMgt.StartRun(Profile, UpperBound, LowerBound, RunLog);
        CheckpointMgt.CompleteRun(RunLog, true, 1, '');

        CheckpointMgt.ResetCheckpoint(Profile."Profile No.", 'test');

        Checkpoint.Get(Profile."Profile No.");
        if Checkpoint."Last Checkpoint DateTime" <> 0DT then
            Error('Expected Reset Checkpoint to clear the watermark back to 0DT.');
    end;

    [Test]
    procedure FullSyncModeIgnoresCheckpointWatermark()
    var
        Profile: Record "WZC Sync Profile";
        Checkpoint: Record "WZC Sync Checkpoint";
        CheckpointMgt: Codeunit "WZC Checkpoint Mgt";
        LowerBound: DateTime;
        UpperBound: DateTime;
    begin
        CreateProfile(Profile, 'TESTFULL1', 'ITEMAVAIL');
        Profile."Sync Mode" := Profile."Sync Mode"::Full;
        Profile.Modify(true);

        Checkpoint.Init();
        Checkpoint."Profile No." := Profile."Profile No.";
        Checkpoint."Last Checkpoint DateTime" := CurrentDateTime();
        Checkpoint.Insert();

        CheckpointMgt.GetSyncWindow(Profile, LowerBound, UpperBound);

        if LowerBound <> 0DT then
            Error('Expected a Full Sync profile to ignore any existing checkpoint and use 0DT as the lower bound.');
    end;

    [Test]
    procedure ConfigVersionBumpsOnMeaningfulChangeOnly()
    var
        Profile: Record "WZC Sync Profile";
        VersionAfterCosmetic: Integer;
        VersionAfterMeaningful: Integer;
    begin
        CreateProfile(Profile, 'TESTVER1', 'ITEMAVAIL');
        VersionAfterCosmetic := Profile."Config Version";

        Profile.Description := 'Renamed, nothing else changed';
        Profile.Modify(true);
        if Profile."Config Version" <> VersionAfterCosmetic then
            Error('Expected Config Version to stay the same after a cosmetic-only change (Description).');

        Profile.Direction := Profile.Direction::Push;
        Profile.Modify(true);
        VersionAfterMeaningful := Profile."Config Version";
        if VersionAfterMeaningful <= VersionAfterCosmetic then
            Error('Expected Config Version to increase after a meaningful change (Direction).');
    end;

    local procedure CreateProfile(var Profile: Record "WZC Sync Profile"; ProfileNo: Code[20]; ApiOperation: Code[30])
    begin
        if Profile.Get(ProfileNo) then
            Profile.Delete(true);

        Profile.Init();
        Profile."Profile No." := ProfileNo;
        Profile.Description := 'Test profile';
        Profile.Entity := Profile.Entity::Product;
        Profile."Api Operation" := ApiOperation;
        Profile.Direction := Profile.Direction::Pull;
        Profile."Sync Mode" := Profile."Sync Mode"::Full;
        Profile.Enabled := true;
        Profile.Insert(true);
    end;

    local procedure AddRule(ProfileNo: Code[20]; LineNo: Integer; GroupNo: Integer; FieldName: Text[50]; Operator: Enum "WZC Filter Operator"; Value: Text[250])
    var
        Rule: Record "WZC Sync Filter Rule";
    begin
        Rule.Init();
        Rule."Profile No." := ProfileNo;
        Rule."Line No." := LineNo;
        Rule."Group No." := GroupNo;
        Rule."Field Name" := FieldName;
        Rule.Operator := Operator;
        Rule.Value := Value;
        Rule.Enabled := true;
        Rule.Insert(true);
    end;

    local procedure CreateTestItem(var Item: Record Item; CategoryCode: Code[20]; Blocked: Boolean)
    begin
        Item.Init();
        Item."No." := CopyStr('WZCT' + Format(Random(999999)), 1, 20);
        Item.Description := 'WZC Test Item';
        Item."Item Category Code" := CategoryCode;
        Item.Blocked := Blocked;
        Item.Insert(true);
    end;

    local procedure CreateTestShipToAddress(var ShipToAddress: Record "Ship-to Address"; CustomerNo: Code[20]; City: Text[30])
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(CustomerNo) then begin
            Customer.Init();
            Customer."No." := CustomerNo;
            Customer.Name := 'WZC Test Customer';
            Customer.Insert(true);
        end;

        ShipToAddress.Init();
        ShipToAddress."Customer No." := CustomerNo;
        ShipToAddress.Code := CopyStr('T' + Format(Random(999999)), 1, 10);
        ShipToAddress.Name := 'WZC Test Ship-to';
        ShipToAddress.City := City;
        ShipToAddress.Insert(true);
    end;

    [TryFunction]
    local procedure TryCheckField(Engine: Codeunit "WZC Sync Filter Engine"; Entity: Enum "WZC Sync Entity"; FieldName: Text[50])
    begin
        Engine.CheckFieldAllowed(Entity, FieldName);
    end;

    [TryFunction]
    local procedure TryCheckOperator(Engine: Codeunit "WZC Sync Filter Engine"; Entity: Enum "WZC Sync Entity"; FieldName: Text[50]; Operator: Enum "WZC Filter Operator")
    begin
        Engine.CheckOperatorAllowed(Entity, FieldName, Operator);
    end;

    [TryFunction]
    local procedure TryStartRun(var CheckpointMgt: Codeunit "WZC Checkpoint Mgt"; Profile: Record "WZC Sync Profile"; UpperBound: DateTime; LowerBound: DateTime; var RunLog: Record "WZC Sync Run Log")
    begin
        CheckpointMgt.StartRun(Profile, UpperBound, LowerBound, RunLog);
    end;
}
