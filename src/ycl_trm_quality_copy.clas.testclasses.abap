*"* use this source file for your ABAP unit test classes

CLASS ltd_custo_entry DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES yif_trm_tr_custo_entry PARTIALLY IMPLEMENTED.

    METHODS constructor
      IMPORTING iv_objname TYPE trobj_name
                iv_tabkey  TYPE trobj_name.

  PRIVATE SECTION.
    DATA objname TYPE trobj_name.
    DATA tabkey  TYPE trobj_name.
ENDCLASS.


CLASS ltd_custo_entry IMPLEMENTATION.
  METHOD constructor.
    objname = iv_objname.
    tabkey  = iv_tabkey.
  ENDMETHOD.

  METHOD yif_trm_tr_custo_entry~get_object_id.
    re_object_id = 'R3TR'.
  ENDMETHOD.

  METHOD yif_trm_tr_custo_entry~get_object_type.
    re_object_type = 'TABU'.
  ENDMETHOD.

  METHOD yif_trm_tr_custo_entry~get_object_name.
    re_object_name = objname.
  ENDMETHOD.

  METHOD yif_trm_tr_custo_entry~get_position.
    CLEAR re_position.
  ENDMETHOD.

  METHOD yif_trm_tr_custo_entry~get_master_type.
    re_master_type = 'TABU'.
  ENDMETHOD.

  METHOD yif_trm_tr_custo_entry~get_master_name.
    re_master_name = objname.
  ENDMETHOD.

  METHOD yif_trm_tr_custo_entry~get_view_name.
    CLEAR re_view_name.
  ENDMETHOD.

  METHOD yif_trm_tr_custo_entry~get_tab_key.
    re_tab_key = tabkey.
  ENDMETHOD.

  METHOD yif_trm_tr_custo_entry~get_sort_flag.
    CLEAR re_sort_flag.
  ENDMETHOD.

  METHOD yif_trm_tr_custo_entry~get_flag.
    CLEAR re_flag.
  ENDMETHOD.

  METHOD yif_trm_tr_custo_entry~get_language.
    CLEAR re_language.
  ENDMETHOD.

  METHOD yif_trm_tr_custo_entry~get_activity.
    CLEAR re_activity.
  ENDMETHOD.
ENDCLASS.


CLASS ltd_object DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES yif_trm_tr_object PARTIALLY IMPLEMENTED.

    METHODS constructor
      IMPORTING iv_pgmid    TYPE pgmid
                iv_object   TYPE trobjtype
                iv_obj_name TYPE trobj_name
                iv_objfunc  TYPE objfunc OPTIONAL
                it_keys     TYPE yif_trm_tr_custo_entry=>tab OPTIONAL.

  PRIVATE SECTION.
    DATA pgmid    TYPE pgmid.
    DATA object   TYPE trobjtype.
    DATA obj_name TYPE trobj_name.
    DATA objfunc  TYPE objfunc.
    DATA keys     TYPE yif_trm_tr_custo_entry=>tab.
ENDCLASS.


CLASS ltd_object IMPLEMENTATION.
  METHOD constructor.
    pgmid    = iv_pgmid.
    object   = iv_object.
    obj_name = iv_obj_name.
    objfunc  = iv_objfunc.
    keys     = it_keys.
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

  METHOD yif_trm_tr_object~is_customizing.
    re_is_custo = xsdbool( objfunc = yif_trm_tr_object=>function-customizing ).
  ENDMETHOD.

  METHOD yif_trm_tr_object~get_custo_entries.
    re_t_custo_entry = keys.
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
      IMPORTING iv_code        TYPE trkorr
                iv_description TYPE as4text OPTIONAL
                it_entries     TYPE yif_trm_tr_object=>tab OPTIONAL.

  PRIVATE SECTION.
    DATA code        TYPE trkorr.
    DATA description TYPE as4text.
    DATA entries     TYPE yif_trm_tr_object=>tab.
ENDCLASS.


CLASS ltd_request IMPLEMENTATION.
  METHOD constructor.
    code        = iv_code.
    description = iv_description.
    entries     = it_entries.
  ENDMETHOD.

  METHOD yif_trm_transport_request~get_code.
    re_code = code.
  ENDMETHOD.

  METHOD yif_trm_transport_request~get_description.
    re_description = description.
  ENDMETHOD.

  METHOD yif_trm_transport_request~get_entries.
    re_t_entries = entries.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_quality_copy DEFINITION DEFERRED.
CLASS ycl_trm_quality_copy DEFINITION LOCAL FRIENDS ltc_quality_copy.

