@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'data defination for ZFI_S_YGSTR2'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZFI_S_YGSTR2 
  as select from    YGSTR2                    as a 
    left outer join I_OperationalAcctgDocItem as GL on(
      GL.AccountingDocument                 =  a.FiDocument
      and GL.TaxItemAcctgDocItemRef         =  a.FiDocumentItem
      and GL.FiscalYear                     =  a.FiscalYear
      and GL.CompanyCode                    =  a.CompanyCode
      and GL.GLAccount                      is not initial
      and GL.FinancialAccountType           != 'K'
      and(
        GL.TransactionTypeDetermination     != 'WIT'
        and GL.TransactionTypeDetermination != 'DIF'
        and GL.TransactionTypeDetermination != 'BSX'
        and GL.TransactionTypeDetermination != 'PRD'
      )
      and ( GL.TransactionTypeDetermination   != 'KBS' or ( GL.TransactionTypeDetermination   = 'KBS'  and  GL.FinancialAccountType = 'S' ) )  
      )
    left outer join I_OperationalAcctgDocItem as GL2 on(
      GL2.AccountingDocument                 =  a.FiDocument
      and GL2.TaxItemAcctgDocItemRef         =  a.FiDocumentItem
      and GL2.FiscalYear                     =  a.FiscalYear
      and GL2.CompanyCode                    =  a.CompanyCode
      and GL2.GLAccount                      is not initial
      and GL2.FinancialAccountType           != 'K'
      and( 
         GL2.TransactionTypeDetermination = 'BSX' )
    )
    left outer join I_GLAccountText           as J  on(
       J.GLAccount    = GL.GLAccount
       and J.Language = 'E'
     )
    left outer join I_GLAccountText           as J2  on(
       J2.GLAccount    = GL2.GLAccount
       and J2.Language = 'E'
     )

{
  key a.FiDocument,
  key a.FiscalYear,
      a.FiDocumentItem,
      a.DocumentDate,
      a.AccountingDocumentItem,
      a.TransactionCurrency,
      a.Mironumber,
      a.MiroYear,
      a.Refrence_No,
      a.AccountingDocumentType,
      a.CompanyCode,
      a.BusinessPlace,
      a.PostingDate,
      a.ProfitCenter,
      //      GLAccount_new,
      @Semantics: { quantity : {unitOfMeasure: 'BaseUnit'} }
      a.Quantity,
      a.BaseUnit,
      a.HsnCode,
      a.AssignmentReference,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      a.InvoceValue,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      a.TaxableValue,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      a.Gross_amount,
      a.TaxCode,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      sum( a.igst )     as IGST,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      sum( a.cgst )     as CGST,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      sum( a.Sgst )     as SGST,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      sum( a.RCM_igst ) as RCMI,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      sum( a.RCM_cgst)  as RCMC,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      sum( a.RCM_Sgst)  as RCMS,
      a.PARTYcODE,
      a.PlaceofSupply,
      a.FinancialAccountType,
      a.IN_GSTSupplierClassification,
      a.PartyName,
      a.PartyAdd,
      a.GstIn,
      a.State,
      a.TaxRate,
      a.taxcodedescription,
      a.AccountingDocumentHeaderText,
      a.DocumentReferenceID,
      a.IsReversed,
      a.IsReversal,
      a.ReversalReferenceDocument,
      a.Product,
      a.ProductDescription,
      case
       when  GL.GLAccount is null
       then GL2.GLAccount
       else GL.GLAccount end as GLAccount ,
      case
       when  GL.GLAccount is null
       then J2.GLAccountName
       else J.GLAccountName end as GLAccountName
      
      
}
group by

  a.FiDocument,
  a.FiscalYear,
  a.FiDocumentItem,
  a.DocumentDate,
  a.AccountingDocumentItem,
  a.TransactionCurrency,
  a.Mironumber,
  a.MiroYear,
  a.Refrence_No,
  a.AccountingDocumentType,
  a.PostingDate,
  a.ProfitCenter,
  a.Quantity,
  a.BaseUnit,
  a.HsnCode,
  GL.GLAccount,
  GL2.GLAccount,
  a.AssignmentReference,
  a.InvoceValue,
  a.TaxableValue,
  a.Gross_amount,
  a.TaxCode,
  a.PARTYcODE,
  a.PlaceofSupply,
  a.FinancialAccountType,
  a.IN_GSTSupplierClassification,
  a.PartyName,
  a.PartyAdd,
  a.GstIn,
  a.State,
  a.TaxRate,
  a.taxcodedescription,
  a.AccountingDocumentHeaderText,
  a.DocumentReferenceID,
  a.IsReversed,
  a.IsReversal,
  a.CompanyCode,
  a.BusinessPlace,
  a.ReversalReferenceDocument,

  a.Product,
  a.ProductDescription,
  J.GLAccountName ,
  J2.GLAccountName
  
  
