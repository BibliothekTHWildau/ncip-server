[%- SET format_ValidToDate = config.format_ValidToDate || '%Y-%m-%d' -%]
<UserId>
    [%- SWITCH config.lookup_user_id -%]
    [%- CASE 'same' -%]
	<UserIdentifierValue>[% user_id | xml %]</UserIdentifierValue>
    [%- CASE 'cardnumber' -%]
	<UserIdentifierValue>[% user.userdata.cardnumber | xml %]</UserIdentifierValue>
    [%- CASE 'userid' -%]
	<UserIdentifierValue>[% user.userdata.userid | xml %]</UserIdentifierValue>
    [%- CASE -%]
        ERROR: lookup_user_id is set to an invalid value!
    [%- END -%]
</UserId>

[%# <UserFiscalAccount></UserFiscalAccount>
LoanedItemsCount
LoanedItem
RequestedItemsCount
RequestedItem
-%]
[%- IF loaned_items -%]
  <LoanedItemsCount>
    <CirculationStatus/>
    <LoanedItemCountValue>[% loaned_items.itemsCount | xml %]</LoanedItemCountValue>
  </LoanedItemsCount>
  [%- FOREACH item IN loaned_items.items -%]
  <LoanedItem>
      <ItemId>
         <ItemIdentifierValue>[% item.barcode | xml %]</ItemIdentifierValue> 
      </ItemId>
      <ReminderLevel>0</ReminderLevel>
      <DateDue>[% item.date_due | xml %]</DateDue> 
      <Amount>
         <CurrencyCode/>
         <MonetaryValue>0</MonetaryValue>
      </Amount>
      <Title>[% item.title | xml %]</Title>
      <MediumType>[% item.itype | xml %]</MediumType>
      <Ext>
         <LocationNameValue>Halle 10 (Hochschulbibliothek)</LocationNameValue> 
         <PickupLocation>Theke</PickupLocation> 
         <Author></Author> 
         <LocationWithinBuilding>[% item.itemcallnumber | xml %]</LocationWithinBuilding> 
         <CirculationStatus></CirculationStatus>
         <DateCheckedOut>[% item.issue_date | xml %]</DateCheckedOut>
         <RenewalCount>[% item.renewals_count | xml %]</RenewalCount>
      </Ext>
   </LoanedItem>
  [%- END -%]
[%- END -%]

[%- IF requested_items -%]
  <RequestedItemsCount>
    <CirculationStatus/>
    <RequestedItemCountValue>[% requested_items.itemsCount | xml %]</RequestedItemCountValue>
  </RequestedItemsCount>
  [%- FOREACH item IN requested_items.items -%]
  <RequestedItem>
      <ItemId>
         <ItemIdentifierValue>[% item.barcode | xml %]</ItemIdentifierValue> 
      </ItemId>
      <ReminderLevel>0</ReminderLevel>
      <Title>[% item.title | xml %]</Title>
      <BibliographicId>[% item.BibliographicId | xml %]</BibliographicId>
      <MediumType>[% item.itype | xml %]</MediumType>
      <DatePlaced>[% item.DatePlaced | xml %]</DatePlaced>
      <PickupExpiryDate>[% item.PickupExpiryDate | xml %]</PickupExpiryDate>
      <RequestType>[% item.RequestType | xml %]</RequestType>
      <Ext>
         <LocationNameValue>[% item.LocationNameValue | xml %]</LocationNameValue> 
         <PickupLocation>[% item.PickupLocation | xml %]</PickupLocation> 
         <LocationWithinBuilding>[% item.itemcallnumber | xml %]</LocationWithinBuilding> 
         <CirculationStatus></CirculationStatus>
         <DateCheckedOut>[% item.issue_date | xml %]</DateCheckedOut>
         <RenewalCount>[% item.renewals_count | xml %]</RenewalCount>
      </Ext>
   </RequestedItem>
  [%- END -%]
[%- END -%]

