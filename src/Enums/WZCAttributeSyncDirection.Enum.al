enum 50111 "WZC Attribute Sync Direction"
{
    Extensible = false;

    value(0; Pull)
    {
        Caption = 'Pull (BC → WizCommerce)';
    }
    value(1; Push)
    {
        Caption = 'Push (WizCommerce → BC)';
    }
    value(2; Both)
    {
        Caption = 'Both';
    }
}
