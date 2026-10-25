codeunit 50133 "WZC Upgrade"
{
    Subtype = Upgrade;

    /// <summary>
    /// Republishing a new app version must never reset tenant configuration. Upgrade only
    /// seeds rows that do not exist yet (new API operations get an enabled default row);
    /// existing WZC Api Config, Field Visibility, Attribute Mapping and Sync Profile rows
    /// are left exactly as the tenant configured them.
    /// </summary>
    trigger OnUpgradePerCompany()
    var
        SetupMgt: Codeunit "WZC Setup Mgt";
    begin
        SetupMgt.SeedAllApiConfigs();
    end;
}
