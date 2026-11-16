*"* use this source file for your ABAP unit test classes

"! Reads objects of the package YTRM in the local system (only read accesses)
CLASS ltc_local_system DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO yif_trm_xref_system.

    METHODS setup.

    METHODS table_existing_returns_fields FOR TESTING RAISING cx_static_check.
    METHODS table_missing_raises          FOR TESTING RAISING cx_static_check.
    METHODS cds_existing_returns_fields   FOR TESTING RAISING cx_static_check.
    METHODS cds_missing_raises            FOR TESTING RAISING cx_static_check.
    METHODS class_described_by_type       FOR TESTING RAISING cx_static_check.
    METHODS interface_described_by_type   FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_local_system IMPLEMENTATION.

  METHOD setup.
    cut = NEW ycl_trm_cross_ref_describe_obj( 'NONE' ).
  ENDMETHOD.

  METHOD table_existing_returns_fields.
    DATA(ls_description) = cut->describe_table( 'YTRM_S_DESCR_ATRB' ).

    cl_abap_unit_assert=>assert_true(
        xsdbool( line_exists( ls_description-fields[ fieldname = 'SUB_OBJECT_NAME' ] ) ) ).
  ENDMETHOD.

  METHOD table_missing_raises.
    TRY.
        cut->describe_table( 'YTRM_S_NOT_EXISTING' ).
        cl_abap_unit_assert=>fail( 'Exception expected' ).
      CATCH ycx_trm_cross_reference INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_bound( lx_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD cds_existing_returns_fields.
    DATA(ls_description) = cut->describe_cds( 'YC_TRANSPORTREQUEST' ).

    cl_abap_unit_assert=>assert_not_initial( ls_description-fields ).
  ENDMETHOD.

  METHOD cds_missing_raises.
    TRY.
        cut->describe_cds( 'YC_NOT_EXISTING_CDS' ).
        cl_abap_unit_assert=>fail( 'Exception expected' ).
      CATCH ycx_trm_cross_reference INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_bound( lx_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD class_described_by_type.
    DATA(lt_description) = cut->describe( 'YCL_TRM_LOGGER' ).

    cl_abap_unit_assert=>assert_true(
        xsdbool( line_exists( lt_description[ sub_object_type = 'METH' sub_object_name = 'NEW' ] ) ) ).
  ENDMETHOD.

  METHOD interface_described_by_type.
    DATA(lt_description) = cut->describe( 'YIF_TRM_LOGGER' ).

    cl_abap_unit_assert=>assert_true(
        xsdbool( line_exists( lt_description[ sub_object_type = 'METH' sub_object_name = 'INFO' ] ) ) ).
  ENDMETHOD.

ENDCLASS.
