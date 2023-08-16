/*********************************************************************************************************
Class            : EquifaxVedaResponseParser
Description      : Manager Class for Equifax Hardpull Integration to create veda Comprehensive response
Created Date     : 26/07/2023
Developer        : Supriyo Seni
Last Modified By : Supriyo Seni
**********************************************************************************************************/

global with sharing class EquifaxVedaResponseParser{

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
     * @params       : Map of String and Object AND veda instance
     * @returnType   : ints.VedaComprehensiveResponse
    ******************************************************************************/ 
    public static ints.VedaComprehensiveResponse getVedaEnquiryReport(Map<String,Object> pdtDataResMap,ints.VedaComprehensiveResponse veda){
        Map<String, Object> enRepResMap = (Map<String, Object>)pdtDataResMap.get(EquifaxIntegrationConstants.ENQ_REPORT);
        if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.PRIMARY_MATCH)){
            veda = getPrimaryMatchDetails(enRepResMap,veda);
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
     * @Description  : This method returns the list of veda erros from the response error map
     * @params       : Map of String and Object
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

    /**************************************************************************
     * @Description  : This method returns the list of veda personalInsolvencies from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.personalInsolvency
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.personalInsolvency> getVedaPerosnalInsolvencies(Map<String,Object> pubRecConCreMap){
        List<ints.VedaComprehensiveResponse.personalInsolvency> vedaPerInsList = new List<ints.VedaComprehensiveResponse.personalInsolvency>();
        List<Map<String, Object>> perInsMapList = new List<Map<String, Object>>(); 
        Map<String, Object> insolMap = (Map<String, Object>)pubRecConCreMap.get(EquifaxIntegrationConstants.PERSONAL_INSOVENCIES);
        if(insolMap != null && insolMap.containsKey(EquifaxIntegrationConstants.PERSONAL_INSOVENCY)){
            perInsMapList = getListOfMaps(insolMap,EquifaxIntegrationConstants.PERSONAL_INSOVENCY);
            if(perInsMapList != null && perInsMapList.size()>0){
                for(Map<String, Object> perInsMap : perInsMapList){
                    ints.VedaComprehensiveResponse.personalInsolvency vedaPerIns = new ints.VedaComprehensiveResponse.personalInsolvency();
                    Map<String, Object> typeMap = (Map<String, Object>)perInsMap.get(EquifaxIntegrationConstants.TYPE);
                    Map<String, Object> dateDecMap = (Map<String, Object>)perInsMap.get(EquifaxIntegrationConstants.DATE_DECLARED);
                    Map<String, Object> textMap = (Map<String, Object>)perInsMap.get(EquifaxIntegrationConstants.TEXT);
                    Map<String, Object> relationshipMap = (Map<String, Object>)perInsMap.get(EquifaxIntegrationConstants.RELATIONSHIP);
                    Map<String, Object> coBorrowerMap = (Map<String, Object>)perInsMap.get(EquifaxIntegrationConstants.COBORROWER);
                    Map<String, Object> admIdMap = (Map<String, Object>)perInsMap.get(EquifaxIntegrationConstants.ADMIN_ID);
                    Map<String, Object> idRefMap = (Map<String, Object>)perInsMap.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        vedaPerIns.idReferences = getIdReferences(idRefMap);
                    }
                    if(typeMap != null && typeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaPerIns.type = String.valueOf(typeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(typeMap != null && typeMap.containsKey(EquifaxIntegrationConstants.CODE)){
                        vedaPerIns.typeCode = String.valueOf(typeMap.get(EquifaxIntegrationConstants.CODE));
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
                    if(relationshipMap != null && relationshipMap.containsKey(EquifaxIntegrationConstants.CODE)){
                        vedaPerIns.relationshipCode = String.valueOf(relationshipMap.get(EquifaxIntegrationConstants.CODE));
                    }
                    if(coBorrowerMap != null && coBorrowerMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaPerIns.coBorrower = String.valueOf(coBorrowerMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(admIdMap != null){
                        Map<String, Object> distMap = (Map<String, Object>)admIdMap.get(EquifaxIntegrationConstants.DISTRICT);
                        Map<String, Object> yearMap = (Map<String, Object>)admIdMap.get(EquifaxIntegrationConstants.YEAR);
                        Map<String, Object> numberMap = (Map<String, Object>)admIdMap.get(EquifaxIntegrationConstants.NUMBER_STR);
                        Map<String, Object> proceStatusMap = (Map<String, Object>)admIdMap.get(EquifaxIntegrationConstants.PROCEEDINGS_STATUS);
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

    /**************************************************************************
     * @Description  : This method returns the list of veda businessNames from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.businessName
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.businessName> getVedaBusinessNames(Map<String,Object> pubRecConCreMap){
        List<ints.VedaComprehensiveResponse.businessName> vedaBusNameList = new List<ints.VedaComprehensiveResponse.businessName>();
        List<Map<String, Object>> busNamesList = new List<Map<String, Object>>(); 
        Map<String, Object> busNamesMap = (Map<String, Object>)pubRecConCreMap.get(EquifaxIntegrationConstants.BUSS_NAMES);
        if(busNamesMap != null && busNamesMap.containsKey(EquifaxIntegrationConstants.BUSS_NAME)){
            busNamesList = getListOfMaps(busNamesMap,EquifaxIntegrationConstants.BUSS_NAME);
            if(busNamesList != null && busNamesList.size()>0){
                for(Map<String, Object> busNameMap : busNamesList){
                    ints.VedaComprehensiveResponse.businessName vedaBusName = new ints.VedaComprehensiveResponse.businessName();
                    Map<String, Object> idRefMap = (Map<String, Object>)busNameMap.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        vedaBusName.idReferences = getIdReferences(idRefMap);
                    }
                    Map<String, Object> busStartDateMap = (Map<String, Object>)busNameMap.get(EquifaxIntegrationConstants.START_DATE);
                    if(busStartDateMap != null && busStartDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaBusName.startDate = String.valueOf(busStartDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(busNameMap != null && busNameMap.containsKey(EquifaxIntegrationConstants.LAST_EXTRACT_DATE)){
                        vedaBusName.lastExtractDate = String.valueOf(busNameMap.get(EquifaxIntegrationConstants.LAST_EXTRACT_DATE));
                    }
                    if(busNameMap != null && busNameMap.containsKey(EquifaxIntegrationConstants.LAST_EXTRACT_TIME)){
                        vedaBusName.lastExtractTime = String.valueOf(busNameMap.get(EquifaxIntegrationConstants.LAST_EXTRACT_TIME));
                    }
                    if(busNameMap != null && busNameMap.containsKey(EquifaxIntegrationConstants.LAST_UPDATE_DATE)){
                        vedaBusName.lastUpdateDate = String.valueOf(busNameMap.get(EquifaxIntegrationConstants.LAST_UPDATE_DATE));
                    }
                    if(busNameMap != null && busNameMap.containsKey(EquifaxIntegrationConstants.LAST_UPDATE_TIME)){
                        vedaBusName.lastUpdateTime = String.valueOf(busNameMap.get(EquifaxIntegrationConstants.LAST_UPDATE_TIME));
                    }
                    Map<String, Object> bussMap = (Map<String, Object>)busNameMap.get(EquifaxIntegrationConstants.BUSINESS);
                    if(bussMap != null){
                        Map<String, Object> bussBrMap = (Map<String, Object>)bussMap.get(EquifaxIntegrationConstants.BUREAU_REFERENCE);
                        Map<String, Object> bussNameMap = (Map<String, Object>)bussMap.get(EquifaxIntegrationConstants.NAME);
                        Map<String, Object> bussAbnMap = (Map<String, Object>)bussMap.get(EquifaxIntegrationConstants.ABN);
                        Map<String, Object> bussPredTerMap = (Map<String, Object>)bussMap.get(EquifaxIntegrationConstants.PREV_STATE_OR_TERRITORY_REGISTRATION);
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
                            Map<String, Object> bussStateMap = (Map<String, Object>)bussPredTerMap.get(EquifaxIntegrationConstants.STATE);
                            Map<String, Object> bussNumberMap = (Map<String, Object>)bussPredTerMap.get(EquifaxIntegrationConstants.NUMBER_STR);
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

    /**************************************************************************
     * @Description  : This method returns the list of veda Directorships from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Directorship
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.Directorship> getVedaDirectorships(Map<String,Object> pubRecConCreMap){
        List<ints.VedaComprehensiveResponse.Directorship> vedaDirectorshipList = new List<ints.VedaComprehensiveResponse.Directorship>();
        List<Map<String, Object>> DirecList = new List<Map<String, Object>>(); 
        Map<String, Object> directMap = (Map<String, Object>)pubRecConCreMap.get(EquifaxIntegrationConstants.DIRECTORSHIPS);
        if(directMap != null && directMap.containsKey(EquifaxIntegrationConstants.DIRECTORSHIP)){
            DirecList = getListOfMaps(directMap,EquifaxIntegrationConstants.DIRECTORSHIP);
            if(DirecList != null && DirecList.size()>0){
                for(Map<String, Object> direct : DirecList){
                    ints.VedaComprehensiveResponse.Directorship vedaDirectorship= new ints.VedaComprehensiveResponse.Directorship();
                    Map<String, Object> idRefMap = (Map<String, Object>)direct.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        vedaDirectorship.idReferences = getIdReferences(idRefMap);
                    }
                    Map<String, Object> dirDateAppMap = (Map<String, Object>)direct.get(EquifaxIntegrationConstants.DATE_APPOINTED);
                    if(dirDateAppMap != null && dirDateAppMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaDirectorship.dateAppointed = String.valueOf(dirDateAppMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> dirDateCeaMap = (Map<String, Object>)direct.get(EquifaxIntegrationConstants.DATE_CEASED);
                    if(dirDateCeaMap != null && dirDateCeaMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaDirectorship.dateCeased = String.valueOf(dirDateCeaMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> dirDatelasDMap = (Map<String, Object>)direct.get(EquifaxIntegrationConstants.DATE_LAST_KNOWN_AS_DIRECTOR);
                    if(dirDatelasDMap != null && dirDatelasDMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaDirectorship.dateLastKnownAsDirector = String.valueOf(dirDatelasDMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(direct != null && direct.containsKey(EquifaxIntegrationConstants.LAST_EXTRACT_DATE)){
                        vedaDirectorship.lastExtractDate = String.valueOf(direct.get(EquifaxIntegrationConstants.LAST_EXTRACT_DATE));
                    }
                    if(direct != null && direct.containsKey(EquifaxIntegrationConstants.LAST_EXTRACT_TIME)){
                        vedaDirectorship.lastExtractTime = String.valueOf(direct.get(EquifaxIntegrationConstants.LAST_EXTRACT_TIME));
                    }
                    if(direct != null && direct.containsKey(EquifaxIntegrationConstants.LAST_UPDATE_DATE)){
                        vedaDirectorship.lastUpdateDate = String.valueOf(direct.get(EquifaxIntegrationConstants.LAST_UPDATE_DATE));
                    }
                    if(direct != null && direct.containsKey(EquifaxIntegrationConstants.LAST_UPDATE_TIME)){
                        vedaDirectorship.lastUpdateTime = String.valueOf(direct.get(EquifaxIntegrationConstants.LAST_UPDATE_TIME));
                    }
                    if(direct != null && direct.containsKey(EquifaxIntegrationConstants.TYPE)){
                        vedaDirectorship.type = String.valueOf(direct.get(EquifaxIntegrationConstants.TYPE));
                    }

                    Map<String, Object> dirOrgMap = (Map<String, Object>)direct.get(EquifaxIntegrationConstants.ORGANISATION);
                    if(dirOrgMap != null){
                        Map<String, Object> dirOrgBrMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.BUREAU_REFERENCE);
                        Map<String, Object> dirOrgNameMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.NAME);
                        Map<String, Object> orgStartDateMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.NAME_START_DATE);
                        Map<String, Object> dirOrgTypeMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.TYPE);
                        Map<String, Object> dirOrgStatusMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.STATUS);
                        Map<String, Object> dirOrgNumberMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.ORG_NUMBER);
                        Map<String, Object> dirOrgAbnMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.ABN);
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
                        if(dirOrgStatusMap != null && dirOrgStatusMap.containsKey(EquifaxIntegrationConstants.CODE)){
                            vedaDirectorship.organisationStatusCode = String.valueOf(dirOrgStatusMap.get(EquifaxIntegrationConstants.CODE));
                        }
                        if(dirOrgTypeMap != null && dirOrgTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDirectorship.organisationType = String.valueOf(dirOrgTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dirOrgTypeMap != null && dirOrgTypeMap.containsKey(EquifaxIntegrationConstants.CODE)){
                            vedaDirectorship.organisationTypeCode = String.valueOf(dirOrgTypeMap.get(EquifaxIntegrationConstants.CODE));
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

    /**************************************************************************
     * @Description  : This method returns the list of veda FileNotes from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Directorship
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.FileNote> getVedaFileNotes(Map<String,Object> comCreFileMap){
        List<ints.VedaComprehensiveResponse.FileNote> vedaFileNoteList = new List<ints.VedaComprehensiveResponse.FileNote>();
        List<Map<String, Object>> fileNoteMapList = new List<Map<String, Object>>(); 
        Map<String, Object> fileNoteMap = (Map<String, Object>)comCreFileMap.get(EquifaxIntegrationConstants.FILE_NOTES);
        if(fileNoteMap != null && fileNoteMap.containsKey(EquifaxIntegrationConstants.FILE_NOTE)){
            fileNoteMapList = getListOfMaps(fileNoteMap,EquifaxIntegrationConstants.FILE_NOTE);
            if(fileNoteMapList != null && fileNoteMapList.size()>0){
                for(Map<String, Object> fnMap : fileNoteMapList){
                    ints.VedaComprehensiveResponse.FileNote vedaFileNote= new ints.VedaComprehensiveResponse.FileNote();
                    Map<String, Object> idRefMap = (Map<String, Object>)fnMap.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        vedaFileNote.idReferences = getIdReferences(idRefMap);
                    }
                    if(fnMap != null && fnMap.containsKey(EquifaxIntegrationConstants.DATE_RECORDED)){
                        vedaFileNote.dateRecorded = String.valueOf(fnMap.get(EquifaxIntegrationConstants.DATE_RECORDED));
                    }
                    Map<String, Object> fnNoteMap = (Map<String, Object>)fnMap.get(EquifaxIntegrationConstants.NOTE);
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
     * @Description  : This method returns the list of veda possibleMatchs from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.possibleMatch
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.possibleMatch> getVedaPossibleMatches(Map<String,Object> pdtDataResMap){
        List<ints.VedaComprehensiveResponse.possibleMatch> vedaPossMatList = new List<ints.VedaComprehensiveResponse.possibleMatch>();
        List<Map<String, Object>> possMatMapList = new List<Map<String, Object>>(); 
        Map<String, Object> possMatMap = (Map<String, Object>)pdtDataResMap.get(EquifaxIntegrationConstants.POSSIBLE_MATCHES);
        if(possMatMap != null && possMatMap.containsKey(EquifaxIntegrationConstants.POSSIBLE_MATCH)){
            possMatMapList = getListOfMaps(possMatMap,EquifaxIntegrationConstants.POSSIBLE_MATCH);
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
                        if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaPossMat.identity.lodgedComplaintReportedDate = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
                        }
                        if(prMatResMap != null && prMatResMap.containsKey(EquifaxIntegrationConstants.ID_INDEX)){
                            vedaPossMat.identity.idIndex = String.valueOf(prMatResMap.get(EquifaxIntegrationConstants.ID_INDEX));
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
            dataBlockMapList = getListOfMaps(dataBlockMap,EquifaxIntegrationConstants.DATA_BLOCK);
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
        dBcharMapList = getListOfMaps(dBMap,EquifaxIntegrationConstants.CHARACTERISTIC);
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
     * @Description  : This method returns the list of veda scores from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Score
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.Score> getVedaScoreData(Map<String,Object> resScoreMap){
        List<ints.VedaComprehensiveResponse.Score> vedaScoreList = new List<ints.VedaComprehensiveResponse.Score>(); 
        Map<String, Object> scoreMap = (Map<String, Object>)resScoreMap.get(EquifaxIntegrationConstants.SCORE_DATA);
        if(scoreMap != null && scoreMap.containsKey(EquifaxIntegrationConstants.SCORE)){
            List<Map<String, Object>> scoreResMapList = getListOfMaps(scoreMap,EquifaxIntegrationConstants.SCORE);
            if(scoreResMapList != null && scoreResMapList.size()>0){
                for(Map<String, Object> scoreResMap : scoreResMapList){
                    ints.VedaComprehensiveResponse.Score vedaScoreRes = new ints.VedaComprehensiveResponse.Score();
                    Map<String, Object> scoreCardMap = (Map<String, Object>)scoreResMap.get(EquifaxIntegrationConstants.SCORECARD);
                    if(scoreCardMap != null){
                        Map<String, Object> scoreCardName = (Map<String, Object>)scoreCardMap.get(EquifaxIntegrationConstants.NAME);
                        Map<String, Object> scoreCardVersion = (Map<String, Object>)scoreCardMap.get(EquifaxIntegrationConstants.VERSION);
                        Map<String, Object> scoreCardType = (Map<String, Object>)scoreCardMap.get(EquifaxIntegrationConstants.TYPE);
                        Map<String, Object> scoreCardDateLevel = (Map<String, Object>)scoreCardMap.get(EquifaxIntegrationConstants.DATA_LEVEL);
                        if(scoreCardDateLevel != null && scoreCardDateLevel.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaScoreRes.scoreDataLevel = String.valueOf(scoreCardDateLevel.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(scoreCardDateLevel != null && scoreCardDateLevel.containsKey(EquifaxIntegrationConstants.CODE)){
                            vedaScoreRes.scoreDataLevelCode = String.valueOf(scoreCardDateLevel.get(EquifaxIntegrationConstants.CODE));
                        }
                        if(scoreCardMap.containsKey(EquifaxIntegrationConstants.ID)){
                            vedaScoreRes.scoreId = String.valueOf(scoreCardMap.get(EquifaxIntegrationConstants.ID));
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
                    Map<String, Object> riskOddsMap = (Map<String, Object>)scoreResMap.get(EquifaxIntegrationConstants.RISK_ODDS);
                    if(riskOddsMap != null && riskOddsMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaScoreRes.riskOdds = String.valueOf(riskOddsMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> scoreMasScaleMap = (Map<String, Object>)scoreResMap.get(EquifaxIntegrationConstants.SCORE_MASTERSCALE);
                    if(scoreMasScaleMap != null && scoreMasScaleMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaScoreRes.scoreMasterscale = String.valueOf(scoreMasScaleMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> conFactorsMap = (Map<String, Object>)scoreResMap.get(EquifaxIntegrationConstants.KEY_CONTRIBUTING_FACTORS);
                    vedaScoreRes.contributingFactor = getScoreConFactors(conFactorsMap);
                    if(vedaScoreRes != null){
                        vedaScoreList.add(vedaScoreRes);
                    }
                }
            }
        }
        return vedaScoreList;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda score contributing factors from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.ContributingFactor
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.ContributingFactor> getScoreConFactors(Map<String,Object> conFactorsMap){
        List<ints.VedaComprehensiveResponse.ContributingFactor> vedaConFacList = new List<ints.VedaComprehensiveResponse.ContributingFactor>(); 
        if(conFactorsMap != null && conFactorsMap.containsKey(EquifaxIntegrationConstants.CONTRIBUTING_FACTOR)){
            List<Map<String, Object>> vedaMapList = getListOfMaps(conFactorsMap,EquifaxIntegrationConstants.CONTRIBUTING_FACTOR);
            if(vedaMapList != null && vedaMapList.size()>0){
                for(Map<String, Object> conFacMap : vedaMapList){
                    ints.VedaComprehensiveResponse.ContributingFactor vedaConFac = new ints.VedaComprehensiveResponse.ContributingFactor();
                    Map<String, Object> conFacNameMap = (Map<String, Object>)conFacMap.get(EquifaxIntegrationConstants.NAME);
                    Map<String, Object> conFacDesMap = (Map<String, Object>)conFacMap.get(EquifaxIntegrationConstants.DESCRIPTION);
                    Map<String, Object> conFaScoImpMap = (Map<String, Object>)conFacMap.get(EquifaxIntegrationConstants.SCORE_IMPACTOR);
                    if(conFacNameMap != null && conFacNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaConFac.name = String.valueOf(conFacNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(conFacDesMap != null && conFacDesMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaConFac.description = String.valueOf(conFacDesMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(conFaScoImpMap != null && conFaScoImpMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaConFac.scoreImpactor = String.valueOf(conFaScoImpMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(conFacMap != null && conFacMap.containsKey(EquifaxIntegrationConstants.ID)){
                        vedaConFac.contributingFactorId = String.valueOf(conFacMap.get(EquifaxIntegrationConstants.ID));
                    }
                    if(conFacMap != null){
                        vedaConFacList.add(vedaConFac);
                    }
                }
            }
        }
        return vedaConFacList;
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
            List<Map<String, Object>> vedaMapList = getListOfMaps(othIdenMap,EquifaxIntegrationConstants.OTHER_IDENTITY);
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
                if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaResOtherIden.lodgedComplaintReportedDate = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
                }
                if(vedaResOtherIden != null){
                    vedaOthIdenList.add(vedaResOtherIden);
                }
            }    
        }
        return vedaOthIdenList;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda addresses from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Address
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.Address> getVedaAddresses(Map<String,Object> resAddMap){
        List<ints.VedaComprehensiveResponse.Address> vedaAddList = new List<ints.VedaComprehensiveResponse.Address>(); 
        Map<String, Object> addMap = (Map<String, Object>)resAddMap.get(EquifaxIntegrationConstants.ADDRESSES);
        if(addMap != null && addMap.containsKey(EquifaxIntegrationConstants.ADDRESS)){
            List<Map<String, Object>> addResMapList = getListOfMaps(addMap,EquifaxIntegrationConstants.ADDRESS); 
            if(addResMapList != null){
                for(Map<String, Object> addResMap : addResMapList){
                    ints.VedaComprehensiveResponse.Address vedaAddRes = new ints.VedaComprehensiveResponse.Address();
                    Map<String, Object> unitNumMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.UNIT_NUMBER_STR);
                    Map<String, Object> stNumMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.STREET_NUMBER_STR);
                    Map<String, Object> stNameMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.STREET_NAME_STR);
                    Map<String, Object> stTypeMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.STREET_TYPE_STR);
                    Map<String, Object> subMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.SUBURB_STR);
                    Map<String, Object> stateMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.STATE);
                    Map<String, Object> postCodeMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.POSTCODE_STR);
                    Map<String, Object> conCodeMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.COUNTRY_CODE_STR);
                    Map<String, Object> propertyMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.PROPERTY_STR);
                    Map<String, Object> idRefMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        vedaAddRes.idReference = getIdReferences(idRefMap);  
                    }
                    if(conCodeMap != null && conCodeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAddRes.countryCode = String.valueOf(conCodeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(addResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                        vedaAddRes.firstReportedDate = String.valueOf(addResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                    }
                    if(addResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                        vedaAddRes.lastReportedDate = String.valueOf(addResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
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
                    if(addResMap != null && addResMap.containsKey(EquifaxIntegrationConstants.TYPE)){
                        vedaAddRes.type = String.valueOf(addResMap.get(EquifaxIntegrationConstants.TYPE));
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

    /**************************************************************************
     * @Description  : This method returns the list of veda employments from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Employer
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.Employer> getVedaEmployments(Map<String,Object> resEmpMap){
        List<ints.VedaComprehensiveResponse.Employer> vedaEmpList = new List<ints.VedaComprehensiveResponse.Employer>(); 
        Map<String, Object> empMap = (Map<String, Object>)resEmpMap.get(EquifaxIntegrationConstants.EMPLOYMENT);
        if(empMap != null && empMap.containsKey(EquifaxIntegrationConstants.EMPLOYER)){
            List<Map<String, Object>> empMapList = getListOfMaps(empMap,EquifaxIntegrationConstants.EMPLOYER); 
            if(empMapList != null){
                for(Map<String, Object> empResMap : empMapList){
                    ints.VedaComprehensiveResponse.Employer vedaEmpRes = new ints.VedaComprehensiveResponse.Employer();
                    if(empResMap != null && empResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                        vedaEmpRes.firstReportedDate = String.valueOf(empResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                    }
                    if(empResMap != null && empResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                        vedaEmpRes.lastReportedDate = String.valueOf(empResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                    }
                    if(empResMap != null && empResMap.containsKey(EquifaxIntegrationConstants.TYPE)){
                        vedaEmpRes.type = String.valueOf(empResMap.get(EquifaxIntegrationConstants.TYPE));
                    }
                    Map<String, Object> empNameMap = (Map<String, Object>)empResMap.get(EquifaxIntegrationConstants.NAME);
                    if(empNameMap != null && empNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaEmpRes.name = String.valueOf(empNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> empOccMap = (Map<String, Object>)empResMap.get(EquifaxIntegrationConstants.OCCUPATION);
                    if(empOccMap != null && empOccMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaEmpRes.occupation = String.valueOf(empOccMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> idRefMap = (Map<String, Object>)empResMap.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
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

    /**************************************************************************
     * @Description  : This method returns the list of veda consumer credit enquiries from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.CreditEnquiry
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.CreditEnquiry> getVedaConsumerCreditEnquiries(Map<String, Object> conCreFileMap){
        List<ints.VedaComprehensiveResponse.CreditEnquiry> vedaCredEnqList = new List<ints.VedaComprehensiveResponse.CreditEnquiry>();
        Map<String, Object> creEnqMap = (Map<String, Object>)conCreFileMap.get(EquifaxIntegrationConstants.CREDIT_ENQS);
        if(creEnqMap != null && creEnqMap.containsKey(EquifaxIntegrationConstants.CREDIT_ENQUIRY)){
            List<Map<String, Object>> creEnqMapList = getListOfMaps(creEnqMap,EquifaxIntegrationConstants.CREDIT_ENQUIRY); 
            if(creEnqMapList != null){
                for(Map<String, Object> creEnq : creEnqMapList){
                    ints.VedaComprehensiveResponse.CreditEnquiry vedaCredEnq = new ints.VedaComprehensiveResponse.CreditEnquiry();
                    Map<String, Object> accTypeMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ACCOUNT_TYPE);
                    Map<String, Object> enqAmtMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ENQUIRY_AMOUNT_STR);
                    Map<String, Object> relMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.RELATIONSHIP);
                    Map<String, Object> creEnqrMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.CREDIT_ENQUIRED);
                    Map<String, Object> creCliRefMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ENQUIRY_CILENT_REFERENCE);
                    Map<String, Object> idRefMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    Map<String, Object> coBorrowerMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.COBORROWER);
                    if(creEnqrMap != null && creEnqrMap.containsKey(EquifaxIntegrationConstants.NAME)){
                        Map<String, Object> creEnqrNameMap = (Map<String, Object>)creEnqrMap.get(EquifaxIntegrationConstants.NAME);
                        if(creEnqrNameMap != null && creEnqrNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaCredEnq.creditEnquirerName = String.valueOf(creEnqrNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                    }
                    if(creEnqrMap != null && creEnqrMap.containsKey(EquifaxIntegrationConstants.CLASSIFICATION)){
                        Map<String, Object> creEnqrClasMap = (Map<String, Object>)creEnqrMap.get(EquifaxIntegrationConstants.CLASSIFICATION);
                        if(creEnqrClasMap != null && creEnqrClasMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaCredEnq.creditEnquirerClassification = String.valueOf(creEnqrClasMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                    }
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        vedaCredEnq.idReferences = getIdReferences(idRefMap);   
                    }
                    if(coBorrowerMap != null && coBorrowerMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaCredEnq.coBorrower = String.valueOf(coBorrowerMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaCredEnq.accountType = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.CODE)){
                        vedaCredEnq.accountTypeCode = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.CODE));
                    }
                    if(enqAmtMap != null && enqAmtMap.containsKey(EquifaxIntegrationConstants.CURRENCY_CODE)){
                        vedaCredEnq.enquiryAmountCurrencyCode = String.valueOf(enqAmtMap.get(EquifaxIntegrationConstants.CURRENCY_CODE));
                    }
                    if(enqAmtMap != null && enqAmtMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaCredEnq.enquiryAmount = String.valueOf(enqAmtMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(creEnq != null && creEnq.containsKey(EquifaxIntegrationConstants.ENQUIRY_DATE)){
                        vedaCredEnq.enquiryDate = String.valueOf(creEnq.get(EquifaxIntegrationConstants.ENQUIRY_DATE));
                    }
                    if(creEnq != null && creEnq.containsKey(EquifaxIntegrationConstants.TYPE)){
                        vedaCredEnq.type = String.valueOf(creEnq.get(EquifaxIntegrationConstants.TYPE));
                    }
                    if(vedaCredEnq != null){
                        vedaCredEnqList.add(vedaCredEnq);
                    }
                }
            }
        }
        return vedaCredEnqList;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda commercial credit enquiries from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.CreditEnquiry
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.CreditEnquiry> getVedaCommercialCreditEnquiries(Map<String, Object> comCreFileMap){
        List<ints.VedaComprehensiveResponse.CreditEnquiry> vedaCredEnqList = new List<ints.VedaComprehensiveResponse.CreditEnquiry>();
        Map<String, Object> creEnqMap = (Map<String, Object>)comCreFileMap.get(EquifaxIntegrationConstants.CREDIT_ENQS);
        if(creEnqMap != null && creEnqMap.containsKey(EquifaxIntegrationConstants.CREDIT_ENQUIRY)){
            List<Map<String, Object>> creEnqMapList = getListOfMaps(creEnqMap,EquifaxIntegrationConstants.CREDIT_ENQUIRY);
            if(creEnqMapList != null){
                for(Map<String, Object> creEnq : creEnqMapList){
                    ints.VedaComprehensiveResponse.CreditEnquiry vedaComCredEnq= new ints.VedaComprehensiveResponse.CreditEnquiry();
                    Map<String, Object> accTypeMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ACCOUNT_TYPE);
                    Map<String, Object> enqAmtMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ENQUIRY_AMOUNT_STR);
                    Map<String, Object> relMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.RELATIONSHIP);
                    Map<String, Object> creEnqrMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.CREDIT_ENQUIRED);
                    Map<String, Object> creCliRefMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ENQUIRY_CILENT_REFERENCE);
                    Map<String, Object> idRefMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    Map<String, Object> coBorrowerMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.COBORROWER);
                    if(creEnqrMap != null && creEnqrMap.containsKey(EquifaxIntegrationConstants.NAME)){
                        Map<String, Object> creEnqrNameMap = (Map<String, Object>)creEnqrMap.get(EquifaxIntegrationConstants.NAME);
                        if(creEnqrNameMap != null && creEnqrNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaComCredEnq.creditEnquirerName = String.valueOf(creEnqrNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                    }
                    if(creEnqrMap != null && creEnqrMap.containsKey(EquifaxIntegrationConstants.CLASSIFICATION)){
                        Map<String, Object> creEnqrClasMap = (Map<String, Object>)creEnqrMap.get(EquifaxIntegrationConstants.CLASSIFICATION);
                        if(creEnqrClasMap != null && creEnqrClasMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaComCredEnq.creditEnquirerClassification = String.valueOf(creEnqrClasMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                    }
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        vedaComCredEnq.idReferences = getIdReferences(idRefMap);
                    }
                    if(coBorrowerMap != null && coBorrowerMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaComCredEnq.coBorrower = String.valueOf(coBorrowerMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaComCredEnq.accountType = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.CODE)){
                        vedaComCredEnq.accountTypeCode = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.CODE));
                    }
                    if(enqAmtMap != null && enqAmtMap.containsKey(EquifaxIntegrationConstants.CURRENCY_CODE)){
                        vedaComCredEnq.enquiryAmountCurrencyCode = String.valueOf(enqAmtMap.get(EquifaxIntegrationConstants.CURRENCY_CODE));
                    }
                    if(enqAmtMap != null && enqAmtMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaComCredEnq.enquiryAmount = String.valueOf(enqAmtMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(creEnq != null && creEnq.containsKey(EquifaxIntegrationConstants.ENQUIRY_DATE)){
                        vedaComCredEnq.enquiryDate = String.valueOf(creEnq.get(EquifaxIntegrationConstants.ENQUIRY_DATE));
                    }
                    if(creEnq != null && creEnq.containsKey(EquifaxIntegrationConstants.TYPE)){
                        vedaComCredEnq.type = String.valueOf(creEnq.get(EquifaxIntegrationConstants.TYPE));
                    }
                    if(vedaComCredEnq != null){
                        vedaCredEnqList.add(vedaComCredEnq);
                    }
                }
            }
        }
        return vedaCredEnqList;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda Accounts from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.account
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.account> getVedaAccounts(Map<String, Object> conCreFileMap){
        List<ints.VedaComprehensiveResponse.account> vedaAccList = new List<ints.VedaComprehensiveResponse.account>();
        Map<String, Object> accountsMap = (Map<String, Object>)conCreFileMap.get(EquifaxIntegrationConstants.ACCOUNTS);
        if(accountsMap != null && accountsMap.containsKey(EquifaxIntegrationConstants.ACCOUNT)){
            List<Map<String, Object>> accMapList = getListOfMaps(accountsMap,EquifaxIntegrationConstants.ACCOUNT);
            if(accMapList != null){
                for(Map<String, Object> accMap : accMapList){
                    ints.VedaComprehensiveResponse.account vedaAcc = new ints.VedaComprehensiveResponse.account();
                    Map<String, Object> accTypeMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ACCOUNT_TYPE);
                    Map<String, Object> accIdMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ACCOUNT_ID);
                    Map<String, Object> oriCredProMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ORIGINAL_CREDIT_PROVIDER);
                    Map<String, Object> relMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.RELATIONSHIP);
                    Map<String, Object> accHolderCntMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ACCOUNT_HOLDER_COUNT);
                    Map<String, Object> accOpenDateMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ACCOUNT_OPEN_DATE);
                    Map<String, Object> accReOpenDateMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ACCOUNT_RE_OPEN_DATE);
                    Map<String, Object> loanPayMetMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.LOAN_PAYMENT_METHOD);
                    Map<String, Object> termTypeMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.TERM_TYPE);
                    Map<String, Object> secCreditMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.SECURED_CREDIT);
                    Map<String, Object> termOfLoanMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.TERM_OF_LOAN);
                    Map<String, Object> latMaxAmtCreMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.LATEST_MAX_AMT_CREDIT);
                    Map<String, Object> isUnlimCreditMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.IS_UNLIMITED_CREDIT);
                    Map<String, Object> accClosedDateMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ACCOUNT_CLOSED_DATE);
                    Map<String, Object> dateLatChangedMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.DATE_LAST_CHANGED);
                    Map<String, Object> oriMaxAmtCreditMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ORIGINAL_MAXIMUM_AMT_CREDIT);
                    Map<String, Object> assInfoMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ASSOCIATION_INFO);
                    Map<String, Object> idRefMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        vedaAcc.idReferences = getIdReferences(idRefMap);  
                    }
                    if(oriCredProMap != null && oriCredProMap.containsKey(EquifaxIntegrationConstants.NAME)){
                        Map<String, Object> oriCredProNameMap = (Map<String, Object>)oriCredProMap.get(EquifaxIntegrationConstants.NAME);
                        vedaAcc.originalCreditProviderName = String.valueOf(oriCredProNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(oriCredProMap != null && oriCredProMap.containsKey(EquifaxIntegrationConstants.CLASSIFICATION)){
                        Map<String, Object> oriCredProClassMap = (Map<String, Object>)oriCredProMap.get(EquifaxIntegrationConstants.CLASSIFICATION);
                        vedaAcc.originalCreditProviderClassification = String.valueOf(oriCredProClassMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(oriCredProMap != null && oriCredProMap.containsKey(EquifaxIntegrationConstants.IS_LICENSEE)){
                        Map<String, Object> oriCredProLiceMap = (Map<String, Object>)oriCredProMap.get(EquifaxIntegrationConstants.IS_LICENSEE);
                        vedaAcc.originalCreditProviderIsLicensee = String.valueOf(oriCredProLiceMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> latCredProMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.LATEST_CREDIT_PROVIDER);
                    if(latCredProMap != null && latCredProMap.containsKey(EquifaxIntegrationConstants.NAME)){
                        Map<String, Object> latCredProNameMap = (Map<String, Object>)latCredProMap.get(EquifaxIntegrationConstants.NAME);
                        vedaAcc.latestCreditProviderName = String.valueOf(latCredProNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(latCredProMap != null && latCredProMap.containsKey(EquifaxIntegrationConstants.CLASSIFICATION)){
                        Map<String, Object> latCredProClassMap = (Map<String, Object>)latCredProMap.get(EquifaxIntegrationConstants.CLASSIFICATION);
                    }
                    if(latCredProMap != null && latCredProMap.containsKey(EquifaxIntegrationConstants.IS_LICENSEE)){
                        Map<String, Object> latCredProLiceMap = (Map<String, Object>)latCredProMap.get(EquifaxIntegrationConstants.IS_LICENSEE);
                    }
                    if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.LATEST_START_DATE)){
                        Map<String, Object> assInfoStDateMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.LATEST_START_DATE);
                        vedaAcc.associationInformationLatestStartDate = String.valueOf(assInfoStDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.IS_SERIOUS_CREDIT_INFRINGEMENT)){
                        Map<String, Object> assInfoIsSeCreInfriMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.IS_SERIOUS_CREDIT_INFRINGEMENT);
                        vedaAcc.associationInformationIsSeriousCreditInfringement = String.valueOf(assInfoIsSeCreInfriMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.LATEST_CEASED_DATE)){
                        Map<String, Object> assInfoCeaseDateMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.LATEST_CEASED_DATE);
                        vedaAcc.associationInformationLatestCeasedDate = String.valueOf(assInfoCeaseDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.DEFAULT_ASSOCIATION_CEASE_DATE)){
                        Map<String, Object> assInfodefAssCeaseDateMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.DEFAULT_ASSOCIATION_CEASE_DATE);
                        vedaAcc.associationInformationDefaultAssociationCeaseDate = String.valueOf(assInfodefAssCeaseDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.DEFAULT_ASSOCIATION_START_DATE)){
                        Map<String, Object> assInfodefAssStartDateMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.DEFAULT_ASSOCIATION_START_DATE);
                        vedaAcc.associationInformationDefaultAssociationStartDate = String.valueOf(assInfodefAssStartDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.SCI_DATE)){
                        Map<String, Object> assInfoSciDateMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.SCI_DATE);
                        vedaAcc.associationInformationSciDate = String.valueOf(assInfoSciDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.IS_LICENSEE)){
                        Map<String, Object> latCredProLiceMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.IS_LICENSEE);
                    }
                    Map<String, Object> payHistoryMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.REPAYMENT_HISTORY);
                    if(payHistoryMap != null && payHistoryMap.containsKey(EquifaxIntegrationConstants.PAYMENT)){
                        vedaAcc.repaymentHistory =  getVedaAccPayments(payHistoryMap);  
                    }
                    Map<String, Object> defaultsMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.DEFAULTS);
                    if(defaultsMap != null && defaultsMap.containsKey(EquifaxIntegrationConstants.DEFAULT_STR)){
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
                    if(accMap != null && accMap.containsKey(EquifaxIntegrationConstants.ACCOUNT_DATA_LEVEL)){
                        vedaAcc.accountDataLevel = String.valueOf(accMap.get(EquifaxIntegrationConstants.ACCOUNT_DATA_LEVEL));
                    }
                    if(accHolderCntMap != null && accHolderCntMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.accountHolderCount = String.valueOf(accHolderCntMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accIdMap != null && accIdMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.accountId = String.valueOf(accIdMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.CODE)){
                        vedaAcc.accountTypeCode = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.CODE));
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
                    if(latMaxAmtCreMap != null && latMaxAmtCreMap.containsKey(EquifaxIntegrationConstants.CURRENCY_CODE)){
                        vedaAcc.latestMaximumAmountCreditCurrencyCode = String.valueOf(latMaxAmtCreMap.get(EquifaxIntegrationConstants.CURRENCY_CODE));
                    }
                    if(accMap != null && accMap.containsKey(EquifaxIntegrationConstants.LATEST_UPDATE_DATE)){
                        vedaAcc.latestUpdateDate = String.valueOf(accMap.get(EquifaxIntegrationConstants.LATEST_UPDATE_DATE));
                    }
                    if(loanPayMetMap != null && loanPayMetMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.loanPaymentMethod = String.valueOf(loanPayMetMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(loanPayMetMap != null && loanPayMetMap.containsKey(EquifaxIntegrationConstants.CODE)){
                        vedaAcc.loanPaymentMethodCode = String.valueOf(loanPayMetMap.get(EquifaxIntegrationConstants.CODE));
                    }
                    if(oriMaxAmtCreditMap != null && oriMaxAmtCreditMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.originalMaximumAmountCredit = String.valueOf(oriMaxAmtCreditMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(oriMaxAmtCreditMap != null && oriMaxAmtCreditMap.containsKey(EquifaxIntegrationConstants.CURRENCY_CODE)){
                        vedaAcc.originalMaximumAmountCreditCurrencyCode = String.valueOf(oriMaxAmtCreditMap.get(EquifaxIntegrationConstants.CURRENCY_CODE));
                    }
                    if(relMap != null && relMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.relationship = String.valueOf(relMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(relMap != null && relMap.containsKey(EquifaxIntegrationConstants.CODE)){
                        vedaAcc.relationshipCode = String.valueOf(relMap.get(EquifaxIntegrationConstants.CODE));
                    }
                    if(secCreditMap != null && secCreditMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.securedCredit = String.valueOf(secCreditMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(secCreditMap != null && secCreditMap.containsKey(EquifaxIntegrationConstants.CODE)){
                        vedaAcc.securedCreditCode = String.valueOf(secCreditMap.get(EquifaxIntegrationConstants.CODE));
                    }
                    if(termOfLoanMap != null && termOfLoanMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.termOfLoan = String.valueOf(termOfLoanMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(termTypeMap != null && termTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaAcc.termType = String.valueOf(termTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(termTypeMap != null && termTypeMap.containsKey(EquifaxIntegrationConstants.CODE)){
                        vedaAcc.termTypeCode = String.valueOf(termTypeMap.get(EquifaxIntegrationConstants.CODE));
                    }
                    if(vedaAcc != null){
                        vedaAccList.add(vedaAcc);
                    }
                }
            }
        }
        return vedaAccList;   
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda Account Payments from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.payment
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.payment> getVedaAccPayments(Map<String,Object> payHistoryMap){
        List<ints.VedaComprehensiveResponse.payment> vedaAccPayList = new List<ints.VedaComprehensiveResponse.payment>();
        List<Map<String, Object>> paymentList = getListOfMaps(payHistoryMap,EquifaxIntegrationConstants.PAYMENT);
        if(paymentList != null && paymentList.size()>0){
            for(Map<String, Object>  paymentMap : paymentList){
                ints.VedaComprehensiveResponse.payment vedaPayHistory = new ints.VedaComprehensiveResponse.payment();
                if(paymentMap.containsKey(EquifaxIntegrationConstants.PERIOD)){
                    Map<String, Object> payPeriodMap = (Map<String, Object>)paymentMap.get(EquifaxIntegrationConstants.PERIOD);
                    vedaPayHistory.period = String.valueOf(payPeriodMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(paymentMap.containsKey(EquifaxIntegrationConstants.STATUS)){
                    Map<String, Object> payStatusMap = (Map<String, Object>)paymentMap.get(EquifaxIntegrationConstants.STATUS);
                    vedaPayHistory.status = String.valueOf(payStatusMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(vedaPayHistory != null){
                    vedaAccPayList.add(vedaPayHistory);
                }
            }
        } 
        return vedaAccPayList;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda Account defaults from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.VedaComprehensivedefault
    ******************************************************************************/ 
    public static List<ints.VedaComprehensiveResponse.VedaComprehensivedefault> getVedaAccDefaults(Map<String,Object> defaultsMap){
        List<ints.VedaComprehensiveResponse.VedaComprehensivedefault> vedaDefList = new List<ints.VedaComprehensiveResponse.VedaComprehensivedefault>();
        List<Map<String, Object>> defaultMapList= getListOfMaps(defaultsMap,EquifaxIntegrationConstants.DEFAULT_STR);
        if(defaultMapList != null && defaultMapList.size()>0){
            for(Map<String, Object>  defaultMap : defaultMapList){
                ints.VedaComprehensiveResponse.VedaComprehensivedefault vedaDef = new ints.VedaComprehensiveResponse.VedaComprehensivedefault();       
                if(defaultMap.containsKey(EquifaxIntegrationConstants.STATUS)){
                    Map<String, Object> defStatusMap = (Map<String, Object>)defaultMap.get(EquifaxIntegrationConstants.STATUS);
                    if(defStatusMap != null && defStatusMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaDef.status = String.valueOf(defStatusMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(defStatusMap != null && defStatusMap.containsKey(EquifaxIntegrationConstants.CODE)){
                        vedaDef.statusCode = String.valueOf(defStatusMap.get(EquifaxIntegrationConstants.CODE));
                    }
                }
                if(defaultMap.containsKey(EquifaxIntegrationConstants.ORIGINAL_DEFAULT)){                                                    
                    Map<String, Object> oriDefMap = (Map<String, Object>)defaultMap.get(EquifaxIntegrationConstants.ORIGINAL_DEFAULT);
                    if(oriDefMap != null){
                        Map<String, Object> oriDefDateRecMap = (Map<String, Object>)oriDefMap.get(EquifaxIntegrationConstants.DATE_RECORDED);
                        Map<String, Object> oriDefAmtMap = (Map<String, Object>)oriDefMap.get(EquifaxIntegrationConstants.DEFAULT_AMOUNT);
                        Map<String, Object> oriDefResMap = (Map<String, Object>)oriDefMap.get(EquifaxIntegrationConstants.REASON_TO_REPORT);
                        if(oriDefDateRecMap != null && oriDefDateRecMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDef.originalDefaultDateRecorded = String.valueOf(oriDefDateRecMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(oriDefResMap != null && oriDefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDef.originalDefaultDefaultReasonToReport = String.valueOf(oriDefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(oriDefResMap != null && oriDefResMap.containsKey(EquifaxIntegrationConstants.CODE)){
                            vedaDef.originalDefaultDefaultReasonToReportCode = String.valueOf(oriDefResMap.get(EquifaxIntegrationConstants.CODE));
                        }
                        if(oriDefAmtMap != null && oriDefAmtMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDef.originalDefaultDefaultAmount = String.valueOf(oriDefAmtMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(oriDefAmtMap != null && oriDefAmtMap.containsKey(EquifaxIntegrationConstants.CURRENCY_CODE)){
                            vedaDef.originalDefaultDefaultAmountCurrencyCode = String.valueOf(oriDefAmtMap.get(EquifaxIntegrationConstants.CURRENCY_CODE));
                        }
                    }
                }
                if(defaultMap.containsKey(EquifaxIntegrationConstants.CURRENT_DEFAULT)){                                                    
                    Map<String, Object> currDefMap = (Map<String, Object>)defaultMap.get(EquifaxIntegrationConstants.CURRENT_DEFAULT);
                    if(currDefMap != null){
                        Map<String, Object> currDefDateRecMap = (Map<String, Object>)currDefMap.get(EquifaxIntegrationConstants.DATE_RECORDED);
                        Map<String, Object> currDefAmtMap = (Map<String, Object>)currDefMap.get(EquifaxIntegrationConstants.DEFAULT_AMOUNT);
                        Map<String, Object> currDefResMap = (Map<String, Object>)currDefMap.get(EquifaxIntegrationConstants.REASON_TO_REPORT);
                        if(currDefDateRecMap != null && currDefDateRecMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDef.currentDefaultDateRecorded = String.valueOf(currDefDateRecMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(currDefResMap != null && currDefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDef.currentDefaultReasonToReport = String.valueOf(currDefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(currDefResMap != null && currDefResMap.containsKey(EquifaxIntegrationConstants.CODE)){
                            vedaDef.currentDefaultReasonToReportCode = String.valueOf(currDefResMap.get(EquifaxIntegrationConstants.CODE));
                        }
                        if(currDefAmtMap != null && currDefAmtMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaDef.currentDefaultDefaultAmount = String.valueOf(currDefAmtMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(currDefAmtMap != null && currDefAmtMap.containsKey(EquifaxIntegrationConstants.CURRENCY_CODE)){
                            vedaDef.currentDefaultDefaultAmountCurrencyCode = String.valueOf(currDefAmtMap.get(EquifaxIntegrationConstants.CURRENCY_CODE));
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
            if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
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
     * @Description  : This method is used to check whether the input object is a list or not.
     * @params       : Object param
     * @returnType   : Boolean
    ******************************************************************************/ 
    public static Boolean isCollection(Object inputObj){
        Object obj;
        try{
            obj = (List<Object>)inputObj;
            return true;
        }
        catch(System.TypeException ex){}
        return false;
    }

    /**************************************************************************
     * @Description  : This method is used to return the List of maps from input map values with a specified key
     * @params       : Map of String and object AND string
     * @returnType   : List of Map of String and object 
    ******************************************************************************/
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

    /**************************************************************************
     * @Description  : This method is used to return the List of id-references from input reference map
     * @params       : Map of String and object
     * @returnType   : List of String
    ******************************************************************************/
    public static List<String> getIdReferences(Map<String,Object> idRefMap){
        List<String> idRefList = new List<String>(); 
        if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
            List<Map<String, Object>> idRefResMapList = getListOfMaps(idRefMap,EquifaxIntegrationConstants.ID_REFERENCE);
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