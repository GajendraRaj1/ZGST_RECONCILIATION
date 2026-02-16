@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'data defination for ZGSTR_RECON_PURCHASE_CDS'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZGSTR_RECON_SALES_CDS as select from ZGSTR1_UNION_CDS
{
    
   key CompanyCode,
   key AccountingDocument,
   key FiscalYear,
   key ProfitCenter,
   key DocumentDate,
   key PostingDate,
   key AccountingDocumentType,
   key doc_item,
   key BillingDocument,
   key BillingDocumentType,
   key Customer,
   key CustomerName,
   key customer_gst,
   key product,
   key ProductDescription,
   key hsn_code,
//   key GLAccount,
   key Region,
   key DocumentReferenceID,
   key TaxCode,
   key BusinessPlace,
//   key ewbnumber,
//   key Irn,
   key Plant,
   key BaseUnit,
   key Quantity,
   key TransactionCurrency,
   key table_value,
   key JOCG_AMT,
   key JOCG_RATE,
   key JOSG_AMT,
   key JOSG_RATE,
   key JOIG_AMT,
   key JOIG_RATE,
   key INVOICE_AMT,
   REPORT,
   BillingDocumentDate,
   BillingDocumentItem,
//   @Semantics.amount.currencyCode: 'TransactionCurrency'
//   NetAmount,
   rATE,

//   @Semantics.amount.currencyCode: 'TransactionCurrency'
   TaxAmount
//   Shipping_Bill_Date,
//   Shipping_Bill_No,
//   Shipping_Port_Code_No
}
