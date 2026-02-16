 CLASS zgstr1_recon_class DEFINITION
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

       gst_recon
         IMPORTING vbeln1          TYPE string OPTIONAL
                   datefrom        TYPE string
                   dateto          TYPE string
                   companycode     TYPE string
                   gstno           TYPE string
         RETURNING VALUE(gstrecon) TYPE string.


   PROTECTED SECTION.
   PRIVATE SECTION.
ENDCLASS.



CLASS ZGSTR1_RECON_CLASS IMPLEMENTATION.


   METHOD create_client.
     DATA(dest) = cl_http_destination_provider=>create_by_url( url ).
     result = cl_web_http_client_manager=>create_by_http_destination( dest ).
   ENDMETHOD.


   METHOD gst_recon.

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
     DATA  expbillnumber        TYPE char10 .
     DATA  expbilldate          TYPE char10 .
     DATA  exptype              TYPE string.
     DATA  expportcd            TYPE string.

     DATA: lr_str TYPE REF TO data.



     DATA gv_from TYPE sy-datum .
     DATA gv_to TYPE sy-datum .
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


     """" ALL GST REPORTS DATA IN ONE INTERNAL TABLE


     SELECT * FROM ZGSTR_RECON_SALES_CDS   WITH PRIVILEGED ACCESS
         WHERE postingdate BETWEEN @gv_from AND @gv_to
         AND companycode   = @companycode
         AND businessplace = @b_place
         INTO TABLE @DATA(gstr1) .


     """""""""""  Seller Address
     READ TABLE gstr1 INTO DATA(wa_bill) INDEX 1.

     SELECT SINGLE  FROM zsd_plant_address WITH PRIVILEGED ACCESS AS a
     FIELDS
     a~plantname,
     a~plant
     WHERE
      a~plant = @wa_bill-Plant
      INTO @DATA(sellerplantaddress) .


     """""""""""  Buyer Address
     SELECT SINGLE  FROM   i_billingdocumentpartner WITH PRIVILEGED ACCESS  AS a
        INNER JOIN i_customer WITH PRIVILEGED ACCESS AS b ON   ( a~customer = b~customer  )
        LEFT outer join I_Address_2 WITH PRIVILEGED ACCESS as c on ( c~AddressID = b~AddressID )
         FIELDS
         a~billingdocument ,
         b~taxnumber3,
         c~AddresseeFullName,
         c~Region
          WHERE a~billingdocument = @wa_bill-billingdocument
               AND a~partnerfunction = 'RE' INTO  @DATA(buyeradd)   .


     """"""" BILL HEADER DATA

     SELECT  FROM i_billingdocumentbasic WITH PRIVILEGED ACCESS AS a
     FIELDS
            a~billingdocument,
            a~sddocumentcategory,
            a~billingdocumenttype

     FOR ALL ENTRIES IN @gstr1
     WHERE billingdocument = @gstr1-billingdocument
     INTO TABLE @DATA(it_billhed) .

     """"" UNIT CONVERT
     SELECT FROM i_unitofmeasure WITH PRIVILEGED ACCESS  AS a
         FIELDS
         a~unitofmeasure ,
         a~unitofmeasure_e

         FOR ALL ENTRIES IN @gstr1
         WHERE a~unitofmeasure = @gstr1-BaseUnit
         INTO TABLE @DATA(it_unit).

     """""""""" BUYER ADDRESS
     SELECT   FROM  i_billingdocumentpartner WITH PRIVILEGED ACCESS AS a
                   INNER JOIN i_customer AS b ON   ( a~customer = b~customer  )
                 FIELDS
                 a~customer ,
                 a~billingdocument ,
                 b~customerfullname ,
                 b~customername ,
                 b~region ,
                 b~taxnumber3

                 FOR ALL ENTRIES IN @gstr1
                 WHERE a~billingdocument = @gstr1-billingdocument
                 AND a~partnerfunction = 'RE' INTO TABLE  @DATA(it_buyeradd1)   .


     SELECT  FROM   i_operationalacctgdocitem WITH PRIVILEGED ACCESS AS a
                INNER JOIN i_customer AS b ON   ( a~customer = b~customer  )
                 FIELDS
                 a~accountingdocument ,
                a~fiscalyear,
                a~companycode ,
               a~customer ,
               a~billingdocument ,
               b~customerfullname ,
               b~customername ,
               b~region ,
               b~taxnumber3

               FOR ALL ENTRIES IN @gstr1
                WHERE a~accountingdocument = @gstr1-accountingdocument
                  AND a~fiscalyear         = @gstr1-fiscalyear
                  AND a~companycode        =  @gstr1-companycode
                  INTO TABLE @DATA(it_buyeraddnew).



     """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

     SORT gstr1 ASCENDING BY CompanyCode FiscalYear AccountingDocument doc_item .

     DATA(gstr_hdr) = gstr1.
     DATA(line_item) = gstr1.

     SORT gstr_hdr ASCENDING BY accountingdocument.
     DELETE ADJACENT DUPLICATES FROM gstr_hdr COMPARING  accountingdocument.

     SORT gstr_hdr ASCENDING BY billingdocument.


     DATA(records) = lines( gstr1 ) .
     DATA total_data   TYPE i .
     DATA success TYPE i .
     DATA fail    TYPE i .
     DATA tot_sum       TYPE string.
     DATA gst_cs_rate   TYPE P DECIMALS 2.
     DATA gst_igst_rate TYPE P DECIMALS 2.
     DATA item_catgry   TYPE c.
     DATA cancel_doc    TYPE c.
     DATA rcm           TYPE c.
     DATA rec(5)        TYPE c.

     DATA: billno TYPE c LENGTH 10.
     DATA bracketo TYPE string VALUE '{' .
     DATA bracketc TYPE string VALUE '}' .
     DATA lv_xml   TYPE string .
     DATA lv_xml13 TYPE string .
     DATA lv_xml14 TYPE string .

     CLEAR: success,fail,total_data.

     total_data = lines( gstr_hdr ).


     DATA: nr_attribute TYPE cl_numberrange_objects=>nr_attribute,
           nr_number    TYPE cl_numberrange_runtime=>nr_number,
           nrnr         TYPE c LENGTH 2 VALUE '01',
           object       LIKE nr_attribute-object VALUE 'YGROUP_ID2',
           quantity     TYPE n LENGTH 20 VALUE 1.

     DATA num TYPE i .

     DATA inv TYPE string .


     """""" HEADER LOOP
     LOOP AT gstr_hdr INTO DATA(wa_hdr).

       DATA(sddocumentcategory) = VALUE #( it_billhed[ billingdocument = wa_hdr-billingdocument ]-sddocumentcategory OPTIONAL ) .
       DATA(billingdocumenttype) = VALUE #( it_billhed[ billingdocument = wa_hdr-billingdocument ]-billingdocumenttype OPTIONAL ) .




       IF wa_hdr-accountingdocumenttype = 'DR' OR wa_hdr-accountingdocumenttype = 'DG' OR wa_hdr-accountingdocumenttype = 'AA'
       OR wa_hdr-accountingdocumenttype = 'SA' OR wa_hdr-accountingdocumenttype = 'DK' OR wa_hdr-accountingdocumenttype = 'SK'.
