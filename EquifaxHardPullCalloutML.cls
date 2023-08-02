/*********************************************************************************************************
Class          : Equifaxsoftpullcallout
Description    : Callout class for cascading integrations id matrix and equifax score seeker on the quick quote
Created Date   : 06/12/2021
Developer      : Rajashree Das
**********************************************************************************************************/

global without sharing class EquifaxHardPullCalloutML
{   
    global static void callout() {
        Map<String, String> queryIdMap = new Map<String, String>();
        Map<String, Object> requestParamMap = new Map<String, Object>();
        intframework.AbstractIntegrationService baseintegrationService = intframework.IntegrationServiceFactory.getBaseIntegrationService();
        intframework.BaseIntegrationResponse responseObject;
        responseObject = (intframework.BaseIntegrationResponse) baseintegrationService.runSynchronousIntegrationService(ConstantValues.EQUIFAX_FAMILY_NAME,
                                                                                                                        'EquifaxHardPull',
                                                                                                                        queryIdMap,
                                                                                                                        requestParamMap);
        
        if(String.isBlank(responseObject.getBody()) && responseObject.getStatusCode() == CpConstants.TWO_HUNDRED ){
            throw new CustomException(ResponseMessenger.somethingWentWrong);
        }  
        // System.debug('responseObject'+responseObject);
        // System.debug('bureauReference ='+responseObject.responseMap);
        // System.debug('res.scoreData) = '+responseObject.getResponseMap());
        String xmlResBody = responseObject.getBody();
        //Map<String,Object> resMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        createVedaResponse(xmlResBody);
    }

    public static void createVedaResponse(String xmlResBody){
        ints.VedaComprehensiveResponse veda = new ints.VedaComprehensiveResponse();
        ints.VedaComprehensiveResponse.Error vedaErrRes = new ints.VedaComprehensiveResponse.Error();
        ints.VedaComprehensiveResponse.GeneralMessages vedaGenMsgRes = new ints.VedaComprehensiveResponse.GeneralMessages();
        ints.VedaComprehensiveResponse.CreditEnquiry credEnqRes= new ints.VedaComprehensiveResponse.CreditEnquiry();
        ints.VedaComprehensiveResponse.Employer empRes = new ints.VedaComprehensiveResponse.Employer();
        ints.VedaComprehensiveResponse.OtherIdentity othRes = new ints.VedaComprehensiveResponse.OtherIdentity();
        ints.VedaComprehensiveResponse.account resAcc = new ints.VedaComprehensiveResponse.account();
        ints.VedaComprehensiveResponse.VedaComprehensivedefault VedaDef = new ints.VedaComprehensiveResponse.VedaComprehensivedefault();
        ints.VedaComprehensiveResponse.payment payHistory = new ints.VedaComprehensiveResponse.payment();
        ints.VedaComprehensiveResponse.Score sData = new ints.VedaComprehensiveResponse.Score(); 
        ints.VedaComprehensiveResponse.ContributingFactor conFact = new ints.VedaComprehensiveResponse.ContributingFactor();
        ints.VedaComprehensiveResponse.DataBlock dB = new ints.VedaComprehensiveResponse.DataBlock();
        ints.VedaComprehensiveResponse.Characteristic cha = new ints.VedaComprehensiveResponse.Characteristic();
        ints.VedaComprehensiveResponse.possibleMatch pbRes = new ints.VedaComprehensiveResponse.possibleMatch();
        ints.VedaComprehensiveResponse.FileNote fnRes = new ints.VedaComprehensiveResponse.FileNote();
        ints.VedaComprehensiveResponse.businessName bsnRes = new ints.VedaComprehensiveResponse.businessName();
        ints.VedaComprehensiveResponse.Directorship dsRes = new ints.VedaComprehensiveResponse.Directorship();
        // Updating variables of veda comprehensive
        Dom.Document doc = new Dom.Document();
        doc.load(xmlResBody);
		Map<String, Object> resMap= intframework.XmlToJson.parseDocumentToMap(doc);
        veda.xmlResponse = xmlResBody;
        veda.xmlRequest = null;
        if(resMap != null && resMap.containsKey('Envelope')){
            Map<String, Object> envResMap = (Map<String, Object>)resMap.get('Envelope');
            if(envResMap != null && envResMap.containsKey('Body')){
                Map<String, Object> bodyResMap = (Map<String, Object>)envResMap.get('Body');
                if(bodyResMap != null && bodyResMap.containsKey('response')){
                    Map<String, Object> resResMap = (Map<String, Object>)bodyResMap.get('response');
                    if(resResMap != null &&  resResMap.containsKey('product-header')){
                        Map<String, Object> pdtHeadResMap = (Map<String, Object>)resResMap.get('product-header');
                    }
                    if(resResMap != null && resResMap.containsKey('product-data')){
                        Map<String, Object> pdtDataResMap = (Map<String, Object>)resResMap.get('product-data');
                        if(pdtDataResMap != null && pdtDataResMap.containsKey('enquiry-report')){
                            Map<String, Object> enRepResMap = (Map<String, Object>)pdtDataResMap.get('enquiry-report');
                            if(enRepResMap != null && enRepResMap.containsKey('primary-match')){
                                Map<String, Object> prMatResMap = (Map<String, Object>)enRepResMap.get('primary-match');
                                if(prMatResMap != null){
                                    Map<String, Object> buRefResMap = (Map<String, Object>)prMatResMap.get('bureau-reference');
                                    Map<String, Object> indNameResMap = (Map<String, Object>)prMatResMap.get('individual-name');
                                    Map<String, Object> genResMap = (Map<String, Object>)prMatResMap.get('gender');
                                    Map<String, Object> dobResMap = (Map<String, Object>)prMatResMap.get('date-of-birth');
                                    Map<String, Object> isDecResMap = (Map<String, Object>)prMatResMap.get('is-deceased');
                                    Map<String, Object> driLicResMap = (Map<String, Object>)prMatResMap.get('drivers-licence');
                                    if(indNameResMap != null){
                                        Map<String, Object> famNameResMap = (Map<String, Object>)indNameResMap.get('family-name');
                                        Map<String, Object> firstNameResMap = (Map<String, Object>)indNameResMap.get('first-given-name');
                                        Map<String, Object> otherNameResMap = (Map<String, Object>)indNameResMap.get('other-given-name');
                                        if(firstNameResMap != null && firstNameResMap.containsKey('NodeValue')){
                                            veda.firstGivenName = String.valueOf(firstNameResMap.get('NodeValue'));
                                        }
                                        if(indNameResMap != null && indNameResMap.containsKey('first-reported-date')){
                                            veda.individualNameFirstReportedDate = String.valueOf(indNameResMap.get('first-reported-date'));
                                        }
                                        if(famNameResMap != null && famNameResMap.containsKey('NodeValue')){
                                            veda.familyName = String.valueOf(famNameResMap.get('NodeValue'));
                                        }
                                        if(indNameResMap != null && indNameResMap.containsKey('last-reported-date')){
                                            veda.individualNameLastReportedDate = String.valueOf(indNameResMap.get('last-reported-date'));
                                        }
                                        if(otherNameResMap != null && otherNameResMap.containsKey('NodeValue')){
                                            veda.OtherGivenName.add(String.valueOf(otherNameResMap.get('NodeValue')));
                                        }
                                    }
                                    if(buRefResMap != null && buRefResMap.containsKey('NodeValue')){
                                        veda.bureauReference = String.valueOf(buRefResMap.get('NodeValue'));
                                    }
                                    if(dobResMap != null && dobResMap.containsKey('NodeValue')){
                                        veda.dateOfBirth = String.valueOf(dobResMap.get('NodeValue'));
                                    }
                                    if(dobResMap != null && dobResMap.containsKey('first-reported-date')){
                                        veda.dateOfBirthFirstReportedDate = String.valueOf(dobResMap.get('first-reported-date'));
                                    }
                                    if(dobResMap != null && dobResMap.containsKey('last-reported-date')){
                                        veda.dateOfBirthLastReportedDate = String.valueOf(dobResMap.get('last-reported-date'));
                                    }
                                    if(driLicResMap != null && driLicResMap.containsKey('first-reported-date')){
                                        veda.driversLicenceFirstReportedDate = String.valueOf(driLicResMap.get('first-reported-date'));
                                    }
                                    if(driLicResMap != null && driLicResMap.containsKey('last-reported-date')){
                                        veda.driversLicenceLastReportedDate = String.valueOf(driLicResMap.get('last-reported-date'));
                                    }
                                    if(driLicResMap != null && driLicResMap.containsKey('NodeValue')){
                                        veda.driversLicenceNumber = String.valueOf(driLicResMap.get('NodeValue'));
                                    }
                                    if(genResMap != null && genResMap.containsKey('NodeValue')){
                                        veda.gender = String.valueOf(genResMap.get('NodeValue'));
                                    }
                                    if(genResMap != null && genResMap.containsKey('code')){
                                        veda.genderCode = String.valueOf(genResMap.get('code'));
                                    }
                                    if(isDecResMap != null && isDecResMap.containsKey('NodeValue')){
                                        veda.isDeceased = String.valueOf(isDecResMap.get('NodeValue'));
                                    }
                                    if(isDecResMap != null && isDecResMap.containsKey('reported-date')){
                                        veda.isDeceasedReportedDate = String.valueOf(isDecResMap.get('reported-date'));
                                    }
                                    //veda.lodgedComplaint = dobResMap.get('NodeValue');
                                    //veda.lodgedComplaintReportedDate = dobResMap.get('NodeValue');
                                    if(prMatResMap != null && prMatResMap.containsKey('id-index')){
                                        veda.primaryMatchIdIndex = String.valueOf(prMatResMap.get('id-index'));
                                    }
                                    if(prMatResMap != null && prMatResMap.containsKey('type')){
                                        veda.primaryMatchType = String.valueOf(prMatResMap.get('type'));
                                    }
                                }
                            }
                        }
                    }
                }
                if(bodyResMap != null && bodyResMap.containsKey('Fault')){
                    Map<String, Object> faultResMap = (Map<String, Object>)envResMap.get('Fault');
                    if(faultResMap != null){
                        Map<String, Object> faultCodeMap = (Map<String, Object>)envResMap.get('faultcode');
                        Map<String, Object> faultStringMap = (Map<String, Object>)envResMap.get('faultstring');
                        Map<String, Object> faultAacMap = (Map<String, Object>)envResMap.get('faultactor');
                        Map<String, Object> faultDetailMap = (Map<String, Object>)envResMap.get('detail');
                        if(faultDetailMap != null && faultDetailMap.containsKey('policyResult')){
                            Map<String, Object> faultPolResMap = (Map<String, Object>)faultDetailMap.get('policyResult');
                            if(faultPolResMap != null && faultPolResMap.containsKey('status')){
                                vedaErrRes.detail  = String.valueOf(faultPolResMap.get('status'));
                            }
                        }
                        if(faultAacMap != null && faultAacMap.containsKey('NodeValue')){
                            vedaErrRes.faultactor  = String.valueOf(faultAacMap.get('NodeValue'));
                        }
                        if(faultCodeMap != null && faultCodeMap.containsKey('NodeValue')){
                            vedaErrRes.faultcode  = String.valueOf(faultCodeMap.get('NodeValue'));
                        }
                        if(faultStringMap != null && faultStringMap.containsKey('NodeValue')){
                            vedaErrRes.faultstring  = String.valueOf(faultStringMap.get('NodeValue'));
                        }
                        if(vedaErrRes != null){
                            veda.errors.add(vedaErrRes);
                        }
                    }
                }
            }
            System.debug('veda = '+veda);
           // System.debug('jsonString'+resMap.get('Body'));
        }
        // Mapping address of response
        if(xmlResBody.contains('addresses>') && xmlResBody.contains('</vs:addresses>') ){
            String addersses  = xmlResBody.substringBetween('<vs:addresses>','</vs:addresses>');
            List<String> addList = new List<String>();
            if(addersses != null){
                addList = addersses.split('</vs:address>');
            }
            if(addList != null && addList.size()>0){
                for(String add : addList){
                    String addWithFooter = add + '</vs:address>';
                    Dom.Document addDoc = new Dom.Document();
                    ints.VedaComprehensiveResponse.Address vedaAddRes = new ints.VedaComprehensiveResponse.Address();
                    addDoc.load(addWithFooter);
                    Map<String, Object> addDocMap= intframework.XmlToJson.parseDocumentToMap(addDoc);
                    Map<String, Object> addResMap = (Map<String, Object>)addDocMap.get('address');
                    if(addResMap != null){
                        Map<String, Object> unitNumMap = (Map<String, Object>)addResMap.get('unit-number');
                        Map<String, Object> stNumMap = (Map<String, Object>)addResMap.get('street-number');
                        Map<String, Object> stNameMap = (Map<String, Object>)addResMap.get('street-name');
                        Map<String, Object> stTypeMap = (Map<String, Object>)addResMap.get('street-type');
                        Map<String, Object> subMap = (Map<String, Object>)addResMap.get('suburb');
                        Map<String, Object> stateMap = (Map<String, Object>)addResMap.get('state');
                        Map<String, Object> postCodeMap = (Map<String, Object>)addResMap.get('postcode');
                        Map<String, Object> conCodeMap = (Map<String, Object>)addResMap.get('country-code');
                        Map<String, Object> propertyMap = (Map<String, Object>)addResMap.get('property');
                        Map<String, Object> idRefMap = (Map<String, Object>)addResMap.get('id-references');
                        if(idRefMap != null && idRefMap.containsKey('id-reference')){
                            Map<String, Object> idRefResMap = (Map<String, Object>)idRefMap.get('id-reference');
                            if(idRefResMap != null && idRefResMap.containsKey('NodeValue')){
                                vedaAddRes.idReference.add(String.valueOf(idRefResMap.get('NodeValue')));
                            }
                        }
                        if(conCodeMap != null && conCodeMap.containsKey('NodeValue')){
                            vedaAddRes.countryCode = String.valueOf(conCodeMap.get('NodeValue'));
                        }
                        if(addResMap.containsKey('first-reported-date')){
                            vedaAddRes.firstReportedDate = String.valueOf(addResMap.get('first-reported-date'));
                        }
                        if(addResMap.containsKey('last-reported-date')){
                            vedaAddRes.firstReportedDate = String.valueOf(addResMap.get('last-reported-date'));
                        }
                        if(postCodeMap != null && postCodeMap.containsKey('NodeValue')){
                            vedaAddRes.postcode = String.valueOf(postCodeMap.get('NodeValue'));
                        }
                        if(propertyMap != null && propertyMap.containsKey('NodeValue')){
                            vedaAddRes.property = String.valueOf(propertyMap.get('NodeValue'));
                        }
                        if(stateMap != null && stateMap.containsKey('NodeValue')){
                            vedaAddRes.state = String.valueOf(stateMap.get('NodeValue'));
                        }
                        if(stNameMap != null && stNameMap.containsKey('NodeValue')){
                            vedaAddRes.streetName = String.valueOf(stNameMap.get('NodeValue'));
                        }
                        if(stNumMap != null && stNumMap.containsKey('NodeValue')){
                            vedaAddRes.streetNumber = String.valueOf(stNumMap.get('NodeValue'));
                        }
                        if(stTypeMap != null && stTypeMap.containsKey('NodeValue')){
                            vedaAddRes.streetType = String.valueOf(stTypeMap.get('NodeValue'));
                        }
                        if(subMap != null && subMap.containsKey('NodeValue')){
                            vedaAddRes.suburb = String.valueOf(subMap.get('NodeValue'));
                        }
                        if(addResMap != null && addResMap.containsKey('type')){
                            vedaAddRes.type = String.valueOf(addResMap.get('type'));
                        }
                        if(unitNumMap != null && unitNumMap.containsKey('NodeValue')){
                            vedaAddRes.unitNumber = String.valueOf(unitNumMap.get('NodeValue'));
                        }
                        if(vedaAddRes != null){
                            veda.addresses.add(vedaAddRes);
                        }
                    }
                    
                }
            }
        }
    }

    /*------Skuid button action controller to initiate hardpull manually from backend------*/
    webservice static String makeCall(Id partyId){
        try{
            List<clcommon__Party__c> partyList = [SELECT id,
                                                            name,
                                                            genesis__Application__r.Id,
                                                            genesis__Application__r.Name,
                                                            genesis__Application__r.genesis__CL_Product_Name__c,
                                                            clcommon__Account__r.City__c,
                                                            clcommon__Account__r.State__c,
                                                            clcommon__Account__r.Street_Name__c,
                                                            clcommon__Account__r.Street_Number__c,
                                                            clcommon__Account__r.Street_Type__c,
                                                            clcommon__Account__r.Country__c,
                                                            clcommon__Account__r.Zip__c,
                                                            clcommon__Account__r.BillingAddress,
                                                            clcommon__Account__r.Drivers_Licence__c,
                                                            genesis__Application__r.genesis__Loan_Amount__c,
                                                            clcommon__Account__c,
                                                            clcommon__Account__r.Unit_Number__c,
                                                            clcommon__Account__r.Name,
                                                            clcommon__Account__r.Gender__c,
                                                            clcommon__Account__r.Date_of_Birth__c,
                                                            clcommon__Account__r.First_Name__c,
                                                            clcommon__Account__r.Last_Name__c,
                                                            clcommon__Account__r.Middle_Name__C,
                                                            clcommon__Account__r.BillingStreet,
                                                            clcommon__Account__r.BillingCity,
                                                            clcommon__Account__r.BillingState,
                                                            clcommon__Account__r.BillingPostalCode,
                                                            clcommon__Account__r.BillingCountry,
                                                            clcommon__Account__r.Citizenship__c
                                                        FROM clcommon__Party__c
                                                        WHERE id=:partyId];
            if(partyList.size()>0){
                //callout(partyList.get(0));
            }
            return ConstantValues.equifaxHardpullSuccess;
        }catch(CustomException e){
            if(e.getMessage().equals(ConstantValues.SERVICE_UNAVAILABLE)){
                throw new CustomException(ConstantValues.SERVICE_UNAVAILABLE);
            }else {
                ExceptionManager.manageException(e);
                return null;
            }
        }catch(Exception Ex){
            ExceptionManager.manageException(ex);
            insert ExceptionManager.getClCommonLog(ex, ResponseMessenger.genesis);
            return ConstantValues.equifaxHardpullFailurePrefix + ConstantValues.DELIMETER_WITH_SPACE + Ex.getMessage();
        }
    }


}