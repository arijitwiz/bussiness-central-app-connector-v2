page 50132 "WZC Customer Contact Part"
{
    PageType = API;
    APIPublisher = 'wizcommerce';
    APIGroup = 'connector';
    APIVersion = 'v2.0';
    EntityCaption = 'Wiz Customer Contact';
    EntitySetCaption = 'Wiz Customer Contacts';
    EntityName = 'wizCustomerContact';
    EntitySetName = 'wizCustomerContacts';
    SourceTable = "Contact Business Relation";
    SourceTableView = where("Link to Table" = const(Customer));
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Contacts linked to the customer through Contact Business Relation, inline under wizCustomers ($expand=wizCustomerContacts). Read-only here; create contacts through the standard contacts API.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(customerNumber; Rec."No.")
                {
                    Caption = 'Customer Number';
                }
                field(contactNo; Rec."Contact No.")
                {
                    Caption = 'Contact No.';
                }
                field(businessRelationCode; Rec."Business Relation Code")
                {
                    Caption = 'Business Relation Code';
                }
                field(contactType; ContactType)
                {
                    Caption = 'Contact Type';
                    Editable = false;
                }
                field(name; ContactName)
                {
                    Caption = 'Name';
                    Editable = false;
                }
                field(email; ContactEmail)
                {
                    Caption = 'E-Mail';
                    Editable = false;
                }
                field(phoneNo; ContactPhoneNo)
                {
                    Caption = 'Phone No.';
                    Editable = false;
                }
                field(mobilePhoneNo; ContactMobilePhoneNo)
                {
                    Caption = 'Mobile Phone No.';
                    Editable = false;
                }
                field(jobTitle; ContactJobTitle)
                {
                    Caption = 'Job Title';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
            }
        }
    }

    var
        ContactType: Text[30];
        ContactName: Text[100];
        ContactEmail: Text[80];
        ContactPhoneNo: Text[30];
        ContactMobilePhoneNo: Text[30];
        ContactJobTitle: Text[30];

    trigger OnAfterGetRecord()
    var
        Contact: Record Contact;
    begin
        Clear(ContactType);
        Clear(ContactName);
        Clear(ContactEmail);
        Clear(ContactPhoneNo);
        Clear(ContactMobilePhoneNo);
        Clear(ContactJobTitle);
        if not Contact.Get(Rec."Contact No.") then
            exit;
        ContactType := CopyStr(Format(Contact.Type), 1, MaxStrLen(ContactType));
        ContactName := Contact.Name;
        ContactEmail := Contact."E-Mail";
        ContactPhoneNo := Contact."Phone No.";
        ContactMobilePhoneNo := Contact."Mobile Phone No.";
        ContactJobTitle := Contact."Job Title";
    end;
}
