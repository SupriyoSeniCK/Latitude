/*********************************************************************************************************
Class            : EquifaxVedaResponseParser
Description      : Manager Class for Equifax Hardpull Integration to create veda Comprehensive response
Created Date     : 26/07/2023
Developer        : Supriyo Seni
Last Modified By : Supriyo Seni
**********************************************************************************************************/

global with sharing class EquifaxVedaResponseParser{

    public static Map<String,String> accIdMap =  new Map<String,String>();

    /**************************************************************************
     * @Description  : This method creates veda Comprehensive response from responsexmlbody which will be used for existing equifax parsing class
     * @params       : xml response body as string
     * @returnType   : ints.VedaComprehensiveResponse
    ******************************************************************************/ 	
    global static ints.VedaComprehensiveResponse createVedaResponse(String xmlResBody){
        ints.VedaComprehensiveResponse veda = new ints.VedaComprehensiveResponse();
        Dom.Document doc = new Dom.Document();
        if(xmlResBody == null || String.isBlank(xmlResBody)){
            throw new CustomException(EquifaxIntegrationConstants.RESPONSE_BODY_IS_BLANK);
        }
        // Remove space from response body if encountered in enquiry-client-reference
        xmlResBody = removeSpaceFromClientReference(xmlResBody);
        xmlResBody = checkForNewAccountId(xmlResBody);
        doc.load(xmlResBody);
		Map<String, Object> resMap = intframework.XmlToJson.parseDocumentToMap(doc);
        if(resMap != null && resMap.containsKey(EquifaxIntegrationConstants.ENVELOPE)){
            Map<String, Object> envResMap = (Map<String, Object>)resMap.get(EquifaxIntegrationConstants.ENVELOPE);
            if(envResMap != null && envResMap.containsKey(EquifaxIntegrationConstants.BODY)){
                Map<String, Object> bodyResMap = (Map<String, Object>)envResMap.get(EquifaxIntegrationConstants.BODY);
                if(bodyResMap != null && bodyResMap.containsKey(EquifaxIntegrationConstants.RESPONSE)){
                    Map<String, Object> resResMap = (Map<String, Object>)bodyResMap.get(EquifaxIntegrationConstants.RESPONSE);
                    if(resResMap != null &&  resResMap.containsKey(EquifaxIntegrationConstants.PRODUCT_HEADER)){
                        Map<String, Object> pdtHeadResMap = (Map<String, Object>)resResMap.get(EquifaxIntegrationConstants.PRODUCT_HEADER);
                        if(pdtHeadResMap != null && pdtHeadResMap.containsKey(EquifaxIntegrationConstants.ENQ_ID)){
                            Map<String, Object> enqIdMap = (Map<String, Object>)pdtHeadResMap.get(EquifaxIntegrationConstants.ENQ_ID);
                            if(enqIdMap !=  null && enqIdMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                veda.enquiryId = String.valueOf(enqIdMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            }
                        }
                    }
                    if(resResMap != null && resResMap.containsKey(EquifaxIntegrationConstants.PRODUCT_DATA)){
                        Map<String, Object> pdtDataResMap = (Map<String, Object>)resResMap.get(EquifaxIntegrationConstants.PRODUCT_DATA);
                        if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.ENQ_REPORT)){
                            // Get veda Equiry report from the Equifax Response Map
                            veda = getVedaEnquiryReport(pdtDataResMap,veda);
                        }
                        if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.SUMM_DATA)){
                            // Get summary data of the customer from the Equifax Response Map
                            List<ints.VedaComprehensiveResponse.DataBlock> vedaSummDataList = getVedaSummaryData(pdtDataResMap);
                            if(vedaSummDataList != null && vedaSummDataList.size()>0){
                                for(ints.VedaComprehensiveResponse.DataBlock vedaSummData : vedaSummDataList){
                                    veda.summaryData.add(vedaSummData);
                                }
                            }
                        }
                        if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.SCORE_DATA)){
                            // Get scorecrds of the customer from the Equifax Response Map if encountered
                            List<ints.VedaComprehensiveResponse.Score> vedaScoreList = EquifaxVedaResponseParserHelper.getVedaScoreData(pdtDataResMap);
                            if(vedaScoreList != null && vedaScoreList.size()>0){
                                for(ints.VedaComprehensiveResponse.Score vedaScore : vedaScoreList){
                                    veda.scoreData.add(vedaScore);
                                } 
                            }   
                        }
                        if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.POSSIBLE_MATCHES)){
                            // Get possible matches of the customer from the Equifax Response Map if encountered
                            List<ints.VedaComprehensiveResponse.possibleMatch> vedaPosMatList = getVedaPossibleMatches(pdtDataResMap);
                            if(vedaPosMatList != null & vedaPosMatList.size()>0){
                                for(ints.VedaComprehensiveResponse.possibleMatch vedaPosMat : vedaPosMatList){
                                    veda.possibleMatches.add(vedaPosMat);
                                } 
                            }                      
                        }if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.FILE_BAN_REPORT)){
                            // Get File Ban report from the Equifax Response Map if encountered
                            veda = getVedaFileBanReport(pdtDataResMap,veda);
                        }else{
                            veda.fileBanReport = null;
                        }
                    }
                    if(resResMap != null && resResMap.containsKey(EquifaxIntegrationConstants.ERRORS)){
                        List<ints.VedaComprehensiveResponse.Error> vedaErrList = getVedaResErrors(resResMap);
                        for(ints.VedaComprehensiveResponse.Error vedaErr : vedaErrList){
                            veda.errors.add(vedaErr);
                        }
                    }  
                }
                if(bodyResMap != null && bodyResMap.containsKey(EquifaxIntegrationConstants.FAULT)){
                    List<ints.VedaComprehensiveResponse.Error> vedaErrList = getVedaErrors(bodyResMap);
                    for(ints.VedaComprehensiveResponse.Error vedaErr : vedaErrList){
                        veda.errors.add(vedaErr);
                    }
                }    
            }
        }
        veda.xmlRequest = null;
        veda.xmlResponse = null;
        return veda;
    }
    
    /**
    * @description : This method removes space from response body if encountered in enquiry-client-reference received from Equifax Callout
    * @author Supriyo Seni | 08-24-2023 
    * @param responseBody 
    * @return String 
    **/
    public static String removeSpaceFromClientReference(String responseBody){
        String originalResBody = responseBody;
        Boolean needReplacement = false;
        Map<String,String> clientRefMap = new Map<String,String>();
        String clientRefMapValue;
        for(Integer replaceCount = 0; replaceCount < EquifaxIntegrationConstants.MAXLIMIT; replaceCount++){
            // Create an Unique Key
            String uniqueKey = EquifaxIntegrationConstants.UNIQUE_CLIENT_REFERENCE + String.valueOf(replaceCount);
            // Get the client reference
            String clientReference = responseBody.substringBetween(EquifaxIntegrationConstants.ENQUIRY_CLIENT_REFERENCE_START,EquifaxIntegrationConstants.ENQUIRY_CLIENT_REFERENCE_END);
            // If no client reference exist then break
            if(clientReference == null || String.isBlank(clientReference)){
                break;
            }
            // Format the client reference with xml tag
            String clientRefWithTag = EquifaxIntegrationConstants.ENQUIRY_CLIENT_REFERENCE_START + clientReference + EquifaxIntegrationConstants.ENQUIRY_CLIENT_REFERENCE_END;
            clientRefMapValue = clientRefWithTag;
            // Check is blank space exist or not
            if(clientReference.contains(EquifaxIntegrationConstants.BLANK_SPACE)){
                clientRefMapValue = EquifaxIntegrationConstants.ENQUIRY_CLIENT_REFERENCE_START + 
                        clientReference.remove(EquifaxIntegrationConstants.BLANK_SPACE) + EquifaxIntegrationConstants.ENQUIRY_CLIENT_REFERENCE_END;
                needReplacement = true;
            }
            // Replace the client reference with a unique key for future replacements
            responseBody = responseBody.replaceFirst(clientRefWithTag,uniqueKey);
            // Store the string after removing space in a map with specied key that we created before
            clientRefMap.put(uniqueKey,clientRefMapValue); 
        }
        // Replace the key in respone body with the respective client references after space removal
        if(needReplacement && !clientRefMap.isEmpty()){
            for(String mapKey : clientRefMap.keySet()){
                responseBody = responseBody.replace(mapKey,clientRefMap.get(mapKey));
            }
            return responseBody;
        }
        return originalResBody;
    }

    /**
    * @description : This menthod check is the response body is need to be replaced with new account-id or not which cause failure in parsing
    * @author Supriyo Seni | 08-29-2023 
    * @param responseBody 
    * @return String 
    **/
    public static String checkForNewAccountId(String responseBody){
        String originalResBody = responseBody;
        Boolean needReplacement = false;
        Map<String,String> newAccIdMap = new Map<String,String>();
        String accIdMapValue;
        for(Integer replaceCount = 0; replaceCount < EquifaxIntegrationConstants.MAXLIMIT; replaceCount++){
            // Create an Unique Key for Account Id replacement
            String uniqueKey = EquifaxIntegrationConstants.ACCOUNT_ID_UNIQUE_KEY + String.valueOf(replaceCount);
            // Get the Acount-id from response
            String accountId = responseBody.substringBetween(EquifaxIntegrationConstants.ACCOUNT_ID_START,EquifaxIntegrationConstants.ACCOUNT_ID_END);
            // If no account-id found then break
            if(accountId == null || String.isBlank(accountId)){
                break;
            }
            // Format the account-id with xml tag
            String accIdWithTag = EquifaxIntegrationConstants.ACCOUNT_ID_START + accountId + EquifaxIntegrationConstants.ACCOUNT_ID_END;
            accIdMapValue = accIdWithTag;
            // Check if the extracted account has the specific substrings or not
            if(containsMLAccountIds(accountId)){
                accIdMapValue = EquifaxIntegrationConstants.ACCOUNT_ID_START + uniqueKey + EquifaxIntegrationConstants.ACCOUNT_ID_END;
                // put the account-id in a global map to be used for veda account parsing
                accIdMap.put(uniqueKey,accountId);
                needReplacement = true;
            }
            // Replace the account-id with a unique key for future replacements
            responseBody = responseBody.replaceFirst(accIdWithTag,uniqueKey);
            // Store the new value in a map with specified key that we created before
            newAccIdMap.put(uniqueKey,accIdMapValue); 
        }
        // Replace the key in respone body with the respective account ids 
        if(needReplacement && !newAccIdMap.isEmpty()){
            for(String mapKey : newAccIdMap.keySet()){
                responseBody = responseBody.replace(mapKey,newAccIdMap.get(mapKey));
            }
            return responseBody;
        }
        return originalResBody;
    }

    /**
    * @description : it checks if the account-id contains the specific substrings present in the custom label
    * @author Supriyo Seni | 08-29-2023 
    * @param accId 
    * @return Boolean 
    **/
    public static Boolean containsMLAccountIds(String accId){
        List<String> accIdErrStrList = new List<String>();
        accIdErrStrList = System.label.EquifaxMLAccountIds.split(EquifaxIntegrationConstants.COMMA);
        for(String str : accIdErrStrList){
            if(accId.contains(str) || accId.endsWithIgnoreCase(str)){
                return true;
            }
        }
        return false;
    }

