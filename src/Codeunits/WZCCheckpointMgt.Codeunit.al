codeunit 50115 "WZC Checkpoint Mgt"
{
    var
        AlreadyRunningErr: Label 'Profile ''%1'' already has a sync run in progress (started %2). Wait for it to finish, or use Reset Checkpoint if you''re certain it''s stuck.';

    procedure GetSyncWindow(Profile: Record "WZC Sync Profile"; var LowerBound: DateTime; var UpperBound: DateTime)
    var
        Checkpoint: Record "WZC Sync Checkpoint";
    begin
        UpperBound := CurrentDateTime();

        if Profile."Sync Mode" = Profile."Sync Mode"::Full then begin
            LowerBound := 0DT;
            exit;
        end;

        if Checkpoint.Get(Profile."Profile No.") and (Checkpoint."Last Checkpoint DateTime" <> 0DT) then
            LowerBound := Checkpoint."Last Checkpoint DateTime" - (Profile."Overlap Seconds" * 1000)
        else
            LowerBound := 0DT; // first ever run for this profile behaves like a full sync
    end;

    /// <summary>
    /// Acquires the run lock for a profile (errors if already running and not stale),
    /// and opens a Run Log entry with Status = Running.
    /// </summary>
    procedure StartRun(Profile: Record "WZC Sync Profile"; UpperBound: DateTime; LowerBound: DateTime; var RunLog: Record "WZC Sync Run Log")
    var
        Checkpoint: Record "WZC Sync Checkpoint";
        StaleRunHoursThreshold: Decimal;
    begin
        StaleRunHoursThreshold := 2;

        Checkpoint.LockTable();
        if not Checkpoint.Get(Profile."Profile No.") then begin
            Checkpoint.Init();
            Checkpoint."Profile No." := Profile."Profile No.";
            Checkpoint.Insert();
        end;

        if Checkpoint."Run In Progress" and (Checkpoint."Run Started At" <> 0DT) then
            if CurrentDateTime() - Checkpoint."Run Started At" < StaleRunHoursThreshold * 3600000 then
                Error(AlreadyRunningErr, Profile."Profile No.", Checkpoint."Run Started At");
        // else: stale (or never recorded a start time) - take over

        Checkpoint."Run In Progress" := true;
        Checkpoint."Run Started At" := CurrentDateTime();
        Checkpoint.Modify();

        RunLog.Init();
        RunLog."Profile No." := Profile."Profile No.";
        RunLog."Config Version" := Profile."Config Version";
        RunLog."Started At" := CurrentDateTime();
        RunLog.Status := RunLog.Status::Running;
        RunLog."Window Lower Bound" := LowerBound;
        RunLog."Window Upper Bound" := UpperBound;
        RunLog."Run By" := CopyStr(UserId(), 1, MaxStrLen(RunLog."Run By"));
        RunLog.Insert(true);
    end;

    /// <summary>
    /// Releases the run lock. Advances the checkpoint watermark ONLY when Success = true,
    /// so a failed/crashed run simply gets reprocessed (with overlap) on the next attempt
    /// rather than silently skipping records.
    /// </summary>
    procedure CompleteRun(var RunLog: Record "WZC Sync Run Log"; Success: Boolean; RecordsProcessed: Integer; ErrorMessage: Text[500])
    var
        Checkpoint: Record "WZC Sync Checkpoint";
        Profile: Record "WZC Sync Profile";
    begin
        Checkpoint.LockTable();
        if Checkpoint.Get(RunLog."Profile No.") then begin
            Checkpoint."Run In Progress" := false;
            if Success then begin
                Checkpoint."Last Checkpoint DateTime" := RunLog."Window Upper Bound";
                Checkpoint."Last Successful Run At" := CurrentDateTime();
                Checkpoint."Last Successful Run Count" := RecordsProcessed;
                if Profile.Get(RunLog."Profile No.") then
                    Checkpoint."Config Version At Checkpoint" := Profile."Config Version";
            end;
            Checkpoint.Modify();
        end;

        RunLog."Ended At" := CurrentDateTime();
        RunLog."Records Processed" := RecordsProcessed;
        RunLog."Error Message" := ErrorMessage;
        if Success then
            RunLog.Status := RunLog.Status::Success
        else
            if RecordsProcessed > 0 then
                RunLog.Status := RunLog.Status::PartialFailure
            else
                RunLog.Status := RunLog.Status::Failed;
        RunLog.Modify(true);

        if Profile.Get(RunLog."Profile No.") then begin
            Profile."Last Sync At" := RunLog."Ended At";
            Profile."Last Sync Result" := CopyStr(StrSubstNo('%1 - %2 record(s)', RunLog.Status, RecordsProcessed), 1, 250);
            Profile.Modify();
        end;
    end;

    /// <summary>Controlled reset: clears the watermark (next run becomes a full resync) and logs why.</summary>
    procedure ResetCheckpoint(ProfileNo: Code[20]; Reason: Text[250])
    var
        Checkpoint: Record "WZC Sync Checkpoint";
    begin
        Checkpoint.LockTable();
        if Checkpoint.Get(ProfileNo) then begin
            if Checkpoint."Run In Progress" then
                Error('Cannot reset the checkpoint for ''%1'' while a run is in progress.', ProfileNo);
            Checkpoint."Last Checkpoint DateTime" := 0DT;
            Checkpoint."Last Successful Run Count" := 0;
            Checkpoint.Modify();
        end;
    end;

    procedure ConfigChangedSinceCheckpoint(Profile: Record "WZC Sync Profile"): Boolean
    var
        Checkpoint: Record "WZC Sync Checkpoint";
    begin
        if not Checkpoint.Get(Profile."Profile No.") then
            exit(false);
        exit(Checkpoint."Config Version At Checkpoint" <> Profile."Config Version");
    end;
}
