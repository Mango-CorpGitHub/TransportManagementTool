*"* use this source file for your ABAP unit test classes

CLASS ltd_object DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES yif_trm_tr_object PARTIALLY IMPLEMENTED.

    METHODS constructor
      IMPORTING iv_pgmid    TYPE pgmid
                iv_object   TYPE trobjtype
                iv_obj_name TYPE trobj_name
                iv_objfunc  TYPE objfunc OPTIONAL.

  PRIVATE SECTION.
    DATA pgmid    TYPE pgmid.
    DATA object   TYPE trobjtype.
    DATA obj_name TYPE trobj_name.
    DATA objfunc  TYPE objfunc.
ENDCLASS.


CLASS ltd_object IMPLEMENTATION.
  METHOD constructor.
    pgmid    = iv_pgmid.
    object   = iv_object.
    obj_name = iv_obj_name.
    objfunc  = iv_objfunc.
  ENDMETHOD.

  METHOD yif_trm_tr_object~get_object_id.
    re_object_id = pgmid.
  ENDMETHOD.

  METHOD yif_trm_tr_object~get_object_type.
    re_object_type = object.
  ENDMETHOD.

  METHOD yif_trm_tr_object~get_object_name.
    re_object_name = obj_name.
  ENDMETHOD.

  METHOD yif_trm_tr_object~get_function.
    re_function = objfunc.
  ENDMETHOD.

  METHOD yif_trm_tr_object~get_activity.
    CLEAR re_activity.
  ENDMETHOD.

  METHOD yif_trm_tr_object~get_language.
    CLEAR re_language.
  ENDMETHOD.
ENDCLASS.


CLASS ltd_request DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES yif_trm_transport_request PARTIALLY IMPLEMENTED.

    METHODS constructor
      IMPORTING iv_code    TYPE trkorr
                it_entries TYPE yif_trm_tr_object=>tab.

  PRIVATE SECTION.
    DATA code    TYPE trkorr.
    DATA entries TYPE yif_trm_tr_object=>tab.
ENDCLASS.


CLASS ltd_request IMPLEMENTATION.
  METHOD constructor.
    code    = iv_code.
    entries = it_entries.
  ENDMETHOD.

  METHOD yif_trm_transport_request~get_code.
    re_code = code.
  ENDMETHOD.

  METHOD yif_trm_transport_request~get_entries.
    re_t_entries = entries.
  ENDMETHOD.
ENDCLASS.


CLASS ltd_comparer DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES yif_trm_compare_objects.

    DATA comparison  TYPE yif_trm_compare_objects=>ty_t_comparison.
    DATA messages    TYPE bapiret2_t.
    DATA raise_error TYPE abap_bool.
ENDCLASS.


CLASS ltd_comparer IMPLEMENTATION.
  METHOD yif_trm_compare_objects~compare.
    IF raise_error = abap_true.
      RAISE EXCEPTION NEW ycx_trm_transport_request( textid      = ycx_trm_transport_request=>communication_error
                                                     destination = 'DEST' ).
    ENDIF.
    et_messages   = messages.
    rt_comparison = comparison.
  ENDMETHOD.
ENDCLASS.


CLASS ltd_collisions DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES yif_trm_get_obj_w_collisions.

    DATA collisions        TYPE yif_trm_get_obj_w_collisions=>tyt_colisions.
    DATA received_range    TYPE yif_trm_get_obj_w_collisions=>ty_r_transport_request.
    DATA received_objects  TYPE yif_trm_get_obj_w_collisions=>tyt_objects.
ENDCLASS.