/**
* @description : It resturns the manipulated account-id map
* @author Supriyo Seni | 08-29-2023 
* @return Map<String, String> 
**/
public static Map<String,String> getAccountIdMap(){
    if(accIdMap != null && !accIdMap.isEmpty()){
        return accIdMap;
    }
    return null;
}

    /**************************************************************************
     * @Description  : This method updates veda Comprehensive response with the enquiry report details of the response
     * @params       : Map of String and Object AND veda instance
     * @returnType   : ints.VedaComprehensiveResponse
    ******************************************************************************/ 
    public static ints.VedaComprehensiveResponse getVedaEnquiryReport(Map<String,Object> pdtDataResMap,ints.VedaComprehensiveResponse veda){
        Map<String, Object> enRepResMap = (Map<String, Object>)pdtDataResMap.get(EquifaxIntegrationConstants.ENQ_REPORT);
        if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.PRIMARY_MATCH)){
            // Get primary match details of the customer from the Equifax Response Map
            veda = getPrimaryMatchDetails(enRepResMap,veda);
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.OTHER_IDEN)){
            // Get veda other identities (if any) of the customer from the Equifax Response Map
            List<ints.VedaComprehensiveResponse.OtherIdentity> vedaOthIdenList = getVedaOtherIdentities(enRepResMap);
            if(vedaOthIdenList != null && vedaOthIdenList.size()>0){
                for(ints.VedaComprehensiveResponse.OtherIdentity vedaOthIden : vedaOthIdenList){
                    veda.otherIdentities.add(vedaOthIden);
                }  
            }  
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.ADDRESSES)){
            // Get addresses of the customer from the Equifax Response Map
            List<ints.VedaComprehensiveResponse.Address> vedaAddResList = EquifaxVedaResponseParserHelper.getVedaAddresses(enRepResMap);
            if(vedaAddResList != null && vedaAddResList.size()>0){
                for(ints.VedaComprehensiveResponse.Address vedaAddRes : vedaAddResList){
                    veda.addresses.add(vedaAddRes);
                }
            }
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.EMPLOYMENT)){
            // Get employment details of the customer from the Equifax Response Map
            List<ints.VedaComprehensiveResponse.Employer> vedaEmpList = EquifaxVedaResponseParserHelper.getVedaEmployments(enRepResMap);
            if(vedaEmpList != null && vedaEmpList.size()>0){
                for(ints.VedaComprehensiveResponse.Employer vedaEmp : vedaEmpList){
                    veda.employers.add(vedaEmp);
                }
            }
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.CONSUMER_CREDIT_FILE)){
            Map<String, Object> conCreFileMap = (Map<String, Object>)enRepResMap.get(EquifaxIntegrationConstants.CONSUMER_CREDIT_FILE);
            if(conCreFileMap != null && conCreFileMap.containsKey(EquifaxIntegrationConstants.CREDIT_ENQS)){
                // Get consumer credit enquiries of the customer from the Equifax Response Map
                List<ints.VedaComprehensiveResponse.CreditEnquiry> vedaCredEnqList = EquifaxVedaResponseParserHelper.getVedaConsumerCreditEnquiries(conCreFileMap);
                if(vedaCredEnqList != null && vedaCredEnqList.size()>0){
                    for(ints.VedaComprehensiveResponse.CreditEnquiry vedaCredEnq : vedaCredEnqList){
                        veda.creditEnquiries.add(vedaCredEnq);
                    }
                }
            }if(conCreFileMap != null && conCreFileMap.containsKey(EquifaxIntegrationConstants.ACCOUNTS)){
                // Get account details of the customer from the Equifax Response Map
                List<ints.VedaComprehensiveResponse.account> vedaAccList = EquifaxVedaResponseParserHelper.getVedaAccounts(conCreFileMap);
                if(vedaAccList != null && vedaAccList.size()>0){
                    for(ints.VedaComprehensiveResponse.account vedaAcc: vedaAccList){
                        veda.accounts.add(vedaAcc);
                    }
                }
            }
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.COMMERCIAL_CREDIT_FILE)){
            Map<String, Object> comCreFileMap = (Map<String, Object>)enRepResMap.get(EquifaxIntegrationConstants.COMMERCIAL_CREDIT_FILE);
            if(comCreFileMap != null && comCreFileMap.containsKey(EquifaxIntegrationConstants.CREDIT_ENQS)){
                // Get commercial credit enquiries of the customer from the Equifax Response Map
                List<ints.VedaComprehensiveResponse.CreditEnquiry> vedaCommCredEnqList = EquifaxVedaResponseParserHelper.getVedaCommercialCreditEnquiries(enRepResMap);
                if(vedaCommCredEnqList != null & vedaCommCredEnqList.size()>0){
                    for(ints.VedaComprehensiveResponse.CreditEnquiry vedaCommCredEnq : vedaCommCredEnqList){
                        veda.commercialCreditFileCreditEnquiries.add(vedaCommCredEnq);
                    }
                }
            }if(comCreFileMap != null && comCreFileMap.containsKey(EquifaxIntegrationConstants.FILE_NOTES)){
                // Get veda file notes of the customer from the Equifax Response Map
                List<ints.VedaComprehensiveResponse.FileNote> vedaFileNoteList = EquifaxVedaResponseParserHelper.getVedaFileNotes(comCreFileMap);
                if(vedaFileNoteList != null && vedaFileNoteList.size()>0){
                    for(ints.VedaComprehensiveResponse.FileNote vedaFileNote : vedaFileNoteList){
                        veda.fileNotes.add(vedaFileNote);
                    }
                }
            }     
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.PUB_REC_OR_CONSUMER_CRED_INFO)){
            Map<String, Object> pubRecConCreMap = (Map<String, Object>)enRepResMap.get(EquifaxIntegrationConstants.PUB_REC_OR_CONSUMER_CRED_INFO);
            if(pubRecConCreMap != null && pubRecConCreMap.containsKey(EquifaxIntegrationConstants.DIRECTORSHIPS)){
                // Get directorship details of the customer from the Equifax Response Map
                List<ints.VedaComprehensiveResponse.Directorship> vedaDirectorshipList = EquifaxVedaResponseParserHelper.getVedaDirectorships(pubRecConCreMap);
                if(vedaDirectorshipList != null && vedaDirectorshipList.size()>0){
                    for(ints.VedaComprehensiveResponse.Directorship vedaDirectorship : vedaDirectorshipList){
                        veda.directorships.add(vedaDirectorship);
                    }
                }
            }
            if(pubRecConCreMap != null && pubRecConCreMap.containsKey(EquifaxIntegrationConstants.BUSS_NAMES)){
                // Get veda Business names of the customer from the Equifax Response Map
                List<ints.VedaComprehensiveResponse.businessName> vedaBusNameList = EquifaxVedaResponseParserHelper.getVedaBusinessNames(pubRecConCreMap);
                if(vedaBusNameList != null && vedaBusNameList.size()>0){
                    for(ints.VedaComprehensiveResponse.businessName vedaBusName : vedaBusNameList){
                        veda.businessNames.add(vedaBusName);
                    }
                }
            }
            if(pubRecConCreMap != null && pubRecConCreMap.containsKey(EquifaxIntegrationConstants.PERSONAL_INSOVENCIES)){
                // Get veda personal Insolvencies of the customer from the Equifax Response Map
                List<ints.VedaComprehensiveResponse.personalInsolvency> vedaPerInsList = EquifaxVedaResponseParserHelper.getVedaPerosnalInsolvencies(pubRecConCreMap);
                if(vedaPerInsList != null && vedaPerInsList.size()>0){
                    for(ints.VedaComprehensiveResponse.personalInsolvency vedaPerIns : vedaPerInsList){
                        veda.personalInsolvencies.add(vedaPerIns);
                    }
                }
            }
        }
        return veda;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda erros from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Error
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.Error> getVedaErrors(Map<String,Object> resErrorMap){
        List<ints.VedaComprehensiveResponse.Error> vedaErrorList = new List<ints.VedaComprehensiveResponse.Error>();
        Map<String, Object> faultResMap = (Map<String, Object>)resErrorMap.get(EquifaxIntegrationConstants.FAULT);
        ints.VedaComprehensiveResponse.Error vedaErrRes = new ints.VedaComprehensiveResponse.Error();
        if(faultResMap != null){
            Map<String, Object> faultCodeMap = (Map<String, Object>)faultResMap.get(EquifaxIntegrationConstants.FAULTCODE);
            Map<String, Object> faultStringMap = (Map<String, Object>)faultResMap.get(EquifaxIntegrationConstants.FAULTSTRING);
            Map<String, Object> faultAacMap = (Map<String, Object>)faultResMap.get(EquifaxIntegrationConstants.FAULTFACTOR);
            Map<String, Object> faultDetailMap = (Map<String, Object>)faultResMap.get(EquifaxIntegrationConstants.DETAIL);
            if(faultDetailMap != null && faultDetailMap.containsKey(EquifaxIntegrationConstants.POLICYRESULT)){
                Map<String, Object> faultPolResMap = (Map<String, Object>)faultDetailMap.get(EquifaxIntegrationConstants.POLICYRESULT);
                if(faultPolResMap != null && faultPolResMap.containsKey(EquifaxIntegrationConstants.STATUS)){
                    vedaErrRes.detail  = String.valueOf(faultPolResMap.get(EquifaxIntegrationConstants.STATUS));
                }
            }
            if(faultAacMap != null && faultAacMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaErrRes.faultactor  = String.valueOf(faultAacMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(faultCodeMap != null && faultCodeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaErrRes.faultcode  = String.valueOf(faultCodeMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(faultStringMap != null && faultStringMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaErrRes.faultstring  = String.valueOf(faultStringMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(vedaErrRes != null){
                vedaErrorList.add(vedaErrRes);
            }
        }
        return vedaErrorList;
    }

    /**************************************************************************
     * @Description  : This method returns the primary match details from equifax response map
     * @params       : Map of String and Object
     * @returnType   : ints.VedaComprehensiveResponse
    ******************************************************************************/ 
    public static ints.VedaComprehensiveResponse getPrimaryMatchDetails(Map<String,Object> enRepResMap,ints.VedaComprehensiveResponse vedaObj){
        Map<String, Object> prMatResMap = (Map<String, Object>)enRepResMap.get(EquifaxIntegrationConstants.PRIMARY_MATCH);
        if(prMatResMap != null){
            Map<String, Object> buRefResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.BUREAU_REFERENCE);
            Map<String, Object> indNameResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.INDIVIDUAL_NAME);
            Map<String, Object> genResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.GENDER_STR);
            Map<String, Object> dobResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.DOB);
            Map<String, Object> isDecResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.IS_DECEASED);
            Map<String, Object> driLicResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.DRIVER_LICENCE);
            Map<String, Object> lodgeResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.LODGED_COMPLAINT);
            if(indNameResMap != null){
                Map<String, Object> famNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.FAMILY_NAME);
                Map<String, Object> firstNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.FIRST_GIVEN_NAME);
                Map<String, Object> otherNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.OTHER_GIVEN_NAME);
                if(firstNameResMap != null && firstNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaObj.firstGivenName = String.valueOf(firstNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                    vedaObj.individualNameFirstReportedDate = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                }
                if(famNameResMap != null && famNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaObj.familyName = String.valueOf(famNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                    vedaObj.individualNameLastReportedDate = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                }
                if(otherNameResMap != null && otherNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaObj.OtherGivenName.add(String.valueOf(otherNameResMap.get(EquifaxIntegrationConstants.NODEVALUE)));
                }
            }
            if(buRefResMap != null && buRefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaObj.bureauReference = String.valueOf(buRefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaObj.dateOfBirth = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                vedaObj.dateOfBirthFirstReportedDate = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
            }
            if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                vedaObj.dateOfBirthLastReportedDate = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
            }
            if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                vedaObj.driversLicenceFirstReportedDate = String.valueOf(driLicResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
            }
            if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                vedaObj.driversLicenceLastReportedDate = String.valueOf(driLicResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
            }
            if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.NUMBER_STR)){
                Map<String, Object> driLicNameMap = (Map<String, Object>)driLicResMap.get(EquifaxIntegrationConstants.NUMBER_STR);
                if(driLicNameMap != null && driLicNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaObj.driversLicenceNumber = String.valueOf(driLicNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
            }
            if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaObj.gender = String.valueOf(genResMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.CODE)){
                vedaObj.genderCode = String.valueOf(genResMap.get(EquifaxIntegrationConstants.CODE));
            }
            if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaObj.isDeceased = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.REPORTED_DATE)){
                vedaObj.isDeceasedReportedDate = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
            }
            if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaObj.lodgedComplaint = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.REPORTED_DATE)){
                vedaObj.lodgedComplaintReportedDate = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
            }
            if(prMatResMap != null && prMatResMap.containsKey(EquifaxIntegrationConstants.ID_INDEX)){
                vedaObj.primaryMatchIdIndex = String.valueOf(prMatResMap.get(EquifaxIntegrationConstants.ID_INDEX));
            }
            if(prMatResMap != null && prMatResMap.containsKey(EquifaxIntegrationConstants.TYPE)){
                vedaObj.primaryMatchType = String.valueOf(prMatResMap.get(EquifaxIntegrationConstants.TYPE));
            }
        }
        return vedaObj;
    }

    /**************************************************************************
     * @Description  : This method updates the veda comprehensive response with file ban report received in Equifax response body
     * @params       : Map of String and Object and veda instance
     * @returnType   : nts.VedaComprehensiveResponse
    ******************************************************************************/ 
    public static ints.VedaComprehensiveResponse getVedaFileBanReport(Map<String,Object> pdtDataResMap,ints.VedaComprehensiveResponse vedaParam){
        Map<String,Object> fileBanRepMap = (Map<String,Object>)pdtDataResMap.get(EquifaxIntegrationConstants.FILE_BAN_REPORT);
        if(fileBanRepMap != null){
            Map<String,Object> repDateMap = (Map<String,Object>)fileBanRepMap.get(EquifaxIntegrationConstants.REPORTED_DATE);
            Map<String,Object> isExtendedMap = (Map<String,Object>)fileBanRepMap.get(EquifaxIntegrationConstants.IS_EXTENDED);
            Map<String,Object> endDateMap = (Map<String,Object>)fileBanRepMap.get(EquifaxIntegrationConstants.END_DATE);
            if(repDateMap != null && repDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaParam.fileBanReport.reportedDate = String.valueOf(repDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(isExtendedMap != null && isExtendedMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaParam.fileBanReport.isExtended = String.valueOf(isExtendedMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(endDateMap != null && endDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaParam.fileBanReport.endDate = String.valueOf(endDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
        }
        return vedaParam;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda erros from the response error map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Error
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.Error> getVedaResErrors(Map<String,Object> resErrorMap){
        List<ints.VedaComprehensiveResponse.Error> vedaErrorList = new List<ints.VedaComprehensiveResponse.Error>();
        List<Map<String, Object>> errMapList = new List<Map<String, Object>>(); 
        Map<String, Object> errMap = (Map<String, Object>)resErrorMap.get(EquifaxIntegrationConstants.ERRORS);
        if(errMap != null && errMap.containsKey(EquifaxIntegrationConstants.ERROR)){
            // Convert to List of Maps
            errMapList = EquifaxVedaResponseParserHelper.getListOfMaps(errMap,EquifaxIntegrationConstants.ERROR);
            if(errMapList != null && errMapList.size()>0){
                for(Map<String, Object> errResMap : errMapList){
                    ints.VedaComprehensiveResponse.Error vedaErr = new ints.VedaComprehensiveResponse.Error();
                    Map<String, Object> faultCodeMap = (Map<String, Object>)errResMap.get(EquifaxIntegrationConstants.FAULT_CODE);
                    Map<String, Object> faultStringMap = (Map<String, Object>)errResMap.get(EquifaxIntegrationConstants.FAULT_STRING);
                    Map<String, Object> faultAacMap = (Map<String, Object>)errResMap.get(EquifaxIntegrationConstants.FAULT_ACTOR);
                    Map<String, Object> faultDetailMap = (Map<String, Object>)errResMap.get(EquifaxIntegrationConstants.DETAIL);
                    if(faultDetailMap != null && faultDetailMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaErr.detail  = String.valueOf(faultDetailMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(faultAacMap != null && faultAacMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaErr.faultactor  = String.valueOf(faultAacMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(faultCodeMap != null && faultCodeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaErr.faultcode  = String.valueOf(faultCodeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(faultStringMap != null && faultStringMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaErr.faultstring  = String.valueOf(faultStringMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(vedaErr != null){
                        vedaErrorList.add(vedaErr);
                    }
                }
            }
        }
        return vedaErrorList;
    }
    
    /**************************************************************************
     * @Description  : This method returns the list of veda possibleMatchs from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.possibleMatch
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.possibleMatch> getVedaPossibleMatches(Map<String,Object> pdtDataResMap){
        List<ints.VedaComprehensiveResponse.possibleMatch> vedaPossMatList = new List<ints.VedaComprehensiveResponse.possibleMatch>();
        List<Map<String, Object>> possMatMapList = new List<Map<String, Object>>(); 
        Map<String, Object> possMatMap = (Map<String, Object>)pdtDataResMap.get(EquifaxIntegrationConstants.POSSIBLE_MATCHES);
        if(possMatMap != null && possMatMap.containsKey(EquifaxIntegrationConstants.POSSIBLE_MATCH)){
            // Convert to List of Maps
            possMatMapList = EquifaxVedaResponseParserHelper.getListOfMaps(possMatMap,EquifaxIntegrationConstants.POSSIBLE_MATCH);
            if(possMatMapList != null && possMatMapList.size()>0){
                for(Map<String, Object> possMat : possMatMapList){
                    ints.VedaComprehensiveResponse.possibleMatch vedaPossMat = new ints.VedaComprehensiveResponse.possibleMatch();
                    Map<String, Object> prMatResMap = (Map<String, Object>)possMat.get(EquifaxIntegrationConstants.IDENTITY);
                    if(prMatResMap != null){
                        Map<String, Object> buRefResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.BUREAU_REFERENCE);
                        Map<String, Object> indNameResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.INDIVIDUAL_NAME);
                        Map<String, Object> genResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.GENDER_STR);
                        Map<String, Object> dobResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.DOB);
                        Map<String, Object> isDecResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.IS_DECEASED);
                        Map<String, Object> driLicResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.DRIVER_LICENCE);
                        Map<String, Object> lodgeResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.LODGED_COMPLAINT);
                        if(indNameResMap != null){
                            Map<String, Object> famNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.FAMILY_NAME);
                            Map<String, Object> firstNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.FIRST_GIVEN_NAME);
                            Map<String, Object> otherNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.OTHER_GIVEN_NAME);
                            if(firstNameResMap != null && firstNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                vedaPossMat.identity.individualNameFirstGivenName = String.valueOf(firstNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            }
                            if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                                vedaPossMat.identity.individualNameFirstReportedDate = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                            }
                            if(famNameResMap != null && famNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                vedaPossMat.identity.individualNameFamilyName = String.valueOf(famNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            }
                            if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                                vedaPossMat.identity.individualNameLastReportedDate = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                            }
                            if(otherNameResMap != null && otherNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                vedaPossMat.identity.individualNameOtherGivenName.add(String.valueOf(otherNameResMap.get(EquifaxIntegrationConstants.NODEVALUE)));
                            }
                            if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.LAST_CREDIT_ENQ_DATE)){
                                vedaPossMat.identity.individualNameLastCreditEnquiryDate = String.valueOf(otherNameResMap.get(EquifaxIntegrationConstants.LAST_CREDIT_ENQ_DATE));
                            }
                        }
                        if(buRefResMap != null && buRefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPossMat.identity.bureauReference = String.valueOf(buRefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPossMat.identity.dateOfBirth = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                            vedaPossMat.identity.dateOfBirthFirstReportedDate = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                        }
                        if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                            vedaPossMat.identity.dateOfBirthLastReportedDate = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                        }
                        if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                            vedaPossMat.identity.driversLicenceFirstReportedDate = String.valueOf(driLicResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                        }
                        if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                            vedaPossMat.identity.driversLicenceLastReportedDate = String.valueOf(driLicResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                        }
                        if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.NUMBER_STR)){
                            Map<String, Object> driLicNameMap = (Map<String, Object>)driLicResMap.get(EquifaxIntegrationConstants.NUMBER_STR);
                            if(driLicNameMap != null && driLicNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                vedaPossMat.identity.driversLicenceNumber = String.valueOf(driLicNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            }
                        }
                        if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPossMat.identity.gender = String.valueOf(genResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.CODE)){
                            vedaPossMat.identity.genderCode = String.valueOf(genResMap.get(EquifaxIntegrationConstants.CODE));
                        }
                        if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPossMat.identity.isDeceased = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.REPORTED_DATE)){
                            vedaPossMat.identity.isDeceasedReportedDate = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
                        }
                        if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPossMat.identity.lodgedComplaint = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.REPORTED_DATE)){
                            vedaPossMat.identity.lodgedComplaintReportedDate = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
                        }
                        if(prMatResMap != null && prMatResMap.containsKey(EquifaxIntegrationConstants.ID_INDEX)){
                            vedaPossMat.identity.idIndex = String.valueOf(prMatResMap.get(EquifaxIntegrationConstants.ID_INDEX));
                        }    
                    }
                    if(possMat != null && possMat.containsKey(EquifaxIntegrationConstants.ADDRESSES)){
                        // Get possible match address details of the customer from the Equifax Response Map
                        vedaPossMat.addresses = EquifaxVedaResponseParserHelper.getVedaAddresses(possMat);
                    }
                    if(possMat != null && possMat.containsKey(EquifaxIntegrationConstants.EMPLOYMENT)){
                        // Get possible match employment details of the customer from the Equifax Response Map
                        vedaPossMat.employment = EquifaxVedaResponseParserHelper.getVedaEmployments(possMat);
                    }
                    if(vedaPossMat != null){
                        vedaPossMatList.add(vedaPossMat);
                    }
                }
            }
        }
        return vedaPossMatList;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda datablocks from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.DataBlock
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.DataBlock> getVedaSummaryData(Map<String,Object> resSummDataMap){
        List<ints.VedaComprehensiveResponse.DataBlock> vedaDataBlockList = new List<ints.VedaComprehensiveResponse.DataBlock>(); 
        List<Map<String, Object>> dataBlockMapList = new List<Map<String, Object>>(); 
        Map<String, Object> dataBlockMap = (Map<String, Object>)resSummDataMap.get(EquifaxIntegrationConstants.SUMM_DATA);
        if(dataBlockMap != null && dataBlockMap.containsKey(EquifaxIntegrationConstants.DATA_BLOCK)){
            // Convert to List of Maps
            dataBlockMapList = EquifaxVedaResponseParserHelper.getListOfMaps(dataBlockMap,EquifaxIntegrationConstants.DATA_BLOCK);
            if(dataBlockMapList != null && dataBlockMapList.size()>0){
                for(Map<String, Object> dBMap : dataBlockMapList){
                    ints.VedaComprehensiveResponse.DataBlock vedaDataBlock = new ints.VedaComprehensiveResponse.DataBlock();
                    if(dBMap != null && dBMap.containsKey(EquifaxIntegrationConstants.NAME)){
                        vedaDataBlock.name = String.valueOf(dBMap.get(EquifaxIntegrationConstants.NAME));
                    }
                    if(dBMap != null && dBMap.containsKey(EquifaxIntegrationConstants.TYPE)){
                        vedaDataBlock.type = String.valueOf(dBMap.get(EquifaxIntegrationConstants.TYPE));
                    }
                    if(dBMap != null && dBMap.containsKey(EquifaxIntegrationConstants.CHARACTERISTIC)){
                        // Get veda data block characteristices of the customer from the Equifax Response Map
                        vedaDataBlock.characteristic  = getDataBlockCharacteristics(dBMap);
                    }
                    if(vedaDataBlock != null){
                        vedaDataBlockList.add(vedaDataBlock);
                    }
                }
            }
        }
        return vedaDataBlockList;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda datablock characteristics from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Characteristic
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.Characteristic> getDataBlockCharacteristics(Map<String,Object> dBMap){
        List<ints.VedaComprehensiveResponse.Characteristic> vedaDbCharList = new  List<ints.VedaComprehensiveResponse.Characteristic> ();
        List<Map<String, Object>> dBcharMapList = new List<Map<String, Object>>(); 
        // Convert to List of Maps
        dBcharMapList = EquifaxVedaResponseParserHelper.getListOfMaps(dBMap,EquifaxIntegrationConstants.CHARACTERISTIC);
        if(dBcharMapList != null && dBcharMapList.size()>0){
            for(Map<String, Object> dBCharMap : dBcharMapList){
                ints.VedaComprehensiveResponse.Characteristic vedaDbChar = new ints.VedaComprehensiveResponse.Characteristic();
                Map<String, Object> charVarNameMap = (Map<String, Object>)dBCharMap.get(EquifaxIntegrationConstants.VARIABLE_NAME);
                Map<String, Object> charDescMap = (Map<String, Object>)dBCharMap.get(EquifaxIntegrationConstants.DESCRIPTION);
                Map<String, Object> charValueMap = (Map<String, Object>)dBCharMap.get(EquifaxIntegrationConstants.VALUE);
                Map<String, Object> charDataLevelMap = (Map<String, Object>)dBCharMap.get(EquifaxIntegrationConstants.DATA_LEVEL);
                if(charDataLevelMap != null && charDataLevelMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaDbChar.dataLevel = String.valueOf(charDataLevelMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(charDataLevelMap != null && charDataLevelMap.containsKey(EquifaxIntegrationConstants.CODE)){
                    vedaDbChar.dataLevelCode = String.valueOf(charDataLevelMap.get(EquifaxIntegrationConstants.CODE));
                }
                if(charDescMap != null && charDescMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaDbChar.description = String.valueOf(charDescMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(dBCharMap != null && dBCharMap.containsKey(EquifaxIntegrationConstants.ID)){
                    vedaDbChar.characteristicId = String.valueOf(dBCharMap.get(EquifaxIntegrationConstants.ID));
                }
                if(dBCharMap != null && dBCharMap.containsKey(EquifaxIntegrationConstants.KEY_CHARACTERISTIC)){
                    vedaDbChar.keyCharacteristic = String.valueOf(dBCharMap.get(EquifaxIntegrationConstants.KEY_CHARACTERISTIC));
                }
                if(charValueMap != null && charValueMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaDbChar.value = String.valueOf(charValueMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(charValueMap != null && charValueMap.containsKey(EquifaxIntegrationConstants.UNIT)){
                    vedaDbChar.unit = String.valueOf(charValueMap.get(EquifaxIntegrationConstants.UNIT));
                }
                if(charVarNameMap != null && charVarNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaDbChar.variableName = String.valueOf(charVarNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(vedaDbChar != null){
                    vedaDbCharList.add(vedaDBChar);
                }
            }
        }
        return vedaDbCharList;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda OtherIdentities from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.OtherIdentity
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.OtherIdentity> getVedaOtherIdentities(Map<String,Object> vedaOtherIdenMap){
        List<ints.VedaComprehensiveResponse.OtherIdentity> vedaOthIdenList = new List<ints.VedaComprehensiveResponse.OtherIdentity>(); 
        Map<String, Object> othIdenMap = (Map<String, Object>)vedaOtherIdenMap.get(EquifaxIntegrationConstants.OTHER_IDEN);
        if(othIdenMap != null && othIdenMap.containsKey(EquifaxIntegrationConstants.OTHER_IDENTITY)){
            // Convert to List of Maps
            List<Map<String, Object>> vedaMapList = EquifaxVedaResponseParserHelper.getListOfMaps(othIdenMap,EquifaxIntegrationConstants.OTHER_IDENTITY);
            for(Map<String, Object> otherIdenMap : vedaMapList){
                ints.VedaComprehensiveResponse.OtherIdentity vedaResOtherIden = new ints.VedaComprehensiveResponse.OtherIdentity();
                Map<String, Object> buRefResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.BUREAU_REFERENCE);
                Map<String, Object> indNameResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.INDIVIDUAL_NAME);
                Map<String, Object> genResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.GENDER_STR);
                Map<String, Object> dobResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.DOB);
                Map<String, Object> isDecResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.IS_DECEASED);
                Map<String, Object> driLicResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.DRIVER_LICENCE);
                Map<String, Object> lodgeResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.LODGED_COMPLAINT);
                if(indNameResMap != null){
                    Map<String, Object> famNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.FAMILY_NAME);
                    Map<String, Object> firstNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.FIRST_GIVEN_NAME);
                    Map<String, Object> otherNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.OTHER_GIVEN_NAME);
                    if(firstNameResMap != null && firstNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaResOtherIden.individualNameFirstGivenName = String.valueOf(firstNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                        vedaResOtherIden.individualNameFirstReportedDate = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                    }
                    if(famNameResMap != null && famNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaResOtherIden.individualNameFamilyName = String.valueOf(famNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                        vedaResOtherIden.individualNameLastReportedDate = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                    }
                    if(otherNameResMap != null && otherNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaResOtherIden.individualNameOtherGivenName.add(String.valueOf(otherNameResMap.get(EquifaxIntegrationConstants.NODEVALUE)));
                    }
                    if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.LAST_CREDIT_ENQ_DATE)){
                        vedaResOtherIden.individualNameLastCreditEnquiryDate = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.LAST_CREDIT_ENQ_DATE));
                    }
                }
                if(buRefResMap != null && buRefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaResOtherIden.bureauReference = String.valueOf(buRefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaResOtherIden.dateOfBirth = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                    vedaResOtherIden.dateOfBirthFirstReportedDate = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                }
                if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                    vedaResOtherIden.dateOfBirthLastReportedDate = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                }
                if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                    vedaResOtherIden.driversLicenceFirstReportedDate = String.valueOf(driLicResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                }
                if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                    vedaResOtherIden.driversLicenceLastReportedDate = String.valueOf(driLicResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                }
                if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.NUMBER_STR)){
                    Map<String, Object> driLicNameMap = (Map<String, Object>)driLicResMap.get(EquifaxIntegrationConstants.NUMBER_STR);
                    if(driLicNameMap != null && driLicNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaResOtherIden.driversLicenceNumber = String.valueOf(driLicNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                }
                if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaResOtherIden.gender = String.valueOf(genResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.CODE)){
                    vedaResOtherIden.genderCode = String.valueOf(genResMap.get(EquifaxIntegrationConstants.CODE));
                }
                if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaResOtherIden.isDeceased = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.REPORTED_DATE)){
                    vedaResOtherIden.isDeceasedReportedDate = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
                }
                if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaResOtherIden.lodgedComplaint = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.REPORTED_DATE)){
                    vedaResOtherIden.lodgedComplaintReportedDate = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
                }
                if(vedaResOtherIden != null){
                    vedaOthIdenList.add(vedaResOtherIden);
                }
            }    
        }
        return vedaOthIdenList;
    }
}