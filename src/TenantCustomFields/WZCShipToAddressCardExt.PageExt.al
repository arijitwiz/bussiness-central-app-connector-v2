pageextension 50123 "WZC Ship-to Address Card Ext" extends "Ship-to Address"
{
    layout
    {
        addlast(General)
        {
            field("WZC Delivery Instructions"; Rec."WZC Delivery Instructions")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies delivery instructions specific to this ship-to address.';
            }
        }
    }
}
