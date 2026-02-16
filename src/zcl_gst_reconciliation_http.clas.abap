class ZCL_GST_RECONCILIATION_HTTP definition
  public
  create public .

public section.

  interfaces IF_HTTP_SERVICE_EXTENSION .
protected section.
private section.
ENDCLASS.



CLASS ZCL_GST_RECONCILIATION_HTTP IMPLEMENTATION.


  method IF_HTTP_SERVICE_EXTENSION~HANDLE_REQUEST.



    DATA(req) = request->get_form_fields(  ).

    DATA companycode TYPE string.
    DATA datefrom    TYPE string.
    DATA dateto      TYPE string.
    DATA gstno       TYPE string.
    DATA vbeln1      TYPE string.
    DATA selection   TYPE string.

    companycode = VALUE #( req[ name = 'companycode' ]-value OPTIONAL ) .
    datefrom = VALUE #( req[ name = 'datefrom' ]-value OPTIONAL ) .
    dateto = VALUE #( req[ name = 'dateto' ]-value OPTIONAL ) .
    gstno = VALUE #( req[ name = 'gstno' ]-value OPTIONAL ) .
    vbeln1 = VALUE #( req[ name = 'vbeln1' ]-value OPTIONAL ) .
    selection = VALUE #( req[ name = 'selection' ]-value OPTIONAL ) .

    IF ( selection = 'Sales' ) .

      DATA(review)  =  zgstr1_recon_class=>gst_recon( datefrom  = datefrom
                                                    dateto    = dateto
                                                    companycode  = companycode
                                                    gstno = gstno ) .


      response->set_text( review ).

    ELSEIF ( selection = 'Purchase' ) .

      DATA(pur)  =  ygstr_recon_pur=>gstr_pur( datefrom  = datefrom
                                               dateto  = dateto
                                               companycode  = companycode
                                               gstno = gstno
                                               vbeln1 = ''
                                                ) .
      response->set_text( pur ).

    ENDIF.



  endmethod.
ENDCLASS.