CLASS ltc_quality_copy DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO ycl_trm_quality_copy.

    METHODS setup.

    METHODS default_selection             FOR TESTING.
    METHODS fragments_when_compared       FOR TESTING.
    METHODS entries_when_not_compared     FOR TESTING.
    METHODS whole_function_group          FOR TESTING.
    METHODS function_group_as_own_entry   FOR TESTING.
    METHODS deleted_function_group_entry  FOR TESTING.
    METHODS no_duplicated_entries         FOR TESTING.
    METHODS proposal_excludes_equal       FOR TESTING.
    METHODS key_count_without_duplicates  FOR TESTING.
    METHODS keys_from_requests            FOR TESTING.
    METHODS table_content_not_in_requests FOR TESTING.
    METHODS limu_entry_as_is              FOR TESTING.
    METHODS deleted_entry_kept            FOR TESTING.
    METHODS default_description_cut       FOR TESTING.

    METHODS overview_entry
      IMPORTING iv_fragid       TYPE pgmid     DEFAULT 'LIMU'
                iv_fragment     TYPE trobjtype DEFAULT 'METH'
                iv_fragname     TYPE trobj_name
                iv_pgmid        TYPE pgmid     DEFAULT 'R3TR'
                iv_object       TYPE trobjtype DEFAULT 'CLAS'
                iv_obj_name     TYPE trobj_name DEFAULT 'YCL_A'
                iv_comparison   TYPE ycl_trm_tr_overview=>ty_e_comparison
                  DEFAULT ycl_trm_tr_overview=>c_comparison-different
      RETURNING VALUE(rs_entry) TYPE ycl_trm_tr_overview=>ty_s_entry.
ENDCLASS.