CLASS ltd_collisions IMPLEMENTATION.
  METHOD yif_trm_get_obj_w_collisions~find.
    received_range   = ir_tr_being_transported.
    received_objects = it_objects_being_transported.
    rt_colisions     = collisions.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_overview DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA comparer   TYPE REF TO ltd_comparer.
    DATA collisions TYPE REF TO ltd_collisions.

    METHODS setup.

    METHODS without_comparer           FOR TESTING RAISING cx_static_check.
    METHODS comparison_values          FOR TESTING RAISING cx_static_check.
    METHODS not_compared_reasons       FOR TESTING RAISING cx_static_check.
    METHODS comparer_error_propagates  FOR TESTING RAISING cx_static_check.
    METHODS comparer_messages          FOR TESTING RAISING cx_static_check.
    METHODS collision_on_fragment      FOR TESTING RAISING cx_static_check.
    METHODS collision_on_main_object   FOR TESTING RAISING cx_static_check.
    METHODS default_excluded_requests  FOR TESTING RAISING cx_static_check.
    METHODS explicit_excluded_requests FOR TESTING RAISING cx_static_check.
    METHODS customizing_keys           FOR TESTING RAISING cx_static_check.

    METHODS one_request
      RETURNING VALUE(rt_requests) TYPE yif_trm_transport_request=>tab.

    METHODS comparison_row
      IMPORTING iv_fragment          TYPE trobjtype DEFAULT 'METH'
                iv_fragname          TYPE trobj_name
                iv_pgmid             TYPE pgmid     DEFAULT 'R3TR'
                iv_object            TYPE trobjtype DEFAULT 'CLAS'
                iv_obj_name          TYPE trobj_name DEFAULT 'YCL_A'
                iv_equal             TYPE abap_bool OPTIONAL
                iv_not_comparable    TYPE abap_bool OPTIONAL
                iv_not_compared      TYPE abap_bool OPTIONAL
                iv_objfunc           TYPE char01 OPTIONAL
      RETURNING VALUE(rs_comparison) TYPE yif_trm_compare_objects=>ty_s_comparison.
ENDCLASS.


