/************************************************
@ Description : Trigger for Pay Off Quote
Developer : Supriyo Seni
Date : 03/02/2023
************************************************/

trigger LoanPayoffQuoteTrigger on loan__Payoff_Quote__c (after insert) {
    try{
        Bpay_Default_Values__c bpayIns = Bpay_Default_Values__c.getInstance();
        if((bpayIns!=null) && (bpayIns.LoanPayOffQuoteTrigger__c == true)){
            List<loan__Payoff_Quote__c> payOffQuoteList = new List<loan__Payoff_Quote__c> ();
            Set<String> loanListSet = new Set<String>();
            List<Insurance__c> insuranceList = new List<Insurance__c>();
            Decimal rebateTotalForActivePolicies = 0;
            Map<Id,Decimal> loanIdVsRebate = new Map<Id,Decimal> ();
            List<loan__Payoff_Quote__c> payOffQuoteToUpdate = new List<loan__Payoff_Quote__c> ();
            if(Trigger.isInsert && Trigger.isAfter){
                for(Id recordId : Trigger.newMap.keyset()){
                    if(Trigger.newMap.get(recordId).loan__Loan_Account__c != NULL){
                        loanListSet.add(Trigger.newMap.get(recordId).loan__Loan_Account__c);
                    }
                }
                payOffQuoteList = [SELECT id,
                                            name,
                                            Total_of_Insurance_rebates__c,
                                            loan__Loan_Account__c,
                                            loan__Poq_Principal_Bal__c,
                                            loan__Poq_Total_Payoff_Amount__c
                                FROM loan__Payoff_Quote__c
                                WHERE id IN : Trigger.newMap.keySet()];
                insuranceList = [SELECT id,
                                        name,
                                        Loan_Account__c,
                                        Product__c,
                                        Premium_Rebate_Amount_Net__c,
                                        Premium_Rebate_Amount_GST__c,
                                        Premium_Rebate_Amount_S_Duty__c,
                                        User_Defined_Policy_Status__c,
                                        Premium_Rebate_Amount_Gross__c,
                                        Policy_Status__c,
                                        Rebate_Factor__c,
                                        Premium_Amount_Gross__c
                                FROM Insurance__c
                                WHERE Policy_Status__c =: InsuranceConstants.ACTIVE
                                AND Loan_Account__r.id IN : loanListSet];
                if(insuranceList != null && insuranceList.size()>0){
                    for(Insurance__c ins : insuranceList){
                        if(loanIdVsRebate.containsKey(ins.Loan_Account__c) && loanIdVsRebate.get(ins.Loan_Account__c) != null && ins.Premium_Amount_Gross__c != null){
                            Decimal totalRebate = loanIdVsRebate.get(ins.Loan_Account__c) + (ins.ins.Rebate_Factor__c * ins.Premium_Amount_Gross__c);
                            loanIdVsRebate.put(ins.Loan_Account__c,totalRebate);
                        }else if(ins.Premium_Amount_Gross__c != null){
                            loanIdVsRebate.put(ins.Loan_Account__c,ins.Rebate_Factor__c * ins.Premium_Amount_Gross__c);
                        }
                    }
                }
                if(payOffQuoteList != null && payOffQuoteList.size()>0){
                    for(loan__Payoff_Quote__c payOffQuote : payOffQuoteList){
                        if(loanIdVsRebate.containsKey(payOffQuote.loan__Loan_Account__c) && loanIdVsRebate.get(payOffQuote.loan__Loan_Account__c) != 0){
                            payOffQuote.Total_of_Insurance_rebates__c = -loanIdVsRebate.get(payOffQuote.loan__Loan_Account__c);
                            payOffQuote.loan__Poq_Total_Payoff_Amount__c = payOffQuote.loan__Poq_Total_Payoff_Amount__c - loanIdVsRebate.get(payOffQuote.loan__Loan_Account__c);
                            payOffQuoteToUpdate.add(payOffQuote);
                        }
                    }
                    if(payOffQuoteToUpdate != null && payOffQuoteToUpdate.size()>0){
                        update payOffQuoteToUpdate;
                    }
                }
            }
        }
    }catch(Exception ex){
        ExceptionManager.manageException(ex);
    }
}