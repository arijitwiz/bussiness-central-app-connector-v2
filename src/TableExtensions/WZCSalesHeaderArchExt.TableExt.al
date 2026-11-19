tableextension 73734364 "WZC Sales Header Arch Ext" extends "Sales Header Archive"
{
    // Same field numbers as WZC Sales Header Ext so TransferFields during archiving
    // carries the WizCommerce external id, notes and source into the archive.
    fields
    {
        field(73734350; "WZC External Id"; Code[50])
        {
            Caption = 'WZC External Id';
            DataClassification = CustomerContent;
        }
        field(73734351; "WZC Order Notes"; Text[2048])
        {
            Caption = 'WZC Order Notes';
            DataClassification = CustomerContent;
        }
        field(73734352; "WZC Source"; Code[20])
        {
            Caption = 'WZC Source';
            DataClassification = CustomerContent;
        }
    }
}
