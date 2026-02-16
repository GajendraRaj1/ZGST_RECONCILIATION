CLASS ycl_gst_recon_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .
  PUBLIC SECTION.
    CLASS-DATA : access_token TYPE string .
    CLASS-METHODS :
      postclear_tax
        IMPORTING
                  gstin           TYPE string
                  json            TYPE string
                  billingdocument TYPE string
        RETURNING VALUE(status1)  TYPE  string  ,

      create_client2
        IMPORTING url           TYPE string
        RETURNING VALUE(result) TYPE REF TO if_web_http_client
        RAISING   cx_static_check,
      create_client
        IMPORTING url           TYPE string
        RETURNING VALUE(result) TYPE REF TO if_web_http_client
        RAISING   cx_static_check .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS YCL_GST_RECON_API IMPLEMENTATION.


  METHOD create_client.

    DATA(dest) = cl_http_destination_provider=>create_by_url( url ).
    result = cl_web_http_client_manager=>create_by_http_destination( dest ).

  ENDMETHOD.


  METHOD create_client2.

    DATA(dest) = cl_http_destination_provider=>create_by_url( url ).
    result = cl_web_http_client_manager=>create_by_http_destination( dest ).

  ENDMETHOD.


  METHOD postclear_tax.

    DATA: uuid      TYPE string.
    DATA: password  TYPE string.
    DATA: user_name TYPE string.

    uuid = cl_system_uuid=>create_uuid_x16_static(  ).
    IF sy-sysid = 'APU'." OR sy-sysid = 'JUE'.
      DATA : ewaylink  TYPE  string VALUE 'https://api-sandbox.clear.in/integration/v2/ingest/json/sales'  .
      DATA(url) = |{ ewaylink }|.
      DATA(client) = create_client2( url ).
      DATA(req) = client->get_http_request(  ).
       req->set_header_field( i_name = 'X-Cleartax-Auth-Token'  i_value = 'sandbox.3.5738e9ea-eb42-4de5-b655-441c3257d8cd_407fff02f259aff5d11edfce4d5904f986b6a700bb4ac6c085a572bf74736217' ) .

      req->set_header_field( i_name = 'x-cleartax-gstin'    i_value = '08AAFCD5862R018' ).    " gstin
      req->set_content_type( 'application/json' ).
      req->set_header_field( i_name = 'requestid' i_value = uuid ).
      req->set_header_field( i_name = 'Authorization' i_value = access_token ).
      req->set_text( json ) .

      status1 = client->execute( if_web_http_client=>post )->get_text( ).

      client->close(  )  .

    ELSE.

      ewaylink =  'https://api.clear.in/integration/v2/ingest/json/sales'  .
      url = |{ ewaylink }|.
      client = create_client2( url ).
      req = client->get_http_request(  ).
*      req->set_header_field( i_name = 'X-Cleartax-Auth-Token'  i_value = '3.590fac9c-020e-43e2-a587-3514052a2888_217165e78656c59b70be5dc45a244a8e076b9a0d3ad45ed4c71c35cbfd842643' ) .
      req->set_header_field( i_name = 'x-cleartax-gstin'    i_value = gstin ).
      req->set_content_type( 'application/json' ).
      req->set_header_field( i_name = 'requestid' i_value = uuid ).
      req->set_header_field( i_name = 'Authorization' i_value = access_token ).
      req->set_text( json ) .

      status1 = client->execute( if_web_http_client=>post )->get_text( ).

      client->close(  )  .

    ENDIF.
  ENDMETHOD.
ENDCLASS.
