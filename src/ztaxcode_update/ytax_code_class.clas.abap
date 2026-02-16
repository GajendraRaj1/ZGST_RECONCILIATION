CLASS ytax_code_class DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
     INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS YTAX_CODE_CLASS IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
 data: lt_tax_codes type table of ytax_code2.
*    delete from ytax_code2.
    lt_tax_codes = value #(

      ( taxcode =   'V8' taxcodedescription = 'IN : 28% IGST'                                     gstrate = '28'    )
      ( taxcode =   'V7' taxcodedescription = 'IN : 18% IGST'                                     gstrate = '18'    )
      ( taxcode =   'V6' taxcodedescription = 'IN : 12% IGST'                                     gstrate = '12'   )
      ( taxcode =   'V5' taxcodedescription = 'IN : 5% IGST'                                      gstrate = '5'   )
      ( taxcode =   'V4' taxcodedescription = 'IN : CGST 14% & SGST 14%'                          gstrate = '14'   )
      ( taxcode =   'V3' taxcodedescription = 'IN : CGST 9 % & SGST 9%'                           gstrate = '9'    )
      ( taxcode =   'V2' taxcodedescription = 'IN : CGST 6% & SGST 6%'                            gstrate = '6'    )
      ( taxcode =   'V1' taxcodedescription = 'IN : CGST 2.5% & SGST 2.5%'                        gstrate = '2.5'  )
      ( taxcode =   'V0' taxcodedescription = 'IN: 0% Tax rate'                                   gstrate = '0'    )

      ( taxcode =   'VA' taxcodedescription = 'IN : CGST 1.5 % & SGST 1.5 %'                      gstrate = '1.5'   )
      ( taxcode =   'VB' taxcodedescription = 'IN : 3% IGST'                                      gstrate = '3'    )

      ( taxcode =   'I1' taxcodedescription = 'IMPORT 5 %( IGST)'                                 gstrate = '5'   )
      ( taxcode =   'I2' taxcodedescription = 'IMPORT 12 %( IGST)'                                gstrate = '12'  )
      ( taxcode =   'I3' taxcodedescription = 'IMPORT 18 %( IGST)'                                gstrate = '18'    )
      ( taxcode =   'I4' taxcodedescription = 'IMPORT 28 %( IGST)'                                gstrate = '28'    )

      ( taxcode =   'R1' taxcodedescription = 'RCM 2.5% CGST & 2.5% SGST'                         gstrate = '2.5'   )
      ( taxcode =   'R2' taxcodedescription = 'RCM 6% CGST & 6% SGST'                             gstrate = '6'     )
      ( taxcode =   'R3' taxcodedescription = 'RCM 9% CGST & 9% SGST'                             gstrate = '9'     )
      ( taxcode =   'R4' taxcodedescription = 'RCM 14% CGST & 14% SGST'                           gstrate = '14'    )
      ( taxcode =   'R5' taxcodedescription = 'IN : 5% IGST  RCM'                                 gstrate = '5'     )
      ( taxcode =   'R6' taxcodedescription = 'IN : 12% IGST  RCM'                                gstrate = '12'     )
      ( taxcode =   'R7' taxcodedescription = 'IN : 18% IGST  RCM'                                gstrate = '18'    )
      ( taxcode =   'R8' taxcodedescription = 'IN : 28% IGST  RCM'                                gstrate = '28'    )
      ( taxcode =   'R9' taxcodedescription = 'RCM IGST 28%'                                      gstrate = '28'    )

      ( taxcode =   'N1' taxcodedescription = 'IN : 2.5% CGST & 2.5% SGST( NON ELIGIBLE)'         gstrate = '2.5'   )
      ( taxcode =   'N2' taxcodedescription = 'IN : 6% CGST & 6% SGST( NON ELIGIBLE)'             gstrate = '6'   )
      ( taxcode =   'N3' taxcodedescription = 'IN : 9% CGST & 9% SGST( NON ELIGIBLE)'             gstrate = '9'     )
      ( taxcode =   'N4' taxcodedescription = 'IN : 14% CGST & 14% SGST( NON ELIGIBLE)'           gstrate = '14'     )
      ( taxcode =   'N5' taxcodedescription = 'IN : 5% IGST(NCM NON ELIGIBLE)'                    gstrate = '5'     )
      ( taxcode =   'N6' taxcodedescription = 'IN : 12% IGST(NCM NON ELIGIBLE)'                   gstrate = '12'     )
      ( taxcode =   'N7' taxcodedescription = 'IN : 18% IGST(NCM NON ELIGIBLE)'                   gstrate = '18'    )
      ( taxcode =   'N8' taxcodedescription = 'IN : 28% IGST(NCM NON ELIGIBLE)'                   gstrate = '28'    )

      ( taxcode =   'M1' taxcodedescription = 'IN : 2.5% CGST & 2.5% SGST(RCM NON ELIGIBLE)'      gstrate = '2.5'   )
      ( taxcode =   'M2' taxcodedescription = 'IN : 6% CGST & 6% SGST(RCM NON ELIGIBLE)'          gstrate = '6'     )
      ( taxcode =   'M3' taxcodedescription = 'IN : 9% CGST & 9% SGST(RCM NON ELIGIBLE)'          gstrate = '9'   )
      ( taxcode =   'M4' taxcodedescription = 'IN : 14% CGST & 14% SGST(RCM NON ELIGIBLE)'        gstrate = '14'   )
      ( taxcode =   'M5' taxcodedescription = 'IN : 5% IGST(RCM NON ELIGIBLE)'                    gstrate = '5'     )
      ( taxcode =   'M6' taxcodedescription = 'IN : 12% IGST(RCM NON ELIGIBLE)'                   gstrate = '12'   )
      ( taxcode =   'M7' taxcodedescription = 'IN : 18% IGST(RCM NON ELIGIBLE)'                   gstrate = '18'   )
      ( taxcode =   'M8' taxcodedescription = 'IN : 28% IGST(RCM NON ELIGIBLE)'                   gstrate = '28'   )


      ( taxcode =   'A0' taxcodedescription = '0% OUTPUT TAX (CGST+SGST)'                         gstrate = '0'    )
      ( taxcode =   'A1' taxcodedescription = 'SALES OUTPUT (2.5 % CGST+ 2.5% SGST)'              gstrate = '2.5'    )
      ( taxcode =   'A2' taxcodedescription = 'SALES OUTPUT (6% CGST+ 6% SGST)'                   gstrate = '6'  )
      ( taxcode =   'A3' taxcodedescription = 'SALES OUTPUT (9% CGST+ 9% SGST)'                   gstrate = '9'    )
      ( taxcode =   'A4' taxcodedescription = 'SALES OUTPUT (14% CGST+14% SGST)'                  gstrate = '14'  )
      ( taxcode =   'A5' taxcodedescription = 'SALES OUTPUT 5% (IGST)'                            gstrate = '5'    )
      ( taxcode =   'A6' taxcodedescription = 'SALES OUTPUT 12% (IGST)'                           gstrate = '12'    )
      ( taxcode =   'A7' taxcodedescription = 'SALES OUTPUT 18 %( IGST)'                          gstrate = '18'   )
      ( taxcode =   'A8' taxcodedescription = 'SALES OUTPUT 28 %( IGST)'                          gstrate = '28'    )

      ( taxcode =   'B1' taxcodedescription = 'SALES Export : 5% (IGST)'                          gstrate = '5'   )
      ( taxcode =   'B2' taxcodedescription = 'SALES Export: 12% (IGST)'                          gstrate = '12'   )
      ( taxcode =   'B3' taxcodedescription = 'SALES Export: 18%( IGST)'                          gstrate = '18'   )
      ( taxcode =   'B4' taxcodedescription = 'SALES Export: 28% (IGST)'                          gstrate = '28'  )
      ( taxcode =   'B0' taxcodedescription = '0% OUTPUT TAX Export (IGST)'                       gstrate = '0'  )

      ).

      MODIFY ytax_code2 from table @lt_tax_codes.
 ENDMETHOD.
ENDCLASS.
