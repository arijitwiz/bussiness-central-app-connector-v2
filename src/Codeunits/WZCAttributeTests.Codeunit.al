codeunit 50113 "WZC Attribute Tests"
{
    Subtype = Test;

    var
        AttrMgt: Codeunit "WZC Attribute Mgt";

    [Test]
    procedure RequiredAttributeBlankValueFails()
    var
        ShipTo: Record "Ship-to Address";
        Mapping: Record "WZC Attribute Mapping";
        AttrValue: Record "WZC Ship-to Attribute";
    begin
        CreateTestShipTo(ShipTo);
        CreateMapping(Mapping, 'ReqTest', 'Required_Attr', Mapping."Data Type"::Text, true, Mapping."Storage Mode"::Flexible);

        AttrValue.Init();
        AttrValue."Customer No." := ShipTo."Customer No.";
        AttrValue."Ship-to Code" := ShipTo.Code;
        AttrValue."Attribute Name" := 'Required_Attr';
        AttrValue."Attribute Value" := '';
        AttrValue."Data Type" := Mapping."Data Type"::Text;

        if TryInsertAttribute(AttrValue) then
            Error('Expected an error inserting a blank value for a required attribute, but it succeeded.');
    end;

    [Test]
    procedure InvalidNumberValueFails()
    var
        ShipTo: Record "Ship-to Address";
        Mapping: Record "WZC Attribute Mapping";
        AttrValue: Record "WZC Ship-to Attribute";
    begin
        CreateTestShipTo(ShipTo);
        CreateMapping(Mapping, 'NumTest', 'Number_Attr', Mapping."Data Type"::Number, false, Mapping."Storage Mode"::Flexible);

        AttrValue.Init();
        AttrValue."Customer No." := ShipTo."Customer No.";
        AttrValue."Ship-to Code" := ShipTo.Code;
        AttrValue."Attribute Name" := 'Number_Attr';
        AttrValue."Attribute Value" := 'not-a-number';
        AttrValue."Data Type" := Mapping."Data Type"::Number;

        if TryInsertAttribute(AttrValue) then
            Error('Expected an error inserting a non-numeric value for a Number attribute, but it succeeded.');
    end;

    [Test]
    procedure BooleanValueNormalizesToLowerCase()
    var
        ShipTo: Record "Ship-to Address";
        Mapping: Record "WZC Attribute Mapping";
        AttrValue: Record "WZC Ship-to Attribute";
    begin
        CreateTestShipTo(ShipTo);
        CreateMapping(Mapping, 'BoolTest', 'Bool_Attr', Mapping."Data Type"::Boolean, false, Mapping."Storage Mode"::Flexible);

        AttrValue.Init();
        AttrValue."Customer No." := ShipTo."Customer No.";
        AttrValue."Ship-to Code" := ShipTo.Code;
        AttrValue."Attribute Name" := 'Bool_Attr';
        AttrValue."Attribute Value" := 'TRUE';
        AttrValue."Data Type" := Mapping."Data Type"::Boolean;
        AttrValue.Insert(true);

        if AttrValue."Attribute Value" <> 'true' then
            Error('Expected ''TRUE'' to normalize to ''true'', got ''%1''.', AttrValue."Attribute Value");
    end;

    [Test]
    procedure DuplicateTenantAttributeNameFails()
    var
        Mapping1: Record "WZC Attribute Mapping";
        Mapping2: Record "WZC Attribute Mapping";
    begin
        CreateMapping(Mapping1, 'DupLogical1', 'Dup_Attr_Name', Mapping1."Data Type"::Text, false, Mapping1."Storage Mode"::Flexible);

        Mapping2.Init();
        Mapping2.Entity := 'SHIPTOADDR';
        Mapping2."Logical Name" := 'DupLogical2';
        Mapping2."Tenant Attribute Name" := 'Dup_Attr_Name';
        Mapping2."Data Type" := Mapping2."Data Type"::Text;
        Mapping2."Storage Mode" := Mapping2."Storage Mode"::Flexible;

        if TryInsertMapping(Mapping2) then
            Error('Expected an error creating two mappings with the same Attribute Name, but it succeeded.');
    end;

    [Test]
    procedure UnsupportedRealFieldLogicalNameFails()
    var
        Mapping: Record "WZC Attribute Mapping";
    begin
        Mapping.Init();
        Mapping.Entity := 'SHIPTOADDR';
        Mapping."Logical Name" := 'SomeOtherField';
        Mapping."Tenant Attribute Name" := 'Some_Other_Field';
        Mapping."Data Type" := Mapping."Data Type"::Text;
        Mapping."Storage Mode" := Mapping."Storage Mode"::RealField;

        if TryInsertMapping(Mapping) then
            Error('Expected an error setting Storage Mode = RealField on a logical name with no real field, but it succeeded.');
    end;

    [Test]
    procedure WritingToRealFieldBackedAttributeFails()
    var
        ShipTo: Record "Ship-to Address";
        Mapping: Record "WZC Attribute Mapping";
        AttrValue: Record "WZC Ship-to Attribute";
    begin
        CreateTestShipTo(ShipTo);
        CreateMapping(Mapping, 'CreateAddress', 'WizCommerce_Create_Address', Mapping."Data Type"::Boolean, false, Mapping."Storage Mode"::RealField);

        AttrValue.Init();
        AttrValue."Customer No." := ShipTo."Customer No.";
        AttrValue."Ship-to Code" := ShipTo.Code;
        AttrValue."Attribute Name" := 'WizCommerce_Create_Address';
        AttrValue."Attribute Value" := 'true';
        AttrValue."Data Type" := Mapping."Data Type"::Boolean;

        if TryInsertAttribute(AttrValue) then
            Error('Expected an error writing to a RealField-mode attribute through the generic table, but it succeeded.');
    end;

    [Test]
    procedure UndeclaredAttributeAutoDiscovers()
    var
        ShipTo: Record "Ship-to Address";
        AttrValue: Record "WZC Ship-to Attribute";
        Mapping: Record "WZC Attribute Mapping";
    begin
        CreateTestShipTo(ShipTo);

        AttrValue.Init();
        AttrValue."Customer No." := ShipTo."Customer No.";
        AttrValue."Ship-to Code" := ShipTo.Code;
        AttrValue."Attribute Name" := 'NeverConfiguredBefore';
        AttrValue."Attribute Value" := 'some value';
        AttrValue."Data Type" := AttrValue."Data Type"::Text;
        AttrValue.Insert(true);

        if not Mapping.Get('SHIPTOADDR', 'NeverConfiguredBefore') then
            Error('Expected an auto-discovered mapping to be created, but none was found.');
        if Mapping.Enabled then
            Error('Expected the auto-discovered mapping to be disabled by default.');
        if not Mapping."Auto Discovered" then
            Error('Expected the auto-discovered mapping to be flagged as Auto Discovered.');
    end;

    [Test]
    procedure DisabledAttributeRejectsWrite()
    var
        ShipTo: Record "Ship-to Address";
        Mapping: Record "WZC Attribute Mapping";
        AttrValue: Record "WZC Ship-to Attribute";
    begin
        CreateTestShipTo(ShipTo);
        CreateMapping(Mapping, 'DisabledTest', 'Disabled_Attr', Mapping."Data Type"::Text, false, Mapping."Storage Mode"::Flexible);
        Mapping.Enabled := false;
        Mapping.Modify(true);

        AttrValue.Init();
        AttrValue."Customer No." := ShipTo."Customer No.";
        AttrValue."Ship-to Code" := ShipTo.Code;
        AttrValue."Attribute Name" := 'Disabled_Attr';
        AttrValue."Attribute Value" := 'x';
        AttrValue."Data Type" := Mapping."Data Type"::Text;

        if TryInsertAttribute(AttrValue) then
            Error('Expected an error writing to a disabled (not auto-discovered) attribute, but it succeeded.');
    end;

    [Test]
    procedure OwnershipValidationRejectsUnknownShipTo()
    var
        AttrValue: Record "WZC Ship-to Attribute";
    begin
        AttrValue.Init();
        AttrValue."Customer No." := 'NOSUCHCUST';
        AttrValue."Ship-to Code" := 'NOSUCH';
        AttrValue."Attribute Name" := 'Whatever';
        AttrValue."Attribute Value" := 'x';
        AttrValue."Data Type" := AttrValue."Data Type"::Text;

        if TryInsertAttribute(AttrValue) then
            Error('Expected an error inserting an attribute for a non-existent Ship-to Address, but it succeeded.');
    end;

    [TryFunction]
    local procedure TryInsertAttribute(var AttrValue: Record "WZC Ship-to Attribute")
    begin
        AttrValue.Insert(true);
    end;

    [TryFunction]
    local procedure TryInsertMapping(var Mapping: Record "WZC Attribute Mapping")
    begin
        Mapping.Insert(true);
    end;

    local procedure CreateTestShipTo(var ShipTo: Record "Ship-to Address")
    var
        Customer: Record Customer;
        CustNo: Code[20];
    begin
        CustNo := 'WZCTESTCUST';
        if not Customer.Get(CustNo) then begin
            Customer.Init();
            Customer."No." := CustNo;
            Customer.Name := 'WZC Test Customer';
            Customer.Insert(true);
        end;

        if not ShipTo.Get(CustNo, 'TEST') then begin
            ShipTo.Init();
            ShipTo."Customer No." := CustNo;
            ShipTo.Code := 'TEST';
            ShipTo.Name := 'WZC Test Ship-to';
            ShipTo.Insert(true);
        end;
    end;

    local procedure CreateMapping(var Mapping: Record "WZC Attribute Mapping"; LogicalName: Code[50]; TenantName: Code[50]; DataType: Enum "WZC Attribute Data Type"; Required: Boolean; StorageMode: Enum "WZC Attribute Storage Mode")
    begin
        Mapping.Init();
        Mapping.Entity := 'SHIPTOADDR';
        Mapping."Logical Name" := LogicalName;
        Mapping."Tenant Attribute Name" := TenantName;
        Mapping."Data Type" := DataType;
        Mapping.Required := Required;
        Mapping."Storage Mode" := StorageMode;
        Mapping."Sync Direction" := Mapping."Sync Direction"::Both;
        Mapping.Enabled := true;
        Mapping.Insert(true);
    end;
}
