@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'gstr recon purchase cds'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZGSTR_RECON_PURCHASE_CDS as select from ZGSTR2_UNION_CDS
{
   key CompanyCode,
   key AccountingDocument,
   key FiscalYear,
   key doc_item,
   key SupplierInvoice,
   key ProductDescription,
   key ConsumptionTaxCtrlCode,
   key DocumentDate,
   key PostingDate,
   key TaxCode,
   key Product,
   key Plant,
   key FiscalPeriod,
   key Supplier,
   key SupplierName,
   key AccountingDocumentType,
   key BusinessPlace,
   key DocumentReferenceID,
   key IN_GSTPlaceOfSupply,
   key SUP_GST,
   key BaseUnit,
   key TransactionCurrency,
   key CompanyCodeCurrency,
   key AmountInCompanyCodeCurrency,
   key Quantity,
   key TAXABLE_AMT,
   key Cgst_amt,
   key sgst_amt,
   key igst_amt,
   key cgst_rate,
   key sgst_rate,
   key igst_rate,
   key INVOICE_AMT,
   REPORT,
   
   '' as taxablevalue,
   //coalesce( Cgst_amt, 0 ) + coalesce( sgst_amt, 0 ) + coalesce( igst_amt, 0 ) as taxablevalue ,
        cast( ' ' as abap.char( 3 ) ) as state,
   '' as SupplierFullName,
   '' as IN_HSNOrSACCode    
        
}
