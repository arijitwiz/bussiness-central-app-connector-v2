enum 50114 "WZC Sync Mode"
{
    Extensible = false;

    value(0; Full)
    {
        Caption = 'Full Sync (every matching record every run)';
    }
    value(1; Incremental)
    {
        Caption = 'Incremental Sync (only records changed since last checkpoint)';
    }
}
