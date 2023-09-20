/**
 * @description       : THIS CLASS IS USED FOR AGGREGATOR API WEBSERVICE QUICK QUOTE GENERATION
 * @author            : Supriyo Seni
 * @group             : Agreegator API
 * @last modified on  : 09-01-2023
 * @last modified by  : Supriyo Seni
**/

public with sharing class QuoteWebServiceAPIHelper {
    public static List<QuoteJSONWrapper.ErrorResponse> listOfErrorResponses = new List<QuoteJSONWrapper.ErrorResponse>();
    public static Boolean errFlag = false;

    /**
    * @description 
    * @author Supriyo Seni | 08-28-2023 
    * @param errorMessage 
    * @param errorCode 
    * @return Boolean 
    **/
    // public static Boolean createErrorResponse(String errorMessage, String errorCode){
    //     QuoteJSONWrapper.ErrorResponse errorResponse = new QuoteJSONWrapper.ErrorResponse();
    //     errorResponse.message = errorMessage;
    //     errorResponse.errorCode = errorCode;
    //     listOfErrorResponses.add(errorResponse);
    //     // errorFlag = true;
    //     return true;
    // }

    public static void createErrorResponse(String errorMessage, String errorCode){
        QuoteJSONWrapper.ErrorResponse errorResponse = new QuoteJSONWrapper.ErrorResponse();
        errorResponse.errorMessage = errorMessage;
        errorResponse.errorCode = errorCode;
        listOfErrorResponses.add(errorResponse);
    }

    /**
    * @description 
    * @author Supriyo Seni | 09-01-2023 
    * @param obj 
    * @param errorMessage 
    **/
    public static void requiredSectionValidation(object obj, String errorMessage){
        if(obj == null) {
            createErrorResponse(errorMessage,'REQUIRED_DATA_MISSING');
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 09-01-2023 
    * @param quotePayLoad 
    **/
    public static void doPrimaryCheck(QuoteJSONWrapper quotePayLoad){
        requiredSectionValidation(quotePayLoad.personalDetails);
        requiredSectionValidation(quotePayLoad.contactDetails);
        requiredSectionValidation(quotePayLoad.loanDetails);
        requiredSectionValidation(quotePayLoad.driverLicenceDetails);
        requiredSectionValidation(quotePayLoad.addressDetails);
        requiredSectionValidation(quotePayLoad.brokerDetails);
        requiredSectionValidation(quotePayLoad.quoteConsentDetails);
        if(!listOfErrorResponses.isEmpty()){
            return listOfErrorResponses;
        }
    }

    public static void doSecondaryNullCheck(QuoteJSONWrapper quotePayLoad){
        requiredFieldValidation(quotePayLoad.personalDetails.firstName);
        requiredFieldValidation(quotePayLoad.personalDetails.lastName);
        requiredFieldValidation(quotePayLoad.personalDetails.gender);
        requiredSectionValidation(quotePayLoad.personalDetails.dateOfBirthDetails);

        requiredFieldValidation(quotePayLoad.contactDetails.emailAddress);
        requiredFieldValidation(quotePayLoad.contactDetails.mobileNumber);

        requiredFieldValidation(quotePayLoad.loanDetails.term);
        requiredFieldValidation(quotePayLoad.loanDetails.loanAmount);
        requiredFieldValidation(quotePayLoad.loanDetails.loanPurpose);

        requiredFieldValidation(quotePayLoad.driverLicenceDetails.isDriverLicenceAvailable);

        if(!listOfErrorResponses.isEmpty()){
            return listOfErrorResponses;
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 08-28-2023 
    * @param quotePayLoad 
    * @return List<QuoteJSONWrapper.ErrorResponse> 
    **/
    public static List<QuoteJSONWrapper.ErrorResponse> validateRequest(QuoteJSONWrapper quotePayLoad){
        doPrimaryNullCheck(quotePayLoad);
        doSecondaryNullCheck(quotePayLoad);

        
        Boolean perDetailsErr = !requiredFieldValidation(quotePayLoad.personal_details,'Personal details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.') ? validatePersonalDetails(quotePayLoad.personal_details) : false;
        Boolean dobErrpor = (quotePayLoad.dob_details != null) ? validateDobDetails(quotePayLoad.dob_details) : createErrorResponse('DOB details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
        Boolean contactErr = (quotePayLoad.contact_details != null) ? validateContactDetails(quotePayLoad.contact_details) : createErrorResponse('Contact details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
        Boolean loanErr = (quotePayLoad.loan_details != null) ? validateLoanDetails(quotePayLoad.loan_details) : createErrorResponse('Loan details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
        Boolean idenErr = (quotePayLoad.identification_details != null) ? validateIdentityDetails(quotePayLoad.identification_details) : false;
        Boolean addressErr = (quotePayLoad.address_details != null) ? validateAddressDetails(quotePayLoad.address_details,quotePayLoad.postaladdress_details) : createErrorResponse('Address details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
        Boolean gpoAddsErr = validateGpoAddDetails(quotePayLoad.postaladdress_details,quotePayLoad.gpoaddress_details);
        Boolean brokerErr = validateBrokerDetails(quotePayLoad.broker_details);
        Boolean consentErr = validateConsentDetails(quotePayLoad.quoteconsent_details,quotePayLoad.contact_details);
        errFlag = (perDetailsErr || dobErrpor || contactErr || loanErr || idenErr || addressErr || gpoAddsErr || brokerErr || consentErr);
        if(listOfErrorResponses != null && listOfErrorResponses.size()>0){
            return listOfErrorResponses;
        }
        return null;
    }

    /**
    * @description 
    * @author Supriyo Seni | 08-30-2023 
    * @param obj 
    * @param errorMessage 
    * @return Boolean 
    **/
    public static Boolean requiredFieldValidation(object obj, String errorMessage){
        return (obj == null) ? createErrorResponse(errorMessage,'REQUIRED_DATA_MISSING') : false;
    }

    /**
    * @description 
    * @author Supriyo Seni | 08-30-2023 
    * @param name 
    * @param errorMessage 
    * @return Boolean 
    **/
    public static Boolean nameValidation(String name){
        return (!name.isAlphaSpace() || !(name.trim().length() >= 2 && 
                name.trim().length() <= 15)) ? createErrorResponse('Only upper and lower case characters, - and space allowed in between 2-15 characters.','VALIDATION_ERROR') : false;
    }

    public static Boolean isStringWithinLength(String str, Integer startLength, Integer endLength){
        return (!(str.trim().length() >= startLength && str.trim().length() <= endLength));
    }

    /**
    * @description 
    * @author Supriyo Seni | 08-30-2023 
    * @param personalDetails 
    * @return Boolean 
    **/
    public static Boolean validatePersonalDetails(QuoteJSONWrapper.PersonalDetails personalDetails ){
        List<String> genders = new  List<String>();
        genders = ('male,female,other,unknown').split(',');
        Boolean firstNameError = !requiredFieldValidation(personalDetails.firstName,'First name can not be blank') ? nameValidation(personalDetails.firstName) : false;
        Boolean lastNameError = !requiredFieldValidation(personalDetails.lastName,'Last name can not be blank') ? nameValidation(personalDetails.lastName) : false;
        Boolean midNameErr = (personalDetails.middleName != null) ? nameValidation(personalDetails.middleName) : false;
        Boolean genderErr = !requiredFieldValidation(personalDetails.gender,'Gender can not be blank') ? genders.contains(personalDetails.gender.trim().toLowerCase()) ? (personalDetails.gender.trim().toLowerCase().equals('other') && personalDetails.otherGenderSpecification == null) ?  
                createErrorResponse('Other gender specification field can not be blank when you are choosing gender value as Other', 'REQUIRED_PARAM_MISSING') : false : (createErrorResponse('Required value (Male, Female, Other, Unknown) is missing for gender', 'VALIDATION_ERROR')) : false;
        return (firstNameError ||  lastNameError || midNameErr || genderErr);
    }

    /**
    * @description 
    * @author Supriyo Seni | 08-28-2023 
    * @param personalDetails 
    * @return Boolean 
    **/
    // public static Boolean validatePersonalDetails(QuoteJSONWrapper.PersonalDetails personalDetails ){
    //     Boolean firstNameError = (personalDetails.firstName == null) ? createErrorResponse('First name can not be blank', 'REQUIRED_PARAM_MISSING') : 
    //         (!personalDetails.firstName.isAlphaSpace() || !(personalDetails.firstName.trim().length() >= 2 && personalDetails.firstName.trim().length() <= 15)) ? 
    //         createErrorResponse('Only upper and lower case characters, - and space allowed in between 2-15 characters for First Name.', 'VALIDATION_ERROR') : false;
    //     Boolean lastNameError = (personalDetails.lastName == null) ? createErrorResponse('Last name can not be blank', 'REQUIRED_PARAM_MISSING') : 
    //         (!personalDetails.lastName.isAlphaSpace() || !(personalDetails.lastName.trim().length() >= 2 && personalDetails.lastName.trim().length() <= 15)) ? 
    //         createErrorResponse('Only upper and lower case characters, - and space allowed in between 2-15 characters for Last Name.', 'VALIDATION_ERROR') : false;
    //     Boolean midNameErr = (personalDetails.middleName != null && (!personalDetails.middleName.isAlphaSpace() || !(personalDetails.middleName.trim().length() >= 2 && personalDetails.middleName.trim().length() <= 15))) ? 
    //         createErrorResponse('Only upper and lower case characters, - and space allowed in between 2-15 characters for Middle Name.', 'VALIDATION_ERROR') : false;
    //     Boolean genderErr = (personalDetails.gender == null) ? createErrorResponse('Gender can not be blank', 'REQUIRED_PARAM_MISSING') : 
    //         (!(personalDetails.gender.trim().toLowerCase().equals('male') || personalDetails.gender.trim().toLowerCase().equals('female') || personalDetails.gender.trim().toLowerCase().equals('other') || personalDetails.gender.trim().toLowerCase().equals('unknown'))) ? 
    //         createErrorResponse('Required value (Male, Female, Other, Unknown) is missing for gender', 'VALIDATION_ERROR') : (personalDetails.gender.trim().toLowerCase().equals('other') && personalDetails.otherGenderSpecification == null) ?  
    //         createErrorResponse('Other gender specification field can not be blank when you are choosing gender value as Other', 'REQUIRED_PARAM_MISSING') : false;
    //     return (firstNameError ||  lastNameError || midNameErr || genderErr);
    // }

    /**
    * @description 
    * @author Supriyo Seni | 08-28-2023 
    * @param dobDetails 
    * @return Boolean 
    **/
    public static Boolean validateDobDetails(QuoteJSONWrapper.DOBDetails dobDetails){
        Boolean otherDobErr = false;
        if (dobDetails.birthDate == null || dobDetails.birthMonth == null || dobDetails.birthYear == null) {
            otherDobErr = createErrorResponse('One of Birth date, Birth month and Birth year is blank', 'REQUIRED_PARAM_MISSING');
        }else if ( !(((Date.newInstance(dobDetails.birthYear, dobDetails.birthMonth, dobDetails.birthDate).daysBetween(System.today()))/365) >= 18)) {
            otherDobErr = createErrorResponse('Must be of 18 years old.', 'VALIDATION_ERROR');
        }
        return otherDobErr;
    }

    /**
    * @description 
    * @author Supriyo Seni | 08-28-2023 
    * @param contactDetails 
    * @return Boolean 
    **/
    public static Boolean validateContactDetails(QuoteJSONWrapper.ContactDetails contactDetails){
        Boolean emailAddErr = false;
        Boolean mobNumberErr = false;
        if (contactDetails.emailAddress == null) {
            emailAddErr =  createErrorResponse('Email address can not be blank', 'REQUIRED_PARAM_MISSING');
        }else if (!(contactDetails.emailAddress.trim().length() >= 4 && contactDetails.emailAddress.trim().length() <= 60)) {
            emailAddErr = createErrorResponse('Valid email must be in between 4-60 characters.', 'VALIDATION_ERROR');
        }else if(!validateEmail(contactDetails.emailAddress.trim())){
            emailAddErr = createErrorResponse('Email format is not correct or valid domain name has not been provided', 'VALIDATION_ERROR');
        }
        if (contactDetails.mobileNumber == null) {
            mobNumberErr = createErrorResponse('Mobile number can not be blank', 'REQUIRED_PARAM_MISSING');
        }else if(!contactDetails.mobileNumber.trim().substring(1).isNumeric() || !(contactDetails.mobileNumber.trim().substring(1).length() == 8)){
            mobNumberErr = createErrorResponse('Valid mobile number must be 8 digit number.', 'VALIDATION_ERROR');
        }
        return (emailAddErr || mobNumberErr);
    }

    /**
    * @description 
    * @author Supriyo Seni | 08-28-2023 
    * @param loanDetails 
    * @return Boolean 
    **/
    public static Boolean validateLoanDetails(QuoteJSONWrapper.LoanDetails loanDetails){
        Boolean termErr = false;
        Boolean freqErr = false;
        Boolean amountErr = false;
        Boolean purposeErr = false;
        Boolean assetErr = false;
        if (loanDetails.term == null) {
            termErr = createErrorResponse('Loan term can not be blank', 'REQUIRED_PARAM_MISSING');
        }else if (!loanDetails.term.trim().isNumeric() || !((Integer.valueOf(loanDetails.term.trim()) >= 2) && (Integer.valueOf(loanDetails.term.trim()) <= 7))) {
            termErr = createErrorResponse('Loan term must be a number between 2 and 7', 'VALIDATION_ERROR');
        }
        if (loanDetails.repaymentFrequency == null) {
            freqErr = createErrorResponse('Loan payment frequency can not be blank', 'REQUIRED_PARAM_MISSING');
        }else if (!(loanDetails.repaymentFrequency.trim().toLowerCase().equals('weekly') || loanDetails.repaymentFrequency.trim().toLowerCase().equals('bi-weekly') || loanDetails.repaymentFrequency.trim().toLowerCase().equals('monthly'))) {
            freqErr = createErrorResponse('Loan payment frequency must be one of Weekly, Bi-Weekly and Monthly', 'VALIDATION_ERROR');
        }
        if (loanDetails.loanAmount == null) {
            amountErr = createErrorResponse('Loan amount can not be blank', 'REQUIRED_PARAM_MISSING');
        }else if (!loanDetails.loanAmount.trim().isNumeric() || !(Integer.valueOf(loanDetails.loanAmount.trim()) >= 5000 && Integer.valueOf(loanDetails.loanAmount.trim()) <= 200000)) {
            amountErr = createErrorResponse('Loan amount must be in between 5000 to 200000', 'VALIDATION_ERROR');
        }
        if (loanDetails.loanPurpose == null) {
            purposeErr = createErrorResponse('Loan purpose can not be blank', 'REQUIRED_PARAM_MISSING');
        }
        if (loanDetails.assetType == null) {
            assetErr = createErrorResponse('Loan asset type can not be blank', 'REQUIRED_PARAM_MISSING');
        }else if(!(loanDetails.assetType.trim().toLowerCase().equals('auto') || loanDetails.assetType.trim().toLowerCase().equals('marine') || loanDetails.assetType.trim().toLowerCase().equals('motorhome') || loanDetails.assetType.trim().toLowerCase().equals('motorcycle'))){
            assetErr = createErrorResponse('Loan asset type required value missing', 'VALIDATION_ERROR');
        }
        return (termErr ||freqErr || amountErr || purposeErr || assetErr);
    }

    /**
    * @description 
    * @author Supriyo Seni | 08-28-2023 
    * @param identificationInfo 
    * @return Boolean 
    **/
    public static Boolean validateIdentityDetails(QuoteJSONWrapper.IdentificationDetails identificationInfo){
        Boolean dlErr = false;
        Boolean dlNumberErr = false;
        if (identificationInfo.isDriverLicenceAvailable == true && (identificationInfo.driverLicenceNumber == null || identificationInfo.licenceCardNumber == null || identificationInfo.stateOfIssue == null)) {
            dlErr = createErrorResponse('Some of Identification info blank whereas DriverLicenceAvailable checkbox has been chosen as true', 'REQUIRED_DATA_MISSING');
        }
        if (identificationInfo.driverLicenceNumber != null && !(identificationInfo.driverLicenceNumber.trim().length() >= 5 && identificationInfo.driverLicenceNumber.trim().length() <= 9)) {
            dlNumberErr = createErrorResponse('Driver licence number have to be in between 5-9 characters', 'VALIDATION_ERROR');
        }else if (identificationInfo.stateOfIssue != null && identificationInfo.stateOfIssue.trim().length() != 3) {
            dlNumberErr =  createErrorResponse('State of issue must consist of 3 characters', 'VALIDATION_ERROR');
        }
        return (dlErr || dlNumberErr);
    }

    /**
    * @description 
    * @author Supriyo Seni | 08-28-2023 
    * @param addressDetails 
    * @param postalAddressDetails 
    * @return Boolean 
    **/
    public static Boolean validateAddressDetails(QuoteJSONWrapper.AddressDetails addressDetails,QuoteJSONWrapper.PostalAddressDetails postalAddressDetails){
        Boolean unitNumErr = false;
        Boolean postalErr = false;
        Boolean mailingAddErr = false;
        if (((addressDetails.unitNumber != null && !addressDetails.unitNumber.trim().isNumeric())) || ((addressDetails.postalCode != null && !addressDetails.postalCode.trim().isNumeric()))) {
            unitNumErr = createErrorResponse('Unit number and postal code must be a number.', 'VALIDATION_ERROR');
        }
        if (addressDetails.postalCode == null || addressDetails.stateAddress == null || addressDetails.streetNumber == null || addressDetails.residentialStatus == null || addressDetails.streetName == null || addressDetails.city == null || addressDetails.streetTypeAddress == null) {
            postalErr = createErrorResponse('One of required fields for address is missing', 'REQUIRED_PARAM_MISSING');
        }else if (addressDetails.streetNumber != null && !(addressDetails.streetNumber.trim().length() >= 1 && addressDetails.streetNumber.trim().length() <= 8)) {
            postalErr = createErrorResponse('Street number must lie between 1-8 characters.', 'VALIDATION_ERROR');
        }
        if (addressDetails.isMailingAddressSame == null && postalAddressDetails == null) {
            mailingAddErr = createErrorResponse('Postal address details not provided whereas IsMailingAddressSame has been chosen as false. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
        }else if(addressDetails.isMailingAddressSame == null && postalAddressDetails != null){
            if (postalAddressDetails.postalStreetNumber == null || postalAddressDetails.postalStateAddress == null || postalAddressDetails.postalStreetName == null || postalAddressDetails.postalCity == null || postalAddressDetails.postalStreetTypeAddress == null || postalAddressDetails.postalCode == null) {
                mailingAddErr = createErrorResponse('One of required fields for postal address is missing', 'REQUIRED_PARAM_MISSING');
            }else if (((postalAddressDetails.postalUnitNumber != null && !postalAddressDetails.postalUnitNumber.trim().isNumeric())) || ((postalAddressDetails.postalCode != null && !postalAddressDetails.postalCode.trim().isNumeric()))) {
                mailingAddErr = createErrorResponse('Unit number and postal code of postal address must be a number.', 'VALIDATION_ERROR');
            }
        }
        return (unitNumErr || postalErr || mailingAddErr);
    }

    /**
    * @description 
    * @author Supriyo Seni | 08-28-2023 
    * @param postalAddressDetails 
    * @param gpoAddressDetails 
    * @return Boolean 
    **/
    public static Boolean validateGpoAddDetails(QuoteJSONWrapper.PostalAddressDetails postalAddressDetails,QuoteJSONWrapper.GPOAddressDetails gpoAddressDetails){
        Boolean isErr = false;
        if (postalAddressDetails != null && postalAddressDetails.poGpoAddressFlag == true && gpoAddressDetails == null) {
            isErr  = createErrorResponse('GPO Address details not provided whereas PoGpoAddressFlag has been chosen as true. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
        }else if (postalAddressDetails != null && postalAddressDetails.poGpoAddressFlag == true && gpoAddressDetails != null && gpoAddressDetails.poBoxNumber == null || gpoAddressDetails.postalBoxCity == null || gpoAddressDetails.poBoxPostalCode == null || gpoAddressDetails.postalBoxStateAddress == null) {
            isErr = createErrorResponse('One of required fields for GPO address is missing', 'REQUIRED_PARAM_MISSING');
        }
        return isErr;
    }

    /**
    * @description 
    * @author Supriyo Seni | 08-28-2023 
    * @param brokerDetails 
    * @return Boolean 
    **/
    public static Boolean validateBrokerDetails(QuoteJSONWrapper.BrokerDetails brokerDetails){
        Boolean brokerErr = false;
        if (brokerDetails == null || brokerDetails.brokerFeeAmount == null || brokerDetails.brokerId == null) {
            brokerErr = createErrorResponse('Broker details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
        }else if(brokerDetails.brokerId != null){
            List<Contact> brokerContactDetails = [SELECT Id,
                                                    brk_AccreditationStatus__c,
                                                    Email,
                                                    Broker_ID__c,
                                                    Account.id 
                                                FROM Contact 
                                                WHERE Broker_ID__c =: brokerDetails.brokerId 
                                                AND brk_AccreditationStatus__c = 'Active' 
                                                WITH SECURITY_ENFORCED 
                                                LIMIT 1];
            if (brokerContactDetails.isEmpty()) {
                brokerErr  = createErrorResponse('Active broker not found. Contact the Salesforce Admin for help.', 'BROKER_UNAVAILABLE');
            }
        }
        return brokerErr;
    }

    /**
    * @description 
    * @author Supriyo Seni | 08-28-2023 
    * @param quoteConsentDetails 
    * @param contactDetails 
    * @return Boolean 
    **/
    public static Boolean validateConsentDetails(QuoteJSONWrapper.QuoteConsentDetails quoteConsentDetails,QuoteJSONWrapper.ContactDetails contactDetails){
        Boolean consentErr = false;
        if (quoteConsentDetails == null || quoteConsentDetails.quoteConsent == null || quoteConsentDetails.quoteConsent == false) {
            consentErr = createErrorResponse('Quote consent details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
        }
        List<genesis__Quick_Quotes__c> qqListExisiting = [SELECT id,
                                                            Name
                                                        FROM genesis__Quick_Quotes__c
                                                        WHERE Email__c =: contactDetails.emailAddress.trim() 
                                                        WITH SECURITY_ENFORCED LIMIT 1];
        if (!qqListExisiting.isEmpty()) {
            consentErr = createErrorResponse('Another Quote with same email already exists in the system - ' + qqListExisiting[0].Name + '.Contact the Salesforce Admin for help.', 'VALIDATION_ERROR');
        }
        return consentErr;
    }

    public static Boolean validateEmail(String email) {
        final String DOMAIN_1 = '.con';
        final String DOMAIN_2 = '.con.au';
        final String DOMAIN_3 = '.comm';
        final String DOMAIN_4 = '.comm.au';
        final String DOMAIN_5 = 'hotmsil.com';
        final String DOMAIN_6 = 'gmsil.com';
        final String AT_SIGN = '@';
        final List<String> INVALID_DOMAINS = new List<String>{'.con','.con.au','.comm','.comm.au','hotmsil.com','gmsil.com'};
        String domainPart = email.split(AT_SIGN)[1];
        for (String invalidDomain : INVALID_DOMAINS) {
            if (domainPart.contains(invalidDomain)) {
                return false;
            }
        }
        String emailRegex = '^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\\.[a-zA-Z]{2,4}$';
        Pattern emailPattern = Pattern.compile(emailRegex);
        Matcher emailMatcher = emailPattern.matcher(email);
        return emailMatcher.matches();
    }

    public static Id  createQuote(QuoteJSONWrapper quotePayLoad){
        String perInfo = ' { "first_Name": "Tony", "last_Name": "Stark", "middle_Name": "Junior", "gender": "Male", "birthDate": "23", "birthMonth": "04", "birthYear": "1991", "email_Address": "abc@mailnator.com", "confirm_Email_Address": "abc@mailnator.com", "please_specify": "", "mobile_Number": "012345678" }';
        String contactInfo = '{ "manual_Address_Flag" : true, "street_Type_Address" : "Street", "state_Address" : "NIC" }';
        String loanPurposeInfo = '{ "select_Loan_Purpose1" : "Private Sale", "select_Loan_Purpose2" : "", "Other_Loan_Purpose" : "" }';
        String loanAmtInfo = '{ "loan_Term" : "4", "repayment_Frequency" : "Monthly", "loan_Amount" : "20000" }';
        String dlInfo = '{ "i_Dont_Have_A_Drivers_License" : false, "state_Of_Issue" : "NSW", "driver_License_Number" : "D888988", "license_Card_Number" : "1234567890" }';
        String addressInfo = '{ "postal_Code" : "3039", "unit_Number" : "10", "street_Number" : "118", "state_Address" : "VIC", "street_Name" : "Holmes", "city" : "Moonee Ponds", "street_Type_Address" : "Road", "residential_Status" : "Renting", "manual_Address_Flag" : "true", "home_Address" : "", "Property_Name" : "" }';
        String postAddInfo = '{ "Postal_address" : "3-39", "Postal_Unit_Number" : "10", "Postal_Street_Number" : "118", "Postal_State_Address" : "VIC", "Postal_Street_Name" : "Holmes", "Postal_City" : "Moonee Ponds", "Postal_Street_Type_Address" : "Road", "Po_Gpo_Address_Flag" : false, "Postal_Manual_Address_Flag" : "true", "Postal_address_search" : "", "Postal_Property_Name" : "", "Po_Postal_Code" : "", "Po_Property_Name" : "" }';
        String gpoAddInfo = '{ "Postal_Box_State_Address" : "", "Postal_Box_City" : "", "Po_box_number" : "", "Postal_State_Country" : "", "Po_Box_Postal_Code" : "" }';
        
        // CreateQQAction.PersonalInformation quotePerInfo = new  CreateQQAction.PersonalInformation();
        // quotePerInfo.first_Name = quotePayLoad.personal_details.firstName;
        // quotePerInfo.last_Name = quotePayLoad.personal_details.lastName;
        // quotePerInfo.middle_Name = quotePayLoad.personal_details.middleName;
        // quotePerInfo.gender = quotePayLoad.personal_details.gender;
        // quotePerInfo.birthDate = quotePayLoad.dob_details.birthDate;
        // quotePerInfo.birthMonth = quotePayLoad.dob_details.birthMonth;
        // quotePerInfo.birthYear = quotePayLoad.dob_details.birthYear;
        // quotePerInfo.email_Address = quotePayLoad.contact_details.emailAddress;
        // quotePerInfo.confirm_Email_Address = quotePayLoad.contact_details.emailAddress;
        // quotePerInfo.please_specify = quotePayLoad.personal_details.otherGenderSpecification;
        // quotePerInfo.mobile_Number = quotePayLoad.contact_details.mobileNumber;
        CreateQQAction qqObj = new CreateQQAction();
        qqObj.parsePersonalInformation(perInfo);
        qqObj.parseContactDetails(contactInfo);
        qqObj.parseLoanPurpose(loanPurposeInfo);
        qqObj.parseLoanAmount(loanAmtInfo);
        qqObj.parseDrivingLicense(dlInfo);
        qqObj.parseHomeAddress(addressInfo);
        qqObj.parsePostalAddress(postAddInfo);
        qqObj.parseGpoAddress(gpoAddInfo);
        Wrapper.QuickQuoteWrapper qqWrap = qqObj.getQuickQuoteWrapper();

        // CreateQQAction.ContactDetails quoteContact = new  CreateQQAction.ContactDetails();
        // quoteContact.manual_Address_Flag = true;
        // quoteContact.street_Type_Address = quotePayLoad.address_details.streetTypeAddress;
        // quoteContact.state_Address = quotePayLoad.address_details.stateAddress;

        // CreateQQAction.LoanPurpose quoteLoan = new  CreateQQAction.LoanPurpose();
        // quoteLoan.select_Loan_Purpose1 = quotePayLoad.loan_details.loanPurpose;
        // quoteLoan.select_Loan_Purpose2 = '';
        // quoteLoan.Other_Loan_Purpose = '';

        // CreateQQAction.LoanAmount quoteLoanAmt = new  CreateQQAction.LoanAmount();
        // quoteLoanAmt.loan_Term = quotePayLoad.loan_details.term;
        // quoteLoanAmt.repayment_Frequency = quotePayLoad.loan_details.repaymentFrequency;
        // quoteLoanAmt.loan_Amount = quotePayLoad.loan_details.loanAmount;

        // CreateQQAction.DrivingLicense quoteDl= new  CreateQQAction.DrivingLicense();
        // quoteDl.i_Dont_Have_A_Drivers_License = quotePayLoad.identification_details.isDriverLicenceAvailable;
        // quoteDl.state_Of_Issue = quotePayLoad.identification_details.stateOfIssue;
        // quoteDl.driver_License_Number = quotePayLoad.identification_details.driverLicenceNumber;
        // quoteDl.license_Card_Number = quotePayLoad.identification_details.licenceCardNumber;

        // CreateQQAction.HomeAddress quoteAddress = new  CreateQQAction.HomeAddress();
        //quoteAddress.postal_Code = quotePayLoad.address_details.postalCode;

        // CreateQQAction qqObj = new CreateQQAction();
        // qqObj.perObj = quotePerInfo;
        // qqObj.conObj = quoteContact;
        // qqObj.loanPurposeObj = quoteLoan;
        // qqObj.loanAmountobj = quoteLoanAmt;
        // qqObj.drivingLicenseObj = quoteDl;
        // qqObj.homeAddObj = quoteAddress;


        boolean createAccount = true; //if account not present with the provided mail, create account
        List <Account> qqAccounts = new List<Account>();
        /* querying account based on mail provided to check for existing borrower account */
        qqAccounts = [ SELECT Id, 
                            Name, 
                            First_Name__c, 
                            Last_Name__c,
                            Date_of_Birth__c,
                            Gender__c,
                            Mobile_Number__c,
                            Account_Security_Token__c,
                            Email__c 
                        FROM Account 
                        WHERE Email__c  = : quotePayLoad.contact_details.emailAddress
                        WITH SECURITY_ENFORCED];

        if( !qqAccounts.isEmpty() && qqAccounts.size()  ==  1){
            createAccount  =  false;
            //check if same personal detail have been provided by the customer else update personal information
            if( qqAccounts[0].First_Name__c !=  qqWrap.fName 
                && qqAccounts[0].Last_Name__c !=  qqWrap.lName 
                && qqAccounts[0].Date_of_Birth__c !=  Date.valueOf(qqwrap.dob)
                && qqAccounts[0].Mobile_Number__c !=  qqWrap.mobileNumber){
                    qqAccounts[0].First_Name__c  =  qqWrap.fName;
                    qqAccounts[0].Last_Name__c  =  qqWrap.lName;
                    qqAccounts[0].Date_of_Birth__c  =  Date.valueOf(qqwrap.dob);
                    qqAccounts[0].Mobile_Number__c  =  qqWrap.mobileNumber;
                        upsert qqAccounts;
                }
        }else if(qqAccounts.size() > 1){
            throw new CustomException(ResponseMessenger.accNotFound);
        }
        String prodName = 'Motor Loan Fixed Rate';
        /* querying product based on product name to assign it to quick quote */
        clcommon__CL_Product__c prod =  [ SELECT  ID, 
                                                Name,
                                                clcommon__Product_Name__c
                                                FROM clcommon__CL_Product__c 
                                                WHERE clcommon__Product_Name__c  = :prodName
                                                WITH SECURITY_ENFORCED
                                                LIMIT 1 ];
        /* calling the check and create quote function for validating customer info */
        System.debug('qqWrap = '+qqWrap);
        System.debug('createAccount = '+createAccount);
        System.debug('qqAccounts = '+qqAccounts);
        System.debug('prod = '+prod);

        Id qqId  =  qqObj.checkAndCreateQuote(qqWrap, createAccount, qqAccounts, prod);
        return qqId;
    }
}