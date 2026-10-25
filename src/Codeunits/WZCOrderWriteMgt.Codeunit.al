codeunit 50132 "WZC Order Write Mgt"
{
    /// <summary>
    /// Business logic behind the WZC Sales Order Write API: idempotent create keyed on the
    /// WizCommerce document id (WZC External Id), dimension validation before the order is
    /// accepted, and order notes materialised as Sales Comment Lines.
    /// </summary>

    var
        WzcCommentCodeTok: Label 'WZC', Locked = true;
        DefaultSourceTok: Label 'WIZCOMMERCE', Locked = true;

    /// <summary>
    /// Search-before-create. Returns true (and the order) when a sales ORDER already carries
    /// this external id, so a retried POST adopts the existing document instead of creating
    /// a duplicate.
    /// </summary>
    procedure FindExistingOrderByExternalId(ExternalId: Code[50]; var SalesHeader: Record "Sales Header"): Boolean
    begin
        if ExternalId = '' then
            exit(false);

        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("WZC External Id", ExternalId);
        exit(SalesHeader.FindFirst());
    end;

    procedure DefaultSource(): Code[20]
    begin
        exit(DefaultSourceTok);
    end;

    /// <summary>
    /// Validates the header dimension set: allowed dimension combinations and
    /// blocked / mandatory dimension values for the customer and salesperson. Errors
    /// surface to the caller as a normal 400 with the Business Central message, so the
    /// WizCommerce push-failure flow gets an actionable reason instead of a posting-time surprise.
    /// </summary>
    procedure ValidateDimensions(var SalesHeader: Record "Sales Header")
    var
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        if not DimMgt.CheckDimIDComb(SalesHeader."Dimension Set ID") then
            Error(DimMgt.GetDimCombErr());

        TableID[1] := Database::Customer;
        No[1] := SalesHeader."Bill-to Customer No.";
        TableID[2] := Database::"Salesperson/Purchaser";
        No[2] := SalesHeader."Salesperson Code";
        if not DimMgt.CheckDimValuePosting(TableID, No, SalesHeader."Dimension Set ID") then
            Error(DimMgt.GetDimValuePostingErr());
    end;

    /// <summary>
    /// Writes WZC Order Notes to Sales Comment Lines (header level, Code = WZC) in 80-char
    /// chunks. Idempotent: WZC-owned comment lines are replaced, manual comments untouched.
    /// </summary>
    procedure WriteNotesAsComments(var SalesHeader: Record "Sales Header")
    var
        SalesCommentLine: Record "Sales Comment Line";
        Remaining: Text;
        NextLineNo: Integer;
    begin
        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::Order);
        SalesCommentLine.SetRange("No.", SalesHeader."No.");
        SalesCommentLine.SetRange("Document Line No.", 0);
        SalesCommentLine.SetRange(Code, WzcCommentCodeTok);
        SalesCommentLine.DeleteAll();

        if SalesHeader."WZC Order Notes" = '' then
            exit;

        SalesCommentLine.SetRange(Code);
        if SalesCommentLine.FindLast() then
            NextLineNo := SalesCommentLine."Line No." + 10000
        else
            NextLineNo := 10000;

        Remaining := SalesHeader."WZC Order Notes";
        while Remaining <> '' do begin
            SalesCommentLine.Init();
            SalesCommentLine."Document Type" := SalesCommentLine."Document Type"::Order;
            SalesCommentLine."No." := SalesHeader."No.";
            SalesCommentLine."Document Line No." := 0;
            SalesCommentLine."Line No." := NextLineNo;
            SalesCommentLine.Date := WorkDate();
            SalesCommentLine.Code := WzcCommentCodeTok;
            SalesCommentLine.Comment := CopyStr(Remaining, 1, MaxStrLen(SalesCommentLine.Comment));
            SalesCommentLine.Insert();

            Remaining := CopyStr(Remaining, MaxStrLen(SalesCommentLine.Comment) + 1);
            NextLineNo += 10000;
        end;
    end;

    /// <summary>Next free line no. on a sales document, for API-created lines that omit lineNo.</summary>
    procedure NextSalesLineNo(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        if SalesLine.FindLast() then
            exit(SalesLine."Line No." + 10000);
        exit(10000);
    end;
}
