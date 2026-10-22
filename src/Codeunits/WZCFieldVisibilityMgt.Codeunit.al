codeunit 50117 "WZC Field Visibility Mgt"
{
    /// <summary>
    /// Tenant-wise field-level response control, per API. Default (no rows configured
    /// for this Api Operation at all) = every field visible, matching the code's normal
    /// behavior. The moment ANY row exists for an Api Operation, that becomes a whitelist:
    /// only fields explicitly marked Visible = true are shown; everything else for that
    /// API is blanked in the response (not removed from the schema - AL can't do that for
    /// a compiled API page - but the value is blank regardless of what the caller requests).
    /// </summary>
    procedure IsFieldVisible(ApiOperation: Code[30]; FieldName: Code[50]): Boolean
    var
        Config: Record "WZC Field Visibility";
    begin
        Config.SetRange("Api Operation", ApiOperation);
        if Config.IsEmpty() then
            exit(true); // no config at all for this API -> code default: show everything

        if not Config.Get(ApiOperation, FieldName) then
            exit(false); // config exists for this API, but not for this field -> hidden

        exit(Config.Visible);
    end;

    procedure HasAnyConfig(ApiOperation: Code[30]): Boolean
    var
        Config: Record "WZC Field Visibility";
    begin
        Config.SetRange("Api Operation", ApiOperation);
        exit(not Config.IsEmpty());
    end;
}
