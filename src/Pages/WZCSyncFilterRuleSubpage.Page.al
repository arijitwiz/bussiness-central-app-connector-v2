page 50107 "WZC Sync Filter Rule Subpage"
{
    PageType = ListPart;
    SourceTable = "WZC Sync Filter Rule";
    Caption = 'Filter Rules';
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Controls default ordering. Reorder with Move Up/Move Down.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Must be one of this entity''s allowlisted fields.';
                }
                field(Operator; Rec.Operator)
                {
                    ApplicationArea = All;
                    ToolTip = 'Must be a valid operator for this field''s data type.';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    ToolTip = 'Leave blank for Is Empty / Is Not Empty. Comma-separate for In List.';
                }
                field("Group No."; Rec."Group No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Rules sharing a Group No. are OR''d together. Different groups are AND''d.';
                }
                field(Enabled; Rec.Enabled)
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
            action(MoveUp)
            {
                ApplicationArea = All;
                Caption = 'Move Up';
                Image = MoveUp;

                trigger OnAction()
                begin
                    SwapWithAdjacent(true);
                end;
            }
            action(MoveDown)
            {
                ApplicationArea = All;
                Caption = 'Move Down';
                Image = MoveDown;

                trigger OnAction()
                begin
                    SwapWithAdjacent(false);
                end;
            }
        }
    }

    local procedure SwapWithAdjacent(Up: Boolean)
    var
        Other: Record "WZC Sync Filter Rule";
        ThisLineNo: Integer;
        OtherLineNo: Integer;
    begin
        ThisLineNo := Rec."Line No.";
        Other.SetRange("Profile No.", Rec."Profile No.");
        if Up then
            Other.SetFilter("Line No.", '<%1', ThisLineNo)
        else
            Other.SetFilter("Line No.", '>%1', ThisLineNo);

        if Up then begin
            if Other.FindLast() then
                OtherLineNo := Other."Line No."
            else
                exit;
        end else
            if Other.FindFirst() then
                OtherLineNo := Other."Line No."
            else
                exit;

        Other."Line No." := ThisLineNo;
        Rec."Line No." := OtherLineNo;

        Other.Rename(Other."Profile No.", -1); // temp line no to avoid PK clash during swap
        Rec.Rename(Rec."Profile No.", OtherLineNo);
        Other.Rename(Other."Profile No.", ThisLineNo);

        CurrPage.Update(false);
    end;
}
