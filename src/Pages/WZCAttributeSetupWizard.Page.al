page 50120 "WZC Attribute Setup Wizard"
{
    PageType = NavigatePage;
    SourceTable = "WZC Attribute Mapping";
    SourceTableTemporary = true;
    Caption = 'New WizCommerce Attribute';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Step1)
            {
                Caption = '1. New Attribute';
                Visible = ShowStep1;

                field("Logical Name"; Rec."Logical Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The stable, internal name WizCommerce will use for this attribute, e.g. CreateAddress.';
                }
                field("Tenant Attribute Name"; Rec."Tenant Attribute Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Whatever this company wants to call the attribute, e.g. WizCommerce_Create_Address.';
                }
            }
            group(Step2)
            {
                Caption = '2. Configure';
                Visible = ShowStep2;

                field("Data Type"; Rec."Data Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Text, Number, Date, or Boolean.';
                }
                field("Default Value"; Rec."Default Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Returned by the API when no explicit value has been set. Leave blank for none.';
                }
                field(Required; Rec.Required)
                {
                    ApplicationArea = All;
                    ToolTip = 'Require a value to be explicitly stored for this attribute.';
                }
                field("Sync Direction"; Rec."Sync Direction")
                {
                    ApplicationArea = All;
                    ToolTip = 'Pull, Push, or Both.';
                }
                field("Storage Mode"; Rec."Storage Mode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Flexible works for any attribute with no AL changes. Real Field only works for attributes this extension already has a real field for.';
                }
            }
            group(Step3)
            {
                Caption = '3. Validate';
                Visible = ShowStep3;

                field("Validation Status"; Rec."Validation Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Result of checking this configuration. Must say OK before you can activate.';
                }
            }
            group(Step4)
            {
                Caption = '4. Activate';
                Visible = ShowStep4;

                field(ActivateNow; ActivateNow)
                {
                    ApplicationArea = All;
                    Caption = 'Enable this attribute immediately';
                    ToolTip = 'If off, the attribute is saved disabled - you can enable it later from WZC Attribute Setup.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Image = PreviousRecord;
                Enabled = BackEnabled;

                trigger OnAction()
                begin
                    Step -= 1;
                    UpdateControls();
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Image = NextRecord;
                Enabled = NextEnabled;

                trigger OnAction()
                var
                    AttrMgt: Codeunit "WZC Attribute Mgt";
                begin
                    case Step of
                        Step::NewAttribute:
                            if (Rec."Logical Name" = '') or (Rec."Tenant Attribute Name" = '') then
                                Error('Enter both Logical Name and Attribute Name before continuing.');
                        Step::Validate:
                            begin
                                AttrMgt.ValidateMapping(Rec);
                                if Rec."Validation Status" <> 'OK' then
                                    Error('Fix this before continuing: %1', Rec."Validation Status");
                            end;
                    end;
                    Step += 1;
                    UpdateControls();
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Activate';
                Image = Approve;
                Enabled = FinishEnabled;

                trigger OnAction()
                var
                    RealMapping: Record "WZC Attribute Mapping";
                begin
                    RealMapping.Init();
                    RealMapping.TransferFields(Rec);
                    RealMapping.Enabled := ActivateNow;
                    RealMapping."Auto Discovered" := false;
                    RealMapping.Insert(true);
                    Message('Attribute ''%1'' saved.', RealMapping."Logical Name");
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        Step: Option NewAttribute,Configure,Validate,Activate;
        ShowStep1: Boolean;
        ShowStep2: Boolean;
        ShowStep3: Boolean;
        ShowStep4: Boolean;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        ActivateNow: Boolean;

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec.Entity := 'SHIPTOADDR';
        Rec.Insert();
        ActivateNow := true;
        UpdateControls();
    end;

    local procedure UpdateControls()
    begin
        ShowStep1 := Step = Step::NewAttribute;
        ShowStep2 := Step = Step::Configure;
        ShowStep3 := Step = Step::Validate;
        ShowStep4 := Step = Step::Activate;
        BackEnabled := Step <> Step::NewAttribute;
        NextEnabled := Step <> Step::Activate;
        FinishEnabled := Step = Step::Activate;
    end;
}
