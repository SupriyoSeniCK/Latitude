/*********************************************************************************************************
Class            : DataParsingManager
Description      : Handler Class for Equifax Hardpull Integration to create veda  Comprehensive response
Created Date     : 26/07/2023
Developer        : Supriyo Seni
Last Modified By : Supriyo Seni
**********************************************************************************************************/

global class EquifaxHardPullManager{

    /**************************************************************************
     * @Description  : This method creates veda Comprehensive response from requestxmlbody
     * @params       : xml response body as string
     * @returnType   : ints.VedaComprehensiveResponse
    ******************************************************************************/ 	
    global static ints.VedaComprehensiveResponse createVedaResponse(String xmlResBody){
        ints.VedaComprehensiveResponse veda = new ints.VedaComprehensiveResponse();
        Dom.Document doc = new Dom.Document();
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
                    }
                    if(resResMap != null && resResMap.containsKey(EquifaxIntegrationConstants.PRODUCT_DATA)){
                        Map<String, Object> pdtDataResMap = (Map<String, Object>)resResMap.get(EquifaxIntegrationConstants.PRODUCT_DATA);
                        if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.ENQ_REPORT)){
                            veda = getVedaEnquiryReport(pdtDataResMap,veda);
                        }
                        if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.SUMM_DATA)){
                            List<ints.VedaComprehensiveResponse.DataBlock> vedaSummDataList = getVedaSummaryData(pdtDataResMap);
                            if(vedaSummDataList != null && vedaSummDataList.size()>0){
                                for(ints.VedaComprehensiveResponse.DataBlock vedaSummData : vedaSummDataList){
                                    veda.summaryData.add(vedaSummData);
                                }
                            }
                        }
                        if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.SCORE_DATA)){
                            List<ints.VedaComprehensiveResponse.Score> vedaScoreList = getVedaScoreData(pdtDataResMap);
                            if(vedaScoreList != null && vedaScoreList.size()>0){
                                for(ints.VedaComprehensiveResponse.Score vedaScore : vedaScoreList){
                                    veda.scoreData.add(vedaScore);
                                } 
                            }   
                        }
                        if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.POSSIBLE_MATCHES)){
                            List<ints.VedaComprehensiveResponse.possibleMatch> vedaPosMatList = getVedaPossibleMatches(pdtDataResMap);
                            if(vedaPosMatList != null & vedaPosMatList.size()>0){
                                for(ints.VedaComprehensiveResponse.possibleMatch vedaPosMat : vedaPosMatList){
                                    veda.possibleMatches.add(vedaPosMat);
                                } 
                            }                      
                        }if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.FILE_BAN_REPORT)){
                            veda = getVedaFileBanReport(pdtDataResMap,veda);
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
        veda.xmlResponse = xmlResBody;
        return veda;
    }
    
    /**************************************************************************
     * @Description  : This method updates veda Comprehensive response with the enquiry report details of the response
     * @params       : Map of string and object AND veda instance
     * @returnType   : ints.VedaComprehensiveResponse
    ******************************************************************************/ 
    public static ints.VedaComprehensiveResponse getVedaEnquiryReport(Map<String,Object> pdtDataResMap,ints.VedaComprehensiveResponse veda){
        Map<String, Object> enRepResMap = (Map<String, Object>)pdtDataResMap.get(EquifaxIntegrationConstants.ENQ_REPORT);
        if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.PRIMARY_MATCH)){
            ints.VedaComprehensiveResponse vedaRes = getPrimaryMatchDetails(enRepResMap);
            if(vedaRes != null){
                veda = vedaRes;
            }
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.OTHER_IDEN)){
            List<ints.VedaComprehensiveResponse.OtherIdentity> vedaOthIdenList = getVedaOtherIdentities(enRepResMap);
            if(vedaOthIdenList != null && vedaOthIdenList.size()>0){
                for(ints.VedaComprehensiveResponse.OtherIdentity vedaOthIden : vedaOthIdenList){
                    veda.otherIdentities.add(vedaOthIden);
                }  
            }  
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.ADDRESSES)){
            List<ints.VedaComprehensiveResponse.Address> vedaAddResList = getVedaAddresses(enRepResMap);
            if(vedaAddResList != null && vedaAddResList.size()>0){
                for(ints.VedaComprehensiveResponse.Address vedaAddRes : vedaAddResList){
                    veda.addresses.add(vedaAddRes);
                }
            }
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.EMPLOYMENT)){
            List<ints.VedaComprehensiveResponse.Employer> vedaEmpList = getVedaEmployments(enRepResMap);
            if(vedaEmpList != null && vedaEmpList.size()>0){
                for(ints.VedaComprehensiveResponse.Employer vedaEmp : vedaEmpList){
                    veda.employers.add(vedaEmp);
                }
            }
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.CONSUMER_CREDIT_FILE)){
            Map<String, Object> conCreFileMap = (Map<String, Object>)enRepResMap.get(EquifaxIntegrationConstants.CONSUMER_CREDIT_FILE);
            if(conCreFileMap != null && conCreFileMap.containsKey(EquifaxIntegrationConstants.CREDIT_ENQS)){
                List<ints.VedaComprehensiveResponse.CreditEnquiry> vedaCredEnqList = getVedaConsumerCreditEnquiries(conCreFileMap);
                if(vedaCredEnqList != null && vedaCredEnqList.size()>0){
                    for(ints.VedaComprehensiveResponse.CreditEnquiry vedaCredEnq : vedaCredEnqList){
                        veda.creditEnquiries.add(vedaCredEnq);
                    }
                }
            }if(conCreFileMap != null && conCreFileMap.containsKey(EquifaxIntegrationConstants.ACCOUNTS)){
                List<ints.VedaComprehensiveResponse.account> vedaAccList = getVedaAccounts(conCreFileMap);
                if(vedaAccList != null && vedaAccList.size()>0){
                    for(ints.VedaComprehensiveResponse.account vedaAcc: vedaAccList){
                        veda.accounts.add(vedaAcc);
                    }
                }
            }
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.COMMERCIAL_CREDIT_FILE)){
            Map<String, Object> comCreFileMap = (Map<String, Object>)enRepResMap.get(EquifaxIntegrationConstants.COMMERCIAL_CREDIT_FILE);
            if(comCreFileMap != null && comCreFileMap.containsKey(EquifaxIntegrationConstants.CREDIT_ENQS)){
                List<ints.VedaComprehensiveResponse.CreditEnquiry> vedaCommCredEnqList = getVedaCommercialCreditEnquiries(enRepResMap);
                if(vedaCommCredEnqList != null & vedaCommCredEnqList.size()>0){
                    for(ints.VedaComprehensiveResponse.CreditEnquiry vedaCommCredEnq : vedaCommCredEnqList){
                        veda.commercialCreditFileCreditEnquiries.add(vedaCommCredEnq);
                    }
                }
            }if(comCreFileMap != null && comCreFileMap.containsKey(EquifaxIntegrationConstants.FILE_NOTES)){
                List<ints.VedaComprehensiveResponse.FileNote> vedaFileNoteList = getVedaFileNotes(comCreFileMap);
                if(vedaFileNoteList != null && vedaFileNoteList.size()>0){
                    for(ints.VedaComprehensiveResponse.FileNote vedaFileNote : vedaFileNoteList){
                        veda.fileNotes.add(vedaFileNote);
                    }
                }
            }     
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.PUB_REC_OR_CONSUMER_CRED_INFO)){
            Map<String, Object> pubRecConCreMap = (Map<String, Object>)enRepResMap.get(EquifaxIntegrationConstants.PUB_REC_OR_CONSUMER_CRED_INFO);
            if(pubRecConCreMap != null && pubRecConCreMap.containsKey(EquifaxIntegrationConstants.DIRECTORSHIPS)){
                List<ints.VedaComprehensiveResponse.Directorship> vedaDirectorshipList = getVedaDirectorships(pubRecConCreMap);
                if(vedaDirectorshipList != null && vedaDirectorshipList.size()>0){
                    for(ints.VedaComprehensiveResponse.Directorship vedaDirectorship : vedaDirectorshipList){
                        veda.directorships.add(vedaDirectorship);
                    }
                }
            }
            if(pubRecConCreMap != null && pubRecConCreMap.containsKey(EquifaxIntegrationConstants.BUSS_NAMES)){
                List<ints.VedaComprehensiveResponse.businessName> vedaBusNameList = getVedaBusinessNames(pubRecConCreMap);
                if(vedaBusNameList != null && vedaBusNameList.size()>0){
                    for(ints.VedaComprehensiveResponse.businessName vedaBusName : vedaBusNameList){
                        veda.businessNames.add(vedaBusName);
                    }
                }
            }
            if(pubRecConCreMap != null && pubRecConCreMap.containsKey(EquifaxIntegrationConstants.PERSONAL_INSOVENCIES)){
                List<ints.VedaComprehensiveResponse.personalInsolvency> vedaPerInsList = getVedaPerosnalInsolvencies(pubRecConCreMap);
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
     * @Description  : This method returns the list of veda erros from the response error mapS
     * @params       : Map of string and object
     * @returnType   : List of ints.VedaComprehensiveResponse.Error
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.Error> getVedaResErrors(Map<String,Object> resErrorMap){
        List<ints.VedaComprehensiveResponse.Error> vedaErrorList = new List<ints.VedaComprehensiveResponse.Error>();
        List<Map<String, Object>> errMapList = new List<Map<String, Object>>(); 
        Map<String, Object> errMap = (Map<String, Object>)resErrorMap.get(EquifaxIntegrationConstants.ERRORS);
        if(errMap != null && errMap.containsKey(EquifaxIntegrationConstants.ERROR)){
            errMapList = getListOfMaps(errMap,EquifaxIntegrationConstants.ERROR);
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

    public static List<ints.VedaComprehensiveResponse.personalInsolvency> getVedaPerosnalInsolvencies(Map<String,Object> pubRecConCreMap){
        List<ints.VedaComprehensiveResponse.personalInsolvency> vedaPerInsList = new List<ints.VedaComprehensiveResponse.personalInsolvency>();
        List<Map<String, Object>> perInsMapList = new List<Map<String, Object>>(); 
        Map<String, Object> insolMap = (Map<String, Object>)pubRecConCreMap.get(EquifaxIntegrationConstants.PERSONAL_INSOVENCIES);
        if(insolMap != null && insolMap.containsKey('personal-insolvency')){
            perInsMapList = getListOfMaps(insolMap,'personal-insolvency');
            if(perInsMapList != null && perInsMapList.size()>0){
                for(Map<String, Object> perInsMap : perInsMapList){
                    ints.VedaComprehensiveResponse.personalInsolvency vedaPerIns = new ints.VedaComprehensiveResponse.personalInsolvency();
                    Map<String, Object> typeMap = (Map<String, Object>)perInsMap.get('type');
                    Map<String, Object> dateDecMap = (Map<String, Object>)perInsMap.get('date-declared');
                    Map<String, Object> textMap = (Map<String, Object>)perInsMap.get('text');
                    Map<String, Object> relationshipMap = (Map<String, Object>)perInsMap.get('relationship');
                    Map<String, Object> coBorrowerMap = (Map<String, Object>)perInsMap.get('co-borrower');
                    Map<String, Object> admIdMap = (Map<String, Object>)perInsMap.get('administration-id');
                    Map<String, Object> idRefMap = (Map<String, Object>)perInsMap.get('id-references');
                    if(idRefMap != null && idRefMap.containsKey('id-reference')){
                        vedaPerIns.idReferences = getIdReferences(idRefMap);
                    }
                    if(typeMap != null && typeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaPerIns.type = String.valueOf(typeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(typeMap != null && typeMap.containsKey('code')){
                        vedaPerIns.typeCode = String.valueOf(typeMap.get('code'));
                    }
                    if(dateDecMap != null && dateDecMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaPerIns.dateDeclared = String.valueOf(dateDecMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(textMap != null && textMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaPerIns.text = String.valueOf(textMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(relationshipMap != null && relationshipMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaPerIns.relationship = String.valueOf(relationshipMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(relationshipMap != null && relationshipMap.containsKey('code')){
                        vedaPerIns.relationshipCode = String.valueOf(relationshipMap.get('code'));
                    }
                    if(coBorrowerMap != null && coBorrowerMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaPerIns.coBorrower = String.valueOf(coBorrowerMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(admIdMap != null){
                        Map<String, Object> distMap = (Map<String, Object>)admIdMap.get('district');
                        Map<String, Object> yearMap = (Map<String, Object>)admIdMap.get('year');
                        Map<String, Object> numberMap = (Map<String, Object>)admIdMap.get('number');
                        Map<String, Object> proceStatusMap = (Map<String, Object>)admIdMap.get('proceedings-status');
                        if(distMap != null && distMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPerIns.administrationIdDistrict = String.valueOf(distMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(numberMap != null && numberMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPerIns.administrationIdNumber = String.valueOf(numberMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        } 
                        if(proceStatusMap != null && proceStatusMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPerIns.administrationIdProceedingsStatus = String.valueOf(proceStatusMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        } 
                        if(yearMap != null && yearMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPerIns.administrationIdYear = String.valueOf(yearMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                    }
                    if(vedaPerIns != null){
                        vedaPerInsList.add(vedaPerIns);
                    }
                }
            }
        }
        return vedaPerInsList;
    }
    public static List<ints.VedaComprehensiveResponse.businessName> getVedaBusinessNames(Map<String,Object> pubRecConCreMap){
        List<ints.VedaComprehensiveResponse.businessName> vedaBusNameList = new List<ints.VedaComprehensiveResponse.businessName>();
        List<Map<String, Object>> busNamesList = new List<Map<String, Object>>(); 
        Map<String, Object> busNamesMap = (Map<String, Object>)pubRecConCreMap.get(EquifaxIntegrationConstants.BUSS_NAMES);
        if(busNamesMap != null && busNamesMap.containsKey('business-name')){
            busNamesList = getListOfMaps(busNamesMap,'business-name');
            if(busNamesList != null && busNamesList.size()>0){
                for(Map<String, Object> busNameMap : busNamesList){
                    ints.VedaComprehensiveResponse.businessName vedaBusName = new ints.VedaComprehensiveResponse.businessName();
                    Map<String, Object> idRefMap = (Map<String, Object>)busNameMap.get('id-references');
                    if(idRefMap != null && idRefMap.containsKey('id-reference')){
                        vedaBusName.idReferences = getIdReferences(idRefMap);
                    }
                    Map<String, Object> busStartDateMap = (Map<String, Object>)busNameMap.get('start-date');
                    if(busStartDateMap != null && busStartDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaBusName.startDate = String.valueOf(busStartDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(busNameMap != null && busNameMap.containsKey('last-extract-date')){
                        vedaBusName.lastExtractDate = String.valueOf(busNameMap.get('last-extract-date'));
                    }
                    if(busNameMap != null && busNameMap.containsKey('last-extract-time')){
                        vedaBusName.lastExtractTime = String.valueOf(busNameMap.get('last-extract-time'));
                    }
                    if(busNameMap != null && busNameMap.containsKey('last-update-date')){
                        vedaBusName.lastUpdateDate = String.valueOf(busNameMap.get('last-update-date'));
                    }
                    if(busNameMap != null && busNameMap.containsKey('last-update-time')){
                        vedaBusName.lastUpdateTime = String.valueOf(busNameMap.get('last-update-time'));
                    }
                    Map<String, Object> bussMap = (Map<String, Object>)busNameMap.get('business');
                    if(bussMap != null){
                        Map<String, Object> bussBrMap = (Map<String, Object>)bussMap.get('bureau-reference');
                        Map<String, Object> bussNameMap = (Map<String, Object>)bussMap.get('name');
                        Map<String, Object> bussAbnMap = (Map<String, Object>)bussMap.get('ABN');
                        Map<String, Object> bussPredTerMap = (Map<String, Object>)bussMap.get('previous-state-or-territory-registration');
                        if(bussBrMap != null && bussBrMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaBusName.businessBureauReference = String.valueOf(bussBrMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(bussNameMap != null && bussNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaBusName.businessName = String.valueOf(bussNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        } 
                        if(bussAbnMap != null && bussAbnMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaBusName.businessABN = String.valueOf(bussAbnMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(bussPredTerMap != null){
                            Map<String, Object> bussStateMap = (Map<String, Object>)bussPredTerMap.get('state');
                            Map<String, Object> bussNumberMap = (Map<String, Object>)bussPredTerMap.get('number');
                            if(bussStateMap != null && bussStateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                vedaBusName.businessPreviousStateOrTerritoryRegistrationState = String.valueOf(bussStateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            } 
                            if(bussNumberMap != null && bussNumberMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                vedaBusName.businessNumber = String.valueOf(bussNumberMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            }
                        }
                    }
                    if(vedaBusName != null){
                        vedaBusNameList.add(vedaBusName);
                    }
                }
            }
        }
        return vedaBusNameList;
    }
    public static List<ints.VedaComprehensiveResponse.Directorship> getVedaDirectorships(Map<String,Object> pubRecConCreMap){
        List<ints.VedaComprehensiveResponse.Directorship> vedaDirectorshipList = new List<ints.VedaComprehensiveResponse.Directorship>();
        List<Map<String, Object>> DirecList = new List<Map<String, Object>>(); 
        Map<String, Object> directMap = (Map<String, Object>)pubRecConCreMap.get(EquifaxIntegrationConstants.DIRECTORSHIPS);
        if(directMap != null && directMap.containsKey('directorship')){
            DirecList = getListOfMaps(directMap,'directorship');
            if(DirecList != null && DirecList.size()>0){
                for(Map<String, Object> direct : DirecList){
                    ints.VedaComprehensiveResponse.Directorship vedaDirectorship= new ints.VedaComprehensiveResponse.Directorship();
                    Map<String, Object> idRefMap = (Map<String, Object>)direct.get('id-references');
                    if(idRefMap != null && idRefMap.containsKey('id-reference')){
                        vedaDirectorship.idReferences = getIdReferences(idRefMap);
                    }
                    Map<String, Object> dirDateAppMap = (Map<String, Object>)direct.get('date-appointed');
                    if(dirDateAppMap != null && dirDateAppMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaDirectorship.dateAppointed = String.valueOf(dirDateAppMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> dirDateCeaMap = (Map<String, Object>)direct.get('date-ceased');
                    if(dirDateCeaMap != null && dirDateCeaMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaDirectorship.dateCeased = String.valueOf(dirDateCeaMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> dirDatelasDMap = (Map<String, Object>)direct.get('date-last-known-as-director');
                    if(dirDatelasDMap != null && dirDatelasDMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaDirectorship.dateLastKnownAsDirector = String.valueOf(dirDatelasDMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(direct != null && direct.containsKey('last-extract-date')){
                        vedaDirectorship.lastExtractDate = String.valueOf(direct.get('last-extract-date'));
                    }
                    if(direct != null && direct.containsKey('last-extract-time')){
                        vedaDirectorship.lastExtractTime = String.valueOf(direct.get('last-extract-time'));
                    }
                    if(direct != null && direct.containsKey('last-update-date')){
                        vedaDirectorship.lastUpdateDate = String.valueOf(direct.get('last-update-date'));
                    }
                    if(direct != null && direct.containsKey('last-update-time')){
                        vedaDirectorship.lastUpdateTime = String.valueOf(direct.get('last-update-time'));
                    }
                    if(direct != null && direct.containsKey('type')){
                        vedaDirectorship.type = String.valueOf(direct.get('type'));
                    }

                    Map<String, Object> dirOrgMap = (Map<String, Object>)direct.get('organisation');
                    if(dirOrgMap != null){
                        Map<String, Object> dirOrgBrMap = (Map<String, Object>)dirOrgMap.get('bureau-reference');
                        Map<String, Object> dirOrgNameMap = (Map<String, Object>)dirOrgMap.get('name');
                        Map<String, Object> orgStartDateMap = (Map<String, Object>)dirOrgMap.get('name-start-date');
                        Map<String, Object> dirOrgTypeMap = (Map<String, Object>)dirOrgMap.get('type');
                        Map<String, Object> dirOrgStatusMap = (Map<String, Object>)dirOrgMap.get('status');
                        Map<String, Object> dirOrgNumberMap = (Map<String, Object>)dirOrgMap.get('organisation-number');
                        Map<String, Object> dirOrgAbnMap = (Map<String, Object>)dirOrgMap.get('ABN');
                        if(dirOrgBrMap != null && dirOrgBrMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDirectorship.organisationBureauReference = String.valueOf(dirOrgBrMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dirOrgAbnMap != null && dirOrgAbnMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDirectorship.organisationABN = String.valueOf(dirOrgAbnMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dirOrgNameMap != null && dirOrgNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDirectorship.organisationName = String.valueOf(dirOrgNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(orgStartDateMap != null && orgStartDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDirectorship.organisationNameStartDate = String.valueOf(orgStartDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dirOrgNumberMap != null && dirOrgNumberMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDirectorship.organisationOrganisationNumber = String.valueOf(dirOrgNumberMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dirOrgStatusMap != null && dirOrgStatusMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDirectorship.organisationStatus = String.valueOf(dirOrgStatusMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dirOrgStatusMap != null && dirOrgStatusMap.containsKey('code')){
                            vedaDirectorship.organisationStatusCode = String.valueOf(dirOrgStatusMap.get('code'));
                        }
                        if(dirOrgTypeMap != null && dirOrgTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDirectorship.organisationType = String.valueOf(dirOrgTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dirOrgTypeMap != null && dirOrgTypeMap.containsKey('code')){
                            vedaDirectorship.organisationTypeCode = String.valueOf(dirOrgTypeMap.get('code'));
                        }
                    }
                    if(vedaDirectorship != null){
                        vedaDirectorshipList.add(vedaDirectorship);
                    }
                }
            }
        }
        return vedaDirectorshipList;
    }

    public static List<ints.VedaComprehensiveResponse.FileNote> getVedaFileNotes(Map<String,Object> comCreFileMap){
        List<ints.VedaComprehensiveResponse.FileNote> vedaFileNoteList = new List<ints.VedaComprehensiveResponse.FileNote>();
        List<Map<String, Object>> fileNoteMapList = new List<Map<String, Object>>(); 
        Map<String, Object> fileNoteMap = (Map<String, Object>)comCreFileMap.get(EquifaxIntegrationConstants.FILE_NOTES);
        if(fileNoteMap != null && fileNoteMap.containsKey('file-note')){
            fileNoteMapList = getListOfMaps(fileNoteMap,'file-note');
            if(fileNoteMapList != null && fileNoteMapList.size()>0){
                for(Map<String, Object> fnMap : fileNoteMapList){
                    ints.VedaComprehensiveResponse.FileNote vedaFileNote= new ints.VedaComprehensiveResponse.FileNote();
                    Map<String, Object> idRefMap = (Map<String, Object>)fnMap.get('id-references');
                    if(idRefMap != null && idRefMap.containsKey('id-reference')){
                        vedaFileNote.idReferences = getIdReferences(idRefMap);
                    }
                    if(fnMap != null && fnMap.containsKey('date-recorded')){
                        vedaFileNote.dateRecorded = String.valueOf(fnMap.get('date-recorded'));
                    }
                    Map<String, Object> fnNoteMap = (Map<String, Object>)fnMap.get('note');
                    if(fnNoteMap != null && fnNoteMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaFileNote.note = String.valueOf(fnNoteMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(vedaFileNote != null){
                        vedaFileNoteList.add(vedaFileNote);
                    }
                }
            }
        }
        return vedaFileNoteList;
    }
    public static ints.VedaComprehensiveResponse getVedaFileBanReport(Map<String,Object> pdtDataResMap,ints.VedaComprehensiveResponse vedaParam){
        Map<String,Object> repDateMap = (Map<String,Object>)pdtDataResMap.get('reported-date');
        Map<String,Object> isExtendedMap = (Map<String,Object>)pdtDataResMap.get('is-extended');
        Map<String,Object> endDateMap = (Map<String,Object>)pdtDataResMap.get('end-date');
        if(repDateMap != null && repDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
            vedaParam.fileBanReport.reportedDate = String.valueOf(repDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
        }
        if(isExtendedMap != null && isExtendedMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
            vedaParam.fileBanReport.isExtended = String.valueOf(isExtendedMap.get(EquifaxIntegrationConstants.NODEVALUE));
        }
        if(endDateMap != null && endDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
            vedaParam.fileBanReport.endDate = String.valueOf(endDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
        }
        return vedaParam;
    }

    public static List<ints.VedaComprehensiveResponse.possibleMatch> getVedaPossibleMatches(Map<String,Object> pdtDataResMap){
        List<ints.VedaComprehensiveResponse.possibleMatch> vedaPossMatList = new List<ints.VedaComprehensiveResponse.possibleMatch>();
        List<Map<String, Object>> possMatMapList = new List<Map<String, Object>>(); 
        Map<String, Object> possMatMap = (Map<String, Object>)pdtDataResMap.get(EquifaxIntegrationConstants.POSSIBLE_MATCHES);
        if(possMatMap != null && possMatMap.containsKey('possible-match')){
            possMatMapList = getListOfMaps(possMatMap,'possible-match');
            if(possMatMapList != null && possMatMapList.size()>0){
                for(Map<String, Object> possMat : possMatMapList){
                    ints.VedaComprehensiveResponse.possibleMatch vedaPossMat = new ints.VedaComprehensiveResponse.possibleMatch();
                    Map<String, Object> prMatResMap = (Map<String, Object>)possMat.get('identity');
                    if(prMatResMap != null){
                        Map<String, Object> buRefResMap = (Map<String, Object>)prMatResMap.get('bureau-reference');
                        Map<String, Object> indNameResMap = (Map<String, Object>)prMatResMap.get('individual-name');
                        Map<String, Object> genResMap = (Map<String, Object>)prMatResMap.get('gender');
                        Map<String, Object> dobResMap = (Map<String, Object>)prMatResMap.get('date-of-birth');
                        Map<String, Object> isDecResMap = (Map<String, Object>)prMatResMap.get('is-deceased');
                        Map<String, Object> driLicResMap = (Map<String, Object>)prMatResMap.get('drivers-licence');
                        Map<String, Object> lodgeResMap = (Map<String, Object>)prMatResMap.get('lodged-complaint');
                        if(indNameResMap != null){
                            Map<String, Object> famNameResMap = (Map<String, Object>)indNameResMap.get('family-name');
                            Map<String, Object> firstNameResMap = (Map<String, Object>)indNameResMap.get('first-given-name');
                            Map<String, Object> otherNameResMap = (Map<String, Object>)indNameResMap.get('other-given-name');
                            if(firstNameResMap != null && firstNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                vedaPossMat.identity.individualNameFirstGivenName = String.valueOf(firstNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            }
                            if(indNameResMap != null && indNameResMap.containsKey('first-reported-date')){
                                vedaPossMat.identity.individualNameFirstReportedDate = String.valueOf(indNameResMap.get('first-reported-date'));
                            }
                            if(famNameResMap != null && famNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                vedaPossMat.identity.individualNameFamilyName = String.valueOf(famNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            }
                            if(indNameResMap != null && indNameResMap.containsKey('last-reported-date')){
                                vedaPossMat.identity.individualNameLastReportedDate = String.valueOf(indNameResMap.get('last-reported-date'));
                            }
                            if(otherNameResMap != null && otherNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                vedaPossMat.identity.individualNameOtherGivenName.add(String.valueOf(otherNameResMap.get(EquifaxIntegrationConstants.NODEVALUE)));
                            }
                        }
                        if(buRefResMap != null && buRefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPossMat.identity.bureauReference = String.valueOf(buRefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPossMat.identity.dateOfBirth = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dobResMap != null && dobResMap.containsKey('first-reported-date')){
                            vedaPossMat.identity.dateOfBirthFirstReportedDate = String.valueOf(dobResMap.get('first-reported-date'));
                        }
                        if(dobResMap != null && dobResMap.containsKey('last-reported-date')){
                            vedaPossMat.identity.dateOfBirthLastReportedDate = String.valueOf(dobResMap.get('last-reported-date'));
                        }
                        if(driLicResMap != null && driLicResMap.containsKey('first-reported-date')){
                            vedaPossMat.identity.driversLicenceFirstReportedDate = String.valueOf(driLicResMap.get('first-reported-date'));
                        }
                        if(driLicResMap != null && driLicResMap.containsKey('last-reported-date')){
                            vedaPossMat.identity.driversLicenceLastReportedDate = String.valueOf(driLicResMap.get('last-reported-date'));
                        }
                        if(driLicResMap != null && driLicResMap.containsKey('number')){
                            Map<String, Object> driLicNameMap = (Map<String, Object>)driLicResMap.get('number');
                            if(driLicNameMap != null && driLicNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                vedaPossMat.identity.driversLicenceNumber = String.valueOf(driLicNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            }
                        }
                        if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPossMat.identity.gender = String.valueOf(genResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(genResMap != null && genResMap.containsKey('code')){
                            vedaPossMat.identity.genderCode = String.valueOf(genResMap.get('code'));
                        }
                        if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPossMat.identity.isDeceased = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(isDecResMap != null && isDecResMap.containsKey('reported-date')){
                            vedaPossMat.identity.isDeceasedReportedDate = String.valueOf(isDecResMap.get('reported-date'));
                        }
                        if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPossMat.identity.lodgedComplaint = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPossMat.identity.lodgedComplaintReportedDate = String.valueOf(lodgeResMap.get('reported-date'));
                        }
                        if(prMatResMap != null && prMatResMap.containsKey('id-index')){
                            vedaPossMat.identity.idIndex = String.valueOf(prMatResMap.get('id-index'));
                        }    
                    }
                    if(possMat != null && possMat.containsKey(EquifaxIntegrationConstants.ADDRESSES)){
                        vedaPossMat.addresses = getVedaAddresses(possMat);
                    }
                    if(possMat != null && possMat.containsKey(EquifaxIntegrationConstants.EMPLOYMENT)){
                        vedaPossMat.employment = getVedaEmployments(possMat);
                    }
                    if(vedaPossMat != null){
                        vedaPossMatList.add(vedaPossMat);
                    }
                }
            }
        }
        return vedaPossMatList;


    }

    public static List<ints.VedaComprehensiveResponse.DataBlock> getVedaSummaryData(Map<String,Object> resSummDataMap){
        List<ints.VedaComprehensiveResponse.DataBlock> vedaDataBlockList = new List<ints.VedaComprehensiveResponse.DataBlock>(); 
        List<Map<String, Object>> dataBlockMapList = new List<Map<String, Object>>(); 
        Map<String, Object> dataBlockMap = (Map<String, Object>)resSummDataMap.get(EquifaxIntegrationConstants.SUMM_DATA);
        if(dataBlockMap != null && dataBlockMap.containsKey('data-block')){
            dataBlockMapList = getListOfMaps(dataBlockMap,'data-block');
            if(dataBlockMapList != null && dataBlockMapList.size()>0){
                for(Map<String, Object> dBMap : dataBlockMapList){
                    ints.VedaComprehensiveResponse.DataBlock vedaDataBlock = new ints.VedaComprehensiveResponse.DataBlock();
                    if(dBMap != null && dBMap.containsKey('name')){
                        vedaDataBlock.name = String.valueOf(dBMap.get('name'));
                    }
                    if(dBMap != null && dBMap.containsKey('type')){
                        vedaDataBlock.type = String.valueOf(dBMap.get('type'));
                    }
                    if(dBMap != null && dBMap.containsKey('characteristic')){
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

    public static List<ints.VedaComprehensiveResponse.Characteristic> getDataBlockCharacteristics(Map<String,Object> dBMap){
        List<ints.VedaComprehensiveResponse.Characteristic> vedaDbCharList = new  List<ints.VedaComprehensiveResponse.Characteristic> ();
        List<Map<String, Object>> dBcharMapList = new List<Map<String, Object>>(); 
        dBcharMapList = getListOfMaps(dBMap,'characteristic');
        if(dBcharMapList != null && dBcharMapList.size()>0){
            for(Map<String, Object> dBCharMap : dBcharMapList){
                ints.VedaComprehensiveResponse.Characteristic vedaDbChar = new ints.VedaComprehensiveResponse.Characteristic();
                Map<String, Object> charVarNameMap = (Map<String, Object>)dBCharMap.get('variable-name');
                Map<String, Object> charDescMap = (Map<String, Object>)dBCharMap.get('description');
                Map<String, Object> charValueMap = (Map<String, Object>)dBCharMap.get('value');
                Map<String, Object> charDataLevelMap = (Map<String, Object>)dBCharMap.get('data-level');
                if(charDataLevelMap != null && charDataLevelMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaDbChar.dataLevel = String.valueOf(charDataLevelMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(charDataLevelMap != null && charDataLevelMap.containsKey('code')){
                    vedaDbChar.dataLevelCode = String.valueOf(charDataLevelMap.get('code'));
                }
                if(charDescMap != null && charDescMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaDbChar.description = String.valueOf(charDescMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(dBCharMap != null && dBCharMap.containsKey('id')){
                    vedaDbChar.characteristicId = String.valueOf(dBCharMap.get('id'));
                }
                if(dBCharMap != null && dBCharMap.containsKey('key-characteristic')){
                    vedaDbChar.keyCharacteristic = String.valueOf(dBCharMap.get('key-characteristic'));
                }
                if(charValueMap != null && charValueMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaDbChar.value = String.valueOf(charValueMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(charValueMap != null && charValueMap.containsKey('unit')){
                    vedaDbChar.unit = String.valueOf(charValueMap.get('unit'));
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

    public static List<ints.VedaComprehensiveResponse.Score> getVedaScoreData(Map<String,Object> resScoreMap){
        List<ints.VedaComprehensiveResponse.Score> vedaScoreList = new List<ints.VedaComprehensiveResponse.Score>(); 
        Map<String, Object> scoreMap = (Map<String, Object>)resScoreMap.get(EquifaxIntegrationConstants.SCORE_DATA);
        if(scoreMap != null && scoreMap.containsKey('score')){
            List<Map<String, Object>> scoreResMapList = getListOfMaps(scoreMap,'score');
            if(scoreResMapList != null && scoreResMapList.size()>0){
                for(Map<String, Object> scoreResMap : scoreResMapList){
                    ints.VedaComprehensiveResponse.Score vedaScoreRes = new ints.VedaComprehensiveResponse.Score();
                    Map<String, Object> scoreCardMap = (Map<String, Object>)scoreResMap.get('scorecard');
                    if(scoreCardMap != null){
                        Map<String, Object> scoreCardName = (Map<String, Object>)scoreCardMap.get('name');
                        Map<String, Object> scoreCardVersion = (Map<String, Object>)scoreCardMap.get('version');
                        Map<String, Object> scoreCardType = (Map<String, Object>)scoreCardMap.get('type');
                        Map<String, Object> scoreCardDateLevel = (Map<String, Object>)scoreCardMap.get('data-level');
                        if(scoreCardDateLevel != null && scoreCardDateLevel.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaScoreRes.scoreDataLevel = String.valueOf(scoreCardDateLevel.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(scoreCardDateLevel != null && scoreCardDateLevel.containsKey('code')){
                            vedaScoreRes.scoreDataLevelCode = String.valueOf(scoreCardDateLevel.get('code'));
                        }
                        if(scoreCardMap.containsKey('id')){
                            vedaScoreRes.scoreId = String.valueOf(scoreCardMap.get('id'));
                        }
                        if(scoreCardName != null && scoreCardName.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaScoreRes.scoreName = String.valueOf(scoreCardName.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(scoreCardVersion != null && scoreCardVersion.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaScoreRes.scoreVersion = String.valueOf(scoreCardVersion.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(scoreCardType != null && scoreCardType.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaScoreRes.scorType = String.valueOf(scoreCardType.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                    }
                    Map<String, Object> riskOddsMap = (Map<String, Object>)scoreResMap.get('risk-odds');
                    if(riskOddsMap != null && riskOddsMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaScoreRes.riskOdds = String.valueOf(riskOddsMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> scoreMasScaleMap = (Map<String, Object>)scoreResMap.get('score-masterscale');
                    if(scoreMasScaleMap != null && scoreMasScaleMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaScoreRes.scoreMasterscale = String.valueOf(scoreMasScaleMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> conFactorsMap = (Map<String, Object>)scoreResMap.get('key-contributing-factors');
                    vedaScoreRes.contributingFactor = getScoreConFactors(conFactorsMap);
                    if(vedaScoreRes != null){
                        vedaScoreList.add(vedaScoreRes);
                    }
                }
            }
        }
        return vedaScoreList;
    }

    public static List<ints.VedaComprehensiveResponse.ContributingFactor> getScoreConFactors(Map<String,Object> conFactorsMap){
        List<ints.VedaComprehensiveResponse.ContributingFactor> vedaConFacList = new List<ints.VedaComprehensiveResponse.ContributingFactor>(); 
        if(conFactorsMap != null && conFactorsMap.containsKey('contributing-factor')){
            List<Map<String, Object>> vedaMapList = getListOfMaps(conFactorsMap,'contributing-factor');
            if(vedaMapList != null && vedaMapList.size()>0){
                for(Map<String, Object> conFacMap : vedaMapList){
                    ints.VedaComprehensiveResponse.ContributingFactor vedaConFac = new ints.VedaComprehensiveResponse.ContributingFactor();
                    Map<String, Object> conFacNameMap = (Map<String, Object>)conFacMap.get('name');
                    Map<String, Object> conFacDesMap = (Map<String, Object>)conFacMap.get('description');
                    Map<String, Object> conFaScoImpMap = (Map<String, Object>)conFacMap.get('score-impactor');
                    if(conFacNameMap != null && conFacNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaConFac.name = String.valueOf(conFacNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(conFacDesMap != null && conFacDesMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaConFac.description = String.valueOf(conFacDesMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(conFaScoImpMap != null && conFaScoImpMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaConFac.scoreImpactor = String.valueOf(conFaScoImpMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(conFacMap != null && conFacMap.containsKey('id')){
                        vedaConFac.contributingFactorId = String.valueOf(conFacMap.get('id'));
                    }
                    if(conFacMap != null){
                        vedaConFacList.add(vedaConFac);
                    }
                }
            }
        }
        return vedaConFacList;
    }



    public static List<ints.VedaComprehensiveResponse.OtherIdentity> getVedaOtherIdentities(Map<String,Object> vedaOtherIdenMap){
        List<ints.VedaComprehensiveResponse.OtherIdentity> vedaOthIdenList = new List<ints.VedaComprehensiveResponse.OtherIdentity>(); 
        Map<String, Object> othIdenMap = (Map<String, Object>)vedaOtherIdenMap.get(EquifaxIntegrationConstants.OTHER_IDEN);
        if(othIdenMap != null && othIdenMap.containsKey('other-identity')){
            List<Map<String, Object>> vedaMapList = getListOfMaps(othIdenMap,'other-identity');
            for(Map<String, Object> otherIdenMap : vedaMapList){
                ints.VedaComprehensiveResponse.OtherIdentity vedaResOtherIden = new ints.VedaComprehensiveResponse.OtherIdentity();
                Map<String, Object> buRefResMap = (Map<String, Object>)otherIdenMap.get('bureau-reference');
                Map<String, Object> indNameResMap = (Map<String, Object>)otherIdenMap.get('individual-name');
                Map<String, Object> genResMap = (Map<String, Object>)otherIdenMap.get('gender');
                Map<String, Object> dobResMap = (Map<String, Object>)otherIdenMap.get('date-of-birth');
                Map<String, Object> isDecResMap = (Map<String, Object>)otherIdenMap.get('is-deceased');
                Map<String, Object> driLicResMap = (Map<String, Object>)otherIdenMap.get('drivers-licence');
                Map<String, Object> lodgeResMap = (Map<String, Object>)otherIdenMap.get('lodged-complaint');
                if(indNameResMap != null){
                    Map<String, Object> famNameResMap = (Map<String, Object>)indNameResMap.get('family-name');
                    Map<String, Object> firstNameResMap = (Map<String, Object>)indNameResMap.get('first-given-name');
                    Map<String, Object> otherNameResMap = (Map<String, Object>)indNameResMap.get('other-given-name');
                    if(firstNameResMap != null && firstNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaResOtherIden.individualNameFirstGivenName = String.valueOf(firstNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(indNameResMap != null && indNameResMap.containsKey('first-reported-date')){
                        vedaResOtherIden.individualNameFirstReportedDate = String.valueOf(indNameResMap.get('first-reported-date'));
                    }
                    if(famNameResMap != null && famNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaResOtherIden.individualNameFamilyName = String.valueOf(famNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(indNameResMap != null && indNameResMap.containsKey('last-reported-date')){
                        vedaResOtherIden.individualNameLastReportedDate = String.valueOf(indNameResMap.get('last-reported-date'));
                    }
                    if(otherNameResMap != null && otherNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaResOtherIden.individualNameOtherGivenName.add(String.valueOf(otherNameResMap.get(EquifaxIntegrationConstants.NODEVALUE)));
                    }
                    if(indNameResMap != null && indNameResMap.containsKey('last-credit-enquiry-date')){
                        vedaResOtherIden.individualNameLastCreditEnquiryDate = String.valueOf(indNameResMap.get('last-credit-enquiry-date'));
                    }
                }
                if(buRefResMap != null && buRefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaResOtherIden.bureauReference = String.valueOf(buRefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaResOtherIden.dateOfBirth = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(dobResMap != null && dobResMap.containsKey('first-reported-date')){
                    vedaResOtherIden.dateOfBirthFirstReportedDate = String.valueOf(dobResMap.get('first-reported-date'));
                }
                if(dobResMap != null && dobResMap.containsKey('last-reported-date')){
                    vedaResOtherIden.dateOfBirthLastReportedDate = String.valueOf(dobResMap.get('last-reported-date'));
                }
                if(driLicResMap != null && driLicResMap.containsKey('first-reported-date')){
                    vedaResOtherIden.driversLicenceFirstReportedDate = String.valueOf(driLicResMap.get('first-reported-date'));
                }
                if(driLicResMap != null && driLicResMap.containsKey('last-reported-date')){
                    vedaResOtherIden.driversLicenceLastReportedDate = String.valueOf(driLicResMap.get('last-reported-date'));
                }
                if(driLicResMap != null && driLicResMap.containsKey('number')){
                    Map<String, Object> driLicNameMap = (Map<String, Object>)driLicResMap.get('number');
                    if(driLicNameMap != null && driLicNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaResOtherIden.driversLicenceNumber = String.valueOf(driLicNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                }
                if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaResOtherIden.gender = String.valueOf(genResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(genResMap != null && genResMap.containsKey('code')){
                    vedaResOtherIden.genderCode = String.valueOf(genResMap.get('code'));
                }
                if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaResOtherIden.isDeceased = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(isDecResMap != null && isDecResMap.containsKey('reported-date')){
                    vedaResOtherIden.isDeceasedReportedDate = String.valueOf(isDecResMap.get('reported-date'));
                }
                if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaResOtherIden.lodgedComplaint = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaResOtherIden.lodgedComplaintReportedDate = String.valueOf(lodgeResMap.get('reported-date'));
                }
                if(vedaResOtherIden != null){
                    vedaOthIdenList.add(vedaResOtherIden);
                }
            }    
        }
        return vedaOthIdenList;
    }
    // Takes addresses of equifax xml response in a Map and returns vedaComprehensive addresses
    
    public static List<ints.VedaComprehensiveResponse.Address> getVedaAddresses(Map<String,Object> resAddMap){
        List<ints.VedaComprehensiveResponse.Address> vedaAddList = new List<ints.VedaComprehensiveResponse.Address>(); 
        Map<String, Object> addMap = (Map<String, Object>)resAddMap.get(EquifaxIntegrationConstants.ADDRESSES);
        if(addMap != null && addMap.containsKey('address')){
            List<Map<String, Object>> addResMapList = getListOfMaps(addMap,'address'); 
            if(addResMapList != null){
                for(Map<String, Object> addResMap : addResMapList){
                    ints.VedaComprehensiveResponse.Address vedaAddRes = new ints.VedaComprehensiveResponse.Address();
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
                        vedaAddRes.idReference = getIdReferences(idRefMap);  
                    }
                    if(conCodeMap != null && conCodeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAddRes.countryCode = String.valueOf(conCodeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(addResMap.containsKey('first-reported-date')){
                        vedaAddRes.firstReportedDate = String.valueOf(addResMap.get('first-reported-date'));
                    }
                    if(addResMap.containsKey('last-reported-date')){
                        vedaAddRes.lastReportedDate = String.valueOf(addResMap.get('last-reported-date'));
                    }
                    if(postCodeMap != null && postCodeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAddRes.postcode = String.valueOf(postCodeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(propertyMap != null && propertyMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAddRes.property = String.valueOf(propertyMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(stateMap != null && stateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAddRes.state = String.valueOf(stateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(stNameMap != null && stNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAddRes.streetName = String.valueOf(stNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(stNumMap != null && stNumMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAddRes.streetNumber = String.valueOf(stNumMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(stTypeMap != null && stTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAddRes.streetType = String.valueOf(stTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(subMap != null && subMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAddRes.suburb = String.valueOf(subMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(addResMap != null && addResMap.containsKey('type')){
                        vedaAddRes.type = String.valueOf(addResMap.get('type'));
                    }
                    if(unitNumMap != null && unitNumMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAddRes.unitNumber = String.valueOf(unitNumMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(vedaAddRes != null){
                        vedaAddList.add(vedaAddRes);
                    }
                }
            }
        }
        return vedaAddList;
    }
    public static List<ints.VedaComprehensiveResponse.Employer> getVedaEmployments(Map<String,Object> resEmpMap){
        List<ints.VedaComprehensiveResponse.Employer> vedaEmpList = new List<ints.VedaComprehensiveResponse.Employer>(); 
        Map<String, Object> empMap = (Map<String, Object>)resEmpMap.get(EquifaxIntegrationConstants.EMPLOYMENT);
        if(empMap != null && empMap.containsKey('employer')){
            List<Map<String, Object>> empMapList = getListOfMaps(empMap,'employer'); 
            if(empMapList != null){
                for(Map<String, Object> empResMap : empMapList){
                    ints.VedaComprehensiveResponse.Employer vedaEmpRes = new ints.VedaComprehensiveResponse.Employer();
                    if(empResMap != null && empResMap.containsKey('first-reported-date')){
                        vedaEmpRes.firstReportedDate = String.valueOf(empResMap.get('first-reported-date'));
                    }
                    if(empResMap != null && empResMap.containsKey('last-reported-date')){
                        vedaEmpRes.lastReportedDate = String.valueOf(empResMap.get('last-reported-date'));
                    }
                    if(empResMap != null && empResMap.containsKey('type')){
                        vedaEmpRes.type = String.valueOf(empResMap.get('type'));
                    }
                    Map<String, Object> empNameMap = (Map<String, Object>)empResMap.get('name');
                    if(empNameMap != null && empNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaEmpRes.name = String.valueOf(empNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> empOccMap = (Map<String, Object>)empResMap.get('occupation');
                    if(empOccMap != null && empOccMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaEmpRes.occupation = String.valueOf(empOccMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> idRefMap = (Map<String, Object>)empResMap.get('id-references');
                    if(idRefMap != null && idRefMap.containsKey('id-reference')){
                        vedaEmpRes.idReferences = getIdReferences(idRefMap);   
                    }
                    if(vedaEmpRes != null){
                        vedaEmpList.add(vedaEmpRes);
                    }
                }
            }
        }
        return vedaEmpList;
    }

    public static List<ints.VedaComprehensiveResponse.CreditEnquiry> getVedaConsumerCreditEnquiries(Map<String, Object> conCreFileMap){
        List<ints.VedaComprehensiveResponse.CreditEnquiry> vedaCredEnqList = new List<ints.VedaComprehensiveResponse.CreditEnquiry>();
        Map<String, Object> creEnqMap = (Map<String, Object>)conCreFileMap.get(EquifaxIntegrationConstants.CREDIT_ENQS);
        if(creEnqMap != null && creEnqMap.containsKey('credit-enquiry')){
            List<Map<String, Object>> creEnqMapList = getListOfMaps(creEnqMap,'credit-enquiry'); 
            if(creEnqMapList != null){
                for(Map<String, Object> creEnq : creEnqMapList){
                    ints.VedaComprehensiveResponse.CreditEnquiry vedaCredEnq = new ints.VedaComprehensiveResponse.CreditEnquiry();
                    Map<String, Object> accTypeMap = (Map<String, Object>)creEnq.get('account-type');
                    Map<String, Object> enqAmtMap = (Map<String, Object>)creEnq.get('enquiry-amount');
                    Map<String, Object> relMap = (Map<String, Object>)creEnq.get('relationship');
                    Map<String, Object> creEnqrMap = (Map<String, Object>)creEnq.get('credit-enquirer');
                    Map<String, Object> creCliRefMap = (Map<String, Object>)creEnq.get('enquiry-client-reference');
                    Map<String, Object> idRefMap = (Map<String, Object>)creEnq.get('id-references');
                    Map<String, Object> coBorrowerMap = (Map<String, Object>)creEnq.get('co-borrower');
                    if(creEnqrMap != null && creEnqrMap.containsKey('name')){
                        Map<String, Object> creEnqrNameMap = (Map<String, Object>)creEnqrMap.get('name');
                        if(creEnqrNameMap != null && creEnqrNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaCredEnq.creditEnquirerName = String.valueOf(creEnqrNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                    }
                    if(creEnqrMap != null && creEnqrMap.containsKey('classification')){
                        Map<String, Object> creEnqrClasMap = (Map<String, Object>)creEnqrMap.get('classification');
                        if(creEnqrClasMap != null && creEnqrClasMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaCredEnq.creditEnquirerClassification = String.valueOf(creEnqrClasMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                    }
                    if(idRefMap != null && idRefMap.containsKey('id-reference')){
                        vedaCredEnq.idReferences = getIdReferences(idRefMap);   
                    }
                    if(coBorrowerMap != null && coBorrowerMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaCredEnq.coBorrower = String.valueOf(coBorrowerMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaCredEnq.accountType = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accTypeMap != null && accTypeMap.containsKey('code')){
                        vedaCredEnq.accountTypeCode = String.valueOf(accTypeMap.get('code'));
                    }
                    if(enqAmtMap != null && enqAmtMap.containsKey('currency-code')){
                        vedaCredEnq.enquiryAmountCurrencyCode = String.valueOf(enqAmtMap.get('currency-code'));
                    }
                    if(enqAmtMap != null && enqAmtMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaCredEnq.enquiryAmount = String.valueOf(enqAmtMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(creEnq != null && creEnq.containsKey('enquiry-date')){
                        vedaCredEnq.enquiryDate = String.valueOf(creEnq.get('enquiry-date'));
                    }
                    if(creEnq != null && creEnq.containsKey('type')){
                        vedaCredEnq.type = String.valueOf(creEnq.get('type'));
                    }
                    if(vedaCredEnq != null){
                        vedaCredEnqList.add(vedaCredEnq);
                    }
                }
            }
        }
        return vedaCredEnqList;
    }

    public static List<ints.VedaComprehensiveResponse.CreditEnquiry> getVedaCommercialCreditEnquiries(Map<String, Object> comCreFileMap){
        List<ints.VedaComprehensiveResponse.CreditEnquiry> vedaCredEnqList = new List<ints.VedaComprehensiveResponse.CreditEnquiry>();
        Map<String, Object> creEnqMap = (Map<String, Object>)comCreFileMap.get(EquifaxIntegrationConstants.CREDIT_ENQS);
        if(creEnqMap != null && creEnqMap.containsKey('credit-enquiry')){
            List<Map<String, Object>> creEnqMapList = getListOfMaps(creEnqMap,'credit-enquiry');
            if(creEnqMapList != null){
                for(Map<String, Object> creEnq : creEnqMapList){
                    ints.VedaComprehensiveResponse.CreditEnquiry vedaComCredEnq= new ints.VedaComprehensiveResponse.CreditEnquiry();
                    Map<String, Object> accTypeMap = (Map<String, Object>)creEnq.get('account-type');
                    Map<String, Object> enqAmtMap = (Map<String, Object>)creEnq.get('enquiry-amount');
                    Map<String, Object> relMap = (Map<String, Object>)creEnq.get('relationship');
                    Map<String, Object> creEnqrMap = (Map<String, Object>)creEnq.get('credit-enquirer');
                    Map<String, Object> creCliRefMap = (Map<String, Object>)creEnq.get('enquiry-client-reference');
                    Map<String, Object> idRefMap = (Map<String, Object>)creEnq.get('id-references');
                    Map<String, Object> coBorrowerMap = (Map<String, Object>)creEnq.get('co-borrower');
                    if(creEnqrMap != null && creEnqrMap.containsKey('name')){
                        Map<String, Object> creEnqrNameMap = (Map<String, Object>)creEnqrMap.get('name');
                        if(creEnqrNameMap != null && creEnqrNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaComCredEnq.creditEnquirerName = String.valueOf(creEnqrNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                    }
                    if(creEnqrMap != null && creEnqrMap.containsKey('classification')){
                        Map<String, Object> creEnqrClasMap = (Map<String, Object>)creEnqrMap.get('classification');
                        if(creEnqrClasMap != null && creEnqrClasMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaComCredEnq.creditEnquirerClassification = String.valueOf(creEnqrClasMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                    }
                    if(idRefMap != null && idRefMap.containsKey('id-reference')){
                        vedaComCredEnq.idReferences = getIdReferences(idRefMap);
                    }
                    if(coBorrowerMap != null && coBorrowerMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaComCredEnq.coBorrower = String.valueOf(coBorrowerMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaComCredEnq.accountType = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accTypeMap != null && accTypeMap.containsKey('code')){
                        vedaComCredEnq.accountTypeCode = String.valueOf(accTypeMap.get('code'));
                    }
                    if(enqAmtMap != null && enqAmtMap.containsKey('currency-code')){
                        vedaComCredEnq.enquiryAmountCurrencyCode = String.valueOf(enqAmtMap.get('currency-code'));
                    }
                    if(enqAmtMap != null && enqAmtMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaComCredEnq.enquiryAmount = String.valueOf(enqAmtMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(creEnq != null && creEnq.containsKey('enquiry-date')){
                        vedaComCredEnq.enquiryDate = String.valueOf(creEnq.get('enquiry-date'));
                    }
                    if(creEnq != null && creEnq.containsKey('type')){
                        vedaComCredEnq.type = String.valueOf(creEnq.get('type'));
                    }
                    if(vedaComCredEnq != null){
                        vedaCredEnqList.add(vedaComCredEnq);
                    }
                }
            }
        }
        return vedaCredEnqList;
    }

    public static List<ints.VedaComprehensiveResponse.account> getVedaAccounts(Map<String, Object> conCreFileMap){
        List<ints.VedaComprehensiveResponse.account> vedaAccList = new List<ints.VedaComprehensiveResponse.account>();
        Map<String, Object> accountsMap = (Map<String, Object>)conCreFileMap.get(EquifaxIntegrationConstants.ACCOUNTS);
        if(accountsMap != null && accountsMap.containsKey('account')){
            List<Map<String, Object>> accMapList = getListOfMaps(accountsMap,'account');
            if(accMapList != null){
                for(Map<String, Object> accMap : accMapList){
                    ints.VedaComprehensiveResponse.account vedaAcc = new ints.VedaComprehensiveResponse.account();
                    Map<String, Object> accTypeMap = (Map<String, Object>)accMap.get('account-type');
                    Map<String, Object> accIdMap = (Map<String, Object>)accMap.get('account-id');
                    Map<String, Object> oriCredProMap = (Map<String, Object>)accMap.get('original-credit-provider');
                    Map<String, Object> relMap = (Map<String, Object>)accMap.get('relationship');
                    Map<String, Object> accHolderCntMap = (Map<String, Object>)accMap.get('account-holder-count');
                    Map<String, Object> accOpenDateMap = (Map<String, Object>)accMap.get('account-open-date');
                    Map<String, Object> accReOpenDateMap = (Map<String, Object>)accMap.get('account-re-open-date');
                    Map<String, Object> loanPayMetMap = (Map<String, Object>)accMap.get('loan-payment-method');
                    Map<String, Object> termTypeMap = (Map<String, Object>)accMap.get('term-type');
                    Map<String, Object> secCreditMap = (Map<String, Object>)accMap.get('secured-credit');
                    Map<String, Object> termOfLoanMap = (Map<String, Object>)accMap.get('term-of-loan');
                    Map<String, Object> latMaxAmtCreMap = (Map<String, Object>)accMap.get('latest-maximum-amount-credit');
                    Map<String, Object> isUnlimCreditMap = (Map<String, Object>)accMap.get('is-unlimited-credit');
                    Map<String, Object> accClosedDateMap = (Map<String, Object>)accMap.get('account-closed-date');
                    Map<String, Object> dateLatChangedMap = (Map<String, Object>)accMap.get('date-last-changed');
                    Map<String, Object> oriMaxAmtCreditMap = (Map<String, Object>)accMap.get('original-maximum-amount-credit');
                    Map<String, Object> assInfoMap = (Map<String, Object>)accMap.get('association-information');
                    Map<String, Object> idRefMap = (Map<String, Object>)accMap.get('id-references');
                    if(idRefMap != null && idRefMap.containsKey('id-reference')){
                        vedaAcc.idReferences = getIdReferences(idRefMap);  
                    }
                    if(oriCredProMap != null && oriCredProMap.containsKey('name')){
                        Map<String, Object> oriCredProNameMap = (Map<String, Object>)oriCredProMap.get('name');
                        vedaAcc.originalCreditProviderName = String.valueOf(oriCredProNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(oriCredProMap != null && oriCredProMap.containsKey('classification')){
                        Map<String, Object> oriCredProClassMap = (Map<String, Object>)oriCredProMap.get('classification');
                        vedaAcc.originalCreditProviderClassification = String.valueOf(oriCredProClassMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(oriCredProMap != null && oriCredProMap.containsKey('is-licensee')){
                        Map<String, Object> oriCredProLiceMap = (Map<String, Object>)oriCredProMap.get('is-licensee');
                        vedaAcc.originalCreditProviderIsLicensee = String.valueOf(oriCredProLiceMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> latCredProMap = (Map<String, Object>)accMap.get('latest-credit-provider');
                    if(latCredProMap != null && latCredProMap.containsKey('name')){
                        Map<String, Object> latCredProNameMap = (Map<String, Object>)latCredProMap.get('name');
                        vedaAcc.latestCreditProviderName = String.valueOf(latCredProNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(latCredProMap != null && latCredProMap.containsKey('classification')){
                        Map<String, Object> latCredProClassMap = (Map<String, Object>)latCredProMap.get('classification');
                    }
                    if(latCredProMap != null && latCredProMap.containsKey('is-licensee')){
                        Map<String, Object> latCredProLiceMap = (Map<String, Object>)latCredProMap.get('is-licensee');
                    }
                    if(assInfoMap != null && assInfoMap.containsKey('latest-start-date')){
                        Map<String, Object> assInfoStDateMap = (Map<String, Object>)assInfoMap.get('latest-start-date');
                        vedaAcc.associationInformationLatestStartDate = String.valueOf(assInfoStDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(assInfoMap != null && assInfoMap.containsKey('is-serious-credit-infringement')){
                        Map<String, Object> assInfoIsSeCreInfriMap = (Map<String, Object>)assInfoMap.get('is-serious-credit-infringement');
                        vedaAcc.associationInformationIsSeriousCreditInfringement = String.valueOf(assInfoIsSeCreInfriMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(assInfoMap != null && assInfoMap.containsKey('latest-ceased-date')){
                        Map<String, Object> assInfoCeaseDateMap = (Map<String, Object>)assInfoMap.get('latest-ceased-date');
                        vedaAcc.associationInformationLatestCeasedDate = String.valueOf(assInfoCeaseDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(assInfoMap != null && assInfoMap.containsKey('default-association-cease-date')){
                        Map<String, Object> assInfodefAssCeaseDateMap = (Map<String, Object>)assInfoMap.get('default-association-cease-date');
                        vedaAcc.associationInformationDefaultAssociationCeaseDate = String.valueOf(assInfodefAssCeaseDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(assInfoMap != null && assInfoMap.containsKey('default-association-start-date')){
                        Map<String, Object> assInfodefAssStartDateMap = (Map<String, Object>)assInfoMap.get('default-association-start-date');
                        vedaAcc.associationInformationDefaultAssociationStartDate = String.valueOf(assInfodefAssStartDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(assInfoMap != null && assInfoMap.containsKey('sci-Date')){
                        Map<String, Object> assInfoSciDateMap = (Map<String, Object>)assInfoMap.get('sci-Date');
                        vedaAcc.associationInformationSciDate = String.valueOf(assInfoSciDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(assInfoMap != null && assInfoMap.containsKey('is-licensee')){
                        Map<String, Object> latCredProLiceMap = (Map<String, Object>)assInfoMap.get('is-licensee');
                    }
                    // Account Repayment Hisroty
                    Map<String, Object> payHistoryMap = (Map<String, Object>)accMap.get('repayment-history');
                    if(payHistoryMap != null && payHistoryMap.containsKey('payment')){
                        vedaAcc.repaymentHistory =  getVedaAccPayments(payHistoryMap);  
                    }
                    // Account Defaults
                    Map<String, Object> defaultsMap = (Map<String, Object>)accMap.get('defaults');
                    if(defaultsMap != null && defaultsMap.containsKey('default')){
                        vedaAcc.defaults = getVedaAccDefaults(defaultsMap);  
                    }
                    if(accClosedDateMap != null && accClosedDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.accountClosedDate = String.valueOf(accClosedDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accOpenDateMap != null && accOpenDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.accountClosedDate = String.valueOf(accOpenDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accReOpenDateMap != null && accReOpenDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.accountClosedDate = String.valueOf(accReOpenDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accMap != null && accMap.containsKey('account-data-level')){
                        vedaAcc.accountDataLevel = String.valueOf(accMap.get('account-data-level'));
                    }
                    if(accHolderCntMap != null && accHolderCntMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.accountHolderCount = String.valueOf(accHolderCntMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accIdMap != null && accIdMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.accountId = String.valueOf(accIdMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accTypeMap != null && accTypeMap.containsKey('code')){
                        vedaAcc.accountTypeCode = String.valueOf(accTypeMap.get('code'));
                    }
                    if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.accountType = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(dateLatChangedMap != null && dateLatChangedMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.dateLastChanged = String.valueOf(dateLatChangedMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(isUnlimCreditMap != null && isUnlimCreditMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.isUnlimitedCredit = String.valueOf(isUnlimCreditMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(latMaxAmtCreMap != null && latMaxAmtCreMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.latestMaximumAmountCredit = String.valueOf(latMaxAmtCreMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(latMaxAmtCreMap != null && latMaxAmtCreMap.containsKey('currency-code')){
                        vedaAcc.latestMaximumAmountCreditCurrencyCode = String.valueOf(latMaxAmtCreMap.get('currency-code'));
                    }
                    if(accMap != null && accMap.containsKey('latest-update-date')){
                        vedaAcc.latestUpdateDate = String.valueOf(accMap.get('latest-update-date'));
                    }
                    if(loanPayMetMap != null && loanPayMetMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.loanPaymentMethod = String.valueOf(loanPayMetMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(loanPayMetMap != null && loanPayMetMap.containsKey('code')){
                        vedaAcc.loanPaymentMethodCode = String.valueOf(loanPayMetMap.get('code'));
                    }
                    if(oriMaxAmtCreditMap != null && oriMaxAmtCreditMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.originalMaximumAmountCredit = String.valueOf(oriMaxAmtCreditMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(oriMaxAmtCreditMap != null && oriMaxAmtCreditMap.containsKey('currency-code')){
                        vedaAcc.originalMaximumAmountCreditCurrencyCode = String.valueOf(oriMaxAmtCreditMap.get('currency-code'));
                    }
                    if(relMap != null && relMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.relationship = String.valueOf(relMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(relMap != null && relMap.containsKey('code')){
                        vedaAcc.relationshipCode = String.valueOf(relMap.get('code'));
                    }
                    if(secCreditMap != null && secCreditMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.securedCredit = String.valueOf(secCreditMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(secCreditMap != null && secCreditMap.containsKey('code')){
                        vedaAcc.securedCreditCode = String.valueOf(secCreditMap.get('code'));
                    }
                    if(termOfLoanMap != null && termOfLoanMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.termOfLoan = String.valueOf(termOfLoanMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(termTypeMap != null && termTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.termType = String.valueOf(termTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(termTypeMap != null && termTypeMap.containsKey('code')){
                        vedaAcc.termTypeCode = String.valueOf(termTypeMap.get('code'));
                    }
                    if(vedaAcc != null){
                        vedaAccList.add(vedaAcc);
                    }
                }
            }
        }
        return vedaAccList;   
    }

    public static List<ints.VedaComprehensiveResponse.payment> getVedaAccPayments(Map<String,Object> payHistoryMap){
        List<ints.VedaComprehensiveResponse.payment> vedaAccPayList = new List<ints.VedaComprehensiveResponse.payment>();
        List<Map<String, Object>> paymentList = getListOfMaps(payHistoryMap,'payment');
        if(paymentList != null && paymentList.size()>0){
            for(Map<String, Object>  paymentMap : paymentList){
                ints.VedaComprehensiveResponse.payment vedaPayHistory = new ints.VedaComprehensiveResponse.payment();
                if(paymentMap.containsKey('period')){
                    Map<String, Object> payPeriodMap = (Map<String, Object>)paymentMap.get('period');
                    vedaPayHistory.period = String.valueOf(payPeriodMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(paymentMap.containsKey('status')){
                    Map<String, Object> payStatusMap = (Map<String, Object>)paymentMap.get('status');
                    vedaPayHistory.status = String.valueOf(payStatusMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(vedaPayHistory != null){
                    vedaAccPayList.add(vedaPayHistory);
                }
            }
        } 
        return vedaAccPayList;
    }

    public static List<ints.VedaComprehensiveResponse.VedaComprehensivedefault> getVedaAccDefaults(Map<String,Object> defaultsMap){
        List<ints.VedaComprehensiveResponse.VedaComprehensivedefault> vedaDefList = new List<ints.VedaComprehensiveResponse.VedaComprehensivedefault>();
        List<Map<String, Object>> defaultMapList= getListOfMaps(defaultsMap,'default');
        if(defaultMapList != null && defaultMapList.size()>0){
            for(Map<String, Object>  defaultMap : defaultMapList){
                ints.VedaComprehensiveResponse.VedaComprehensivedefault vedaDef = new ints.VedaComprehensiveResponse.VedaComprehensivedefault();       
                if(defaultMap.containsKey('status')){
                    Map<String, Object> defStatusMap = (Map<String, Object>)defaultMap.get('status');
                    if(defStatusMap != null && defStatusMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaDef.status = String.valueOf(defStatusMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(defStatusMap != null && defStatusMap.containsKey('code')){
                        vedaDef.statusCode = String.valueOf(defStatusMap.get('code'));
                    }
                }
                if(defaultMap.containsKey('original-default')){                                                    
                    Map<String, Object> oriDefMap = (Map<String, Object>)defaultMap.get('original-default');
                    if(oriDefMap != null){
                        Map<String, Object> oriDefDateRecMap = (Map<String, Object>)oriDefMap.get('date-recorded');
                        Map<String, Object> oriDefAmtMap = (Map<String, Object>)oriDefMap.get('default-amount');
                        Map<String, Object> oriDefResMap = (Map<String, Object>)oriDefMap.get('reason-to-report');
                        if(oriDefDateRecMap != null && oriDefDateRecMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDef.originalDefaultDateRecorded = String.valueOf(oriDefDateRecMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(oriDefResMap != null && oriDefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDef.originalDefaultDefaultReasonToReport = String.valueOf(oriDefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(oriDefResMap != null && oriDefResMap.containsKey('code')){
                            vedaDef.originalDefaultDefaultReasonToReportCode = String.valueOf(oriDefResMap.get('code'));
                        }
                        if(oriDefAmtMap != null && oriDefAmtMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDef.originalDefaultDefaultAmount = String.valueOf(oriDefAmtMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(oriDefAmtMap != null && oriDefAmtMap.containsKey('currency-code')){
                            vedaDef.originalDefaultDefaultAmountCurrencyCode = String.valueOf(oriDefAmtMap.get('currency-code'));
                        }
                    }
                }
                if(defaultMap.containsKey('current-default')){                                                    
                    Map<String, Object> currDefMap = (Map<String, Object>)defaultMap.get('current-default');
                    if(currDefMap != null){
                        Map<String, Object> currDefDateRecMap = (Map<String, Object>)currDefMap.get('date-recorded');
                        Map<String, Object> currDefAmtMap = (Map<String, Object>)currDefMap.get('default-amount');
                        Map<String, Object> currDefResMap = (Map<String, Object>)currDefMap.get('reason-to-report');
                        if(currDefDateRecMap != null && currDefDateRecMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDef.currentDefaultDateRecorded = String.valueOf(currDefDateRecMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(currDefResMap != null && currDefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDef.currentDefaultReasonToReport = String.valueOf(currDefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(currDefResMap != null && currDefResMap.containsKey('code')){
                            vedaDef.currentDefaultReasonToReportCode = String.valueOf(currDefResMap.get('code'));
                        }
                        if(currDefAmtMap != null && currDefAmtMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDef.currentDefaultDefaultAmount = String.valueOf(currDefAmtMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(currDefAmtMap != null && currDefAmtMap.containsKey('currency-code')){
                            vedaDef.currentDefaultDefaultAmountCurrencyCode = String.valueOf(currDefAmtMap.get('currency-code'));
                        }
                    }
                }
                if(vedaDef != null){
                    vedaDefList.add(vedaDef);
                }
            }
        }
        return vedaDefList;
    }

    public static List<ints.VedaComprehensiveResponse.Error> getVedaErrors(Map<String,Object> resErrorMap){
        List<ints.VedaComprehensiveResponse.Error> vedaErrorList = new List<ints.VedaComprehensiveResponse.Error>();
        Map<String, Object> faultResMap = (Map<String, Object>)resErrorMap.get(EquifaxIntegrationConstants.FAULT);
        ints.VedaComprehensiveResponse.Error vedaErrRes = new ints.VedaComprehensiveResponse.Error();
        if(faultResMap != null){
            Map<String, Object> faultCodeMap = (Map<String, Object>)faultResMap.get('faultcode');
            Map<String, Object> faultStringMap = (Map<String, Object>)faultResMap.get('faultstring');
            Map<String, Object> faultAacMap = (Map<String, Object>)faultResMap.get('faultactor');
            Map<String, Object> faultDetailMap = (Map<String, Object>)faultResMap.get(EquifaxIntegrationConstants.DETAIL);
            if(faultDetailMap != null && faultDetailMap.containsKey('policyResult')){
                Map<String, Object> faultPolResMap = (Map<String, Object>)faultDetailMap.get('policyResult');
                if(faultPolResMap != null && faultPolResMap.containsKey('status')){
                    vedaErrRes.detail  = String.valueOf(faultPolResMap.get('status'));
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

    public static ints.VedaComprehensiveResponse getPrimaryMatchDetails(Map<String,Object> enRepResMap){
        ints.VedaComprehensiveResponse vedaObj = new ints.VedaComprehensiveResponse();
        Map<String, Object> prMatResMap = (Map<String, Object>)enRepResMap.get(EquifaxIntegrationConstants.PRIMARY_MATCH);
        if(prMatResMap != null){
            Map<String, Object> buRefResMap = (Map<String, Object>)prMatResMap.get('bureau-reference');
            Map<String, Object> indNameResMap = (Map<String, Object>)prMatResMap.get('individual-name');
            Map<String, Object> genResMap = (Map<String, Object>)prMatResMap.get('gender');
            Map<String, Object> dobResMap = (Map<String, Object>)prMatResMap.get('date-of-birth');
            Map<String, Object> isDecResMap = (Map<String, Object>)prMatResMap.get('is-deceased');
            Map<String, Object> driLicResMap = (Map<String, Object>)prMatResMap.get('drivers-licence');
            Map<String, Object> lodgeResMap = (Map<String, Object>)prMatResMap.get('lodged-complaint');
            if(indNameResMap != null){
                Map<String, Object> famNameResMap = (Map<String, Object>)indNameResMap.get('family-name');
                Map<String, Object> firstNameResMap = (Map<String, Object>)indNameResMap.get('first-given-name');
                Map<String, Object> otherNameResMap = (Map<String, Object>)indNameResMap.get('other-given-name');
                if(firstNameResMap != null && firstNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaObj.firstGivenName = String.valueOf(firstNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(indNameResMap != null && indNameResMap.containsKey('first-reported-date')){
                    vedaObj.individualNameFirstReportedDate = String.valueOf(indNameResMap.get('first-reported-date'));
                }
                if(famNameResMap != null && famNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaObj.familyName = String.valueOf(famNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(indNameResMap != null && indNameResMap.containsKey('last-reported-date')){
                    vedaObj.individualNameLastReportedDate = String.valueOf(indNameResMap.get('last-reported-date'));
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
            if(dobResMap != null && dobResMap.containsKey('first-reported-date')){
                vedaObj.dateOfBirthFirstReportedDate = String.valueOf(dobResMap.get('first-reported-date'));
            }
            if(dobResMap != null && dobResMap.containsKey('last-reported-date')){
                vedaObj.dateOfBirthLastReportedDate = String.valueOf(dobResMap.get('last-reported-date'));
            }
            if(driLicResMap != null && driLicResMap.containsKey('first-reported-date')){
                vedaObj.driversLicenceFirstReportedDate = String.valueOf(driLicResMap.get('first-reported-date'));
            }
            if(driLicResMap != null && driLicResMap.containsKey('last-reported-date')){
                vedaObj.driversLicenceLastReportedDate = String.valueOf(driLicResMap.get('last-reported-date'));
            }
            if(driLicResMap != null && driLicResMap.containsKey('number')){
                Map<String, Object> driLicNameMap = (Map<String, Object>)driLicResMap.get('number');
                if(driLicNameMap != null && driLicNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaObj.driversLicenceNumber = String.valueOf(driLicNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
            }
            if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaObj.gender = String.valueOf(genResMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(genResMap != null && genResMap.containsKey('code')){
                vedaObj.genderCode = String.valueOf(genResMap.get('code'));
            }
            if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaObj.isDeceased = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(isDecResMap != null && isDecResMap.containsKey('reported-date')){
                vedaObj.isDeceasedReportedDate = String.valueOf(isDecResMap.get('reported-date'));
            }
            if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaObj.lodgedComplaint = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                vedaObj.lodgedComplaintReportedDate = String.valueOf(lodgeResMap.get('reported-date'));
            }
            if(prMatResMap != null && prMatResMap.containsKey('id-index')){
                vedaObj.primaryMatchIdIndex = String.valueOf(prMatResMap.get('id-index'));
            }
            if(prMatResMap != null && prMatResMap.containsKey('type')){
                vedaObj.primaryMatchType = String.valueOf(prMatResMap.get('type'));
            }
        }
        return vedaObj;
    }

    public static Boolean isCollection(Object input){
        Object test;
        try{
            test = (List<Object>)input;
            return true;
        }
       //catch(Exception ex){}
        catch(System.TypeException ex){}
        return false;
    }

    public static List<Map<String,Object>> getListOfMaps(Map<String,Object> inputMap, string mapKey){
        List<Map<String,Object>> mapList = new List<Map<String,Object>>();
        if(inputMap !=  null && inputMap.containsKey(mapKey) && inputMap.get(mapKey) != null){
            if(isCollection(inputMap.get(mapKey))){
                for(Object scoreObj : (List<Object>)inputMap.get(mapKey)){
                    mapList.add((Map<String, Object>)scoreObj);
                }
            }else{
                mapList.add((Map<String, Object>)inputMap.get(mapKey));
            }
        }else{
            return null;
        }
        return mapList;
    }

    public static List<String> getIdReferences(Map<String,Object> idRefMap){
        List<String> idRefList = new List<String>(); 
        if(idRefMap != null && idRefMap.containsKey('id-reference')){
            List<Map<String, Object>> idRefResMapList = getListOfMaps(idRefMap,'id-reference');
            if(idRefResMapList != null && idRefResMapList.size()>0){
                for(Map<String, Object> idRefResMap : idRefResMapList){
                    if(idRefResMap != null && idRefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        idRefList.add(String.valueOf(idRefResMap.get(EquifaxIntegrationConstants.NODEVALUE)));
                    }
                }
            }    
        }
        return idRefList;
    }

}