codeunit 50111 "WZC Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.SeedAllApiConfigs();
        SeedExampleAttributeMapping();
        SeedSyncTemplates();
    end;

    local procedure SeedExampleAttributeMapping()
    begin
        SeedAttrMapping('CreateAddress', 'CREATEADDRESS', "WZC Attribute Data Type"::Boolean, 'false');
        SeedAttrMapping('DeliveryInstructions', 'DELIVERYINSTRUCTIONS', "WZC Attribute Data Type"::Text, '');
    end;

    local procedure SeedAttrMapping(LogicalName: Code[50]; TenantName: Code[50]; DataType: Enum "WZC Attribute Data Type"; DefaultValue: Text[250])
    var
        Mapping: Record "WZC Attribute Mapping";
    begin
        if Mapping.Get('SHIPTOADDR', LogicalName) then
            exit;

        Mapping.Init();
        Mapping.Entity := 'SHIPTOADDR';
        Mapping."Logical Name" := LogicalName;
        Mapping."Tenant Attribute Name" := TenantName;
        Mapping."Data Type" := DataType;
        Mapping."Default Value" := CopyStr(DefaultValue, 1, MaxStrLen(Mapping."Default Value"));
        Mapping.Required := false;
        Mapping."Sync Direction" := Mapping."Sync Direction"::Both;
        Mapping."Storage Mode" := Mapping."Storage Mode"::Flexible;
        Mapping.Enabled := true;
        Mapping.Insert(true);
    end;

    /// <summary>
    /// Seeds Product-entity templates only. Ship-to Addresses and Prices templates are
    /// deliberately NOT seeded yet - those entities aren't wired into the filter engine
    /// in this version, and a template for an entity that can't actually be filtered
    /// would be misleading.
    /// </summary>
    local procedure SeedSyncTemplates()
    begin
        SeedTemplate('TPL_FULL_SYNC', 'Full Sync - All Products', "WZC Sync Entity"::Product, 'ITEMAVAIL');
        SeedTemplate('TPL_INCREMENTAL', 'Incremental Sync - All Products', "WZC Sync Entity"::Product, 'ITEMAVAIL');
        SeedActiveProductsTemplate();
    end;

    local procedure SeedTemplate(ProfileNo: Code[20]; Description: Text[100]; Entity: Enum "WZC Sync Entity"; ApiOperation: Code[30])
    var
        Profile: Record "WZC Sync Profile";
    begin
        if Profile.Get(ProfileNo) then
            exit;

        Profile.Init();
        Profile."Profile No." := ProfileNo;
        Profile.Description := Description;
        Profile.Entity := Entity;
        Profile."Api Operation" := ApiOperation;
        Profile.Direction := Profile.Direction::Pull;
        if ProfileNo = 'TPL_INCREMENTAL' then
            Profile."Sync Mode" := Profile."Sync Mode"::Incremental
        else
            Profile."Sync Mode" := Profile."Sync Mode"::Full;
        Profile."Is Template" := true;
        Profile.Enabled := false;
        Profile.Insert(true);
    end;

    local procedure SeedActiveProductsTemplate()
    var
        Profile: Record "WZC Sync Profile";
        Rule1: Record "WZC Sync Filter Rule";
        Rule2: Record "WZC Sync Filter Rule";
    begin
        if Profile.Get('TPL_ACTIVE_PRODUCTS') then
            exit;

        Profile.Init();
        Profile."Profile No." := 'TPL_ACTIVE_PRODUCTS';
        Profile.Description := 'Active Products Only';
        Profile.Entity := Profile.Entity::Product;
        Profile."Api Operation" := 'ITEMAVAIL';
        Profile.Direction := Profile.Direction::Pull;
        Profile."Sync Mode" := Profile."Sync Mode"::Incremental;
        Profile."Is Template" := true;
        Profile.Enabled := false;
        Profile.Insert(true);

        Rule1.Init();
        Rule1."Profile No." := Profile."Profile No.";
        Rule1."Line No." := 10000;
        Rule1."Group No." := 10000;
        Rule1."Field Name" := 'Blocked';
        Rule1.Operator := Rule1.Operator::Equals;
        Rule1.Value := 'false';
        Rule1.Enabled := true;
        Rule1.Insert(true);

        Rule2.Init();
        Rule2."Profile No." := Profile."Profile No.";
        Rule2."Line No." := 20000;
        Rule2."Group No." := 20000;
        Rule2."Field Name" := 'Sales Blocked';
        Rule2.Operator := Rule2.Operator::Equals;
        Rule2.Value := 'false';
        Rule2.Enabled := true;
        Rule2.Insert(true);
    end;
}
