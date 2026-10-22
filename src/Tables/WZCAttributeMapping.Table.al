table 50117 "WZC Attribute Mapping"
{
    DataClassification = CustomerContent;
    Caption = 'WizCommerce Attribute Mapping';

    fields
    {
        field(1; "Entity"; Code[20])
        {
            Caption = 'Entity';
            InitValue = 'SHIPTOADDR';
        }
        field(2; "Logical Name"; Code[50])
        {
            Caption = 'Logical Name';
        }
        field(10; "Tenant Attribute Name"; Code[50])
        {
            Caption = 'Attribute Name';

            trigger OnValidate()
            var
                AttrMgt: Codeunit "WZC Attribute Mgt";
            begin
                AttrMgt.CheckTenantNameNotDuplicated(Rec);
            end;
        }
        field(20; "Data Type"; Enum "WZC Attribute Data Type")
        {
            Caption = 'Data Type';
        }
        field(21; "Default Value"; Text[250])
        {
            Caption = 'Default Value';
        }
        field(22; Required; Boolean)
        {
            Caption = 'Required';
        }
        field(23; "Sync Direction"; Enum "WZC Attribute Sync Direction")
        {
            Caption = 'Sync Direction';
        }
        field(30; "Storage Mode"; Enum "WZC Attribute Storage Mode")
        {
            Caption = 'Storage Mode';

            trigger OnValidate()
            var
                AttrMgt: Codeunit "WZC Attribute Mgt";
            begin
                if Rec."Storage Mode" = Rec."Storage Mode"::RealField then
                    AttrMgt.CheckRealFieldSupported(Rec."Logical Name");
            end;
        }
        field(40; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(41; "Auto Discovered"; Boolean)
        {
            Caption = 'Auto Discovered';
            Editable = false;
        }
        field(50; "Validation Status"; Text[250])
        {
            Caption = 'Validation Status';
            Editable = false;
        }
        field(60; "Last Modified At"; DateTime)
        {
            Caption = 'Last Modified At';
            Editable = false;
        }
        field(61; "Last Modified By"; Code[50])
        {
            Caption = 'Last Modified By';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entity", "Logical Name")
        {
            Clustered = true;
        }
        key(SK1; "Entity", "Tenant Attribute Name")
        {
        }
    }

    trigger OnInsert()
    var
        AttrMgt: Codeunit "WZC Attribute Mgt";
    begin
        AttrMgt.ValidateMapping(Rec);
        AttrMgt.StampLastModified(Rec);
        AttrMgt.LogMappingChange(Rec, 'Created');
    end;

    trigger OnModify()
    var
        AttrMgt: Codeunit "WZC Attribute Mgt";
    begin
        AttrMgt.ValidateMapping(Rec);
        AttrMgt.StampLastModified(Rec);
        AttrMgt.LogMappingChange(Rec, 'Modified');
    end;

    trigger OnDelete()
    var
        AttrMgt: Codeunit "WZC Attribute Mgt";
    begin
        AttrMgt.LogMappingChange(Rec, 'Deleted');
    end;
}
