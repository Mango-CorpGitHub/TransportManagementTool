*"* use this source file for your ABAP unit test classes

CLASS ltc_run DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO ycl_trm_xref_attribute_descr.

    METHODS setup.

    METHODS constant_structure_flattened FOR TESTING RAISING cx_static_check.
    METHODS simple_constant              FOR TESTING RAISING cx_static_check.
    METHODS unknown_attribute_ignored    FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_run IMPLEMENTATION.

  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD constant_structure_flattened.
    DATA(lt_result) = cut->run( VALUE #( ( object_name     = 'YIF_TRM_TRANSPORT_REQUEST'
                                           sub_object_name = 'STATUS' ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = 'D'
        act = VALUE #( lt_result[ path = 'MODIFIABLE' ]-value OPTIONAL ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = 'YIF_TRM_TRANSPORT_REQUEST'
        act = VALUE #( lt_result[ path = 'MODIFIABLE' ]-object_name OPTIONAL ) ).
  ENDMETHOD.

  METHOD simple_constant.
    DATA(lt_result) = cut->run( VALUE #( ( object_name     = 'YIF_TRM_TRANSPORT_REQUEST'
                                           sub_object_name = 'MESSAGE_CLASS' ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_result ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'YTRM'
                                        act = lt_result[ 1 ]-value ).
  ENDMETHOD.

  METHOD unknown_attribute_ignored.
    DATA(lt_result) = cut->run( VALUE #( ( object_name     = 'YIF_TRM_TRANSPORT_REQUEST'
                                           sub_object_name = 'NOT_EXISTING_ATTRIBUTE' ) ) ).

    cl_abap_unit_assert=>assert_initial( lt_result ).
  ENDMETHOD.

ENDCLASS.
