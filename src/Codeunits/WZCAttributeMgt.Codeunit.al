codeunit 50112 "WZC Attribute Mgt"
{
    var
        TenantNameAlreadyUsedErr: Label 'Attribute name ''%1'' is already mapped to logical attribute ''%2''. Choose a different name or edit that mapping instead.';
        RealFieldNotSupportedErr: Label 'Storage Mode ''Real Field'' is only available for logical attributes this extension actually has a real field for. Currently supported: %1. For any other attribute, use ''Flexible''.';
        AttributeDisabledErr: Label 'Attribute ''%1'' is disabled in WZC Attribute Setup for this company.';
        RealFieldRedirectErr: Label 'Attribute ''%1'' is backed by a real field (%2). Read/write it via WZC Ship-to Address Full API instead of this generic attribute API.';
        InvalidNumberErr: Label 'Attribute ''%1'' expects a Number value. ''%2'' does not parse as one.';
        InvalidDateErr: Label 'Attribute ''%1'' expects a Date value. ''%2'' does not parse as one.';
        InvalidBooleanErr: Label 'Attribute ''%1'' expects a Boolean value (''true'' or ''false''). Got ''%2''.';
        RequiredMissingErr: Label 'Attribute ''%1'' is required and cannot be blank.';
        ShipToNotFoundErr: Label 'Ship-to Address %1 / %2 does not exist. Attributes can only be stored against an existing address.';
        SupportedRealFieldLogicalNamesTok: Label 'CreateAddress', Locked = true;

    procedure ValidateShipToOwnership(CustomerNo: Code[20]; ShipToCode: Code[10])
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        if not ShipToAddress.Get(CustomerNo, ShipToCode) then
            Error(ShipToNotFoundErr, CustomerNo, ShipToCode);
    end;

    procedure ValidateAttributeValue(var AttrRec: Record "WZC Ship-to Attribute")
    var
        Mapping: Record "WZC Attribute Mapping";
        DecimalValue: Decimal;
        DateValue: Date;
        NormalizedBool: Text;
    begin
        if not FindMappingByTenantName('SHIPTOADDR', AttrRec."Attribute Name", Mapping) then begin
            AutoDiscoverMapping(AttrRec."Attribute Name", AttrRec."Data Type");
            exit;
        end;

        if Mapping."Storage Mode" = Mapping."Storage Mode"::RealField then
            Error(RealFieldRedirectErr, AttrRec."Attribute Name", Mapping."Logical Name");

        if not Mapping."Auto Discovered" and not Mapping.Enabled then
            Error(AttributeDisabledErr, AttrRec."Attribute Name");

        if Mapping.Required and (AttrRec."Attribute Value" = '') then
            Error(RequiredMissingErr, AttrRec."Attribute Name");

        if AttrRec."Attribute Value" <> '' then
            case Mapping."Data Type" of
                Mapping."Data Type"::Number:
                    if not Evaluate(DecimalValue, AttrRec."Attribute Value") then
                        Error(InvalidNumberErr, AttrRec."Attribute Name", AttrRec."Attribute Value");
                Mapping."Data Type"::Date:
                    if not Evaluate(DateValue, AttrRec."Attribute Value") then
                        Error(InvalidDateErr, AttrRec."Attribute Name", AttrRec."Attribute Value");
                Mapping."Data Type"::Boolean:
                    begin
                        NormalizedBool := LowerCase(AttrRec."Attribute Value");
                        if not (NormalizedBool in ['true', 'false']) then
                            Error(InvalidBooleanErr, AttrRec."Attribute Name", AttrRec."Attribute Value");
                        AttrRec."Attribute Value" := NormalizedBool;
                    end;
            end;
    end;

    local procedure AutoDiscoverMapping(TenantAttributeName: Code[50]; DataType: Enum "WZC Attribute Data Type")
    var
        Mapping: Record "WZC Attribute Mapping";
        LogicalName: Code[50];
    begin
        LogicalName := TenantAttributeName;
        Mapping.LockTable();
        if Mapping.Get('SHIPTOADDR', LogicalName) then
            exit;

        Mapping.Init();
        Mapping.Entity := 'SHIPTOADDR';
        Mapping."Logical Name" := LogicalName;
        Mapping."Tenant Attribute Name" := TenantAttributeName;
        Mapping."Data Type" := DataType;
        Mapping."Storage Mode" := Mapping."Storage Mode"::Flexible;
        Mapping."Sync Direction" := Mapping."Sync Direction"::Both;
        Mapping.Enabled := false;
        Mapping."Auto Discovered" := true;
        Mapping."Validation Status" := 'Auto-created from an incoming value. Review and activate in WZC Attribute Setup.';
        Mapping.Insert(true);
    end;

    procedure CheckTenantNameNotDuplicated(var Mapping: Record "WZC Attribute Mapping")
    var
        Existing: Record "WZC Attribute Mapping";
    begin
        Existing.SetRange(Entity, Mapping.Entity);
        Existing.SetRange("Tenant Attribute Name", Mapping."Tenant Attribute Name");
        Existing.SetFilter("Logical Name", '<>%1', Mapping."Logical Name");
        if Existing.FindFirst() then
            Error(TenantNameAlreadyUsedErr, Mapping."Tenant Attribute Name", Existing."Logical Name");
    end;

    procedure CheckRealFieldSupported(LogicalName: Code[50])
    begin
        if not IsRealFieldSupported(LogicalName) then
            Error(RealFieldNotSupportedErr, SupportedRealFieldLogicalNamesTok);
    end;

    local procedure IsRealFieldSupported(LogicalName: Code[50]): Boolean
    begin
        exit(LogicalName = 'CreateAddress');
    end;

    procedure ValidateMapping(var Mapping: Record "WZC Attribute Mapping")
    var
        DecimalValue: Decimal;
        DateValue: Date;
        NormalizedBool: Text;
        Status: Text[250];
    begin
        Status := 'OK';

        if Mapping."Tenant Attribute Name" = '' then
            Status := 'Attribute Name is blank.'
        else
            if (Mapping."Default Value" <> '') then
                case Mapping."Data Type" of
                    Mapping."Data Type"::Number:
                        if not Evaluate(DecimalValue, Mapping."Default Value") then
                            Status := 'Default Value does not parse as Number.';
                    Mapping."Data Type"::Date:
                        if not Evaluate(DateValue, Mapping."Default Value") then
                            Status := 'Default Value does not parse as Date.';
                    Mapping."Data Type"::Boolean:
                        begin
                            NormalizedBool := LowerCase(Mapping."Default Value");
                            if not (NormalizedBool in ['true', 'false']) then
                                Status := 'Default Value must be ''true'' or ''false'' for a Boolean attribute.';
                        end;
                end;

        if (Status = 'OK') and (Mapping."Storage Mode" = Mapping."Storage Mode"::RealField) and not IsRealFieldSupported(Mapping."Logical Name") then
            Status := StrSubstNo('No real field exists for logical name ''%1''. Use Flexible storage.', Mapping."Logical Name");

        Mapping."Validation Status" := Status;
    end;

    procedure StampLastModified(var Mapping: Record "WZC Attribute Mapping")
    begin
        Mapping."Last Modified At" := CurrentDateTime();
        Mapping."Last Modified By" := CopyStr(UserId(), 1, MaxStrLen(Mapping."Last Modified By"));
    end;

    procedure LogMappingChange(var Mapping: Record "WZC Attribute Mapping"; ChangeType: Text[20])
    var
        Log: Record "WZC Attribute Change Log";
    begin
        Log.Init();
        Log."Log Type" := Log."Log Type"::"Config Change";
        Log."Logical Name" := Mapping."Logical Name";
        Log."Change Type" := ChangeType;
        Log."New Value" := CopyStr(
            StrSubstNo('%1=%2, Type=%3, Required=%4, Storage=%5, Enabled=%6',
                Mapping."Tenant Attribute Name", Mapping."Default Value", Mapping."Data Type",
                Mapping.Required, Mapping."Storage Mode", Mapping.Enabled),
            1, MaxStrLen(Log."New Value"));
        Log."Changed By" := CopyStr(UserId(), 1, MaxStrLen(Log."Changed By"));
        Log."Changed At" := CurrentDateTime();
        Log.Insert(true);
    end;

    procedure LogSyncError(LogicalName: Code[50]; CustomerNo: Code[20]; ShipToCode: Code[10]; Message: Text[500])
    var
        Log: Record "WZC Attribute Change Log";
    begin
        Log.Init();
        Log."Log Type" := Log."Log Type"::"Sync Error";
        Log."Logical Name" := LogicalName;
        Log."Customer No." := CustomerNo;
        Log."Ship-to Code" := ShipToCode;
        Log.Message := Message;
        Log."Changed By" := CopyStr(UserId(), 1, MaxStrLen(Log."Changed By"));
        Log."Changed At" := CurrentDateTime();
        Log.Insert(true);
    end;

    local procedure FindMappingByTenantName(Entity: Code[20]; TenantAttributeName: Code[50]; var Mapping: Record "WZC Attribute Mapping"): Boolean
    begin
        Mapping.SetRange(Mapping.Entity, Entity);
        Mapping.SetRange("Tenant Attribute Name", TenantAttributeName);
        exit(Mapping.FindFirst());
    end;
}
