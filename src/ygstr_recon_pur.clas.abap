 CLASS ygstr_recon_pur DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

   PUBLIC SECTION.

     INTERFACES  if_oo_adt_classrun.

     CLASS-DATA : access_token TYPE string .
     CLASS-DATA  : zgst_recon_data TYPE zgst_recon_data .

     TYPES:
       BEGIN OF post_s,
         user_id TYPE i,
         id      TYPE i,
         title   TYPE string,
         body    TYPE string,
       END OF post_s,

       BEGIN OF post_without_id_s,
         user_id TYPE i,
         title   TYPE string,
         body    TYPE string,
       END OF post_without_id_s.

     CLASS-METHODS :

       create_client

         IMPORTING url           TYPE string
         RETURNING VALUE(result) TYPE REF TO if_web_http_client
         RAISING   cx_static_check ,

       gstr_pur
         IMPORTING vbeln1              TYPE string OPTIONAL
                   datefrom            TYPE string
                   dateto              TYPE string
                   companycode         TYPE string
                   gstno               TYPE string
*                   plant               TYPE string
         RETURNING VALUE(gstrecon_pur) TYPE string.

   PROTECTED SECTION.
   PRIVATE SECTION.
ENDCLASS.



CLASS YGSTR_RECON_PUR IMPLEMENTATION.


   METHOD create_client.
     DATA(dest) = cl_http_destination_provider=>create_by_url( url ).
     result = cl_web_http_client_manager=>create_by_http_destination( dest ).
   ENDMETHOD.


   METHOD gstr_pur.

     FIELD-SYMBOLS:
       <datax>  TYPE data,
       <datay>  TYPE data,
       <dataz>  TYPE data,
       <data2>  TYPE data,
       <data3>  TYPE any,
       <field>  TYPE any,
       <field1> TYPE any,
       <field2> TYPE any.

     DATA  gstinstats           TYPE string .
     DATA  gstin                TYPE string .
     DATA  totaldocumentcount   TYPE string .
     DATA  validrows            TYPE string .
     DATA  invalidrows          TYPE string .
     DATA  jsonrecorderrors     TYPE string .
     DATA  recordindex          TYPE string .
     DATA  externalid           TYPE string .
     DATA  externallineitemid   TYPE string .
     DATA  recorderrors         TYPE string .
     DATA  errorid              TYPE string .
     DATA  errormessage         TYPE string .
     DATA  impbillnumber        TYPE char10 .
     DATA  impbilldate          TYPE char10 .

     DATA  imp     TYPE char10 .
     DATA: lr_str TYPE REF TO data.


     DATA gv_from TYPE sy-datum .
     DATA gv_to TYPE  sy-datum .
    gv_from = |{ datefrom+0(4) }{ datefrom+5(2) }{ datefrom+8(2) }|. " 2025-02-01
    gv_to   = |{ dateto+0(4) }{ dateto+5(2) }{ dateto+8(2) }|.

         DATA: b_place TYPE string.


    IF companycode = '1000' AND gstno = '08AAACP1125E1ZZ' .
      b_place  = '1010' .
    ELSEIF
       companycode = '1000' AND gstno = '08AAACP1125E2ZY' .
       b_place  = '1020' .
       ELSEIF
       companycode = '1000' AND gstno = '07AAACP1125E4ZY' .
       b_place  = '1030' .
       ELSEIF
       companycode = '1000' AND gstno = '33AAACP1125E3Z4' .
       b_place  = '1040' .
       ELSEIF
       companycode = '1000' AND gstno = '27AAACP1125E3ZX' .
       b_place  = '1050' .
    ENDIF.

     """ COMBINE ALL GST REPORTS
     SELECT * FROM ZGSTR_RECON_PURCHASE_CDS WITH PRIVILEGED ACCESS WHERE postingdate BETWEEN @gv_from AND @gv_to
              AND companycode = @companycode AND businessplace = @b_place
              INTO TABLE @DATA(gstr2) .


     """"" UNIT CONVERT
     SELECT FROM i_unitofmeasure WITH PRIVILEGED ACCESS AS a
         FIELDS
         a~unitofmeasure ,
         a~unitofmeasure_e

         FOR ALL ENTRIES IN @gstr2
         WHERE a~unitofmeasure = @gstr2-baseunit
         INTO TABLE @DATA(it_unit).

     """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
     READ TABLE gstr2 INTO DATA(wa_gst) INDEX 1 .

      DATA plant1 TYPE char4.

     SORT gstr2 ASCENDING BY accountingdocument doc_item.
     DELETE ADJACENT DUPLICATES FROM gstr2 COMPARING accountingdocument doc_item.
     DATA(gstr_hdr) = gstr2.
     SORT gstr_hdr ASCENDING BY accountingdocument .
     DELETE ADJACENT DUPLICATES FROM gstr_hdr COMPARING accountingdocument  .

     DATA(records) = lines( gstr_hdr ) .
     DATA total   TYPE i .
     DATA success TYPE i .
     DATA fail    TYPE i .
     DATA rcm     TYPE c .
     DATA tot_sum       TYPE string.
     DATA total_amt     TYPE string.
     DATA gst_cs_rate   TYPE P DECIMALS 1.
     DATA gst_igst_rate TYPE P DECIMALS 1.
     DATA zero_tax      TYPE string.
     DATA compo         TYPE c.

     DATA: accountingdocument TYPE c LENGTH 10.
     DATA bracketo TYPE string VALUE '{' .
     DATA bracketc TYPE string VALUE '}' .
     DATA lv_xml   TYPE string .
     DATA lv_xml13 TYPE string .
     DATA lv_xml14 TYPE string .

     CLEAR: success,fail,total.

     DATA(sep) = ',' .
     IF sy-tabix NE 1 .
       CLEAR sep .
     ENDIF .


     DATA gv TYPE string .
     DATA gv11 TYPE string .


     """""" HEADER DATA
     LOOP AT gstr_hdr INTO DATA(wa_hdr) .

       SELECT SINGLE * FROM i_regiontext WHERE region = @wa_hdr-state AND language = 'E' AND country = 'IN' INTO @DATA(state)  .
       IF state-region = '37' OR state-region = '28'.
         state-regionname = 'Andhra Pradesh'.
       ENDIF.

       DATA: fin_json TYPE string,
             tabix    TYPE sy-tabix.

       DATA(gstr_item) = gstr2 .
       DELETE  gstr_item WHERE accountingdocument <>  wa_hdr-accountingdocument  .
       CLEAR : tot_sum .

       LOOP AT gstr_item INTO DATA(wa_a).
         tot_sum = tot_sum + wa_a-invoice_amt + wa_a-taxable_amt .
       ENDLOOP .

       fin_json =
        |{ bracketo }"userInputArgs" :{ bracketo }"templateId":"60e5613ff71f4a7aeca4336b","settings":{ bracketo }"ignoreHsnValidation":true{ bracketc }{ bracketc },| &&
        |"jsonRecords":[ | .

       LOOP AT gstr2 INTO DATA(iv) WHERE accountingdocument = wa_hdr-accountingdocument .
          tabix = sy-tabix.

         gv   = |{ iv-postingdate+0(4) }/{ iv-postingdate+4(2) }/{ iv-postingdate+6(2) }| .
         gv11 = |{ iv-documentdate+0(4) }/{ iv-documentdate+4(2) }/{ iv-documentdate+6(2) }| .





         DATA(unit) = VALUE #( it_unit[ unitofmeasure = iv-baseunit ]-unitofmeasure_e OPTIONAL ) .

         """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
         IF iv-accountingdocumenttype = 'KR' OR iv-accountingdocumenttype = 'KA'.
           DATA(doc_typ) = 'Invoice'.
         ELSEIF iv-accountingdocumenttype = 'KG' .
           doc_typ  = 'Debit'.
         ELSEIF iv-accountingdocumenttype = 'DG' .
           doc_typ  = 'Credit'.
         ELSEIF iv-accountingdocumenttype = 'RE'.

           SELECT SINGLE debitcreditcode, financialaccounttype FROM i_operationalacctgdocitem WHERE accountingdocument = @iv-accountingdocument
              AND accountingdocumentitem = @iv-doc_item AND companycode = @iv-companycode AND financialaccounttype = 'K'
              AND fiscalyear = @iv-fiscalyear INTO @DATA(dc_code).

           IF dc_code-debitcreditcode = 'H'.
             doc_typ = 'Invoice'.
           ELSE.
             doc_typ = 'Debit'.
           ENDIF.

         ENDIF.

         IF iv-taxcode = 'RA' OR
            iv-taxcode = 'RB' OR
            iv-taxcode = 'RC' OR
            iv-taxcode = 'RD' OR
            iv-taxcode = 'RE' OR
            iv-taxcode = 'RF' OR
            iv-taxcode = 'RG' OR
            iv-taxcode = 'RH' OR
            iv-taxcode = 'RN' OR
            iv-taxcode = 'RS' .

           rcm = 'Y'.

           IF  iv-SUP_GST = '0'.
             iv-SUP_GST = 'null'.
           ENDIF.

           SELECT SINGLE  taxbaseamountincocodecrcy  FROM i_operationalacctgdocitem WITH PRIVILEGED ACCESS
            WHERE accountingdocument = @iv-accountingdocument
              AND taxitemacctgdocitemref = @iv-doc_item
              AND fiscalyear = @iv-fiscalyear
              AND transactiontypedetermination IN ( 'JII','JIC','JIS' ) AND companycode = @iv-companycode
