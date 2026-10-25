codeunit 50110 "WZC Setup Mgt"
{
    procedure GetSetup(var Setup: Record "WZC Connector Setup")
    begin
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert();
        end;
    end;

    /// <summary>
    /// Call once at the top of every WZC API's OnOpenPage/OnBeforeOpen trigger.
    /// Errors out if the API is disabled for this company, or if the per-hour
    /// rate limit configured for this company has been exceeded.
    /// </summary>
    procedure EnforceApiAccess(ApiName: Code[30]; FriendlyName: Text[100])
    var
        Config: Record "WZC Api Config";
    begin
        GetOrCreateApiConfig(ApiName, FriendlyName, Config);

        if not Config.Enabled then
            Error(
                'The %1 is disabled for this company. Ask your Business Central administrator to enable it in WZC Connector API Configuration.',
                FriendlyName);

        CheckAndIncrementRateLimit(Config);
    end;

    procedure EnsureApiConfigExists(ApiName: Code[30]; FriendlyName: Text[100])
    var
        Config: Record "WZC Api Config";
    begin
        GetOrCreateApiConfig(ApiName, FriendlyName, Config);
    end;

    procedure SeedAllApiConfigs()
    begin
        EnsureApiConfigExists('SHIPTOADDR', 'WZC Ship-to Address API');
        EnsureApiConfigExists('SHIPMENTTRACK', 'WZC Shipment Tracking API');
        EnsureApiConfigExists('CUSTPRICE', 'WZC Customer Price API');
        EnsureApiConfigExists('ITEMAVAIL', 'WZC Item Availability');
        EnsureApiConfigExists('SHIPTOADDRFULL', 'WZC Ship-to Address Full API');
        EnsureApiConfigExists('SHIPTOATTR', 'WZC Ship-to Attribute API');
        // v2.0 unified entity APIs
        EnsureApiConfigExists('CUSTOMER', 'WZC Customer API');
        EnsureApiConfigExists('ITEM', 'WZC Item API');
        EnsureApiConfigExists('INVFEED', 'WZC Inventory Feed API');
        EnsureApiConfigExists('INVBYLOC', 'WZC Inventory By Location');
        EnsureApiConfigExists('SALESORDER', 'WZC Sales Order API');
        EnsureApiConfigExists('SALESORDERWRITE', 'WZC Sales Order Write API');
        EnsureApiConfigExists('SALESORDERARCH', 'WZC Sales Order Archive API');
    end;

    local procedure GetOrCreateApiConfig(ApiName: Code[30]; FriendlyName: Text[100]; var Config: Record "WZC Api Config")
    begin
        Config.LockTable();
        if not Config.Get(ApiName) then begin
            Config.Init();
            Config."Api Name" := ApiName;
            Config."Friendly Name" := FriendlyName;
            Config.Enabled := true;
            Config.Insert();
        end;
    end;

    local procedure CheckAndIncrementRateLimit(var Config: Record "WZC Api Config")
    var
        RateState: Record "WZC Api Rate State";
        WindowLengthMs: Duration;
    begin
        if Config."Rate Limit Per Hour" <= 0 then
            exit;

        WindowLengthMs := 3600000; // 1 hour

        RateState.LockTable();
        if not RateState.Get(Config."Api Name") then begin
            RateState.Init();
            RateState."Api Name" := Config."Api Name";
            RateState.Insert();
        end;

        if RateState."Window Start" = 0DT then begin
            RateState."Window Start" := CurrentDateTime();
            RateState."Call Count" := 0;
        end else
            if CurrentDateTime() - RateState."Window Start" > WindowLengthMs then begin
                RateState."Window Start" := CurrentDateTime();
                RateState."Call Count" := 0;
            end;

        RateState."Call Count" += 1;
        RateState.Modify();

        if RateState."Call Count" > Config."Rate Limit Per Hour" then
            Error(
                'Rate limit exceeded for %1: %2 calls/hour allowed for this company. Try again after the current hourly window resets.',
                Config."Friendly Name", Config."Rate Limit Per Hour");
    end;
}
