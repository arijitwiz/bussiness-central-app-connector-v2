tableextension 50114 "WZC Sales Header Arch Ext" extends "Sales Header Archive"
{
    // Same field numbers as WZC Sales Header Ext so TransferFields during archiving
    // carries the WizCommerce external id, notes and source into the archive.
    fields
    {
        field(50100; "WZC External Id"; Code[50])
        {
            Caption = 'WZC External Id';
            DataClassification = CustomerContent;
        }
        field(50101; "WZC Order Notes"; Text[2048])
        {
            Caption = 'WZC Order Notes';
            DataClassification = CustomerContent;
        }
        field(50102; "WZC Source"; Code[20])
        {
            Caption = 'WZC Source';
            DataClassification = CustomerContent;
        }
    }
}
