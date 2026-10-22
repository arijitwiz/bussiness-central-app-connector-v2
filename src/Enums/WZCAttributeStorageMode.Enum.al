enum 50112 "WZC Attribute Storage Mode"
{
    Extensible = false;

    value(0; Flexible)
    {
        Caption = 'Flexible (generic key-value row; no AL changes needed)';
    }
    value(1; RealField)
    {
        Caption = 'Real Field (backed by an actual table field; requires AL)';
    }
}