*    OR wa_hdr-AccountingDocumentType = 'RV'.
         wa_hdr-billingdocument = wa_hdr-accountingdocument.
         DELETE ADJACENT DUPLICATES FROM gstr1 COMPARING accountingdocument doc_item.
       ENDIF.


       """""""""""""Number Range For Group Id""""""""""""""""""""""
       TRY.
           CALL METHOD cl_numberrange_runtime=>number_get
             EXPORTING
               nr_range_nr = nrnr
               object      = object
               quantity    = quantity
             IMPORTING
               number      = nr_number.

         CATCH cx_nr_object_not_found.
         CATCH cx_number_ranges.
       ENDTRY.
       DATA(grp_id) = |{ |{ nr_number ALPHA = OUT }| ALPHA = IN }|.
       billno = wa_hdr-billingdocument.
       """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
       DATA: fin_json TYPE string,
             tabix    TYPE sy-tabix.

       fin_json = |{ bracketo }"userInputArgs" :{ bracketo }"templateId":"618a5623836651c01c1498ad","groupId":"{ grp_id }| &&
                  |","settings":{ bracketo }"ignoreHsnValidation":true{ bracketc }{ bracketc },"jsonRecords":[ | .


       CLEAR rec.
       """"" LINE ITEM DATA
       LOOP AT gstr1 INTO DATA(iv) WHERE billingdocument = wa_hdr-billingdocument OR accountingdocument = wa_hdr-billingdocument .

         """"""""""""
         READ TABLE it_buyeradd1 INTO DATA(buyeradd1) WITH KEY billingdocument = iv-billingdocument .
         IF sy-subrc <> 0 .
           READ TABLE it_buyeraddnew INTO DATA(buyeraddnew) WITH KEY accountingdocument = iv-accountingdocument .

           buyeradd1-customerfullname    = buyeraddnew-customerfullname.
           buyeradd1-customername        = buyeraddnew-customername.
           buyeradd1-region              = buyeraddnew-region.
           buyeradd1-taxnumber3          = buyeraddnew-taxnumber3.
         ENDIF.
         """"""""""""

         IF sddocumentcategory = 'O'.
           inv = 'CRN'.
         ELSEIF sddocumentcategory = 'P'.
           inv = 'DBN'.
         ELSEIF sddocumentcategory = 'U'.
           inv = 'PINV'.
         ELSE .
           inv = 'INV'.
         ENDIF .

         """"""""""Goods & Service Indicator
         DATA: len(2) TYPE c .
         len = iv-hsn_code+0(2).
         IF len = '99'.
           item_catgry = 'S'.
         ELSE.
           item_catgry = 'G'.
         ENDIF.
         """""""""""""Cancelled Document Indicator
           cancel_doc = 'N'.

         IF iv-report = 'RCM DOCUMENT'.
           rcm = 'Y'.
         ELSE.
           rcm = 'N'.
         ENDIF.

         DATA(zexp)    = billno+0(1).
         DATA(zplant)  = iv-profitcenter+4(4).
         DATA(zunit) = VALUE #( it_unit[ unitofmeasure = iv-BaseUnit ]-unitofmeasure_e OPTIONAL ) .


         IF iv-accountingdocumenttype = 'DR' OR iv-accountingdocumenttype = 'DG' OR iv-accountingdocumenttype = 'AA'
         OR iv-accountingdocumenttype = 'SA' OR iv-accountingdocumenttype = 'DK' OR iv-accountingdocumenttype = 'SK'.