<UserOptionalFields>
    [%- FOREACH element IN elements -%]
        [%- IF element.textContent == 'NameInformation' -%]
            <NameInformation>
                <PersonalNameInformation>
                    <StructuredPersonalUserName>
                        <GivenName>[% user.userdata.firstname | xml %]</GivenName>
                        <Surname>[% user.userdata.surname | xml %]</Surname>
                    </StructuredPersonalUserName>
                </PersonalNameInformation>
            </NameInformation>
        [%- END -%]

        [%- IF element.textContent == 'UserAddressInformation' -%]
            <UserAddressInformation>
                <UserAddressRoleType>Home</UserAddressRoleType>
                <PhysicalAddress>
                    <StructuredAddress>
                        <Line1>[% FILTER collapse %][% user.userdata.streetnumber | xml %] [% user.userdata.address | xml %][% END %]</Line1>

                        <Street>[% FILTER collapse %][% user.userdata.streetnumber | xml %] [% user.userdata.address | xml %][% END %]</Street>

                        [%- IF user.userdata.address2 -%]
                            <Line2>[% user.userdata.address2 | xml %]</Line2>
                        [%- END -%]

                        [%- IF user.userdata.city -%]
                            <Locality>[% user.userdata.city | xml %]</Locality>
                        [%- END -%]

                        [%- IF user.userdata.state -%]
                            <Region>[% user.userdata.state | xml %]</Region>
                        [%- END -%]

                        [%- IF user.userdata.zipcode -%]
                            <PostalCode>[% user.userdata.zipcode | xml %]</PostalCode>
                        [%- END -%]

                        [%- IF user.userdata.country -%]
                            <Country>[% user.userdata.country | xml %]</Country>
                        [%- END -%]
                    </StructuredAddress>
                    <PhysicalAddressType>Postal Address</PhysicalAddressType>
                </PhysicalAddress>
            </UserAddressInformation>

            [%- IF user.userdata.email -%]
                <UserAddressInformation>
                    <UserAddressRoleType>Home</UserAddressRoleType>
                    <ElectronicAddress>
                        <ElectronicAddressType>mailto</ElectronicAddressType>
                        <ElectronicAddressData>[% user.userdata.email %]</ElectronicAddressData>
                    </ElectronicAddress>
                </UserAddressInformation>
            [%- END -%]

            [%- IF user.userdata.phone -%]
                <UserAddressInformation>
                    <UserAddressRoleType>Home</UserAddressRoleType>
                    <ElectronicAddress>
                        <ElectronicAddressType>tel</ElectronicAddressType>
                        <ElectronicAddressData>[% user.userdata.phone %]</ElectronicAddressData>
                    </ElectronicAddress>
                </UserAddressInformation>
            [%- END -%]

            [%- IF user.userdata.phonepro || user.userdata.mobile -%]
                <UserAddressInformation>
                    <UserAddressRoleType>Mobile</UserAddressRoleType>
                    <ElectronicAddress>
                        <ElectronicAddressType>tel</ElectronicAddressType>
                        <ElectronicAddressData>[% user.userdata.phonepro || user.userdata.mobile %]</ElectronicAddressData>
                    </ElectronicAddress>
                </UserAddressInformation>
            [%- END -%]
        [%- END -%]

        [%- IF element.textContent == 'UserPrivilege' -%]
            <UserPrivilege>
                <AgencyUserPrivilegeType>LIBRARY</AgencyUserPrivilegeType>
                <UserPrivilegeStatus>
                    <UserPrivilegeStatusType>[% user.userdata.branchcode %]</UserPrivilegeStatusType>
                </UserPrivilegeStatus>
            </UserPrivilege>

            <UserPrivilege>
                <AgencyUserPrivilegeType>PROFILE</AgencyUserPrivilegeType>
                <UserPrivilegeStatus>
                    <UserPrivilegeStatusType>[% user.userdata.categorycode %]</UserPrivilegeStatusType>
                </UserPrivilegeStatus>
            </UserPrivilege>

            <UserPrivilege>
                <AgencyUserPrivilegeType>STATUS</AgencyUserPrivilegeType>
                <ValidToDate>[% user.userdata.dateexpiry_dt.strftime(format_ValidToDate) %]</ValidToDate>
                <UserPrivilegeStatus>
                    [%- FILTER collapse -%]
                        <UserPrivilegeStatusType>[%- FILTER collapse -%]
                                [%- IF user.userdata.restricted == -1 # overdues block circ-%]
                                    Delinquent
                                [%- ELSIF user.userdata.restricted == 1 # has restriction-%]
                                    Restricted
                                [%- ELSIF user.userdata.restricted == 2 # fees block circ -%]
                                    Barred
                                [%- ELSE -%]
                                    Ok
                                [%- END -%]
                        [%- END -%]</UserPrivilegeStatusType>
                    [%- END -%]
                </UserPrivilegeStatus>
            </UserPrivilege>
        [%- END -%]

        [%- IF user.userdata.restricted != 0 -%]
            <BlockOrTrap>
                <AgencyId>[% to_agency | trim %]</AgencyId>
                <BlockOrTrapType>Block Check Out</BlockOrTrapType>
            </BlockOrTrap>
        [% END %]
    [%- END -%]

    [%- UNLESS config.do_not_include_user_identifier_primary_key -%]
        <UserId>
            <UserIdentifierType>Primary Key</UserIdentifierType>
            <UserIdentifierValue>[% user.userdata.borrowernumber %]</UserIdentifierValue>
        </UserId>
    [%- END -%]
</UserOptionalFields>
