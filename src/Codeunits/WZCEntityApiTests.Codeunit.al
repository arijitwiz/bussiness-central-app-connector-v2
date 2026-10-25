codeunit 50134 "WZC Entity Api Tests"
{
    Subtype = Test;

    [Test]
    procedure CustomerPriceGroupFilterMatchesCorrectly()
    var
        Profile: Record "WZC Sync Profile";
        Matching: Record Customer;
        NonMatching: Record Customer;
        Customer: Record Customer;
        Engine: Codeunit "WZC Sync Filter Engine";
    begin
        // Browne's real rule: only customers in price group RTMASTER are synced.
        CreateProfile(Profile, 'TESTCUST1', 'CUSTOMER', "WZC Sync Entity"::Customer);
        AddRule(Profile."Profile No.", 10000, 10000, 'Customer Price Group', "WZC Filter Operator"::Equals, 'RTMASTER');

        CreateTestCustomer(Matching, 'RTMASTER');
        CreateTestCustomer(NonMatching, 'RETAIL');

        Engine.ApplyProfileToCustomer(Profile, 0DT, 0DT, Customer);

        Customer.SetRange("No.", Matching."No.");
        if Customer.IsEmpty() then
            Error('Expected the RTMASTER customer to be included, but it was not.');

        Customer.SetRange("No.", NonMatching."No.");
        if not Customer.IsEmpty() then
            Error('Expected the RETAIL customer to be excluded, but it was included.');
    end;

    [Test]
    procedure NewFilterFieldsAreAllowed()
    var
        Engine: Codeunit "WZC Sync Filter Engine";
    begin
        Engine.CheckFieldAllowed("WZC Sync Entity"::Product, 'WZC Sell On Website');
        Engine.CheckFieldAllowed("WZC Sync Entity"::Customer, 'Customer Price Group');
        Engine.CheckFieldAllowed("WZC Sync Entity"::Customer, 'WZC Web Customer');
        Engine.CheckOperatorAllowed("WZC Sync Entity"::Product, 'WZC Sell On Website', "WZC Filter Operator"::Equals);
    end;

    [Test]
    procedure CustomerEntityIsWiredForApiOperations()
    var
        Engine: Codeunit "WZC Sync Filter Engine";
        Entity: Enum "WZC Sync Entity";
    begin
        if not Engine.TryGetEntityForApiOperation('CUSTOMER', Entity) or (Entity <> Entity::Customer) then
            Error('CUSTOMER must map to the Customer entity.');
        if not Engine.TryGetEntityForApiOperation('INVFEED', Entity) or (Entity <> Entity::Product) then
            Error('INVFEED must map to the Product entity.');
        if not Engine.IsEntityWired(Entity::Customer) then
            Error('Customer entity must be wired into the filter engine.');
    end;

    [Test]
    procedure OrderWriteFindsExistingOrderByExternalId()
    var
        SalesHeader: Record "Sales Header";
        Found: Record "Sales Header";
        OrderWriteMgt: Codeunit "WZC Order Write Mgt";
        ExternalId: Code[50];
    begin
        ExternalId := CopyStr('WZCDOC-' + Format(Random(999999)), 1, 50);
        CreateTestOrder(SalesHeader, ExternalId);

        if not OrderWriteMgt.FindExistingOrderByExternalId(ExternalId, Found) then
            Error('Expected search-before-create to find the order carrying external id %1.', ExternalId);
        if Found."No." <> SalesHeader."No." then
            Error('Expected order %1 to be adopted, got %2.', SalesHeader."No.", Found."No.");

        if OrderWriteMgt.FindExistingOrderByExternalId('', Found) then
            Error('A blank external id must never match an existing order.');
        if OrderWriteMgt.FindExistingOrderByExternalId('WZC-NO-SUCH-ID', Found) then
            Error('An unknown external id must not match an existing order.');
    end;

    [Test]
    procedure OrderNotesAreWrittenAsCommentLinesIdempotently()
    var
        SalesHeader: Record "Sales Header";
        SalesCommentLine: Record "Sales Comment Line";
        OrderWriteMgt: Codeunit "WZC Order Write Mgt";
        Notes: Text;
        i: Integer;
    begin
        CreateTestOrder(SalesHeader, CopyStr('WZCDOC-' + Format(Random(999999)), 1, 50));

        // Pre-existing manual comment must survive untouched.
        SalesCommentLine.Init();
        SalesCommentLine."Document Type" := SalesCommentLine."Document Type"::Order;
        SalesCommentLine."No." := SalesHeader."No.";
        SalesCommentLine."Line No." := 10000;
        SalesCommentLine.Comment := 'Manual comment';
        SalesCommentLine.Insert();

        for i := 1 to 200 do
            Notes += 'x';
        SalesHeader."WZC Order Notes" := CopyStr(Notes, 1, MaxStrLen(SalesHeader."WZC Order Notes"));
        SalesHeader.Modify();

        OrderWriteMgt.WriteNotesAsComments(SalesHeader);
        OrderWriteMgt.WriteNotesAsComments(SalesHeader); // second call must replace, not append

        SalesCommentLine.Reset();
        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::Order);
        SalesCommentLine.SetRange("No.", SalesHeader."No.");
        SalesCommentLine.SetRange(Code, 'WZC');
        if SalesCommentLine.Count() <> 3 then
            Error('Expected 200 chars of notes to become 3 WZC comment lines (80+80+40), got %1.', SalesCommentLine.Count());

        SalesCommentLine.SetRange(Code, '');
        if SalesCommentLine.Count() <> 1 then
            Error('Manual comment lines must not be touched by WZC note writes.');
    end;

    [Test]
    procedure AvailabilityCalcSubtractsDemandAndAddsSupply()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        AvailabilityCalc: Codeunit "WZC Availability Calc";
        Available: Decimal;
        AvailableInv: Decimal;
        Projected: Decimal;
    begin
        CreateTestItem(Item);

        SalesLine.Init();
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := CopyStr('WZCSO' + Format(Random(999999)), 1, 20);
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine."Outstanding Qty. (Base)" := 5;
        SalesLine.Insert();

        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine."Document No." := CopyStr('WZCPO' + Format(Random(999999)), 1, 20);
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := Item."No.";
        PurchaseLine."Outstanding Qty. (Base)" := 7;
        PurchaseLine.Insert();

        AvailabilityCalc.Calculate(Item, Available, AvailableInv, Projected);

        if Available <> -5 then
            Error('Expected availableQuantity = 0 on hand - 5 on sales order = -5, got %1.', Available);
        if Projected <> 2 then
            Error('Expected projectedAvailableQuantity = -5 + 7 inbound = 2, got %1.', Projected);
    end;

    [Test]
    procedure BlankHiddenFieldsBlanksOnlyHiddenFields()
    var
        Config: Record "WZC Field Visibility";
        Item: Record Item;
        ApiBase: Codeunit "WZC Api Base";
        RecRef: RecordRef;
        FieldMap: Dictionary of [Code[50], Integer];
    begin
        // Tenant exposes displayName only for this API.
        Config.Init();
        Config."Api Operation" := 'TESTFV_BLANK';
        Config."Field Name" := 'displayName';
        Config.Visible := true;
        Config.Insert(true);

        Item.Init();
        Item.Description := 'Keep me';
        Item."Description 2" := 'Hide me';
        Item."Unit Price" := 9.5;

        FieldMap.Add('displayName', Item.FieldNo(Description));
        FieldMap.Add('description2', Item.FieldNo("Description 2"));
        FieldMap.Add('unitPrice', Item.FieldNo("Unit Price"));

        RecRef.GetTable(Item);
        ApiBase.BlankHiddenFields('TESTFV_BLANK', RecRef, FieldMap);
        RecRef.SetTable(Item);

        if Item.Description <> 'Keep me' then
            Error('Visible field must be kept.');
        if Item."Description 2" <> '' then
            Error('Hidden text field must be blanked.');
        if Item."Unit Price" <> 0 then
            Error('Hidden decimal field must be zeroed.');
    end;

    [Test]
    procedure BlankHiddenFieldsIsNoOpWithoutConfig()
    var
        Item: Record Item;
        ApiBase: Codeunit "WZC Api Base";
        RecRef: RecordRef;
        FieldMap: Dictionary of [Code[50], Integer];
    begin
        Item.Init();
        Item."Description 2" := 'Still here';
        FieldMap.Add('description2', Item.FieldNo("Description 2"));

        RecRef.GetTable(Item);
        ApiBase.BlankHiddenFields('TESTFV_NOCONFIG', RecRef, FieldMap);
        RecRef.SetTable(Item);

        if Item."Description 2" <> 'Still here' then
            Error('With no Field Visibility rows for the API, every field must stay visible (code default).');
    end;

    local procedure CreateProfile(var Profile: Record "WZC Sync Profile"; ProfileNo: Code[20]; ApiOperation: Code[30]; Entity: Enum "WZC Sync Entity")
    begin
        if Profile.Get(ProfileNo) then
            Profile.Delete(true);

        Profile.Init();
        Profile."Profile No." := ProfileNo;
        Profile.Description := 'Test profile';
        Profile.Entity := Entity;
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

    local procedure CreateTestCustomer(var Customer: Record Customer; PriceGroup: Code[10])
    begin
        Customer.Init();
        Customer."No." := CopyStr('WZCC' + Format(Random(999999)), 1, 20);
        Customer.Name := 'WZC Test Customer';
        Customer."Customer Price Group" := PriceGroup;
        Customer.Insert(true);
    end;

    local procedure CreateTestItem(var Item: Record Item)
    begin
        Item.Init();
        Item."No." := CopyStr('WZCT' + Format(Random(999999)), 1, 20);
        Item.Description := 'WZC Test Item';
        Item.Insert(true);
    end;

    local procedure CreateTestOrder(var SalesHeader: Record "Sales Header"; ExternalId: Code[50])
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := CopyStr('WZCO' + Format(Random(999999)), 1, 20);
        SalesHeader."WZC External Id" := ExternalId;
        SalesHeader."WZC Source" := 'TEST';
        SalesHeader.Insert();
    end;
}