*    OR iv-AccountingDocumentType = 'RV'.

           """""""""""""""""""""""""""""""
           iv-billingdocument     = iv-accountingdocument.
           iv-BillingDocumentDate = iv-postingdate.
           iv-BillingDocumentItem = iv-doc_item.
         ENDIF.

         CLEAR: tot_sum.
         DATA(lv_tab)  = gstr1 .
         DELETE  lv_tab WHERE billingdocument NE wa_hdr-billingdocument  .
         DATA(tot_items) = lines( lv_tab ) .


         IF iv-accountingdocumenttype = 'DR'
          OR iv-accountingdocumenttype = 'DG'
          OR iv-accountingdocumenttype = 'AA'
          OR iv-accountingdocumenttype = 'SA'
          OR iv-accountingdocumenttype = 'DK'
          OR iv-accountingdocumenttype = 'SK'.

           lv_tab  = gstr1 .
           DELETE  lv_tab WHERE  accountingdocument NE wa_hdr-billingdocument .

         ENDIF.

         """ documentTotalAmount
         iv-josg_amt = abs( iv-josg_amt ).
         iv-jocg_amt = abs( iv-jocg_amt ).
         iv-joig_amt = abs( iv-joig_amt ).
         LOOP AT lv_tab INTO DATA(w_a) WHERE billingdocument = wa_hdr-billingdocument OR accountingdocument = wa_hdr-billingdocument .
           DATA(total_amt)    = abs( w_a-invoice_amt ) .   "+ abs( w_a-josg_amt ) + abs( w_a-jocg_amt ) + abs( w_a-joig_amt ).
           tot_sum =  tot_sum + total_amt .
         ENDLOOP .

         DATA(gv) = |{ iv-postingdate+6(2) }/{ iv-postingdate+4(2) }/{ iv-postingdate+0(4) }| .

         CLEAR total_amt .


"""""""""""""""""""""""""''EXPORT CASE
"""""""""""""""""""""""""""""""""""""""""""""""''EXPORT CASE  LAST CHANGE ON 16.09.2025


 IF wa_hdr-report+0(1)  = 'E'   .

    buyeradd1-region =  '96'      .

  ENDIF .



""""""""FOR TEMP.
IF zunit = 'M2' .

zunit = 'SQM' .

