@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'data defination for YGSTR2'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity YGSTR2 
  as select from    I_OperationalAcctgDocItem as a
    left outer join I_OperationalAcctgDocItem as b  on(
       b.AccountingDocument       = a.AccountingDocument
       and b.CompanyCode          = a.CompanyCode
       and b.FiscalYear           = a.FiscalYear
       and b.FinancialAccountType = 'K'
     )
    left outer join I_Supplier                as C  on(
       C.Supplier = b.Supplier
     )
     
    left outer join      I_OperationalAcctgDocItem as ZE on(
                                          ZE.AccountingDocument = a.AccountingDocument
                                      and ZE.FinancialAccountType = 'D'  and ZE.FiscalYear = a.FiscalYear
                                      and ZE.CompanyCode = a.CompanyCode )
    left outer join I_Customer        as    ZEC on ( ZEC.Customer = ZE.Customer  )
     
     
    left outer join ytax_code2                 as D  on( 
       D.taxcode = a.TaxCode
     )
    left outer join I_JournalEntry            as E  on(
       E.AccountingDocument = a.AccountingDocument
       and E.FiscalYear     = a.FiscalYear
       and E.CompanyCode    = a.CompanyCode
     )

    left outer join I_OperationalAcctgDocItem as AB on(
      AB.AccountingDocument         = a.AccountingDocument
      and AB.FiscalYear             = a.FiscalYear
      and AB.CompanyCode            = a.CompanyCode
      and AB.TaxItemAcctgDocItemRef = a.TaxItemAcctgDocItemRef
      and AB.IN_HSNOrSACCode        is not initial
    )

    left outer join I_JournalEntryItem        as H  on(
       H.AccountingDocument              = a.AccountingDocument
       and H.AccountingDocumentItem      = a.AccountingDocumentItem
       and H.FiscalYear                  = a.FiscalYear
       and H.CompanyCode                 = a.CompanyCode
       and H.AmountInTransactionCurrency = a.AmountInCompanyCodeCurrency
       and H.Ledger                      = '0L'
     )
    left outer join I_ProductDescription      as i  on(
       i.Product      = a.Product
       and i.Language = 'E'
     )