CLASS ltc_overview IMPLEMENTATION.

  METHOD setup.
    comparer   = NEW #( ).
    collisions = NEW #( ).
  ENDMETHOD.


  METHOD one_request.
    rt_requests = VALUE #( ( NEW ltd_request(
                                 iv_code    = 'S4DK000001'
                                 it_entries = VALUE #( ( NEW ltd_object( iv_pgmid    = 'R3TR'
                                                                         iv_object   = 'CLAS'
                                                                         iv_obj_name = 'YCL_A' ) ) ) ) ) ).
  ENDMETHOD.


  METHOD comparison_row.
    rs_comparison = VALUE #( fragid         = 'LIMU'
                             fragment       = iv_fragment
                             fragname       = iv_fragname
                             pgmid          = iv_pgmid
                             object         = iv_object
                             obj_name       = iv_obj_name
                             equal          = iv_equal
                             not_comparable = iv_not_comparable
                             not_compared   = iv_not_compared
                             objfunc        = iv_objfunc ).
  ENDMETHOD.


  METHOD without_comparer.
    DATA(lt_requests) = VALUE yif_trm_transport_request=>tab(
        ( NEW ltd_request( iv_code    = 'S4DK000001'
                           it_entries = VALUE #( ( NEW ltd_object( iv_pgmid    = 'R3TR'
                                                                   iv_object   = 'PROG'
                                                                   iv_obj_name = 'YB' ) )
                                                 ( NEW ltd_object( iv_pgmid    = 'R3TR'
                                                                   iv_object   = 'CLAS'
                                                                   iv_obj_name = 'YCL_A' ) ) ) ) )
        ( NEW ltd_request( iv_code    = 'S4DK000002'
                           it_entries = VALUE #( ( NEW ltd_object( iv_pgmid    = 'R3TR'
                                                                   iv_object   = 'CLAS'
                                                                   iv_obj_name = 'YCL_A' ) ) ) ) ) ).

    DATA(ls_overview) = NEW ycl_trm_tr_overview( io_collisions = collisions )->get( lt_requests ).

    cl_abap_unit_assert=>assert_false( ls_overview-compared ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( ls_overview-entries ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'CLAS'
                                        act = ls_overview-entries[ 1 ]-object ).
    cl_abap_unit_assert=>assert_equals( exp = ycl_trm_tr_overview=>c_comparison-not_requested
                                        act = ls_overview-entries[ 1 ]-comparison ).
    cl_abap_unit_assert=>assert_equals(
        exp = VALUE ycl_trm_tr_overview=>ty_t_trkorr( ( 'S4DK000001' ) ( 'S4DK000002' ) )
        act = ls_overview-entries[ 1 ]-requests ).
    cl_abap_unit_assert=>assert_equals(
        exp = VALUE ycl_trm_tr_overview=>ty_t_trkorr( ( 'S4DK000001' ) )
        act = ls_overview-entries[ 2 ]-requests ).
  ENDMETHOD.


  METHOD comparison_values.
    comparer->comparison = VALUE #( ( comparison_row( iv_fragname = 'NEW' iv_not_comparable = abap_true ) )
                                    ( comparison_row( iv_fragname = 'EQUAL' iv_equal = abap_true ) )
                                    ( comparison_row( iv_fragname = 'DIFFERENT' ) )
                                    ( comparison_row( iv_fragname = 'NOT_COMPARED' iv_not_compared = abap_true ) ) ).

    DATA(ls_overview) = NEW ycl_trm_tr_overview( io_comparer   = comparer
                                                 io_collisions = collisions )->get( one_request( ) ).

    cl_abap_unit_assert=>assert_true( ls_overview-compared ).
    cl_abap_unit_assert=>assert_equals( exp = ycl_trm_tr_overview=>c_comparison-new
                                        act = ls_overview-entries[ fragname = 'NEW' ]-comparison ).
    cl_abap_unit_assert=>assert_equals( exp = ycl_trm_tr_overview=>c_comparison-equal
                                        act = ls_overview-entries[ fragname = 'EQUAL' ]-comparison ).
    cl_abap_unit_assert=>assert_equals( exp = ycl_trm_tr_overview=>c_comparison-different
                                        act = ls_overview-entries[ fragname = 'DIFFERENT' ]-comparison ).
    cl_abap_unit_assert=>assert_equals( exp = ycl_trm_tr_overview=>c_comparison-not_compared
                                        act = ls_overview-entries[ fragname = 'NOT_COMPARED' ]-comparison ).
  ENDMETHOD.


  METHOD not_compared_reasons.
    comparer->comparison = VALUE #(
        ( comparison_row( iv_fragname = 'CUSTO' iv_not_compared = abap_true iv_objfunc = 'K' ) )
        ( comparison_row( iv_fragname = 'DELETED' iv_not_compared = abap_true iv_objfunc = 'D' ) )
        ( comparison_row( iv_fragname = 'PACKAGE' iv_not_compared = abap_true iv_object = 'DEVC' ) )
        ( comparison_row( iv_fragname = 'LANGUAGE' iv_not_compared = abap_true iv_pgmid = 'LANG' ) )
        ( comparison_row( iv_fragname = 'ENHANCEMENT' iv_not_compared = abap_true iv_object = 'ENHO' ) )
        ( comparison_row( iv_fragname = 'OTHER' iv_not_compared = abap_true iv_object = 'TOBJ' ) ) ).

    DATA(lt_entries) = NEW ycl_trm_tr_overview( io_comparer   = comparer
                                                io_collisions = collisions )->get( one_request( ) )-entries.

    cl_abap_unit_assert=>assert_equals( exp = ycl_trm_tr_overview=>c_not_compared_reason-customizing
                                        act = lt_entries[ fragname = 'CUSTO' ]-not_compared_reason ).
    cl_abap_unit_assert=>assert_equals( exp = ycl_trm_tr_overview=>c_not_compared_reason-deleted
                                        act = lt_entries[ fragname = 'DELETED' ]-not_compared_reason ).
    cl_abap_unit_assert=>assert_equals( exp = ycl_trm_tr_overview=>c_not_compared_reason-package
                                        act = lt_entries[ fragname = 'PACKAGE' ]-not_compared_reason ).
    cl_abap_unit_assert=>assert_equals( exp = ycl_trm_tr_overview=>c_not_compared_reason-language
                                        act = lt_entries[ fragname = 'LANGUAGE' ]-not_compared_reason ).
    cl_abap_unit_assert=>assert_equals( exp = ycl_trm_tr_overview=>c_not_compared_reason-enhancement
                                        act = lt_entries[ fragname = 'ENHANCEMENT' ]-not_compared_reason ).
    cl_abap_unit_assert=>assert_equals( exp = ycl_trm_tr_overview=>c_not_compared_reason-not_versionable
                                        act = lt_entries[ fragname = 'OTHER' ]-not_compared_reason ).
  ENDMETHOD.


  METHOD comparer_error_propagates.
    comparer->raise_error = abap_true.

    TRY.
        NEW ycl_trm_tr_overview( io_comparer   = comparer
                                 io_collisions = collisions )->get( one_request( ) ).
        cl_abap_unit_assert=>fail( 'The comparison error must be propagated' ).
      CATCH ycx_trm_transport_request INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_equals( exp = 'DEST'
                                            act = lx_error->destination ).
    ENDTRY.
  ENDMETHOD.


  METHOD comparer_messages.
    comparer->messages = VALUE #( ( type = 'W' id = 'TSYS' number = '015' ) ).

    DATA(ls_overview) = NEW ycl_trm_tr_overview( io_comparer   = comparer
                                                 io_collisions = collisions )->get( one_request( ) ).

    cl_abap_unit_assert=>assert_equals( exp = comparer->messages
                                        act = ls_overview-messages ).
  ENDMETHOD.


  METHOD collision_on_fragment.
    comparer->comparison = VALUE #( ( comparison_row( iv_fragname = 'YCL_A                         M1' ) )
                                    ( comparison_row( iv_fragname = 'YCL_A                         M2' ) ) ).
    collisions->collisions = VALUE #( ( request  = 'S4DK999999'
                                        pgmid    = 'LIMU'
                                        object   = 'METH'
                                        obj_name = 'YCL_A                         M1' ) ).

    DATA(lt_entries) = NEW ycl_trm_tr_overview( io_comparer   = comparer
                                                io_collisions = collisions )->get( one_request( ) )-entries.

    cl_abap_unit_assert=>assert_equals(
        exp = VALUE ycl_trm_tr_overview=>ty_t_trkorr( ( 'S4DK999999' ) )
        act = lt_entries[ fragname = 'YCL_A                         M1' ]-collisions ).
    cl_abap_unit_assert=>assert_initial( lt_entries[ fragname = 'YCL_A                         M2' ]-collisions ).
    cl_abap_unit_assert=>assert_true(
        xsdbool( line_exists( collisions->received_objects[ pgmid    = 'LIMU'
                                                            object   = 'METH'
                                                            obj_name = 'YCL_A                         M1' ] ) ) ).
  ENDMETHOD.


  METHOD collision_on_main_object.
    comparer->comparison = VALUE #( ( comparison_row( iv_fragname = 'YCL_A                         M1' ) )
                                    ( comparison_row( iv_fragname = 'YCL_A                         M2' ) ) ).
    collisions->collisions = VALUE #( ( request  = 'S4DK999999'
                                        pgmid    = 'R3TR'
                                        object   = 'CLAS'
                                        obj_name = 'YCL_A' ) ).

    DATA(lt_entries) = NEW ycl_trm_tr_overview( io_comparer   = comparer
                                                io_collisions = collisions )->get( one_request( ) )-entries.

    LOOP AT lt_entries INTO DATA(ls_entry).
      cl_abap_unit_assert=>assert_equals( exp = VALUE ycl_trm_tr_overview=>ty_t_trkorr( ( 'S4DK999999' ) )
                                          act = ls_entry-collisions ).
    ENDLOOP.
  ENDMETHOD.


  METHOD default_excluded_requests.
    NEW ycl_trm_tr_overview( io_collisions = collisions )->get( one_request( ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = VALUE yif_trm_get_obj_w_collisions=>ty_r_transport_request( ( sign = 'I' option = 'EQ' low = 'S4DK000001' ) )
        act = collisions->received_range ).
  ENDMETHOD.


  METHOD explicit_excluded_requests.
    NEW ycl_trm_tr_overview( io_collisions = collisions )->get(
        it_transport_request = one_request( )
        ir_excluded_requests = VALUE #( ( sign = 'I' option = 'CP' low = 'S4DK*' ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = VALUE yif_trm_get_obj_w_collisions=>ty_r_transport_request( ( sign = 'I' option = 'CP' low = 'S4DK*' ) )
        act = collisions->received_range ).
  ENDMETHOD.


  METHOD customizing_keys.
    DATA(ls_row) = comparison_row( iv_fragname = 'TABU' iv_not_compared = abap_true iv_objfunc = 'K' ).
    ls_row-keys = VALUE #( ( objname = 'ZTABLE' tabkey = '100A' ) ).
    comparer->comparison = VALUE #( ( ls_row ) ).

    DATA(lt_entries) = NEW ycl_trm_tr_overview( io_comparer   = comparer
                                                io_collisions = collisions )->get( one_request( ) )-entries.

    cl_abap_unit_assert=>assert_equals( exp = ls_row-keys
                                        act = lt_entries[ 1 ]-keys ).
  ENDMETHOD.

ENDCLASS.