CLASS ltc_quality_copy IMPLEMENTATION.

  METHOD setup.
    cut = NEW #( ycl_trm_logger=>new( ) ).
  ENDMETHOD.


  METHOD overview_entry.
    rs_entry = VALUE #( fragid     = iv_fragid
                        fragment   = iv_fragment
                        fragname   = iv_fragname
                        pgmid      = iv_pgmid
                        object     = iv_object
                        obj_name   = iv_obj_name
                        comparison = iv_comparison ).
  ENDMETHOD.


  METHOD default_selection.
    cl_abap_unit_assert=>assert_true(
        cut->is_selected_by_default( iv_compared   = abap_false
                                     iv_comparison = ycl_trm_tr_overview=>c_comparison-not_requested ) ).
    cl_abap_unit_assert=>assert_true(
        cut->is_selected_by_default( iv_compared   = abap_true
                                     iv_comparison = ycl_trm_tr_overview=>c_comparison-new ) ).
    cl_abap_unit_assert=>assert_true(
        cut->is_selected_by_default( iv_compared   = abap_true
                                     iv_comparison = ycl_trm_tr_overview=>c_comparison-different ) ).
    cl_abap_unit_assert=>assert_true(
        cut->is_selected_by_default( iv_compared   = abap_true
                                     iv_comparison = ycl_trm_tr_overview=>c_comparison-not_compared ) ).
    cl_abap_unit_assert=>assert_false(
        cut->is_selected_by_default( iv_compared   = abap_true
                                     iv_comparison = ycl_trm_tr_overview=>c_comparison-equal ) ).
  ENDMETHOD.


  METHOD fragments_when_compared.
    DATA(lt_entries) = cut->to_copy_entries(
        it_selected = VALUE #( ( overview_entry( iv_fragname = 'YCL_A                         M1' ) )
                               ( overview_entry( iv_fragname = 'YCL_A                         M2' ) ) )
        iv_compared = abap_true ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_entries ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'LIMU'
                                        act = lt_entries[ 1 ]-pgmid ).
    cl_abap_unit_assert=>assert_equals( exp = 'METH'
                                        act = lt_entries[ 1 ]-object ).
    cl_abap_unit_assert=>assert_equals( exp = 'YCL_A                         M1'
                                        act = lt_entries[ 1 ]-obj_name ).
    cl_abap_unit_assert=>assert_equals( exp = 'YCL_A'
                                        act = lt_entries[ 1 ]-overview-obj_name ).
    cl_abap_unit_assert=>assert_initial( lt_entries[ 1 ]-added_by ).
  ENDMETHOD.


  METHOD entries_when_not_compared.
    DATA(lt_entries) = cut->to_copy_entries(
        it_selected = VALUE #( ( pgmid = 'R3TR' object = 'CLAS' obj_name = 'YCL_A' )
                               ( pgmid = 'R3TR' object = 'PROG' obj_name = 'YB' ) )
        iv_compared = abap_false ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_entries ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'CLAS'
                                        act = lt_entries[ 1 ]-object ).
    cl_abap_unit_assert=>assert_equals( exp = 'YB'
                                        act = lt_entries[ 2 ]-obj_name ).
  ENDMETHOD.


  METHOD whole_function_group.
    DATA(lt_entries) = cut->to_copy_entries(
        it_selected = VALUE #( ( overview_entry( iv_fragment = 'FUNC' iv_fragname = 'Y_F1'
                                                 iv_object   = 'FUGR' iv_obj_name = 'YFG' ) )
                               ( overview_entry( iv_fragment = 'FUNC' iv_fragname = 'Y_F2'
                                                 iv_object   = 'FUGR' iv_obj_name = 'YFG' ) ) )
        iv_compared = abap_true ).

    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_entries ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = VALUE ycl_trm_quality_copy=>ty_s_copy_entry( pgmid    = 'R3TR'
                                                           object   = 'FUGR'
                                                           obj_name = 'YFG'
                                                           added_by = ycl_trm_quality_copy=>c_added_by-function_group )
        act = lt_entries[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( exp = 'Y_F2'
                                        act = lt_entries[ 3 ]-obj_name ).
  ENDMETHOD.


  METHOD function_group_as_own_entry.
    DATA(lt_entries) = cut->to_copy_entries(
        it_selected = VALUE #( ( pgmid = 'R3TR' object = 'FUGR' obj_name = 'YFG' ) )
        iv_compared = abap_false ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_entries ) ).
    cl_abap_unit_assert=>assert_initial( lt_entries[ 1 ]-added_by ).
    cl_abap_unit_assert=>assert_equals( exp = 'YFG'
                                        act = lt_entries[ 1 ]-overview-obj_name ).
  ENDMETHOD.


  METHOD deleted_function_group_entry.
    DATA(ls_deleted) = overview_entry( iv_fragid     = 'R3TR'
                                       iv_fragment   = 'FUGR'
                                       iv_fragname   = 'YFG'
                                       iv_object     = 'FUGR'
                                       iv_obj_name   = 'YFG'
                                       iv_comparison = ycl_trm_tr_overview=>c_comparison-not_compared ).
    ls_deleted-objfunc             = yif_trm_tr_object=>function-deleted.
    ls_deleted-not_compared_reason = ycl_trm_tr_overview=>c_not_compared_reason-deleted.

    DATA(lt_entries) = cut->to_copy_entries( it_selected = VALUE #( ( ls_deleted ) )
                                             iv_compared = abap_true ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_entries ) ).
    cl_abap_unit_assert=>assert_initial( lt_entries[ 1 ]-added_by ).
    cl_abap_unit_assert=>assert_equals( exp = yif_trm_tr_object=>function-deleted
                                        act = lt_entries[ 1 ]-overview-objfunc ).
  ENDMETHOD.


  METHOD no_duplicated_entries.
    DATA(lt_entries) = cut->to_copy_entries(
        it_selected = VALUE #( ( overview_entry( iv_fragname = 'YCL_A                         M1' ) )
                               ( overview_entry( iv_fragname = 'YCL_A                         M1'
                                                 iv_pgmid    = 'LIMU'
                                                 iv_object   = 'METH'
                                                 iv_obj_name = 'YCL_A                         M1' ) ) )
        iv_compared = abap_true ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_entries ) ).
  ENDMETHOD.


  METHOD proposal_excludes_equal.
    DATA(ls_proposal) = cut->propose( VALUE #(
        compared = abap_true
        entries  = VALUE #( ( overview_entry( iv_fragname   = 'NEW'
                                              iv_comparison = ycl_trm_tr_overview=>c_comparison-new ) )
                            ( overview_entry( iv_fragname   = 'EQUAL'
                                              iv_comparison = ycl_trm_tr_overview=>c_comparison-equal ) )
                            ( overview_entry( iv_fragname   = 'DIFFERENT'
                                              iv_comparison = ycl_trm_tr_overview=>c_comparison-different ) ) ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( ls_proposal-entries ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( ls_proposal-excluded ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'EQUAL'
                                        act = ls_proposal-excluded[ 1 ]-fragname ).
  ENDMETHOD.


  METHOD key_count_without_duplicates.
    DATA(ls_entry) = overview_entry( iv_fragname = 'YT' ).
    ls_entry-keys = VALUE #( ( trkorr = 'DEVK900001' pgmid = 'R3TR' object = 'TABU' objname = 'YT' tabkey = 'A' )
                             ( trkorr = 'DEVK900002' pgmid = 'R3TR' object = 'TABU' objname = 'YT' tabkey = 'A' )
                             ( trkorr = 'DEVK900002' pgmid = 'R3TR' object = 'TABU' objname = 'YT' tabkey = 'B' ) ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = cut->get_customizing_key_count( ls_entry ) ).
  ENDMETHOD.


  METHOD keys_from_requests.
    DATA(lt_requests) = VALUE yif_trm_transport_request=>tab(
        ( NEW ltd_request(
              iv_code    = 'DEVK900001'
              it_entries = VALUE #( ( NEW ltd_object( iv_pgmid    = 'R3TR'
                                                      iv_object   = 'TABU'
                                                      iv_obj_name = 'YT'
                                                      iv_objfunc  = 'K'
                                                      it_keys     = VALUE #(
                                                          ( NEW ltd_custo_entry( iv_objname = 'YT' iv_tabkey = 'A' ) )
                                                          ( NEW ltd_custo_entry( iv_objname = 'YT' iv_tabkey = 'B' ) ) ) ) ) ) ) )
        ( NEW ltd_request(
              iv_code    = 'DEVK900002'
              it_entries = VALUE #( ( NEW ltd_object( iv_pgmid    = 'R3TR'
                                                      iv_object   = 'TABU'
                                                      iv_obj_name = 'YT'
                                                      iv_objfunc  = 'K'
                                                      it_keys     = VALUE #(
                                                          ( NEW ltd_custo_entry( iv_objname = 'YT' iv_tabkey = 'B' ) )
                                                          ( NEW ltd_custo_entry( iv_objname = 'YT' iv_tabkey = 'C' ) ) ) ) ) ) ) ) ).

    cut->build_objects( EXPORTING it_transport_request = lt_requests
                                  it_entries           = VALUE #( ( pgmid = 'R3TR' object = 'TABU' obj_name = 'YT' ) )
                        IMPORTING et_e071              = DATA(lt_e071)
                                  et_e071k             = DATA(lt_e071k)
                                  et_not_added         = DATA(lt_not_added) ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_e071 ) ).
    cl_abap_unit_assert=>assert_equals( exp = yif_trm_tr_object=>function-customizing
                                        act = lt_e071[ 1 ]-objfunc ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_e071k ) ).
    cl_abap_unit_assert=>assert_initial( lt_not_added ).
  ENDMETHOD.


  METHOD table_content_not_in_requests.
    cut->build_objects( EXPORTING it_transport_request = VALUE #( ( NEW ltd_request( iv_code = 'DEVK900001' ) ) )
                                  it_entries           = VALUE #( ( pgmid = 'R3TR' object = 'TABU' obj_name = 'YT' ) )
                        IMPORTING et_e071              = DATA(lt_e071)
                                  et_e071k             = DATA(lt_e071k)
                                  et_not_added         = DATA(lt_not_added) ).

    cl_abap_unit_assert=>assert_initial( lt_e071 ).
    cl_abap_unit_assert=>assert_initial( lt_e071k ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_not_added ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'YT'
                                        act = lt_not_added[ 1 ]-obj_name ).
  ENDMETHOD.


  METHOD limu_entry_as_is.
    cut->build_objects(
        EXPORTING it_transport_request = VALUE #( ( NEW ltd_request(
                                                        iv_code    = 'DEVK900001'
                                                        it_entries = VALUE #( ( NEW ltd_object( iv_pgmid    = 'R3TR'
                                                                                                iv_object   = 'CLAS'
                                                                                                iv_obj_name = 'YCL_A' ) ) ) ) ) )
                  it_entries           = VALUE #( ( pgmid = 'LIMU' object = 'METH' obj_name = 'YCL_A                         M1' )
                                                  ( pgmid = 'LIMU' object = 'METH' obj_name = 'YCL_A                         M1' ) )
        IMPORTING et_e071              = DATA(lt_e071)
                  et_not_added         = DATA(lt_not_added) ).

    cl_abap_unit_assert=>assert_equals(
        exp = VALUE e071_t( ( pgmid = 'LIMU' object = 'METH' obj_name = 'YCL_A                         M1' ) )
        act = lt_e071 ).
    cl_abap_unit_assert=>assert_initial( lt_not_added ).
  ENDMETHOD.


  METHOD deleted_entry_kept.
    cut->build_objects(
        EXPORTING it_transport_request = VALUE #( ( NEW ltd_request(
                                                        iv_code    = 'DEVK900001'
                                                        it_entries = VALUE #( ( NEW ltd_object( iv_pgmid    = 'R3TR'
                                                                                                iv_object   = 'PROG'
                                                                                                iv_obj_name = 'YB'
                                                                                                iv_objfunc  = 'D' ) ) ) ) ) )
                  it_entries           = VALUE #( ( pgmid = 'R3TR' object = 'PROG' obj_name = 'YB' ) )
        IMPORTING et_e071              = DATA(lt_e071) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_tr_object=>function-deleted
                                        act = lt_e071[ 1 ]-objfunc ).
  ENDMETHOD.


  METHOD default_description_cut.
    DATA(lv_description) = cut->get_default_description(
        NEW ltd_request( iv_code        = 'DEVK900001'
                         iv_description = 'Request with a very long description to check the cut at 60' ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = CONV as4text( 'COPY - Request with a very long description to check the cut' )
        act = lv_description ).
  ENDMETHOD.

ENDCLASS.