{
  key a.AccountingDocument                                                                    as FiDocument,
  key a.FiscalYear                                                                            as FiscalYear,
      a.TaxItemAcctgDocItemRef                                                                as FiDocumentItem,
      a.AccountingDocumentItem,
      a.DocumentDate,
      H.ProfitCenter,
      a.TransactionCurrency,
      left(  a.OriginalReferenceDocument  , 10 )                                              as Mironumber,
      right( a.OriginalReferenceDocument  , 4 )                                               as MiroYear,
      a.AssignmentReference                                                                   as Refrence_No,
      a.AccountingDocumentType,
      a.PostingDate,
      a.CompanyCode,
      a.TransactionTypeDetermination,
      AB.IN_HSNOrSACCode                                                                      as HsnCode,
      a.GLAccount,
      b.AssignmentReference,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case a.TransactionTypeDetermination
      when  'JII' then  ( a.TaxBaseAmountInCoCodeCrcy )
      when  'JIS' then  ( a.TaxBaseAmountInCoCodeCrcy )
       end                                                                                    as TaxableValue,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      ( b.AmountInCompanyCodeCurrency  )                                                      as InvoceValue,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case a.TransactionTypeDetermination

      when  'JII' then ( ( a.TaxBaseAmountInCoCodeCrcy  )  + ( a.AmountInCompanyCodeCurrency  )  )
      when  'JIC' then ( ( a.TaxBaseAmountInCoCodeCrcy  )  + ( a.AmountInCompanyCodeCurrency  )  )
      when  'JIS' then ( ( a.TaxBaseAmountInCoCodeCrcy  )  + ( a.AmountInCompanyCodeCurrency  )  )
      when  'JRC' then ( ( a.TaxBaseAmountInCoCodeCrcy  )  + ( a.AmountInCompanyCodeCurrency  )  )
      when  'JRS' then ( ( a.TaxBaseAmountInCoCodeCrcy  )  + ( a.AmountInCompanyCodeCurrency  )  )
      when  'JRI' then ( ( a.TaxBaseAmountInCoCodeCrcy  )  + ( a.AmountInCompanyCodeCurrency  )  )
           end                                                                                as Gross_amount,
      a.TaxCode,
      a.DebitCreditCode,
      a.IsNegativePosting,
      
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case
      when a.TransactionTypeDetermination = 'JII'  then ( a.AmountInCompanyCodeCurrency ) end as igst,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case
      when a.TransactionTypeDetermination = 'JIC'  then ( a.AmountInCompanyCodeCurrency ) end as cgst,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case
      when a.TransactionTypeDetermination = 'JIS'  then ( a.AmountInCompanyCodeCurrency ) end as Sgst,
       @Semantics.amount.currencyCode: 'TransactionCurrency'
      case a.TransactionTypeDetermination
      when  'JRI' then  ( a.AmountInCompanyCodeCurrency ) end                                 as RCM_igst,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case a.TransactionTypeDetermination
      when  'JRC' then  ( a.AmountInCompanyCodeCurrency ) end                                 as RCM_cgst,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case a.TransactionTypeDetermination
      when  'JRS' then  ( a.AmountInCompanyCodeCurrency ) end                                 as RCM_Sgst,
      b.IN_GSTPlaceOfSupply                                                                   as PlaceofSupply,
      b.FinancialAccountType,
      
      C.IN_GSTSupplierClassification,
      C.Region                                                                                as State,
      
       case a.AccountingDocumentType when 'ZE'
      then ZE.Customer 
      else b.Supplier
      end as PARTYcODE ,
      
      case a.AccountingDocumentType when 'ZE'
      then ZEC.CustomerName 
      else C.SupplierName 
      end as PartyName ,
      case a.AccountingDocumentType when 'ZE'
      then ZEC.CustomerFullName  
      else C.SupplierFullName 
      end as PartyAdd ,
       
      case a.AccountingDocumentType when 'ZE'
      then ZEC.TaxNumber3 
      else C.TaxNumber3 
      end as GstIn ,                 

      D.gstrate                                                                               as TaxRate,
      D.taxcodedescription,
      E.AccountingDocumentHeaderText,
      E.DocumentReferenceID,
      E.IsReversed,
      E.IsReversal,
      E.ReversalReferenceDocument,
      a.BusinessPlace,
      @Semantics: { quantity : {unitOfMeasure: 'BaseUnit'} }
      a.Quantity,
      a.BaseUnit,

      a.Product,
      i.ProductDescription

}
where
  (
         a.AccountingDocumentType     =    'RE'
    or   a.AccountingDocumentType     =    'KR'
    or   a.AccountingDocumentType     =    'KZ'
    or   a.AccountingDocumentType     =    'KG'
    or   a.AccountingDocumentType     =    'KA'
    or   a.AccountingDocumentType     =    'KD'
    or   a.AccountingDocumentType     =    'JV'
    or   a.AccountingDocumentType     =    'ZE'
  )

  and(
         a.TaxCode                    like 'R%'
  )
  and    a.AccountingDocumentItemType =    'T'
  and(
         E.IsReversal                 !=   'X'
    and  E.IsReversed                 !=   'X'
  )

  and(
    (
         E.TransactionCode            =    'FB01'
      or E.TransactionCode            =    'FB60'
      or E.TransactionCode            =    'FB70'
      or E.TransactionCode            =    'FBDC_C014'
      or E.TransactionCode            =    'FBDC_C024'
      or E.TransactionCode            =    'MIR7'
      or E.TransactionCode            =    'MIRO'
    ) //  or E.TransactionCode = 'J_1IG_INV'
  )

group by

  a.AccountingDocument,
  a.FiscalYear,
  a.TaxItemAcctgDocItemRef,
  a.AccountingDocumentItem,
  a.DocumentDate,
  H.ProfitCenter,
  a.TransactionCurrency,
  a.OriginalReferenceDocument,
  a.AssignmentReference,
  a.TaxCode,
  a.DebitCreditCode,
  a.IsNegativePosting,
  a.AccountingDocumentType,
  a.PostingDate,
  a.CompanyCode,
  a.TransactionTypeDetermination,
  AB.IN_HSNOrSACCode,
  a.GLAccount,
  b.AssignmentReference,
  b.Supplier,
  b.IN_GSTPlaceOfSupply,
  b.FinancialAccountType,
  C.IN_GSTSupplierClassification,
  C.SupplierName,
  C.SupplierFullName,
  C.TaxNumber3,
  C.Region,
  D.gstrate,
  D.taxcodedescription,
  E.AccountingDocumentHeaderText,
  E.DocumentReferenceID,
  E.IsReversed,
  E.IsReversal,
  E.ReversalReferenceDocument,
  a.BusinessPlace,
  a.Quantity,
  a.BaseUnit,

  a.TaxBaseAmountInCoCodeCrcy,
  a.AmountInCompanyCodeCurrency,
  b.AmountInCompanyCodeCurrency,

  a.Product,
  i.ProductDescription,
  
   ZEC.CustomerName ,
   ZEC.CustomerFullName ,
   ZEC.TaxNumber3 ,
  ZE.Customer
