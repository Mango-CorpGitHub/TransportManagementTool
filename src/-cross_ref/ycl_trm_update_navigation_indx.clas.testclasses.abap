*"* use this source file for your ABAP unit test classes

CLASS ltd_wb_index DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES yif_trm_xref_wb_index.

    TYPES ty_t_programs TYPE STANDARD TABLE OF program WITH EMPTY KEY.

    DATA class_includes TYPE seoincl_t.
    DATA actualized     TYPE ty_t_programs.

ENDCLASS.


CLASS ltd_wb_index IMPLEMENTATION.

  METHOD yif_trm_xref_wb_index~get_class_includes.
    rt_includes = class_includes.
  ENDMETHOD.

  METHOD yif_trm_xref_wb_index~actualize.
    INSERT iv_program INTO TABLE actualized.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_update DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS c_class TYPE trobj_name VALUE 'ZCL_TRM_TEST'.

    DATA cut      TYPE REF TO ycl_trm_update_navigation_indx.
    DATA wb_index TYPE REF TO ltd_wb_index.

    METHODS setup.

    METHODS class_updates_all_includes    FOR TESTING RAISING cx_static_check.
    METHODS method_updates_class_includes FOR TESTING RAISING cx_static_check.
    METHODS interface_updates_intf_pool   FOR TESTING RAISING cx_static_check.
    METHODS include_updated_once          FOR TESTING RAISING cx_static_check.

    METHODS method_name
      IMPORTING iv_method      TYPE csequence
      RETURNING VALUE(rv_name) TYPE trobj_name.

    METHODS expected_class_programs
      RETURNING VALUE(rt_programs) TYPE ltd_wb_index=>ty_t_programs.

ENDCLASS.


CLASS ltc_update IMPLEMENTATION.

  METHOD setup.
    wb_index = NEW #( ).
    wb_index->class_includes = VALUE #( ( 'ZCL_TRM_TEST==================CU' )
                                        ( 'ZCL_TRM_TEST==================CI' ) ).

    cut = NEW #( wb_index ).
  ENDMETHOD.

  METHOD class_updates_all_includes.
    cut->update( VALUE #( ( pgmid = 'R3TR' obj_type = 'CLAS' obj_name = c_class ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = expected_class_programs( )
                                        act = wb_index->actualized ).
  ENDMETHOD.

  METHOD method_updates_class_includes.
    cut->update( VALUE #( ( pgmid = 'LIMU' obj_type = 'METH' obj_name = method_name( 'DO_IT' ) ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = expected_class_programs( )
                                        act = wb_index->actualized ).
  ENDMETHOD.

  METHOD interface_updates_intf_pool.
    cut->update( VALUE #( ( pgmid = 'R3TR' obj_type = 'INTF' obj_name = 'ZIF_TRM_TEST' ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = VALUE ltd_wb_index=>ty_t_programs( ( 'CP_ZIF_TRM_TEST' ) )
                                        act = wb_index->actualized ).
  ENDMETHOD.

  METHOD include_updated_once.
    cut->update( VALUE #( ( pgmid = 'LIMU' obj_type = 'METH' obj_name = method_name( 'DO_IT' ) )
                          ( pgmid = 'LIMU' obj_type = 'METH' obj_name = method_name( 'DO_OTHER' ) ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = expected_class_programs( )
                                        act = wb_index->actualized ).
  ENDMETHOD.

  METHOD method_name.
    rv_name = c_class.
    rv_name+30 = iv_method.
  ENDMETHOD.

  METHOD expected_class_programs.
    rt_programs = VALUE #( ( 'CP_ZCL_TRM_TEST==================CU' )
                           ( 'CP_ZCL_TRM_TEST==================CI' ) ).
  ENDMETHOD.

ENDCLASS.
