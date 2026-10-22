page 50119 "WZC Attribute Setup"
{
    PageType = List;
    SourceTable = "WZC Attribute Mapping";
    Caption = 'WizCommerce Attribute Setup';
    ApplicationArea = All;
    UsageCategory = Administration;
    DeleteAllowed = true;
    InsertAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Entity; Rec.Entity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Which BC entity this attribute belongs to. Ship-to Address only, for now.';
                }
                field("Logical Name"; Rec."Logical Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The stable, internal name WizCommerce uses for this attribute. Does not change even if the Attribute Name below is renamed.';
                }
                field("Tenant Attribute Name"; Rec."Tenant Attribute Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Whatever this company calls the attribute. This is the key used when reading/writing via the API.';
                }
                field("Data Type"; Rec."Data Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Text, Number, Date, or Boolean.';
                }
                field("Default Value"; Rec."Default Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Returned by the API when no explicit value has been set for a given address. Never written to storage automatically.';
                }
                field(Required; Rec.Required)
                {
                    ApplicationArea = All;
                    ToolTip = 'If set, a value must be explicitly stored for this attribute before it is considered complete.';
                }
                field("Sync Direction"; Rec."Sync Direction")
                {
                    ApplicationArea = All;
                    ToolTip = 'Whether WizCommerce pulls this attribute, pushes it, or both.';
                }
                field("Storage Mode"; Rec."Storage Mode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Flexible (no AL needed) or Real Field (requires a matching AL table extension field - currently only CreateAddress).';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Only enabled attributes can be written through the API.';
                }
                field("Auto Discovered"; Rec."Auto Discovered")
                {
                    ApplicationArea = All;
                    ToolTip = 'Set automatically when a value arrived for an attribute that had not been configured yet. Review and enable it.';
                }
                field("Validation Status"; Rec."Validation Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Result of the last validation check on this mapping.';
                }
                field("Last Modified At"; Rec."Last Modified At")
                {
                    ApplicationArea = All;
                }
                field("Last Modified By"; Rec."Last Modified By")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewAttributeWizard)
            {
                ApplicationArea = All;
                Caption = 'New Attribute (Guided)';
                Image = New;
                RunObject = page "WZC Attribute Setup Wizard";
                ToolTip = 'Walk through New Attribute → Configure → Validate → Activate.';
            }
            action(ViewChangeLog)
            {
                ApplicationArea = All;
                Caption = 'Change Log';
                Image = Log;
                RunObject = page "WZC Attribute Change Log";
                ToolTip = 'View configuration changes and sync errors for these attributes.';
            }
        }
    }
}