ENDIF.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""""""""
         """""""" CREATE JSON
         rec = rec + 1.
         IF rec NE 1.
           fin_json = fin_json && ','.
         ENDIF.

         fin_json = fin_json &&
             |{ bracketo }"documentType":"{ inv }","documentDate": "{ gv }" ,"documentNumber": "{ billno }",| &&
             |"erpSource":"SAP","voucherNumber":"{ billno  }","voucherDate":"{ gv }",| &&
             |"isBillOfSupply":"N","isReverseCharge":"{ rcm }","isDocumentCancelled":"{ cancel_doc }",| &&
             |"exportType":"{ exptype }","exportBillNumber":"{ expbillnumber }","exportBillDate":"{ expbilldate }","exportPortCode":"{ expportcd }",| &&
             |"supplierName":"{ sellerplantaddress-plantname }","supplierGstin":"{ '08AAFCD5862R018' }","customerName":"{ buyeradd1-customername }","customerAddress":"{ buyeradd1-customerfullname }","customerState":"{ buyeradd1-region }", | &&
             |"customerGstin":"{ buyeradd1-taxnumber3 }","placeOfSupply":"{ buyeradd1-region }",| &&
             | "itemDescription":"{ iv-billingdocumentitem }","itemCategory":"{ item_catgry }",| &&
             |"hsnSacCode":"{ iv-hsn_code }","itemQuantity":{ iv-Quantity },"itemUnitCode":"{ zunit }","itemUnitPrice":{ iv-rATE },"itemDiscount":"0.00","itemTaxableAmount":{ iv-table_value },| &&
             |"cgstRate":{ iv-jocg_rate },"cgstAmount":{ iv-jocg_amt },"sgstRate":{ iv-josg_rate },"sgstAmount":{ iv-josg_amt },"igstRate":{ IV-joig_rate },"igstAmount":{ iv-joig_amt },"cessRate":0,"cessAmount":0, | &&
             |"documentTotalAmount":{ tot_sum } { bracketc } | .

       ENDLOOP.
       fin_json = fin_json && |]{ bracketc }|.


       """" DATA PUSH ON PORTAL
       DATA(status1)  =  ycl_gst_recon_api=>postclear_tax( json =  fin_json gstin = |{ gstno }| billingdocument = |{ billno }| ) .




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

       zgst_recon_data-templateid       =  '618a5623836651c01c1498ad' .
       zgst_recon_data-groupid          =  grp_id .
       zgst_recon_data-documenttype     = 'Invoice' .
       zgst_recon_data-documentdate     =  iv-postingdate .
       zgst_recon_data-documentnumber   = iv-billingdocument  .
       zgst_recon_data-erpsource        = 'SAP' .
       zgst_recon_data-vouchernumber    = iv-billingdocument  .
       zgst_recon_data-voucherdate      = iv-postingdate .
       zgst_recon_data-responce         = errormessage .

       zgst_recon_data-fiscalyear       =  wa_bill-fiscalyear.
       zgst_recon_data-companycode      =  iv-companycode.
       zgst_recon_data-businessplace    =  iv-businessplace.
       zgst_recon_data-igstrate         =  IV-joig_rate.
       zgst_recon_data-igstamount       =  iv-joig_amt.
       zgst_recon_data-cgstrate         =  iv-jocg_rate.
       zgst_recon_data-cgstamount       =  iv-jocg_amt.
       zgst_recon_data-sgstrate         =  iv-josg_rate.
       zgst_recon_data-sgstamount       =  iv-josg_amt .
       zgst_recon_data-itemtaxableamount = iv-table_value.
       zgst_recon_data-documenttotalamount = tot_sum.
       zgst_recon_data-customer_gstin   =  buyeradd-taxnumber3.
       zgst_recon_data-customername   = iv-CustomerName .
       zgst_recon_data-customeraddress = buyeradd-AddresseeFullName.
       zgst_recon_data-customerstate   =  buyeradd-Region.
       zgst_recon_data-supp_gstin       =  gstno .
       zgst_recon_data-sales_purchase =  'Sales'.
       zgst_recon_data-supplier_name    =  sellerplantaddress-plantname.
       zgst_recon_data-hsnsaccode  = iv-hsn_code.
       zgst_recon_data-placeofsupply = buyeradd1-region .


       IF errormessage IS NOT INITIAL.
         zgst_recon_data-success_indctr = 'E' .
         fail = fail + 1.
       ELSE.
         zgst_recon_data-success_indctr = 'S' .
         success = success + 1.
       ENDIF.

       MODIFY zgst_recon_data FROM @zgst_recon_data .
       CLEAR : iv, errormessage, zgst_recon_data, buyeradd1 ,inv,sddocumentcategory,billingdocumenttype,
                exptype, expbilldate, expbillnumber, expportcd , tot_sum.
       gstr1 = line_item.
       DELETE gstr1 WHERE accountingdocument = wa_hdr-accountingdocument.

     ENDLOOP.

     gstrecon = |Total { total_data } Documents, where { success } Documents Pushed Suscessfully and { fail } Failed | .

   ENDMETHOD.


   METHOD if_oo_adt_classrun~main.

     TRY.
         DATA(return_data) = gst_recon(  datefrom = '2025-09-01'  dateto = '2026-01-09' companycode = '' gstno = '' ).
     ENDTRY.

   ENDMETHOD.
ENDCLASS.
