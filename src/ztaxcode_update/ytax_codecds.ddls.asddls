@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'data defination for YTAX_CODECDS'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity YTAX_CODECDS as select from ytax_code2 
{
    key taxcode as Taxcode,
    taxcodedescription as Taxcodedescription,
    gstrate as gstrate 
}
