CLASS ycl_trm_xref_repository DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES yif_trm_xref_repository.

    METHODS constructor
      IMPORTING iv_rfc_destination TYPE rfcdes-rfcdest.

  PRIVATE SECTION.
    DATA ai_rfc_destination    TYPE rfcdes-rfcdest.
    DATA ai_namespaces_loaded  TYPE abap_bool.
    DATA ai_t_namespace        TYPE STANDARD TABLE OF /sdf/cmo_namespace_long WITH DEFAULT KEY
                                    WITH NON-UNIQUE SORTED KEY sorted_by_key COMPONENTS namespace.

    METHODS load_namespaces.

ENDCLASS.


CLASS ycl_trm_xref_repository IMPLEMENTATION.

  METHOD constructor.
    ai_rfc_destination = iv_rfc_destination.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~get_fragments.
    TYPES ty_t_e071 TYPE STANDARD TABLE OF e071 WITH DEFAULT KEY.

    DATA lt_comparison TYPE vrs_compare_item_tab.
    DATA lt_nonvers    TYPE TABLE OF e071.

    DATA(lv_filter_lang) = abap_true.
    DATA(lv_delete_lang) = ' '.

    CALL FUNCTION 'SVRS_MASSCOMPARE_ACT_OBJECTS'
      EXPORTING  it_e071                = CORRESPONDING ty_t_e071( it_objects MAPPING object = obj_type )
                 iv_rfcdest_b           = 'NONE'
                 iv_filter_lang         = lv_filter_lang
                 iv_delete_lang         = lv_delete_lang
                 iv_with_gui_progress   = abap_false
                 iv_ignore_report_text  = 'X'
      IMPORTING  et_compare_items       = lt_comparison
                 et_nonversionable_e071 = lt_nonvers
      EXCEPTIONS rfc_error              = 1
                 not_supported          = 2
                 OTHERS                 = 3.
    CASE sy-subrc.
      WHEN 0.
      WHEN 1.
        FINAL(lo_log) = ycl_trm_logger=>new( ).
        MESSAGE i008(tsys) WITH ai_rfc_destination INTO FINAL(lv_message) ##NEEDED.
        lo_log->add_from_system_variables( ).
        RAISE EXCEPTION NEW ycx_trm_cross_reference( logger = lo_log ).
      WHEN OTHERS.
        MESSAGE i015(tsys).
    ENDCASE.

    rt_fragments = VALUE #( FOR ls_comparison IN lt_comparison
                            ( pgmid    = ls_comparison-fragid
                              obj_type = ls_comparison-fragment
                              obj_name = ls_comparison-fragname ) ).

    rt_fragments = VALUE #( BASE rt_fragments
                            FOR ls_nonvers IN lt_nonvers
                            ( pgmid    = ls_nonvers-pgmid
                              obj_type = ls_nonvers-object
                              obj_name = ls_nonvers-obj_name ) ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~get_references.
    DATA lt_messages TYPE TABLE OF cnvcdmc_messages.

    DATA(lt_objects) = it_objects.

    CALL FUNCTION '/SDF/TEAP_GET_REF_OBJECTS'
      TABLES     it_objs                    = lt_objects
                 it_obj_ref_tab             = rt_references
                 et_messages                = lt_messages
      EXCEPTIONS no_objs_specified_for_anal = 1
                 no_ref_found               = 2
                 OTHERS                     = 3.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~resolve_methods.
    DATA lt_objs TYPE STANDARD TABLE OF cnvcdmccts_objects_set WITH DEFAULT KEY.

    rt_methods = it_methods.

    CALL FUNCTION '/SDF/TEAP_RESOLVE_METH'
      TABLES et_objs = lt_objs
             it_objs = lt_objs
             tt_meth = rt_methods.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~get_class_part_methods.
    DATA lt_seomethod TYPE STANDARD TABLE OF vseomethod WITH DEFAULT KEY.
    DATA lt_seoredef  TYPE STANDARD TABLE OF seoredef WITH DEFAULT KEY.

    DATA(lv_function_name) = |SVRS_GET_VERSION_{ iv_part }_40|.

    CALL FUNCTION lv_function_name
      EXPORTING  object_name           = CONV vrsd-objname( iv_class_name )
                 versno                = CONV vrsd-versno( '00000' )
      TABLES     pvseomethod           = lt_seomethod
                 pseoredef             = lt_seoredef
      EXCEPTIONS no_version            = 1
                 system_failure        = 2
                 communication_failure = 3
                 OTHERS                = 4.

    rt_methods = VALUE #( FOR ls_seomethod IN lt_seomethod
                          ( CONV #( ls_seomethod-cmpname ) ) ).

    rt_methods = VALUE #( BASE rt_methods
                          FOR ls_seoredef IN lt_seoredef
                          ( CONV #( ls_seoredef-mtdname ) ) ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~has_own_pgmid.
    CALL FUNCTION 'TR_GET_PGMID_FOR_OBJECT'
      EXPORTING  iv_object      = iv_object_type
      EXCEPTIONS illegal_object = 1
                 OTHERS         = 2.

    rv_result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~normalize_reference.
    DATA(lt_reference) = VALUE yif_trm_xref_repository=>ty_t_references( ( is_reference ) ).
    DATA(lt_normalized) = VALUE yif_trm_xref_repository=>ty_t_references( ).

    PERFORM convert_ref_objects IN PROGRAM /sdf/saplteap_main
      TABLES lt_reference
             lt_normalized
      USING  'NONE'
             ai_rfc_destination.

    rt_normalized = lt_normalized.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~is_sap_object.
    DATA ls_e071      TYPE e071.
    DATA lv_namespace TYPE trnspace-namespace.

    ls_e071-pgmid    = is_object-pgmid.
    ls_e071-object   = is_object-obj_type.
    ls_e071-obj_name = is_object-obj_name.

    IF ls_e071-object = 'FUNC'.
      CALL FUNCTION '/SDF/TEAP_TR_CHECK_TYPE'
        EXPORTING wi_e071      = ls_e071
        IMPORTING ev_namespace = lv_namespace.
    ELSE.
      CALL FUNCTION 'TR_CHECK_TYPE'
        EXPORTING wi_e071      = ls_e071
        IMPORTING ev_namespace = lv_namespace.
    ENDIF.

    IF lv_namespace <> '/0SAP/' AND lv_namespace <> '/0CUST/'.
      load_namespaces( ).
      TRY.
          FINAL(ls_namespace) = ai_t_namespace[ KEY sorted_by_key
                                                namespace = lv_namespace ].
          lv_namespace = COND #( WHEN ls_namespace-ns_info = 'SAP' THEN '/0SAP/' ELSE '/0CUST/' ).
        CATCH cx_sy_itab_line_not_found.
          lv_namespace = '/0CUST/'.
      ENDTRY.
    ENDIF.

    rv_result = xsdbool( lv_namespace = '/0SAP/' ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~method_exists.
    CALL FUNCTION 'RPY_EXISTENCE_CHECK_METH'
      EXPORTING  class     = iv_class_name
                 method    = iv_method_name
      EXCEPTIONS not_exist = 1.

    rv_result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD load_namespaces.
    IF ai_namespaces_loaded = abap_true.
      RETURN.
    ENDIF.

    CALL FUNCTION '/SDF/CMO_NAMESPACE_INFO'
      TABLES et_namespace = ai_t_namespace.

    ai_namespaces_loaded = abap_true.
  ENDMETHOD.

ENDCLASS.