INTO @iv-taxable_amt .
         ELSE.
           rcm = 'N'.
         ENDIF.

         IF iv-companycode = '4000' .
           rcm = 'Y'.
         ENDIF.

         """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" ND TaxCodes
         IF      iv-taxcode = 'ZA' OR
                 iv-taxcode = 'ZB' OR
                 iv-taxcode = 'ZC' OR
                 iv-taxcode = 'ZD' OR
                 iv-taxcode = 'Z1' OR
                 iv-taxcode = 'Z2' OR
                 iv-taxcode = 'Z3' OR
                 iv-taxcode = 'Z4' .

              if iv-invoice_amt < 0.
              iv-invoice_amt = iv-invoice_amt * -1.
              endif.

              DATA(ND) = 'INELIGIBLE'.

              ELSE. ND = 'INPUT'.
 Endif.

         IF  iv-taxcode = 'PE' OR
             iv-taxcode = 'PF' OR
             iv-taxcode = 'PG' OR
             iv-taxcode = 'PH'.

           SELECT SINGLE amountincompanycodecurrency FROM i_operationalacctgdocitem WITH PRIVILEGED ACCESS  WHERE accountingdocument = @iv-accountingdocument AND financialaccounttype = 'S' AND
               accountingdocumentitem = @iv-doc_item AND fiscalyear = @iv-fiscalyear AND companycode = @wa_a-companycode AND accountingdocumentitemtype = 'T'
               AND transactiontypedetermination = 'JIM' INTO @iv-igst_amt .

           rcm = 'N'.

         ELSE.
           SELECT SINGLE cgst, igst FROM zfi_s_ygstr2 WITH PRIVILEGED ACCESS WHERE FIDOCUMENT = @iv-AccountingDocument AND
               accountingdocumentitem = @iv-doc_item   AND fiscalyear = @iv-fiscalyear
               AND companycode = @wa_a-companycode  AND ( cgst GT 0 OR  igst GT 0 )
               INTO (  @iv-Cgst_amt ,@iv-igst_amt )   .
         ENDIF.
         IF iv-sgst_amt IS INITIAL.
           iv-sgst_amt = iv-Cgst_amt.
         ENDIF.
         IF iv-Cgst_amt IS INITIAL.
           iv-Cgst_amt = iv-sgst_amt.
         ENDIF.

         total_amt    = iv-taxablevalue + iv-Cgst_amt + iv-sgst_amt + iv-igst_amt.

         IF total_amt < 0.
           total_amt = ( total_amt * -1 ) - 0.
         ENDIF.

         DATA(rt) = iv-taxcode+0(1).

         IF tot_sum < 0.
           tot_sum = tot_sum * -1.
         ENDIF.

         IF iv-taxablevalue < 0.
           iv-taxablevalue = iv-taxablevalue * -1.
         ENDIF.

          IF iv-taxable_amt < 0.
           iv-taxable_amt = iv-taxable_amt * -1.
         ENDIF.

         IF iv-Cgst_amt < 0.
           iv-Cgst_amt = iv-Cgst_amt * -1.
         ENDIF.

         IF iv-sgst_amt < 0.
           iv-sgst_amt = iv-sgst_amt * -1.
         ENDIF.

         IF iv-igst_amt < 0.
           iv-igst_amt = iv-igst_amt * -1.
         ENDIF.

         IF ( iv-taxcode = 'PE' OR iv-taxcode = 'PF' OR
                iv-taxcode = 'PG' OR
                iv-taxcode = 'PH' ) .

           SELECT SINGLE plant FROM i_operationalacctgdocitem WHERE accountingdocument = @iv-accountingdocument
                     AND fiscalyear = @iv-fiscalyear AND companycode = @iv-companycode
                     AND plant NE '' INTO @plant1.

           IF ( plant1 = '1100' OR plant1 = '1110' OR plant1 = '1120' OR plant1 = '1150' OR plant1 = '1140' OR plant1 = '1160' OR plant1 = '1170'
               OR plant1 = '2100' OR plant1 = '2110' OR plant1 = '2200' OR plant1 = '5100' ).
             DATA(impportcd) = 'INMUN1'.
           ELSEIF ( plant1 = '1130' OR plant1 = '5000' ).
             impportcd = 'INNSA1'.
           ELSEIF ( plant1 = '2120' ).
             impportcd = 'INVTZ1'.
           ENDIF.

           impbillnumber = iv-documentreferenceid.
           impbilldate   = gv11.
           DATA(imptype) = 'GOODS'.

         ENDIF.

         """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

         IF tabix NE 1.
           fin_json = fin_json && sep.
         ENDIF.



         fin_json = fin_json &&
              |{ bracketo }"documentType":"{ doc_typ }","documentDate": "{ gv11 }" ,"documentNumber": "{ iv-documentreferenceid }","itcClaimType": "{ nd }", | &&
              |"erpSource":"SAP","voucherNumber":"{ iv-documentreferenceid  }","voucherDate":"{ gv }","isSupplierCompositionDealer":"{ compo }",| &&
              |"isBillOfSupply":"N","isReverseCharge":"{ rcm }","isDocumentCancelled":"N","zeroTaxCategory":"{ zero_tax }",| &&
              |"importType":"{ imptype }","importBillNumber":"{ impbillnumber }","importBillDate":"{ gv11 }","importPortCode":"{ impportcd }",| &&
              |"supplierGstin":"{ iv-sup_gst }","supplierName":"{ iv-SupplierName }","supplierAddress":"{ iv-SupplierFullName }","supplierState":"{ state-regionname }", | &&
              |"customerGstin":"{ '08AAFCD5862R018' }","placeOfSupply":"",| &&   "{ iv-IN_GSTPlaceOfSupply }
           | "itemDescription":"{ iv-doc_item }","itemCategory":"G",| &&
           |"hsnSacCode":"{ iv-IN_HSNOrSACCode }","itemQuantity":{ iv-quantity },"itemUnitCode":"{ unit }","itemUnitPrice":{ iv-taxable_amt },"itemDiscount":"0.00","itemTaxableAmount":{ iv-taxable_amt },| &&
           |"cgstRate":{ SWITCH #(  iv-igst_amt WHEN 0 THEN iv-cgst_rate ELSE 0 )  },"cgstAmount":{ iv-Cgst_amt }, | &&
           |"sgstRate":{ SWITCH #(  iv-igst_amt WHEN 0 THEN iv-sgst_rate ELSE 0 )  },"sgstAmount":{ iv-sgst_amt }, | &&
           |"igstRate":{ SWITCH #(  iv-igst_amt WHEN 0 THEN 0 ELSE iv-igst_rate ) },"igstAmount":{ iv-igst_amt },"cessRate":0,"cessAmount":0, | &&
           |"documentTotalAmount":{ tot_sum } { bracketc } | .
       REPLACE ALL OCCURRENCES OF '"cgstRate":,' IN fin_json WITH '"cgstRate": 0,'.
      REPLACE ALL OCCURRENCES OF '"sgstRate":,' IN fin_json WITH '"sgstRate": 0,'.

       ENDLOOP.
       fin_json = fin_json && |]{ bracketc }|.
       DATA(status1)  =  ygstr_recon_api=>post_clear_tax( json =  fin_json gstin = |{ gstno }| fidocument = |{ iv-accountingdocument }| ) .
       DATA(lr_d1) = /ui2/cl_json=>generate( json = status1 ).
       IF lr_d1 IS BOUND.
         ASSIGN lr_d1->* TO <datax>.
         IF <datax> IS ASSIGNED .
           ASSIGN COMPONENT 'jsonRecordErrors' OF STRUCTURE <datax>  TO   <field>    .
           IF sy-subrc = 0 .
             ASSIGN <field>->* TO <data2>  .
             IF <data2> IS ASSIGNED .
               LOOP AT <data2> ASSIGNING FIELD-SYMBOL(<ls_data2>).
                 ASSIGN COMPONENT 'RECORDERRORS' OF STRUCTURE <ls_data2> TO FIELD-SYMBOL(<fs>).
                 IF <fs> IS ASSIGNED.
                 ELSE.
                   ASSIGN <ls_data2>->* TO FIELD-SYMBOL(<lt_fs>).
                   IF <lt_fs> IS ASSIGNED.
                     ASSIGN COMPONENT 'RECORDERRORS' OF STRUCTURE <lt_fs> TO FIELD-SYMBOL(<fs2>).
                     IF <fs2> IS ASSIGNED.
                       ASSIGN <fs2>->* TO FIELD-SYMBOL(<fs4>).
                       IF <fs4> IS ASSIGNED.
                         LOOP AT <fs4> ASSIGNING FIELD-SYMBOL(<fs5>).
                           IF <fs5> IS ASSIGNED.
                             ASSIGN COMPONENT 'ERRORMESSAGE' OF STRUCTURE <fs5> TO FIELD-SYMBOL(<fs6>).
                             IF <fs6> IS ASSIGNED.
                             ELSE.
                               ASSIGN <fs5>->* TO FIELD-SYMBOL(<fs7>).
                               IF <fs7> IS ASSIGNED.
                                 ASSIGN COMPONENT `ERRORMESSAGE` OF STRUCTURE <fs7>  TO   <field1>    .
                                 IF sy-subrc = 0 .
                                   ASSIGN <field1>->* TO <field1> .
                                   errormessage = <field1> .
                                 ENDIF.
                               ENDIF.
                             ENDIF.
                           ENDIF.
                         ENDLOOP.
                       ENDIF.
                     ENDIF.
                   ENDIF.
                 ENDIF.
               ENDLOOP.
             ENDIF.
           ENDIF.
         ENDIF.
       ENDIF.

       zgst_recon_data-templateid       =  '60e5613ff71f4a7aeca4336b' .
       zgst_recon_data-document_type         =  doc_typ .
       zgst_recon_data-documentdate     =  iv-postingdate .
       zgst_recon_data-documentnumber   =  iv-accountingdocument.
       zgst_recon_data-itemdescription  =  iv-doc_item.
       zgst_recon_data-erpsource        =  'SAP' .
       zgst_recon_data-fiscalyear       =  wa_gst-fiscalyear.
       zgst_recon_data-companycode      =  iv-companycode.
       zgst_recon_data-businessplace    =  iv-businessplace.
       IF iv-igst_amt IS NOT INITIAL.
         zgst_recon_data-igstrate         = iv-igst_rate .   "iv-taxrate
         zgst_recon_data-igstamount       =  iv-igst_amt.
       ELSE.
         zgst_recon_data-cgstrate         =  iv-cgst_rate.  "iv-taxrate
         zgst_recon_data-cgstamount       =  iv-Cgst_amt.
         zgst_recon_data-sgstrate         =  iv-sgst_rate.    "iv-taxrate
         zgst_recon_data-sgstamount       =  iv-sgst_amt.
       ENDIF.
       zgst_recon_data-itemtaxableamount =   iv-taxable_amt.
       zgst_recon_data-documenttotalamount = tot_sum.
       zgst_recon_data-customer_gstin   =  gstno.
       zgst_recon_data-supp_gstin       =  iv-sup_gst.
       zgst_recon_data-supplier_name    =  iv-SupplierName.
       zgst_recon_data-supplier_address =  iv-SupplierFullName.
       zgst_recon_data-vouchernumber    =  iv-documentreferenceid  .
       zgst_recon_data-voucherdate      =  iv-postingdate  .
       zgst_recon_data-error_message    =  errormessage .
       zgst_recon_data-importbillnumber =  iv-accountingdocument.
       zgst_recon_data-importbilldate   =  iv-postingdate .
       zgst_recon_data-importtype =  imptype.
       zgst_recon_data-importportcode =  impportcd.
       zgst_recon_data-sales_purchase =  'Purchase'.
       zgst_recon_data-plant =  iv-Plant .



       IF errormessage IS NOT INITIAL.
         zgst_recon_data-success_indctr = 'E' .
         fail = fail + 1.
       ELSE.
         zgst_recon_data-success_indctr = 'S' .
         success = success + 1.
       ENDIF.

       MODIFY zgst_recon_data FROM @zgst_recon_data .
       CLEAR : iv, errormessage, zgst_recon_data, gst_cs_rate, gst_igst_rate, zero_tax, compo, impbillnumber,impbilldate,impportcd,imptype.
       DELETE gstr2 WHERE accountingdocument = wa_hdr-accountingdocument.
     ENDLOOP.

     IF gstno IS INITIAL.
       gstrecon_pur = | Business Place is missing | .
     ELSE.
       gstrecon_pur = |Total { records } Documents, where { success } Documents Pushed Suscessfully and { fail } Failed | .
     ENDIF.

   ENDMETHOD.


   METHOD if_oo_adt_classrun~main.

     DATA: vbeln1 TYPE string.
     TRY.
*        DATA(return_data) = gstr_pur(  datefrom = '01/11/2022'  dateto = '30/11/2022' companycode = '1000' gstno = '08AAICR3451R1ZP' ).
     ENDTRY.

   ENDMETHOD.
ENDCLASS.
