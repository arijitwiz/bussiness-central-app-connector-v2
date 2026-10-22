enum 50117 "WZC Sync Run Status"
{
    Extensible = false;

    value(0; Running)
    {
        Caption = 'Running';
    }
    value(1; Success)
    {
        Caption = 'Success';
    }
    value(2; Failed)
    {
        Caption = 'Failed';
    }
    value(3; PartialFailure)
    {
        Caption = 'Partial Failure';
    }
}
