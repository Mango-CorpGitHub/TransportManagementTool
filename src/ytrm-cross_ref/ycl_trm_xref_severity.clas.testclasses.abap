*"* use this source file for your ABAP unit test classes

CLASS ltc_severity DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO ycl_trm_xref_severity.

    METHODS setup.
    METHODS assert_status
      IMPORTING iv_status TYPE yif_trm_cross_reference=>ty_e_status
                iv_text   TYPE string.

    METHODS checked_statuses  FOR TESTING.
    METHODS green_statuses    FOR TESTING.
    METHODS yellow_statuses   FOR TESTING.
    METHODS red_statuses      FOR TESTING.
    METHODS internal_statuses FOR TESTING.
    METHODS unknown_status    FOR TESTING.
ENDCLASS.


CLASS ltc_severity IMPLEMENTATION.

  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.


  METHOD assert_status.
    cl_abap_unit_assert=>assert_equals( exp = iv_text
                                        act = cut->to_text( cut->of_status( iv_status ) )
                                        msg = |{ iv_status }| ).
  ENDMETHOD.


  METHOD checked_statuses.
    assert_status( iv_status = yif_trm_cross_reference=>c_status-also_in_transport_request
                   iv_text   = ycl_trm_xref_severity=>c_text-checked ).
    assert_status( iv_status = yif_trm_cross_reference=>c_status-sap_reference
                   iv_text   = ycl_trm_xref_severity=>c_text-checked ).
  ENDMETHOD.


  METHOD green_statuses.
    assert_status( iv_status = yif_trm_cross_reference=>c_status-equal_in_destination
                   iv_text   = ycl_trm_xref_severity=>c_text-green ).
    assert_status( iv_status = yif_trm_cross_reference=>c_status-exist_in_destination
                   iv_text   = ycl_trm_xref_severity=>c_text-green ).
    assert_status( iv_status = yif_trm_cross_reference=>c_status-different_but_not_relevant
                   iv_text   = ycl_trm_xref_severity=>c_text-green ).
    assert_status( iv_status = yif_trm_cross_reference=>c_status-definition_also_in_trans_req
                   iv_text   = ycl_trm_xref_severity=>c_text-green ).
  ENDMETHOD.


  METHOD yellow_statuses.
    assert_status( iv_status = yif_trm_cross_reference=>c_status-different_in_destination
                   iv_text   = ycl_trm_xref_severity=>c_text-yellow ).
    assert_status( iv_status = yif_trm_cross_reference=>c_status-method_definition_dif_in_dest
                   iv_text   = ycl_trm_xref_severity=>c_text-yellow ).
  ENDMETHOD.


  METHOD red_statuses.
    assert_status( iv_status = yif_trm_cross_reference=>c_status-method_def_dif_in_dest_w_err
                   iv_text   = ycl_trm_xref_severity=>c_text-red ).
    assert_status( iv_status = yif_trm_cross_reference=>c_status-only_in_source
                   iv_text   = ycl_trm_xref_severity=>c_text-red ).
    assert_status( iv_status = yif_trm_cross_reference=>c_status-different
                   iv_text   = ycl_trm_xref_severity=>c_text-red ).
    assert_status( iv_status = yif_trm_cross_reference=>c_status-definition_missing
                   iv_text   = ycl_trm_xref_severity=>c_text-red ).
  ENDMETHOD.


  METHOD internal_statuses.
    assert_status( iv_status = yif_trm_cross_reference=>c_status-subobject_not_assigned
                   iv_text   = ycl_trm_xref_severity=>c_text-internal ).
    assert_status( iv_status = yif_trm_cross_reference=>c_status-to_delete
                   iv_text   = ycl_trm_xref_severity=>c_text-internal ).
  ENDMETHOD.


  METHOD unknown_status.
    cl_abap_unit_assert=>assert_initial( cut->of_status( 'Unknown' ) ).
    cl_abap_unit_assert=>assert_initial( cut->to_text( CONV #( icon_display ) ) ).
  ENDMETHOD.

ENDCLASS.
